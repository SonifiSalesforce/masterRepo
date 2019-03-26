@isTest
public class InstallGradeBatchTest
{
    static testMethod void gradeRollupTest()
    {
        Account a = DataGenerator.createAccounts(1,true)[0];
        Contact c1 = new Contact(FirstName = 'Steve 1', LastName = 'Test', AccountId = a.Id);
        insert c1;
        Contact c2 = new Contact(FirstName = 'Steve 2', LastName = 'Test', AccountId = a.Id);
        insert c2;
        
        Work_Order__c wo = new Work_Order__c();
        insert wo;
        Install_Grade__c ig1 = new Install_Grade__c(Grade__c = 80, Installer__c= c1.Id, Work_Order__c = wo.Id);
        insert ig1;
        Install_Grade__c ig2 = new Install_Grade__c(Grade__c = 50, Installer__c= c2.Id, Work_Order__c = wo.Id);
        insert ig2;
        Install_Grade__c ig3 = new Install_Grade__c(Grade__c = 70, Installer__c= c1.Id, Work_Order__c = wo.Id);
        insert ig3;
        Test.startTest();
        InstallGradeBatchProcess b = new InstallGradeBatchProcess();
        Database.executeBatch(b);
        Test.stopTest();
        c1 = [SELECT Grade__c from Contact WHERE Id = :c1.id];
        system.assert(c1.Grade__c == 75);
    }
}