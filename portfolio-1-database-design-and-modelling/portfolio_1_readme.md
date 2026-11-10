# 📘 Portfolio 1 Overview – Database Design & Modelling

## Case Study Context
This portfolio is modeled on the **JPMorgan Chase Nigeria case study**, specifically isolating the complex functional areas of corporate clearing, financial control, and regulatory compliance operations within the Nigerian banking sector.  
The primary objective of this architecture is to provide a **production-grade Oracle Database schema** capable of handling high-throughput customer onboarding, core ledger account management, structured transaction processing, and immutable Anti-Money Laundering (AML) forensic logging.

---

## Core Architectural Requirements
The structural design addresses the following mandatory case study criteria:

- **Relational Schema Map**: A complete Entity-Relationship (ER) model charting data streams between customer identities, operational accounts, double-entry transaction journals, and compliance records.  
- **Production DDL Scripts**: Optimized, compile-ready Oracle SQL scripts defining relational table spaces, constraints, custom data domains, and access indexing paths.  
- **Data Normalisation Engineering**: Comprehensive architectural documentation tracking the schema’s lifecycle from raw inputs through 1st, 2nd, and 3rd Normal Forms (1NF–3NF) to systematically eliminate data corruption risks and operational update anomalies.  
- **Security & Governance Matrix**: Multi-layered access blueprints defining structural schema isolation, fine-grained role-based access control (RBAC) grants, and active ledger auditing parameters.

---

## Implemented Database Architecture

### 1. Schema Isolation Model
- **CUSTOMER Schema**: Encapsulates core identity frameworks, mapping corporate and retail Customer Information Files (CIF) alongside regulatory AML forensic logs.  
- **TRANSACT Schema**: Houses the high-concurrency engine running the General Ledger account configurations and the multi-leg daily journal transaction records.

### 2. Core Relational Entities
- **RETAIL_CUSTOMER_MASTER / CORPORATE_CUSTOMER_MASTER**: Structural tables tracking verified customer entities, Central Bank of Nigeria (CBN) KYC tiers, and unique national identification numbers (NIN).  
- **GENERAL_ACCT_MAST_TABLE (GAM)**: The relational ledger account master, storing real-time cleared balances, localized multi-currency allocations (e.g., NGN, USD), and operational status vectors.  
- **DAILY_TXN_DTL (DTD)**: A high-velocity ledger journal recording atomic, balanced debit and credit legs under an explicit compound key strategy.  
- **AML_FORENSIC_TRAIL**: An immutable, append-only security log decoupled from operational data pathways to track network configurations (IP_ADDRESS, TERMINAL_ID), risk shifts (RISK_SCORE), and structural dual-control footprints (INITIATOR_USER, VERIFIER_USER).

### 3. Normalisation & Structural Integrity
- **1NF (Atomicity & Flattening)**: Enforces indivisible values across structural identity fields (e.g., separating customer names) and eliminates repeating multi-valued arrays or lists.  
- **2NF (Full Functional Dependency)**: Wipes out partial functional key dependencies by ensuring non-key attributes relate strictly to the full primary key (e.g., pulling descriptive customer data completely away from account-level records).  
- **3NF (Transitive Anomaly Removal)**: Segregates distinct business contexts (Customers → Accounts → Transactions) across independent relational tables, using strict primary-to-foreign key mappings to eliminate transitive overhead.

### 4. Enterprise Security & Access Matrix
- **Operational Decoupling**: Enforces complete boundary isolation between front-office transaction layers and internal auditing/compliance assets.  
- **Granular Role Privileges**: Restricts application-layer runtimes (`APPUSER`) and infrastructure operations (`SUPPORTUSER`) via targeted DML filters, explicitly revoking uncontrolled DELETE and UPDATE privileges on analytical fields.  
- **Advanced Maintenance Controls**: Configures localized database options including `FLASHBACK`, `QUERY REWRITE`, and `DEBUG` to allow secure recovery testing, execution plan optimization, and trace-logging.

---

✅ Portfolio 1 establishes a **robust, compliant, and normalised Oracle database foundation** for JPMorgan Chase Nigeria.
