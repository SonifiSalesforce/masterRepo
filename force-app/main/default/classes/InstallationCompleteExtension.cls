public class InstallationCompleteExtension {
	public Work_Order__c installObj {get;set;} 
	public String tab {get;set;}
	public String oldTab {get;set;}
	public List<TV_Type__c> tvList {get;set;}
	private String id{get;set;}
	public List<SelectOption> yesNoList {get;set;}
	public List<SelectOption> yesNaList {get;set;}
	public Account acc {get;set;}
	private String privateTVRecordId {get;set;}
	public Integer numRows {get;set;}
	public List<Task> taskList {get;set;}
	public List<Integer> dtvHDList {get;set;}
	public List<Integer> dtvAnalogList {get;set;}
	public List<Building__c> buildingList {get;set;}
	private String siteSurveyId {get;set;}
	public Map<String, String> photoMap {get;set;}
	public Map<String, List<String>> photoGroup2photoMap {get;set;}
	public Map<Id, Associated_Item__c> id2AssociatedItem {get;set;}
	public List<Id> fullParentIds {get;set;}
	public Set<Id> partialParentIds {get;set;}
	public Map<Id, List<Id>> parent2ChildIds {get;set;}
	public Map<Id, List<Associated_Item__c>> orderId2AssItems {get;set;}
	public Map<Id, Integer> orderId2Size {get;set;}
	public Map<Id, Set<Id>> partialParent2ChildIds {get;set;}
	public Integer headerTasks {get;set;}
	public Integer headerTVs {get;set;}
	public Integer headerBuildings {get;set;}
	public String otherForms {get;set;}
	public string treeJSON {get;set;}
	public string treeJSONPartial {get;set;}
	public List<Associated_Item__c> grandParentItems {get;set;}
	private boolean partnerPortal {get;set;}
	// Global JSON generator
    public static JSONGenerator gen {
    	get {
    		if(gen == null)
    			gen = JSON.createGenerator(true);
    		return gen;
    	} 
    	set;
    }    
	
	public InstallationCompleteExtension(ApexPages.StandardController stdController) {
		this.installObj = (Work_Order__c)stdController.getRecord();
		this.tab = 'Cover Sheet';
		this.oldTab = '';
		this.tvList = new List<TV_Type__c>();
		this.yesNoList = new List<SelectOption>{new SelectOption('Yes', 'Yes'), new SelectOption('No', 'No')};
		this.yesNaList = new List<SelectOption>{new SelectOption('Yes', 'Yes'), new SelectOption('Na', 'N/A')};
		this.acc = new Account();
		this.privateTvRecordId = '';
		this.numRows = 1;
		this.taskList = new List<Task>();
		this.buildingList = new List<Building__c>();
		this.siteSurveyId = '';
		this.photoMap = new Map<String, String>();
		this.photoGroup2photoMap = new Map<String, List<String>>();
		this.id2AssociatedItem = new Map<Id, Associated_Item__c>();
		this.fullParentIds = new List<Id>();
		this.partialParentIds = new Set<Id>();
		this.parent2ChildIds = new Map<Id, List<Id>>();
		this.orderId2AssItems = new Map<Id, List<Associated_Item__c>>();
		this.orderId2Size = new Map<Id, Integer>();
		this.partialParent2ChildIds = new Map<Id, Set<Id>>();
		this.headerTasks = 0;
		this.headerTVs = 0;
		this.headerBuildings = 0;
		this.otherForms = '';
		this.treeJSON = '';
		this.treeJSONPartial = '';
		this.grandParentItems = new List<Associated_Item__c>();
		this.partnerPortal = false;
		
		//query for the record ids 
    	List<RecordType> recordIds = [Select SobjectType, Id, DeveloperName From RecordType WHERE SobjectType = 'TV_Type__c' OR SobjectType = 'Site_Survey__c'];
    	
    	//get the guestroom tv id
    	for(RecordType recId : recordIds){
    		if(recId.DeveloperName == 'Guestroom_TV'){
    			this.privateTvRecordId = recId.Id;
    		} 
    	}
    	
    	/*shawks 20171006:  - comment out since partners not used and security change for Winter '18 breaks (Improved Brower Protection (Referer))
    	//get the base Url
    	if(ApexPages.currentPage().getHeaders().containsKey('Referer')){
    		String baseUrl = ApexPages.currentPage().getHeaders().get('Referer');
	    	System.debug('Base URL is ' + baseUrl);
	    	
	    	//split the url
	    	List<String> pathList = baseUrl.split('/');
	    	if(pathList[3] == Definitions.PORTAL_NAME){ 
	    		this.partnerPortal = true;
	    	}
    	}
    	System.debug('Partner Portal? ' + this.partnerPortal);
    	*/
		
		//get the id of the site survey if passed through parameters
    	if(System.currentPageReference().getParameters().containsKey('Id')) {
    		this.id= System.currentPageReference().getParameters().get('Id');
    		
    		//loadWorkOrder();
    		loadEverything();
    	}
    	
    	//get the id of the site survey if passed through parameters
    	if(System.currentPageReference().getParameters().containsKey('Tab')) {
    		this.tab= System.currentPageReference().getParameters().get('Tab');
    		
    	}
    	
    	
	}
	
	/***************************************************************************************
    ***************************** JSON GENERATOR *******************************************
    ****************************************************************************************/
	
	private void getTreeJSON() {
        gen.writeStartArray();
        for(String oItemId : this.fullParentIds) {
        	if(null != this.orderId2AssItems.get(oItemId)[0]){
            	convertNodeToJSON(this.orderId2AssItems.get(oItemId)[0], 'full');
        	}
        }
        gen.writeEndArray();
        this.treeJSON = gen.getAsString();
        
        System.debug('JSON is ' + this.treeJSON);
        
        gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for(String oItemId : this.partialParentIds) {
        	if(null != this.orderId2AssItems.get(oItemId)[0]){
            	convertNodeToJSON(this.orderId2AssItems.get(oItemId)[0], 'partial');
        	}
        }
        gen.writeEndArray();
        this.treeJSONPartial = gen.getAsString();
        
        System.debug('JSON Partial is ' + this.treeJSONPartial);
    }
    
    private void convertNodeToJSON(Associated_Item__c inventoryProduct, String listType){
    	System.debug('convertNodeToJSON ' + inventoryProduct.Order_Item__r.Product__r.Name + ' inventoryProduct children are ' + parent2ChildIds.get(inventoryProduct.Order_Item__c));
    	
    	gen.writeStartObject();
        if(null != inventoryProduct.Id)
        {
        	gen.writeStringField('key', inventoryProduct.Id);
        	gen.writeStringField('href','/'+inventoryProduct.Id);
        	gen.writeStringField('target', '_top');
        }
        if(null != inventoryProduct.Order_Item__r.Product__r.Name)
        	gen.writeStringField('title', inventoryProduct.Order_Item__r.Product__r.Name);
        if(null != inventoryProduct.Quantity__c)
        	gen.writeNumberField('quantity', inventoryProduct.Quantity__c.intValue());
        if(null != inventoryProduct.Billing_Commencement_Date__c)
        	gen.writeStringField('bcd', inventoryProduct.Billing_Commencement_Date__c.format());
        if(inventoryProduct.Partial_Order__c){
        	gen.writeBooleanField('partial', true);
        }
        	
        gen.writeBooleanField('expanded', true);
        if(listType == 'full'){
	         if(parent2ChildIds.get(inventoryProduct.Order_Item__c).size() == 0) {
	        	gen.writeBooleanField('hasChildren', false);
	        	gen.writeBooleanField('folder', false);
	        } else {
	        	gen.writeBooleanField('hasChildren', true);
	        	gen.writeBooleanField('folder', true);
	        	gen.writeFieldName('children');
	            gen.writeStartArray(); 
		    	for(String oItem : parent2ChildIds.get(inventoryProduct.Order_Item__c)) {
	            	for(Associated_Item__c aItem : this.orderId2AssItems.get(oItem)){
	            		convertNodeToJSON(aItem, listType);	
	            	}	
	            }
	            gen.writeEndArray();       
	        }
        } else {
        	if(partialParent2ChildIds.get(inventoryProduct.Order_Item__c).size() == 0) {
	        	gen.writeBooleanField('hasChildren', false);
	        	gen.writeBooleanField('folder', false);
	        } else {
	        	gen.writeBooleanField('hasChildren', true);
	        	gen.writeBooleanField('folder', true);
	        	gen.writeFieldName('children');
	            gen.writeStartArray(); 
		    	for(String oItem : partialParent2ChildIds.get(inventoryProduct.Order_Item__c)) {
	            	for(Associated_Item__c aItem : this.orderId2AssItems.get(oItem)){
	            		convertNodeToJSON(aItem, listType);	
	            	}	
	            }
	            gen.writeEndArray();       
	        }
        }
    	gen.writeEndObject();
    } 
	
	/***********************************************************************************
    ***************************** ADD ROW *******************************************
    *************************************************************************************/
	public void addAllRows(){
		
		this.numRows = this.headerTasks;
		this.addRowTask();
		
		this.numRows = this.headerTVs;
		this.addRowTVInfo();
		
		this.numRows = this.headerBuildings;
		this.addRowBuilding();
		
		//set all header values to zero
		this.headerTasks = 0;
		this.headerTVs = 0;
		this.headerBuildings = 0;
	}
	//upserts the prior records of the list
    //looks at the last item in list and see if brand and model is filled
    // if yes then upsert the new item and add a new TV type to list
    // if false then do not upsert the last record and leave list as is
    public void addRowTVInfo() {
    	if(this.tab != 'ALL'){
    		System.debug('Tab is ' + this.tab);
	    	//save the object
	    	Boolean addNew = saveObject(this.tvList, new List<String>{'TV_Manufacturer__c'}, false, false, new List<String>());
	    	
	    	//if successful, add a new record to the list
	    	if(addNew){
	    		for(Integer i = 0; i < this.numRows; i++){
		    		TV_Type__c tv = new TV_Type__c(Work_Order__c = this.id, RecordTypeId = this.privateTvRecordId);
		    		this.tvList.add(tv);
	    		}
	    	}
    	} else {
    		System.debug('Tab is ALL');
    		for(Integer i = 0; i < this.numRows; i++){
	    		TV_Type__c tv = new TV_Type__c(Work_Order__c = this.id, RecordTypeId = this.privateTvRecordId);
	    		this.tvList.add(tv);
    		}
    	}
    }
	
	public void addRowTask() {
		if(this.tab != 'ALL'){
			System.debug('Tab is ' + this.tab);
			//save the object
		    Boolean addNew = saveObject(this.taskList, new List<String>{'Status'}, false, false, new List<String>());
		    
		    //if successful, add a new record to the list
		    if(addNew){
	    		for(Integer i = 0; i < this.numRows; i++){
					this.taskList.add(new Task(WhatId = this.id, OwnerId=this.installObj.OwnerId));
	    		}
		    }
		}else {
			System.debug('Tab is ALL');
    		for(Integer i = 0; i < this.numRows; i++){
	    		this.taskList.add(new Task(WhatId = this.id, OwnerId=this.installObj.OwnerId));
    		}
    	}
	}
	
	public void addRowBuilding() {
		if(this.tab != 'ALL'){
			System.debug('Tab is ' + this.tab);
			//save the object
		    Boolean addNew = saveObject(this.buildingList, new List<String>{'Name'}, false, false, new List<String>());
		    
		    //if successful, add a new record to the list
		    if(addNew){
	    		for(Integer i = 0; i < this.numRows; i++){
					this.buildingList.add(new Building__c(Work_Order__c = this.id));
	    		}
		    }
		}else {
    		for(Integer i = 0; i < this.numRows; i++){
	    		this.buildingList.add(new Building__c(Work_Order__c = this.id));
    		}
    	}
	}
	
	/***********************************************************************************
    ***************************** SAVE METHODS *******************************************
    *************************************************************************************/
    
    //save method and redirect to view of the site survey
    public PageReference saveInfo() {
    	quickSave();
    	
    	PageReference ref = new PageReference('/' + this.id);
    	ref.setRedirect(true);
    	System.debug('Page reference Url is ' + ref);
		return ref;
    }
    
    //quick save method
    public void quickSave(){
    	System.debug('Entering QuickSave Method...');
    	System.debug('Tab is ' + this.tab);
    	
    	if(this.tab == 'SOW') {
    		saveData(new List<Work_Order__c>{this.installObj});
    	} else if(this.tab == 'TV Information') {
    		saveObject(this.tvList, new List<String>{'TV_Manufacturer__c'}, true, false, new List<String>());
    	} else if(this.tab == 'Checklists') {
    		saveData(new List<Work_Order__c>{this.installObj});
    	} else if(this.tab == 'BB Building Construction') {
    		saveObject(this.buildingList, new List<String>{'Name'}, true, false, new List<String>());
    	} else if(this.tab == 'UTR') {
    		saveObject(this.taskList, new List<String>{'Status'}, true, false, new List<String>());
    	} 
    }
    
   	// save data when someone switches tabs
   	public void quickSaveSwitch(){
   		System.debug('Entering quick save switch...');
    	System.debug('Tab is ' + this.tab);
    	System.debug('Old tab is ' + this.oldTab);
    	
    	if(this.oldTab == 'SOW') {
    		saveData(new List<Work_Order__c>{this.installObj});
    	} else if(this.oldTab == 'TV Information') {
    		saveObject(this.tvList, new List<String>{'TV_Manufacturer__c'}, true, false, new List<String>());
    	} else if(this.oldTab == 'Checklists') {
    		saveData(new List<Work_Order__c>{this.installObj});
    	} else if(this.oldTab == 'BB Building Construction') {
    		saveObject(this.buildingList, new List<String>{'Name'}, true, false, new List<String>());
    	} else if(this.oldTab == 'UTR') {
    		saveObject(this.taskList, new List<String>{'Status'}, true, false, new List<String>());
    	}
    	
    	this.oldTab = this.tab;
    	
   	}
   	
   	// upsert the data
   	public List<Id> saveData(List<SObject> objects) {
    	System.debug('Entering saveData method with ' + objects.size() + ' ' + objects[0].getSObjectType() + ' records.');
    	
    	//initialize var
    	List<Id> allIds = new List<Id>();
    	List<Sobject> insertList = new List<Sobject>();
    	List<Sobject> updateList = new List<Sobject>();
    	
    	//check to make sure list is not empty
    	if(objects.size() != 0) {
	    	//go through objects and put them into the correct list
	    	for(Sobject obj : objects){
	    		if(obj.get('Id') == null){
	    			insertList.add(obj);
	    		} else{
	    			updateList.add(obj);
	    		}
	    	}
	    	System.debug('Insert list is ' + insertList);
	    	System.debug('update list is ' + updateList);
	    	
	    	// try to upsert the data
	    	try {
	    		//upsert the records
	    		List<Database.SaveResult> insertList1 = new List<Database.SaveResult>();
	    		List<Database.SaveResult> updateList2 = new List<Database.SaveResult>();
	    		if(insertList.size() > 0){insertList1 = Database.insert(insertList);}
	    		if(updateList.size() > 0){updateList2 = Database.update(updateList);}
	    		
	    		//get the ids of the successful updates/inserts or post the errors
	    		for(Database.SaveResult up : insertList1){
	    			if(up.isSuccess()){
	    				allIds.add(up.id);
	    			} else {
	    				for(Database.Error er : up.getErrors()){
	    					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,er.getMessage()));
	    				}
	    			}
	    		}
	    		for(Database.SaveResult up : updateList2){
	    			if(up.isSuccess()){
	    				allIds.add(up.id);
	    			} else {
	    				for(Database.Error er : up.getErrors()){
	    					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,er.getMessage()));
	    				}
	    			}
	    		}
	    		return allIds;
	    	} catch (Exception e) {
	    		Utilities.writeLOg('Unable to upsert ' + objects.size() + ' ' + objects[0].getSObjectType() + ' records: ' +e.getMessage(),
					DesktopSurveyExtension.class, 'saveData', LoggingLevel.DEBUG);
	    	}
    	}
    	System.debug('Exiting save data method....');
    	return allIds;
    }
    
    //save the object and returns if all objects are inserted or all of them except the last
    //allRecords - true means to check each record to see if they meet the requirements; false means to check the last one
    // return true if all records are upserted; false if the last record is not upserted - for allRecords = false
    // checkIfFilled is to see if any of the fields have data then to save record
    // field that is populated right away like the lookup to site survey; used for when checkIfFilled is true
    public Boolean saveObject(List<Sobject> objectList, List<String> fieldCheckList, Boolean allRecords, Boolean checkIfFilled, List<String> theExceptionList){
    	//debug
    	System.debug('Entering saveObject method with ' + objectList.size() + ' ' + objectList.getSObjectType() + ' records.');
    	System.debug('The fields to check are: ' + fieldCheckList);
    	System.debug('Check all records: ' + allRecords);
    	System.debug('CheckIfFilled: ' + checkIfFilled + '. Exceptions are: ' + theExceptionList);
    	
    	if(objectList.size() == 0){
    		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Record(s) not saved.'));
    		return false;
    	}
    	
    	//check all records
    	if(allRecords) {
    		List<Sobject> upsertList = new List<Sobject>();
    		Boolean pass;
    		//go through each record
    		for(Sobject obj : objectList){
    			
    			//enter this if you want objects to check if all fields are filled out
    			if(!checkIfFilled){
    				SYstem.debug('Check filled is false...');
    				pass = true;
	    			//check each field on the record
	    			for(String fld : fieldCheckList) { 
	    				if(obj.get(fld) == '' || obj.get(fld) == null){
	    					pass = false;
	    					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,fld + ' field must be filled out'));
	    				}
	    			}
    			} 
    			// enter this if one field is filled out then to save record
    			else {
    				SYstem.debug('Check filled is true...');
    				pass= false; 
    				//check each field and if it contains a value then save it
    				for(String fld : fieldCheckList) { 
	    				if(obj.get(fld) != '' && obj.get(fld) != null && obj.get(fld) != false){
	    					
	    					Boolean notInException = true;	
	    					for(String str : theExceptionList){
			    				if(str == fld)	{
			    					notInException = false;
			    					System.debug('Found an exception');
			    				}
	    					}
	    					if(notInException){
		    					pass = true;
	    					}
	    				}
	    			}
	    			if(!pass){
    					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'One field must be filled out in order for it to be saved'));
    				}
    			}
    			
    			//true - save all objects;  false - save all objects except the last one
	    		if(pass){
	    			System.debug('Adding ' + obj + ' to the upsert list');
	    			upsertList.add(obj);
	    		}else {
	    			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Record(s) on ' + this.oldTab + ' tab is not saved because fields are missing'));
	    			System.debug('Did not add ' + obj + ' to the upsert list.');
	    		}
    		}
    		
    		//upsert the upsert list if not empty
    		if(upsertList.size() > 0){
    			System.debug('Upserting the list: ' + upsertList);
    			saveData(upsertList);
    		}
    		System.debug('Exiting saveObject method...');
    		return true;
    	}
    	//check only the last record
    	else {
    		//get the last object
    		Sobject obj = objectList.get(objectList.size()-1);
    		Boolean pass = true;
    		
    		//enter this if you want objects to check if all fields are filled out
			if(!checkIfFilled){
				
				pass = true;
    			//check each field on the record
    			for(String fld : fieldCheckList) { 
    				if(obj.get(fld) == '' || obj.get(fld) == null){
    					pass = false;
    					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,fld + ' field must be filled out'));
    				}
    			}
			} 
			// enter this if one field is filled out then to save record
			else {
				pass = false; 
				//check each field and if it contains a value then save it
				for(String fld : fieldCheckList) { 
    				if(obj.get(fld) != '' && obj.get(fld) != null && obj.get(fld) != false){
    					
    					Boolean notInException = true;	
    					for(String str : theExceptionList){
		    				if(str == fld)	{
		    					notInException = false;
		    					System.debug('Found an exception');
		    				}
    					}
    					if(notInException){
	    					pass = true;
    					}
    				}
    			}
    			if(!pass){
    				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'One field must be filled out in order for it to be saved'));
    			}
			}
    		
    		//true - save all objects;  false - save all objects except the last one
    		if(pass){
    			System.debug('Upserting all records...');
    			System.debug('The records being upserted are: ' + objectList);
    			saveData(objectList);
    			System.debug('Exiting saveObject method...');
    			return true;
    		}else {
    			System.debug('Upserting all records except last...');
    			obj = objectList.remove(objectList.size()-1);
    			
    			//upsert the objects
    			System.debug('The records being upserted are: ' + objectList);
    			if(objectList.size() > 0){
    				saveData(objectList);
    			}
    			objectList.add(obj);
    			System.debug('Exiting saveObject method...');
    			return false;
    		}
    	} 
    }
    
    /*******************************************************************************************
    ***************************************Load Methods*************************************
    *******************************************************************************************/
    
    //load everything
    public void loadEverything() {
    	
    	//load the work order
    	loadWorkOrder();
    	
    	//load the account
    	loadAccount();
    	
    	//load the Type Dara
    	loadTypeData();
    	
    	//load the task information
    	loadTasksData();
    	
    	//load the buildings
    	loadBuildingsData();
    	
    	//load photos
    	loadPhotoData();
    }
    
    //load the work order
    public void loadWorkOrder() {
    	//initialize var
    	String fieldQuery = '';
    	String fieldQueryItem = '';
    	String oppId = '';
    	
    	//get the fields needed to be retrieved
		fieldQuery = String.join(getSObjectFields(Work_Order__c.getSObjectType()), ',');
		fieldQueryItem = String.join(getSObjectFields(Associated_Item__c.getSObjectType()), ',');
    	System.debug('The fields that are being queried for workOrder are ' + fieldQuery);
    	
		System.debug('querying for record...');
		List<Work_Order__c> workList = new List<Work_Order__c>();
		try{
			workList = Database.query('Select ' + fieldQuery + ', (SELECT Id, Name, LastModifiedDate FROM Attachments), (SELECT ' + fieldQueryItem + ', Order_Item__r.Parent__c, Order_Item__r.Product__r.Name, Order_Item__r.Name, Order_Item__r.Status__c FROM Associated_Items__r), Owner.Name From Work_Order__c WHERE Id = \'' + this.id + '\' limit 1');
			System.debug('The retrieved records are ' + workList);
			if(workList.size() > 0 ) {
				this.installObj = workList[0];
				Datetime latestDate;
				//get the id of the msot recent attachment with the name installation forms
				for(Attachment att : this.installObj.Attachments){
					if(att.Name.containsIgnoreCase('Installation Forms')){
						if(latestDate == null){
							this.otherForms = Definitions.DOWNLOAD_ATTACHMENT + '?file=' + att.id;
							latestDate = att.LastModifiedDate;
						} else if(latestDate < att.LastModifiedDate){
							this.otherForms = Definitions.DOWNLOAD_ATTACHMENT + att.id;
							latestDate = att.LastModifiedDate;
						}
					}
				}
				
				//make the map of the associated items
				for(Associated_Item__c item : [SELECT Billing_Commencement_Date__c, id, Install_Complete_Date__c, Work_Order__c, Status__c, Quantity__c, Project_Number__c, Partial_Order__c, Order_Item__c, Install_Cost__c, Order_Item__r.Parent__c, Order_Item__r.Product__r.Name, Order_Item__r.Name, Name, Order_Item__r.Status__c FROM Associated_Item__c WHERE Work_Order__c = :this.installObj.id]){
					
					System.debug('New parent2ChildId Map is 1::' + this.parent2ChildIds);
					//map order item id to the associated item
					if(this.orderId2AssItems.containsKey(item.Order_Item__c)){
						this.orderId2AssItems.get(item.Order_Item__c).add(item);
					} else {
						this.orderId2AssItems.put(item.Order_Item__c, new List<Associated_Item__c>{item});
					}
					if(item.Order_Item__r.Parent__c == null){
						//set parent ids if it is being serviced or not
						if(item.Order_Item__r.Status__c == 'Cancelled'){
							this.partialParentIds.add(item.Order_Item__c);
							if(!this.parent2ChildIds.containsKey(item.Order_Item__c)){
								this.parent2ChildIds.put(item.Order_Item__c, new List<Id>());
							}
						} else {
							this.fullParentIds.add(item.Order_Item__c);
							if(!this.parent2ChildIds.containsKey(item.Order_Item__c)){
								this.parent2ChildIds.put(item.Order_Item__c, new List<Id>());
							}
						}
					} else {
						if(item.Order_Item__r.Status__c != 'Cancelled'){
							//not a partial order
							System.debug('Name of associated item: ' + item.Name);
							if(this.parent2ChildIds.containsKey(item.Order_Item__r.Parent__c)){
								System.debug('Adding item to parent ' + item.Order_Item__r.Parent__c);
								this.parent2ChildIds.get(item.Order_Item__r.Parent__c).add(item.Order_Item__c);
								System.debug('New parent2ChildId Map is 2::' + this.parent2ChildIds);
							} else {
								System.debug('putting new item to parent ' + item.Order_Item__r.Parent__c);
								this.parent2ChildIds.put(item.Order_Item__r.Parent__c, new List<Id>{item.Order_Item__c});
								System.debug('New parent2ChildId Map is 3::' + this.parent2ChildIds);
							}
							// add map so that order item has 0 children
							if(!this.parent2ChildIds.containsKey(item.Order_Item__c)){
								this.parent2ChildIds.put(item.Order_Item__c, new List<Id>());
							}
						} else {
							System.debug('Partial Order...' + item.Name);
							//partial order
							//add item to the parent related to that record
							if(this.partialParent2ChildIds.containsKey(item.Order_Item__r.Parent__c)){
								System.debug('Adding item to parent ' + item.Order_Item__r.Parent__c);
								this.partialParent2ChildIds.get(item.Order_Item__r.Parent__c).add(item.Order_Item__c);
							} else {
								System.debug('putting new item to parent ' + item.Order_Item__r.Parent__c);
								this.partialParent2ChildIds.put(item.Order_Item__r.Parent__c, new Set<Id>{item.Order_Item__c});
							}
							// add map so that order item has 0 children
							if(!this.partialParent2ChildIds.containsKey(item.Order_Item__c)){
								this.partialParent2ChildIds.put(item.Order_Item__c, new Set<Id>());
							}
						}
					}
				}
			} else {
				this.installObj = new Work_Order__c();
			}
		} catch (DMLException e) {
			this.installObj = new Work_Order__c();
		}
		System.debug('OrderId 2 size before ' + this.orderId2Size);
		for(String item : partialParent2ChildIds.keySet()){
			// put the partial order grandparent name into the list of partial
			Associated_Item__c assItem = this.orderId2AssItems.get(item)[0];
			System.debug('Associated item is ' + assItem);
			//if(assItem.Order_Item__r.Parent__c != null){
			while(assItem.Order_Item__r.Parent__c != null){
				System.debug('Adding the parent of the order item to the list ' + assItem.Order_Item__r.Parent__c);
				//Associated_Item__c assItem2 = this.orderId2AssItems.get(assItem.Order_Item__r.Parent__c)[0];
				if(!this.partialParent2ChildIds.containsKey(assItem.Order_Item__r.Parent__c)){
					this.partialParent2ChildIds.put(assItem.Order_Item__r.Parent__c, new Set<Id>{assItem.Order_Item__c});
				}  
				assItem = this.orderId2AssItems.get(assItem.Order_Item__r.Parent__c)[0];
			} 
			this.partialParentIds.add(assItem.Order_Item__c);
		}
		System.debug('Partial order parent map is ' + this.partialParent2ChildIds);
		
		//if form is empty then set the id of the default document retrieved from a custom setting
		if(this.otherForms == ''){
    		List<Installation_Form__c> formId = Installation_Form__c.getAll().values();
    		if(formId.size() > 0){
	    		this.otherForms = Definitions.DOWNLOAD_ATTACHMENT + 'Installation_Forms.xls?file=' + formId[0].Name;
    		}
    	}
    	
    	if(this.partnerPortal){
    		this.otherForms = '/sonifipartners' + this.otherForms;    		
    	}
    	
    	//initialize the JSON and make a list of grandparent ids 
    	if(this.partialParentIds.size() > 0 || this.fullParentIds.size() > 0){
    		System.debug('About to generate the JSON...');
       		getTreeJSON();
       		Set<Associated_Item__c> items = new Set<Associated_Item__c>();
       		for(Id full : this.fullParentIds){
       			items.add(this.orderId2AssItems.get(full)[0]);
       		}
       		for(Id partial : this.partialParentIds){
       			items.add(this.orderId2AssItems.get(partial)[0]);
       		}
       		this.grandParentItems.addAll(items);
    	} else {
 			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
		        			     'No product inventory assigned to account.', 
		        			     'To view product inventory for this account, you must first add a product inventory to the account.'));
    	}
		
		System.debug('Work Order is: ' + this.installObj);
		System.debug('Order id to associated items map is ' + this.orderId2AssItems);
		System.debug('Full Order item list of Ids ' + this.fullParentIds);
		System.debug('Partial Order item list of ids ' + this.partialParentIds);
		System.debug('Parent to child map is ' + this.parent2ChildIds);
		System.debug('OrderId 2 size ' + this.orderId2Size);
		System.debug('Partial order parent map is ' + this.partialParent2ChildIds);
    }
    
    //load the related account
    public void loadAccount() {
    	//initialize var
    	String fieldQuery = '';
    	
    	//get the fields needed to be retrieved
		fieldQuery = String.join(getSObjectFields(Account.getSObjectType()), ',');
    	System.debug('The fields that are being queried for Account are ' + fieldQuery);
    	
		System.debug('querying for record...');
		List<Account> accList = new List<Account>();
		try{
			if(this.installObj.Site__c != null){
				accList = Database.query('Select ' + fieldQuery + ' From Account WHERE Id =\'' + this.installObj.Site__c + '\' limit 1');
			}
			System.debug('The retrieved records are ' + accList);
			if(accList.size() > 0 ) {
				this.acc = accList[0];
			} else {
				this.acc = new Account();
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'No Account attached to Work Order'));
			}
		} catch (DMLException e) {
			this.acc = new Account();
		}
		
		System.debug('account is: ' + this.acc);
    }
        
    //load the tv type records attached to the site survey and the account
    public void loadTypeData() {
    	//initialize var
    	String fieldQueryTVType = '';
    	
    	//get the fields needed to be retrieved
		fieldQueryTVType = String.join(getSObjectFields(TV_Type__c.getSObjectType()), ',');
    	System.debug('The fields that are being queried for TV Type are ' + fieldQueryTVType);
    	
		System.debug('querying for record...');
		try{
			this.tvList = Database.query('Select ' + fieldQueryTVType + ', TV_Manufacturer__r.Name, TV_Model__r.Name From TV_Type__c WHERE Work_Order__c =\'' + this.id + '\'');
			System.debug('The retrieved records are ' + this.tvList);
			if(tvList.size() == 0 ) {
				this.tvList.add(new TV_Type__c(Work_Order__c = this.installObj.id));
			} 
		} catch (DMLException e) {
			this.tvList.add(new TV_Type__c(Site__c = this.installObj.id));
		}
		
		System.debug('TV Types are: ' + this.tvList);
    }
    
    //load the tasks
    public void loadTasksData() {
    	//initialize var
    	String fieldQuery = '';
    	
    	//get the fields needed to be retrieved
		fieldQuery = String.join(getSObjectFields(Task.getSObjectType()), ',');
    	System.debug('The fields that are being queried for Tasks are ' + fieldQuery);
    	
		System.debug('querying for record...');
		try{
			this.taskList = Database.query('Select ' + fieldQuery + ', Owner.Name From Task WHERE WhatId =\'' + this.Id + '\' AND Status != \'Completed\'');
			System.debug('The retrieved records are ' + this.tvList);
			if(this.taskList.size() == 0 ) {
				this.taskList.add(new Task(WhatId = this.id, OwnerId=this.installObj.OwnerId));
			} 
		} catch (DMLException e) {
			Task task = new Task(WhatId = this.id, OwnerId=this.installObj.OwnerId);
			this.taskList.add(task);
		}
		
		System.debug('Task are: ' + this.tvList);
    }
    
    //load the building records attached to the work order
    public void loadBuildingsData() {
    	//initialize var
    	String fieldQuery = '';
    	String searchQuery = '';
    	
    	//get the fields needed to be retrieved
		fieldQuery = String.join(getSObjectFields(Building__c.getSObjectType()), ',');
    	System.debug('The fields that are being queried for Building__c are ' + fieldQuery);
    	
		System.debug('querying for record...');
		try{
			this.buildingList = Database.query('Select ' + fieldQuery + ' From Building__c WHERE Work_Order__c =\'' + this.id + '\'');
			System.debug('The retrieved records are ' + this.buildingList);
			if(!(buildingList.size() > 0) ) {
				this.buildingList.add(new Building__c(Work_Order__c = this.id));
			} 
		} catch (DMLException e) {
			this.buildingList.add(new Building__c(Work_Order__c = this.id));
		}
		
		System.debug('Building__c are: ' + this.buildingList);
    }
    
    //load the photos
    public void loadPhotoData() {
    	//initialize var
    	String fieldQuery = '';
    	String searchQuery = '';
    	List<Site_Photo__c> photoList = new List<Site_Photo__c>();
    	
    	//get the fields needed to be retrieved
		fieldQuery = String.join(getSObjectFields(Site_Photo__c.getSObjectType()), ',');
    	System.debug('The fields that are being queried for Tasks are ' + fieldQuery);
    	
    	//add the search query
    	if(this.siteSurveyId != ''){
    		searchQuery = 'Work_Order__c = \'' + this.id + '\' OR Site_Survey__c = \'' + this.siteSurveyId + '\'';
    	} else {
    		searchQuery = 'Work_Order__c = \'' + this.id + '\''; 
    	}
    	
		System.debug('querying for record...');
		try{
			photoList = Database.query('Select ' + fieldQuery + ' From Site_Photo__c WHERE ' + searchQuery);
			 
		} catch (DMLException e) {
		}
		System.debug('Site_Photo__c are: ' + photoList);
		
		Map<String, Work_Order_Photos__c> workOrderMap = Work_Order_Photos__c.getAll();
		//map the names
		for(String n : Work_Order_Photos__c.getall().keySet()){
			this.photoMap.put(n, 'No');
			if(this.photoGroup2photoMap.containsKey(workOrderMap.get(n).Group_Name__c)){
				this.photoGroup2photoMap.get(workOrderMap.get(n).Group_Name__c).add(n);
			} else {
				this.photoGroup2photoMap.put(workOrderMap.get(n).Group_Name__c, new List<String>{n});
			}
		}
		System.debug('Photo group mapping of the photos ' + this.photoGroup2photoMap);
		System.debug('Photo map before mapping the photos ' + this.photoMap);
		
		//map the photos already queried
		for(Site_Photo__c photo : photoList){
			if(this.photoMap.containsKey(photo.Photo_Type__c)){
				this.photoMap.put(photo.Photo_Type__c, 'Yes');
			}
		}
		System.debug('Photo map after mapping the photos ' + this.photoMap);
    }
    /*******************************************************************************************
    ***************************************Helper Methods*************************************
    *******************************************************************************************/
   
    /* Returns all fields in an SObject */ 
    public static List<String> getSObjectFields(Schema.SObjectType objectType) {
    
	    // Check for object type 
	    if (objectType == null) { return null; }
	    
	    // Get field map
	    Map<String, SObjectField> fieldMap = objectType.getDescribe().fields.getMap();	      
	   
	    List<String> fieldList = new List<String>();
	    for (String f : fieldMap.keySet()) {
	    	if(f != 'geolocation__c'){
		       // DescribeFieldResult field = fieldMap.get(f).getDescribe();
		     	fieldList.add(f);
	    	}
	    }
	    
	    //return the list of fields
	    return fieldList;
    }
}