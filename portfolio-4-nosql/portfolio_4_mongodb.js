// =====================================================
// Portfolio 4 - NoSQL and Advanced Data Models
// JPMorgan Chase & Co. Case Study
// MongoDB Implementation
// =====================================================

// Create Database
use("jpmorgan_nosql");

// Create Collection
db.createCollection("transaction_events");

// =====================================================
// Insert Sample Documents
// =====================================================

db.transaction_events.insertMany([

{
    transaction_id: "TXN100001",
    account_id: "ACC10001",
    customer_reference: "CIF10001",
    transaction_date: new Date("2026-11-01T10:30:00Z"),
    amount: 25000,
    currency: "NGN",
    transaction_type: "TRANSFER",
    channel: "MOBILE_BANKING",
    status: "SUCCESSFUL",
    metadata: {
        device_type: "Android",
        location: "Lagos",
        beneficiary_reference: "BEN10001"
    }
},

{
    transaction_id: "TXN100002",
    account_id: "ACC10002",
    customer_reference: "CIF10002",
    transaction_date: new Date("2026-11-02T09:15:00Z"),
    amount: 15000,
    currency: "NGN",
    transaction_type: "WITHDRAWAL",
    channel: "ATM",
    status: "SUCCESSFUL",
    metadata: {
        terminal_id: "ATM-001",
        location: "Abuja"
    }
},

{
    transaction_id: "TXN100003",
    account_id: "ACC10001",
    customer_reference: "CIF10001",
    transaction_date: new Date("2026-11-03T14:05:00Z"),
    amount: 5000,
    currency: "NGN",
    transaction_type: "BILL_PAYMENT",
    channel: "INTERNET_BANKING",
    status: "PENDING",
    metadata: {
        beneficiary: "Electricity Company",
        channel_reference: "WEB20261103"
    }
},

{
    transaction_id: "TXN100004",
    account_id: "ACC10003",
    customer_reference: "CIF10003",
    transaction_date: new Date("2026-11-04T16:45:00Z"),
    amount: 120000,
    currency: "NGN",
    transaction_type: "TRANSFER",
    channel: "BRANCH",
    status: "SUCCESSFUL",
    metadata: {
        approval_officer: "OFF001",
        branch_code: "0001"
    }
}
]);

// =====================================================
// Retrieve Transactions by Account
// =====================================================

db.transaction_events.find({
    account_id: "ACC10001"
});

// =====================================================
// Retrieve Successful Transactions
// =====================================================

db.transaction_events.find({
    status: "SUCCESSFUL"
});

// =====================================================
// Filter by Date Range
// =====================================================

db.transaction_events.find({
    transaction_date: {
        $gte: new Date("2026-11-01"),
        $lte: new Date("2026-11-30")
    }
});

// =====================================================
// Aggregation by Channel
// =====================================================

db.transaction_events.aggregate([
{
    $group: {
        _id: "$channel",
        totalTransactions: { $sum: 1 },
        totalAmount: { $sum: "$amount" }
    }
}
]);

// =====================================================
// Create Index
// =====================================================

db.transaction_events.createIndex({
    account_id: 1,
    transaction_date: 1
});

// =====================================================
// Update a Transaction
// =====================================================

db.transaction_events.updateOne(
{
    transaction_id: "TXN100003"
},
{
    $set: {
        status: "SUCCESSFUL"
    }
}
);

// Verify Update

db.transaction_events.find({
    transaction_id: "TXN100003"
});
