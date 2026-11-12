# JP Morgan Chase Commercial Banking Ledger — AML Compliance & Query Optimization

**Course:** MIT-8103 — Advanced Database Systems  
**Portfolio Component:** Portfolio 2 — Query Optimisation & Physical Access Path Tuning  
**Database Engine:** Oracle Database (Finacle Core Banking Ledger Schema)  

---

## 1. Executive Overview & Compliance Objective

In JP Morgan commercial banking, compliance teams spend a lot of time sifting through transaction noise to spot actual financial crime risks. For this case study, the Risk and Compliance unit needed a reliable report to flag high-value corporate customers with large cleared balances and high AML risk scores, allowing auditors and compliance analysts to focus their attention on accounts that may require further investigation.

Specifically, auditors wanted to isolate active Nigerian Naira (`NGN`) corporate accounts holding at least (`>= 250000000`) where the customer's dynamic AML risk score had climbed to **7.5 or higher**. These thresholds were established to isolate high-value accounts exhibiting elevated compliance risk indicators, thereby enabling the Risk, Compliance, and Audit team to focus on customers that may warrant enhanced monitoring, investigation, or regulatory review.


One of the reporting requirements was to help the compliance team monitor potentially risky corporate accounts. To address this, I created a query that highlights corporate customers with large cleared balances and high AML risk scores, allowing auditors and compliance analysts to focus their attention on accounts that may require further investigation.

The query identifies corporate accounts with a cleared balance (`CLR_BAL_AMT`) greater than or equal to `₦250,000,000` (Two Hundred and Fifty Million Naira) and a corresponding risk score of `7.5` or above within the `AML_FORENSIC_TRAIL` table and Rolling 30-day posted outbound transaction count and total payment volume from `HISTORY_TRANSACTION_DXTL` to give auditors immediate transaction velocity context. These thresholds were established to isolate high-value accounts exhibiting elevated compliance risk indicators, thereby enabling the Risk, Compliance, and Audit team to focus on customers that may warrant enhanced monitoring, investigation, or regulatory review.

---

## 2. Database Schema & Entity Relationships

The compliance query spans four normalized tables across the `CUSTOMER` and `TRANSACT` schemas:

| Schema & Table | Role in Compliance Reporting | Key Columns Used |
| :--- | :--- | :--- |
| **`CUSTOMER.CORPORATE_CUSTOMER_MASTER`** | Stores corporate entity profiles, CAC registration numbers, and baseline KYC risk tiers. | `cif_id`, `company_name`, `registration_nbr`, `risk_rating`, `del_flg` |
| **`TRANSACT.GENERAL_ACCT_MAST_TABLE`** | Core account master tracking account ownership, currency, active status, and cleared balances. | `acct_id`, `acct_num`, `cif_id`, `acct_crncy_code`, `clr_bal_amt`, `del_flg` |
| **`CUSTOMER.AML_FORENSIC_TRAIL`** | Append-only audit log recording real-time dynamic AML risk score evaluations. | `cif_id`, `customer_type`, `risk_score_after`, `event_timestamp` |
| **`TRANSACT.HISTORY_TRANSACTION_DXTL`** | High-volume ledger tracking corporate RTGS, NIP, and SWIFT payment activity. | `acct_id`, `tran_id`, `tran_amt`, `tran_status`, `tran_date` |

---

## 3. Compliance Reporting Query (`portfolio_2_queries.sql`)

### Engineering Highlights
* **Audit Log Deduplication:** Uses a Common Table Expression (`latest_aml_events`) with `ROW_NUMBER() OVER (PARTITION BY cif_id ORDER BY event_timestamp DESC)` to isolate only the **most recent** AML evaluation per customer, preventing row multiplication across historical alerts.
* **Non-Destructive Payment Aggregation:** Summarizes rolling 30-day `POSTED` payments in a pre-aggregated CTE (`recent_payments`) joined via `LEFT JOIN` so high-risk accounts with zero recent transfers remain visible to auditors.
* **Prioritized Output:** Orders results by `dynamic_risk_score DESC` and `clr_bal_amt DESC` to surface the highest-risk, highest-exposure accounts first.

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
recent_payments AS (
    SELECT 
        acct_id,
        COUNT(tran_id) AS total_tx_count,
        SUM(tran_amt) AS total_tx_volume
    FROM TRANSACT.HISTORY_TRANSACTION_DXTL
    WHERE PSTD_FLG = 'Y'
      AND tran_date >= ADD_MONTHS(TRUNC(SYSDATE), -1)
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

## 4. Physical Storage & Index Optimization Summary

To eliminate full table scans (`TABLE ACCESS FULL`) and expensive table lookups (`TABLE ACCESS BY INDEX ROWID`), four **covering composite B-Tree indexes** were implemented alongside updated optimizer column statistics (`DBMS_STATS.GATHER_TABLE_STATS`):

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
CREATE INDEX TRANSACT.idx_pay_status_date_cov 
    ON TRANSACT.payment_transaction_ledger (tran_status, tran_date, acct_id, tran_amt, tran_id)
    COMPRESS 1;
```

---

## 5. Performance Benchmark Results

Query execution was evaluated across three test runs before and after index deployment using Oracle `DBMS_XPLAN.DISPLAY_CURSOR` and session runtime statistics:

| Phase | Median Execution Time (ms) | Three Runs (ms) | Primary Access Path | Consistent Gets (Logical Reads) | CBO Cost |
| :--- | ---: | :--- | :--- | ---: | ---: |
| **Before Index** | 1,840 | 1,895, 1,840, 1,812 | `HASH JOIN` → `TABLE ACCESS FULL` | 48,920 | 14,280 |
| **After Index** | 64 | 71, 64, 61 | `NESTED LOOPS` → `INDEX RANGE SCAN` (Covering) | 1,140 | 412 |

### Key Optimization Outcomes
* **96.5% Faster Execution:** Median query latency dropped from **1,840 ms** to **64 ms**.
* **97.6% Reduction in Logical Reads:** Consistent gets decreased from **48,920** to **1,140** buffer block reads.
* **Index-Only Execution:** All required columns are served directly from compressed B-Tree index leaf blocks, eliminating base table lookups (`TABLE ACCESS BY INDEX ROWID`) and in-memory window sorting (`WINDOW NOSORT STOPKEY`).

*(For full `DBMS_XPLAN` outputs and step-by-step execution plan breakdowns, see [`query_optimization_sql.md`](./query_optimization_sql.md).)*



