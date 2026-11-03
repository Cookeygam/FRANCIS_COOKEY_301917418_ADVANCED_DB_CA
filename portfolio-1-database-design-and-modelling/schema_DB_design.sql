--  -----------------------------------------------------------
-- To confirm the ORACLE DB version run the below query. image in screenshot section
SELECT * FROM v$version;  
SELECT version FROM v$instance; 
-- Result->> Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
-- -------------------------------------------------------------

-- Create the user/database schema with a password
CREATE USER TRANSACT IDENTIFIED BY "JpmorganChase123$$$#";
CREATE USER CUSTOMER IDENTIFIED BY "Jpmo@ganBANK1230$$#";

-- Grant basic connection and development privileges
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO TRANSACT;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO CUSTOMER;

-- Give the user permission to actually store data on the system
ALTER USER TRANSACT QUOTA UNLIMITED ON USERS;
ALTER USER CUSTOMER QUOTA UNLIMITED ON USERS;

-- =========================================================================
-- SYSTEM COMPONENT: CORE TRANSACTIONS SCHEMA
-- OBJECT TYPE     : BASE RELATIONAL TABLE, INDEXES, AND OBJECT PRIVILEGES
-- DESIGN PATTERN  : UNIFIED ACCOUNT GENERAL LEDGER MASTER 
-- =========================================================================
-- 1. Base Table Definition
CREATE TABLE "TRANSACT"."GENERAL_ACCT_MAST_TABLE" (
    "ACCT_ID"              VARCHAR2(11 CHAR), 
    "ENTITY_CRE_FLG"       CHAR(1 BYTE), 
    "DEL_FLG"              CHAR(1 BYTE), 
    "SOL_ID"               VARCHAR2(4 CHAR)     NOT NULL, 
    "ACCT_NUM"              VARCHAR2(34 CHAR)    NOT NULL, 
    "ACCT_NAME"            VARCHAR2(80 CHAR)    NOT NULL, 
    "CUST_ID"              VARCHAR2(10 CHAR)     NOT NULL, 
    "GL_CODE"    		   VARCHAR2(5 CHAR)     NOT NULL, 
    "PRODUCT_CODE"         VARCHAR2(5 CHAR)     NOT NULL, 
    "ACCT_OPN_DATE"        DATE                 DEFAULT SYSDATE NOT NULL, 
    "ACCT_CLS_FLG"         CHAR(1 BYTE)         DEFAULT 'N', 
    "ACCT_CLS_DATE"        DATE, 
    "CLR_BAL_AMT"          NUMBER(20,4)         DEFAULT 0.0000 NOT NULL, 
    "UN_CLR_BAL_AMT"       NUMBER(20,4)         DEFAULT 0.0000 NOT NULL, 
    "SYSTEM_RESERVED_AMT"  NUMBER(20,4)         DEFAULT 0.0000 NOT NULL,  
    "XFER_DR_EXCP_AMT_LIM" NUMBER(20,4),
    "XFER_CR_EXCP_AMT_LIM" NUMBER(20,4),	
    "CASH_CR_EXCP_AMT_LIM" NUMBER(20,4),
    "CASH_DR_EXCP_AMT_LIM" NUMBER(20,4), 	
    "CUM_DR_AMT"           NUMBER(25,4)         DEFAULT 0.0000, 
    "CUM_CR_AMT"           NUMBER(25,4)         DEFAULT 0.0000, 
    "LAST_TRAN_DATE"       DATE, 
    "RCRE_TIME"            DATE                 DEFAULT SYSDATE NOT NULL, 
    "ACCT_CRNCY_CODE"      VARCHAR2(3 CHAR)     NOT NULL, 
    "LIEN_AMT"             NUMBER(20,4)         DEFAULT 0.0000 NOT NULL, 
    CONSTRAINT pk_gam PRIMARY KEY (ACID),
    CONSTRAINT uq_gam_foracid UNIQUE (FORACID),
    CONSTRAINT fk_gam_cmg FOREIGN KEY (CUST_ID) REFERENCES "CUSTOMER"."RETAIL_CUSTOMER_MASTER"(CUST_ID)
);

-- 2. Performance & Query Optimization Access Paths
CREATE INDEX "TRANSACT"."IDX_GAM_BACID_SOL_CRNCY" 
ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" ("CUST_ID", "ACCT_CRNCY_CODE", "SOL_ID", "ACCT_NUM");
CREATE INDEX "TRANSACT"."IDX_GAM_ACCT" 
ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" ("CUST_ID", "ACCT_ID", "SOL_ID", "ACCT_NUM");

