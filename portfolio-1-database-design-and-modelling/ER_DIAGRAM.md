
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



# Entity Relationship Diagram (ERD)

## Database Overview

The database consists of three schemas:

- **CUSTOMER** — customer identity and customer-related records.
- **TRANSACT** — product definitions, general account master records, and transaction records.
- **LEDGER** — internal asset, liability, and nostro account records.

## ER Diagram

```mermaid
erDiagram
    %% CUSTOMER SCHEMA
    RETAIL_CUSTOMER_MASTER ||--o{ GENERAL_ACCT_MAST_TABLE : "has retail accounts"
    CORPORATE_CUSTOMER_MASTER ||--o{ GENERAL_ACCT_MAST_TABLE : "has corporate accounts"

    %% PRODUCT AND ACCOUNT MASTER
    PRODUCT_MASTER ||--o{ GENERAL_ACCT_MAST_TABLE : "defines account scheme"

    %% CUSTOMER ACCOUNT TRANSACTIONS
    GENERAL_ACCT_MAST_TABLE ||--o{ DAILY_TXN_DTL : "records daily transactions"
    GENERAL_ACCT_MAST_TABLE ||--o{ HISTORY_TXN_DTL : "records transaction history"

    %% INTERNAL LEDGER ACCOUNTS
    PRODUCT_MASTER ||--o{ ASSETS_ACCOUNT : "defines asset product"
    PRODUCT_MASTER ||--o{ LIABILITY_ACCOUNT : "defines liability product"
    PRODUCT_MASTER ||--o{ NOSTRO_ACCOUNT : "defines nostro product"

    GENERAL_ACCT_MAST_TABLE ||--o{ ASSETS_ACCOUNT : "relates to asset ledger"
    GENERAL_ACCT_MAST_TABLE ||--o{ LIABILITY_ACCOUNT : "relates to liability ledger"
    GENERAL_ACCT_MAST_TABLE ||--o{ NOSTRO_ACCOUNT : "relates to nostro ledger"

    %% CUSTOMER SCHEMA ENTITIES
    RETAIL_CUSTOMER_MASTER {
        string CUSTOMER_ID PK
    }

    CORPORATE_CUSTOMER_MASTER {
        string CORPORATE_CUSTOMER_ID PK
    }

    AML_FORENSIC_TRAIL {
        string TRAIL_ID PK
    }

    %% TRANSACT SCHEMA ENTITIES
    PRODUCT_MASTER {
        string PRODUCT_CODE PK
        string PRODUCT_NAME
        string SEGMENT
    }

    GENERAL_ACCT_MAST_TABLE {
        string ACCT_ID PK
        string CUSTOMER_ID FK
        string CORPORATE_CUSTOMER_ID FK
        string PRODUCT_CODE FK
    }

    DAILY_TXN_DTL {
        string TRANSACTION_ID PK
        string ACCT_ID FK
    }

    HISTORY_TXN_DTL {
        string TRANSACTION_ID PK
        string ACCT_ID FK
    }

    %% LEDGER SCHEMA ENTITIES
    ASSETS_ACCOUNT {
        number ASSET_ACCOUNT_ID PK
        number ASSET_ACCOUNT_NUM
        string PRODUCT_CODE FK
        string GL_CODE
        string ACCT_CRNCY_CODE
    }

    LIABILITY_ACCOUNT {
        number LIABILITY_ACCOUNT_ID PK
        number LIABILITY_ACCOUNT_NUM
        string PRODUCT_CODE FK
        string GL_CODE
        string ACCT_CRNCY_CODE
    }

    NOSTRO_ACCOUNT {
        number NOSTRO_ACCOUNT_ID PK
        string NOSTRO_ACCOUNT_NUMBER
        string PRODUCT_CODE FK
        string GL_CODE
        string ACCT_CRNCY_CODE
    }
```

## Relationship Interpretation

| Relationship | Description |
|---|---|
| Retail customer → GAM | A retail customer can hold one or more accounts in GAM. |
| Corporate customer → GAM | A corporate customer can hold one or more accounts in GAM. |
| Product master → GAM | A product or scheme, such as savings or current, can be assigned to multiple GAM accounts. |
| GAM → Daily transaction details | A GAM account can have multiple daily transaction records. |
| GAM → Transaction history | A GAM account can have multiple historical transaction records. |
| Product master → Ledger accounts | Products can be associated with asset, liability, and nostro accounts. |
| GAM → Ledger accounts | GAM is the central account master through which customer-account activity is associated with the corresponding internal ledger accounts. |

## Design Principle

The CUSTOMER schema is not directly linked to the LEDGER schema.

Customer details are maintained in the CUSTOMER schema, and customer accounts are represented in the general account master table (GAM) in the TRANSACT schema. GAM serves as the central account reference for product assignment, transaction records, and corresponding ledger-account relationships.

The ERD represents the logical model. Foreign-key columns and cardinalities should be confirmed against the final Oracle DDL.


### Notes

- **PK** = Primary Key
- **FK** = Foreign Key
- A **Customer** (Retail or Corporate) may own multiple **Accounts**.
- An **Account** may have many **Transactions**.
- AML events are tracked in **AML_FORENSIC_TRAIL** for both customer types.
- Only business-critical attributes are shown to keep the ER diagram readable.

