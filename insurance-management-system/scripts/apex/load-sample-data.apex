// Loads ~200 customers, ~400 policies and ~100 claims of simulated data.
// Run:  sf apex run --file scripts/apex/load-sample-data.apex
String[] firstNames = new String[]{'Aarav','Vivaan','Aditya','Arjun','Rohan','Ishaan','Kabir','Anaya','Diya','Meera','Priya','Sneha','Kavya','Riya','Neha','Rahul','Amit','Pooja','Karan','Simran'};
String[] lastNames  = new String[]{'Sharma','Verma','Gupta','Singh','Chaudhary','Kumar','Yadav','Mishra','Jain','Agarwal','Tyagi','Malik','Saxena','Rana','Tomar'};
String[] cities     = new String[]{'Bijnor','Meerut','Lucknow','Noida','Delhi','Dehradun','Agra','Kanpur'};
String[] types      = new String[]{'Life','Health','Auto','Home'};
Map<String, String> subtypeFor = new Map<String, String>{
    'Life' => 'Term Life', 'Health' => 'Family Floater', 'Auto' => 'Comprehensive', 'Home' => 'Building'
};

List<Insurance_Customer__c> customers = new List<Insurance_Customer__c>();
for (Integer i = 0; i < 200; i++) {
    customers.add(new Insurance_Customer__c(
        Name = firstNames[Math.mod(i, firstNames.size())] + ' ' + lastNames[Math.mod(i * 7, lastNames.size())],
        Email__c = 'customer' + i + '@example.com',
        Phone__c = '98' + String.valueOf(10000000 + i * 13),
        Date_of_Birth__c = Date.today().addYears(-(22 + Math.mod(i * 3, 40))),
        City__c = cities[Math.mod(i, cities.size())],
        State__c = 'Uttar Pradesh',
        Address__c = 'House ' + (i + 1) + ', Civil Lines, ' + cities[Math.mod(i, cities.size())],
        Customer_Status__c = 'Active'
    ));
}
insert customers;

List<Insurance_Policy__c> policies = new List<Insurance_Policy__c>();
for (Integer i = 0; i < customers.size(); i++) {
    Integer policyCount = 1 + Math.mod(i, 3);
    for (Integer k = 0; k < policyCount; k++) {
        String t = types[Math.mod(i + k, 4)];
        Decimal coverage = 100000 + Math.mod(i * 37, 20) * 50000;
        Date startDate = Date.today().addMonths(-Math.mod(i * 7, 24));
        policies.add(new Insurance_Policy__c(
            Customer__c = customers[i].Id,
            Policy_Type__c = t,
            Policy_Subtype__c = subtypeFor.get(t),
            Coverage_Amount__c = coverage,
            Premium_Amount__c = PremiumCalculator.calculate(t, coverage, customers[i].Date_of_Birth__c),
            Start_Date__c = startDate,
            End_Date__c = startDate.addYears(1 + Math.mod(k, 3)),
            Status__c = 'Active'
        ));
    }
}
insert policies;

Date claimCutoff = Date.today().addDays(-30);
List<Insurance_Claim__c> claims = new List<Insurance_Claim__c>();
Integer seen = 0;
for (Insurance_Policy__c p : [
    SELECT Id, Coverage_Amount__c, Start_Date__c, End_Date__c
    FROM Insurance_Policy__c
    WHERE Status__c = 'Active' AND Start_Date__c <= :claimCutoff
    LIMIT 400
]) {
    seen++;
    if (Math.mod(seen, 3) == 0 && claims.size() < 100) {
        claims.add(new Insurance_Claim__c(
            Policy__c = p.Id,
            Claim_Amount__c = p.Coverage_Amount__c * 0.1,
            Claim_Date__c = p.Start_Date__c.addDays(30),
            Description__c = 'Simulated claim for demo data'
        ));
    }
}
insert claims;

List<Insurance_Claim__c> toDecide = new List<Insurance_Claim__c>();
for (Integer i = 0; i < claims.size(); i++) {
    if (Math.mod(i, 3) == 0) {
        claims[i].Status__c = 'Approved';
        toDecide.add(claims[i]);
    } else if (Math.mod(i, 3) == 1) {
        claims[i].Status__c = 'Rejected';
        claims[i].Rejection_Reason__c = 'Documents incomplete';
        toDecide.add(claims[i]);
    } else {
        claims[i].Status__c = 'Under Review';
        toDecide.add(claims[i]);
    }
}
update toDecide;
System.debug('Loaded ' + customers.size() + ' customers, ' + policies.size() + ' policies, ' + claims.size() + ' claims.');