-- 3. Security Role & Object Privilege Matrix (Support and Application layers)
GRANT SELECT ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "SUPPORTUSER";
GRANT READ ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT REFERENCES ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT ON COMMIT REFRESH ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT QUERY REWRITE ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT DEBUG ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT FLASHBACK ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT UPDATE ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT INSERT ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER" WITH GRANT OPTION;
GRANT ALTER ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER" WITH GRANT OPTION;
GRANT DELETE ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER" WITH GRANT OPTION;
-- -------------------------------------------------------------------------------------
--this is for shorter table name
CREATE SYNONYM GAM FOR GENERAL_ACCT_MAST_TABLE;
-----------------------------------------------------------------------------------------

-- =========================================================================
-- SYSTEM COMPONENT : DAILY TRANSACTION DETAIL 
-- OBJECT TYPE      : Base Relational Transaction Ledger
-- DESIGN PATTERN   : Double-Entry Journal Transaction Leg Storage
-- =========================================================================

CREATE TABLE "TRANSACT"."DAILY_TXN_DTL" (
    "TXN_ID"             VARCHAR2(16 CHAR)    NOT NULL,
    "TXN_INDEX"          NUMBER(5,0)          NOT NULL,
	"TRAN_DATE"         DATE                 NOT NULL,
    "ACCT_ID"            VARCHAR2(11 CHAR)    NOT NULL,
    "SOL_ID"             VARCHAR2(4 CHAR)     NOT NULL,
    "PART_TRAN_TYPE"     CHAR(1 BYTE)         NOT NULL,
    "TRAN_AMT"           NUMBER(20,4)         DEFAULT 0.0000 NOT NULL,
    "TRAN_CRNCY_CODE"    VARCHAR2(3 CHAR)     NOT NULL,
    "TRAN_TYPE"          CHAR(1 BYTE)         NOT NULL,
    "TRAN_SUB_TYPE"      VARCHAR2(5 CHAR)     NOT NULL,
    "TRAN_PARTICULAR"    VARCHAR2(50 CHAR)    NOT NULL,
    "VALUE_DATE"         DATE                 NOT NULL,
    "INSTRM_TYPE"        VARCHAR2(5 CHAR),
    "INSTRM_NUM"         VARCHAR2(12 CHAR),
    "ENTRY_USER_ID"      VARCHAR2(15 CHAR)    NOT NULL,
    "PSTD_USER_ID"       VARCHAR2(15 CHAR),
    "ENTRY_DATE"         DATE DEFAULT SYSDATE NOT NULL,
    "PSTD_DATE"          DATE,
    "PSTD_FLG"           CHAR(1 BYTE)         DEFAULT 'E' NOT NULL,
    
    CONSTRAINT "PK_DAILY_TXN_DTL" PRIMARY KEY ("TXN_ID", "TXN_INDEX"),
    CONSTRAINT "FK_DTD_GAM" FOREIGN KEY ("ACCT_ID") 
        REFERENCES "TRANSACT"."GENERAL_ACCT_MAST_TABLE"("ACCT_ID"),
    CONSTRAINT "CHK_DTD_PART_TRAN_TYPE" CHECK ("PART_TRAN_TYPE" IN ('D','C')),
    CONSTRAINT "CHK_DTD_TRAN_TYPE" CHECK ("TRAN_TYPE" IN ('C','T','M')),
);

-- =========================================================================
-- PERFORMANCE OPTIMIZATION ACCESS PATHWAYS
-- =========================================================================

-- Rapid end-of-day trial balance verification and ledger reconciliation
CREATE INDEX "TRANSACT"."IDX_DTD_ACCT_ID_VALUE_DT" 
    ON "TRANSACT"."DAILY_TXN_DTL" ("ACID", "VALUE_DATE","TRAN_DATE");

-- Teller/Branch balancing queues for pending unposted transactions
CREATE INDEX "TRANSACT"."IDX_DTD_SOL_PSTD_FLG" 
    ON "TRANSACT"."DAILY_TXN_DTL" ("SOL_ID", "PSTD_FLG");

-- -------------------------------------------------------------------------------------
--this is for shorter table name
CREATE SYNONYM DTD FOR DAILY_TXN_DTL;
-----------------------------------------------------------------------------------------

-- =========================================================================
-- MODULE 1: CUSTOMER INFORMATION FILE (CIF) SUBSYSTEM
-- =========================================================================

