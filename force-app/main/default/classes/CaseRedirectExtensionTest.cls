@isTest
public with sharing class CaseRedirectExtensionTest {
    @isTest
    static void testCaseRedirectExtension(){
        User user = DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 1, true)[0];
        Account acc = DataGenerator.createAccounts(1, true)[0];
        Case c = DataGenerator.createCases(acc.Id, 1, true)[0];
        c.RecordTypeId = Utilities.RecordTypeNameToId('Task', Definitions.RECORDTYPE_Task_SupportCase);
        
        ApexPages.PageReference pageRef = Page.CaseRedirect;
        pageRef.getParameters().put('retUrl', '%2F' + c.Id);
        pageRef.getHeaders().put('Referer','/500/e');
        Test.setCurrentPage(pageRef);
        
        SupportCaseEditRestrictions__c supportCaseEditRestrictions = new SupportCaseEditRestrictions__c();
        supportCaseEditRestrictions.Name = 'Test';
        supportCaseEditRestrictions.Profile__c = Definitions.PROFILE_SystemAdmin;
        upsert supportCaseEditRestrictions;
        
        CaseRedirectExtension caseRedExtn = new CaseRedirectExtension(new Apexpages.Standardcontroller(c));
        PageReference redirectPg = caseRedExtn.redirectCase();
        System.assertNotEquals(null,redirectPg);
        
        pageRef = Page.CaseRedirect;
        pageRef.getParameters().put('retUrl', '%2F' + c.Id);
        pageRef.getHeaders().put('Referer','/500/o');
        Test.setCurrentPage(pageRef);
        
        System.runAs(user){
            caseRedExtn = new CaseRedirectExtension(new Apexpages.Standardcontroller(acc));
            redirectPg = caseRedExtn.redirectCase();
            System.assertNotEquals(null,redirectPg);
            
            Case c2 = DataGenerator.createCases(acc.Id, 1, true)[0];
            c2.RecordTypeId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Case_SupportCase);
            caseRedExtn = new CaseRedirectExtension(new Apexpages.Standardcontroller(c2));
            
            redirectPg = caseRedExtn.redirectCase();
            System.assertNotEquals(null,redirectPg);
        }
        
        supportCaseEditRestrictions.Name = 'Test';
        supportCaseEditRestrictions.Profile__c = Definitions.PROFILE_HealthcareSales;
        upsert supportCaseEditRestrictions;
        
        System.runAs(user){
            Case c2 = DataGenerator.createCases(acc.Id, 1, true)[0];
            c2.RecordTypeId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Case_SupportCase);
            c2.status='Closed';
            upsert c2;
            
            caseRedExtn = new CaseRedirectExtension(new Apexpages.Standardcontroller(c2));
            
            redirectPg = caseRedExtn.redirectCase();
            System.assertNotEquals(null,redirectPg);
        }
        
            
        Case c3 = DataGenerator.createCases(acc.Id, 1, true)[0];
        c3.RecordTypeId = Utilities.RecordTypeNameToId('Task', Definitions.RECORDTYPE_Task_SupportCase);
        c3.status='Closed';
            
        caseRedExtn = new CaseRedirectExtension(new Apexpages.Standardcontroller(c3));
            
        System.runAs(user){ 
            
            
            redirectPg = caseRedExtn.redirectCase();
            System.assertNotEquals(null,redirectPg);
        }
    }
}