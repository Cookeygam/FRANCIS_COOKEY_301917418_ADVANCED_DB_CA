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

| Phase | Median Execution Time (ms) | Three Runs (ms) | Dominant Access Path | Consistent Gets |
|---------|---------:|---------|---------|---------:|
| Before Index | 2,260 | 2,253, 2,260, 2,292 | `HASH JOIN` + `TABLE ACCESS FULL` | 274 |
| After Index | 289 | 289, 283, 302 | `INDEX RANGE SCAN` + `TABLE ACCESS BY INDEX ROWID` | 55 |

### Conclusion

The implementation of the indexing strategy significantly improved query performance. Prior to optimization, Oracle relied primarily on full table scans to evaluate the filtering criteria, resulting in higher I/O activity and longer execution times. After index creation and statistics refresh, the optimizer adopted index range scans, reducing both logical reads and execution time. This demonstrates that the selected indexes provide efficient access paths for compliance reporting queries involving large account balances and high AML risk indicators.
