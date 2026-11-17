/**
 * Stamps the decision date when a claim is approved or rejected.
 */
public with sharing class ClaimTriggerHandler {

    public static void beforeUpdate(List<Insurance_Claim__c> newList, Map<Id, Insurance_Claim__c> oldMap) {
        for (Insurance_Claim__c c : newList) {
            Insurance_Claim__c old = oldMap.get(c.Id);
            Boolean decided = c.Status__c == 'Approved' || c.Status__c == 'Rejected';
            if (decided && c.Status__c != old.Status__c && c.Decision_Date__c == null) {
                c.Decision_Date__c = Date.today();
            }
        }
    }
}
