@isTest
private class InstallationCompleteExtensionTests {
	
	
	/****************************************************************************************************************
	**************************************Quick Save METHOD*************************************************************
	*****************************************************************************************************************/
	static testMethod void quickSaveTV() {
		User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
		InstallationCompleteExtension stdController;
		 TV_Manufacturer__c manu;
		System.runAs(u1){
			//create test data
	        Account acc = DataGenerator.createAccounts(1, true).get(0);
	        System.debug('Account data is ' + acc);
	        Work_Order__c work = createWorkOrder(acc, 1, true).get(0);
	        manu = new TV_Manufacturer__c(Name='Sony');
        	insert manu;
	        
	        //put in the test page
	        PageReference pageRef = Page.SiteSurvey;
			pageRef.getParameters().put('Id', work.id);
			Test.setCurrentPageReference(pageRef);
	        
	        //make the standard controller
	        ApexPages.StandardController controller = new ApexPages.StandardController(work);
	
		    // now pass it to the extension
		    stdController = new InstallationCompleteExtension(controller);
		    System.assert(stdController != null); // controller has successfully been created
		    
		    Test.startTest();
		    stdController.oldTab ='TV Information';
		    stdController.tab = 'BB Building Construction';
		    stdController.tvList[0].TV_Manufacturer__c = manu.id;
		    stdController.tvList[0].Quantity__c = 50;
		    stdController.tvList[0].Other_Model__c = 'test model';
		    stdController.tvList.add(new TV_Type__c(Work_Order__c = work.id));
		    stdController.quickSaveSwitch();
		    stdController.saveInfo();
		    Test.stopTest();
		}
		
		List<TV_Type__c> tvs = [SELECT id, TV_Manufacturer__c, Quantity__c FROM TV_Type__c WHERE TV_Manufacturer__c =: manu.id];
		
		//assertions
		System.assertEquals(50, tvs[0].Quantity__c);
		System.assertEquals(2, stdController.tvList.size());
		System.assertEquals('BB Building Construction', stdController.oldTab);
	}
	/****************************************************************************************************************
	**************************************ADD ROW METHODS*************************************************************
	*****************************************************************************************************************/
	static testMethod void addAllRows() {
		User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
		InstallationCompleteExtension stdController;
		System.runAs(u1){
			//create test data
	        Account acc = DataGenerator.createAccounts(1, true).get(0);
	        System.debug('Account data is ' + acc);
	        Work_Order__c work = createWorkOrder(acc, 1, true).get(0);
	        
	        //put in the test page
	        PageReference pageRef = Page.SiteSurvey;
			pageRef.getParameters().put('Id', work.id);
			Test.setCurrentPageReference(pageRef);
	        
	        //make the standard controller
	        ApexPages.StandardController controller = new ApexPages.StandardController(work);
	
		    // now pass it to the extension
		    stdController = new InstallationCompleteExtension(controller);
		    System.assert(stdController != null); // controller has successfully been created
		    
		    Test.startTest();
		    stdController.headerBuildings = 2;
		    stdController.headerTasks = 2;
		    stdController.headerTVs = 2;
		    stdController.tab ='ALL';
		    stdController.addAllRows();
		    Test.stopTest();
		}
		
		//assertions
		System.assertEquals(3, stdController.taskList.size());
		System.assertEquals(3, stdController.buildingList.size());
		System.assertEquals(3, stdController.tvList.size());
	}
	
	static testMethod void addBuildings(){
		User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
		InstallationCompleteExtension stdController;
		System.runAs(u1){
			//create test data
	        Account acc = DataGenerator.createAccounts(1, true).get(0);
	        System.debug('Account data is ' + acc);
	        Work_Order__c work = createWorkOrder(acc, 1, true).get(0);
	        insert new Building__c(Work_Order__c = work.id, Name = 'Building 1');
	        
	        //put in the test page
	        PageReference pageRef = Page.SiteSurvey;
			pageRef.getParameters().put('Id', work.id);
			Test.setCurrentPageReference(pageRef);
	        
	        //make the standard controller
	        ApexPages.StandardController controller = new ApexPages.StandardController(work);
	
		    // now pass it to the extension
		    stdController = new InstallationCompleteExtension(controller);
		    System.assert(stdController != null); // controller has successfully been created
		    
		    Test.startTest();
		    stdController.addRowBuilding();
		    stdController.addRowBuilding();
		    Test.stopTest();
		}
		
		//assertions
		System.assertEquals(2, stdController.buildingList.size());
	}
	
