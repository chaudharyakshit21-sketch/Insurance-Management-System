@IsTest
private class PolicyTriggerHandlerTest {

    @IsTest
    static void duplicateActivePolicyOfSameTypeIsBlocked() {
        Insurance_Customer__c c = InsuranceTestDataFactory.createCustomers(1, true)[0];
        insert InsuranceTestDataFactory.buildPolicy(c.Id, 'Life', 'Term Life', 'Active');

        Test.startTest();
        Database.SaveResult sr = Database.insert(InsuranceTestDataFactory.buildPolicy(c.Id, 'Life', 'Whole Life', 'Active'), false);
        Test.stopTest();

        System.assert(!sr.isSuccess());
        System.assert(sr.getErrors()[0].getMessage().contains('overlapping Active'));
    }

    @IsTest
    static void differentTypesAreAllowed() {
        Insurance_Customer__c c = InsuranceTestDataFactory.createCustomers(1, true)[0];
        List<Insurance_Policy__c> policies = new List<Insurance_Policy__c>{
            InsuranceTestDataFactory.buildPolicy(c.Id, 'Life', 'Term Life', 'Active'),
            InsuranceTestDataFactory.buildPolicy(c.Id, 'Home', 'Building', 'Active')
        };
        insert policies;
        System.assertEquals(2, [SELECT COUNT() FROM Insurance_Policy__c WHERE Customer__c = :c.Id]);
    }

    @IsTest
    static void activePolicyPastEndDateIsAutoExpired() {
        Insurance_Customer__c c = InsuranceTestDataFactory.createCustomers(1, true)[0];
        Insurance_Policy__c p = InsuranceTestDataFactory.buildPolicy(c.Id, 'Auto', 'Third Party', 'Active');
        p.Start_Date__c = Date.today().addYears(-2);
        p.End_Date__c = Date.today().addDays(-1);
        insert p;
        System.assertEquals('Expired', [SELECT Status__c FROM Insurance_Policy__c WHERE Id = :p.Id].Status__c);
    }

    @IsTest
    static void bulkInsertIsGovernorSafe() {
        List<Insurance_Customer__c> customers = InsuranceTestDataFactory.createCustomers(100, true);
        List<Insurance_Policy__c> policies = new List<Insurance_Policy__c>();
        for (Insurance_Customer__c c : customers) {
            policies.add(InsuranceTestDataFactory.buildPolicy(c.Id, 'Health', 'Individual', 'Active'));
        }
        insert policies;
        System.assertEquals(100, [SELECT COUNT() FROM Insurance_Policy__c]);
    }

    @IsTest
    static void validationRulesRejectBadData() {
        Insurance_Customer__c c = InsuranceTestDataFactory.createCustomers(1, true)[0];
        Insurance_Policy__c badDates = InsuranceTestDataFactory.buildPolicy(c.Id, 'Life', 'Term Life', 'Draft');
        badDates.End_Date__c = badDates.Start_Date__c.addDays(-1);
        System.assert(!Database.insert(badDates, false).isSuccess());

        Insurance_Customer__c minor = InsuranceTestDataFactory.createCustomers(1, false)[0];
        minor.Date_of_Birth__c = Date.today().addYears(-10);
        System.assert(!Database.insert(minor, false).isSuccess());
    }

    @IsTest
    static void claimAboveCoverageIsRejected() {
        Insurance_Customer__c c = InsuranceTestDataFactory.createCustomers(1, true)[0];
        Insurance_Policy__c p = InsuranceTestDataFactory.buildPolicy(c.Id, 'Life', 'Term Life', 'Active');
        insert p;
        Database.SaveResult sr = Database.insert(InsuranceTestDataFactory.buildClaim(p.Id, 9999999), false);
        System.assert(!sr.isSuccess());
    }

    @IsTest
    static void claimDecisionStampsDecisionDate() {
        Insurance_Customer__c c = InsuranceTestDataFactory.createCustomers(1, true)[0];
        Insurance_Policy__c p = InsuranceTestDataFactory.buildPolicy(c.Id, 'Life', 'Term Life', 'Active');
        insert p;
        Insurance_Claim__c claim = InsuranceTestDataFactory.buildClaim(p.Id, 1000);
        insert claim;
        claim.Status__c = 'Approved';
        update claim;
        System.assertEquals(Date.today(), [SELECT Decision_Date__c FROM Insurance_Claim__c WHERE Id = :claim.Id].Decision_Date__c);
    }
}
