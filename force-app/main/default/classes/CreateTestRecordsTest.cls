@isTest
private class CreateTestRecordsTest {

    static testMethod void testSupportCaseandAccounts() {
        
        Case newcase = CreateTestRecords.DefaultSupportCase();
        
   
        Account healthcareacct = CreateTestRecords.DefaultHealthcareAccount();
        Account contractedacct = CreateTestRecords.DefaultThirdPartyContractedAccount();
        Account thirdpartyacct = CreateTestRecords.DefaultThirdPartyAccount();
        Account_Third_Party_Partner__c atpp = CreateTestRecords.LinkAccountToPartner(contractedacct.id, thirdpartyacct.id);
       
        
        
        Case c = [Select Id, Account.Support_Office__c from Case where Id = :newcase.id LIMIT 1 ];
        
        SupportOfficeMember__c member = CreateTestRecords.CreatePrimaryEngineer(c.account.support_office__c);
        
        Case contractedcase = CreateTestRecords.DefaultContractedFieldServiceCase(contractedacct.id, atpp.id);
        
        WorkOrder fwo = CreateTestRecords.DefaultFieldServiceWO(newcase.accountid, newcase.id);
        
        WorkOrder tpfwo = CreateTestRecords.DefaultThirdPartyFWO(contractedacct.id, contractedcase.id);
        

        Opportunity opp = CreateTestRecords.DefaultHospitalityOpportunity(c.accountid);
        
        Quote q = CreateTestRecords.DefaultHospitalityQuote(opp.id);
        
 
        
        
        
        system.assert(newcase.subject == 'Test Subject');
        
    }
    
    static testmethod void GetContactsList()
    {
    	     Account a = CreateTestRecords.DefaultHospitalityAccount();
    	     List<Contact> newcontactlist = CreateTestRecords.DefaultHospitalityContacts(a.id, 3);
    	     
    	     system.assert(newcontactlist.size() == 3);
    	     
    }
    
    static testmethod void CreateSonifiWorkOrders()
    {
    	Account acc = CreateTestRecords.DefaultHospitalityAccount();
    	Work_Order__c installwo = CreateTestRecords.DefaultInstallWorkOrder(acc.id);
    	Work_Order__c rackbuild = CreateTestRecords.DefaultRackBuild(acc.id);
    	
    }
    
    static testmethod void CreateOrder()
    {
    	Account a = CreateTestRecords.DefaultHospitalityAccount();
    	Order__c o = CreateTestRecords.DefaultOrder(a.id);
    }
}