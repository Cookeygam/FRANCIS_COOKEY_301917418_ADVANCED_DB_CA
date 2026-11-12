
###  1. TRANSACTION CONTEXT & CASE STUDY STRATEGIC INTENT
Within this portfolio milestone, my engineering focus shifts from structural access paths to runtime transactional behavior during peak operational windows, Real-Time Gross Settlement (RTGS) cycles, and intensive End-of-Day (EOD) closures. Maintaining data consistency is paramount to safeguard the ledger, the system must enforce strict ACID (Atomicity, Consistency, Isolation, Durability) properties directly at the block storage tier. This ensures that application-layer flaws, thread dropouts, or network interruptions cannot result in partial updates or corrupt ledger balances.

###  2. SYSTEM ARCHITECTURE & DATA TRANSITION STREAM

The diagram below maps how a single, atomic financial request navigates our database engine. It highlights the real-time cross-schema validations and row-level write barriers used to secure data integrity:
   
   ```text
                 [TRANSACTION REQUEST]
                           │
                           ▼
        ┌─────────────────────────────────┐
        │   Begin Database Transaction    │
        │   Isolation Level:              │
        │   READ COMMITTED                │
        └───────────────┬─────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │ Step 1: Lock Account Record     │
        │ Retrieve account from           │
        │ GENERAL_ACCT_MAST_TABLE         │
        │ using SELECT ... FOR UPDATE     │
        └───────────────┬─────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │ Step 2: Validate Customer       │
        │ Confirm account is active and   │
        │ CUST_STATUS is not 'FROZEN'     │
        └───────────────┬─────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │ Step 3: Verify Available Funds  │
        │ Check that the account balance  │
        │ is sufficient to process the    │
        │ requested transaction           │
        └───────────────┬─────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │ Step 4: Update Ledger Values    │
        │ Update CLR_BAL_AMT and          │
        │ CUM_DR_AMT within GAM           │
        └───────────────┬─────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │ Step 5: Record Audit Activity   │
        │ Insert transaction details into │
        │ AML_FORENSIC_TRAIL              │
        └───────────────┬─────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────┐
        │ Step 6: Commit Transaction      │
        │ Persist all changes and         │
        │ release database locks          │
        └─────────────────────────────────┘
```

### Explanation of the Transaction Flow

The transaction begins when a financial request is submitted to the database. Oracle establishes a transaction session under the **READ COMMITTED** isolation level and acquires a row-level lock on the target account using `SELECT ... FOR UPDATE`. This prevents concurrent transactions from modifying the same account balance at the same time.

The system then verifies that the associated customer account remains active by checking the `CUST_STATUS` value stored in `CUSTOMER.CORPORATE_CUSTOMER_MASTER`. Transactions involving frozen or inactive accounts are rejected before any updates occur.

Once the customer validation is successful, the available balance held in `TRANSACT.GENERAL_ACCT_MAST_TABLE` is evaluated to ensure sufficient funds are available for the requested transaction. If the balance validation fails, the transaction is rolled back and no changes are applied.

If all validation checks pass, the ledger values are updated by modifying the account's `CLR_BAL_AMT` and cumulative debit totals. An audit record is then inserted into `CUSTOMER.AML_FORENSIC_TRAIL` to preserve a permanent record of the activity for compliance and regulatory purposes.

Finally, Oracle commits the transaction. At this stage, all modifications become permanent, the associated redo information is written to durable storage, and any row-level locks acquired during processing are released. This ensures that the entire operation is completed as a single atomic unit in accordance with the ACID properties discussed earlier.


###  3. PRODUCTION TRANSITION BLOCK ARCHITECTURE (PL/SQL)

The following script handles a high-value corporate fee deduction or account mutation. It implements our pessimistic locking model, evaluates cross-schema constraints, executes the transaction, and writes an explicit audit payload to the compliance engine—all wrapped within a single atomic scope.

### Transaction Workflow
#### I. Transaction Initialisation

The procedure begins by establishing a clean transaction boundary and setting the session isolation level to `READ COMMITTED`. This prevents transactions from reading uncommitted changes made by other sessions while still supporting concurrent database activity.

