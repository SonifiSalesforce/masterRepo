@isTest
private class SiteSurveyExtensionTests {
	//Template
	/*static testMethod void saveObjectAllSuccess() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
	}/*
	/****************************************************************************************************************
	**************************************TAB ALL METHODS*************************************************************
	*****************************************************************************************************************/
	static testMethod void tabAllMethods() {
		//create variables to hold values
		List<Contact> contactList = new List<Contact>();
		List<TV_Type__c> tvTypes = new List<TV_Type__c>();
		List<TV_Type__c> tvGuestList = new List<TV_Type__c>();
		Map<String, TV_Location__c> tvMap = new Map<String, TV_Location__c>();
		
		//create test data
		User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
		System.runAs(u1){
	        Account acc = DataGenerator.createAccounts(1, true).get(0);
	        System.debug('Account data is ' + acc);
	        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
	        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
	        TV_Location__c loc = createTVLocations(site, 1, true)[0];
	        TV_Type__c tv = createTVTypes(site, 1, false, 'Public Area TV')[0];
	        tv.Public_Viewing_Location__c = loc.id;
	        insert tv;
	        
	        //put in the test page
	        PageReference pageRef = Page.SiteSurvey;
			pageRef.getParameters().put('Id', site.id);
			Test.setCurrentPageReference(pageRef);
	        
	        //make the standard controller
	        ApexPages.StandardController controller = new ApexPages.StandardController(site);
	
		    // now pass it to the extension
		    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
	        
	        System.assert(stdController != null); // controller has successfully been created
	        stdController.tab = 'ALL';
	        stdController.oldTab = 'ALL';
	        stdController.locationId = loc.id;
	        Test.startTest();
	        stdController.addRowContact();
	        stdController.addRowContact();
	        stdController.addRowTVInfo();
	        stdController.addRowTVInfo();
	        stdController.addRowTVLoc();
	        stdController.addRowTVLoc();
	        stdController.addRowLocation();
	        stdController.addRowLocation();
	        stdController.quickSave();
	        stdController.quickSaveSwitch();
	        Test.stopTest();
			
			contactList = stdController.contactList;
	        tvMap = stdController.id2TvLoc;
	        tvTypes = stdController.tvTypes;
	        tvGuestList = stdController.tvListGuest;
	        
	        
		}
		
		//query for data to make sure none of it inserted
        List<TV_Location__c> tvLoc = [SELECT id FROM TV_Location__c];
        List<Contact> contacts = [SELECT id FROM Contact];
        List<TV_Type__c> tvList = [SELECT id FROM TV_Type__c ];
	        
	    //assertions
        System.assertEquals(1, tvLoc.size());
        System.assertEquals(0, contacts.size());
        System.assertEquals(1, tvList.size());
        System.assertEquals(3, contactList.size());
        System.assertEquals(3, tvMap.keySet().size());
        System.assertEquals(3, tvTypes.size());
        System.assertEquals(3, tvGuestList.size());
	}
	/****************************************************************************************************************
	**************************************ADD ROW METHODS*************************************************************
	*****************************************************************************************************************/
	
