/**
 * Business logic for Insurance_Policy__c:
 *  - auto-expire policies whose end date has passed
 *  - block overlapping Active policies of the same type for the same customer
 */
public with sharing class PolicyTriggerHandler {

    @TestVisible
    private static Boolean bypass = false;

    public static void beforeInsert(List<Insurance_Policy__c> newList) {
        if (bypass) return;
        markExpired(newList);
        preventDuplicateActive(newList);
    }

    public static void beforeUpdate(List<Insurance_Policy__c> newList, Map<Id, Insurance_Policy__c> oldMap) {
        if (bypass) return;
        markExpired(newList);
        preventDuplicateActive(newList);
    }

    private static void markExpired(List<Insurance_Policy__c> policies) {
        for (Insurance_Policy__c p : policies) {
            if (p.Status__c == 'Active' && p.End_Date__c != null && p.End_Date__c < Date.today()) {
                p.Status__c = 'Expired';
            }
        }
    }

    private static void preventDuplicateActive(List<Insurance_Policy__c> policies) {
        Set<Id> customerIds = new Set<Id>();
        for (Insurance_Policy__c p : policies) {
            if (p.Status__c == 'Active' && p.Customer__c != null) {
                customerIds.add(p.Customer__c);
            }
        }
        if (customerIds.isEmpty()) return;

        Map<String, List<Insurance_Policy__c>> existing = new Map<String, List<Insurance_Policy__c>>();
        for (Insurance_Policy__c e : [
            SELECT Id, Customer__c, Policy_Type__c, Start_Date__c, End_Date__c
            FROM Insurance_Policy__c
            WHERE Customer__c IN :customerIds AND Status__c = 'Active'
        ]) {
            String key = e.Customer__c + '|' + e.Policy_Type__c;
            if (!existing.containsKey(key)) existing.put(key, new List<Insurance_Policy__c>());
            existing.get(key).add(e);
        }

        Map<String, List<Insurance_Policy__c>> inBatch = new Map<String, List<Insurance_Policy__c>>();
        for (Insurance_Policy__c p : policies) {
            if (p.Status__c != 'Active' || p.Customer__c == null) continue;
            String key = p.Customer__c + '|' + p.Policy_Type__c;
            List<Insurance_Policy__c> others = new List<Insurance_Policy__c>();
            if (existing.containsKey(key)) others.addAll(existing.get(key));
            if (inBatch.containsKey(key)) others.addAll(inBatch.get(key));
            for (Insurance_Policy__c o : others) {
                if (o.Id != null && o.Id == p.Id) continue;
                if (o.Start_Date__c <= p.End_Date__c && o.End_Date__c >= p.Start_Date__c) {
                    p.addError('Customer already has an overlapping Active ' + p.Policy_Type__c + ' policy.');
                    break;
                }
            }
            if (!inBatch.containsKey(key)) inBatch.put(key, new List<Insurance_Policy__c>());
            inBatch.get(key).add(p);
        }
    }
}
