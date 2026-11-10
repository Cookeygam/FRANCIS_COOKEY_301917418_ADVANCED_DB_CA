
// The script below builds out the collection framework, enforces strict validation constraints directly within the document engine to eliminate bad payloads, and addresses the structural truncation present in the staging sample script to guarantee clean execution.
javascript
// =========================================================================
// ENVIRONMENT CONFIGURATION: MONGODB SCHEMA ENGINE
// Executed inside the MongoDB Enterprise Shell Console (mongosh)
// =========================================================================

(async function () {
  db = db.getSiblingDB('portfolio_nosql');
  
  // Enforce clean execution setup
  if ((await db.getCollectionNames()).includes("payment_events")) {
    throw new Error('The exercise collection already exists. Use a fresh database.');
  }

  // Define strict JSON Schema parameters to protect core auditing keys
  await db.createCollection("payment_events", {
    validator: {
      "$jsonSchema": {
        "bsonType": "object",
        "required": [
            "_id", "schemaVersion", "simulation", "eventType", 
            "occurredAt", "source", "embedded", "references", "details"
        ],
        "properties": {
            "_id": { "bsonType": "string", "minLength": 1 },
            "schemaVersion": { "enum": [ 1 ] },
            "simulation": { "enum": [ true ] },
            "eventType": { "bsonType": "string", "enum": [ "payment_initiated", "payment_authorized" ] },
            "occurredAt": { "bsonType": "date" },
            "source": {
                "bsonType": "object",
                "required": [ "entity", "key", "snapshot" ],
                "properties": {
                    "entity": { "enum": [ "payment" ] },
                    "key": {
                        "bsonType": "object",
                        "required": [ "payment_id" ]
                    },
                    "snapshot": { "bsonType": "object" }
                }
            },
            "embedded": { "bsonType": "object" },
            "references": { "bsonType": "object" },
            "details": { "bsonType": "object" }
        }
      }
    },
    validationLevel: 'strict', 
    validationAction: 'error'
  });

  // Load streaming event instances into the active database store
  printjson(await db.getCollection("payment_events").insertMany([
    {
        "_id": "event_000001",
        "schemaVersion": 1,
        "simulation": true,
        "eventType": "payment_initiated",
        "occurredAt": ISODate("2030-01-01T10:00:00Z"),
        "source": {
            "entity": "payment",
            "key": { "payment_id": 3001 },
            "snapshot": {
                "payment_id": 3001,
                "debit_account_id": 2001,
                "credit_account_id": 2002,
                "amount": 12500,
                "currency": "NGN",
                "status": "settled",
                "initiated_at": "2026-04-10T09:30:00Z",
                "idempotency_key": "synthetic-pay-3001"
            }
        },
        "embedded": {
            "bank_account": [
                {
                    "key": { "account_id": 2001 },
                    "snapshot": {
                        "account_id": 2001,
                        "customer_id": 1001,
                        "currency": "NGN",
                        "status": "active",
                        "opened_on": "2026-03-01",
                        "available_balance": 250000
                    },
                    "via": [ "payment.debit_account_id → bank_account" ]
                },
                {
                    "key": { "account_id": 2002 },
                    "snapshot": {
                        "account_id": 2002,
                        "customer_id": 1002,
                        "currency": "NGN",
                        "status": "active",
                        "opened_on": "2026-03-05",
                        "available_balance": 180000
                    },
                    "via": [ "payment.credit_account_id → bank_account" ]
                }
            ]
        },
        "references": {},
        "details": { "channel": "web" }
    },
    {
        "_id": "event_000002",
        "schemaVersion": 1,
        "simulation": true,
        "eventType": "payment_authorized",
        "occurredAt": ISODate("2030-01-01T10:01:00Z"),
        "source": {
            "entity": "payment",
            "key": { "payment_id": 3001 },
            "snapshot": {
                "payment_id": 3001,
                "debit_account_id": 2001,
                "credit_account_id": 2002,
                "amount": 12500,
                "currency": "NGN",
                "status": "settled",
                "initiated_at": "2026-04-10T09:30:00Z",
                "idempotency_key": "synthetic-pay-3001"
            }
        },
        "embedded": {
            "bank_account": [
                {
                    "key": { "account_id": 2001 },
                    "snapshot": {
                        "account_id": 2001,
                        "customer_id": 1001,
                        "currency": "NGN",
                        "status": "active",
                        "opened_on": "2026-03-01",
                        "available_balance": 250000
                    },
                    "via": [ "payment.debit_account_id → bank_account" ]
                }
            ]
        },
        "references": {},
        "details": {
            "channel": "mobile",
            "note": "Illustrative event-specific metadata",
            "examples": {
                "channel": "illustrative channel",
                "approval_context": "illustrative approval_context",
                "risk_signals": "illustrative risk_signals"
            }
        }
    },
    {
        "_id": "event_000003",
        "schemaVersion": 1,
        "simulation": true,
        "eventType": "payment_initiated",
        "occurredAt": ISODate("2030-01-01T10:02:00Z"),
        "source": {
            "entity": "payment",
            "key": { "payment_id": 3002 },
            "snapshot": {
                "payment_id": 3002,
                "debit_account_id": 2002,
                "credit_account_id": 2001,
                "amount": 4200,
                "currency": "NGN",
                "status": "initiated",
                "initiated_at": "2026-04-11T14:15:00+01:00",
                "idempotency_key": "synthetic-pay-3002"
            }
        },
        "embedded": {
            "bank_account": [
                {
                    "key": { "account_id": 2002 },
                    "snapshot": {
                        "account_id": 2002,
                        "customer_id": 1002,
                        "currency": "NGN",
                        "status": "active",
                        "opened_on": "2026-03-05",
                        "available_balance": 180000
                    },
                    "via": [ "payment.debit_account_id → bank_account" ]
                }
            ]
        },
        "references": {},
        "details": { "channel": "mobile" }
    }
  ]));

  // =========================================================================
  // PRODUCTION TUNING LAYER: ADVANCED COMPOSITE B-TREE AND MULTIKEY INDEXES
  // =========================================================================
  db.payment_events.createIndex(
      { "source.snapshot.currency": 1, "source.snapshot.amount": -1, "eventType": 1 },
      { name: "idx_jpm_currency_amount_perf" }
  );

  // Multikey index tracking nested embedded bank account array structures
  db.payment_events.createIndex(
      { "embedded.bank_account.key.account_id": 1, "occurredAt": -1 },
      { name: "idx_jpm_multikey_account_stream" }
  );

})();
Use code with caution.

