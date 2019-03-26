@isTest
public with sharing class BatchPMTest {
	@isTest
	static void testBatchPM(){
		 
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
		
		Account acc1 = DataGenerator.createAccounts(1, true)[0];
		upsert acc1;
		Product2 prod = DataGenerator.createProducts(1, true)[0];
		prod.Name='Test Product';
		upsert prod;
		Asset asset1 = (Asset) DataGenerator.createSObjectWithDefaultValues('Asset');
		asset1.Name = 'A-GP';
		asset1.Product2Id = prod.Id;
		asset1.AccountId = acc1.Id;
		upsert asset1;
		ServiceContract sc = (ServiceContract) DataGenerator.createSObjectWithDefaultValues('ServiceContract');
		sc.Name='Test Service Contract';
		upsert sc;
		
		 
		List<Case> caseList =DataGenerator.createCases(acc1.Id, 2, true);
		
		
		for(Case c: caseList){
			c.Service_Contract_Name__c = sc.Id;
			c.Status = 'Open';
			c.RecordTypeId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Interactive_Preventative_Maintenance);
		}
		upsert caseList;
		
		List<Entitlement> entlList = new List<Entitlement>();
		for(Integer i=0; i<2; i++){ 
			
			Entitlement entl= new Entitlement(
				Name='Test Entitlement For Case '+i,
				AccountId = acc1.Id,
				AssetId = asset1.Id,
				ServiceContractId = sc.Id,
				PM_Frequency__c = 30
			);
			entlList.add(entl);
		}
		
		upsert entlList;
		//List<String> batchPMEntlList = new BatchPM().getPMFreqList();
		//System.debug('entlList is : '+batchPMEntlList);
		
		//Database.BatchableContext context = new Database.BatchableContext();
		//Database.Querylocator startBatch = BatchPM.start(context);
		Test.startTest();
		BatchPM bPM = new BatchPM();
		ID id =Database.executeBatch(bPM);
		System.debug('id is : '+id);
		Test.stopTest();
		
		//Batch.execute(context,startBatch);
	}
	
}