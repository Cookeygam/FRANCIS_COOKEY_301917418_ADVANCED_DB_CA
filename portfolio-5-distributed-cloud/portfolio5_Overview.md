# Distributed and Cloud Database Exercise

## JPMorgan Chase Nigeria - Distributed Banking Database Architecture

**Course:** MIT 8103 – Advanced Database Systems  
**Academic Session:** 2026/2027  
**Portfolio Activity:** Portfolio 5  
**Database Platform:** Oracle Database 19c

---

# Overview

The previous portfolio activities focused on designing and implementing a banking database using Oracle Database 19c. Customer records, account information, transaction journals, account balances, and compliance records were modelled using relational database principles to ensure accuracy and consistency across the system.

While the logical database design defines how data is stored, banks must also consider how the database is deployed and protected in a real-world environment.

For an institution such as JPMorgan Chase Nigeria, database availability is a critical business requirement. Customers expect banking services to be available at any time through mobile applications, internet banking platforms, ATMs, and physical branches. Any prolonged outage may prevent customers from accessing their accounts, completing transactions, or retrieving account information.

A single database server creates a significant operational risk because a hardware failure, software fault, maintenance activity, or network disruption could make banking services unavailable.

This portfolio therefore examines how the banking system developed in previous portfolios can be deployed using distributed database concepts to improve availability, fault tolerance, operational resilience, and disaster recovery capabilities.

Rather than redesigning the database itself, the focus of this exercise is on how the existing Oracle banking system can be distributed across multiple locations while ensuring continued access to business-critical data.

---

# Design Rationale

The distributed architecture proposed for this portfolio was designed around the operational realities of modern banking systems.

In earlier portfolios, the Oracle database was deployed as a single logical database containing:

- Customer information
- Account master records
- Transaction journals
- Product information
- AML audit records
- Ledger-related data

Although this design provides a reliable source of truth, deploying all services on a single database server introduces a single point of failure.

Consider a situation where the primary database server hosting customer and transaction data becomes unavailable due to:

- Hardware failure
- Data centre power outage
- Network connectivity issues
- Operating system corruption
- Planned maintenance activities

Without an alternative database location, banking operations could be interrupted, preventing customers from performing routine transactions.

To reduce this risk, the proposed design introduces replication across multiple sites. Replication ensures that copies of the banking database are available even if one server becomes unavailable.

This approach supports both business continuity and disaster recovery objectives while allowing critical banking services to remain accessible during infrastructure failures.

For a banking environment where customer trust and continuous service availability are essential, distributed deployment is therefore a practical operational requirement rather than simply a technical enhancement.

---

# Proposed Distributed Architecture

The proposed deployment consists of three database locations.

## Primary Data Centre - Lagos

The Lagos data centre serves as the primary production environment.

This server processes live banking activities including:

- Customer onboarding
- Account creation
- Deposits and withdrawals
- Funds transfers
- Account updates
- Transaction posting

All write operations are performed against the primary database to maintain transactional consistency.

---

## Secondary Data Centre - Abuja

The Abuja data centre maintains a replicated copy of the production database.

This server provides an additional layer of protection by maintaining an up-to-date copy of transactional and customer data.

The Abuja database can also be used for:

- Reporting activities
- Internal analytics
- Compliance reviews
- Read-only operational queries

Separating reporting workloads from transaction processing helps reduce pressure on the production environment.

---

## Disaster Recovery Site - Port Harcourt

The Port Harcourt location functions as the disaster recovery site.

Its primary purpose is to maintain a recoverable database copy that can be activated if both the Lagos and Abuja environments become unavailable.

While such scenarios may be uncommon, banking systems must be designed around worst-case operating conditions.

Maintaining a disaster recovery site helps ensure that customer data remains recoverable even during catastrophic infrastructure failures.

---
# Cloud deployment, Replication and recovery

A real deployment would use private networking, authentication, least-privilege roles, TLS, monitoring and tested backups. Replication also copies accidental deletions, so it does not replace backups. Availability zones do not provide regional disaster recovery. No cloud service was provisioned and no failover, replication, sharding or recovery experiment was run for this discussion.


## Replication Strategy

Replication forms the foundation of the distributed design.

Whenever a transaction is successfully posted within the banking application, the data is first committed to the primary database located in Lagos.

The changes are then transmitted to the secondary environments where replicated copies of the database are maintained.

For example, when a customer performs a transfer through the mobile banking platform:

1. The transfer request is processed by the application.
2. The transaction is written to the primary Oracle database.
3. The transaction details are replicated to Abuja.
4. The updated records are subsequently replicated to the disaster recovery environment.

This process ensures that customer, account, and transaction information remains available across multiple locations.

As a result, the loss of a single server does not immediately result in the loss of business-critical data.

---

# Availability and Failover

One of the major benefits of a distributed database architecture is improved availability.

Within a banking environment, customers expect uninterrupted access to services regardless of infrastructure problems occurring behind the scenes.

Consider the following scenario:

A hardware fault causes the Lagos production database to become unavailable.

In a single-server environment, all dependent services may stop functioning until the server is repaired.

Within the proposed architecture, operations can continue by promoting the Abuja replica to become the active production database.

This failover capability significantly reduces downtime and helps maintain business continuity.

Although failover procedures require careful planning and testing, they provide a practical mechanism for maintaining service availability during unexpected outages.

---

# Scalability Considerations

Another benefit of the distributed design is improved scalability.

The volume of banking transactions generally increases as customer adoption grows.

Examples include:

- Mobile banking activity
- ATM usage
- Online transfers
- Internal reporting requests
- Regulatory compliance reviews

Running all activities against a single database server can create performance bottlenecks.

By using replicated database nodes, certain read-heavy activities such as:

- Reporting
- Analytics
- Compliance reviews
- Historical transaction searches

can be redirected away from the primary transaction-processing server.

This helps preserve resources for critical operational transactions while still supporting business reporting requirements.

---

# Security and Data Protection Considerations

Because banking information is highly sensitive, replication alone is not sufficient.

The distributed environment must also incorporate security controls including:

- Database authentication
- Role-based access control
- Data encryption
- Audit logging
- Backup management
- Network security controls

Replicating data across multiple locations improves availability, but it also increases the responsibility to protect that data consistently across all sites.

For this reason, security policies must be applied uniformly throughout the distributed environment.

---

# Evaluation

The distributed architecture provides several practical benefits for the JPMorgan Chase Nigeria case study.

First, it removes the dependency on a single database server, reducing the impact of hardware failures and operational disruptions.

Second, it supports disaster recovery planning by maintaining multiple copies of critical banking data across separate locations.

Third, it improves system availability by providing alternative database servers that can be activated during outages.

Finally, it improves overall scalability by allowing reporting and analytical workloads to be separated from transaction-processing activities.

These advantages are especially important within a banking environment where service availability, data protection, and operational continuity are fundamental business requirements.

---

# Conclusion

The database designed in previous portfolios provides the logical foundation for the JPMorgan Chase Nigeria banking system. This portfolio extends that work by examining how the same database can be deployed within a distributed environment.

The proposed architecture uses a primary production database in Lagos, a replicated secondary database in Abuja, and a disaster recovery site in Port Harcourt. This approach improves availability, supports disaster recovery objectives, and reduces the operational risks associated with a single-server deployment.

For a banking organisation that must provide continuous access to financial services, a distributed database architecture represents a practical and effective strategy for maintaining reliability and resilience.
