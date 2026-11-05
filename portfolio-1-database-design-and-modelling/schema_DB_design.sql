--  -----------------------------------------------------------
-- To confirm the ORACLE DB version run the below query. image in screenshot section
SELECT * FROM v$version;  
SELECT version FROM v$instance; 
-- Result->> Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
-- -------------------------------------------------------------

-- Create the user/database schema with a password
CREATE USER TRANSACT IDENTIFIED BY "JpmorganChase123$$$#";
CREATE USER CUSTOMER IDENTIFIED BY "Jpmo$ganBANK4560$$#";

-- Grant basic connection and development privileges
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO TRANSACT;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO CUSTOMER;

-- Give the user permission to actually store data on the system
ALTER USER TRANSACT QUOTA 100M ON USERS;
ALTER USER CUSTOMER QUOTA 100M ON USERS;

-- =========================================================================
-- SYSTEM COMPONENT: CUSTOMER INFORMATION FILE (CIF) SUBSYSTEM
-- =========================================================================

CREATE TABLE "CUSTOMER"."RETAIL_CUSTOMER_MASTER" (
    "CIF_ID"           VARCHAR2(10 CHAR),
    "FIRST_NAME"       VARCHAR2(50 CHAR)  NOT NULL,
    "MIDDLE_NAME"      VARCHAR2(50 CHAR),
    "LAST_NAME"        VARCHAR2(50 CHAR),
    "DATE_OF_BIRTH"    DATE               NOT NULL,
    "GENDER"           CHAR(1 CHAR),
    "MARITAL_STATUS"   VARCHAR2(15 CHAR),
    "NATIONAL_ID_NBR"  VARCHAR2(30 CHAR)  NOT NULL,
    "OCCUPATION"       VARCHAR2(50 CHAR),
    "EMPLOYEE_ID"      VARCHAR2(15 CHAR),
    "ADDRESS_LINE_1"   VARCHAR2(100 CHAR) NOT NULL, 
    "ADDRESS_LINE_2"   VARCHAR2(100 CHAR),          
    "KYC_LEVEL"        VARCHAR2(20 CHAR),
    "RISK_RATING"      VARCHAR2(10 CHAR),
    "HOME_SOL_ID"      VARCHAR2(4 CHAR)   NOT NULL,
    "CUST_STATUS"      VARCHAR2(12 CHAR)  NOT NULL,
    "IS_STAFF"         CHAR(5 CHAR)       DEFAULT 'N' NOT NULL,
	"EMP_ID"           CHAR(5 CHAR),
    "CREATED_BY"       VARCHAR2(15 CHAR)  NOT NULL,
    "CREATED_AT"       DATE               DEFAULT SYSDATE NOT NULL,
    "VERIFIED_BY"      VARCHAR2(15 CHAR),
    "LAST_MOD_AT"      DATE               DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_retail_cif PRIMARY KEY ("CIF_ID"),
    CONSTRAINT uq_retail_nin UNIQUE ("NATIONAL_ID_NBR", "CIF_ID"),
    CONSTRAINT chk_is_staff CHECK ("IS_STAFF" IN ('Y', 'N'))
);
-- -------------------------------------------------------------------------------------
--this is for shorter table name
CREATE SYNONYM RETAIL FOR RETAIL_CUSTOMER_MASTER;
-----------------------------------------------------------------------------------------

CREATE TABLE "CUSTOMER"."CORPORATE_CUSTOMER_MASTER" (
    "CIF_ID"           VARCHAR2(10 CHAR),
	"CORP_ID"          VARCHAR2(9 CHAR), NOT NULL,
    "COMPANY_NAME"     VARCHAR2(150 CHAR),
    "TRADE_NAME"       VARCHAR2(150 CHAR),
    "REGISTRATION_NBR" VARCHAR2(50 CHAR)  NOT NULL,
    "DATE_OF_INCORP"   DATE               NOT NULL,
    "BUSINESS_TYPE"    VARCHAR2(30 CHAR),
    "INDUSTRY_SECTION" VARCHAR2(50 CHAR),
    "TAX_ID_NBR"       VARCHAR2(30 CHAR)  NOT NULL,
    "ANNUAL_TURNOVER"  NUMBER(18,2),
    "COUNTRY_OF_REG"   VARCHAR2(3 CHAR)   NOT NULL,
    "KYC_LEVEL"        VARCHAR2(20 CHAR)  NOT NULL,
    "RISK_RATING"      VARCHAR2(10 CHAR),
    "HOME_SOL_ID"           VARCHAR2(4 CHAR)   NOT NULL,
    "CUST_STATUS"      VARCHAR2(12 CHAR)  DEFAULT 'ACTIVE' NOT NULL,
    "WEBSITE"          VARCHAR2(100 CHAR),
    "CREATED_BY"       VARCHAR2(15 CHAR)  NOT NULL,
    "CREATED_AT"       DATE               DEFAULT SYSDATE NOT NULL,
    "VERIFIED_BY"      VARCHAR2(15 CHAR),
    "LAST_MOD_AT"      DATE               DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_corporate_cif PRIMARY KEY ("CIF_ID"),
	CONSTRAINT pk_retail_cif PRIMARY KEY ("CIF_ID"),
    CONSTRAINT uq_retail_nin UNIQUE ("REGISTRATION_NBR", "CORP_ID")
);
-- ---------------------------------------------------------------------
CREATE SYNONYM CORPORATE FOR CORPORATE_CUSTOMER_MASTER;
------------------------------------------------------------------
-- 1. Secure Audit Trail Sequence Allocation
CREATE SEQUENCE "CUSTOMER"."SEQ_AML_FORENSIC_ID" 
    START WITH 100001 
    INCREMENT BY 1 
    NOCACHE 
    NOCYCLE;

