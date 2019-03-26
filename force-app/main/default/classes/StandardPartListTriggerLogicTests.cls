@isTest
private class StandardPartListTriggerLogicTests {

	static testmethod void createOrderItems(){
		Account acc = new Account(Name = 'test acc');
		insert acc;
		
		Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
		Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
		
		Part_List__c part = new Part_List__c(Site_Survey__c = site.id);
		insert part;
		
		Product2 prod = new Product2(Name = 'test prod');
		insert prod;
		
		Part_List_Item__c item = new Part_List_Item__c(Product__c = prod.id, Part_List__c = part.id, Part_Number__c = 'test num', Price__c = 80, Unit__c = 'Rack', Quantity__c = 50, Description__c = 'test description');
		insert item;
		
		Part_List__c part2 = new Part_List__c(Site_Survey__c = site.id, Part_List_Selected__c = true);
		
		Test.startTest();
		insert part2;
		
		part.Part_List_Selected__c = true;
		update part;
		Test.stopTest();
		
		//requery
		List<Order__c> oList = [SELECT id FROM Order__c];
		List<Order_Item__c> oItems = [SELECT id FROM Order_Item__c];
		
		//assertions
		System.assertEquals(2, oList.size());
		System.assertEquals(1, oItems.size());
	}
	
	static testMethod void updatePartLineItems() {
    	//create test data
        Part_List__c Part_List1 = new Part_List__c(Approval_Status__c = 'Pending');
        Part_List__c Part_List2 = new Part_List__c(Approval_Status__c = 'Approved');
        insert new List<Part_List__c>{Part_List1, Part_List2};
        
        Part_List_Item__c pli1 = new Part_List_Item__c(Part_List__c = Part_List1.id, Conversion_Date__c = Date.Today().addDays(-30));
        Part_List_Item__c pli2 = new  Part_List_Item__c(Part_List__c = Part_List2.id, Conversion_Date__c = Date.Today().addDays(-30));
        insert new List<Part_List_Item__c>{pli1, pli2};
        
        Test.startTest();
        Part_List1.Approval_Status__c = 'Approved';
        Part_List2.Approval_Status__c = 'Pending';
        update new List<Part_List__c>{Part_List1, Part_List2};
        Test.stopTest();
        
        //requery the data
        Map<Id, Part_List_Item__c> Part_ListLineMap = new Map<Id, Part_List_Item__c>([SELECT id, Conversion_Date__c  FROM Part_List_Item__c]);
        
        //assertions
        System.assertEquals(Date.Today(), Part_ListLineMap.get(pli1.id).Conversion_Date__c);
        System.assertEquals(Date.Today().addDays(-30), Part_ListLineMap.get(pli2.id).Conversion_Date__c);
    }
	
	/******************************************************************************************
	*******************************HELPER CLASS************************************************
	******************************************************************************************/
	
	public static List<Site_Survey__c> createSiteSurveys(Opportunity oppty, integer recordsToCreate, Boolean insertRecords, String recordTypeName) {
    	
    	//check for oppty
    	if(oppty == null) {
    		throw new Exceptions.IllegalArgumentException('No opportunity provided for site survey.');
    	}
    	
    	//create the site survey
    	List<Site_Survey__c> siteList = new List<Site_Survey__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Site_Survey__c site = (Site_Survey__c)DataGenerator.createSObjectWithDefaultValues('Site_Survey__c');
    		site.Opportunity__c = oppty.id;
    		site.Site__c = oppty.Account_ID__c;
    		site.recordTypeId = Utilities.RecordTypeNameToIdWithObject(recordTypeName, 'Site_Survey__c');
    		siteList.add(site);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert siteList; }
    	
    	//return site surveys
    	return siteList;
    }
}