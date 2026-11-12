# JP Morgan Chase Commercial Banking Ledger — AML Compliance & Query Tuning

**Course:** MIT-8103 — Advanced Database Systems  
**Portfolio:** Portfolio 2 — Query Optimisation & Access Path Tuning  
**Environment:** Oracle Database 19c (Finacle Core Banking Schema)  

---

## 1. The Business Problem

In JP Morgan commercial banking, compliance teams spend a lot of time sifting through transaction noise to spot actual financial crime risks. For this case study, the Risk and Compliance unit needed a reliable report to flag high-value corporate customers with large cleared balances and high AML risk scores, allowing auditors and compliance analysts to focus their attention on accounts that may require further investigation.

Specifically, auditors wanted to isolate active Nigerian Naira (`NGN`) corporate accounts holding at least (`>= 250000000`) where the customer's dynamic AML risk score had climbed to **7.5 or higher**. These thresholds were established to isolate high-value accounts exhibiting elevated compliance risk indicators, thereby enabling the Risk, Compliance, and Audit team to focus on customers that may warrant enhanced monitoring, investigation, or regulatory review.

---

## 2. Database Schema & Entity Relationships

Following Finacle's core banking table design, the query pulls across five tables in the `CUSTOMER` and `TRANSACT` schemas:

* **`CUSTOMER.CORPORATE_CUSTOMER_MASTER`**: Holds the company's legal name, Nigerian CAC registration number, and baseline KYC risk tier.
* **`TRANSACT.GENERAL_ACCT_MAST_TABLE`**: The core account master tracking NUBAN account numbers, currency codes, active flags, and cleared balances.
* **`CUSTOMER.AML_FORENSIC_TRAIL`**: An append-only audit log that records every dynamic AML risk score evaluation over time.
* **`TRANSACT.DAILY_TXN_DTL`**: Captures intraday posted transactions for the current banking cycle.
* **`TRANSACT.HISTORY_TXN_DTL`**: Stores end-of-day archived transaction details for historical reporting.

---

## 3. Compliance Reporting Query (`portfolio_2_queries.sql`)

Writing a query across these five tables comes with three design considerations that had to be handled cleanly:

