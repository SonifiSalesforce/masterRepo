@isTest
private class FieldWorkOrderDisplayInstructionsTest {

    static testMethod void testDisplayInstructions() {
    	
    	Account tpcaccount = CreateTestRecords.DefaultThirdPartyContractedAccount();
    	Account tpaccount = CreateTestRecords.DefaultThirdPartyAccount();
    	Account_Third_Party_Partner__c atpp = CreateTestRecords.LinkAccountToPartner(tpcaccount.id, tpaccount.id);
        
        Third_Party_Partner_Case_Instructions__mdt instruction = [Select Developername, partner_site_id__c from
                                                                  Third_Party_Partner_Case_Instructions__mdt where DeveloperName = 'TEST1' LIMIT 1];

        Case contractedcase = CreateTestRecords.DefaultContractedFieldServiceCase(tpcaccount.id, atpp.id);
        
        WorkOrder fwo = CreateTestRecords.DefaultThirdPartyFWO(tpcaccount.id, contractedcase.id);
        
        ApexPages.StandardController con = new ApexPages.StandardController(fwo);
   		FieldWorkOrderDisplaySpecialInstructions testcon = New FieldWorkOrderDisplaySpecialInstructions(con);
   		PageReference pageRef = Page.FieldWorkOrderDisplaySpecialInstrucs;
   		pageRef.getParameters().put('Id', String.valueOf(fwo.id));
   		Test.setCurrentPage(pageRef);
   		
   		test.StartTest();
   		
   			testcon.wo = fwo;
   			List<Third_Party_Partner_Case_Instructions__mdt> lstinstructions = testcon.GetInstructions();
   			
   		test.StopTest();
   		
   		//jjackson--lstinstructions doesn't actually return anything because the site id on the test third party account
   		//doesn't match the site id on the custom metadata TEST1 record.  But at least this unit test runs the soql query
   		//against the metadata, so the code is covered even if the list is empty.
   		
        
    }
    
    static testmethod void DisplayInstructionsforThirdPartyEntitlement()
    {
    	Case suppcase = CreateTestRecords.DefaultSupportCase();
     	Date start = system.today();
    	Date done = system.today().addmonths(3);
    	ServiceContract sc = New ServiceContract(Name='TestWarranty', accountid=suppcase.accountid,
    	                     startdate=start, enddate=done);
    	insert sc;
    	Entitlement ent = New Entitlement(Name = 'TestTPEntitlement', accountid = suppcase.accountid,
    	startdate=start, enddate=done, servicecontractid=sc.id);
    	insert ent;
    	suppcase.entitlementid = ent.id;
    	suppcase.service_contract_name__c = sc.id;
    	update suppcase;
    	
    	ThirdPartyEntitlementName__c setting = New ThirdPartyEntitlementName__c();
    	setting.Name='TestTPEntitlement';
    	setting.ThirdPartySiteId__c = '0099887';
    	insert setting;
    	
    	WorkOrder fwo = CreateTestRecords.DefaultThirdPartyFWO(suppcase.accountid, suppcase.id);
    	fwo.entitlementid = ent.id;
    	fwo.servicecontractid = sc.id;
    	update fwo;
        
        ApexPages.StandardController con = new ApexPages.StandardController(fwo);
   		FieldWorkOrderDisplaySpecialInstructions testcon = New FieldWorkOrderDisplaySpecialInstructions(con);
   		PageReference pageRef = Page.FieldWorkOrderDisplaySpecialInstrucs;
   		pageRef.getParameters().put('Id', String.valueOf(fwo.id));
   		Test.setCurrentPage(pageRef);
   		
   		test.StartTest();
   		
   			testcon.wo = fwo;
   			List<Third_Party_Partner_Case_Instructions__mdt> lstinstructions = testcon.GetInstructions();
    	
    	
    }
}