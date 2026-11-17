@IsTest
private class PolicyServiceTest {

    @TestSetup
    static void setup() {
        List<Insurance_Customer__c> customers = InsuranceTestDataFactory.createCustomers(2, true);
        List<Insurance_Policy__c> policies = new List<Insurance_Policy__c>{
            InsuranceTestDataFactory.buildPolicy(customers[0].Id, 'Life', 'Term Life', 'Active'),
            InsuranceTestDataFactory.buildPolicy(customers[0].Id, 'Health', 'Individual', 'Active'),
            InsuranceTestDataFactory.buildPolicy(customers[1].Id, 'Auto', 'Comprehensive', 'Active')
        };
        policies[2].End_Date__c = Date.today().addDays(10);
        insert policies;
    }

    @IsTest
    static void getPoliciesByCustomerReturnsOnlyThatCustomer() {
        Insurance_Customer__c c = [SELECT Id FROM Insurance_Customer__c WHERE Name = 'Test Customer 0'];
        System.assertEquals(2, PolicyService.getPoliciesByCustomer(c.Id).size());
    }

    @IsTest
    static void getExpiringPoliciesFindsPolicyEndingSoon() {
        List<Insurance_Policy__c> expiring = PolicyService.getExpiringPolicies(30);
        System.assertEquals(1, expiring.size());
        System.assertEquals('Auto', expiring[0].Policy_Type__c);
    }

    @IsTest
    static void premiumByTypeAggregatesActivePolicies() {
        Map<String, Decimal> totals = PolicyService.getPremiumByPolicyType();
        System.assertEquals(5000, totals.get('Life').intValue());
        System.assertEquals(3, [SELECT COUNT() FROM Insurance_Policy__c WHERE Status__c = 'Active']);
    }

    @IsTest
    static void approvedClaimsTotalAndOpenClaims() {
        Insurance_Customer__c c = [SELECT Id FROM Insurance_Customer__c WHERE Name = 'Test Customer 0'];
        Insurance_Policy__c p = [SELECT Id FROM Insurance_Policy__c WHERE Customer__c = :c.Id AND Policy_Type__c = 'Life'];
        Insurance_Claim__c claim = InsuranceTestDataFactory.buildClaim(p.Id, 20000);
        insert claim;
        System.assertEquals(1, PolicyService.getOpenClaims().size());
        System.assertEquals(0, PolicyService.getApprovedClaimsTotal(c.Id).intValue());

        claim.Status__c = 'Approved';
        update claim;
        System.assertEquals(20000, PolicyService.getApprovedClaimsTotal(c.Id).intValue());
        System.assertEquals(0, PolicyService.getOpenClaims().size());
    }

    @IsTest
    static void cancelPolicySetsStatus() {
        Insurance_Policy__c p = [SELECT Id FROM Insurance_Policy__c LIMIT 1];
        PolicyService.cancelPolicy(p.Id);
        System.assertEquals('Cancelled', [SELECT Status__c FROM Insurance_Policy__c WHERE Id = :p.Id].Status__c);
    }

    @IsTest
    static void rollupSummariesCalculate() {
        Insurance_Customer__c c = [SELECT Policy_Count__c, Active_Premium_Total__c FROM Insurance_Customer__c WHERE Name = 'Test Customer 0'];
        System.assertEquals(2, c.Policy_Count__c.intValue());
        System.assertEquals(10000, c.Active_Premium_Total__c.intValue());
    }
}
