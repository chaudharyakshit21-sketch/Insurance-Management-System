trigger InsurancePolicyTrigger on Insurance_Policy__c (before insert, before update) {
    if (Trigger.isInsert) {
        PolicyTriggerHandler.beforeInsert(Trigger.new);
    } else if (Trigger.isUpdate) {
        PolicyTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
}
