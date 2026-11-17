trigger InsuranceClaimTrigger on Insurance_Claim__c (before update) {
    ClaimTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
}
