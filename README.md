# Insurance Management System (Salesforce CRM)

A full-cycle Salesforce application that manages **customer profiles, insurance policies and claims**, built with custom objects, relationships, validation rules, Apex and SOQL.

## Features
- **Data model**: `Insurance_Customer__c` → (Master-Detail) → `Insurance_Policy__c` → (Master-Detail) → `Insurance_Claim__c`, plus a **Lookup** from Policy to `User` (sales agent).
- **Controlled (dependent) picklists**: *Policy Type* controls *Policy Subtype*.
- **Roll-up summaries**: policies per customer, active premium total, claims per policy, approved claim total.
- **Validation rules** (11): customer age ≥ 18, phone format, end date after start date, claim ≤ coverage, claim within policy term, no future claims, rejection reason required, etc.
- **Apex**: `PolicyService` (SOQL / aggregate queries), `PremiumCalculator`, trigger handlers (auto-expiry, duplicate-policy guard, decision-date stamping), `PolicyExpiryBatch` (Batch + Schedulable).
- **Test classes** covering positive, negative and bulk (100 records) scenarios.
- **Sample data script** that loads ~200 customers, ~400 policies and ~100 claims.

## Data model
```
Insurance_Customer__c
 └── Insurance_Policy__c   (Master-Detail: Customer__c,  Lookup: Agent__c -> User)
      └── Insurance_Claim__c   (Master-Detail: Policy__c)
```

## Getting started
Prerequisites: [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) and a free [Developer Edition org](https://developer.salesforce.com/signup).

```bash
# 1. Authorise your org
sf org login web --alias insurance-dev

# 2. Deploy the project
sf project deploy start --source-dir force-app --target-org insurance-dev

# 3. Give yourself access to the app
sf org assign permset --name Insurance_Manager --target-org insurance-dev

# 4. Load ~700 simulated records
sf apex run --file scripts/apex/load-sample-data.apex --target-org insurance-dev

# 5. Run the Apex tests
sf apex run test --test-level RunLocalTests --result-format human --code-coverage --target-org insurance-dev

# 6. Open the org and use the "Insurance Management" app
sf org open --target-org insurance-dev
```

Schedule the nightly expiry job (Developer Console → Anonymous Apex):
```apex
System.schedule('Policy Expiry', '0 0 1 * * ?', new PolicyExpiryBatch());
```

## Project structure
```
force-app/main/default
├── applications/      Insurance Management app
├── classes/           Apex services, handlers, batch, tests
├── objects/           3 custom objects, fields, roll-ups, validation rules
├── permissionsets/    Insurance_Manager
├── tabs/
└── triggers/          InsurancePolicyTrigger, InsuranceClaimTrigger
scripts/apex/          Sample-data loader
```

## Tech stack
Salesforce CRM · Apex · SOQL · Custom Objects · Validation Rules · Salesforce DX
