@isTest(seeAllData=true)
public with sharing class CaseEditExtensionTest {
	@isTest
	static void testCaseEditExtension(){
		
		User user = DataGenerator.createUsers(Definitions.PROFILE_SalesUser, 1, true)[0];
		
		Case newCase =(Case) DataGenerator.createSObjectWithDefaultValues('Case');
		//newCase.RecordTypeId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Case_SupportCase);
		newCase.Status='Closed';
		upsert newCase;
		CaseEditExtension caseEditExtn = new CaseEditExtension(new ApexPages.StandardController(newCase));
		
		Account acc = DataGenerator.createAccounts(1,true)[0];
		upsert acc;
		
		List<Flash_Notification__c> flashList = new List<Flash_Notification__c>();
		for(Integer i=0;i<1;i++){
			Flash_Notification__c flash = new Flash_Notification__c();
			flash.Account__c= acc.Id;
			flash.Subject__c='Subject '+i;
			flash.Never_Expires__c = true;
			flash.Urgent__c = true;
			
			flashList.add(flash);
		}
		for(Integer i=0;i<1;i++){
			Flash_Notification__c flash = new Flash_Notification__c();
			flash.Account__c= acc.Id;
			flash.Subject__c='Subject '+i;
			flash.Never_Expires__c = false;
			flash.Urgent__c = false;
			flash.End_Date__c= System.now().addDays(10).date();
			
			flashList.add(flash);
		}
		
		upsert flashList;
		AppConfig__c AppConfig = new AppConfig__c();
		AppConfig.Name = 'Global';
		AppConfig.Not_Contracted_Entitlement__c = '550Z0000000FqcS';
		//upsert AppConfig;
		
		
		Asset asset = (Asset) DataGenerator.createSObjectWithDefaultValues('Asset');
		asset.AccountId = acc.Id;
		asset.Name = 'Asset 1';
		upsert asset; 
		
		Contact con =  (Contact) DataGenerator.createSObjectWithDefaultValues('Contact');
		con.LastName = 'LastName';
		upsert con;
		
		ServiceContract sc = (ServiceContract) DataGenerator.createSObjectWithDefaultValues('ServiceContract');
		sc.Name = 'Service Name';
		sc.ContactId = con.Id;
		upsert sc;
		
		MilestoneDetails__c milestoneDetails = new MilestoneDetails__c();
		milestoneDetails.Name = 'Test - Core - Catastrophic';
		milestoneDetails.Entitlement__c = 'BB - Core';
		milestoneDetails.Description__c = 'Field to Initiate Truck-Roll'; 
		milestoneDetails.Milestone__c = 'Field Response Time';
		milestoneDetails.Priority__c = 'MODERATE';
		milestoneDetails.Order__c = 1;
		milestoneDetails.TimeAllowed__c = 'Next Business Day'; 
		upsert milestoneDetails;
		
  		SlaProcess sla =[Select Id,Name,Description from SlaProcess where Name='Legacy Enhanced SLA' LIMIT 1];
		System.debug('sla is : '+sla);
		 
		Entitlement entl = (Entitlement) DataGenerator.createSObjectWithDefaultValues('Entitlement');
		entl.Name = 'Entitlement 1';
		entl.AssetId= asset.Id;
		entl.ServiceContractId = sc.Id;
		entl.AccountId = acc.Id;
		entl.SlaProcessId = sla.Id;
		entl.Moderate_Severity_Description__c = 'Moderate Severity Desc...';
		upsert entl;
		
		List<Entitlement> entlList = [SELECT Id, Name, ServiceContractId, ServiceContract.Name
				FROM Entitlement
				WHERE Id = :entl.Id
				LIMIT 1];
		
		ApexPages.PageReference pageRef = Page.caseEdit;
		//pageRef.getParameters().put('retUrl', '%2F' + newCase.Id);
		pageRef.getParameters().put('def_entitlement_id', entl.Id);
		pageRef.getHeaders().put('Referer','/500/e');
		Test.setCurrentPage(pageRef);
		
		Map<String, String> fieldSetNames = caseEditExtn.fieldSetNames;
		Map<String, Map<String, Integer>> fieldSetTabOrder = caseEditExtn.fieldSetTabOrder;
		
		
		//System.runAs(user){
			Case newCase2 =(Case) DataGenerator.createSObjectWithDefaultValues('Case');
			newCase2.RecordTypeId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Case_SupportCase);
			newCase2.Status='Closed';
				
			upsert newCase2;
			
			
		
			caseEditExtn = new CaseEditExtension(new ApexPages.StandardController(newCase2));
			
			System.assertNotEquals(null,entlList);
			System.debug('The entitlement Id in the test CLass is : '+entlList);
			/*
			Entitlement entlment = CaseEditExtension.entlList(entl.Id);
			System.assertNotEquals(null,entlList);
			System.debug('entlment is : '+entlment);
			*/ 
			
			List<CustomFlashNotificationLogic.FlashNotification> getFlashNotificationList =CaseEditExtension.GetFlashNotifications(acc.Id);
			System.assertNotEquals(null,getFlashNotificationList);
			
			caseEditExtn.applyAssignmentRules = true;
			caseEditExtn.milestoneSynopsis = 'Test Milestone Synopsis';
			caseEditExtn.casePriority = 'Moderate';
			caseEditExtn.internalComments ='Case Internal Comments';
			caseEditExtn.externalComments ='Case External Comments';
			
			Id id = CaseEditExtension.GetBaseEntitlementId();
			System.assertNotEquals(null,id);
							
			CaseEditExtension.EntitlementDetails serviceContracts = CaseEditExtension.GetServiceContract(entl.Id);
			System.assertNotEquals(null,serviceContracts);
			
			CaseEditExtension.EntitlementDetails getEntitlementDetails = CaseEditExtension.GetEntitlementDetails(entl.Id);
			System.assertNotEquals(null,getEntitlementDetails);
			
			List<CustomCaseLogic.CaseInteractionHistory> caseIntHis = CaseEditExtension.GetCaseInteractionHistory(newCase.Id);
			System.assertNotEquals(null,caseIntHis);
			
			PageReference pg = caseEditExtn.Save();
			System.assertNotEquals(null,pg);
			
			Case c1 = DataGenerator.createCases(acc.id, 1, false)[0];
			CaseEditExtension caseEditExtn1 = new CaseEditExtension(new ApexPages.StandardController(c1));
			//Testing for isNew
			caseEditExtn1.newCaseId = newCase.Id;
			pg = caseEditExtn1.Save();
			System.assertNotEquals(null,pg);
			
			pg = caseEditExtn.SaveAndClose();
			System.assertNotEquals(null,pg);
			
			pg = caseEditExtn.SaveAndNew();
			System.assertNotEquals(null,pg);
			
			pg = caseEditExtn.Cancel();
			System.assertNotEquals(null,pg);
			
			String ownerIdString= String.valueOf(user.Id);
			String createdOn = System.now().format();
			String accountIdString = String.valueOf(acc.Id);
			String entitlementIdString = String.valueOf(entl.Id);
			String serviceContractIdString = String.valueOf(sc.Id);
			
			Case createCase = CaseEditExtension.CreateCase(ownerIdString, createdOn, accountIdString, entitlementIdString, serviceContractIdString);
			System.assertNotEquals(null,createCase); 
			
			//Testing various scenarios with Parameters
			ApexPages.PageReference pageRef1 = Page.caseEdit;
			pageRef1.getParameters().put('retUrl', '%2F' + newCase.Id);
			pageRef1.getHeaders().put('Referer','/500/e');
			Test.setCurrentPage(pageRef1);
			
			caseEditExtn1 = new CaseEditExtension(new ApexPages.StandardController(c1));
			System.assertNotEquals(null,caseEditExtn1);
			
			ApexPages.PageReference pageRef2 = Page.caseEdit;
			pageRef2.getParameters().put('def_account_id', acc.Id);
			pageRef2.getHeaders().put('Referer','/500/e');
			Test.setCurrentPage(pageRef2);
			
			caseEditExtn1 = new CaseEditExtension(new ApexPages.StandardController(c1));
			System.assertNotEquals(null,caseEditExtn1);
			
			ApexPages.PageReference pageRef3 = Page.caseEdit;
			pageRef3.getParameters().put('recordtype', newCase2.RecordTypeId);
			pageRef3.getHeaders().put('Referer','/500/e');
			Test.setCurrentPage(pageRef3);
			
			caseEditExtn1 = new CaseEditExtension(new ApexPages.StandardController(c1));
			System.assertNotEquals(null,caseEditExtn1);
		//}
		
	}

}