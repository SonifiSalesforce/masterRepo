@isTest
private class DesktopSurveyExtensionTests {

    static testMethod void loadDataNoData() {
         //create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Desktop Review').get(0);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    DesktopSurveyExtension stdController = new DesktopSurveyExtension(controller);        
        System.assert(stdController != null); // controller has successfully been created
        
        System.assertNotEquals(null, stdController.siteObject);
        System.assertEquals(null, stdController.rackLoc.Id);
        System.assertEquals(1, stdController.tvListGuest.size());
        System.assertEquals(1, stdController.id2TvLoc.keySet().size());
        System.assertEquals(0, stdController.id2TVType.keySet().size());
    }
    
    static testMethod void loadDataDataPresent() {
         //create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Desktop Review').get(0);
        createRackLocations(site, 1, true);
        createTVTypes(site, 2,true, 'Guestroom TV');
        TV_Location__c loc = createTVLocations(site, 2, true).get(0);
        List<TV_Type__c> publicTVs = createTVTypes(site, 1, true, 'Public Area TV');
        publicTVs[0].Public_Viewing_Location__c = loc.id;
        update publicTVs;
        
        //put in the test page
        PageReference pageRef = Page.DesktopSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    DesktopSurveyExtension stdController = new DesktopSurveyExtension(controller);        
        System.assert(stdController != null); // controller has successfully been created
        
        System.assertNotEquals(null, stdController.siteObject);
        System.assertNotEquals(null, stdController.rackLoc.Id);
        System.assertEquals(2, stdController.tvListGuest.size());
        System.assertEquals(2, stdController.id2TvLoc.keySet().size());
        System.assertEquals(1, stdController.id2TypeMap.get(loc.Id).size());
    }
    
     /****************************************************************************************************************
	**************************************SAVE METHODS*************************************************************
	*****************************************************************************************************************/
    static testMethod void saveData() {
         //create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Desktop Review').get(0);
        createRackLocations(site, 1, true);
        createTVTypes(site, 2,true, 'Guestroom TV');
        TV_Location__c loc = createTVLocations(site, 2, true).get(0);
        List<TV_Type__c> publicTVs = createTVTypes(site, 1, true, 'Public Area TV');
        publicTVs[0].Public_Viewing_Location__c = loc.id;
        update publicTVs;
        
        //put in the test page
        PageReference pageRef = Page.DesktopSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    DesktopSurveyExtension stdController = new DesktopSurveyExtension(controller);        
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
        stdController.rackLoc.Comments__c = 'New Comments';
        stdController.saveInfo();
        Test.stopTest();
        
        Rack_Location__c r = [SELECT Id, Comments__c FROM Rack_Location__c][0];
        
        System.assertEquals('New Comments', r.Comments__c);
    }
    /****************************************************************************************************************
	**************************************ADD ROW METHODS*************************************************************
	*****************************************************************************************************************/
	static testMethod void addRowTVTypeLocation() {
         //create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Desktop Review').get(0);
        TV_Location__c loc = createTVLocations(site, 1, true).get(0);
        loc.Name = 'Test Loc';
        update loc;
        List<TV_Type__c> publicTVs = createTVTypes(site, 1, true, 'Public Area TV');
        publicTVs[0].Public_Viewing_Location__c = loc.id;
        update publicTVs;
        
        //put in the test page
        PageReference pageRef = Page.DesktopSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    DesktopSurveyExtension stdController = new DesktopSurveyExtension(controller);        
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
        stdController.locationId = loc.Id;
        stdController.addRowTVLoc();
        stdController.addRowTVLoc();
        stdController.addRowLocation();
        stdController.id2TvLoc.get('Fake_ID').Name = 'Test Location 2';
        stdController.locationId = 'Fake_ID';
        stdController.addRowTVLoc();
        Test.stopTest();
        
        System.assertEquals(2, stdController.id2TvLoc.keySet().size());
        System.assertEquals(2, stdController.id2TypeMap.get(loc.Id).size());
    }
    
