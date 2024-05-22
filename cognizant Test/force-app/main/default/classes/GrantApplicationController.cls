public with sharing class GrantApplicationController {
    @AuraEnabled
    public static String submitApplication(Map<String, Object> applicationData) {
        String firstName = (String)applicationData.get('firstName');
        String lastName = (String)applicationData.get('lastName');
        String phone = (String)applicationData.get('phone');
        String postalCode = (String)applicationData.get('postalCode');
        Decimal monthlyIncome = (Decimal)applicationData.get('monthlyIncome');
        String supportOption = (String)applicationData.get('supportOption');

        // Check if the contact already exists
        Contact existingContact = [SELECT Id FROM Contact WHERE Phone = :phone LIMIT 1];

        if (existingContact == null) {
            // Create a new contact
            Contact newContact = new Contact(
                FirstName = firstName,
                LastName = lastName,
                Phone = phone,
                MailingPostalCode = postalCode,
                Monthly_Income__c = monthlyIncome,
                Support_Option__c = supportOption
            );
            insert newContact;
            existingContact = newContact;
        } else {
            // Update existing contact
            existingContact.FirstName = firstName;
            existingContact.LastName = lastName;
            existingContact.MailingPostalCode = postalCode;
            existingContact.Monthly_Income__c = monthlyIncome;
            existingContact.Support_Option__c = supportOption;
            update existingContact;
        }

        // Process grant disbursement
        processGrantDisbursement(existingContact.Id, monthlyIncome, supportOption);

        return 'Application processed successfully';
    }

    private static void processGrantDisbursement(Id contactId, Decimal monthlyIncome, String supportOption) {
    if (monthlyIncome >= 2000) {
        throw new AuraHandledException('Applicant is not eligible for the grant');
    }

    // Fetch existing disbursed grants
    List<Grant_Disbursed__c> existingGrants = [SELECT Id, Disbursed_Amount__c, Disbursed_Date__c FROM Grant_Disbursed__c WHERE Contact__c = :contactId ];
    Decimal totalDisbursed = 0;
    for (Grant_Disbursed__c grant : existingGrants) {
        totalDisbursed += grant.Disbursed_Amount__c;
    }

    Integer months;
    Decimal amountPerMonth;

    if (supportOption == 'Option1') {
        months = 3;
        amountPerMonth = 500;
    } else if (supportOption == 'Option2') {
        months = 6;
        amountPerMonth = 300;
    } else if (supportOption == 'Option3') {
        months = 12;
        amountPerMonth = 200;
    } else {
        throw new AuraHandledException('Invalid support option selected');
    }

    Decimal totalNewOption = months * amountPerMonth;
    if (totalDisbursed > totalNewOption) {
        throw new AuraHandledException('Cannot change to a support option with less total disbursement');
    }

    // Recalculate remaining amount
    Decimal remainingAmount = totalNewOption - totalDisbursed;
    Integer remainingMonths = months - existingGrants.size();

    Decimal newDisbursementPerMonth = remainingAmount / remainingMonths;

    // Update existing grants
    for (Grant_Disbursed__c grant : existingGrants) {
        grant.Disbursed_Amount__c = newDisbursementPerMonth;
    }
    update existingGrants;

    // Insert new grants for remaining months
    Date disbursementDate = existingGrants.isEmpty() ? Date.today().addMonths(1) : existingGrants[0].Disbursed_Date__c.addMonths(1);
    List<Grant_Disbursed__c> newGrants = new List<Grant_Disbursed__c>();
    for (Integer i = existingGrants.size(); i < months; i++) {
        newGrants.add(new Grant_Disbursed__c(
            Contact__c = contactId,
            Disbursed_Amount__c = newDisbursementPerMonth,
            Grant_is_disbursed__c = true,
            Disbursed_Date__c = disbursementDate
        ));
        disbursementDate = disbursementDate.addMonths(1);
    }

    insert newGrants;
}

}