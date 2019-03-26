// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 06/10/2013
// Description:  Class for housing custom logic for the Opportunity object
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************


global with sharing class SiteSurveyExtension {
    public Site_Survey__c siteObject {get;set;} // the site survey object
    public String tab {get;set;} //new tab that was selected
    public String oldTab {get;set;} // old tab that was selected
    public List<TV_Type__c> tvTypes {get;set;} // list of the tv types attached to site survey
    private String id{get;set;} //the id of the site survey object
    public String locationId {get;set;} //stores the current location id in order to add a tv type to that location
    public Map<String, List<TV_Type__c>> id2TypeMap {get;set;} //maps the tv location to the list of related tv types
    public Map<String, TV_Location__c> id2TvLoc {get;set;} //maps the id of tv location to the tv location object
    public Map<String, List<Integer>> locationId2NumTVs {get;set;}
    public String recordName {get;set;} // stores the record name of the site survey
    public Map<String, Building__c> buildingMap {get;set;} // list of all the building records attached to site survey
    public List<Digital_Off_Air__c> digitalList {get;set;} //list of all the digital off air records attached to the site survey
    public List<TV_Type__c> tvListGuest {get;set;}
    public List<Contact> contactList {get;set;}
    public String productCategory {get;set;}
    public List<OpportunityLineItem> oppProds {get;set;}
    public List<OpportunityLineItem> oppAttachProds {get;set;}
    public List<Rack_Location__c> rackLocList {get;set;}
    public integer numRows {get;set;} // number of rows to add to the list
    public List<integer> numberList {get;set;}
    private String publicTvRecordId {get;set;}
    private String privateTvRecordId {get;set;}
    public List<SelectOption> yesNoList {get;set;}
    public Map<String, FTG_Lineup__c> int2FTGMap {get;set;}
    public List<String> firstColNum {get;set;}
    public List<String> secondColNum {get;set;}
    public List<String> thirdColNum {get;set;}
    public Map<String, List<String>> id2mediaList {get;set;}
    public List<BB_IDF__c> bbIDFList {get;set;}
    public List<BB_IDF__c> bbMDFList {get;set;}
    private String mdfRecordId {get;set;}
    private String idfRecordId {get;set;}
    public List<Cable_Type__c> cableTypeList {get;set;}
    public List<Passive_Device__c> passiveDeviceList{get;set;}
    public Map<String, Media_IDF__c> id2MediaIdfMap {get;set;}
    public Integer headerBuilding {get;set;}
    public Integer headerIDF {get;set;}
    public Integer headerCable {get;set;}
    public Integer headerPassive {get;set;}
    public Integer headerBBIDF {get;set;}
    public Integer headerBBMDF {get;set;}
    public Integer headerDigital {get;set;}
    public Integer headerContact {get;set;}
    public Integer headerPrivateTv {get;set;}
    public Integer headerLocation {get;set;}
    public Integer headerPublicTv {get;set;}
    public Integer headerRack {get;set;}
    public String otherForms {get;set;}
    private boolean partnerPortal {get;set;}
    private Boolean isLocked {get;set;}
    
    global SiteSurveyExtension(ApexPages.StandardController stdController) {
    	this.siteObject = (Site_Survey__c) stdController.getRecord();
    	this.tvTypes = new List<TV_Type__c>();
    	this.tab = 'Cover Sheet';
    	this.id2TypeMap = new Map<String, List<TV_Type__c>>();
    	this.id2TvLoc = new Map<String, TV_Location__c>();
    	this.recordName = '';
    	this.locationId = '';
    	this.buildingMap = new Map<String, Building__c>();
    	this.oldTab = 'Cover Sheet';
    	this.digitalList = new List<Digital_Off_Air__c>();
    	this.tvListGuest = new List<TV_Type__c>();
    	this.contactList = new List<Contact>();   	
    	this.locationId2NumTVs = new Map<String, List<Integer>>();
    	this.productCategory = 'Capital';
    	this.oppProds = new List<OpportunityLineItem>();
    	this.oppAttachProds = new List<OpportunityLineItem>();
    	this.rackLocList = new List<Rack_Location__c>();
    	this.numRows = 1;
    	this.numberList = new List<Integer>();
    	this.publicTvRecordId = '';
    	this.privateTvRecordId = '';
    	this.yesNoList = new List<SelectOption>{new SelectOption('Yes', 'Yes'), new SelectOption('No', 'No')};
    	this.int2FTGMap = new Map<String, FTG_Lineup__c>();
    	this.firstColNum = new List<String>();
    	this.secondColNum = new List<String>();
    	this.thirdColNum = new List<String>();
    	this.id2mediaList = new Map<String, List<String>>();
    	this.bbIDFList = new List<BB_IDF__c>();
    	this.bbMDFList = new List<BB_IDF__c>();
    	this.cableTypeList = new List<Cable_Type__c>();
    	this.passiveDeviceList = new List<Passive_Device__c>();
    	this.id2MediaIDFMap = new Map<String, Media_IDF__c>();
    	this.headerBuilding = 0;
	    this.headerIDF = 0;
	    this.headerCable = 0;
	    this.headerPassive = 0;
	    this.headerBBIDF = 0;
	    this.headerBBMDF = 0;
	    this.headerDigital = 0;
	    this.headerContact = 0;
	    this.headerPrivateTv = 0;
	    this.headerLocation = 0;
	    this.headerPublicTv = 0;
	    this.headerRack = 0;
	    this.otherForms = '';
	    this.partnerPortal = false;
	    this.isLocked = false;
    	
    	//debug to see all parameters
    	System.debug('Parameters: ' + System.currentPageReference().getParameters());
    	
    	//set tab if found in parameters
    	if(System.currentPageReference().getParameters().containsKey('tab')){
    		this.tab = System.currentPageReference().getParameters().get('tab');
    		this.oldTab = this.tab;
    	}
    	
    	//query for the record ids 
    	List<RecordType> recordIds = [Select SobjectType, Id, DeveloperName From RecordType WHERE SobjectType = 'TV_Type__c' OR SobjectType = 'BB_IDF__c' OR SobjectType = 'Site_Survey__c'];
    	
    	String tempSiteSurveyId ='';
    	String tempDesktopSurveyId = '';
    	//put the record ids in the appropriate places
    	for(RecordType recId : recordIds){
    		if(recId.DeveloperName == 'Guestroom_TV'){
    			this.privateTvRecordId = recId.Id;
    		} else if(recId.DeveloperName == 'Public_Area_TV'){
    			this.publicTvRecordId = recId.id;
    		} else if(recId.DeveloperName == 'IDF'){
    			this.idfRecordId = recId.Id;
    		}else if(recId.DeveloperName == 'MDF'){
    			this.mdfRecordId = recId.Id;
    		}else if(recId.DeveloperName == 'Site_Survey'){
    			tempSiteSurveyId = recId.Id;
    		}else if(recId.DeveloperName == 'Desktop_Review'){
    			tempDesktopSurveyId = recId.Id;
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
    		//load all fields and lists
    		loadEverything();
    		
    		//get the record Name for the site survey
	    	if(this.siteObject.RecordTypeId == tempSiteSurveyId){
	    		this.recordName = 'Site Survey';
	    	} else {
	    		this.recordName = 'Desktop Review';
	    	}
    	}  else if (System.currentPageReference().getParameters().containsKey('oppId')){
    		this.siteObject = new Site_Survey__c(Opportunity__c = System.currentPageReference().getParameters().get('oppId'));
    	} else {
    		this.siteObject = new Site_Survey__c();
    	}
    	System.debug('siteObject is ' + this.siteObject);
    	
    	//set the is locked attribute
    	if(this.siteObject.Approval_Status__c == 'Approved' || this.siteObject.Approval_Status__c == 'Pending'){
    		this.isLocked = true;
    	}
    }        
    
    /***********************************************************************************
    ***************************** ADD ROW METHODS ***************************************
    *************************************************************************************/
    
    //add rows for site survey full tab equals all
    public void addRowHeaders() {
    	//add contacts
    	this.numRows = this.headerContact;
    	this.addRowContact();
    	this.headerContact = 0;
    	
    	//add buildings
    	this.numRows = this.headerBuilding;
    	this.addRowBuilding();
    	this.headerBuilding = 0;
    	
    	//add idfs
    	this.numRows = this.headerIDF;
    	for(String buildId : this.id2MediaList.KeySet()){
    		this.locationId = buildId;
    		this.addRowIDF();
    	}
    	this.headerIDF = 0;
    	
    	//add cable types
    	this.numRows = this.headerCable;
    	this.addRowCableType();
    	this.headerCable= 0;
    	
    	//add passive device
    	this.numRows = this.headerPassive;
    	this.addRowPassiveDevice();
    	this.headerPassive = 0;
    	
    	//add BB MDF
    	this.numRows = this.headerBBMDF;
    	this.addBBMDF();
    	this.headerBBMDF = 0;
    	
    	//add BB IDF
    	this.numRows = this.headerBBIDF;
    	this.addBBIDF();
    	this.headerBBIDF = 0;
    	
    	// add Private TVs
    	this.numRows = this.headerPrivateTv;
    	this.addRowTVInfo();
    	this.headerPrivateTv = 0;
    	
    	//add public locations
    	this.numRows = this.headerLocation;
    	this.addRowLocation();
    	this.headerLocation = 0;
    	
    	//add public TVs
    	this.numRows = this.headerPublicTv;
    	for(String publicId : this.id2TvLoc.KeySet()){
    		this.locationId = publicId;
    		this.addRowTVLoc();
    	}
    	this.headerPublicTv = 0;
    	
    	//add rack locations
    	this.numRows = this.headerRack;
    	this.addRowRackLoc();
    	this.headerRack = 0;
    	
    	//add Digital off airs
    	this.numRows = this.headerDigital;
    	this.addDigitalOffAir();
    	this.headerDigital = 0;
    }
    
    //upserts the prior records of the list
    //looks at the last item in list and see if brand and model is filled
    // if yes then upsert the new item and add a new TV type to list
    // if false then do not upsert the last record and leave list as is
    public void addRowTVInfo() {
    	if(this.tab != 'ALL'){
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
    	} else {
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
    	
    	if(this.tab != 'ALL'){
	    	
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
    	} else {
    		for(integer i = 0; i < this.numRows; i++) {
	    		this.id2TypeMap.get(this.locationId).add(new TV_Type__c(Site_Survey__c = this.id, RecordTypeId = this.publicTvRecordId));
				this.locationId2NumTVs.get(this.locationId).add(this.locationId2NumTVs.get(this.locationId).size());
    		}
    	}
    }

    //add a new location 
    /*and save prior locations and tv types associated to those row locations disable for right now; added if cliet demands it*/
    public void addRowLocation() {
    	SYstem.debug('Entering add Row Location...');
    	//initialize var
    	TV_Location__c tvLoc = new TV_Location__c(Site_Survey__c = this.id);
    	if(this.tab != 'ALL'){
	    	System.debug('id2typeMap contain Fake ID?' + this.id2TypeMap.containsKey('Fake ID'));
	    	if(!this.id2TypeMap.containsKey('Fake ID')){
	    		tvLoc.Name = '';
	    		this.id2TypeMap.put('Fake ID', new List<TV_Type__c>());
	    		this.id2TVLoc.put('Fake ID', tvLoc);
	    		this.locationId2NumTVs.put('Fake ID', new List<Integer>());
	    	} else if(this.id2TVLoc.get('Fake ID').Name != '' && this.id2TVLoc.get('Fake ID').Name != null){
	    		//insert the location 
				String locId = saveData(new List<TV_Location__c>{this.id2TvLoc.get('Fake ID')})[0];
				List<TV_Location__c> tvLocTemp = Database.query('SELECT ' + String.join(getSObjectFields(TV_Location__c.getSobjectType()), ',') + ' FROM TV_Location__c WHERE ID = \'' + locId + '\' limit 1');
				
				//remove the prior mapping
				this.id2TvLoc.remove('Fake ID');
				this.id2TypeMap.remove('Fake ID');
				this.locationId2NumTVs.remove('Fake ID');
					
				//if the location is inserted then map it appropriately
				if(locId!= null){
					this.locationId2NumTVs.put(locId, new List<Integer>());
					this.id2TVLoc.put(locId, tvLocTemp[0]);
					this.id2TypeMap.put(locId, new List<TV_Type__c>());
					
					//add a new empty tv location
					tvLoc.Name = '';
		    		this.id2TypeMap.put('Fake_ID', new List<TV_Type__c>());
		    		this.id2TVLoc.put('Fake_ID', tvLoc);
		    		this.locationId2NumTVs.put('Fake_ID', new List<Integer>());
				}
	    	} else{
	    		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Enter new TV Location data first before trying to add a new row'));
	    	}
    	} else {
    		for(integer i = 0; i < this.numRows; i++) {
	    		String fakeId = generateRandomString(15);
	    		this.id2TypeMap.put(fakeId, new List<TV_Type__c>());
		    	this.id2TVLoc.put(fakeId, tvLoc);
		    	this.locationId2NumTVs.put(fakeId, new List<Integer>());
    		}
    	}
    	
    	System.debug('Exiting add Row Location...');
    }
    	
   
    //add row to digital off air
    //save prior records
    public void addDigitalOffAir() {
    	if(this.tab != 'ALL'){
	    	//save the data
	    	saveObject(this.digitalList, getSObjectFields(Digital_Off_Air__c.getSObjectType()), new Map<String, String>(), true, true, new List<String>{'Site_Survey__c'});
    	
	    	for(Integer i = 0; i < this.numRows; i++){
		    	// add a row to the list of digitalOff air
		    	this.digitalList.add(new Digital_Off_Air__c(Site_Survey__c = this.id));
	    	}
    	} else {
    		for(Integer i = 0; i < this.numRows; i++){
		    	// add a row to the list of digitalOff air
		    	this.digitalList.add(new Digital_Off_Air__c(Site_Survey__c = this.id));
	    	}
    	}
    }
    
    //add a contact to the contact list
    public void addRowContact() {
    	if(this.tab != 'ALL'){
	    	//save the prior data
	    	Boolean saveSuccessful = saveObject(this.contactList, new List<String>{'LastName'}, new Map<String, String>{'LastName'=> 'Last Name'}, false, false, new List<String>());
	    	
	    	if(saveSuccessful){
	    		loadContactData();
		    	//add a row
		    	for(integer i = 0; i < Integer.valueOf(numRows); i++){
	    			if(this.siteObject.AccountID__c != null){
		    			this.contactList.add(new Contact(AccountId = this.siteObject.AccountID__c, FirstName ='', LastName =''));
		    		} else {
		    			this.contactList.add(new Contact(FirstName ='', LastName =''));
		    		}
		    	}
	    	}
    	} else {
    		for(integer i = 0; i < Integer.valueOf(numRows); i++){
    			//add a row
    			if(this.siteObject.AccountID__c != null){
	    			this.contactList.add(new Contact(AccountId = this.siteObject.AccountID__c, FirstName ='', LastName =''));
	    		} else {
	    			this.contactList.add(new Contact(FirstName ='', LastName =''));
	    		}
    		}
    	}
    }
    
    //add a row to rack location
    public void addRowRackLoc() {
    	if(this.tab != 'ALL') {
    		//save the prior data
    		Boolean saveSuccessful = saveObject(this.rackLocList, getSObjectFields(Rack_Location__c.getSObjectType()),new Map<String, String>(), false, true, new List<String>{'Site_Survey__c'});
    		
    		if(saveSuccessful){
	    		//add a row
	    		this.rackLocList.add(new Rack_Location__c(Site_Survey__c = this.id));
    		}
    	} else{
    		for(Integer i = 0; i < this.numRows; i++){
	    		//add a row
	    		this.rackLocList.add(new Rack_Location__c(Site_Survey__c = this.id));
    		}
    	}
    }
    
    //add a row to BB IDF
    public void addBBIDF() {
    	if(this.tab != 'ALL') {
    		//save the prior data
    		Boolean saveSuccessful = saveObject(this.bbIDFList, getSObjectFields(BB_IDF__c.getSObjectType()),new Map<String, String>(), false, true, new List<String>{'Site_Survey__c', 'RecordTypeId'});
    		
    		if(saveSuccessful){
	    		//add a row
	    		this.bbIDFList.add(new BB_IDF__c(Site_Survey__c = this.id, recordTypeId = this.idfRecordId));
    		}
    	} else{
    		for(Integer i = 0; i < this.numRows; i++){
	    		//add a row
	    		this.bbIDFList.add(new BB_IDF__c(Site_Survey__c = this.id, recordTypeId = this.idfRecordId));
    		}
    	}
    }
    
    //add a row to BB MDF
    public void addBBMDF() {
    	if(this.tab != 'ALL') {
    		//save the prior data
    		Boolean saveSuccessful = saveObject(this.bbMDFList, getSObjectFields(BB_IDF__c.getSObjectType()),new Map<String, String>(), false, true, new List<String>{'Site_Survey__c', 'RecordTypeId'});
    		
    		if(saveSuccessful){
	    		//add a row
	    		this.bbMDFList.add(new BB_IDF__c(Site_Survey__c = this.id, recordTypeId = this.mdfRecordId));
    		}
    	} else{
    		for(Integer i = 0; i < this.numRows; i++){
	    		//add a row
	    		this.bbMDFList.add(new BB_IDF__c(Site_Survey__c = this.id, recordTypeId = this.mdfRecordId));
    		}
    	}
    }
    
    //add a media idf
    public void addRowIDF() {
    	System.debug('Entering addRowIdf...');
    	System.debug('LocationId is ' + this.locationId);
    	
    	if(tab != 'ALL'){
    		if(this.locationId != '' && (this.buildingMap.get(this.locationId).Name != null && this.buildingMap.get(this.locationId).Name != '')){
    			//save the building
    			System.debug('Building being look at is ' + buildingMap.get(this.locationId));
    			if(this.buildingMap.get(this.locationId).Id != null){
    				//update the building
    				String locId = saveData(new List<Building__c>{this.buildingMap.get(locationId)})[0];
    				
    				//if save was successful
    				if(locId != null) {
    					// save the prior idfs if list is not empty
    					if(!this.id2MediaList.get(locId).isEmpty()){
    						// this is already exisiting building with idfs attached to it
    						List<Media_IDF__c> mediaList = new List<Media_IDF__c>();
    						for(String s : this.id2MediaList.get(locId)){
    							mediaList.add(this.id2MediaIDFMap.get(s));
    						}
    						
    						if(mediaList.size() > 0){
    							Boolean addNew = saveObject(mediaList, getSObjectFields(Media_IDF__c.getSObjectType()),new Map<String, String>(), false, true, new List<String>{'Building__c'});
    							
    							if(addNew){
    								this.loadBuildingData();
    								this.loadMediaIDFData();
    								
    								//add a new idf to building
    								this.id2MediaList.get(locId).add('Fake_ID');
		    						this.id2MediaIdfMap.put('Fake_ID', new Media_IDF__c(Building__c = this.locationId));
						    		//this.id2CableTypeMap.put('Fake_ID', new List<Cable_Type__c>());
					    			//this.id2PassiveDeviceMap.put('Fake_ID', new List<Passive_Device__c>());	
    							}
    						}
    					}else {
    						System.debug('No idfs attached to this builing. Adding one Media IDF to ' + locId);
    						this.id2MediaList.get(locId).add('Fake_ID');
    						this.id2MediaIdfMap.put('Fake_ID', new Media_IDF__c(Building__c = this.locationId));
    					}
    				}
    				
    			} else {
    				//remove the new building
    				Building__c tempBuild = this.buildingMap.remove(this.locationId);
    				
    				//save prior data
    				saveObject(this.buildingMap.Values(), new List<String>{'Name'},new Map<String, String>{'Name' => 'Name'}, true, false, new List<String>());
    				
    				//save the new building
    				String locId = saveData(new List<Building__c>{tempBuild})[0];
    				if(locId != null){
	    				//query for the new building
	    				List<Building__c> tempList = Database.query('SELECT ' + String.join(getSObjectFields(Building__c.getSobjectType()), ',') + ' FROM Building__c WHERE ID = \'' + locId + '\' limit 1');
	    				
	    				//remove the prior building mapping
	    				this.id2MediaList.remove(this.locationId);
	    				
	    				//enter in the new mappings
	    				this.id2MediaList.put(locId, new List<String>{'Fake_ID'});
	    				this.buildingMap.put(locId, tempList[0]);
	    				this.id2MediaIdfMap.put('Fake_ID', new Media_IDF__c(Building__c = locId));
    				}
    			}
    		} else {
	    		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Need to add the name for the building'));
	    	}
    		
    	} else {
    		for(Integer i = 0; i < this.numRows; i++){
	    		//add a row
	    		String tempId = generateRandomString(15);
	    		this.id2MediaList.get(locationId).add(tempId);
	    		this.id2MediaIdfMap.put(tempId, new Media_IDF__c());
    		}
    	}
    	
    	System.debug('Exiting addrowIdf');
    }
    
    //add a building
    public void addRowBuilding() {
    	System.debug('Entering add Row Building...');
    	
    	if(this.tab != 'ALL'){
	    	System.debug('buildingMap contain Fake ID?' + this.buildingMap.containsKey('Fake_ID'));
	    	if(!this.buildingMap.containsKey('Fake_ID')){
	    		//save the prior data
	    		Boolean saveSuccessful = saveObject(this.buildingMap.Values(), new List<String>{'Name'},new Map<String, String>{'Name'=>'Name'}, true, false, new List<String>());
    		
	    		if(saveSuccessful){
		    		//add a row
		    		this.buildingMap.put('Fake_ID', new Building__c(Site_Survey__c = this.id));
		    		this.id2MediaList.put('Fake_ID', new List<String>());
	    		}
	    	} else if (this.buildingMap.get('Fake_ID').Name != '' && this.buildingMap.get('Fake_ID').Name != null){
	    		System.debug('Name is ' + this.buildingMap.get('Fake_ID').Name);
	    		//remove the building record first so it can be saved by itself
	    		Building__c temp = this.buildingMap.remove('Fake_ID');
	    		String locId = saveData(new List<Building__c>{temp})[0];
		    	SYstem.debug('Building inserted id is ' + locId);
	    		
	    		//save the prior data
	    		Boolean saveSuccessful = saveObject(this.buildingMap.Values(), new List<String>{'Name'},new Map<String, String>{'Name'=>'Name'}, true, false, new List<String>());
    		
	    		if(saveSuccessful){
	    			this.loadBuildingData();
	    			this.loadMediaIDFData();
		    		//add a row
		    		this.buildingMap.put('Fake_ID', new Building__c(Site_Survey__c = this.id));
		    		this.id2MediaList.put('Fake_ID', new List<String>());
		    		
	    		}
	    	}else{
	    		// insert error message
	    		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Enter new Building data first before trying to add a new building'));
	    	}
    	} else {
    		for(integer i = 0; i < this.numRows; i++) {
	    		String fakeId = generateRandomString(15);
	    		this.buildingMap.put(fakeId, new Building__c(Site_Survey__c = this.id));
	    		this.id2MediaList.put(fakeId, new List<String>());
    		}
    	}
    	
    	System.debug('Exiting add Row Building...');
    }
    
    //add a row to passive device
    public void addRowPassiveDevice() {
    	System.debug('Entering addRowPassiveDevice...');
    	
    	if(this.tab != 'ALL'){
			Boolean successful = saveObject(this.passiveDeviceList, new List<String>{'Device__c'},new Map<String, String>{'Device__c'=>'Device'}, false, false, new List<String>());
			
			if(successful){
				//add a row
				this.passiveDeviceList.add( new Passive_Device__c(Site_Survey__c = this.Id));
			}
    	} else {
    		for(Integer i = 0; i < this.numRows; i++) {
    			//add a row
    			this.passiveDeviceList.add( new Passive_Device__c(Site_Survey__c = this.Id));
    		}
    	}
    	
    	System.debug('Exiting addRowPassiveDevice...');
    }
    
    //add row to cable type
    public void addRowCableType(){
    	System.debug('Entering addRowCableType...');
    	System.debug('LocationId is ' + this.locationId);
    	
    	if(this.tab != 'ALL'){
    		Boolean successful = saveObject(cableTypeList, new List<String>{'Make__c'},new Map<String, String>{'Make__c'=>'Make'}, false, false, new List<String>());
	    			
			if(successful){
				//add a row
				this.cableTypeList.add( new Cable_Type__c(Site_Survey__c = this.Id));
			}
    	} else {
    		for(Integer i = 0; i < this.numRows; i++) {
    			//add a row
    			this.cableTypeList.add( new Cable_Type__c(Site_Survey__c = this.Id));
    		}
    	}
    	
    	System.debug('Exiting addRowCableType');
    }
    
    /***********************************************************************************
    ***************************** SAVE METHODS *******************************************
    *************************************************************************************/
    
    //save method and redirect to view of the site survey
    public PageReference saveInfo() {
    	quickSave();
    	PageReference ref = new PageReference('/' + this.id);
    	ref.setRedirect(true);
    	System.debug('PAge reference Url is ' + ref);
		return ref;
    }
    
    //save everything on the current tab
    public void quickSave() {
    	System.debug('Entering quick save...');
    	System.debug('Tab is ' + this.tab);
    	System.debug('Old tab is ' + this.oldTab);
    	if(this.tab == 'ALL' || this.isLocked){}
    	else if(this.tab == 'Property Info' || this.tab == 'Comments' || this.tab == 'Property SignOff' || this.tab =='Cover Sheet' || this.tab == 'BB Connectivity' || this.tab == 'Satellite Info' || this.oldTab == 'Satellite Info'){
    		saveData(new List<Sobject>{this.siteObject});
    	}else if(this.tab == 'Contacts'){
    		saveObject(this.contactList, new List<String>{'LastName'},new Map<String, String>{'LastName'=>'Last Name'}, true, false, new List<String>());
    	}
    	else if(this.tab == 'Media Building Info'){
    		saveObject(this.buildingMap.Values(), new List<String>{'Name'},new Map<String, String>{'Name'=>'Name'}, true, false, new List<String>());
    		
    		saveObject(this.id2MediaIdfMap.Values(), getSObjectFields(Media_IDF__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Building__c'});
    		
    		saveObject(this.passiveDeviceList, new List<String>{'Device__c'},new Map<String, String>{'Device__c'=>'Device'}, true, false, new List<String>());

			saveObject(this.cableTypeList, new List<String>{'Make__c'},new Map<String, String>{'Make__c'=>'Make'}, true, false, new List<String>());
    		
    	}else if(this.tab == 'BB MDF'){
    		saveObject(this.bbMDFList, getSObjectFields(BB_IDF__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c', 'RecordTypeId'});
    	}else if(this.tab == 'BB IDF'){
    		saveObject(this.bbIDFList, getSObjectFields(BB_IDF__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c', 'RecordTypeId'});
    	}else if(this.tab == 'TV Info'){
    		// save info on the site survey record
    		saveData(new List<Sobject>{this.siteObject});
    		
    		//save all tv types and go through each record
    		saveObject(this.tvListGuest, new List<String>{'TV_Manufacturer__c'},new Map<String, String>{'TV_Manufacturer__c'=>'TV Manufacturer'}, true, false, new List<String>());
    	}else if(this.tab == 'Public TVs'){
    		//make a list of tv types in order to save them
    		List<TV_Type__c> tvTempList = new List<TV_Type__c>();
    		List<TV_Location__c> locTempList = new List<TV_Location__c>();
    		for(String locId : this.id2TypeMap.keySet()){
    			tvTempList.addAll(this.id2TypeMap.get(locId));
    			locTempList.add(this.id2TvLoc.get(locId));
    		}
    		saveObject(locTempList, new List<String>{'Name'},new Map<String, String>{'Name'=>'Name'}, true, false, new List<String>());
    		saveObject(tvTempList, new List<String>{'TV_Manufacturer__c'},new Map<String, String>{'TV_Manufacturer__c'=>'TV Manufacturer'}, true, false, new List<String>());
    	}else if(this.tab == 'Rack Location'){
    		//save the data
    		saveObject(this.rackLocList, getSObjectFields(Rack_Location__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c'});
    	}else if(this.tab == 'FTG-GP Lineups'){
    		saveObject(this.int2FTGMap.Values(), getSObjectFields(FTG_Lineup__c.getSobjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c', 'Channel__c'});
    		saveData(new List<Sobject>{this.siteObject});
    	}else if(this.tab == 'Digital Off-Air'){
    		saveObject(this.digitalList, getSObjectFields(Digital_Off_Air__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c'});
    		saveObject(new List<Site_Survey__c>{this.siteObject}, new List<String>(),new Map<String, String>(), true, false, new List<String>());
    	}
    	
    	System.debug('Exiting quick save ...');
    }
    
   	// save data when someone switches tabs
   	public void quickSaveSwitch(){
   		System.debug('Entering quick save switch...');
    	System.debug('Tab is ' + this.tab);
    	System.debug('Old tab is ' + this.oldTab);
    	if(this.oldTab == 'ALL' || this.isLocked){}
    	else if(this.oldTab == 'Property Info' || this.oldTab == 'Comments' || this.oldTab == 'Property SignOff' || this.oldTab == 'Cover Sheet' || this.oldTab == 'BB Connectivity'){
    		saveData(new List<Site_Survey__c>{this.siteObject});
    	
    	}else if(this.oldTab == 'Contacts'){
    		saveObject(this.contactList, new List<String>{'LastName'},new Map<String, String>{'LastName'=>'Last Name'}, true, false, new List<String>());
    		
    	}else if(this.oldTab == 'Media Building Info'){
    		saveObject(this.buildingMap.Values(), new List<String>{'Name'},new Map<String, String>{'Name'=>'Name'}, true, false, new List<String>());
    		
    		saveObject(this.id2MediaIdfMap.Values(), getSObjectFields(Media_IDF__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Building__c'});
    		
    		saveObject(this.passiveDeviceList, new List<String>{'Device__c'},new Map<String, String>{'Device__c'=>'Device'}, true, false, new List<String>());

			saveObject(this.cableTypeList, new List<String>{'Make__c'},new Map<String, String>{'Make__c'=>'Make'}, true, false, new List<String>());

    	}else if(this.oldTab == 'BB MDF'){
    		saveObject(this.bbMDFList, getSObjectFields(BB_IDF__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c', 'RecordTypeId'});
    		
    	}else if(this.oldTab == 'BB IDF'){
    		saveObject(this.bbIDFList, getSObjectFields(BB_IDF__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c', 'RecordTypeId'});
    		
    	}else if(this.oldTab == 'TV Info'){
    		// save info on the site survey record
    		saveData(new List<Sobject>{this.siteObject});
    		
    		//save all tv types and go through each record
    		saveObject(this.tvListGuest, new List<String>{'TV_Manufacturer__c'},new Map<String, String>{'TV_Manufacturer__c'=>'TV Manufacturer'}, true, false, new List<String>());
    	
    	}else if(this.oldTab == 'Public TVs'){
    		//make a list of tv types in order to save them
    		List<TV_Type__c> tvTempList = new List<TV_Type__c>();
    		List<TV_Location__c> locTempList = new List<TV_Location__c>();
    		for(String locId : this.id2TypeMap.keySet()){
    			tvTempList.addAll(this.id2TypeMap.get(locId));
    			locTempList.add(this.id2TvLoc.get(locId));
    		}
    		saveObject(locTempList, new List<String>{'Name'},new Map<String, String>{'Name'=>'Name'}, true, false, new List<String>());
    		saveObject(tvTempList, new List<String>{'TV_Manufacturer__c'},new Map<String, String>{'TV_Manufacturer__c'=>'TV Manufacturer'}, true, false, new List<String>());
    		
    	}else if(this.oldTab == 'Rack Location'){
    		//save the data
    		saveObject(this.rackLocList, getSObjectFields(Rack_Location__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c'});
    		
    	}else if(this.oldTab == 'FTG-GP Lineups'){
    		saveObject(this.int2FTGMap.Values(), getSObjectFields(FTG_Lineup__c.getSobjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c', 'Channel__c'});
    		saveData(new List<Sobject>{this.siteObject});
    		
    	}else if(this.oldTab == 'Digital Off-Air'){
    		saveObject(this.digitalList, getSObjectFields(Digital_Off_Air__c.getSObjectType()),new Map<String, String>(), true, true, new List<String>{'Site_Survey__c'});
    		saveData(new List<Sobject>{this.siteObject});
    		
    	}
    	this.oldTab = this.tab;
    	System.debug('Exiting quick save switch...');
   	}
   	
   	// upsert the data
   	public List<Id> saveData(List<SObject> objects) {
    	System.debug('Entering saveData method with ' + objects.size() + ' ' + objects[0].getSObjectType() + ' records.');
    	
    	//if the survey is locked then do not save
    	if(this.isLocked)
    		return null;
    	
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
	    					if(pass) {ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Record(s) on ' + this.oldTab + ' tab is not saved because fields are missing'));}
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
	    				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Record(s) on ' + this.oldTab + ' tab is not saved because fields are missing'));
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
		    					if(pass) {ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Record(s) on ' + this.oldTab + ' tab is not saved because fields are missing'));}
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
    
    /***********************************************************************************
    ***************************** LOAD DATA METHODS **************************************
    *************************************************************************************/
    
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
    	
    	//load building data
    	loadBuildingData();
    	
    	//load media idf
    	loadMediaIDFData();
    	
    	//load digital off air
    	loadDigitalOffAirData();
    	
    	//load contact data
    	loadContactData();
    	
		//load ftg lineup
		loadFTGLineupData();
		
		//load the bb idf
		loadBBIDFData();
    	
    }
    
    //load the Site survey record and all the fields
    public void loadSiteData() {
    	String fieldQuerySite = '';
    	String fieldQueryCableType;
    	String fieldQueryPassiveDevice;
    	String fieldQueryRack;
    	
		fieldQuerySite = String.join(getSObjectFields(Site_Survey__c.getSObjectType()), ',');
		fieldQueryCableType = String.join(getSObjectFields(Cable_Type__c.getSObjectType()), ',');
		fieldQueryPassiveDevice = String.join(getSObjectFields(Passive_Device__c.getSObjectType()) , ',');
		fieldQueryRack = String.join(getSObjectFields(Rack_Location__c.getSObjectType()), ',');
    	System.debug('The fields that are being queried for Site Survey are ' + fieldQuerySite);
    	
    	//add additional fields to query
    	fieldQuerySite += ', Site__r.Phone, Site__r.Fax';
		
		System.debug('querying for record...');
		try{
			this.siteObject = Database.query('Select ' + fieldQuerySite + ', (SELECT Id, Name, LastModifiedDate FROM Attachments),  (SELECT ' + fieldQueryRack + ' FROM Rack_Locations__r), (SELECT ' + fieldQueryPassiveDevice + ' FROM Passive_Devices__r), (SELECT ' + fieldQueryCableType + ' FROM Cable_Types__r) From Site_Survey__c WHERE Id =\'' + this.id + '\' limit 1');
			System.debug('The retrieved record is ' + this.siteObject);
		} catch (Exception e){
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, e.getMessage()));
		}
		//add the cable types to list
		for(Cable_Type__c cable : this.siteObject.Cable_Types__r){
			this.cableTypeList.add(cable);
		}
		//add passive device to list
		for(Passive_Device__c passive : this.siteObject.Passive_Devices__r){
			this.passiveDeviceList.add(passive);
		}
		//add rack location to list
		for(Rack_Location__c rack : this.siteObject.Rack_Locations__r){
			this.rackLocList.add(rack);
		}
		
		//load the attachments
		Datetime latestDate;
		for(Attachment att : this.siteObject.Attachments){
			if(att.Name.containsIgnoreCase('Site Survey Forms')){
				if(latestDate == null){
					this.otherForms = Definitions.DOWNLOAD_ATTACHMENT +'?file=' + att.id;
					latestDate = att.LastModifiedDate;
				} else if(latestDate < att.LastModifiedDate){
					this.otherForms = Definitions.DOWNLOAD_ATTACHMENT + att.id;
					latestDate = att.LastModifiedDate;
				}
			}
		}
		
		if(this.siteObject == null) {
			this.siteObject = new Site_Survey__c();
		}
		
		if(this.cableTypeList.size() == 0 ) {
    		this.cableTypeList.add(new Cable_Type__c(Site_Survey__c = this.id));
    	}
    	
    	if(this.passiveDeviceList.size() == 0 ) {
    		this.passiveDeviceList.add(new Passive_Device__c(Site_Survey__c = this.id));
    	}
    	
    	if(this.rackLocList.size() == 0 ) {
    		this.rackLocList.add(new Rack_Location__c(Site_Survey__c = this.id));
    	}
    	
    	if(this.otherForms == ''){
    		List<Site_Survey_Forms__c> formId = Site_Survey_Forms__c.getAll().values();
    		if(formId.size() > 0){
    			this.otherForms = Definitions.DOWNLOAD_ATTACHMENT + 'Site_Survey_Forms.xls?file='+ formId[0].Name;
    		}
    	}
    	if(this.partnerPortal){
    		this.otherForms = '/sonifipartners' + this.otherForms;    		
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
    		this.id2TvLoc.put('Fake ID', new TV_Location__c(Site_Survey__c = this.id));
    		this.id2TypeMap.put('Fake ID', new List<TV_Type__c>());
    		locationId2NumTVs.put('Fake ID', new List<Integer>());
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
    	
    	System.debug('TV Location Id mapped to tv type: ' + this.id2TypeMap);
    	
    	//add one item to tvList Guest if empty
    	if(this.tvListGuest.size() == 0) {
    		this.tvListGuest.add(new TV_Type__c(Site_Survey__c = this.id));
    	}
    }
    
    //load the buildings related to site survey
    public void loadBuildingData() {
    	//initialize variable
    	Building__c build;
    	String fieldQuery= '';
    	List<Building__c> buildList = new List<Building__c>();
    	
    	//build query
    	fieldQuery = String.join( getSObjectFields(Building__c.getSObjectType()), ',');
    	
    	//query for the results
    	buildList = Database.query('SELECT ' + fieldQuery + ' FROM Building__c WHERE Site_Survey__c = \'' + this.id + '\'');
    	
    	//if the building list is empty then add one building to the list
    	if(buildList.size() == 0) {
    		buildingMap.put('Fake_ID', new Building__c(Site_Survey__c = this.id));
    		this.id2mediaList.put('Fake_ID', new List<String>());
    	} else {
    		//map the building id to the building object and the select options
    		for(Building__c b : buildList) {
    			this.buildingMap.put(b.id, b);
				this.id2mediaList.put(b.id, new List<String>());
    		}
    	}
    	System.debug('Buildings found are ' + this.buildingMap);
    }
    
    //load digital off air records associated to the site survey
    public void loadDigitalOffAirData() {
    	//initialze var
    	String fieldQuery;
    	
    	//get the fields need to be queried
    	fieldQuery = String.join( getSObjectFields(Digital_Off_Air__c.getSObjectType()), ',');
    	
    	//query for the digital off air records
    	this.digitalList = Database.query('SELECT ' + fieldQuery + ' FROM Digital_Off_Air__c WHERE Site_Survey__c = \'' + this.id + '\'');
    	
    	//if list is empty then add an empty digital off air record to the list
    	if(this.digitalList.isEmpty()){
    		this.digitalList.add(new Digital_Off_Air__c (Site_Survey__c = this.id));
    	}
    }
    
    //load the contact records associated to the account
    public void loadContactData() {
    	//initialize var
    	String fieldQuery;
    	
    	//get the fields need to be queried
    	fieldQuery = String.join( getSOBjectFields(Contact.getSObjectType()), ',');
    	
    	if(this.siteObject.AccountID__c != null){
	    	//query for the contacts related to account that is on the site survey
	    	this.contactList = Database.query('SELECT ' + fieldQuery + ' FROM Contact WHERE AccountId = \'' + this.siteObject.AccountID__c + '\'');
    	}
    	
    	if(this.contactList.size() == 0){
    		if(this.siteObject.AccountID__c != null){
    			this.contactList.add(new Contact(AccountId = this.siteObject.AccountID__c));
    		} else {
    			this.contactList.add(new Contact());
    		}
    	}
    	
    	System.debug('Contacts found on Account are ' + this.contactList);
    }
        
    //load rack room locations
    public void loadFTGLineupData() {
    	System.debug('Entering FTG LINEUP LOAD...');
    	//initialize var
    	String fieldQuery;
    	
    	//get the fields need to be queried
    	fieldQuery = String.join(getSObjectFields(FTG_Lineup__c.getSObjectType()), ',');
    	System.debug('Field query for ftgLineup ' + fieldQuery);
    	
    	//query for the rack locations related to site survey
    	List<FTG_Lineup__c> tempFTG = new List<FTG_Lineup__c>();
    	tempFTG = Database.query('SELECT ' + fieldQuery + ' FROM FTG_Lineup__c WHERE Site_Survey__c = \'' + this.Id + '\'');
    	SYstem.debug('Queried results ##TT ' + tempFTG);
    	for(FTG_Lineup__c ftg : tempFTG) {
    		this.int2FTGMap.put(ftg.Channel__c, ftg);
    	} 
    	System.debug('The integer map to ftg is ' + this.int2FTGMap);
    	
    	//get all channels available on channels
    	Schema.DescribeFieldResult fieldResult = FTG_Lineup__c.Channel__c.getDescribe();
	    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	    System.debug('### picklist entries are ' + ple);    
	    for( Schema.PicklistEntry f : ple){
	    	if( !int2FTGMap.containsKey(f.getValue())){
	    		this.int2FTGMap.put(f.getValue(), new FTG_Lineup__c(Site_Survey__c = this.id, Channel__c = f.getValue()));
	    	}
	    	
	    	//set the list of rows 
	    	if(this.firstColNum.size() < 45){
	    		this.firstColNum.add(f.getValue());
	    	}
	    	else if(this.secondColNum.size() < 45){
	    		this.secondColNum.add(f.getValue());
	    	}
	    	else{
	    		this.thirdColNum.add(f.getValue());
	    	}
	    }
    }
    
    //load the media idf records associated to the site survey
    public void loadMediaIDFData() {
    	//initialize var
    	String fieldQuery;
    	
    	//get the fields need to be queried
    	fieldQuery = String.join( getSOBjectFields(Media_IDF__c.getSObjectType()), ',');
    	
    	String buildingIds = '';
    	for(String buildId : this.buildingMap.KeySet()){
    		if(buildId != 'Fake_ID'){
    			buildingIds += ', \'' + buildId + '\'';
    		}
    	}
    	if(!this.buildingMap.containsKey('Fake_ID')){
	    	buildingIds = '(' + buildingIds.substring(1) + ')';
	    	System.debug('Building Ids are ' + buildingIds);
    	} 
    	
    	//query for the contacts related to account that is on the site survey
    	List<Media_IDF__c> tempMediaIdf = new List<Media_IDF__c>();
    	if(buildingIds.length() > 0){
    					   tempMediaIdf = Database.query('SELECT ' + fieldQuery + ' FROM Media_IDF__c WHERE Building__c IN ' + buildingIds);
    	 
	    	//map the idf to the related buildings
	    	for(Media_IDF__c idf : tempMediaIdf){
	    		this.id2mediaList.get(idf.building__c).add(idf.id);
	    		this.id2MediaIdfMap.put(idf.id, idf);
	    	}
    	}
    	System.debug('Media IDF found on Buildings are ' + this.id2mediaList);
    }
    
    //load the BB idf records associated to the site survey
    public void loadBBIDFData() {
    	//initialize var
    	String fieldQuery;
    	
    	//get the fields need to be queried
    	fieldQuery = String.join( getSOBjectFields(BB_IDF__c.getSObjectType()), ',');
    	
    	//query for the contacts related to account that is on the site survey
    	List<BB_IDF__c> tempBBIdf = Database.query('SELECT ' + fieldQuery + ' FROM BB_IDF__c WHERE Site_Survey__c = \'' + this.id + '\'');
    	
    	//map the idf to the related buildings
    	for(BB_IDF__c idf : tempBBIdf){
    		//initialize the mappings for the idf
    		if(idf.RecordTypeId == this.idfRecordId){
    			this.bbIDFList.add(idf);
    		} else if (idf.RecordTypeId == this.mdfRecordId){
    			this.bbMDFList.add(idf);
    		}
    	}
    	
    	if(this.bbIDFList.size() == 0){
    		this.bbIDFList.add(new BB_IDF__c(Site_Survey__c = this.id, recordTypeId = this.idfRecordId));
    	}
    	if(this.bbMDFList.size() == 0){
    		this.bbMDFList.add(new BB_IDF__c(Site_Survey__c = this.id, recordTypeId = this.mdfRecordId));
    	}
    	
    	System.debug('BB IDF found on site survey are ' + this.bbIDFList);
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
	       // DescribeFieldResult field = fieldMap.get(f).getDescribe();
	     	fieldList.add(f);
	    }
	    
	    //return the list of fields
	    return fieldList;
	  }
	  
	  public static String generateRandomString(Integer len) {
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(blobKey);
        
        System.debug(key);
        return key.substring(0,len);
    }
}