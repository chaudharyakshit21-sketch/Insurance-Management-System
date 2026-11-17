@IsTest
private class PremiumCalculatorTest {
    @IsTest
    static void calculatesPremiumByTypeAndAge() {
        Date dob = Date.today().addYears(-35);
        Decimal premium = PremiumCalculator.calculate('Auto', 100000, dob);
        System.assertEquals(3500, premium.intValue(), 'Auto at 3.5% with age factor 1.0');
    }

    @IsTest
    static void olderCustomersPayMore() {
        Decimal young = PremiumCalculator.calculate('Life', 100000, Date.today().addYears(-25));
        Decimal old = PremiumCalculator.calculate('Life', 100000, Date.today().addYears(-65));
        System.assert(old > young, 'Older customers should pay a higher premium');
    }

    @IsTest
    static void invalidInputReturnsZero() {
        System.assertEquals(0, PremiumCalculator.calculate(null, 1000, null).intValue());
        System.assertEquals(0, PremiumCalculator.calculate('Life', 0, null).intValue());
    }
}
