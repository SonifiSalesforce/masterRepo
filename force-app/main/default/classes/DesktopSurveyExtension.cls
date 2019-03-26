global with sharing class DesktopSurveyExtension {
	public Site_Survey__c siteObject {get;set;} 
    private List<TV_Type__c> tvTypes {get;set;}
    public List<TV_Type__c> tvListGuest {get;set;}
    public Map<String, List<TV_Type__c>> id2TypeMap {get;set;} //maps the tv location to the list of related tv types
    public Map<String, TV_Location__c> id2TvLoc {get;set;} //maps the id of tv location to the tv location object
    public Map<String, List<Integer>> locationId2NumTVs {get;set;}
    private String id{get;set;}
    private String oppId{get;set;}
    public Map<String, List<TV_Type__c>> id2TVType {get;set;}
    public Rack_Location__c rackLoc {get;set;}
    public Set<String> tvLocIds {get;set;}
    public List<SelectOption> yesNoList {get;set;}
    private String publicTvRecordId {get;set;}
    private String privateTvRecordId {get;set;}
    public Integer numRows {get;set;}
    public String locationId {get;set;}

	global DesktopSurveyExtension(ApexPages.StandardController stdController) {
		this.siteObject = (Site_Survey__c) stdController.getRecord();
		this.tvTypes= new List<TV_Type__c>();
		this.tvListGuest = new List<TV_Type__c>();
		this.id2TVType = new Map<String, List<TV_Type__c>>();
		this.id2TVLoc = new Map<String, TV_Location__c>();
		this.rackLoc = new Rack_Location__c();
		List<TV_Location__c> tvLocList = new List<TV_Location__c>();
		this.tvLocIds = new Set<String>();
		this.yesNoList = new List<SelectOption>{new SelectOption('Yes', 'Yes'), new SelectOption('No', 'No')};
		this.id2TypeMap = new Map<String, List<TV_Type__c>>();
    	this.id2TvLoc = new Map<String, TV_Location__c>();
    	this.numRows = 1;
    	this.locationId = '';
    	this.locationId2NumTVs = new Map<String, List<Integer>>(); 
		
		//get opportunity id if it is found in parameters
    	if(System.currentPageReference().getParameters().containsKey('oppId')){
    		this.oppId = System.currentPageReference().getParameters().get('oppId');
    	}
		
		//query for the record ids 
    	List<RecordType> recordIds = [Select SobjectType, Id, DeveloperName From RecordType WHERE SobjectType = 'TV_Type__c' OR SobjectType = 'BB_IDF__c' OR SobjectType = 'Site_Survey__c'];
    	
    	//put the record ids in the appropriate places
    	for(RecordType recId : recordIds){
    		if(recId.DeveloperName == 'Guestroom_TV'){
    			this.privateTvRecordId = recId.Id;
    		} else if(recId.DeveloperName == 'Public_Area_TV'){
    			this.publicTvRecordId = recId.id;
    		} 
    	}
    	
		//get the id of the site survey if passed through parameters
    	if(System.currentPageReference().getParameters().containsKey('Id')) {
    		this.id= System.currentPageReference().getParameters().get('Id');
    		
    		//load all fields and lists
    		loadEverything();
    		
    		// add an empty tv type
    		//this.tvTypes.add(new TV_Type__c(Site_Survey__c = this.id));
    	} else {
    		this.siteObject = new Site_Survey__c(Opportunity__c = this.oppId);
    	}
    	System.debug('siteObject is ' + this.siteObject);
	}
	
	/***********************************************************************************************************
	***************************************** LOAD METHODS ****************************************************
	***********************************************************************************************************/
	
	//method that calls all load functions
    public void loadEverything() {
    	//load the site data
    	loadSiteData();
    	
    	//load the tv types
    	loadTypeData();
    	
    	//load the tv location data
    	loadTVLocationData();
    	
    	//load the correct mappings of tv type and guest room tvs
    	loadMappingsForTVLoc2TVType();
    	
    	//load rack location
    	loadRackLocationData();
    }
    
    //load the Site survey record and all the fields
    public void loadSiteData() {
    	String fieldQuery = '';
    	
		//get all the fields that need to be queried
		fieldQuery = String.join ( getSObjectFields(Site_Survey__c.getSObjectType()), ',');
		System.debug('the query fields for site data are: ' + fieldQuery);
		
		System.debug('querying for record...');
		try{
			this.siteObject = Database.query('Select ' + fieldQuery + ' From Site_Survey__c WHERE Id =\'' + this.id + '\' limit 1');
			System.debug('The retrieved record of site object is ' + this.siteObject);
		} catch (DMLException e) {
			this.siteObject = new Site_Survey__c(Opportunity__c = this.oppId);
		}
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
			this.tvTypes = Database.query('Select ' + fieldQueryTVType + ', TV_Manufacturer__r.Name, TV_Model__r.Name From TV_Type__c WHERE Site_Survey__c =\'' + this.id + '\'');
			System.debug('The retrieved records are ' + this.tvTypes);
			if(tvTypes.size() == 0 ) {
				this.tvTypes.add(new TV_Type__c(Site_Survey__c = this.id));
			} 
		} catch (DMLException e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, e.getMessage()));
		}
		
		System.debug('TV Types are: ' + this.tvTypes);
    }
    
    //load the TV location list and tv type related to tv location list
    public void loadTVLocationData() {
    	//intialize variables
    	this.id2TvLoc = new Map<String, TV_Location__c>();
    	this.id2TypeMap = new Map<String, List<TV_Type__c>>();
    	this.locationId2NumTVs = new Map<String, List<Integer>>();
    	List<TV_Location__c> tvLocList = new List<TV_Location__c>();
    	String fieldQuery = '';
    	
    	fieldQuery = String.join(getSObjectFields(TV_Location__c.getSObjectType()), ',');
    	System.debug('The fields that are being queried for TV_Location__c are ' + fieldQuery);
    	
    	System.debug('querying for record...');
		try{
			tvLocList = Database.query('Select ' + fieldQuery + ' From TV_Location__c WHERE Site_Survey__c =\'' + this.id + '\'');
			System.debug('The retrieved records are ' + tvLocList);
		} catch (DMLException e) {
			tvLocList = new List<TV_Location__c>{new TV_Location__c(Site_Survey__c = this.Id)};
		}
		
		if(tvLocList.size() > 0) {
			for(TV_Location__c tvLoc : tvLocList){
				this.id2TvLoc.put(tvLoc.id, tvLoc);
				this.id2TypeMap.put(tvLoc.id, new List<TV_Type__c>());
				this.locationId2NumTVs.put(tvLoc.id, new List<Integer>());
			}
		} else{
    		this.id2TvLoc.put('Fake_ID', new TV_Location__c(Site_Survey__c = this.id));
    		this.id2TypeMap.put('Fake_ID', new List<TV_Type__c>());
    		locationId2NumTVs.put('Fake_ID', new List<Integer>());
    	}
    	System.debug('TV Location map is ' + this.id2TvLoc);
    }
    
    public void loadMappingsForTVLoc2TVType(){
    	System.debug('Entering LoadMappingForTVLOc2TVType...');
		this.tvListGuest = new List<TV_Type__c>(); // reset the tv type guest list
    	//loop through the tv types and put them into the appropriate locations
    	for(TV_Type__c tv : this.tvTypes) {
    		if(tv.Public_Viewing_Location__c != null && tv.RecordTypeId == this.publicTvRecordId ){
	    		
	    		if(this.id2TvLoc.containsKey(tv.Public_Viewing_Location__c)){
		    		//add the tv types to the appropriate location
		    		this.id2TypeMap.get(tv.Public_Viewing_Location__c).add(tv);
		    		//map the tv location id to the number of tv types that are attached to it
		    		this.locationId2NumTVs.get(tv.Public_Viewing_Location__c).add( this.locationId2NumTVs.get(tv.Public_Viewing_Location__c).size());
	    		} 
    		}
    		//add tv type to list if it considered a guest room tv
    		 else {
    			this.tvListGuest.add(tv);
    		}
    	}
    	SYstem.debug('Tv location key set ' + this.id2TvLoc.KeySet());
    	SYstem.debug('locId2NumTvs is ' + this.locationId2NumTVs);
    	System.debug('TV Location Id mapped to tv type: ' + this.id2TypeMap);
    	
    	//add one item to tvList Guest if empty
    	if(this.tvListGuest.size() == 0) {
    		this.tvListGuest.add(new TV_Type__c(Site_Survey__c = this.id));
    	}
    }
    
    //load the rack location
    public void loadRackLocationData() {
    	String fieldQuery = '';
    	
		//get all the fields that need to be queried
		fieldQuery = String.join ( getSObjectFields(Rack_Location__c.getSObjectType()), ',');
		System.debug('the query fields for Rack_Location__c data are: ' + fieldQuery);
		
		System.debug('querying for record...');
		try{
			List<Rack_Location__c> tempRacks = new List<Rack_Location__c>();
			tempRacks = Database.query('Select ' + fieldQuery + ' From Rack_Location__c WHERE Site_Survey__c =\'' + this.id + '\' ');
			if (tempRacks.size()>0) {
				this.rackLoc = tempRacks[0]; 
			} else {
				 this.rackLoc = new Rack_Location__c(Site_Survey__c = this.id);
			}
			System.debug('The retrieved record of site object is ' + this.rackLoc);
		} catch (DMLException e) {
			this.rackLoc = new Rack_Location__c(Site_Survey__c = this.Id);
		}
    }
    
     /***********************************************************************************************************
	***************************************** SAVE METHODS ****************************************************
	***********************************************************************************************************/
	
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
	    		if(obj.get('Id') == null ){
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
    public Boolean saveObject(List<Sobject> objectList, List<String> fieldCheckList, Map<String, String> fieldApi2Label, Boolean allRecords, Boolean checkIfFilled, List<String> theExceptionList){
    	//debug
    	System.debug('Entering saveObject method with ' + objectList.size() + ' ' + objectList.getSObjectType() + ' records.');
    	System.debug('The fields to check are: ' + fieldCheckList);
    	System.debug('Check all records: ' + allRecords);
    	System.debug('CheckIfFilled: ' + checkIfFilled + '. Exceptions are: ' + theExceptionList);
    	
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
	    					//if(pass) {ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Record(s) on ' + this.oldTab + ' tab is not saved because fields are missing'));}
	    					pass = false;
	    					Schema.DescribeSObjectResult r = obj.getSObjectType().getDescribe();
    						ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Record(s) with this field ' + fieldApi2Label.get(fld) + ' blank on ' + r.getLabel() + ' will not get saved'));
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
	    				//ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Record(s) on ' + this.oldTab + ' tab is not saved because fields are missing'));
    					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'One field must be filled out in order for that individual record to be saved'));
    				}
    			}
    			
    			//true - save all objects;  false - save all objects except the last one
	    		if(pass){
	    			System.debug('Adding ' + obj + ' to the upsert list');
	    			upsertList.add(obj);
	    		}else {
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
    					Schema.DescribeSObjectResult r = obj.getSObjectType().getDescribe();
    					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Record(s) with this field ' + fieldApi2Label.get(fld) + ' blank on ' + r.getLabel() + ' will not get saved'));
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
		    					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'One field must be filled out in order for it to be saved'));
		    				}
    					}
    					if(notInException){
	    					pass = true;
    					}
    				}
    			}
    			if(!pass){
    				
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
    
    
    //save method and redirect to view of the site survey
    public PageReference saveInfo() {
    	System.debug('Entering SaveInfo...');
    	// save the site survey
    	saveData(new List<Site_Survey__c>{this.siteObject});
    	
    	//save the rack location
    	saveObject(new List<Rack_Location__c>{this.rackLoc}, getSObjectFields(Rack_Location__c.getSObjectType()), new Map<String, String>(), true, true, new List<String>{'Site_Survey__c'} );
    	
    	//save the tv types
    	saveObject(this.tvListGuest, getSobjectFields(TV_Type__c.getSObjectTYpe()), new Map<String, String>(), true, true, new List<String>{'Site_Suvrye__c', 'RecordTypeId'});
    	
    	//make a list of tv types in order to save them
		List<TV_Type__c> tvTempList = new List<TV_Type__c>();
		List<TV_Location__c> locTempList = new List<TV_Location__c>();
		for(String locId : this.id2TypeMap.keySet()){
			tvTempList.addAll(this.id2TypeMap.get(locId));
			locTempList.add(this.id2TvLoc.get(locId));
		}
		saveObject(locTempList, getSObjectFields(TV_Location__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c'});
		saveObject(tvTempList, getSObjectFields(TV_Type__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'RecordTypeId', 'Public_Viewing_Location__c', 'Site_Survey__c'});
		
    	PageReference ref = new PageReference('/' + this.id);
    	ref.setRedirect(true);
    	System.debug('Page reference Url is ' + ref);
		return ref;
    }
    
    
    /***********************************************************************************************************
	***************************************** ADD ROW METHODS ****************************************************
	***********************************************************************************************************/
    
    //upserts the prior records of the list
    //looks at the last item in list and see if brand and model is filled
    // if yes then upsert the new item and add a new TV type to list
    //upserts the prior records of the list
    //looks at the last item in list and see if brand and model is filled
    // if yes then upsert the new item and add a new TV type to list
    // if false then do not upsert the last record and leave list as is
    public void addRowTVInfo() {
    	//save the object
    	Boolean addNew = saveObject(this.tvListGuest, new List<String>{'TV_Manufacturer__c'}, new Map<String, String>{'TV_Manufacturer__c' =>'TV Manufacturer'}, false, false, new List<String>());
    	
    	//if successful, add a new record to the list
    	if(addNew){
    		for(Integer i = 0; i < this.numRows; i++){
	    		TV_Type__c tv = new TV_Type__c(Site_Survey__c = this.id, RecordTypeId = this.privateTvRecordId);
	    		this.tvTypes.add(tv);
	    		this.tvListGuest.add(tv);
    		}
    	}
    }
    
     // adding a row of tv type to tv location and saves the tv location and saves the prior tv rows
    //it only adds a tv type to location if certain fields are filled out
    public void addRowTVLoc() {
    	//initialize var
    	TV_Type__c tv;
    	Id locId;
		System.debug('Num Rows is ' + this.numRows);
    	System.debug('Location id is ' + this.locationId);
    	if(this.locationId != '' && (this.id2TvLoc.get(this.locationId).Name != '' && this.id2TvLoc.get(locationId).Name != null)){
    		// save the tv location
    		System.debug('TV LOcation looking at is ' + this.id2TvLoc.get(this.locationId));
    		System.debug('Created Date is ' + this.id2TvLoc.get(this.locationId).CreatedDate);
    		if(this.id2TvLoc.get(this.locationId).CreatedDate != null){
    			//update the location
    			System.debug('TV Location being updated is ' + this.id2TvLoc.get(this.locationId));
	    		locId = saveData(new List<TV_Location__c>{this.id2TvLoc.get(this.locationId)})[0];
	    		SYstem.debug('Location updated id is ' + locId);
	    		
	    		//if the upsert was successful
	    		if(locId != null) {
		    		//save tv types if the list is not empty
		    		if(!this.id2TypeMap.get(this.locationId).isEmpty()) {
		    			// this is already existed location with tv types already attached to it
		    			List<TV_Type__c> upsertTVList = this.id2TypeMap.get(this.locationId);
		    			if(upsertTVList.size() > 0){
							Boolean addNew = saveObject(upsertTVList, new List<String>{'TV_Manufacturer__c'}, new Map<String, String>{'TV_Manufacturer__c'=>'TV Manufacturer'}, false, false, new List<String>());
							
					    	if(addNew){
					    		this.loadTypeData(); // requery for the records
								this.loadTVLocationData(); // remap the tv location to the tv types
								this.loadMappingsForTVLoc2TVType(); // reload the mappings
					    		if(this.id2TypeMap.containsKey(this.locationId)){
						    		//add a new tv type to the location
						    		SYstem.debug('loctionId is' + this.locationId);
						    		SYstem.debug('id2TypeMap: ' + this.id2TypeMap);
				    				this.id2TypeMap.get(locId).add(new TV_Type__c(Site_Survey__c = this.id, Public_Viewing_Location__c = locId, RecordTypeId = this.publicTvRecordId));
				    				this.locationId2NumTVs.get(locId).add(this.locationId2NumTVs.get(locId).size());
				    			}
					    	} 
				    	}
					}else {
			    		System.debug('Just adding an emtpy tv type to ' + this.locationId);
			    		this.id2TypeMap.get(this.locationId).add(new TV_Type__c(Site_Survey__c = this.id, Public_Viewing_Location__c = this.locationId, RecordTypeId = this.publicTvRecordId));
			    		this.locationId2NumTVs.put(this.locationId, new List<Integer>{0});
			    	}
	    		}
    		} else {
				//insert the location 
				locId = saveData(new List<TV_Location__c>{this.id2TvLoc.get(this.locationId)})[0];
				List<TV_Location__c> tvLocTemp = Database.query('SELECT ' + String.join(getSObjectFields(TV_Location__c.getSobjectType()), ',') + ' FROM TV_Location__c WHERE ID = \'' + locId + '\' limit 1');
				
				//remove the prior mapping
				this.id2TvLoc.remove(this.locationId);
				this.id2TypeMap.remove(this.locationId);
				this.locationId2NumTVs.remove(this.locationId);
					
				//if the location is inserted then map it appropriately
				if(locId!= null){
					this.locationId2NumTVs.put(locId, new List<Integer>{0});
					this.id2TVLoc.put(locId, tvLocTemp[0]);
					this.id2TypeMap.put(locId, new List<TV_Type__c>{new TV_Type__c(Site_Survey__c = this.id, Public_Viewing_Location__c = locId, RecordTypeId = this.publicTvRecordId)});
				}
			}
    		
    	} else {
    		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Need to add the name of the location'));
    	}

    }

    //add a new location 
    /*and save prior locations and tv types associated to those row locations disable for right now; added if cliet demands it*/
    public void addRowLocation() {
    	SYstem.debug('Entering add Row Location...');
    	//initialize var
    	TV_Location__c tvLoc = new TV_Location__c(Site_Survey__c = this.id);
    	System.debug('id2typeMap contain Fake_ID?' + this.id2TypeMap.containsKey('Fake_ID'));
    	if(!this.id2TypeMap.containsKey('Fake_ID')){
    		tvLoc.Name = '';
    		this.id2TypeMap.put('Fake_ID', new List<TV_Type__c>());
    		this.id2TVLoc.put('Fake_ID', tvLoc);
    		this.locationId2NumTVs.put('Fake_ID', new List<Integer>());
    	} else if(this.id2TVLoc.get('Fake_ID').Name != '' && this.id2TVLoc.get('Fake_ID').Name != null) {
    		//insert the location 
			String locId = saveData(new List<TV_Location__c>{this.id2TvLoc.get('Fake_ID')})[0];
			List<TV_Location__c> tvLocTemp = Database.query('SELECT ' + String.join(getSObjectFields(TV_Location__c.getSobjectType()), ',') + ' FROM TV_Location__c WHERE ID = \'' + locId + '\' limit 1');
				
			//if the location is inserted then map it appropriately
			if(locId!= null){
				//remove the prior mapping
				this.id2TvLoc.remove('Fake_ID');
				this.id2TypeMap.remove('Fake_ID');
				this.locationId2NumTVs.remove('Fake_ID');
			
				this.locationId2NumTVs.put(locId, new List<Integer>());
				this.id2TVLoc.put(locId, tvLocTemp[0]);
				this.id2TypeMap.put(locId, new List<TV_Type__c>());
				
				//add a new empty tv location
				tvLoc.Name = '';
	    		this.id2TypeMap.put('Fake_ID', new List<TV_Type__c>());
	    		this.id2TVLoc.put('Fake_ID', tvLoc);
	    		this.locationId2NumTVs.put('Fake_ID', new List<Integer>());
			}
    	}else {
    		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Enter new TV Location data first before trying to add a new row'));
    	}
    	
    	System.debug('Exiting add Row Location...');
    }
    
    /***********************************************************************************************************
	***************************************** HELPER FUNCTIONS ****************************************************
	***********************************************************************************************************/
    
      /* Returns all fields in an SObject */ 
	  public static List<String> getSObjectFields(Schema.SObjectType objectType) {
	    
	    // Check for object type 
	    if (objectType == null) { return null; }
	    
	    // Get field map
	    Map<String, SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
	      
	   
	    List<String> fieldList = new List<String>();
	    for (String f : fieldMap.keySet()) {
	    	if(f != 'geolocation__c'){
		        //DescribeFieldResult field = fieldMap.get(f).getDescribe();
		     	fieldList.add(f);
	    	}
	    }
	    
	    //return the list of fields
	    return fieldList;
  }
}