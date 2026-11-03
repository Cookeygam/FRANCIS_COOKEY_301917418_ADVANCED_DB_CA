# CA_ADVANCED_DB_ASSESSMENT

Name: FRANCIS COOKEY

Student ID: XXXXX 

Individual Practical Database Portfolio for course MIT 8103. Hands-on technical portfolio demonstrating the practical design, implementation, optimization, and management of advanced database systems.
NAME: FRANCIS COOKEY.
STUDENT ID: xxxx.
COURSE CODE: MIT 8103.

# 🏛️CASE STUDY: Enterprise Banking Oracle Database Design For JPmorgan Chase Nigeria.
JPMorgan Chase & Co. is establishing a commercial banking operation within the Federal Republic of Nigeria, targeting corporate banking, investment banking, asset management, and high-net-worth treasury operations. Operating under a Commercial Banking License with National/International Authorization issued by the Central Bank of Nigeria (CBN), the infrastructure must strictly comply with CBN regulatory frameworks, including the Guidelines on Cyber-Security Insurance for Banks,  data protection (NPDA), and financial reporting.

To support this operational footprint, JPMorgan Chase is deploying the Infosys Finacle Core Banking Solution v11 supported by Oracle Database 23ai on Exadata. This setup is a heavily normalized, highly transactional (OLTP) engine that demands extreme write throughput during peak operational windows, combined with intensive, block-level parallelization batch processing and guarantees zero data loss.

# User Personas and Access.
The relational schema is built to isolate and serve discrete operational domains, maintaining structural data separation:
To protect data integrity from application-layer flaws or network dropouts, every core business rule is implemented directly within the database tier using declarative constraints, and atomic transaction scopes. To support the three distinct organizational personas safely, the database is architected into three dedicated domain schemas. This enforces strict security boundaries while allowing for specialized multi-currency, trading, and compliance workflows.

| Domain Owner | Schema | Primary Responsibilities | Core Data Entities |
| :--- | :--- | :--- | :--- |
| **Persona A: Corporate Clearing team** | `TRANSACT` | High-value payment processing, multi-currency corporate pooling, and external financial gateway integrations. | <ul><li>`clearing_accounts`</li><li>`wire_transactions`</li></ul> |
| **Persona B: Financial control officers** | `TRANSACT` | General Ledger (GL) balancing, End-of-Day (EOD) closures, fee income collection, and correspondent bank matching. | <ul><li>`general_ledger_entries`</li><li>`nostro_vostro_reconciliation`</li></ul> |
| **Persona C: Risk, Compliance & Audit team** | `CUSTOMER` | Central Bank of Nigeria (CBN) regulatory, unalterable system forensic tracking, and real-time AML/KYC analysis. | <ul><li>`cbn_registry`</li><li>`aml_forensic_trail`</li></ul> |

### 🔒 Cross-Domain Security Design
1. **Isolation:** Each schema operates as an independent security boundary. Tables are wholly owned by their respective schema users.
2. **Access Control:** No direct cross-schema modifications are allowed. If the `CUSTOMER` engine needs to read data from `TRANSACT` for AML transaction spotting, explicit `GRANT SELECT` privileges must be mapped explicitly via database roles.
