# Query Performance Testing & Execution Plan Analysis

**Course:** MIT-8103 — Advanced Database Systems  
**Database Engine:** Oracle Database 19c Enterprise Edition  
**Case Study:** JP Morgan Chase Commercial Banking Core Ledger (Nigeria Operations)  

---

## 1. Performance Testing Methodology

To evaluate the effectiveness of the covering indexing strategy if it actually reduces I/O and execution time. The compliance reporting query was executed before and after index creation on Oracle 19c. The objective was to determine whether the proposed indexes reduced query execution costs and improved data retrieval efficiency.

Testing was run across all five schema tables:

* `TRANSACT.GENERAL_ACCT_MAST_TABLE`
* `CUSTOMER.CORPORATE_CUSTOMER_MASTER`
* `CUSTOMER.AML_FORENSIC_TRAIL`
* `TRANSACT.DAILY_TXN_DTL`
* `TRANSACT.HISTORY_TXN_DTL`

---

## Baseline query


## 2. Capturing Execution Plans & Runtime Statistics

I used `EXPLAIN PLAN` to inspect the Cost-Based Optimizer's estimated path, and `ALTER SESSION SET statistics_level = ALL` paired with `DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST')` to capture actual runtime execution metrics across three runs:

```sql
ALTER SESSION SET statistics_level = ALL;

-- Execute compliance reporting query (see portfolio_2_queries.sql)

SELECT * 
FROM TABLE(
    DBMS_XPLAN.DISPLAY_CURSOR(
        NULL, 
        NULL, 
        'ALLSTATS LAST'
    )
);
```

---

## 3. Baseline Execution Plan (Before Indexing)

Before adding secondary indexes, Oracle 19c performed full table scans (`TABLE ACCESS FULL`) across all five tables—with `HISTORY_TXN_DTL` accounting for the bulk of the I/O cost—and executed a blocking window sort on `AML_FORENSIC_TRAIL`.

```text
-------------------------------------------------------------------------------------------------------------

| Id  | Operation                        | Name                       | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------------

|   0 | SELECT STATEMENT                 |                            |    42 |  8148 | 18920   (2)| 00:00:03 |
|   1 |  SORT ORDER BY                   |                            |    42 |  8148 | 18920   (2)| 00:00:03 |
|*  2 |   HASH JOIN RIGHT OUTER          |                            |    42 |  8148 | 18919   (2)| 00:00:03 |
|   3 |    VIEW                          |                            |  8920 |   226K|  9450   (2)| 00:00:02 |
|   4 |     HASH GROUP BY                |                            |  8920 |   269K|  9450   (2)| 00:00:02 |
|   5 |      VIEW                        |                            | 98600 |  2983K|  9432   (1)| 00:00:02 |
|   6 |       UNION-ALL                  |                            |       |       |            |          |
|*  7 |        TABLE ACCESS FULL         | DAILY_TXN_DTL              |  6200 |   187K|   412   (1)| 00:00:01 |
|*  8 |        TABLE ACCESS FULL         | HISTORY_TXN_DTL            | 92400 |  2796K|  9020   (1)| 00:00:02 |
|*  9 |    HASH JOIN                     |                            |    42 |  7056 |  9468   (2)| 00:00:02 |
|* 10 |     VIEW                         |                            |   310 |  9610 |  3912   (2)| 00:00:01 |
|* 11 |      WINDOW SORT PUSHED RANK     |                            |   310 | 11470 |  3912   (2)| 00:00:01 |
|* 12 |       TABLE ACCESS FULL          | AML_FORENSIC_TRAIL         | 64200 |  2320K|  3890   (1)| 00:00:01 |
|* 13 |     HASH JOIN                    |                            |   480 | 65760 |  5555   (1)| 00:00:01 |
|* 14 |      TABLE ACCESS FULL           | GENERAL_ACCT_MAST_TABLE    |   495 | 26730 |  3420   (1)| 00:00:01 |
|* 15 |      TABLE ACCESS FULL           | CORPORATE_CUSTOMER_MASTER  | 18500 |  1499K|  2134   (1)| 00:00:01 |
-------------------------------------------------------------------------------------------------------------
```

---

## 4. Tuned Execution Plan (After Indexing & `DBMS_STATS`)

After deploying the five covering indexes (`IDX_GAM_CURR_DEL_BAL_COV`, `IDX_CORP_CIF_COVERING`, `IDX_AML_CORP_TS_SCORE`, `IDX_DTD_PSTD_DATE_COV`, and `IDX_HTD_PSTD_DATE_COV`) and refreshing optimizer column histograms, every `TABLE ACCESS FULL` disappeared from the plan:

```text
------------------------------------------------------------------------------------------------------------

| Id  | Operation                       | Name                       | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------------------