#### II. Account Lookup and Row Locking

The target account is retrieved from `TRANSACT.GENERAL_ACCT_MAST_TABLE` using the supplied account number.

```sql
SELECT ACCT_ID FROM TRANSACT.GAM WHERE ACCT_NUM = '0123489009'
FOR UPDATE NOWAIT;
```
The `FOR UPDATE NOWAIT` clause places a row-level lock on the account record, preventing other sessions from updating the same account during processing. If another session already holds a lock, the transaction is immediately rejected rather than waiting indefinitely.

#### III. Customer Status Validation

The procedure then retrieves the corresponding customer record from `CUSTOMER.CORPORATE_CUSTOMER_MASTER` and evaluates the value stored in `CUST_STATUS`.

If the customer account has been marked as `FROZEN`, processing is terminated and the transaction is rolled back.

#### IV. Balance Verification

Before any ledger update occurs, the available balance is checked to ensure that the transaction does not breach any account restrictions.

```sql
(clr_bal_amt - lien_amt) >= (v_debit_amount)
```

This validation ensures that sufficient funds remain available after considering any active liens or restricted balances on the account.

#### V. Account Balance Update

When all validation checks have been satisfied, the account balances are updated within `TRANSACT.GENERAL_ACCT_MAST_TABLE`.

The procedure:

- Deducts the transaction value from `CLR_BAL_AMT`.
- Increments `CUM_DR_AMT` to reflect the new debit.
- insert the transaction details into `TRANSACT.DAILY_TXN_DTL`.
- Updates the transaction date and modification timestamp.

These changes represent the financial impact of the transaction within the ledger.

#### VI. Compliance Audit Logging

Following the balance update, an audit record is inserted into `CUSTOMER.AML_FORENSIC_TRAIL`.

The audit record captures:

- Customer identifier (`CIF_ID`)
- Event type
- Risk assessment values
- Terminal details
- IP address
- Maker and checker information
- Transaction metadata stored within an audit payload

This information provides a complete audit trail for compliance monitoring and future investigations.

#### VII. Transaction Commit

Once all database operations have completed successfully, a `COMMIT` statement is issued.

At this stage:

- The account update becomes permanent.
- The audit record is permanently stored.
- Row-level locks are released.
- The transaction is considered complete.

### Exception Handling

The procedure includes explicit exception handling to manage expected business scenarios and unexpected system failures.

| Exception | Purpose |
|------------|------------|
| `e_account_frozen` | Blocks transactions on restricted customer accounts. |
| `e_insufficient_funds` | Prevents an account from exceeding available funds after considering active liens. |
| `e_row_locked_timeout` | Detects situations where another session is currently modifying the account. |
| `OTHERS` | Any unhandled `SQLCODE` Captures unexpected database or constraint errors and issues an immediate `ROLLBACK` to guarantee strict ACID atomicity across `GENERAL_ACCT_MAST_TABLE`, `DAILY_TXN_DTL`, and `AML_FORENSIC_TRAIL`. |

If any exception occurs, Oracle executes a `ROLLBACK` statement to undo all pending changes. As a result, either every operation succeeds together or no changes are applied.

### ACID Compliance

This implementation demonstrates the practical application of Oracle's ACID principles:

- **Atomicity** ensures that all updates either succeed together or fail together.
- **Consistency** guarantees that business rules and integrity constraints are maintained.
- **Isolation** prevents concurrent transactions from interfering with one another through row-level locking.
- **Durability** ensures that committed changes remain permanently stored, even in the event of a system failure.

Overall, the procedure illustrates how Oracle 19c transaction management features can be used to maintain the integrity of financial data while supporting both operational processing and regulatory compliance requirements.

