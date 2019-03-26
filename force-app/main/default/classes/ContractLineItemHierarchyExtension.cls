/*
jjackson 4/2018 Added code to help with navigation on lightning ui as well as classic ui.  TODO : change lightning
url references from /one/one.app#/sObject/ to the new url format coming in summer '18
shawks 09/18/2017 - BUG-00176: Add Delivery Method to Contract Line Items
jjackson, Sonifi Solutions, 3/17/2016:  Added code to throw an error if the Finalize Order button is clicked
and any product parents on the contract are missing either a project type or equipment ownership value.  The
error message displays as a javascript error. BUG-00553
*/

global with sharing class ContractLineItemHierarchyExtension{ 

		
    public Contract__c con{get;set;}
    public String contractLineItemPrefix {get;set;}
    public Map<String, CustomOrder> orderMap {get;set;}
    public List<String> orderList {get;set;}
    public Map<Id, Contract_Line_Item__c> cliMap;
    public string treeJSON {get;set;}
    public string statusValuesJSON {get;set;}
    public Boolean showDelete{get;set;}
    public List<Id> selectIdList{get;set;}
    public Integer treeSize {get;set;}
    public Boolean showNewButton {get;set;}
    public Boolean showFinalizeOrderButton {get;set;}
    public Boolean showCheckboxes {get;set;}
    public String redirectUrl {public get; private set;}
    public Boolean shouldRedirect {public get; private set;}
    public Contract_Line_Item__c cli{get;set;}
    public String saveURL {get;set;}
    public String returnURL {get;set;}
    public Id conid;
    public String returnmessage {get;set;}
    public String OrdId {get;set;}
    public Boolean islightning {get;set;}
    
    
    public class CustomOrder {
		public Id									orderId									{ get; set; }
		public String 								name									{ get; set; }
		public String								key										{ get; set; }
	}
   
   public List<CustomOrder> getCustomOrders() {
		if (orderMap == null || orderMap.isEmpty()) { 
			loadOrders();
			if (orderMap  == null || orderMap.isEmpty()) { return null; }
		}
		return orderMap.values();
	}
    public static JSONGenerator gen {
  		get {
			if(gen == null)
		  		gen = JSON.createGenerator(true);
			return gen;
      	} 
      	set;
    }
    	   
    public ContractLineItemHierarchyExtension(ApexPages.StandardController controller)
    {
    	Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'ContractLineItemHierarchyExtension', LoggingLevel.DEBUG);
    	this.showNewButton = false;
    	this.showFinalizeOrderButton = false;
    	this.showDelete = false;
    	this.showCheckboxes = false;	
    	this.shouldRedirect = false;
    	this.cli = new Contract_Line_Item__c();
    	cli.Status__c = null;
    	
    	islightning = false;
    	
    	if(UserInfo.getUIThemeDisplayed() == 'Theme4d')
    	{  islightning = true;  }
    	
    	system.debug('theme displayed is ' +UserInfo.getUIThemeDisplayed());
     	
        if(ApexPages.currentPage().getParameters().containsKey('saveURL')) {
            this.saveURL = ApexPages.currentPage().getParameters().get('saveURL');
            system.debug('saveURL value is ' +this.saveURL);
        }

        if(ApexPages.currentPage().getParameters().containsKey('retURL')) {
            this.returnURL = ApexPages.currentPage().getParameters().get('retURL');
            system.debug('returnURL value is ' +this.returnURL);
        }
    	
    	
    	//jjackson 10/2014 add Accounting and Finance profiles
    	List<Profile> currentUserProfiles = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
		String currentUserProfileName = currentUserProfiles[0].Name;
		//jjackson 12/2014 Added new custom setting that contains a list of all profile names so we don't have to keep hardcoding
	    List<Create_Contract_Line_Item_Profiles__c> profilelist = Create_Contract_Line_Item_Profiles__c.getall().values();  //jjackson 12/2014
	    Set<String> profilenames = new set<String>();  //jjackson  12/2014
		//if(currentUserProfileName != 'CSG' && 
		//   currentUserProfileName != 'CSG Manager' && 
		//   currentUserProfileName != 'Contracts Admin Manager' && 
		//   currentUserProfileName != 'Contracts Specialist' && 
		//   currentUserProfileName != 'Contracts Admin Specialist' && 
		//   currentUserProfileName != 'Contracts/Sales Specialist' && 
		//   currentUserProfileName != 'System Administrator' &&
		//   currentUserProfileName != 'Accounting' &&
		//   currentUserProfileName != 'Finance') {
		this.showNewButton = false;  //jjackson button should be false until it is verified that the person is the correct profile
	    for(Create_Contract_Line_Item_Profiles__c proname : profilelist)
	    {
            profilenames.add(proname.profile_name__c);	
		}
		
		if(profilenames.Contains(currentUserProfileName)==true)
		{
			if(islightning == false)	
			{  this.showNewButton = true;    }
			system.debug('this.shownewButton value is ' +this.showNewButton);
		}
		 //else {
		//this.showNewButton = true;
		//jjackson no changes made to the showFinalizeOrderButton code
			if(currentUserProfileName == 'CSG Manager' ||
		   	   currentUserProfileName == 'Contracts Admin Manager' ||
		       currentUserProfileName == 'System Administrator') {
		     	this.showFinalizeOrderButton = true;  	
		    }
		
		//}
		
		this.treeSize = 0;
    	showDelete = true;
		this.orderMap = new Map<String, CustomOrder>();
		this.orderList = new List<String>();
		
		Schema.DescribeSObjectResult dsr = Contract_Line_Item__c.SObjectType.getDescribe();
		this.contractLineItemPrefix = dsr.getKeyPrefix();
		setStatusPicklistValues();
					   	
        this.con = (Contract__c)controller.getRecord();
        this.con = [SELECT Id,Name,Status__c, Account_Name__c from Contract__c WHERE Id = :con.Id];
        conid = this.con.Id;
        System.debug('COntract is :' + this.con);
        if(this.con.Status__c == 'Order Approved' || this.con.Status__c == 'Approved to Build' || this.con.Status__c == 'Approved to Ship and Install')
        {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                       '<b>Contract Status is an Order Approved status</b>', ''));
			this.showDelete = false;        	
        } else {
        	
        	if(currentUserProfileName == 'CSG Manager' ||
		   	   currentUserProfileName == 'Contracts Admin Manager' ||
		       currentUserProfileName == 'System Administrator' ||
		       currentUserProfileName == 'Accounting' ||
		       currentUserProfileName == 'Finance') {
        		this.showDelete=true;
		   } else { this.showDelete=false;  }
         }   
        
        if(this.showDelete || this.showFinalizeOrderButton) {
        	this.showCheckboxes = true;
        }
   
        //Initialize data for hierarchy
        populateHierarchy();
        this.treeSize = this.cliMap.KeySet().size();
        
        //jjackson 3/2016 return message is used by javascript on the contract line item visual force page
        returnmessage = errormessage(); 
        
        //load the orders
        loadOrders();
        
        Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'ContractLineItemHierarchyExtension', LoggingLevel.DEBUG);    	
    }
    
    //jjackson added to catch javascript variable from page
   // public PageReference UIValue()
  //  {
  //  	if(Apexpages.currentPage().getParameters().containsKey('islightning'))
  //  	{  islightning = ApexPages.currentPage().getParameters().get('islightning');  }
  //  	system.debug('string value is ' +islightning);
  //  	return null;
  //  }
    
    public String errormessage()
    {
    	 //jjackson 3/16/2016 get a list of all product parents on the contract and verify they have both
        //a project type and equipment ownership.  If not, throw an alert in javascript on the page
        //if the string returned here is not empty
        //this is a save test
        
        
        String message = '';
        
        List<Contract_Line_Item__c> lstprodparents = New List<Contract_Line_Item__c>();
        lstprodparents = [ Select Id, Name, project_type__c, equipment_ownership__c, legal_contract__c from
                            contract_line_item__c where legal_contract__c = :conid AND Name like '%Product Parent' ];
        for(Contract_Line_Item__c lcli :lstprodparents)
        {
        	if(lcli.project_type__c == null || lcli.equipment_ownership__c == null)
        	{
        		message += lcli.Name +' is missing equipment ownership or project type.  Please fix and try again.  ';	
        	}	
        }
        
        if(test.IsRunningTest())  //don't actually return the message while testing because we are throwing an error
        {  message = '';  }

       return message;           
   }
    //shawks - BUG-00176: Add Delivery Method parameter
    public PageReference massUpdateFields()
    {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        String keys = params.get('selectedKeys');
        String selectedStatus = params.get('selectedStatus');
        String selectedQuantity = params.get('selectedQuantity');
        String selectedProjectType = params.get('selectedProjectType');
        String selectedDeliveryMethod = params.get('selectedDeliveryMethod');

        if(keys != null || selectedStatus != null || selectedQuantity != null || selectedProjectType != null || selectedDeliveryMethod != null)
        {
            //intialize variables
            Id contractId = null;
            //get all the parameters
            List<String> selectedKeysString = new List<String>();
            List<Id> selectedKeys = new List<Id>();
            List<Contract_Line_Item__c> cliList = new List<Contract_Line_Item__c>();
            //get the parameters and set their values
            if(params.containsKey('selectedKeys')){
                System.debug('SelectedKeys::' +keys);
                selectedKeysString = (List<String>) JSON.deserialize(keys, List<String>.class);
            }
            //remove Non Ids from List
            for(String selectedKey : selectedKeysString)
            {
                if(selectedKey.startsWith(Contract_Line_Item__c.sObjectType.getDescribe().getKeyPrefix()))
                {
                    selectedKeys.add((Id)selectedKey);
                }
            }
            System.debug('SelectedKeys: ' + selectedKeys );
            for(Id cliId : selectedKeys)
            {
                Contract_Line_Item__c temp = new Contract_Line_Item__c(Id = cliId);
                if(selectedStatus != null && selectedStatus != '' && selectedStatus != '--None--')
                    temp.Status__c = selectedStatus;
                if(selectedQuantity != null && selectedQuantity != '')
                    temp.Quantity__c = Decimal.valueOf(selectedQuantity);
                if(selectedProjectType != null && selectedQuantity != '--None--')
                	temp.Project_Type__c = selectedProjectType;
                if(selectedDeliveryMethod != null && selectedDeliveryMethod != '')
                    temp.Delivery_Method__c = selectedDeliveryMethod;
                cliList.add(temp);
            }
            try{
                update cliList;
                this.shouldRedirect = true;
                PageReference pageRef = new PageReference('/'+con.id);
                pageRef.getParameters().put('saveURL',this.saveURL);
                pageRef.getParameters().put('retURL',this.returnURL);
                pageRef.setRedirect(true);
               
                //jjackson 3/2018 added this so vf page will redirect back to legal contract in lightning
                if(islightning == false)
                {   this.redirectUrl = pageRef.getUrl();  
                	system.debug('this.redirectUrl is ' +this.redirectUrl);
                }
                else
                {   this.redirectURL = '/one/one.app#/sObject/' +con.id;  }
            } catch (Exception ex ){
                system.debug('update Contract Line Item failed : '+ex.getMessage());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
				return null;
            }
        }
		return null;
    }
    
    
    
    
    public PageReference deleteContractLineItems()
    {
    	Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'deleteContractLineItems', LoggingLevel.DEBUG);
    	
    	String selectedKeysJSON = Apexpages.currentPage().getParameters().get('selectedKeysJSON');
    	
    	//Convert the comma separated string into List of ID
    	if(selectedKeysJSON == '' || selectedKeysJSON == null)
    	{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                       								   'No Contract Line Items selected'));
    	} else {
    		try{
    			List<Id> contractLineItemIds = (List<ID>) JSON.deserialize(selectedKeysJSON, List<ID>.class);
    			Map<Id,Contract_Line_Item__c> cliToDelete = new Map<Id,Contract_Line_Item__c>([SELECT Id from Contract_Line_Item__c WHERE Id IN :contractLineItemIds]);
    		
				for(Id cliId : cliToDelete.keySet()){
					cliMap.remove(cliId);
				}
	    		delete cliToDelete.values();
				this.shouldRedirect = true;
    			PageReference pageRef = new ApexPages.StandardController(this.con).view();
				pageRef.setRedirect(true);
				
				//jjackson 3/2018 redirectUrl value must be different if lightning vs. Classic
				if(islightning == false)
				{  this.redirectUrl = pageRef.getUrl();  }
				else
				{  this.redirectUrl = '/one/one.app#/sObject/' +con.Id;  }
			
			}
			catch(Exception ex){
				Utilities.writeLog('Exception....' + ex.getMessage(), ContractLineItemHierarchyExtension.class, 'deleteContractLineItems', LoggingLevel.DEBUG);
				this.shouldRedirect = false;
		    	this.redirectUrl = null;
	    	 	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
			}
    	}
    	
    	Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'deleteContractLineItems', LoggingLevel.DEBUG);
    	
    	return null; 
    }
    
    @RemoteAction
    global static boolean updateStatus(List<ID> contractLineItemIds, String statusValue) {
    	Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'updateStatus statusValue::'+ statusValue, LoggingLevel.DEBUG);
    	
    	List<Contract_Line_Item__c> contractLineItems = new List<Contract_Line_Item__c> ();
    	Boolean returnStatus = false;
    	
    	for(ID contractLineItemId : contractLineItemIds) {    		
			Contract_Line_Item__c contractLineItem = new Contract_Line_Item__c(ID=contractLineItemId, Status__c=statusValue);	
			contractLineItems.add(contractLineItem);
    	}
    	
    	try {    		
    		update contractLineItems;
    		returnStatus=true;
    	}
    	catch (Exception ex) {
    		Utilities.writeLog('Exception....' + ex.getMessage(), ContractLineItemHierarchyExtension.class, 'updateStatus statusValue::'+ statusValue, LoggingLevel.DEBUG);
    	}
    	finally {
    		Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'updateStatus statusValue::'+ statusValue, LoggingLevel.DEBUG);
    	}
    	return returnStatus;
    }
    
    private void setStatusPicklistValues() {
    	Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'setStatusPicklistValues', LoggingLevel.DEBUG);
    	
    	Schema.DescribeFieldResult fieldResult = Contract_Line_Item__c.Status__c.getDescribe();
	   	List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();	
	   	List<SelectOption> options = new List<SelectOption>();
	   	gen = JSON.createGenerator(true);
	   	gen.writeStartArray();      
	   	for( Schema.PicklistEntry f : ple) {
	   		gen.writeStartObject();
	   		gen.writeStringField('label', f.getLabel());
	   		gen.writeStringField('value', f.getValue());
      		gen.writeEndObject();
      	}  
	   	gen.writeEndArray(); 
	   	this.statusValuesJSON= gen.getAsString();
	   	
	   	Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'setStatusPicklistValues', LoggingLevel.DEBUG);
	}
	
	public Map<Id,Contract_Line_Item__c> getcliMap()
	{ 
		//shawks - BUG-00176: Add Delivery Method
		Map<Id,Contract_Line_Item__c> lineitemmap = new Map<Id,Contract_Line_Item__c>([SELECT 
        													  Id,
								        				  	  Name,	
								        				  	  Legal_Contract__c,
															  Legal_Contract__r.Name,
															  Auto_Renew__c,
															  Status__c,
															  Parent__c,
															  Renewal_Cycle__c, 
															  Term_End_Date__c,
															  Term_Start_Date__c,
															  Quantity__c,
															  Price__c,
															  Equipment_Ownership__c,
															  Project_Type__c,
															  Product__c,
															  Product__r.Name, 
															  Delivery_Method__c,
															  (SELECT Id, Parent__c FROM Contract_Line_Items__r)
								                          FROM 
								                              Contract_Line_Item__c  
								                          WHERE 
								                              Legal_Contract__c = :con.Id
								                          ORDER BY 
								                              Parent__c] );
		
		return lineitemmap;
	}
    
    private void populateHierarchy() 
    {      
    	Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'populateHierarchy', LoggingLevel.DEBUG);
    		  
        // Get role to users mapping in a map with key as role id
        this.cliMap = getcliMap();
                            
      	if(this.cliMap.size() == 0){
      		showDelete = false;
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                       '<b>No Contract Line Items on Contract.</b>', 
                       'To view contract line items for this contract, you must first add a contract line item to the contract.'));
      	}
      	getTreeJSON();
      
      Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'populateHierarchy', LoggingLevel.DEBUG);
    } 
    
	private void getTreeJSON() {
		Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);
		//Utilities.writeLog('cliMap: '+cliMap, ContractLineItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);
		
		Integer cliIndex = 0;
		
		gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for(Contract_Line_Item__c cli : this.cliMap.values()) {
      		if(cli != null && null == cli.Parent__c) {      			
      			if(cliIndex==0)
    				convertNodeToJSON(cli, true);
    			else
    				convertNodeToJSON(cli, false);
 				cliIndex++;
          	}
        }
        gen.writeEndArray();
        this.treeJSON = gen.getAsString();
        
        Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);
    }
    
    private void convertNodeToJSON(Contract_Line_Item__c cli, Boolean initialActivate)
    {    
    	//Utilities.writeLog('Starting.... ContractLineItem: '+cli+' intialActivate: '+initialActivate, ContractLineItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
    	//
    		
        gen.writeStartObject();
        if(null != cli)
        {
	        gen.writeStringField('key', cli.Id);
	        if(this.showNewButton||islightning==true){
	       		gen.writeStringField('href','/' + cli.Id + '?saveURL=%2F' + this.con.Id + '&retURL=%2F' + this.con.Id);
	        	gen.writeStringField('target', '_top');
	        }
        }
        if(null != cli.Product__r.Name)
        	gen.writeStringField('title', cli.Product__r.Name);
        if(null != cli.Status__c)
        	gen.writeStringField('status', cli.Status__c);
        if(null != cli.Term_Start_Date__c)
      		gen.writeDateField('termStart', cli.Term_Start_Date__c);
        if(null != cli.Term_End_Date__c)
      		gen.writeDateField('termEnd', cli.Term_End_Date__c);
        if(null != cli.Quantity__c)
            gen.writeNumberField('Quantity',cli.Quantity__c);
        if(null != cli.Price__c)
        {
        	if(string.valueof(cli.Price__c).contains('.00'))
        	{  gen.writeStringField('Price', string.valueof(cli.Price__c));  }
        	else
        	{  gen.writeNumberField('Price', cli.Price__c.setScale(2));  }
        }
        //shawks - BUG-00176: Add Delivery Method
        if(null != cli.Delivery_Method__c)
            gen.writeStringField('DeliveryMethod', cli.Delivery_Method__c);
      	//jjackson 4/18/2016:  replace autorenew and renewal cycle with quantity and price
       // gen.writeBooleanField('autoRenew', cli.Auto_Renew__c);
       // if(null != cli.Renewal_Cycle__c)
       // 	gen.writeNumberField('renewalCycle', cli.Renewal_Cycle__c.intValue());
        if(null == cli.Parent__c)
      		gen.writeBooleanField('productFamily', true);
        gen.writeBooleanField('unselectable', true);
        gen.writeBooleanField('expanded', true);
        gen.writeBooleanField('activate', initialActivate);
        gen.writeBooleanField('focus', initialActivate);
        if(cli.Contract_Line_Items__r.size() == 0) {
      		gen.writeBooleanField('folder', false);
        } else {
      		gen.writeBooleanField('folder', true);
  			gen.writeFieldName('children');
            gen.writeStartArray(); 
            for(Contract_Line_Item__c cliLine : cli.Contract_Line_Items__r) {
              convertNodeToJSON(this.cliMap.get(cliLine.Id),false);    
            }
            gen.writeEndArray();       
        }
  		gen.writeEndObject();
  		
  		//Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
    }   
    
    //load all orders related to the account
     public void loadOrders(){
     	//query for the orders
		List<Order__c> orderLists = [SELECT id, Name, Status__c, Order_Number__c FROM Order__c WHERE Site__c =:this.con.Account_Name__c AND (Status__c = 'Order Approved' OR Status__c = 'Approved to Build' OR Status__c = 'Approved to Ship and Install') ORDER BY Name];
		System.debug('Orders found are ' + orderLists);
		
		//intialize and set the wrapper fields and add it to the map
		for(Order__c o : orderLists){
			CustomOrder co = new CustomOrder();
			co.key = o.Id;
			co.orderId = o.Id;
			co.name = o.Name + ' - ' + o.Order_Number__c;
			this.orderMap.put(co.key, co);
			this.orderList.add(co.key);
		}
		System.debug('Orders options are ' + orderList);
		
		//new order custom order to the map
		CustomOrder co1 = new CustomOrder();
		co1.key = 'New_Order';
		co1.orderId = null;
		co1.name = 'New Order';
		this.orderMap.put(co1.key, co1);
		this.orderList.add(co1.key);
		
		//no order custom order to the map
		CustomOrder co2 = new CustomOrder();
		co2.key = 'No_Order';
		co2.orderId = null;
		co2.name = 'No Order';
		this.orderMap.put(co2.key, co2);
		this.orderList.add(co2.key);
	}
    
    //send the contract line items and other attributes to be processed
    public PageReference saveTasks(){
    	system.debug('Entering save tasks');
    	//intialize variables
    	Id orderId = null;
    	List<ID> selectedKeys = new List<ID>();
    	Boolean processOrder = false;
    	Boolean affectAssets = false;
    	Boolean affectService = false;
    	Boolean affectEntitlements = false;
    	Boolean processflag = false;
    	Id orderNewId = null;
    
    // try{ processflag = CheckOwnershipandProjectType(); }
    // catch(Exception ex)
    // {ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));   }
     
     //if(processflag == true)
     	//get all the parameters 
    	Map<String, String> params = ApexPages.currentPage().getParameters();
    	
    	//get the parameters and set their values
    	if(params.containsKey('orderId')){
    		orderId = params.get('orderId') != ''? params.get('orderId'): null;
    		system.debug('saveTasks order id is ' +orderId);
    	}
    	if(params.containsKey('selectedKeys')){
    		String keys = params.get('selectedKeys');
    		System.debug('SelectedKeys::' +keys);
    		selectedKeys = (List<ID>) JSON.deserialize(keys, List<ID>.class);
    	}
    	if(params.containsKey('processOrder')){
    		String key = params.get('processOrder');
    		if(key == 'No_Order'){
    			processOrder = false;
    		} else {
    			processOrder = true;
    		}
    	}
    	if(params.containsKey('affectAssets')){
    		affectAssets = params.get('affectAssets') == 'true'? true: false;
    	}
    	if(params.containsKey('affectService')){
    		affectService = params.get('affectService') == 'true'? true: false;
    	}
    	if(params.containsKey('affectEntitle')){
    		affectEntitlements = params.get('affectEntitle') == 'true'? true: false;
    	}
    	system.debug('SelectedKeys: ' + selectedKeys + '. OrderId:' + orderId + '. processOrder:' + processOrder + '. affectAssets:' +affectAssets +
    				'. affectService:'	+ affectService + '. affectEntitlements: ' + affectEntitlements);
    	 
    	 
    	 try{
	    	//send data off to other method to do actions
	    	orderNewId = CustomContractLogic.CreateRelatedRecords(selectedKeys, processOrder, orderId, affectAssets, affectService, affectEntitlements, affectAssets, null);
	    	system.debug(LoggingLevel.Info, 'saveTasks New Order Id returned is '+orderNewId);
	    	if(orderNewId != null){
	    		this.shouldRedirect = true;
	    		OrdId=orderNewId;
	    		//jjackson 3/2018 redirect URL must be different if lightning vs. classic
	    		if(islightning == false)
	    		{ this.redirectUrl = '/' +orderNewId; 
	    		  system.debug('redirectUrl in classic is ' +redirectUrl);
	    		}
	    		
	    	} else {
	    		this.shouldRedirect = false;
	    		this.redirectUrl = null;
	    	}
    	 } catch (Exception ex ){
    	 	this.shouldRedirect = false;
	    	this.redirectUrl = null;
    	 	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
    	 	
    	 }
       	
    	return null;
    
    }

}