|   0 | SELECT STATEMENT                |                            |    42 |  8148 |   495   (2)| 00:00:01 |
|   1 |  SORT ORDER BY                  |                            |    42 |  8148 |   495   (2)| 00:00:01 |
|*  2 |   HASH JOIN RIGHT OUTER         |                            |    42 |  8148 |   494   (2)| 00:00:01 |
|   3 |    VIEW                         |                            |  8920 |   226K|   268   (3)| 00:00:01 |
|   4 |     HASH GROUP BY               |                            |  8920 |   269K|   268   (3)| 00:00:01 |
|   5 |      VIEW                       |                            | 98600 |  2983K|   251   (1)| 00:00:01 |
|   6 |       UNION-ALL                 |                            |       |       |            |          |
|*  7 |        INDEX RANGE SCAN         | IDX_DTD_PSTD_DATE_COV      |  6200 |   187K|    19   (0)| 00:00:01 |
|*  8 |        INDEX RANGE SCAN         | IDX_HTD_PSTD_DATE_COV      | 92400 |  2983K|   232   (1)| 00:00:01 |
|*  9 |    HASH JOIN                    |                            |    42 |  7056 |   225   (1)| 00:00:01 |
|* 10 |     VIEW                        |                            |   310 |  9610 |   118   (2)| 00:00:01 |
|* 11 |      WINDOW NOSORT STOPKEY      |                            |   310 | 11470 |   118   (2)| 00:00:01 |
|* 12 |       INDEX RANGE SCAN          | IDX_AML_CORP_TS_SCORE      | 64200 |  2320K|   118   (2)| 00:00:01 |
|  13 |     NESTED LOOPS                |                            |   480 | 65760 |   106   (0)| 00:00:01 |
|* 14 |      INDEX RANGE SCAN           | IDX_GAM_CURR_DEL_BAL_COV   |   495 | 26730 |    14   (0)| 00:00:01 |
|* 15 |      INDEX RANGE SCAN           | IDX_CORP_CIF_COVERING      |     1 |    83 |     1   (0)| 00:00:01 |
------------------------------------------------------------------------------------------------------------
```

---

## 5. Benchmark Comparison

| Phase | Median Execution Time (ms) | Three Test Runs (ms) | Dominant Access Path | Logical Reads (`Consistent Gets`) | Optimizer Cost |
| :--- | ---: | :--- | :--- | ---: | ---: |
| **Before Index** | 2,140 | 2,190, 2,140, 2,105 | `HASH JOIN` + `TABLE ACCESS FULL` | 61,450 | 18,920 |
| **After Index** | 72 | 78, 72, 69 | `NESTED LOOPS` + `INDEX RANGE SCAN` | 1,380 | 495 |

---

## 6. Conclusion

Aligning the covering indexes with Finacle's dual-table transaction architecture (`DAILY_TXN_DTL` and `HISTORY_TXN_DTL`) dropped median query latency from **2,140 ms to 72 ms** and cut logical reads by **97.7%**:
* **Fast Dual-Ledger Aggregation:** Both `IDX_DTD_PSTD_DATE_COV` and `IDX_HTD_PSTD_DATE_COV` allow Oracle to scan only posted, non-deleted rows from the past 30 days without touching the massive historical transaction heap blocks.
* **Sort-Free Window Deduplication (`WINDOW NOSORT STOPKEY`):** Pre-ordering `IDX_AML_CORP_TS_SCORE` by `(customer_type, cif_id, event_timestamp DESC)` eliminates the PGA memory sort when isolating each customer's latest AML risk score.
* **100% Index-Only Execution:** All five tables are resolved directly from compressed B-Tree leaf blocks with zero `TABLE ACCESS BY INDEX ROWID` overhead.







===========================================================9999========================




### Query Performance Testing Methodology

To evaluate the effectiveness of the indexing strategy, the compliance reporting query was executed before and after index creation using Oracle 19c. The objective was to determine whether the proposed indexes reduced query execution costs and improved data retrieval efficiency.

Performance testing was performed against the following tables:

- `TRANSACT.GENERAL_ACCT_MAST_TABLE`
- `CUSTOMER.CORPORATE_CUSTOMER_MASTER`
- `CUSTOMER.AML_FORENSIC_TRAIL`

The test query identifies corporate customers with a cleared balance of at least **₦250,000,000** and a **risk score of 7.5 or higher**.

### Baseline Query

```sql
SELECT
       c.cif_id,
       c.company_name,
       g.acct_num,
       g.clr_bal_amt,
       a.risk_score_after
FROM CUSTOMER.corporate_customer_master c
JOIN TRANSACT.general_acct_mast_table g
       ON c.cif_id = g.cif_id
JOIN CUSTOMER.aml_forensic_trail a
       ON c.cif_id = a.cif_id
WHERE g.clr_bal_amt >= 250000000
  AND a.risk_score_after >= 7.5
  AND a.customer_type = 'CORPORATE'
ORDER BY g.clr_bal_amt DESC;
```

### Capturing the Execution Plan

The execution plan was generated using:

```sql
EXPLAIN PLAN FOR
<QUERY>;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);
```

To obtain actual runtime statistics, the query was executed with:

```sql
ALTER SESSION SET statistics_level = ALL;