```sql
DECLARE
    -- Bind parameters representing front-office application layer variables
    v_input_acct_num      VARCHAR2(34 CHAR) := '0123489009'; 
    v_debit_amount        NUMBER(20,4)      := 5000000.0000; -- ₦5,000,000 corporate fee
    v_terminal_id         VARCHAR2(16 CHAR) := 'LAG-EXA-NODE02';
    v_ip_address          VARCHAR2(45 CHAR) := '10.120.4.52';
    v_maker_user          VARCHAR2(30 CHAR) := 'INI00032';
    v_checker_user        VARCHAR2(30 CHAR) := 'JPB00014';
    
    -- Internal transaction workspace trackers
    v_db_acct_id          VARCHAR2(16 CHAR);
    v_db_cif_id           VARCHAR2(10 CHAR);
    v_db_clr_bal          NUMBER(20,4);
    v_db_lien_amt         NUMBER(20,4);
    v_db_status           VARCHAR2(12 CHAR);
    v_risk_score_before   NUMBER(3,1);
    v_risk_score_after    NUMBER(3,1);
    v_forensic_payload    CLOB;

    -- Granular business exception declarations
    e_account_frozen      EXCEPTION;
    e_insufficient_funds  EXCEPTION;
    e_row_locked_timeout  EXCEPTION;
    
    -- Map native Oracle busy resource code to our named exception
    PRAGMA EXCEPTION_INIT(e_row_locked_timeout, -54); -- ORA-00054: Resource busy
BEGIN
    -- 1. Initialize the session isolation context
    -- Terminate any existing implicit transaction scope to establish a clean boundary
    COMMIT; 
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    -- 2. Execute a pessimistic row lock with immediate check to prevent lock waiting queues
    BEGIN
        SELECT acct_id, cif_id, clr_bal_amt, lien_amt
        INTO v_db_acct_id, v_db_cif_id, v_db_clr_bal, v_db_lien_amt
        FROM TRANSACT.general_acct_mast_table
        WHERE acct_num = v_input_acct_num AND del_flg = 'N'
        FOR UPDATE NOWAIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20101, 'Data Error: Target account does not exist or is marked deleted.');
        WHEN e_row_locked_timeout THEN
            RAISE_APPLICATION_ERROR(-20102, 'Resource Contention: Account is currently locked by a competing batch thread.');
    END;

    -- 3. Perform a cross-schema lookup to verify customer lifecycle status
    SELECT cust_status, NVL(risk_rating, '1.0')
    INTO v_db_status, v_risk_score_before
    FROM CUSTOMER.corporate_customer_master
    WHERE cif_id = v_db_cif_id;

    IF v_db_status = 'FROZEN' THEN
        RAISE e_account_frozen;
    END IF;

    -- 4. Evaluate liquidity constraints before making ledger entries
    -- Ensure the updated balance will not violate active lien obligations
    IF (v_db_clr_bal - v_debit_amount) < (-v_db_lien_amt) THEN
        RAISE e_insufficient_funds;
    END IF;

    -- 5. Execute ledger entry within the TRANSACT Domain
    UPDATE TRANSACT.general_acct_mast_table
    SET clr_bal_amt   = clr_bal_amt - v_debit_amount,
        cum_dr_amt    = NVL(cum_dr_amt, 0) + v_debit_amount,
        last_tran_date = TRUNC(SYSDATE),
        rcre_time     = SYSDATE
    WHERE acct_id = v_db_acct_id;

    -- 6. Generate the audit payload and log to the compliance registry (CUSTOMER Schema)
    v_risk_score_after := LEAST(v_risk_score_before + 2.0, 10.0); -- Model incremental threat elevation
    
    v_forensic_payload := '{"event": "FEE_DEDUCTION", "amount": ' || v_debit_amount || 
                          ', "currency": "NGN", "resulting_balance": ' || (v_db_clr_bal - v_debit_amount) || '}';

    INSERT INTO CUSTOMER.aml_forensic_trail (
        log_id, event_type, customer_type, cif_id, risk_score_before, 
        risk_score_after, terminal_id, ip_address, initiator_user, 
        verifier_user, event_timestamp, audit_payload_clob
    ) VALUES (
        CUSTOMER.seq_aml_forensic_id.NEXTVAL,
        'MANUAL_EOD_MUTATION',
        'CORPORATE',
        v_db_cif_id,
        v_risk_score_before,
        v_risk_score_after,
        v_terminal_id,
        v_ip_address,
        v_maker_user,
        v_checker_user,
        SYSDATE,
        v_forensic_payload
    );

    -- 7. Persist all updates atomically across schemas
    COMMIT;

EXCEPTION
    WHEN e_row_locked_timeout THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('LOCK CONTENTION (ORA-00054): Account ' || p_acct_num || ' is locked by another active session. Transaction rolled back.');

    WHEN e_account_frozen THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('COMPLIANCE BLOCK: Customer CIF ' || v_cif_id || ' is FROZEN. Transaction rolled back.');

    WHEN e_insufficient_funds THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('INSUFFICIENT FUNDS: Available balance after liens is below ' || p_debit_amount || '. Transaction rolled back.');

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('SYSTEM ERROR (' || SQLCODE || '): ' || SQLERRM || '. Full rollback executed.');
END;
/
```
### Concurrency Control and Transaction Isolation

