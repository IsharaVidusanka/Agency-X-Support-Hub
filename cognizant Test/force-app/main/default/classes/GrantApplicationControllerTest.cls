@isTest
public class GrantApplicationControllerTest {
    
    @isTest
    static void testSubmitNewApplication() {
        // Arrange
        Map<String, Object> applicationData = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            'phone' => '65 68123456',
            'postalCode' => '123456',
            'monthlyIncome' => 1500,
            'supportOption' => 'Option1'
        };

        // Act
        Test.startTest();
        String result = GrantApplicationController.submitApplication(applicationData);
        Test.stopTest();

        // Assert
        Contact contact = [SELECT Id, FirstName, LastName, Phone, MailingPostalCode, Monthly_Income__c, Support_Option__c FROM Contact WHERE Phone = '65 68123456'];
        System.assertEquals('John', contact.FirstName);
        System.assertEquals('Doe', contact.LastName);
        System.assertEquals('65 68123456', contact.Phone);
        System.assertEquals('123456', contact.MailingPostalCode);
        System.assertEquals(1500, contact.Monthly_Income__c);
        System.assertEquals('Option1', contact.Support_Option__c);

        List<Grant_Disbursed__c> grants = [SELECT Disbursed_Amount__c, Disbursed_Date__c FROM Grant_Disbursed__c WHERE Contact__c = :contact.Id];
        System.assertEquals(3, grants.size());
        System.assertEquals(500, grants[0].Disbursed_Amount__c);
        System.assertEquals(Date.today().addMonths(1), grants[0].Disbursed_Date__c);
    }

    @isTest
    static void testUpdateExistingApplication() {
        // Arrange
        Contact existingContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Phone = '65 68123456',
            MailingPostalCode = '654321',
            Monthly_Income__c = 1800,
            Support_Option__c = 'Option2'
        );
        insert existingContact;

        Map<String, Object> applicationData = new Map<String, Object>{
            'firstName' => 'Jane',
            'lastName' => 'Smith',
            'phone' => '65 68123456',
            'postalCode' => '123456',
            'monthlyIncome' => 1500,
            'supportOption' => 'Option1'
        };

        // Act
        Test.startTest();
        String result = GrantApplicationController.submitApplication(applicationData);
        Test.stopTest();

        // Assert
        Contact updatedContact = [SELECT Id, FirstName, LastName, Phone, MailingPostalCode, Monthly_Income__c, Support_Option__c FROM Contact WHERE Phone = '65 68123456'];
        System.assertEquals('Jane', updatedContact.FirstName);
        System.assertEquals('Smith', updatedContact.LastName);
        System.assertEquals('65 68123456', updatedContact.Phone);
        System.assertEquals('123456', updatedContact.MailingPostalCode);
        System.assertEquals(1500, updatedContact.Monthly_Income__c);
        System.assertEquals('Option1', updatedContact.Support_Option__c);

        List<Grant_Disbursed__c> grants = [SELECT Disbursed_Amount__c, Disbursed_Date__c FROM Grant_Disbursed__c WHERE Contact__c = :updatedContact.Id];
        System.assertEquals(3, grants.size());
        System.assertEquals(500, grants[0].Disbursed_Amount__c);
        System.assertEquals(Date.today().addMonths(1), grants[0].Disbursed_Date__c);
    }

    @isTest
    static void testEligibilityCheck() {
        // Arrange
        Map<String, Object> applicationData = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            'phone' => '65 68123456',
            'postalCode' => '123456',
            'monthlyIncome' => 2500,
            'supportOption' => 'Option1'
        };

        // Act
        Test.startTest();
        try {
            String result = GrantApplicationController.submitApplication(applicationData);
            System.assert(false, 'Exception should have been thrown due to ineligibility');
        } catch (Exception e) {
            // Assert
            System.assert(e instanceof AuraHandledException);
            System.assertEquals('Applicant is not eligible for the grant', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testChangeSupportOption() {
        // Arrange
        Contact existingContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Phone = '65 68123456',
            MailingPostalCode = '654321',
            Monthly_Income__c = 1800,
            Support_Option__c = 'Option1'
        );
        insert existingContact;

        // Simulate grant disbursement
        List<Grant_Disbursed__c> grants = new List<Grant_Disbursed__c>();
        for (Integer i = 0; i < 2; i++) {
            grants.add(new Grant_Disbursed__c(
                Contact__c = existingContact.Id,
                Disbursed_Amount__c = 500,
                Grant_is_disbursed__c = true,
                Disbursed_Date__c = Date.today().addMonths(i+1)
            ));
        }
        insert grants;

        Map<String, Object> applicationData = new Map<String, Object>{
            'firstName' => 'Jane',
            'lastName' => 'Doe',
            'phone' => '65 68123456',
            'postalCode' => '654321',
            'monthlyIncome' => 1800,
            'supportOption' => 'Option2'
        };

        // Act
        Test.startTest();
        String result = GrantApplicationController.submitApplication(applicationData);
        Test.stopTest();

        // Assert
        List<Grant_Disbursed__c> updatedGrants = [SELECT Disbursed_Amount__c, Disbursed_Date__c FROM Grant_Disbursed__c WHERE Contact__c = :existingContact.Id];
        System.assertEquals(6, updatedGrants.size());
        System.assertEquals(200, updatedGrants[2].Disbursed_Amount__c);
        System.assertEquals(Date.today().addMonths(3), updatedGrants[2].Disbursed_Date__c);
    }
}