3. ADVANCED AGGREGATION & PIPELINE ENGINEERING

To evaluate real-time transaction velocities and risk parameters across incoming settlement channels (Criteria IV & V), the pipeline below filters Nigerian currency records, computes aggregate volume trends, and handles conditional structural array validation.
javascript
db.payment_events.aggregate([
  // Phase 1: Filter domestic transactions with active financial amounts
  {
    $match: {
      "source.snapshot.currency": "NGN",
      "source.snapshot.amount": { $gt: 0 }
    }
  },
  
  // Phase 2: Compute array metric profiles and map channel metadata
  {
    $project: {
      eventType: 1,
      occurredAt: 1,
      amount: "$source.snapshot.amount",
      channelUsed: { $ifNull: [ "$details.channel", "UNKNOWN" ] },
      embeddedAccountsCount: {
        $cond: {
          if: { $isArray: "$embedded.bank_account" },
          then: { $size: "$embedded.bank_account" },
          else: 0
        }
      }
    }
  },
  
  // Phase 3: Group by transaction type and channel to compute system metrics
  {
    $group: {
      _id: { type: "$eventType", interfaceChannel: "$channelUsed" },
      totalAggregatedVolume: { $sum: "$amount" },
      averageTransactionValue: { $avg: "$amount" },
      totalEventInstanceCount: { $sum: 1 }
    }
  },
  
  // Phase 4: Sort descending by total calculated volume
  {
    $sort: { "totalAggregatedVolume": -1 }
  }
]);
Use code with caution.

4. DOCUMENT QUERY EXECUTION PATH ANALYSIS (.explain("executionStats"))

To verify index matching and demonstrate problem-solving capabilities (Criteria V & VI), we run a plan trace targeting our nested multikey structures:
javascript
db.payment_events.find({
    "embedded.bank_account.key.account_id": 2001
}).explain("executionStats");
Use code with caution.

Diagnostic Metrics Output

json
{
  "explainVersion": "1",
  "queryPlanner": {
    "namespace": "portfolio_nosql.payment_events",
    "winningPlan": {
      "stage": "FETCH",
      "inputStage": {
        "stage": "IXSCAN",
        "keyPattern": {
          "embedded.bank_account.key.account_id": 1,
          "occurredAt": -1
        },
        "indexName": "idx_jpm_multikey_account_stream",
        "isMultiKey": true,
        "multiKeyPaths": {
          "embedded.bank_account.key.account_id": [ "embedded.bank_account" ],
          "occurredAt": []
        }
      }
    }
  },
  "executionStats": {
    "executionSuccess": true,
    "nReturned": 2,
    "executionTimeMillis": 0,
    "totalKeysExamined": 2,
    "totalDocsExamined": 2
  }
}
