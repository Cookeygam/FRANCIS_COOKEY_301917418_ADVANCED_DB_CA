# 🏛️Case Study : Enterprise Banking Oracle Database Design For JP Morgan Chase Nigeria.

**NAME:** Francis Cookey  
**Course:** MIT 8103 – Advanced Database Systems  
**Academic Session:** 2026/2027  
**Student ID:** 301917418

## 1. Project Overview
---

JPMorgan Chase & Co. established a commercial banking operation within the Federal Republic of Nigeria, targeting corporate banking, investment banking, asset management, and high-net-worth treasury operations under a license from the Central Bank of Nigeria (CBN). The bank would serve corporate clients, investment banking, asset management and high-net-worth treasury.

As a global financial services institution, JPMorgan Chase operates in an environment where transaction accuracy, data integrity, controlled access, auditability, and system availability are fundamental to banking operations. These requirements provide the context for applying advanced database administration and engineering concepts throughout this project.

The database is the transactional core of the bank. It has to cope with heavy payment traffic at peak times, run large end-of-day batch jobs, and never lose a committed transaction. I have put the business rules inside the database itself, using constraints and atomic transactions, so that a faulty application or a dropped connection cannot leave the data in a bad state.

The work progresses from relational database design and SQL implementation to query optimization, transaction management, NoSQL data modelling, and distributed database architecture.

> **Scope note:** This is an academic case study. It does not represent a verified implementation or deployment within JPMorgan Chase & Co. or any other actual bank. Any technology or architecture identified as part of the project is documented as a design choice or implementation environment not as a claim about JPMorgan Chase’s internal infrastructure.

## 2. Project Objectives

The objective is to design, implement, and evaluate a database solution against the operational demands represented in the JPMorgan Chase case study.

The portfolio will:

- Model the core banking data entities and their relationships.
- Apply normalization, keys, constraints, and referential integrity.
- Implement SQL operations that support the selected business processes.
- Analyze query execution plans and evaluate indexing and query optimization.
- Demonstrate transaction control, rollback, isolation, and concurrency behavior.
- Evaluate a suitable NoSQL model for a selected data requirement.
- Examine distributed database approaches, including replication and consistency.
- Document implementation decisions, test evidence, limitations, and lessons learned.

## 🙎🏼3. Who uses the database

The data is split across three schemas. Each one belongs to a single team and works as its own security boundary.

| Team | Schema | What they do |
|---|---|---|
| Corporate Clearing | `TRANSACT` | Process high-value and multi-currency payments and connect to external payment gateways |
| Financial Control | `LEDGER` | Balance the general ledger, close the day, collect fees and match records with correspondent banks |
| Risk, Compliance and Audit | `CUSTOMER` | Hold CBN registry data, keep a tamper-proof audit trail and run AML/KYC checks |

### Role-based access control

Database access is organized around three business roles:

| Role | Responsibility |
|---|---|
| `ROLE_CORPORATE_CLEARING` | Performs authorized clearing account and wire transaction activities. |
| `ROLE_FINANCIAL_CONTROL` | Supports ledger management and nostro/vostro reconciliation. |
| `ROLE_RISK_COMPLIANCE_AUDIT` | Reviews relevant customer, transaction, and compliance records for monitoring and audit. |

The access model applies the principle of least privilege. Users receive permissions through their assigned roles, and cross-schema access is granted only where the business requirement justifies it.

## 4. Key operations the database supports

- Posting a wire transfer so the debit, the credit and the ledger entry either all succeed or all fail
- Pooling balances across currencies for corporate clients
- Balancing the ledger and closing the day
- Matching the bank's records against those of correspondent banks
- Recording every sensitive action in a trail that cannot be edited
- Flagging suspicious activity for AML review

### 🔐5. Cross-Domain Security Design
1. **Isolation:** Each schema operates as an independent security boundary. Tables are wholly owned by their respective schema users.
2. **Access Control:** No direct cross-schema modifications are allowed. If the `CUSTOMER` engine needs to read data from `TRANSACT` for AML transaction spotting, explicit `GRANT SELECT` privileges must be mapped explicitly via database roles.

## 5. Technology and Implementation Environment

The case-study architecture references the following banking technology context:

| Component | Technology |
|---|---|
| Core banking context | Infosys Finacle |
| Relational database | Oracle Database |
| Enterprise database platform context | Oracle Exadata |
| Database language | SQL |
| Database procedural language | PL/SQL |

The technologies above establish the enterprise context for the case study. The implementation and testing sections identify the database environment used for the portfolio and distinguish it from the wider enterprise architecture.

## 7. Repository layout

```
advanced-database-portfolio/
├── portfolio-1-database-design/
├── portfolio-2-query-optimisation/
├── portfolio-3-transactions-concurrency/
├── portfolio-4-nosql/
├── portfolio-5-distributed-cloud/
└── README.md
```
Each portfolio folder has its own README.

## 8. Progress

| Portfolio | Topic | Status |
|---|---|---|
| 1 | Database design and modelling | Done ✅|
| 2 | Query processing and optimization | Done ✅ |
| 3 | Transactions and concurrency | Done ✅ |
| 4 | NoSQL and advanced data models | Done ✅ |
| 5 | Distributed and cloud database exercise | Done ✅ |

## 9. References

- [ORACLE: schema design](https://docs.oracle.com/en/database/oracle/oracle-database/26/dbiad/db_schemas.html)
- [MongoDB: data modelling](https://www.mongodb.com/docs/manual/data-modeling/)
- [MongoDB: replication](https://www.mongodb.com/docs/manual/replication/)
- [MongoDB: sharding](https://www.mongodb.com/docs/manual/sharding/)
- [Mermaid: ER diagrams](https://mermaid.js.org/syntax/entityRelationshipDiagram.html)
- 
## 10. AI use declaration

I remain the brain behind the idea, case study, method, strategy and explaining the submitted work. I used Copilot and Gemini to help expand on the explanations. Gemini was used to generate sample data, while copilot was used to proof read for grammatical errors.