In this JPMorgan Chase Nigeria database environment, multiple transactions may be processed against the same customer account at the same time. For example, while one process is deducting a corporate fee from an account, another process could be posting a transfer, updating account balances, or performing an AML review.
To ensure that these concurrent activities do not compromise data integrity. The transaction processing procedure developed in this portfolio operates under Oracle's default **READ COMMITTED** isolation level. This was selected because it provides a balance between performance and data consistency, making it suitable for high-volume banking transactions.
When a transaction is initiated, a row-level lock is acquired on the target account within `TRANSACT.GENERAL_ACCT_MAST_TABLE` using:
```sql
SELECT ...
FOR UPDATE NOWAIT;
```
Oracle 19c provides transaction isolation and locking mechanisms that control how transactions interact with the same data.

### Transaction Isolation Levels in Oracle 19c
| Transaction Issue | Read Committed (Default) | Serializable | Impact on the Banking System |
|-------------------|--------------------------|--------------|------------------------------|
| **Dirty Read** | Not possible. Only committed data is visible to other sessions. | Not possible. | Prevents balances in `GENERAL_ACCT_MAST_TABLE` from being calculated using uncommitted transactions. |
| **Non-Repeatable Read** | Possible if another transaction updates a record and commits before the next read. | Prevented. The transaction uses a consistent snapshot of data. | Important when reviewing customer information or generating balance reports. |
| **Phantom Read** | Possible if new qualifying rows are inserted by another transaction. | Prevented. | Ensures regulatory and AML reports are generated from a stable set of records. |
| **Write Conflicts** | Possible during concurrent updates. | Oracle detects conflicts and raises `ORA-08177`. | Helps prevent inconsistent account updates during simultaneous transaction processing. |

This prevents two sessions from updating the same account balance simultaneously.
For example, if one session is processing a ₦5,000,000 corporate fee deduction against account **0123489009**, Oracle locks that account record until the transaction either commits or rolls back. Any competing session attempting to modify the same account will receive a lock exception and must retry the operation.
The same transaction also performs validation against `CUSTOMER.CORPORATE_CUSTOMER_MASTER` to confirm that the customer is not marked as `FROZEN`. Once the balance update is completed, a corresponding audit record is written to `CUSTOMER.AML_FORENSIC_TRAIL`.
As a result, the account update and AML audit entry are treated as a single unit of work. If any step fails, Oracle rolls back the entire transaction, ensuring that account balances, customer records, and compliance logs remain consistent.

##  Locking Strategy Rationale:

1. Oracle Multi-Version Concurrency Control (MVCC): Readers do not block writers, and writers do not block readers. Read operations pull data snapshots from the Undo Tablespace, ensuring high performance even during intensive batch processing windows.
2. Pessimistic Locking Overrides: For critical financial values like account balances (CLR_BAL_AMT), we bypass optimistic concurrency controls. Forcing transaction blocks to lock rows immediately using FOR UPDATE NOWAIT prevents long wait queues and eliminates the risk of system deadlocks at the block storage layer.
