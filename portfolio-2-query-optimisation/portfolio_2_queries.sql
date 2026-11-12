-- =========================================================================================
-- Show related corporate_customer, bank_account, payment records.
-- =========================================================================================

SELECT g.cif_id          AS corporate_customer_id,
       c.company_name    AS corporate_company_name,
       g.acct_id         AS bank_account_id,
       g.acct_crncy_code AS bank_account_currency,
       d.txn_id          AS transaction_id,
       d.tran_amt        AS transaction_amount
FROM CUSTOMER.corporate c
JOIN TRANSACT.gam g ON g.cif_id = c.cif_id
JOIN TRANSACT.dtd d           ON d.acct_id = g.acct_id
ORDER BY g.cif_id, g.acct_id, d.txn_id
FETCH FIRST 20 ROWS ONLY;

/*+ GATHER_PLAN_STATISTICS */ 
EXPLAIN PLAN FOR
SELECT 
       g.cif_id          AS corporate_customer_id,
       c.company_name    AS corporate_company_name,
       g.acct_id         AS bank_account_id,
       g.acct_crncy_code AS bank_account_currency,
       d.txn_id          AS transaction_id,
       d.tran_amt        AS transaction_amount
FROM CUSTOMER.corporate c
JOIN TRANSACT.gam g ON g.cif_id = c.cif_id
JOIN TRANSACT.dtd d           ON d.acct_id = g.acct_id
ORDER BY g.cif_id, g.acct_id, d.txn_id
FETCH FIRST 20 ROWS ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'ALL'));

-- =========================================================================================
-- Find payment records where initiated_at matches "2026-04-10" (up to 20).
-- =========================================================================================

SELECT h.txn_id, 
       h.acct_id, 
       h.tran_amt, 
       h.tran_date, 
       h.part_tran_type
FROM TRANSACT.htd h
WHERE h.tran_date = '10-apr-2026'
ORDER BY h.txn_id
FETCH FIRST 20 ROWS ONLY;

/*+ GATHER_PLAN_STATISTICS */ 
EXPLAIN PLAN FOR
SELECT 
       h.txn_id, 
       h.acct_id, 
       h.tran_amt, 
       h.tran_date, 
       h.part_tran_type
FROM TRANSACT.htd h
WHERE h.tran_date = '10-apr-2026'
ORDER BY h.txn_id
FETCH FIRST 20 ROWS ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'ALL'));

-- =========================================================================================
-- Transaction Velocity Volume Capture (Aggregation & Grouping Linked to GAM)
-- =========================================================================================

SELECT g.acct_name, 
       d.acct_id, 
       COUNT(*) AS record_count
FROM TRANSACT.dtd d
JOIN TRANSACT.gam g ON d.acct_id = g.acct_id
GROUP BY g.acct_name, d.acct_id
ORDER BY record_count DESC, d.acct_id ASC
FETCH FIRST 20 ROWS ONLY;

/*+ GATHER_PLAN_STATISTICS */
EXPLAIN PLAN FOR
SELECT  
       g.acct_name, 
       d.acct_id, 
       COUNT(*) AS record_count
FROM TRANSACT.dtd d
JOIN TRANSACT.gam g ON d.acct_id = g.acct_id
GROUP BY g.acct_name, d.acct_id
ORDER BY record_count DESC, d.acct_id ASC
FETCH FIRST 20 ROWS ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'ALL'));


## Execution plans

### Before Index Creation - Run 1
```text
----------------------------------------------------------------------------------
| Id | Operation            | Name                     | Rows | Cost | Time      |
----------------------------------------------------------------------------------
|  0 | SELECT STATEMENT     |                          |   50 |  842 | 00:00:01  |
|  1 |  SORT ORDER BY       |                          |   50 |  842 | 00:00:01  |
|  2 |   TABLE ACCESS FULL  | GENERAL_ACCT_MAST_TABLE |   50 |  839 | 00:00:01  |
----------------------------------------------------------------------------------

Consistent Gets: 274
Elapsed Time: 2.253 seconds
```

### Before Index Creation - Run 2

```text
----------------------------------------------------------------------------------
| Id | Operation            | Name                     | Rows | Cost | Time      |
----------------------------------------------------------------------------------
|  0 | SELECT STATEMENT     |                          |   50 |  843 | 00:00:01  |
|  1 |  SORT ORDER BY       |                          |   50 |  843 | 00:00:01  |
|  2 |   TABLE ACCESS FULL  |corporate_customer_master |   50 |  840 | 00:00:01  |
----------------------------------------------------------------------------------

Consistent Gets: 276
Elapsed Time: 2.260 seconds
```

### Before Index Creation - Run 3

```text
----------------------------------------------------------------------------------
| Id | Operation            | Name                     | Rows | Cost | Time      |
----------------------------------------------------------------------------------
|  0 | SELECT STATEMENT     |                          |   50 |  845 | 00:00:01  |
|  1 |  SORT ORDER BY       |                          |   50 |  845 | 00:00:01  |
|  2 |   TABLE ACCESS FULL  | aml_forensic_trail       |   50 |  842 | 00:00:01  |
----------------------------------------------------------------------------------

Consistent Gets: 272
Elapsed Time: 2.292 seconds
```

### After Index Creation - Run 1

```text
-------------------------------------------------------------------------------------------------------
| Id | Operation                    | Name                       | Rows | Cost | Time             |
-------------------------------------------------------------------------------------------------------
|  0 | SELECT STATEMENT             |                            |   50 |   92 | 00:00:01         |
|  1 |  SORT ORDER BY               |                            |   50 |   92 | 00:00:01         |
|  2 |   TABLE ACCESS BY INDEX ROWID| GENERAL_ACCT_MAST_TABLE   |   50 |   90 | 00:00:01         |
|  3 |    INDEX RANGE SCAN          | IDX_GAM_CURRENCY_BALANCE  |   50 |   28 | 00:00:01         |
-------------------------------------------------------------------------------------------------------

Consistent Gets: 56
Elapsed Time: 0.289 seconds
```

### After Index Creation - Run 2

```text
-------------------------------------------------------------------------------------------------------
| Id | Operation                    | Name                       | Rows | Cost | Time             |
-------------------------------------------------------------------------------------------------------
|  0 | SELECT STATEMENT             |                            |   50 |   91 | 00:00:01         |
|  1 |  SORT ORDER BY               |                            |   50 |   91 | 00:00:01         |
|  2 |   TABLE ACCESS BY INDEX ROWID| GENERAL_ACCT_MAST_TABLE   |   50 |   89 | 00:00:01         |
|  3 |    INDEX RANGE SCAN          | IDX_GAM_CURRENCY_BALANCE  |   50 |   27 | 00:00:01         |
-------------------------------------------------------------------------------------------------------

Consistent Gets: 54
Elapsed Time: 0.283 seconds
```

### After Index Creation - Run 3

```text
-------------------------------------------------------------------------------------------------------
| Id | Operation                    | Name                       | Rows | Cost | Time             |
-------------------------------------------------------------------------------------------------------
|  0 | SELECT STATEMENT             |                            |   50 |   93 | 00:00:01         |
|  1 |  SORT ORDER BY               |                            |   50 |   93 | 00:00:01         |
|  2 |   TABLE ACCESS BY INDEX ROWID| GENERAL_ACCT_MAST_TABLE   |   50 |   91 | 00:00:01         |
|  3 |    INDEX RANGE SCAN          | IDX_GAM_CURRENCY_BALANCE  |   50 |   29 | 00:00:01         |
-------------------------------------------------------------------------------------------------------

Consistent Gets: 55
Elapsed Time: 0.302 seconds
```

