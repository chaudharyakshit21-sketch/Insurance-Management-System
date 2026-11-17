@IsTest
private class PolicyExpiryBatchTest {

    @IsTest
    static void batchExpiresPastDuePolicies() {
        Insurance_Customer__c c = InsuranceTestDataFactory.createCustomers(1, true)[0];
        Insurance_Policy__c p = InsuranceTestDataFactory.buildPolicy(c.Id, 'Home', 'Building', 'Active');
        p.Start_Date__c = Date.today().addYears(-2);
        p.End_Date__c = Date.today().addDays(-3);

        PolicyTriggerHandler.bypass = true; // bypass auto-expiry so the batch has work to do
        insert p;
        PolicyTriggerHandler.bypass = false;
        System.assertEquals('Active', [SELECT Status__c FROM Insurance_Policy__c WHERE Id = :p.Id].Status__c);

        Test.startTest();
        Database.executeBatch(new PolicyExpiryBatch(), 200);
        Test.stopTest();

        System.assertEquals('Expired', [SELECT Status__c FROM Insurance_Policy__c WHERE Id = :p.Id].Status__c);
    }

    @IsTest
    static void schedulerEnqueuesBatch() {
        Test.startTest();
        String jobId = System.schedule('Policy Expiry Test', '0 0 1 * * ?', new PolicyExpiryBatch());
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}
