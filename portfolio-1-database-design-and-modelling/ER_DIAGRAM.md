# JP Morgan Chase Commercial Banking Ledger — ER diagram

```mermaid
erDiagram
    CUSTOMER_RETAIL_CUSTOMER_MASTER {
        varchar2 CIF_ID PK
        varchar2 FIRST_NAME NN
        varchar2 MIDDLE_NAME
        varchar2 LAST_NAME
        date DATE_OF_BIRTH NN
        char GENDER
        varchar2 MARITAL_STATUS
        varchar2 NATIONAL_ID_NBR NN
        varchar2 OCCUPATION
        varchar2 EMPLOYEE_ID
        varchar2 ADDRESS_LINE_1 NN
        varchar2 ADDRESS_LINE_2
        varchar2 KYC_LEVEL
        varchar2 RISK_RATING
        varchar2 HOME_SOL_ID NN
        varchar2 CUST_STATUS NN
        char IS_STAFF NN
        char EMP_ID
        varchar2 CREATED_BY NN
        date CREATED_AT NN
        varchar2 VERIFIED_BY
        date LAST_MOD_AT NN
    }

    CUSTOMER_CORPORATE_CUSTOMER_MASTER {
        varchar2 CIF_ID FK
        varchar2 CORP_ID PK
        varchar2 COMPANY_NAME
        varchar2 TRADE_NAME
        varchar2 REGISTRATION_NBR NN
        date DATE_OF_INCORP NN
        varchar2 BUSINESS_TYPE
        varchar2 INDUSTRY_SECTION
        varchar2 TAX_ID_NBR NN
        number ANNUAL_TURNOVER
        varchar2 COUNTRY_OF_REG NN
        varchar2 KYC_LEVEL NN
        varchar2 RISK_RATING
        varchar2 HOME_SOL_ID NN
        varchar2 CUST_STATUS NN
        varchar2 WEBSITE
        varchar2 CREATED_BY NN
        date CREATED_AT NN
        varchar2 VERIFIED_BY
        date LAST_MOD_AT NN
    }

    CUSTOMER_AML_FORENSIC_TRAIL {
        number CIF_ID FK
        varchar2 EVENT_TYPE NN
        varchar2 CUSTOMER_TYPE NN
        varchar2 LOG_ID PK
        number RISK_SCORE_BEFORE
        number RISK_SCORE_AFTER NN
        varchar2 TERMINAL_ID NN
        varchar2 IP_ADDRESS NN
        varchar2 INITIATOR_USER NN
        varchar2 VERIFIER_USER NN
        date EVENT_TIMESTAMP NN
        clob AUDIT_PAYLOAD_CLOB
    }

    TRANSACT_GENERAL_ACCT_MAST_TABLE {
        varchar2 ACCT_ID FK
        varchar2 ACCT_NUM PK
        varchar2 CIF_ID NN
        varchar2 SOL_ID NN
        char ENTITY_CRE_FLG NN
        char DEL_FLG NN
        varchar2 ACCT_NAME
        varchar2 GL_CODE NN
        varchar2 PRODUCT_CODE NN
        varchar2 ACCT_CRNCY_CODE NN
        date ACCT_OPN_DATE NN
        char ACCT_CLS_FLG
        date ACCT_CLS_DATE
        number CLR_BAL_AMT NN
        number UN_CLR_BAL_AMT NN
        number SYSTEM_RESERVED_AMT NN
        number XFER_DR_EXCP_AMT_LIM
        number XFER_CR_EXCP_AMT_LIM
        number CASH_CR_EXCP_AMT_LIM
        number CASH_DR_EXCP_AMT_LIM
        number CUM_DR_AMT
        number CUM_CR_AMT
        date LAST_TRAN_DATE
        date RCRE_TIME NN
        number LIEN_AMT NN
    }

    TRANSACT_DAILY_TXN_DTL {
        number TXN_ID PK
        varchar2 ACCT_ID PK
        number TXN_INDEX NN
        char PART_TRAN_TYPE NN
        number TRAN_AMT NN
        char TRAN_TYPE NN
        varchar2 TRAN_SUB_TYPE NN
        varchar2 TRAN_PARTICULAR
        date VALUE_DATE NN
        date TRAN_DATE NN
        varchar2 INSTRM_TYPE
        varchar2 INSTRM_NUM
        varchar2 ENTRY_USER_ID NN
        varchar2 PSTD_USER_ID
        sysdate ENTRY_DATE NN
        date PSTD_DATE
        char PSTD_FLG
    }

    CUSTOMER_RETAIL_CUSTOMER_MASTER ||--o{ TRANSACT_GENERAL_ACCT_MAST_TABLE : "Has accounts"
    CUSTOMER_CORPORATE_CUSTOMER_MASTER ||--o{ TRANSACT_GENERAL_ACCT_MAST_TABLE : "Has accounts"
    CUSTOMER_RETAIL_CUSTOMER_MASTER ||--o{ CUSTOMER_AML_FORENSIC_TRAIL : "audited"
    CUSTOMER_CORPORATE_CUSTOMER_MASTER ||--o{ CUSTOMER_AML_FORENSIC_TRAIL : "audited"
    TRANSACT_GENERAL_ACCT_MAST_TABLE ||--o{ TRANSACT_DAILY_TXN_DTL : "records"
```

[Diagram image](../images/ER_Diagram.png)

PK identifies a record; FK links to another table; UK marks a single-field unique value. The relationship ends show exactly one, zero or one, or zero or many records. Composite unique keys and conditional rules are listed in the schema and design.