1. **Combining Intraday & Historical Ledgers (`UNION ALL`):** In Finacle, recent 30-day activity spans both `DAILY_TXN_DTL` (today's posted entries) and `HISTORY_TXN_DTL` (prior days). Combining both tables with `UNION ALL` ensures zero blind spots in transaction monitoring without paying the sorting overhead of `UNION`.
2. **Avoiding Duplicate Rows from Audit Logs:** Because `AML_FORENSIC_TRAIL` logs every historical risk evaluation, a direct join would repeat a company's ₦250M+ balance multiple times if they had multiple past alerts. Using `ROW_NUMBER()` partitioned by `cif_id` isolates only their **most recent** risk assessment.
3. **Keeping Quiet Accounts Visible:** By pre-aggregating posted transactions in `recent_payments` and joining via `LEFT JOIN`, high-risk accounts with zero recent transfers still appear on the compliance radar with a `0` count rather than disappearing from the report.

```sql
WITH latest_aml_events AS (
    SELECT 
        cif_id,
        risk_score_after,
        event_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY cif_id 
            ORDER BY event_timestamp DESC
        ) AS rn
    FROM CUSTOMER.aml_forensic_trail
    WHERE customer_type = 'CORPORATE'
),
combined_txn_30d AS (
    SELECT acct_id, tran_id, tran_amt
    FROM TRANSACT.daily_txn_dtl
    WHERE pstd_flg = 'Y'
      AND del_flg = 'N'
      AND tran_date >= ADD_MONTHS(TRUNC(SYSDATE), -1)
    UNION ALL
    SELECT acct_id, tran_id, tran_amt
    FROM TRANSACT.history_txn_dtl
    WHERE pstd_flg = 'Y'
      AND del_flg = 'N'
      AND tran_date >= ADD_MONTHS(TRUNC(SYSDATE), -1)
),
recent_payments AS (
    SELECT 
        acct_id,
        COUNT(tran_id) AS total_tx_count,
        SUM(tran_amt) AS total_tx_volume
    FROM combined_txn_30d
    GROUP BY acct_id
)
SELECT 
    g.acct_id,
    g.acct_num,
    c.company_name,
    c.registration_nbr,
    c.risk_rating AS profile_risk_tier,
    g.clr_bal_amt,
    g.acct_crncy_code,
    a.risk_score_after AS dynamic_risk_score,
    a.event_timestamp AS latest_aml_review,
    NVL(p.total_tx_count, 0) AS monthly_payment_count,
    NVL(p.total_tx_volume, 0) AS monthly_payment_volume
FROM TRANSACT.general_acct_mast_table g
INNER JOIN CUSTOMER.corporate_customer_master c 
    ON g.cif_id = c.cif_id
INNER JOIN latest_aml_events a 
    ON c.cif_id = a.cif_id
LEFT JOIN recent_payments p
    ON g.acct_id = p.acct_id
WHERE g.acct_crncy_code = 'NGN'
  AND g.del_flg = 'N'
  AND g.clr_bal_amt >= 250000000
  AND c.del_flg = 'N'
  AND a.rn = 1
  AND a.risk_score_after >= 7.5
ORDER BY a.risk_score_after DESC, g.clr_bal_amt DESC;
```

---

## 4. Tuning Physical Access Paths with Covering Indexes

On unindexed tables, Oracle had to scan all five tables from top to bottom—especially `HISTORY_TXN_DTL`, which grows rapidly in production banking environments. Instead of indexing only join columns and forcing Oracle to jump back to the base tables (`TABLE ACCESS BY INDEX ROWID`), I created five **covering composite indexes** that include every column needed for filtering, joining, and display:

* **`IDX_GAM_CURR_DEL_BAL_COV`**: Filters active NGN accounts `>= 250M` and carries `cif_id`, `acct_id`, and `acct_num`.
* **`IDX_CORP_CIF_COVERING`**: Resolves corporate names, CAC registration numbers, and risk ratings inside the index.
* **`IDX_AML_CORP_TS_SCORE`**: Pre-sorts AML events by `(customer_type, cif_id, event_timestamp DESC, risk_score_after)` so `ROW_NUMBER()` avoids an in-memory sort.
* **`IDX_DTD_PSTD_DATE_COV` & `IDX_HTD_PSTD_DATE_COV`**: Covering indexes on `(pstd_flg, del_flg, tran_date, acct_id, tran_amt, tran_id)` so Oracle can aggregate 30-day posted transactions from both `DAILY_TXN_DTL` and `HISTORY_TXN_DTL` via index range scans.
  
  To eliminate full table scans (`TABLE ACCESS FULL`) and expensive table lookups (`TABLE ACCESS BY INDEX ROWID`), five **covering composite B-Tree indexes** were implemented alongside updated optimizer column statistics (`DBMS_STATS.GATHER_TABLE_STATS`):

```sql
-- 1. Covering Index for High-Value Active Account Filtering
CREATE INDEX TRANSACT.idx_gam_curr_del_bal_cov 
    ON TRANSACT.general_acct_mast_table (acct_crncy_code, del_flg, clr_bal_amt, cif_id, acct_id, acct_num)
    COMPRESS 2;

-- 2. True Covering Index for Corporate Customer Registry
CREATE INDEX CUSTOMER.idx_corp_cif_covering 
    ON CUSTOMER.corporate_customer_master (cif_id, del_flg, company_name, registration_nbr, risk_rating)
    COMPRESS 2;

-- 3. Composite Index for Windowed AML Forensic Event Lookup
CREATE INDEX CUSTOMER.idx_aml_corp_ts_score 
    ON CUSTOMER.aml_forensic_trail (customer_type, cif_id, event_timestamp DESC, risk_score_after)
    COMPRESS 1;

-- 4. Covering Index for 30-Day Payment Volume Aggregation
CREATE INDEX TRANSACT.IDX_DTD_PSTD_DATE_COV 
    ON TRANSACT.DAILY_TXN_DTL (pstd_flg, del_flg, tran_date, acct_id, tran_amt, tran_id)
    COMPRESS 1;

-- 5. Covering Index for 30-Day Payment Volume Aggregation
CREATE INDEX TRANSACT.IDX_HTD_PSTD_DATE_COV 
    ON TRANSACT.HISTORY_TXN_DTL (pstd_flg, del_flg, tran_date, acct_id, tran_amt, tran_id)
    COMPRESS 1;
```

---

## 5. Performance Impact Summary

| Metric | Before Indexing | After Indexing | Impact |
| :--- | ---: | ---: | :--- |
| **Median Execution Time** | 2,140 ms | 72 ms | **~29x faster** |
| **Three Test Runs** | 2,190 / 2,140 / 2,105 ms | 78 / 72 / 69 ms | Consistent sub-80ms response |
| **Consistent Gets (Logical Reads)** | 61,450 | 1,380 | **97.7% fewer block reads** |
| **CBO Optimizer Cost** | 18,920 | 495 | **97.4% cost reduction** |
| **Primary Access Path** | `HASH JOIN` + `TABLE ACCESS FULL` | `NESTED LOOPS` + `INDEX RANGE SCAN` | **100% Index-Only Plan** |

*(Full Oracle 19c `DBMS_XPLAN.DISPLAY_CURSOR` outputs and execution plan breakdowns are documented in [`query_optimization_sql.md`](./query_optimization_sql.md).)*





