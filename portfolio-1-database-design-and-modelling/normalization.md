# 🗂 Normalisation  – JP morgan Commercial Banking Ledger

## 1. First Normal Form (1NF)
- All attributes are atomic (no repeating groups or multi‑valued fields).
- Example: `RETAIL_CUSTOMER_MASTER` stores `FIRST_NAME`, `LAST_NAME`, `DATE_OF_BIRTH` separately.
- `GENERAL_ACCT_MAST_TABLE` stores balances (`CLR_BAL_AMT`, `UN_CLR_BAL_AMT`) as numeric fields with precision.
- Each record is uniquely identified by a primary key (`CIF_ID`, `ACCT_ID`, `TXN_ID + TXN_INDEX`, `EVENT_ID`).

✅ **Result:** Data is structured into rows and columns with no repeating groups.

---

## 2. Second Normal Form (2NF)
- All non‑key attributes are fully dependent on the primary key.
- In `RETAIL_CUSTOMER_MASTER`, attributes like `ADDRESS_LINE_1`, `KYC_LEVEL`, `RISK_RATING` depend only on `CIF_ID`.
- In `GENERAL_ACCT_MAST_TABLE`, balances and flags depend only on `ACCT_ID`.
- Composite keys are handled correctly:
  - `DAILY_TXN_DTL` uses `(TXN_ID, TXN_INDEX)` as PK. Attributes like `TRAN_AMT`, `TRAN_TYPE` depend on the full composite key.

✅ **Result:** No partial dependency on part of a composite key.

---

## 3. Third Normal Form (3NF)
- No transitive dependencies:
  - Customer details are separated from account details (no duplication of names in account table).
  - Transaction details are separated from account master (no duplication of balances).
  - AML forensic trail is separated as an independent immutable log.
Every non-prime attribute must depend entirely and directly on the primary key identifier. Let us analyze our core transaction engine ledger table (GENERAL_ACCT_MAST_TABLE)
- Each entity’s key determines its own attributes.

`{ACCT_ID}` ----> {`ACCT_NUM`,`CIF_ID`,`SOL_ID`,`GL_CODE`,`CLR_BAL_AMT`,`LIEN_AMT`}

✅ **Result:** No non‑key attribute depends on another non‑key attribute.

---

#   Storage Optimization & Precision Architecture

For a tier handling multi-currency processing on Exadata, floating-point data errors can introduce auditing issues. I have addressed this through precise data type configurations:

- `NUMBER(20,4)` & `NUMBER(25,4)`: Standardizes financial columns `(CLR_BAL_AMT, CUM_DR_AMT)` to 4 decimal places. This ensures perfect rounding precision across international currencies like NGN, USD, GBP, and EUR.

---

# 🔒 Security & Schema Isolation Notes

## Schema Isolation
- `CUSTOMER` schema: sensitive CIF data and AML forensic trail.
- `TRANSACT` schema: operational account and transaction data.
- Synonyms (`RETAIL`, `CORPORATE`, `GAM`, `DTD`) simplify developer access without exposing schema names.

## Grants & Roles
- `SUPPORTUSER`: read‑only access for troubleshooting.
- `APPUSER`: controlled DML privileges (SELECT, INSERT, UPDATE, DELETE).
- Advanced privileges: `FLASHBACK`, `QUERY REWRITE`, `DEBUG`.
- Quotas enforced (`100M`) to prevent uncontrolled growth.

## Audit & Compliance
- AML trail enforces immutability (`immutable_flag = 'Y'`).
- Oracle Database Vault policies can prevent updates/deletes on AML tables.
- Separation of duties: compliance team owns `CUSTOMER` schema, operations team owns `TRANSACT`.
---