	//mass add row methods
	static testMethod void addAllRowTabALL() {
		//create variables to hold values
		List<Contact> contactList = new List<Contact>();
		List<TV_Type__c> tvTypes = new List<TV_Type__c>();
		List<TV_Type__c> tvGuestList = new List<TV_Type__c>();
		Map<String, TV_Location__c> tvMap = new Map<String, TV_Location__c>();
		
		//create test data
		User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
		System.runAs(u1){
	        Account acc = DataGenerator.createAccounts(1, true).get(0);
	        System.debug('Account data is ' + acc);
	        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
	        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
	        
	        //put in the test page
	        PageReference pageRef = Page.SiteSurvey;
			pageRef.getParameters().put('Id', site.id);
			Test.setCurrentPageReference(pageRef);
	        
	        //make the standard controller
	        ApexPages.StandardController controller = new ApexPages.StandardController(site);
	
		    // now pass it to the extension
		    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
	        
	        System.assert(stdController != null); // controller has successfully been created
	        
	        stdController.tab = 'ALL';
	        stdController.headerBuilding = 2;
	        stdController.headerIDF = 2;
 	  	    stdController.headerCable = 2;
 	  	    stdController.headerPassive = 2;
 	  	    stdController.headerBBIDF = 2;
 	  	    stdController.headerBBMDF = 2;
 	  	    stdController.headerDigital = 2;
 	  	    stdController.headerContact = 2;
 	  	    stdController.headerPrivateTv = 2;
 	  	    stdController.headerLocation = 2;
 	  	    stdController.headerPublicTv = 2;
 	  	    stdController.headerRack = 2;
 	  	    stdController.addRowHeaders();
 	  	    
 	  	    //assertions
 	  	    System.assertEquals(3, stdController.buildingMap.KeySet().size());
 	  	    System.assertEquals(3, stdController.bbIDFList.size());
 	  	    System.assertEquals(3, stdController.bbMDFList.size());
 	  	    System.assertEquals(3, stdController.cableTypeList.size());
 	  	    System.assertEquals(3, stdController.passiveDeviceList.size());
 	  	    System.assertEquals(3, stdController.contactList.size());
 	  	    System.assertEquals(3, stdController.tvListGuest.size());
 	  	    System.assertEquals(3, stdController.locationId2NumTVs.keySet().size());
 	  	    System.assertEquals(3, stdController.id2TypeMap.Values().size());
 	  	    System.assertEquals(3, stdController.digitalList.size());
 	  	    System.assertEquals(3, stdController.rackLocList.size());
 	  	    System.assertEquals(3, stdController.id2MediaList.Values().size());
		}
	}
	 
	static testMethod void addRowBuilding() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        createBuildings(site, 1,true);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        Test.startTest();
        stdController.addRowBuilding();
        stdController.buildingMap.get('Fake_ID').Name = 'Test Building';
        stdController.addRowBuilding();
        stdController.addRowBuilding();
		Test.stopTest();
		