	static testMethod void addRowTasks() {
    	//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Work_Order__c work = createWorkOrder(acc, 1, true).get(0);
        User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', work.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(work);

	    // now pass it to the extension
	    InstallationCompleteExtension stdController = new InstallationCompleteExtension(controller);
	    System.assert(stdController != null); // controller has successfully been created
	    
	    Test.startTest();
		stdController.addRowTask();
		stdController.taskList[0].Status = 'In Progress';
		stdController.taskList[0].OwnerId = u1.id;
		stdController.addRowTask();
	    Test.stopTest();
	    
	    List<Task> ts = [SELECT Id FROM Task];
	    
	    //assertions
	    System.assertEquals(2, stdController.taskList.size());
	    System.assertEquals(1, ts.size());
    }
    
	static testMethod void addRowTvType() {
    	//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        System.debug('Account site id is ' + acc.Site_Id_Ext_id__c);
        Work_Order__c work = createWorkOrder(acc, 1, true).get(0);
        TV_Manufacturer__c manu = new TV_Manufacturer__c(Name='Sony');
        insert manu;

        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', work.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(work);

	    // now pass it to the extension
	    InstallationCompleteExtension stdController = new InstallationCompleteExtension(controller);
	    System.assert(stdController != null); // controller has successfully been created
	    
	    Test.startTest();
		stdController.addRowTVInfo();
		stdController.tvList[0].TV_Manufacturer__c = manu.id;
		stdController.tvList[0].Other_Model__c = 'test mdoel';
		stdController.addRowTVInfo();
	    Test.stopTest();
	    
	    List<TV_Type__c> tvs = [SELECT Id FROM TV_Type__c];
	    
	    //assertions
	    System.assertEquals(2, stdController.tvList.size());
	    System.assertEquals(1, tvs.size());
    }
	/****************************************************************************************************************
	**************************************LOAD TEST METHODS*************************************************************
	*****************************************************************************************************************/
	//load associated items
	static testMethod void loadAssociatedItems(){
		User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
		InstallationCompleteExtension stdController;
		System.runAs(u1){
			//create test data
	        Account acc = DataGenerator.createAccounts(1, true).get(0);
	        List<Product2> pList = DataGenerator.createProducts(1,true);
	        pList[0].Name = 'FTG';
	        update pList;
	        System.debug('Account data is ' + acc);
	        Work_Order__c work = createWorkOrder(acc, 1, true).get(0);
	        Order_Item__c oItemGrand1 = new Order_Item__c(Name = 'Order Item Grand 1', Product__c = pList[0].Id, Status__c = 'Installed');
	        Order_Item__c oItemGrand2 = new Order_Item__c(Name = 'Order Item Grand 2', Product__c = pList[0].Id, Status__c = 'Installed');
	        Order_Item__c oItemParent1 = new Order_Item__c(Name = 'Order Item Parent 1', Product__c = pList[0].Id, Status__c = 'Installed');
	        Order_Item__c oItemParent2 = new Order_Item__c(Name = 'Order Item Parent 2', Product__c = pList[0].Id, Status__c = 'Installed');
	        Order_Item__c oItemChild1 = new Order_Item__c(Name = 'Order Item Child 1', Product__c = pList[0].Id, Status__c ='Cancelled');
	        Order_Item__c oItemChild2 = new Order_Item__c(Name = 'Order Item Child 2', Product__c = pList[0].Id, Status__c = 'Installed');
	        insert new List<Order_Item__c>{oItemGrand1, oItemGrand2, oItemParent1, oItemParent2, oItemChild1, oItemChild2};
	        oItemParent1.Parent__c = oItemGrand1.id;
	        oItemParent2.Parent__c = oItemGrand2.id;
	        oItemChild1.Parent__c = oItemParent1.id;
	        oItemChild2.Parent__c = oItemParent1.id;
	        update new List<Order_Item__c>{oItemParent1, oItemParent2, oItemChild1, oItemChild2};
	        
	        Associated_Item__c aItemGrand1 = new Associated_Item__c(Name = 'Associated Item Grand 1', Order_Item__c = oItemGrand1.id, Work_Order__c = work.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
	        Associated_Item__c aItemGrand2 = new Associated_Item__c(Name = 'Associated Item Grand 2', Order_Item__c = oItemGrand2.id, Work_Order__c = work.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
	        Associated_Item__c aItemParent1 = new Associated_Item__c(Name = 'Associated Item Parent 1', Order_Item__c = oItemParent1.id, Work_Order__c = work.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
	        Associated_Item__c aItemParent2 = new Associated_Item__c(Name = 'Associated Item Parent 2', Order_Item__c = oItemParent2.id, Work_Order__c = work.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
	        Associated_Item__c aItemChild1 = new Associated_Item__c(Name = 'Associated Item Child 1', Order_Item__c = oItemChild1.id, Work_Order__c = work.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
	        Associated_Item__c aItemChild2 = new Associated_Item__c(Name = 'Associated Item Child 2', Order_Item__c = oItemChild2.id, Work_Order__c = work.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50, Partial_Order__c = true);
	        insert new List<Associated_Item__c>{aItemGrand1, aItemGrand2, aItemParent1, aItemParent2, aItemChild1, aItemChild2};
	        
	        //put in the test page
	        PageReference pageRef = Page.SiteSurvey;
			pageRef.getParameters().put('Id', work.id);
			Test.setCurrentPageReference(pageRef);
	        
	        //make the standard controller
	        ApexPages.StandardController controller = new ApexPages.StandardController(work);
	
		    // now pass it to the extension
		    stdController = new InstallationCompleteExtension(controller);
		    System.assert(stdController != null); // controller has successfully been created
		}
		
		//assertions
		System.assertEquals(2, stdController.fullParentIds.size());
		System.assertEquals(1, stdController.partialParentIds.size());
	}
	
	//load site photos
	static testMethod void loadSitePhotos(){
		User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
		InstallationCompleteExtension stdController;
		System.runAs(u1){
			//create test data
	        Account acc = DataGenerator.createAccounts(1, true).get(0);
	        System.debug('Account data is ' + acc);
	        Work_Order__c work = createWorkOrder(acc, 1, true).get(0);
	        insert new Work_Order_Photos__c(Group_Name__c = 'iTV Photos', Name = 'Mini Hub');
	        insert new List<Site_Photo__c>{new Site_Photo__c(Work_Order__c = work.id, Photo_Group__c = 'iTV', Photo_Type__c = 'Mini Hub'), new Site_Photo__c(Work_Order__c = work.id, Photo_Group__c = 'FTG', Photo_Type__c = 'FTG Antennas')};
	        
	        //put in the test page
	        PageReference pageRef = Page.SiteSurvey;
			pageRef.getParameters().put('Id', work.id);
			Test.setCurrentPageReference(pageRef);
	        
	        //make the standard controller
	        ApexPages.StandardController controller = new ApexPages.StandardController(work);
	
		    // now pass it to the extension
		    stdController = new InstallationCompleteExtension(controller);
		    System.assert(stdController != null); // controller has successfully been created
		    
		}
		
		//assertions
		System.assertEquals(1, stdController.photoMap.keySet().size());
	}
	
	//load all data with no records in the system
    static testMethod void loadAllDataNoRecords() {
    	//create test data
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        System.debug('Account site id is ' + acc.Site_Id_Ext_id__c);
        Work_Order__c work = createWorkOrder(acc, 1, true).get(0);
        
        //put in the test page
        PageReference pageRef = Page.SiteSurvey;
		pageRef.getParameters().put('Id', work.id);
		Test.setCurrentPageReference(pageRef);
        
        //make the standard controller
        ApexPages.StandardController controller = new ApexPages.StandardController(work);

	    // now pass it to the extension
	    InstallationCompleteExtension stdController = new InstallationCompleteExtension(controller);
	    System.assert(stdController != null); // controller has successfully been created
	    
	    //assertions
	    System.assertEquals(work.id, stdController.installObj.id);
	    System.assertEquals(1, stdController.tvList.size());
	    System.assertEquals(1, stdController.taskList.size());
    }
	
	 /****************************************************************************************************************
	**************************************CREATION/HELPER METHODS*************************************************************
	*****************************************************************************************************************/
	public static List<TV_Type__c> createTVTypes(Work_Order__c work, integer recordsToCreate, Boolean insertRecords){
    	//check for site Survey
    	if(work == null) {
    		throw new Exceptions.IllegalArgumentException('No work order provided for TV Type');
    	}
    	TV_Manufacturer__c manu = new TV_Manufacturer__c(Name='Sony');
        insert manu;
    	
    	//create the tv type
    	List<TV_Type__c> tvList = new List<TV_Type__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		TV_Type__c tv = (TV_Type__c)DataGenerator.createSObjectWIthDefaultValues('TV_Type__c');
    		tv.Work_Order__c = work.id;
    		tv.TV_Manufacturer__c = manu.id;
    		tv.Other_Model__c = 'test model';
    		tv.RecordTypeId = Utilities.RecordTypeNameToIdWithObject('Guestroom TV', 'TV_Type__c');
    		tvList.add(tv);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert tvList; }
    	
    	//return the list
    	return tvList;
    }
    /*
    public static List<Building__c> createBuildings(Work_Order__c work, integer recordsToCreate, Boolean insertRecords){
    	//check for site Survey
    	if(work == null) {
    		throw new Exceptions.IllegalArgumentException('No work order provided for Building');
    	}
    	
    	//create the tv type
    	List<Building__c> buildList = new List<Building__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Building__c build = (Building__c)DataGenerator.createSObjectWIthDefaultValues('Building__c');
    		build.Work_Order__c = work.id;
    		build.Name = 'Building Name ' + i;
    		buildList.add(build);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert buildList; }
    	
    	//return the list
    	return buildList;
    }*/
    
    public static List<Work_Order__c> createWorkOrder(Account acc, integer recordsToCreate, Boolean insertRecords){
    	//check for work ORder
    	if(acc == null) {
    		throw new Exceptions.IllegalArgumentException('No opportuntiy provided for work order');
    	}
    	
    	//create the tv type
    	List<Work_Order__c> workList = new List<Work_Order__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Work_Order__c work = (Work_Order__c)DataGenerator.createSObjectWIthDefaultValues('Work_Order__c');
    		//work.Opportunity__c = opp.id;
    		work.Site__c = acc.id;
    		
    		workList.add(work);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert workList; }
    	
    	//return the list
    	return workList;
    }
    
    public static List<Task> createTasks(Work_Order__c work, integer recordsToCreate, Boolean insertRecords){
    	//check for work ORder
    	if(work == null) {
    		throw new Exceptions.IllegalArgumentException('No Work_Order__c provided for Task');
    	}
    	
    	//create the tv type
    	List<Task> taskList = new List<Task>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Task t = (Task)DataGenerator.createSObjectWIthDefaultValues('Task');
    		t.WhatId = work.id;
    		t.Status = 'In Progress';
    		
    		taskList.add(t);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert taskList; }
    	
    	//return the list
    	return taskList;
    }
    
    public static List<Order__c> createOrders(Opportunity opp, integer recordsToCreate, Boolean insertRecords){
    	//check for work ORder
    	if(opp == null) {
    		throw new Exceptions.IllegalArgumentException('No Opportunity provided for Order__c');
    	}
    	
    	//create the tv type
    	List<Order__c> orderList = new List<Order__c>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Order__c o = (Order__c)DataGenerator.createSObjectWIthDefaultValues('Task');
    		o.Opportunity__c = opp.id;
    		
    		
    		orderList.add(o);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert orderList; }
    	
    	//return the list
    	return orderList;
    }
    /*
    public static List<Order_Item__c> createOrderItems(Order__c orders, integer recordsToCreate, Boolean insertRecords){
    	//check for work ORder
    	if(orders == null) {
    		throw new Exceptions.IllegalArgumentException('No order provided for order items');
    	}
    	
    	//create the tv type
    	List<Task> taskList = new List<Task>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Task t = (Task)DataGenerator.createSObjectWIthDefaultValues('Task');
    		t.WhatId = orders.id;
    		t.Status = 'In Progress';
    		
    		taskList.add(t);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert taskList; }
    	
    	//return the list
    	return taskList;
    }
    
    public static List<Order_Item__c> createAssociatedItems(Order_Item__c item, integer recordsToCreate, Boolean insertRecords){
    	//check for work ORder
    	if(item == null) {
    		throw new Exceptions.IllegalArgumentException('No order item provided for associated items');
    	}
    	
    	//create the tv type
    	List<Task> taskList = new List<Task>();
    	for(integer i = 1; i <= recordsToCreate; i++){
    		Task t = (Task)DataGenerator.createSObjectWIthDefaultValues('Task');
    		t.WhatId = work.id;
    		t.Status = 'In Progress';
    		
    		taskList.add(t);
    	}
    	
    	//check flag and insert records
    	if(insertRecords) { insert taskList; }
    	
    	//return the list
    	return taskList;
    }*/
}