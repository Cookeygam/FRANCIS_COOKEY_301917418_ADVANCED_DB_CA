-- =============================================================================
-- MIT 8103 | Portfolio 1 | Does the design actually protect the data?
-- Run after schema_DB_design.sql and sample_data.sql, as SYS or SYSTEM.
-- Tests 1 to 7 are SUPPOSED to failed. 
-- Every failed statement changes nothing, so nothing needs cleaning up.
-- =============================================================================
SET DEFINE OFF;
SET SERVEROUTPUT ON;

-- ---------------------------------------------------------------------------
-- A. Inventory: what was built (screenshot these two)
-- ---------------------------------------------------------------------------
SELECT owner, table_name
FROM   dba_tables
WHERE  owner IN ('CUSTOMER','TRANSACT')
ORDER  BY owner, table_name;

SELECT owner, table_name, constraint_type, COUNT(*) AS how_many
FROM   dba_constraints
WHERE  owner IN ('CUSTOMER','TRANSACT')
AND    constraint_type IN ('P','U','R','C')
AND    generated = 'USER NAME'
GROUP  BY owner, table_name, constraint_type
ORDER  BY owner, table_name, constraint_type;

-- ---------------------------------------------------------------------------
-- B. Things the database must refuse
-- ---------------------------------------------------------------------------

-- 1. Same national ID twice (UNIQUE)                          
INSERT INTO CUSTOMER.CUSTOMER_MASTER (CIF_ID, CUSTOMER_TYPE) VALUES ('CIF9001','RETAIL');
INSERT INTO CUSTOMER.RETAIL_CUSTOMER_MASTER
  (CIF_ID, FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, NATIONAL_ID_NBR, ADDRESS_LINE_1, KYC_LEVEL, RISK_RATING, HOME_SOL_ID, CREATED_BY)
VALUES ('CIF9001','Test','Duplicate',DATE '1990-01-01','NIN-1234567890','1 Test Street','Level 1','Low','1001','TESTER');
--output ORA-00001

ROLLBACK;

-- 2. Account for a customer that does not exist (FOREIGN KEY)  
INSERT INTO TRANSACT.GENERAL_ACCT_MAST_TABLE
  (ACCT_ID, ACCT_NUM, CIF_ID, SOL_ID, GL_CODE, PRODUCT_CODE, ACCT_CRNCY_CODE)
VALUES ('ACCT00000099','0123489099','CIF9999','2001','GL101','PRD01','NGN');
--output ORA-02291

-- 3. Non-staff customer given a staff ID (CHECK)               
UPDATE CUSTOMER.RETAIL_CUSTOMER_MASTER SET EMP_ID = '99999' WHERE CIF_ID = 'CIF0001';
--output  ORA-02290

-- 4. Journal line must be a debit or a credit (CHECK)          
INSERT INTO TRANSACT.DAILY_TXN_DTL
  (TXN_ID, TXN_INDEX, ACCT_ID, PART_TRAN_TYPE, TRAN_AMT, TRAN_TYPE, TRAN_SUB_TYPE, VALUE_DATE, TRAN_DATE, ENTRY_USER_ID)
VALUES (9001, 1, 'ACCT00000001', 'X', 100, 'T', 'TRF', DATE '2026-11-10', DATE '2026-11-10', 'INI9083001');
--Output ORA-02290

-- 5. Tamper with the forensic trail (trigger)                 
UPDATE CUSTOMER.AML_FORENSIC_TRAIL SET RISK_SCORE_AFTER = 0 WHERE LOG_ID = 10001;
-- Output ORA-20901

-- 6. Delete from the forensic trail (trigger)                 
DELETE FROM CUSTOMER.AML_FORENSIC_TRAIL WHERE LOG_ID = 10001;
--output  ORA-20901

-- 7. Close an account without a closing date (CHECK)          
UPDATE TRANSACT.GENERAL_ACCT_MAST_TABLE SET ACCT_CLS_FLG = 'Y' WHERE ACCT_ID = 'ACCT00000001';
--output ORA-02290

-- ---------------------------------------------------------------------------
-- B. Things that must be TRUE (should return no rows / the stated answer)
-- ---------------------------------------------------------------------------

-- Every account points at a real customer: expect no rows
SELECT g.acct_id FROM TRANSACT.GENERAL_ACCT_MAST_TABLE g
WHERE  NOT EXISTS (SELECT 1 FROM CUSTOMER.CUSTOMER_MASTER c WHERE c.cif_id = g.cif_id);

-- Balance on the account master equals credits minus debits ever recorded: expect no rows
SELECT acct_id, clr_bal_amt, cum_cr_amt - cum_dr_amt AS from_totals
FROM   TRANSACT.GENERAL_ACCT_MAST_TABLE
WHERE  clr_bal_amt <> cum_cr_amt - cum_dr_amt;

-- The Portfolio compliance query should now return rows
SELECT g.acct_id, c.company_name, g.clr_bal_amt, a.risk_score_after
FROM   TRANSACT.GENERAL_ACCT_MAST_TABLE g
JOIN   CUSTOMER.CORPORATE_CUSTOMER_MASTER c ON c.cif_id = g.cif_id
JOIN   CUSTOMER.AML_FORENSIC_TRAIL a        ON a.cif_id = c.cif_id AND a.customer_type = 'CORPORATE'
WHERE  g.acct_crncy_code = 'NGN' AND g.clr_bal_amt >= 250000000 AND a.risk_score_after >= 7.5
AND    g.del_flg = 'N'
ORDER  BY a.risk_score_after DESC;