		//assertions
		System.assertEquals(3, stdController.buildingMap.keySet().size());
	}
	
	static testMethod void addRowMediaIDF() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        Building__c build = createBuildings(site, 1,true)[0];
        createMediaIDF(build, 1, true);
        Building__c build2 = createBuildings(site, 1,true)[0];
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        Test.startTest();
        stdController.addRowIDF();
        stdController.locationId = build.id;
        stdController.addRowIDF();
        stdController.addRowIDF();
        stdController.locationId = build2.id;
        stdController.addRowIDF();
        stdController.addRowIDF();
        stdController.addRowBuilding();
        stdController.buildingMap.get('Fake_ID').Name = 'Test Buildings6';
        stdController.addRowIDF();
        stdController.addRowIDF();
		Test.stopTest();
		
		//assertions
		System.assertEquals(3, stdController.buildingMap.keySet().size());
	}
	
	static testMethod void addRowPassiveDevice() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);

        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        Test.startTest();
        
        stdController.addRowPassiveDevice();
        stdController.passiveDeviceList[0].Device__c = 'Wall Taps';
        stdController.addRowPassiveDevice();
		Test.stopTest();
		
		//assertions
		System.assertEquals(2, stdController.passiveDeviceList.size());
	}
	
	static testMethod void addRowCableType() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        createCableTypes(site, 1, true );
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        Test.startTest();
        
        stdController.addRowCableType();
        stdController.cableTypeList[0].Make__c ='Test cable';
        stdController.addRowCableType();
		Test.stopTest();
		
		//assertions
		System.assertEquals(2, stdController.cableTypeList.size());
	}
	
	static testMethod void addRowBBIDF() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        createBBIDF(site, 'IDF', 1, true);
        createBBIDF(site, 'MDF', 1, true);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        Test.startTest();
        stdController.bbIDFList.get(0).Data_Comments__c = 'This is a test';
        stdController.bbMDFList.get(0).Data_Comments__c = 'This is a test';
        stdController.addBBIDF();
        stdController.addBBIDF();
        stdController.addBBMDF();
        stdController.addBBMDF();
		Test.stopTest();
		
		//assertions
		System.assertEquals(2, stdController.bbIDFList.size());
	}
	
	// add tv type to tv location that is already inserted into salesforce 
	static testMethod void addRowType2TVLoc() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<TV_Type__c> tvs = createTVTypes(site, 2, false, 'Public Area TV');
        List<TV_Location__c> locs = createTVLocations(site, 2, true);
        tvs[0].Public_Viewing_Location__c = locs[0].id;
        tvs[1].Public_Viewing_Location__c = locs[1].id;
        insert tvs;
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        System.debug('id2TVMap is ' + stdController.id2TypeMap);
        System.debug('TV Types are ' + stdController.tvTypes);
        Test.startTest();
        stdController.locationId = locs[0].id;
        stdController.id2TvLoc.get(locs[0].id).FCO__c = 'Test Fire Code';
        stdController.id2TypeMap.get(locs[0].id)[0].Quantity__c = 50;
		stdController.addRowTVLoc();
		Test.stopTest();
		
		//assertions
		System.assertEquals(2, stdController.id2TypeMap.get(locs[0].id).size());
		System.assertEquals('Test Fire Code', stdController.id2TvLoc.get(locs[0].id).FCO__c);
		System.assertEquals(50, stdController.id2TypeMap.get(locs[0].id)[0].Quantity__c);
	}
	
	//add tv type to tv location that is not inserted into salesforce ye
	static testMethod void addRowType2TVLocInsertLOC() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<TV_Type__c> tvs = createTVTypes(site, 2, false, 'Public Area TV');
        List<TV_Location__c> locs = createTVLocations(site, 2, true);
        tvs[0].Public_Viewing_Location__c = locs[0].id;
        tvs[1].Public_Viewing_Location__c = locs[1].id;
        insert tvs;
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        stdController.addRowLocation();//adds empty row to the list
        
        Test.startTest();
        stdController.locationId = 'Fake ID';
        stdController.id2TvLoc.get('Fake ID').Name = 'Test Name';
		stdController.addRowTVLoc();
		Test.stopTest();
		
		//assertions
		System.assertEquals(3, stdController.id2TypeMap.values().size());
		System.assertEquals(3, stdController.id2TvLoc.keySet().size());
	}
	//add tv location
	static testMethod void addRowTVLocation() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<TV_Type__c> tvs = createTVTypes(site, 2, false, 'Public Area TV');
        List<TV_Location__c> locs = createTVLocations(site, 2, true);
        tvs[0].Public_Viewing_Location__c = locs[0].id;
        insert tvs;
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
		stdController.addRowLocation();
		stdController.addRowLocation();
		Test.stopTest();
		
		//assertions
		System.assertEquals(3, stdController.id2TvLoc.keySet().size());
	}
	
	//add tv location
	static testMethod void addRowTVLocationALL() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<TV_Type__c> tvs = createTVTypes(site, 2, false, 'Public Area TV');
        List<TV_Location__c> locs = createTVLocations(site, 2, true);
        tvs[0].Public_Viewing_Location__c = locs[0].id;
        tvs[1].Public_Viewing_Location__c = locs[1].id;
        insert tvs;
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        stdController.tab ='ALL';
	    stdController.numRows = 2;
	    
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
		stdController.addRowLocation();
		Test.stopTest();
		
		//assertions
		System.assertEquals(4, stdController.id2TvLoc.keySet().size());
	}
	
	//add row tv types success
	static testMethod void addRowTVInfoSuccess() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<TV_Type__c> tvs = createTVTypes(site, 2, false, 'Public Area TV');   
        TV_Location__c loc = createTVLocations(site, 1, true).get(0);
        tvs[0].Public_Viewing_Location__c = loc.id;
        String guestroomTVRecordId = Utilities.RecordTypeNameToIdWithObject('Guestroom TV', 'TV_Type__c');
        tvs[1].RecordTypeId = guestroomTVRecordId;
        insert tvs;
             
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);        
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
        stdController.addRowTVInfo();
        Test.stopTest();
        
        //assertions
        System.assertEquals(3, stdController.tvTypes.size());
        System.assertEquals(2, stdController.tvListGuest.size());
	}
	
	//add row tv types fail
	static testMethod void addRowTVInfoFail() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<TV_Type__c> tvs = createTVTypes(site, 3, false, 'Guestroom TV');
        TV_Location__c loc = createTVLocations(site, 1, true).get(0);
        TV_Manufacturer__c manu = new TV_Manufacturer__c(Name='Sony');
        insert manu;  
        tvs.get(1).Public_Viewing_Location__c = loc.id;
        String publicTVRecordId = Utilities.RecordTypeNameToIdWithObject('Public Area TV', 'TV_Type__c');
        tvs.get(1).RecordTypeId = publicTVRecordId;
        insert tvs;
             
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);        
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
        stdController.addRowTVInfo();
        stdController.addRowTVInfo();
        Test.stopTest();
        
        //assertions
        System.assertEquals(4, stdController.tvTypes.size());
        System.assertEquals(3, stdController.tvListGuest.size());
	}
	
	//add room reading to list
	static testMethod void addRackLocations() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<Rack_Location__c> rackList = createRackLocations(site, 1, true);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
	    
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
        stdController.addRowRackLoc();
        Test.stopTest();
        
        //assertions
        System.assertEquals(2, stdController.rackLocList.size());
	}
	
	//add room reading to list
	static testMethod void addRackLocationsALL() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<Rack_Location__c> rackList = createRackLocations(site, 2, true);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
	    
        System.assert(stdController != null); // controller has successfully been created
        
        //tab all functionality
        stdController.tab = 'ALL';
        stdController.numRows = 2;
        
        Test.startTest();
        stdController.addRowRackLoc();
        
        //end test
        Test.stopTest();
        
        //assertions
        System.assertEquals(4, stdController.rackLocList.size());
	}
	
	//add room reading to list
	static testMethod void addContactsFail() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<Contact> conList = createContacts(acc, 2, true);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
	    
        System.assert(stdController != null); // controller has successfully been created
        
        //edit fields
        stdController.contactList[1].FirstName = '';
        stdController.contactList[1].LastName = '';
        
        Test.startTest();
        stdController.addRowContact();
        Test.stopTest();
        
        //assertions
        System.assertEquals(2, stdController.contactList.size());
	}
	
	//add room reading to list
	static testMethod void addContactsSuccess() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<Contact> conList = createContacts(acc, 2, true);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
	    
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
        
        stdController.contactList[1].FirstName = 'UpdateFirst';
        stdController.contactList[1].LastName = 'UpdateLast';
        
        stdController.addRowContact();
        
        Test.stopTest();
        
        //query for results
        Contact con = [SELECT id, FirstName FROM Contact WHERE FirstName = 'UpdateFirst' limit 1][0];
        
        //assertions
        System.assertEquals(3, stdController.contactList.size());
        System.assertNotEquals(null, con);
	}
	
	//add digital off air to list
	static testMethod void addDigitalOffAirList() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<Digital_Off_Air__c> digitalList = createDigitalOffAir(site, 2, true);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
        stdController.addDigitalOffAir();
        Test.stopTest();
        
        //assertions
        System.assertEquals(3, stdController.digitalList.size());
	}
	
	//add digital off air to list
	static testMethod void addDigitalOffAirALLList() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<Digital_Off_Air__c> digitalList = createDigitalOffAir(site, 2, true);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
	    stdController.tab ='ALL';
	    stdController.numRows = 2;
        
        System.assert(stdController != null); // controller has successfully been created
        
        Test.startTest();
        stdController.addDigitalOffAir();
        Test.stopTest();
        
        //assertions
        System.assertEquals(4, stdController.digitalList.size());
	}
	/****************************************************************************************************************
	**************************************SAVE TEST METHODS*************************************************************
	*****************************************************************************************************************/
	
	static testMethod void saveInfoTest() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        
        PageReference ref = stdController.saveInfo();
        
        //assertions
        System.assertEquals('/' + site.id, ref.getUrl());
	}
	
	
	static testMethod void quickSaveTVType() {
		//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<TV_Type__c> tvList = createTVTypes(site, 2, true, 'Guestroom TV');
        String id = tvList[1].id;
        
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);
		
	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
	    System.assert(stdController != null); // controller has successfully been created
	    
	    Test.startTest();
	    stdController.tab = 'TV Type';
	    stdController.tvListGuest.get(stdController.tvListGuest.size()-1).Quantity__c = 50;
	    stdController.tvListGuest.get(stdController.tvListGuest.size()-1).TV_Manufacturer__c = null;
	    stdController.quickSave();
	    stdController.loadTypeData();
        stdController.loadTVLocationData();
        Test.stopTest();
        
        //query for the results
        TV_Type__c tv = [SELECT id, TV_Manufacturer__c, Quantity__c FROM TV_Type__c WHERE Id = :id limit 1];
        
        //assertions
        System.assertNotEquals(null, tv.TV_Manufacturer__c);
        System.assertNotEquals(50, tv.Quantity__c);
	}

	/****************************************************************************************************************
	**************************************LOAD TEST METHODS*************************************************************
	*****************************************************************************************************************/
	//prior site survey was created. also related test objects were also present
     static testMethod void loadAllData() {
        //create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        List<TV_Type__c> listType = createTVTypes(site, 5, false, 'Public Area TV');
        List<TV_Location__c> listLocation = createTVLocations(site, 2, true);
        listType[0].Public_Viewing_Location__c = listLocation[0].id;
        listType[1].Public_Viewing_Location__c = listLocation[0].id;
        listType[2].Public_Viewing_Location__c = listLocation[1].id;
        String guestroomTVRecordId = Utilities.RecordTypeNameToIdWithObject('Guestroom TV', 'TV_Type__c');
        listType[3].recordTypeId = guestroomTVRecordId;
        listType[4].recordTypeId = guestroomTVRecordId;
        insert listType;
        List<Building__c> buildingList = createBuildings(site, 2, true);
        List<Digital_Off_Air__c> digitalList = createDigitalOffAir(site, 3, true);
        List<Contact>conList = createContacts(acc, 2, true);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		pageRef.getParameters().put('tab', 'ALL');
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
        
        System.assert(stdController != null); // controller has successfully been created
        System.assertEquals(5, stdController.tvTypes.size());
        System.assertEquals(2, stdController.id2TypeMap.get(listLocation[0].id).size());
        System.assertEquals(site.id, stdController.siteObject.id);
        System.assertEquals(2, stdController.buildingMap.keySet().size());
        System.assertEquals(3, stdController.digitalList.size());
        System.assertEquals(2, stdController.tvListGuest.size());
        System.assertEquals(2, stdController.contactList.size());
        System.assertEquals('ALL', stdController.tab);
    }
    
    //load all data with no records in the system
    static testMethod void loadAllDataNoRecords() {
    	//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Site_Survey__c site = createSiteSurveys(opp, 1, true, 'Site Survey').get(0);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', site.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(site);

	    // now pass it to the extension
	    SiteSurveyExtension stdController = new SiteSurveyExtension(controller);
	    System.assert(stdController != null); // controller has successfully been created
	    
	    //assertions
	    System.assertEquals(site.id, stdController.siteObject.id);
	    System.assertEquals(1, stdController.buildingMap.keySet().size());
	    System.assertEquals(1, stdController.digitalList.size());
	    System.assertEquals(1, stdController.id2TvLoc.keySet().size()); 
	    System.assertEquals(1, stdController.tvListGuest.size());
	    System.assertEquals(1, stdController.contactList.size());
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
    	TV_Manufacturer__c manu = new TV_Manufacturer__c(Name='Sony');
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
    
    public static List<Cable_Type__c> createCableTypes(Site_Survey__c site, integer recordsToCreate, Boolean insertRecords){
    	//check for site
    	if(site == null) {
    		throw new Exceptions.IllegalArgumentException('No site provided for cable types.');
    	}
    	
    	//create the cable types
    	List<Cable_Type__c> cableList = new List<Cable_Type__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Cable_Type__c cable = (Cable_Type__c)DataGenerator.createSObjectWithDefaultValues('Cable_Type__c');
    		cable.Site_Survey__c = site.id;
    		cable.Make__c = 'Sony '+ i;
    		
    		cableList.add(cable);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert cableList; }
    	
    	//return building list
    	return cableList;
    }
    
    public static List<Digital_Off_Air__c> createDigitalOffAir(Site_Survey__c site, integer recordsToCreate, Boolean insertRecords){
    	//check for site
    	if(site == null) {
    		throw new Exceptions.IllegalArgumentException('No site provided for digital off air.');
    	}
    	
    	//create the cable types
    	List<Digital_Off_Air__c> digitalList = new List<Digital_Off_Air__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Digital_Off_Air__c digital = (Digital_Off_Air__c)DataGenerator.createSObjectWithDefaultValues('Digital_Off_Air__c');
    		digital.Site_Survey__c = site.id;
    		
    		digitalList.add(digital);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert digitalList; }
    	
    	//return building list
    	return digitalList;
    }
    
    public static List<Contact> createContacts(Account acc, integer recordsToCreate, Boolean insertRecords){
    	//check fro account
    	if(acc == null){
    		throw new Exceptions.IllegalArgumentException('No acc provided for contact');
    	}
    	
    	//create the account
    	List<Contact> conList = new List<Contact>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Contact con = (Contact) DataGenerator.createSObjectWithDefaultValues('Contact');
    		con.AccountId = acc.id;
    		con.FirstName = 'First' + i;
    		con.lastName = 'last' + i;
    		con.email = 'emailTestingaf@aol.com'+i;
    		con.phone = '555555555';
    		
    		conList.add(con);
    	}
    	
    	//check for insert flag
    	if(insertRecords) { insert conList;}
    	
    	//return contacts
    	return conList;
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
    
    public static List<Passive_Device__c> createPassiveDevices(Site_Survey__c site, integer recordsToCreate, Boolean insertRecords){
    	//check for account
    	if(site == null){
    		throw new Exceptions.IllegalArgumentException('No Site Survey provided for passive device');
    	}
    	
    	//create the account
    	List<Passive_Device__c> passList = new List<Passive_Device__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Passive_Device__c pass = (Passive_Device__c) DataGenerator.createSObjectWithDefaultValues('Passive_Device__c');
    		pass.Site_Survey__c = site.id;
    		pass.Device__c = 'Wall Tap';
    		
    		passList.add(pass);
    	}
    	
    	//check for insert flag
    	if(insertRecords) { insert passList;}
    	
    	//return contacts
    	return passList;
    }
    
    public static List<Building__c> createBuildings(Site_Survey__c site, integer recordsToCreate, Boolean insertRecords) {
    	//check for site survey
    	if(site == null){
    		throw new Exceptions.IllegalArgumentException('No site provided for building');
    	}
    	
    	List<Building__c> buildList = new List<Building__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		//create building
    		Building__c build = (Building__c)DataGenerator.createSObjectWithDefaultValues('Building__c');
    		build.Site_Survey__c = site.id;
    		build.Name = 'BuildingName '+ i;
    		
    		buildList.add(build);
    	}
    	
    	//check for insert flag
    	if(insertRecords) { insert buildList;}
    	
    	//return buildings
    	return buildList;
    }
    
    public static List<BB_IDF__c> createBBIDF(Site_Survey__c site, String recordIdName, integer recordsToCreate, Boolean insertRecords) {
    	//check for site survey
    	if(site == null){
    		throw new Exceptions.IllegalArgumentException('No site provided for building');
    	}
    	
    	List<BB_IDF__c> idfList = new List<BB_IDF__c>();
    	String recordId = Utilities.RecordTypeNameToIdWithObject(recordIdName, 'BB_IDF__c');
    	for(integer i = 1; i <= recordsToCreate; i++){
    		//create idf
    		BB_IDF__c idf = (BB_IDF__c)DataGenerator.createSObjectWithDefaultValues('BB_IDF__c');
    		idf.Site_Survey__c = site.id;
    		idf.recordTypeId = recordId;
    		
    		idfList.add(idf);
    	}
    	
    	//check for insert flag
    	if(insertRecords) { insert idfList;}
    	
    	//return idf
    	return idfList;
    }
    
    public static List<Media_IDF__c> createMediaIDF(Building__c build, integer recordsToCreate, Boolean insertRecords) {
    	//check for site survey
    	if(build == null){
    		throw new Exceptions.IllegalArgumentException('No building provided for media idf');
    	}
    	
    	List<Media_IDF__c> idfList = new List<Media_IDF__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		//create building
    		Media_IDF__c idf = (Media_IDF__c)DataGenerator.createSObjectWithDefaultValues('Media_IDF__c');
    		idf.Building__c = build.id;
    		
    		idfList.add(idf);
    	}
    	
    	//check for insert flag
    	if(insertRecords) { insert idfList;}
    	
    	//return buildings
    	return idfList;
    }
}