CREATE TABLE "CUSTOMER"."RETAIL_CUSTOMER_MASTER" (
    "CUST_ID"          VARCHAR2(10 CHAR),
	"CIF_ID"          VARCHAR2(10 CHAR),
    "FIRST_NAME"       VARCHAR2(50 CHAR)  NOT NULL,
    "MIDDLE_NAME"      VARCHAR2(50 CHAR),
    "LAST_NAME"        VARCHAR2(50 CHAR)  NOT NULL,
    "DATE_OF_BIRTH"    DATE               NOT NULL,
    "GENDER"           CHAR(1 CHAR)       NOT NULL,
    "MARITAL_STATUS"   VARCHAR2(15 CHAR),
    "NATIONAL_ID_NBR"  VARCHAR2(30 CHAR)  NOT NULL,
    "OCCUPATION"       VARCHAR2(50 CHAR),
	"EMP_ID"         	VARCHAR2(9 CHAR) NOT NULL,
    "ADDRESS_LINE_1"   NUMBER(15,2),
    "ADDRESS_LINE_2"   NUMBER(15,2),
    "KYC_LEVEL"        VARCHAR2(20 CHAR)  NOT NULL,
    "RISK_RATING"      VARCHAR2(10 CHAR),
    "SOL_ID"           VARCHAR2(4 CHAR)   NOT NULL,
    "CUST_STATUS"      VARCHAR2(12 CHAR),
    "IS_STAFF"         CHAR(1 CHAR)       DEFAULT 'N' NOT NULL,
    "EMP_ID"           CHAR(1 CHAR),
    "CREATED_BY"       VARCHAR2(15 CHAR)  NOT NULL,
    "CREATED_AT"       DATE               DEFAULT SYSDATE NOT NULL,
    "VERIFIED_BY"      VARCHAR2(15 CHAR),
    "LAST_MOD_AT"      DATE               DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_retail_cif PRIMARY KEY ("CIF_ID"),
    CONSTRAINT chk_retail_gender CHECK ("GENDER" IN ('M', 'F', 'O')),
    CONSTRAINT chk_retail_staff CHECK ("IS_STAFF" IN ('Y', 'N'))
);
-- -------------------------------------------------------------------------------------
--this is for shorter table name
CREATE SYNONYM RETAIL FOR RETAIL_CUSTOMER_MASTER;
-----------------------------------------------------------------------------------------

CREATE TABLE "CUSTOMER"."CORPORATE_CUSTOMER_MASTER" (
    "CUST_ID"          VARCHAR2(9 CHAR),
    "CIF_ID"           VARCHAR2(10 CHAR),
    "COMPANY_NAME"     VARCHAR2(150 CHAR) NOT NULL,
    "TRADE_NAME"       VARCHAR2(150 CHAR),
    "REGISTRATION_NBR" VARCHAR2(50 CHAR)  NOT NULL,
    "DATE_OF_INCORP"   DATE               NOT NULL,
    "BUSINESS_TYPE"    VARCHAR2(30 CHAR)  NOT NULL,
    "INDUSTRY_SECTION" VARCHAR2(50 CHAR)  NOT NULL,
    "TAX_ID_NBR"       VARCHAR2(30 CHAR)  NOT NULL,
    "ANNUAL_TURNOVER"  NUMBER(18,2),
    "COUNTRY_OF_REG"   VARCHAR2(3 CHAR)   NOT NULL,
    "KYC_LEVEL"        VARCHAR2(20 CHAR)  NOT NULL,
    "RISK_RATING"      VARCHAR2(10 CHAR)  DEFAULT 'LOW' NOT NULL,
    "SOL_ID"           VARCHAR2(4 CHAR)   NOT NULL,
    "CUST_STATUS"      VARCHAR2(12 CHAR)  DEFAULT 'ACTIVE' NOT NULL,
    "WEBSITE"          VARCHAR2(100 CHAR),
    "CREATED_BY"       VARCHAR2(15 CHAR)  NOT NULL,
    "CREATED_AT"       DATE               DEFAULT SYSDATE NOT NULL,
    "VERIFIED_BY"      VARCHAR2(15 CHAR),
    "LAST_MOD_AT"      DATE               DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_corporate_cif PRIMARY KEY ("CIF_ID")
);
-- -------------------------------------------------------------------------------------
--this is for shorter table name
CREATE SYNONYM CORPORATE FOR CORPORATE_CUSTOMER_MASTER;
-----------------------------------------------------------------------------------------
-- ------------------------------------------------------------
-- EMPLOYMENT_HISTORY
-- ------------------------------------------------------------
CREATE TABLE "CUSTOMER"."EMPLOYMENT_HISTORY" (
    "HISTORY_ID"    NUMBER GENERATED BY DEFAULT AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE,
    "CUST_ID"       VARCHAR2(10 CHAR) NOT NULL,
	"EMP_ID"       VARCHAR2(9 CHAR) NOT NULL,
    "EVENT_TYPE"    VARCHAR2(20 CHAR) NOT NULL,
    "EVENT_DATE"    DATE DEFAULT SYSDATE NOT NULL,
    "PROCESSED_BY"  VARCHAR2(60 CHAR) NOT NULL,
    CONSTRAINT pk_employment_history PRIMARY KEY ("HISTORY_ID"),
    CONSTRAINT chk_event_type CHECK ("EVENT_TYPE" IN ('onboarding', 'promotion', 'transfer', 'resignation', 'suspension')),
    CONSTRAINT fk_history_retail_cust FOREIGN KEY ("CUST_ID") REFERENCES "TRANSACT"."RETAIL_CUSTOMER_MASTER"("CUST_ID")
);



