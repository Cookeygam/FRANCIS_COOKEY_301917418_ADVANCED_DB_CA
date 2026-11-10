
 ## Figure 1: Distributed Banking Database Architecture
```
                         
                         JPMORGAN CHASE NIGERIA
                    DISTRIBUTED DATABASE ARCHITECTURE

                                    Users
                                       │
            ┌──────────────────────────┼──────────────────────────┐
            │                          │                          │
            ▼                          ▼                          ▼

       Mobile App              Internet Banking             Branch Systems
            │                          │                          │
            └─────────────── Load Balancer / API Layer ───────────┘
                                       │
                                       ▼

                    ┌─────────────────────────────┐
                    │  Oracle Database Primary    │
                    │     Lagos Data Centre       │
                    │                             │
                    │ CUSTOMER Schema             │
                    │ TRANSACT Schema             │
                    │ LEDGER Schema               │
                    └─────────────┬───────────────┘
                                  │
                    Real-Time Replication
                                  │
                ┌─────────────────┴──────────────────┐
                │                                    │
                ▼                                    ▼

    ┌──────────────────────┐         ┌─────────────────────────┐
    │ Secondary Database   │         │ Disaster Recovery Site  │
    │ Abuja Data Centre    │         │ Port Harcourt           │
    │                      │         │                         │
    │ Reporting Server     │         │ Recovery Database       │
    │ Read-Only Queries    │         │ Backup Copy             │
    └──────────────────────┘         └─────────────────────────┘
                │
                │ Failover
                ▼

      Becomes Primary Database
      if Lagos Becomes Unavailable
```

## Figure 2: Replication and Failover Process
```text
 ┌─────────────────────┐
 │ Customer Transfer   │
 │ via Mobile Banking  │
 └──────────┬──────────┘
            │
            ▼

 ┌─────────────────────┐
 │ Lagos Primary DB    │
 │ Transaction Posted  │
 └──────────┬──────────┘
            │
            ▼

 ┌─────────────────────┐
 │ Replication Engine  │
 └───────┬───────┬─────┘
         │       │
         ▼       ▼

 ┌─────────────┐   ┌─────────────┐
 │ Abuja Site  │   │ Port Harc.  │
 │ Replica DB  │   │ DR Replica  │
 └─────────────┘   └─────────────┘

                If Failure
                      │
                      ▼

          ┌─────────────────────┐
          │ Abuja Promoted to   │
          │ Primary Database    │
          └─────────────────────┘
    
```
## Figure 3: Workload Distribution

```text
                     PRIMARY DATABASE
                         (LAGOS)

                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │

        ▼                     ▼                     ▼

 Customer Updates      Fund Transfers       Transaction Posting
    (Writes)              (Writes)               (Writes)

                              │
                              ▼

                    Database Replication

                              │
                              ▼

                     REPLICA DATABASE
                          (ABUJA)

        ┌─────────────────────┼─────────────────────┐
        │                     │                     │

        ▼                     ▼                     ▼

 AML Reports          Management Reports    Historical Queries
 (Read Only)             (Read Only)          (Read Only)

```
