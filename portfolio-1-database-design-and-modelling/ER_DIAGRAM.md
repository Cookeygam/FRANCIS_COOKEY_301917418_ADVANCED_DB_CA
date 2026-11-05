
# JP Morgan Chase Commercial Banking Ledger — ER Diagram
 summarized ER_diagram view the image link [Diagram image](../images/ER_Diagram.png)

```mermaid
erDiagram

    CUSTOMER_RETAIL {
        varchar CIF_ID PK
        varchar FIRST_NAME
        varchar LAST_NAME
        date DATE_OF_BIRTH
        varchar NATIONAL_ID_NBR
        varchar OCCUPATION
        varchar KYC_LEVEL
        varchar RISK_RATING
        varchar CUST_STATUS
    }

    CUSTOMER_CORPORATE {
        varchar CORP_ID PK
        varchar CIF_ID FK
        varchar COMPANY_NAME
        varchar REGISTRATION_NBR
        date DATE_OF_INCORP
        varchar BUSINESS_TYPE
        varchar TAX_ID_NBR
        varchar COUNTRY_OF_REG
        varchar KYC_LEVEL
        varchar RISK_RATING
        varchar CUST_STATUS
    }

    AML_FORENSIC_TRAIL {
        varchar LOG_ID PK
        varchar CIF_ID FK
        varchar CUSTOMER_TYPE
        varchar EVENT_TYPE
        number RISK_SCORE_BEFORE
        number RISK_SCORE_AFTER
        date EVENT_TIMESTAMP
    }

    ACCOUNT {
        varchar ACCT_NUM PK
        varchar CIF_ID FK
        varchar PRODUCT_CODE
        varchar GL_CODE
        varchar ACCT_CRNCY_CODE
        date ACCT_OPN_DATE
        number CLR_BAL_AMT
        number LIEN_AMT
        date LAST_TRAN_DATE
    }

    TRANSACTION {
        number TXN_ID PK
        varchar ACCT_NUM FK
        number TRAN_AMT
        char TRAN_TYPE
        varchar TRAN_SUB_TYPE
        date VALUE_DATE
        date TRAN_DATE
        varchar INSTRM_TYPE
    }

    CUSTOMER_RETAIL ||--o{ ACCOUNT : owns
    CUSTOMER_CORPORATE ||--o{ ACCOUNT : owns

    CUSTOMER_RETAIL ||--o{ AML_FORENSIC_TRAIL : audited
    CUSTOMER_CORPORATE ||--o{ AML_FORENSIC_TRAIL : audited

    ACCOUNT ||--o{ TRANSACTION : records
```

### Notes

- **PK** = Primary Key
- **FK** = Foreign Key
- A **Customer** (Retail or Corporate) may own multiple **Accounts**.
- An **Account** may have many **Transactions**.
- AML events are tracked in **AML_FORENSIC_TRAIL** for both customer types.
- Only business-critical attributes are shown to keep the ER diagram readable.

