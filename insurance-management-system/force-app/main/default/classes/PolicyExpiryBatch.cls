/**
 * Nightly job: flips Active policies past their end date to Expired.
 * Schedule: System.schedule('Policy Expiry', '0 0 1 * * ?', new PolicyExpiryBatch());
 */
public with sharing class PolicyExpiryBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c FROM Insurance_Policy__c
            WHERE Status__c = 'Active' AND End_Date__c < TODAY
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Insurance_Policy__c> scope) {
        for (Insurance_Policy__c p : scope) {
            p.Status__c = 'Expired';
        }
        Database.SaveResult[] results = Database.update(scope, false);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'Expiry update failed: ' + sr.getErrors()[0].getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('PolicyExpiryBatch finished: ' + bc.getJobId());
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new PolicyExpiryBatch(), 200);
    }
}
