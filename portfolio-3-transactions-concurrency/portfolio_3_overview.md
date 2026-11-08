## Transaction Management and ACID Compliance

At this stage of the portfolio, the focus shifts from database structure and query optimisation to transaction processing and data consistency. In a banking environment, large volumes of transactions are processed throughout the day, particularly during peak business hours, Real-Time Gross Settlement (RTGS) operations, and End-of-Day (EOD) processing.

A key responsibility of the database is to ensure that all financial transactions are completed accurately and consistently, regardless of system failures, network interruptions, or application-level errors. For this reason, the database relies on the ACID principles of **Atomicity**, **Consistency**, **Isolation**, and **Durability** to maintain the integrity of customer accounts and ledger balances.

These properties ensure that a transaction is either completed in its entirety or not applied at all, preventing situations where only part of a financial operation is recorded. They also guarantee that committed transactions remain permanently stored and that concurrent users cannot introduce inconsistencies into the system.

To demonstrate transaction management within the proposed banking environment, operations are performed across the core tables developed in [Portfolio 1](../port):

### `TRANSACT.GENERAL_ACCT_MAST_TABLE (GAM)`

This table stores account balances and supports day-to-day financial processing. Key attributes include:

- `CLR_BAL_AMT` - the available cleared balance on an account.
- `UN_CLR_BAL_AMT` - the uncleared cheques/drafts balance on an account.
- `CUM_DR_AMT` - the cumulative debit amount recorded against the account.
- `CUM_CR_AMT` - the cumulative credit amount recorded against the account.
- `Lien_amt` - the cumulative lien amount recorded against the account.

As customer transactions are processed, these values are updated to reflect the current financial position of each account.

### `CUSTOMER.CORPORATE_CUSTOMER_MASTER`

This table serves as the authoritative source for corporate customer information. It contains customer status information through the `CUST_STATUS` attribute and supports account validation during transaction processing.

### `CUSTOMER.RETAIL_CUSTOMER_MASTER`

This table serves as the authoritative source for customer information. It contains customer status information through the `CUST_STATUS`  AND `KYC_LEVEL` attribute and supports account validation during transaction processing.

### `CUSTOMER.AML_FORENSIC_TRAIL`

This table provides an audit trail of compliance-related activities and risk assessments. Records are maintained to support regulatory monitoring, internal investigations, and reporting requirements associated with the Central Bank of Nigeria (CBN) and the Nigeria Data Protection Act (NDPA).

Together, these tables demonstrate how transactional updates, customer management, and compliance monitoring operate within a controlled Oracle 19c database environment while preserving data integrity and auditability.

## System Architecture and Transaction Flow

The following process illustrates how a financial transaction is processed within the database environment. The objective is to ensure that all account updates are validated, recorded, and committed as a single atomic transaction while maintaining data integrity across the customer, account, and compliance tables.

Each stage of the transaction is executed within a controlled Oracle 19c transaction session operating under the **READ COMMITTED** isolation level. This prevents users from reading uncommitted changes while allowing the database to support concurrent transaction processing. Please see the [System Architecture and Transaction](Transaction_concurrency.md)

## Transaction Processing Procedure (PL/SQL)

The following PL/SQL block demonstrates how a high-value corporate transaction can be processed within the proposed Oracle 19c JP Morgan chasebanking environment. In this example, a corporate fee of **₦5,000,000** is deducted from a customer account while ensuring that all business rules, balance validations, and compliance requirements are satisfied.

The transaction spans both the `TRANSACT` and `CUSTOMER` schemas. Throughout the process, Oracle's transaction management features are used to maintain data consistency and prevent concurrent updates from affecting the same account record.

### Transaction Objectives

The procedure performs the following activities within a single database transaction:

- Acquires a row-level lock on the target account using `SELECT ... FOR UPDATE NOWAIT`.
- Validates that the associated customer account is not frozen.
- Verifies that sufficient funds are available before processing the debit.
- Updates account balances within `TRANSACT.GENERAL_ACCT_MAST_TABLE`.
- Records a transaction entry in `TRANSACT.DAILY_TXN_DTL`.
- Records an audit entry in `CUSTOMER.AML_FORENSIC_TRAIL`.
- Commits all changes only when every validation step succeeds.
- Rolls back the transaction if any business rule or system error is encountered. Please see the [Transaction Processing](Transaction_concurrency.md)