	static testMethod void addRowTVLocation() {
         //create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Desktop Review').get(0);
        
        //put in the test page
        PageReference pageRef = Page.DesktopSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    DesktopSurveyExtension stdController = new DesktopSurveyExtension(controller);        
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
        stdController.id2TvLoc.get('Fake_ID').Name = 'New Location';
        stdController.addRowLocation();
        stdController.addRowLocation();
        Test.stopTest();
        
        System.assertEquals(2, stdController.id2TvLoc.keySet().size());
    }
    
    static testMethod void addRowTVGuest() {
         //create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Desktop Review').get(0);
        createTVTypes(site, 2,true, 'Guestroom TV');
        
        //put in the test page
        PageReference pageRef = Page.DesktopSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    DesktopSurveyExtension stdController = new DesktopSurveyExtension(controller);        
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
        stdController.tvListGuest[0].Quantity__c =50;
        stdController.addRowTVInfo();
        stdController.addRowTVInfo();
        Test.stopTest();
        
        List<TV_Type__c> tvList = [SELECT id, Quantity__c FROM TV_Type__c WHERE Quantity__c = 50];
        
        System.assertEquals(3, stdController.tvListGuest.size());
        System.assertEquals(1, tvList.size());
    }
    
     
    /****************************************************************************************************************
	**************************************CREATION/HELPER METHODS*************************************************************
	*****************************************************************************************************************/
    
    public static List<TV_Location__c> createTVLocations(Site_Survey__c site, integer recordsToCreate, Boolean insertRecords){
    	//check for site Survey
    	if(site == null) {
    		throw new Exceptions.IllegalArgumentException('No Site survey provided for TV Type');
    	}
    	
    	//create the tv type
    	List<TV_Location__c> tvList = new List<TV_Location__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		TV_Location__c tv = (TV_Location__c)DataGenerator.createSObjectWIthDefaultValues('TV_Location__c');
    		tv.Site_Survey__c = site.id;
    		tv.Name = 'TVLocation ' + i;
    		tvList.add(tv);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert tvList; }
    	
    	//return the list
    	return tvList;
    }
    
    public static List<TV_Type__c> createTVTypes(Site_Survey__c site, integer recordsToCreate, Boolean insertRecords, String recordTypeName){
    	//check for site Survey
    	if(site == null) {
    		throw new Exceptions.IllegalArgumentException('No Site survey provided for TV Type');
    	}
    	TV_Manufacturer__c manu = new TV_Manufacturer__c(Name = 'Sony');
    	insert manu;
    	
    	//create the tv type
    	List<TV_Type__c> tvList = new List<TV_Type__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		TV_Type__c tv = (TV_Type__c)DataGenerator.createSObjectWIthDefaultValues('TV_Type__c');
    		tv.Site_Survey__c = site.id;
    		tv.TV_Manufacturer__c = manu.id;
    		tv.Other_Model__c = 'Test Model';
    		tv.RecordTypeId = Utilities.RecordTypeNameToIdWithObject(recordTypeName, 'TV_Type__c');
    		tvList.add(tv);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert tvList; }
    	
    	//return the list
    	return tvList;
    }
    
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
    
    public static List<Rack_Location__c> createRackLocations(Site_Survey__c site, integer recordsToCreate, Boolean insertRecords){
    	//check fro account
    	if(site == null){
    		throw new Exceptions.IllegalArgumentException('No site survey provided for rack location');
    	}
    	
    	//create the account
    	List<Rack_Location__c> rackList = new List<Rack_Location__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Rack_Location__c rack = (Rack_Location__c) DataGenerator.createSObjectWithDefaultValues('Rack_Location__c');
    		rack.Site_Survey__c = site.id;
    		
    		rackList.add(rack);
    	}
    	
    	//check for insert flag
    	if(insertRecords) { insert rackList;}
    	
    	//return contacts
    	return rackList;
    }
}