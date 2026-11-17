@IsTest
public class InsuranceTestDataFactory {

    public static List<Insurance_Customer__c> createCustomers(Integer count, Boolean doInsert) {
        List<Insurance_Customer__c> customers = new List<Insurance_Customer__c>();
        for (Integer i = 0; i < count; i++) {
            customers.add(new Insurance_Customer__c(
                Name = 'Test Customer ' + i,
                Email__c = 'test' + i + '@example.com',
                Phone__c = '9876500' + String.valueOf(i).leftPad(3, '0'),
                Date_of_Birth__c = Date.today().addYears(-30),
                City__c = 'Bijnor',
                State__c = 'Uttar Pradesh'
            ));
        }
        if (doInsert) insert customers;
        return customers;
    }

    public static Insurance_Policy__c buildPolicy(Id customerId, String policyType, String subtype, String status) {
        return new Insurance_Policy__c(
            Customer__c = customerId,
            Policy_Type__c = policyType,
            Policy_Subtype__c = subtype,
            Premium_Amount__c = 5000,
            Coverage_Amount__c = 500000,
            Start_Date__c = Date.today().addMonths(-2),
            End_Date__c = Date.today().addMonths(10),
            Status__c = status
        );
    }

    public static Insurance_Claim__c buildClaim(Id policyId, Decimal amount) {
        return new Insurance_Claim__c(
            Policy__c = policyId,
            Claim_Amount__c = amount,
            Claim_Date__c = Date.today().addDays(-5),
            Description__c = 'Test claim'
        );
    }
}
