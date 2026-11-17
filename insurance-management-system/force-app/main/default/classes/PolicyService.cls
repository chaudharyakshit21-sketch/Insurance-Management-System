/**
 * Query / reporting layer for policies and claims (SOQL).
 */
public with sharing class PolicyService {

    public static List<Insurance_Policy__c> getPoliciesByCustomer(Id customerId) {
        return [
            SELECT Id, Name, Policy_Type__c, Policy_Subtype__c, Premium_Amount__c,
                   Coverage_Amount__c, Start_Date__c, End_Date__c, Status__c
            FROM Insurance_Policy__c
            WHERE Customer__c = :customerId
            ORDER BY Start_Date__c DESC
        ];
    }

    public static List<Insurance_Policy__c> getExpiringPolicies(Integer withinDays) {
        Date today = Date.today();
        Date limitDate = today.addDays(withinDays);
        return [
            SELECT Id, Name, Customer__c, Customer__r.Name, Customer__r.Email__c,
                   Policy_Type__c, End_Date__c, Premium_Amount__c
            FROM Insurance_Policy__c
            WHERE Status__c = 'Active' AND End_Date__c >= :today AND End_Date__c <= :limitDate
            ORDER BY End_Date__c ASC
        ];
    }

    /** Total active premium grouped by policy type. */
    public static Map<String, Decimal> getPremiumByPolicyType() {
        Map<String, Decimal> result = new Map<String, Decimal>();
        for (AggregateResult ar : [
            SELECT Policy_Type__c pType, SUM(Premium_Amount__c) total
            FROM Insurance_Policy__c
            WHERE Status__c = 'Active'
            GROUP BY Policy_Type__c
        ]) {
            result.put((String) ar.get('pType'), (Decimal) ar.get('total'));
        }
        return result;
    }

    /** Sum of approved claim amounts for a customer. */
    public static Decimal getApprovedClaimsTotal(Id customerId) {
        AggregateResult[] rows = [
            SELECT SUM(Claim_Amount__c) total
            FROM Insurance_Claim__c
            WHERE Policy__r.Customer__c = :customerId AND Status__c = 'Approved'
        ];
        Decimal total = (Decimal) rows[0].get('total');
        return total == null ? 0 : total;
    }

    public static List<Insurance_Claim__c> getOpenClaims() {
        return [
            SELECT Id, Name, Claim_Amount__c, Claim_Date__c, Status__c,
                   Policy__r.Name, Policy__r.Customer__r.Name
            FROM Insurance_Claim__c
            WHERE Status__c IN ('Submitted', 'Under Review')
            ORDER BY Claim_Date__c ASC
            LIMIT 200
        ];
    }

    /** Cancels a policy; DML is performed with sharing rules enforced. */
    public static void cancelPolicy(Id policyId) {
        Insurance_Policy__c policy = [SELECT Id, Status__c FROM Insurance_Policy__c WHERE Id = :policyId LIMIT 1];
        policy.Status__c = 'Cancelled';
        update policy;
    }
}