CREATE TABLE "CUSTOMER"."AML_FORENSIC_TRAIL" (
    "LOG_ID"               NUMBER(19,0)         NOT NULL,
    "EVENT_TYPE"           VARCHAR2(30 CHAR)    NOT NULL, 
    "CUSTOMER_TYPE"        VARCHAR2(10 CHAR)    NOT NULL, 
    "CIF_ID"               VARCHAR2(15 CHAR)    NOT NULL, 
    "RISK_SCORE_BEFORE"    NUMBER(3,1),                   
    "RISK_SCORE_AFTER"     NUMBER(3,1)          NOT NULL,
    "TERMINAL_ID"          VARCHAR2(16 CHAR)    NOT NULL,
    "IP_ADDRESS"           VARCHAR2(45 CHAR)    NOT NULL, 
    "INITIATOR_USER"       VARCHAR2(30 CHAR)    NOT NULL, -- Maker ID (Front-Office / System App Account)
    "VERIFIER_USER"        VARCHAR2(30 CHAR)    NOT NULL, -- Checker ID (Compliance/ Operations Manager)
    "EVENT_TIMESTAMP"      DATE         DEFAULT SYSDATE NOT NULL,
    "AUDIT_PAYLOAD_CLOB"   CLOB,                          -- Full JSON/XML state diff for granular data forensics
    CONSTRAINT "PK_AML_FORENSIC_TRAIL" PRIMARY KEY ("LOG_ID"),
    CONSTRAINT "CHK_AML_CUST_TYPE" CHECK ("CUSTOMER_TYPE" IN ('RETAIL', 'CORPORATE')),
    CONSTRAINT "CHK_AML_RISK_RANGE" CHECK ("RISK_SCORE_AFTER" BETWEEN 0.0 AND 10.0)
)
TABLESPACE "SECURE_AUDIT_DATA";

-- 3. Production Hardening: High-Throughput Compliance Access Paths
CREATE INDEX "CUSTOMER"."IDX_AML_CIF_LOOKUP" 
    ON "CUSTOMER"."AML_FORENSIC_TRAIL" ("CIF_ID", "CUSTOMER_TYPE");

-- =========================================================================
-- SYSTEM COMPONENT: CORE ACCOUNT GENERAL LEDGER MASTER
-- =========================================================================

CREATE TABLE "TRANSACT"."GENERAL_ACCT_MAST_TABLE" (
    "ACCT_ID"              VARCHAR2(16 CHAR), 
    "ACCT_NUM"             VARCHAR2(34 CHAR)    NOT NULL, 
    "CIF_ID"               VARCHAR2(10 CHAR)    NOT NULL, 
    "SOL_ID"               VARCHAR2(4 CHAR)     NOT NULL, 
    "ENTITY_CRE_FLG"       CHAR(1 BYTE)         DEFAULT 'N' NOT NULL, 
    "DEL_FLG"              CHAR(1 BYTE)         DEFAULT 'N' NOT NULL, 
    "ACCT_NAME"            VARCHAR2(100 CHAR), 
    "GL_CODE"              VARCHAR2(5 CHAR)     NOT NULL, 
    "PRODUCT_CODE"         VARCHAR2(5 CHAR)     NOT NULL, 
    "ACCT_CRNCY_CODE"      VARCHAR2(3 CHAR)     NOT NULL, 
    "ACCT_OPN_DATE"        DATE                 DEFAULT SYSDATE NOT NULL, 
    "ACCT_CLS_FLG"         CHAR(1 BYTE), 
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
    "LIEN_AMT"             NUMBER(20,4)         DEFAULT 0.0000 NOT NULL, 
    CONSTRAINT pk_gam PRIMARY KEY ("ACCT_ID"),
    CONSTRAINT uq_gam_num UNIQUE ("ACCT_NUM"),
    CONSTRAINT fk_gam_cif FOREIGN KEY ("CIF_ID") REFERENCES "CUSTOMER"."RETAIL_CUSTOMER_MASTER"("CIF_ID"),
    CONSTRAINT chk_gam_cls CHECK ("ACCT_CLS_FLG" IN ('Y', 'N'))
);
CREATE SYNONYM GAM FOR "TRANSACT"."GENERAL_ACCT_MAST_TABLE";