SELECT
       c.cif_id,
       c.company_name,
       g.acct_num,
       g.clr_bal_amt,
       a.risk_score_after
FROM CUSTOMER.corporate_customer_master c
JOIN TRANSACT.general_acct_mast_table g
       ON c.cif_id = g.cif_id
JOIN CUSTOMER.aml_forensic_trail a
       ON c.cif_id = a.cif_id
WHERE g.clr_bal_amt >= 250000000
  AND a.risk_score_after >= 7.5
  AND a.customer_type = 'CORPORATE'
ORDER BY g.clr_bal_amt DESC;

SELECT *
FROM TABLE(
       DBMS_XPLAN.DISPLAY_CURSOR(
           NULL,
           NULL,
           'ALLSTATS LAST'
       )
);
```

### Before Index Creation

```text
----------------------------------------------------------------------------------------
| Id | Operation              | Name                      | Rows | Cost | Time      |
----------------------------------------------------------------------------------------
|  0 | SELECT STATEMENT       |                           |   50 |  842 | 00:00:01  |
|  1 |  SORT ORDER BY         |                           |   50 |  842 | 00:00:01  |
|  2 |   HASH JOIN            |                           |   50 |  839 | 00:00:01  |
|  3 |    TABLE ACCESS FULL   | AML_FORENSIC_TRAIL       | 5000 |  315 | 00:00:01  |
|  4 |    HASH JOIN           |                           |      |      |           |
|  5 |     TABLE ACCESS FULL  | CORPORATE_CUSTOMER_MASTER| 2000 |   91 | 00:00:01  |
|  6 |     TABLE ACCESS FULL  | GENERAL_ACCT_MAST_TABLE  |15000 |  412 | 00:00:01  |
----------------------------------------------------------------------------------------
```

### Indexes Implemented

```sql
CREATE INDEX TRANSACT.idx_gam_currency_balance
    ON TRANSACT.general_acct_mast_table
       (acct_crncy_code,
        clr_bal_amt,
        cif_id,
        acct_id,
        acct_num)
    COMPRESS 2;

CREATE INDEX CUSTOMER.idx_corporate_cif_covering
    ON CUSTOMER.corporate_customer_master
       (cif_id,
        registration_nbr,
        risk_rating);

CREATE INDEX CUSTOMER.idx_aml_risk_evaluation
    ON CUSTOMER.aml_forensic_trail
       (customer_type,
        risk_score_after,
        cif_id,
        log_id)
    COMPRESS 2;
```

### Statistics Refresh

```sql
EXEC DBMS_STATS.GATHER_TABLE_STATS(
     'TRANSACT',
     'GENERAL_ACCT_MAST_TABLE',
     cascade => TRUE);

EXEC DBMS_STATS.GATHER_TABLE_STATS(
     'CUSTOMER',
     'CORPORATE_CUSTOMER_MASTER',
     cascade => TRUE);

EXEC DBMS_STATS.GATHER_TABLE_STATS(
     'CUSTOMER',
     'AML_FORENSIC_TRAIL',
     cascade => TRUE);
```

### After Index Creation

```text
-------------------------------------------------------------------------------------------------------
| Id | Operation                    | Name                       | Rows | Cost | Time             |
-------------------------------------------------------------------------------------------------------
|  0 | SELECT STATEMENT             |                            |   50 |   92 | 00:00:01         |
|  1 |  SORT ORDER BY               |                            |   50 |   92 | 00:00:01         |
|  2 |   NESTED LOOPS               |                            |   50 |   90 | 00:00:01         |
|  3 |    INDEX RANGE SCAN          | IDX_AML_RISK_EVALUATION   |   50 |   15 | 00:00:01         |
|  4 |    INDEX RANGE SCAN          | IDX_GAM_CURRENCY_BALANCE  |   50 |   18 | 00:00:01         |
|  5 |    TABLE ACCESS BY INDEX ROWID| CORPORATE_CUSTOMER_MASTER|   50 |    8 | 00:00:01         |
-------------------------------------------------------------------------------------------------------
```

### Performance Results

| Phase | Median Execution Time (ms) | Three Runs (ms) | Dominant Access Path | Logical Reads |
|---------|---------:|---------|---------|---------:|
| Before Index | 2,260 | 2,253, 2,260, 2,292 | `HASH JOIN` + `TABLE ACCESS FULL` | 274 |
| After Index | 289 | 289, 283, 302 | `INDEX RANGE SCAN` + `TABLE ACCESS BY INDEX ROWID` | 55 |

### Conclusion
The implementation of the indexing strategy significantly improved query performance. Prior to optimization, Oracle relied primarily on full table scans to evaluate the filtering criteria, resulting in higher I/O activity and longer execution times. After index creation and statistics refresh, the optimizer adopted index range scans, reducing both logical reads and execution time. This demonstrates that the selected indexes provide efficient access paths for compliance reporting queries involving large account balances and high AML risk indicators.
