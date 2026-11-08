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
-- Find payment records where initiated_at matches "2026-04-10 09:30:00" (up to 20).
-- =========================================================================================

SELECT h.txn_id, 
       h.acct_id, 
       h.tran_amt, 
       h.tran_date, 
       h.part_tran_type
FROM TRANSACT.htd h
WHERE h.tran_date = TO_DATE('2026-04-10 09:30:00', 'YYYY-MM-DD HH24:MI:SS')
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
WHERE h.tran_date = TO_DATE('2026-04-10 09:30:00', 'YYYY-MM-DD HH24:MI:SS')
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