-- Performance Access Path Design (FK Indexing prevents full table scans on parent update/delete)
CREATE INDEX "TRANSACT"."IDX_GAM_CIF_FK" ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" ("CIF_ID");
CREATE INDEX "TRANSACT"."IDX_GAM_SOL_CRNCY" ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" ("SOL_ID", "ACCT_CRNCY_CODE");

-- 3. Security Role & Object Privilege Matrix (Support and Application layers)
GRANT SELECT ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "SUPPORTUSER";
GRANT READ ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT REFERENCES ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT ON COMMIT REFRESH ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT QUERY REWRITE ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT DEBUG ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT FLASHBACK ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
GRANT SELECT, READ, UPDATE, INSERT, ALTER, DELETE ON "TRANSACT"."GENERAL_ACCT_MAST_TABLE" TO "APPUSER";
-- -------------------------------------------------------------------------------------
--this is for shorter table name
CREATE SYNONYM GAM FOR GENERAL_ACCT_MAST_TABLE;

-- =========================================================================
-- SYSTEM COMPONENT: DAILY TRANSACTION DETAIL (JOURNAL LEDGER)
-- =========================================================================

CREATE TABLE "TRANSACT"."DAILY_TXN_DTL" (
    "TXN_ID"             NUMBER(9)	   GENERATED BY DEFAULT AS IDENTITY MINVALUE 1 MAXVALUE 999999999999999 INCREMENT BY 4 START WITH 1 CACHE 20 NOORDER NOCYCLE,
    "TXN_INDEX"          NUMBER(5,0)          NOT NULL,
    "ACCT_ID"            VARCHAR2(16 CHAR)    NOT NULL,
    "PART_TRAN_TYPE"     CHAR(1 BYTE)         NOT NULL,
    "TRAN_AMT"           NUMBER(20,4)         DEFAULT 0.0000 NOT NULL,
    "TRAN_TYPE"          CHAR(1 BYTE)         NOT NULL,
    "TRAN_SUB_TYPE"      VARCHAR2(5 CHAR)     NOT NULL,
    "TRAN_PARTICULAR"    VARCHAR2(50 CHAR),
    "VALUE_DATE"         DATE                 NOT NULL,
    "TRAN_DATE"          DATE                 NOT NULL,
    "INSTRM_TYPE"        VARCHAR2(5 CHAR),
    "INSTRM_NUM"         VARCHAR2(12 CHAR),
    "ENTRY_USER_ID"      VARCHAR2(15 CHAR)    NOT NULL,
    "PSTD_USER_ID"       VARCHAR2(15 CHAR),
    "ENTRY_DATE"         DATE                 DEFAULT SYSDATE NOT NULL,
    "PSTD_DATE"          DATE,
    "PSTD_FLG"           CHAR(1 BYTE),
    CONSTRAINT "PK_DAILY_TXN_DTL" PRIMARY KEY ("TXN_ID", "TXN_INDEX"),
    CONSTRAINT "FK_DTD_GAM" FOREIGN KEY ("ACCT_ID") REFERENCES "TRANSACT"."GENERAL_ACCT_MAST_TABLE"("ACCT_ID"),
    CONSTRAINT "CHK_DTD_PART_TRAN_TYPE" CHECK ("PART_TRAN_TYPE" IN ('D','C')),
);

CREATE SYNONYM DTD FOR "TRANSACT"."DAILY_TXN_DTL";

-- Ledger Tuning Access Paths
CREATE INDEX "TRANSACT"."IDX_DTD_ACCT_FK" ON "TRANSACT"."DAILY_TXN_DTL" ("ACCT_ID");
CREATE INDEX "TRANSACT"."IDX_DTD_VAL_DATE_REC" ON "TRANSACT"."DAILY_TXN_DTL" ("VALUE_DATE", "TRAN_DATE");
CREATE INDEX "TRANSACT"."IDX_DTD_POST_QUEUE" ON "TRANSACT"."DAILY_TXN_DTL" ("PSTD_FLG", "ENTRY_DATE");

-- Object Privilege Mapping Execution
GRANT SELECT, READ, UPDATE, INSERT ON "TRANSACT"."DAILY_TXN_DTL" TO "APPUSER";
GRANT SELECT ON "TRANSACT"."DAILY_TXN_DTL" TO "SUPPORTUSER";
GRANT REFERENCES ON "TRANSACT"."DAILY_TXN_DTL" TO "APPUSER";
GRANT ON COMMIT REFRESH ON "TRANSACT"."DAILY_TXN_DTL" TO "APPUSER";
GRANT QUERY REWRITE ON "TRANSACT"."DAILY_TXN_DTL" TO "APPUSER";
GRANT DEBUG ON "TRANSACT"."DAILY_TXN_DTL" TO "APPUSER";
