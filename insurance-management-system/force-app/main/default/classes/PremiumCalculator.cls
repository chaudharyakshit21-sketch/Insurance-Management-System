/**
 * Calculates an indicative annual premium from policy type, coverage and customer age.
 */
public with sharing class PremiumCalculator {

    private static final Map<String, Decimal> BASE_RATES = new Map<String, Decimal>{
        'Life'   => 0.012,
        'Health' => 0.020,
        'Auto'   => 0.035,
        'Home'   => 0.008
    };

    public static Decimal calculate(String policyType, Decimal coverage, Date dateOfBirth) {
        if (String.isBlank(policyType) || coverage == null || coverage <= 0) {
            return 0;
        }
        Decimal rate = BASE_RATES.containsKey(policyType) ? BASE_RATES.get(policyType) : 0.02;
        return (coverage * rate * ageFactor(dateOfBirth)).setScale(2);
    }

    @TestVisible
    private static Decimal ageFactor(Date dateOfBirth) {
        if (dateOfBirth == null) {
            return 1.0;
        }
        Integer age = Date.today().year() - dateOfBirth.year();
        if (Date.today() < dateOfBirth.addYears(age)) {
            age--;
        }
        if (age < 30) return 0.9;
        if (age < 45) return 1.0;
        if (age < 60) return 1.25;
        return 1.6;
    }
}
