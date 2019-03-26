@isTest
public with sharing class PMCaseCreationTest {
		
	@isTest
	static void testPrevMaintCaseCreation(){
		
		AppConfig__c appConfig = new AppConfig__c();
		appConfig.Name = 'Global';
		appConfig.Dispatch_Error__c ='Dispatch Error in PMCaseCreation';
		upsert appConfig;
		
		Integer recordsToCreate = 2;
		
		//shawks 20180312 (Too may SOQL queries issue) - comment out following 2 lines and replace "true" with "false" since records saved later
		//Account acc1 = DataGenerator.createAccounts(1, true)[0];
		//Account suppAcc = DataGenerator.createAccounts(1, true)[0];
		Account acc1 = DataGenerator.createAccounts(1, false)[0];
		Account suppAcc = DataGenerator.createAccounts(1, false)[0];
		Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
		System.debug('**** /////// *****  SupportOffice Id = ' + supportOfficeId);
		suppAcc.RecordTypeId = supportOfficeId;
		upsert suppAcc;
		acc1.Support_Office__c = suppAcc.Id;
		upsert acc1;
		
		User u = DataGenerator.createUsers(Definitions.PROFILE_SalesUser, 1, true)[0];
		SupportOfficeMember__c suppMem = new SupportOfficeMember__c();
		suppMem.User__c = u.Id;
		suppMem.SupportOffice__c = suppAcc.Id;
		suppMem.Role__c = 'Primary Engineer';
		
		upsert suppMem;
		//upsert suppAcc;  //shawks 20180312 (Too may SOQL queries issue) - comment out since already saved to database
		
		Product2 prod = DataGenerator.createProducts(1, true)[0];
		prod.Name='Interactive Product Parent';
		upsert prod;
		Asset asset1 = (Asset) DataGenerator.createSObjectWithDefaultValues('Asset');
		asset1.Name = 'A-GP';
		asset1.Product2Id = prod.Id;
		asset1.AccountId = acc1.Id;
		upsert asset1;
		
		Asset testAsset = [Select Id,Product2.Name from Asset where Id =:asset1.Id and Product2Id =: prod.Id Limit 1];
		System.debug('testAsset is : '+testAsset);
		System.debug('Asset.Product2.Name is : '+asset1.Product2.Name);
		
		List<Case> caseList =DataGenerator.createCases(acc1.Id, recordsToCreate, true);
		List<Id> recordTypeIdList = new List<Id>();
		List<Id> caseIdList = new List<Id>();
		for(Case c : caseList){
			c.Status = 'Open';
			c.RecordTypeId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Interactive_Preventative_Maintenance);
			c.AssetId = asset1.Id;
			c.System_Created__c = true;
			c.Support_Office__c = suppAcc.Id;
			recordTypeIdList.add(c.RecordTypeId);
			caseIdList.add(asset1.Id);
		}
		upsert caseList;
		
		ServiceContract sc = (ServiceContract) DataGenerator.createSObjectWithDefaultValues('ServiceContract');
		sc.Name='Test Service Contract';
		upsert sc;
		
		PMCaseRecordtypes__c pmCaseRecordtypes = new PMCaseRecordtypes__c();
		pmCaseRecordtypes.Name ='Interactive Product Parent'; 
		pmCaseRecordtypes.PM_Recordtype__c = 'Interactive Preventative Maintenance';
		upsert pmCaseRecordtypes;
		
		List<PMCaseSchedule__c> PMCaseScheduleList = new List<PMCaseSchedule__c>();
		PMCaseSchedule__c PMCaseSchedule1 = new PMCaseSchedule__c();
		PMCaseSchedule1.Name ='182'; PMCaseSchedule1.Creation_Months__c ='|1|7|';
		PMCaseScheduleList.add(PMCaseSchedule1);
		PMCaseSchedule__c PMCaseSchedule2 = new PMCaseSchedule__c();
		PMCaseSchedule2.Name ='30'; PMCaseSchedule2.Creation_Months__c ='|1|2|3|4|5|6|7|8|9|10|11|12|';
		PMCaseScheduleList.add(PMCaseSchedule2);
		PMCaseSchedule__c PMCaseSchedule3 = new PMCaseSchedule__c();
		PMCaseSchedule3.Name ='365'; PMCaseSchedule3.Creation_Months__c ='|1|';
		PMCaseScheduleList.add(PMCaseSchedule3);
		PMCaseSchedule__c PMCaseSchedule4 = new PMCaseSchedule__c();
		PMCaseSchedule4.Name ='60' ; PMCaseSchedule4.Creation_Months__c ='|1|3|5|7|9|11|';
		PMCaseScheduleList.add(PMCaseSchedule4);
		PMCaseSchedule__c PMCaseSchedule5 = new PMCaseSchedule__c();
		PMCaseSchedule5.Name ='90';  PMCaseSchedule5.Creation_Months__c ='|1|4|7|10|';
		PMCaseScheduleList.add(PMCaseSchedule5);
		
		upsert PMCaseScheduleList;
		
		
		List<Entitlement> entlListCreate = new List<Entitlement>();
		for(Integer i=0; i<5; i++){ 
			Entitlement entl= (Entitlement) DataGenerator.createSObjectWithDefaultValues('Entitlement'); 
				entl.Name='Test Entitlement For Case '+i;
				entl.AccountId = acc1.Id;
				entl.AssetId = asset1.Id;
				entl.ServiceContractId = sc.Id;
				entl.PM_Frequency__c = 30;
				entl.EndDate = System.now().date();
				entl.StartDate = System.now().addDays(-30).date();
			entlListCreate.add(entl);
		}
		upsert entlListCreate;
		
		String batchQuery =
				  'SELECT Id, Name, AccountId, AssetId, ServiceContractId, '
				+        'Asset.Name, Asset.Product2Id, Asset.Product2.Name '
				+ 'FROM Entitlement '
				+ 'WHERE PM_Frequency__c IN (' + String.join(PMCaseCreation.PMFrequencyList, ',') + ') '
				+ '  AND Status = \'Active\'';
		
		
		List<Entitlement> entlList = Database.query(batchQuery);		
		upsert entlList;
		
		List<Id> entlIdList = new List<Id>();
		for(Entitlement e : entlList){
			entlIdList.add(e.Id);
		}
		
		System.debug('pmCaseRecordtypes is ***** : '+pmCaseRecordtypes);
		System.debug('entlList is ***** : '+entlList);
		
		//System.runAs(u){
			PMCaseCreation.closePMCases(caseIdList, true);
		//}
		
		List<Case> closedPMCases = [SELECT Id 
									FROM Case 
									WHERE AssetId IN :caseIdList AND
									   System_Created__c = true
								 and status = :Definitions.CASE_STATUS_INCOMPLETE];
		System.assertEquals(closedPMCases.size(), caseList.size());
		
		//System.runAs(u){
			PMCaseCreation.CreatePMCases(entlList);
		//}
		
		List<Case> openPMCases = [SELECT Id 
									FROM Case 
									WHERE EntitlementId IN : entlIdList
									  AND System_Created__c = true
								 and status != :Definitions.CASE_STATUS_INCOMPLETE];
		System.assertEquals(openPMCases.size(), entlList.size());
	}
	
	
	@isTest static void tsetPMFrequencyList(){
		List<Integer> PMFrequencyList = PMCaseCreation.PMFrequencyList;
	}
}