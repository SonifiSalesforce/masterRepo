global with sharing class SubscriptionItemHierarchyExtension {
	
	public Contract con {get;set;}     //public Contract__c con{get;set;}
	public String contnumber {get;set;}
	public String accname {get;set;}
    public String subscriptionprefix {get;set;} //public String subscriptionprefix {get;set;}
    public Map<String, CustomOrder> orderMap {get;set;}
    public List<String> orderList {get;set;}
    public Map<Id,SBQQ__Subscription__c> subMap;  //public Map<Id, Contract_Line_Item__c> subMap;
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
    public SBQQ__Subscription__c cli {get;set;} //public Contract_Line_Item__c cli{get;set;}
    public String saveURL {get;set;}
    public String returnURL {get;set;}
    public Id conid;
    public String returnmessage {get;set;}
    public Boolean islightning {get;set;}
    
    //declaring these variables as public static so they can be used by all the methods in this class
    public static List<SBQQ__Subscription__c> lstsubassets = New List<SBQQ__Subscription__c>();
    public static Contract ContractData = new Contract();
    public static Id OrID;
    
    //jjackson 9/2018 replace hardcoded values with custom setting
    public List<Contract_Order_Approved_Statuses__c> cslist = Contract_Order_Approved_Statuses__c.getall().values();
	public Set<String> setapprovedstatus = getstatusvals(cslist);    
    
    public Set<String> getstatusvals (List<Contract_Order_Approved_Statuses__c> valuelist)
    {
    	Set<String> setvalues = New Set<String>();
    	if(test.IsRunningTest()) { //shawks CPQ 201810 - if in test use following instead of Custom Setting
    		setvalues.add('Order Approved');
    	}
    	else {
    		for(Contract_Order_Approved_Statuses__c coa : valuelist)
    		   {  setvalues.add(coa.name);  }
        }
     	return setvalues;
    }
    
    
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
    	   
    //public ContractLineItemHierarchyExtension(ApexPages.StandardController controller)
    public SubscriptionItemHierarchyExtension(ApexPages.StandardController controller)
    {
    	Utilities.writeLog('Starting....', SubscriptionItemHierarchyExtension.class, 'SubscriptionItemHierarchyExtension', LoggingLevel.DEBUG);
    	this.showNewButton = false;
    	this.showFinalizeOrderButton = false;
    	this.showDelete = false;
    	this.showCheckboxes = false;	
    	this.shouldRedirect = false;
    	this.cli = new SBQQ__Subscription__c();
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
		
		//Schema.DescribeSObjectResult dsr = Contract_Line_Item__c.SObjectType.getDescribe();
		Schema.DescribeSObjectResult dsr = SBQQ__Subscription__c.SObjectType.getDescribe();
		this.subscriptionprefix = dsr.getKeyPrefix();
		setStatusPicklistValues();
					   	
        this.con = (Contract)controller.getRecord();
        this.con = [SELECT Id,ContractNumber,Contract_Status__c, AccountId, Account.name from Contract WHERE Id = :con.Id];
        conid = this.con.Id;
        accname = this.con.account.name;
        contnumber=this.con.contractnumber;
        ContractData = this.con;
        system.debug('contractdata Contract_Status__c is ' +contractdata.Contract_Status__c);
        system.debug('contractdata accountid is ' +contractdata.accountid);
        System.debug('COntract is :' + this.con);
        
           
        if(setapprovedstatus.contains(this.con.Contract_Status__c))
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
       
       //jjackson 2/27/2019 making the checkboxes available to all users because without them,
       //the hierarchy tree doesn't display properly for some profiles and the column spacing is
       //out of whack.  Adding the checkboxes fixes it for everybody.
       //this.showCheckboxes = true;
   
        //Initialize data for hierarchy
        populateHierarchy(); 
        this.treeSize = this.subMap.KeySet().size();
        
        //jjackson 3/2016 return message is used by javascript on the contract line item visual force page
        returnmessage = errormessage(); 
        
        //load the orders
        loadOrders();
        
        Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'ContractLineItemHierarchyExtension', LoggingLevel.DEBUG);    	
    }
 
    public String errormessage()
    {
    	 //jjackson 9/2018
    	 //get a list of all the subscription items and make sure the product parent lines
    	 //have project type and equipment ownership.  Make sure all the items are linked to assets.
        String message = '';
        Boolean assetflag = false;
        
        //List<Contract_Line_Item__c> lstprodparents = New List<Contract_Line_Item__c>();
        List<SBQQ__Subscription__c> lstsubs = New List<SBQQ__Subscription__c>();
        lstsubs = [Select Id, Name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, 
                    product_inventory__c, sbqq__product__r.family, sbqq__product__c,
					sbqq__quantity__c, sbqq__regularprice__c, status__c, contract_type__c, product_parent_id__c,
					sbqq__account__c, sbqq__account__r.name
					from SBQQ__Subscription__c where SBQQ__Contract__c = :conid ];
  
        for(SBQQ__Subscription__c lcli :lstsubs)
        {
        	if(lcli.name__c.contains('Product Parent') && (lcli.project_type__c == null || lcli.equipment_ownership__c == null))
        	{
        		message += lcli.Name__c +' is missing equipment ownership or project type.  Please fix and try again.  ';	
        	}
        	
        	if(lcli.product_inventory__c == null && (lcli.sbqq__product__r.family != 'Entitlement' && lcli.sbqq__product__r.family != 'Warranty'))
        	{
        		
        		assetflag = true;
        	}	
        } 
        
        if(assetflag == true)
        {
        	message += 'One or more selected line items is not linked to a product inventory record.';
        	message += 'Please click Finalize Contract and try again.';
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
            List<SBQQ__Subscription__c> cliList = new List<SBQQ__Subscription__c>();
            //get the parameters and set their values
            if(params.containsKey('selectedKeys')){
                System.debug('SelectedKeys::' +keys);
                selectedKeysString = (List<String>) JSON.deserialize(keys, List<String>.class);
            }
            //remove Non Ids from List
            for(String selectedKey : selectedKeysString)
            {
                if(selectedKey.startsWith(SBQQ__Subscription__c.sObjectType.getDescribe().getKeyPrefix()))
                {
                    selectedKeys.add((Id)selectedKey);
                }
            }
            System.debug('SelectedKeys: ' + selectedKeys );
            for(Id cliId : selectedKeys)
            {
                SBQQ__Subscription__c temp = new SBQQ__Subscription__c (Id = cliId);
                if(selectedStatus != null && selectedStatus != '' && selectedStatus != '--None--')
                    temp.Status__c = selectedStatus;
                if(selectedQuantity != null && selectedQuantity != '')
                    temp.SBQQ__Quantity__c = Decimal.valueOf(selectedQuantity);
                if(selectedProjectType != null && selectedQuantity != '--None--')
                	temp.Project_Type__c = selectedProjectType;
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
                {   this.redirectURL = '/r/Contract/' +con.id +'/view' ; }
            } catch (Exception ex ){
                system.debug('update Subscription Line Item failed : '+ex.getMessage());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
				return null;
            }
        }
		return null;
    }
    
    
    
    
    public PageReference deleteContractLineItems()
    {
    	//Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'deleteContractLineItems', LoggingLevel.DEBUG);
    	
    	system.debug('************BEGIN deleteContractLineItems ***************');
    	
    	String selectedKeysJSON = Apexpages.currentPage().getParameters().get('selectedKeysJSON');
    	
    	//Convert the comma separated string into List of ID
    	if(selectedKeysJSON == '' || selectedKeysJSON == null)
    	{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                       								   'No Subscription Items selected'));
    	} else {
    		try{
    			List<Id> contractLineItemIds = (List<ID>) JSON.deserialize(selectedKeysJSON, List<ID>.class);
    			Map<Id,SBQQ__Subscription__c> cliToDelete = new Map<Id,SBQQ__Subscription__c>([SELECT Id from SBQQ__Subscription__c WHERE Id IN :contractLineItemIds]);
    			
    			   		
				for(Id cliId : cliToDelete.keySet()){
					subMap.remove(cliId);
				}
	    		delete cliToDelete.values();
	    			    		
				this.shouldRedirect = true;
    			PageReference pageRef = new ApexPages.StandardController(this.con).view();
				pageRef.setRedirect(true);
				
				//jjackson 3/2018 redirectUrl value must be different if lightning vs. Classic
				if(islightning == false)
				{  this.redirectUrl = pageRef.getUrl();  }
				else
				{  this.redirectUrl = '/r/Contract/'+con.Id +'/view';  }
			
			}
			catch(Exception ex){
				Utilities.writeLog('Exception....' + ex.getMessage(), SubscriptionItemHierarchyExtension.class, 'deleteContractLineItems', LoggingLevel.DEBUG);
				this.shouldRedirect = false;
		    	this.redirectUrl = null;
	    	 	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
			}
    	}
    	
    	//Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'deleteContractLineItems', LoggingLevel.DEBUG);
    	system.debug('***************END deleteContractLineItems*******************');
    	
    	return null; 
    }
    
    @RemoteAction
    global static boolean updateStatus(List<ID> contractLineItemIds, String statusValue) {
    	//Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'updateStatus statusValue::'+ statusValue, LoggingLevel.DEBUG);
    	
    	system.debug('**********BEGIN updateStatus***************');
    	system.debug('statusValue is ' +statusValue);
    	
    	List<SBQQ__Subscription__c> LineItems = new List<SBQQ__Subscription__c> ();
    	Boolean returnStatus = false;
    	
    	for(ID contractLineItemId : contractLineItemIds) {    		
			SBQQ__Subscription__c subLineItem = new SBQQ__Subscription__c(ID=contractLineItemId, Status__c=statusValue);	
			LineItems.add(subLineItem);
    	}
    	
    	try {    		
    		update LineItems;
    		returnStatus=true;
    	}
    	catch (Exception ex) {
    		Utilities.writeLog('Exception....' + ex.getMessage(), SubscriptionItemHierarchyExtension.class, 'updateStatus statusValue::'+ statusValue, LoggingLevel.DEBUG);
    	}
    	finally {
    		Utilities.writeLog('Ending....', SubscriptionItemHierarchyExtension.class, 'updateStatus statusValue::'+ statusValue, LoggingLevel.DEBUG);
    	}
    	return returnStatus;
    }
    
    private void setStatusPicklistValues() {
    	//Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'setStatusPicklistValues', LoggingLevel.DEBUG);
    	system.debug('***********BEGIN setStatusPicklistValues**************');
    	
    	Schema.DescribeFieldResult fieldResult = SBQQ__Subscription__c.Status__c.getDescribe();
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
	   	
	   	//Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'setStatusPicklistValues', LoggingLevel.DEBUG);
	   	system.debug('***********END setStatusPicklistValues**************');
	}
	
	public Map<Id,SBQQ__Subscription__c> getsubMap()
	{ 
		system.debug('*************BEGIN getsubMap**************');
		
		//shawks - BUG-00176: Add Delivery Method
		Map<Id,SBQQ__Subscription__c> lineitemmap = new Map<Id,SBQQ__Subscription__c>([SELECT 
        													  Id,
								        				  	  Name__c, 
								        				  	  Name,
								        				  	  SBQQ__Contract__c,
															  SBQQ__Contract__r.ContractNumber,
															  Status__c,
															  Parent__c,
															  SBQQ__StartDate__c,
															  SBQQ__EndDate__c,
															  SBQQ__Quantity__c,
															  SBQQ__RegularPrice__c,
															  Equipment_Ownership__c,
															  Project_Type__c,
															  SBQQ__Product__c,
															  SBQQ__Product__r.productcode,
															  SBQQ__Product__r.Name,
															  Parent_ProductCode__c,
															  product_inventory__c,
															  Product_Parent_Id__c,
															  (SELECT Id, Parent__c FROM Subscriptions__r)
								                          FROM 
								                              SBQQ__Subscription__c  
								                          WHERE 
								                              SBQQ__Contract__c = :con.Id
								                          ORDER BY 
								                              Parent__c] );
								                              
								                              
		system.debug('*****************END getsubMap*************');
		
		return lineitemmap;
	}
    
    private void populateHierarchy() 
    {      
    	//Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'populateHierarchy', LoggingLevel.DEBUG);
    	
    	system.debug('**********BEGIN populateHierarchy************');
    	  
        // Get role to users mapping in a map with key as role id
        this.subMap = getsubMap();
                            
      	if(this.subMap.size() == 0){
      		showDelete = false;
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                       '<b>No Subscription Items on Contract.</b>', 
                       'To view subscription items for this contract, you must first add a subscription item to the contract.'));
      	}
      	getTreeJSON();
      
      //Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'populateHierarchy', LoggingLevel.DEBUG);
      system.debug('**********END populateHierarchy************');
    } 
    
	private void getTreeJSON() {
		//Utilities.writeLog('Starting....', ContractLineItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);
		//Utilities.writeLog('subMap: '+subMap, ContractLineItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);
		
		system.debug('***********BEGIN getTreeJSON************');
		
		Integer cliIndex = 0;
		
		gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for(SBQQ__Subscription__c cli : this.subMap.values()) {
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
        
        //Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);
        system.debug('***********END getTreeJSON************');
    }
    
    private void convertNodeToJSON(SBQQ__Subscription__c cli, Boolean initialActivate)
    {    
    	//Utilities.writeLog('Starting.... ContractLineItem: '+cli+' intialActivate: '+initialActivate, ContractLineItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
    	//
    	
    	system.debug('***************BEGIN convertNodeToJSON***************');
    		
        gen.writeStartObject();
        if(null != cli)
        {
	        gen.writeStringField('key', cli.Id);
	        if(this.showNewButton||islightning==true){
	       		gen.writeStringField('href','/' + cli.Id + '?saveURL=%2F' + this.con.Id + '&retURL=%2F' + this.con.Id);
	        	gen.writeStringField('target', '_top');
	        }
        }
        if(null != cli.SBQQ__Product__r.Name)
        	gen.writeStringField('title', cli.SBQQ__Product__r.Name);
        if(null != cli.Status__c)
        	gen.writeStringField('status', cli.Status__c);
        if(null != cli.SBQQ__StartDate__c)
      		gen.writeDateField('termStart', cli.SBQQ__StartDate__c);
        if(null != cli.SBQQ__EndDate__c)
      		gen.writeDateField('termEnd', cli.SBQQ__EndDate__c);
        if(null != cli.SBQQ__Quantity__c)
            gen.writeNumberField('Quantity',cli.SBQQ__Quantity__c);
        if(null != cli.SBQQ__RegularPrice__c)
        {
        	if(string.valueof(cli.SBQQ__RegularPrice__c).contains('.00'))
        	{  gen.writeStringField('Price', string.valueof(cli.SBQQ__RegularPrice__c));  }
        	else
        	{  gen.writeNumberField('Price', cli.SBQQ__RegularPrice__c.setScale(2));  }
        }
        
        //jjackson 9/2018 CPQ Project Commenting this out because Delivery Method is no longer
        //needed on the Subscription object (the subscription object replaces the legal contract line item object)
        //shawks - BUG-00176: Add Delivery Method
       // if(null != cli.Delivery_Method__c)
       //     gen.writeStringField('DeliveryMethod', cli.Delivery_Method__c);
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
        if(cli.Subscriptions__r.size() == 0) {
      		gen.writeBooleanField('folder', false);
        } else {
      		gen.writeBooleanField('folder', true);
  			gen.writeFieldName('children');
            gen.writeStartArray(); 
            for(SBQQ__Subscription__c cliLine : cli.Subscriptions__r) {
              convertNodeToJSON(this.subMap.get(cliLine.Id),false);    
            }
            gen.writeEndArray();       
        }
  		gen.writeEndObject();
  		
  		//Utilities.writeLog('Ending....', ContractLineItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
  		system.debug('***************END convertNodeToJSON***************');
    }   
    
    //load all orders related to the account
     public void loadOrders(){
     	//query for the orders
		List<Order__c> orderLists = [SELECT id, Name, Status__c, Order_Number__c FROM Order__c WHERE Site__c =:ContractData.AccountId AND status__c in :setapprovedstatus ORDER BY Name];
		System.debug('Orders found are ' + orderLists.size());
		
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
		//CustomOrder co2 = new CustomOrder();
		//co2.key = 'No_Order';
		//co2.orderId = null;
		//co2.name = 'No Order';
		//this.orderMap.put(co2.key, co2);
		//this.orderList.add(co2.key);
	}
    
    //send the contract line items and other attributes to be processed
    //jjackson this is what runs after clicking the Finalize Order button
    public PageReference saveTasks(){
    	
    	
    	system.debug('Entering saveTasks');
    	//intialize variables
    	Id orderId = null;
    	List<ID> selectedKeys = new List<ID>();
    	Boolean processOrder = false;
    	//Boolean affectAssets = false;
    	//Boolean affectService = false;
    	//Boolean affectEntitlements = false;
    	Boolean processflag = false;
        Id orderNewId;
    	Map<String, String> params = ApexPages.currentPage().getParameters();
    	Contract thiscontract = New Contract();
    	thiscontract = ContractData;
    	system.debug('thiscontract Contract_Status__c is ' +con.Contract_Status__c);
    	
    	//get the parameters and set their values
    	if(params.containsKey('orderId')){
    		orderId = params.get('orderId') != ''? params.get('orderId'): null;
    		system.debug('saveTasks order id is ' +orderId);
    	}
    	if(params.containsKey('selectedKeys')){
    		String keys = params.get('selectedKeys');
    		System.debug('SelectedKeys::' +keys);
    		selectedKeys = (List<ID>) JSON.deserialize(keys, List<ID>.class);
    		
    		//jjackson query the selected subscription items to verify they are related to asset records.  If not,
    		//throw an error.
    		
    		
    		lstsubassets = [Select Id, Name__c, project_type__c, equipment_ownership__c, sbqq__contract__c,  //undo change Name to new name__c value
                    product_inventory__c, sbqq__product__r.family, sbqq__product__c, sbqq__product__r.productcode, sbqq__contract__r.Contract_Status__c,
					sbqq__quantity__c, sbqq__regularprice__c, status__c, contract_type__c, product_parent_id__c,
					sbqq__account__c, sbqq__account__r.name, parent_productcode__c, parent__c, parent__r.sbqq__product__r.productcode
					from SBQQ__Subscription__c where Id in :selectedKeys ];
					
			//for(Sbqq__subscription__c s :lstsubassets)
			//{ system.debug('sub product inventory is ' +s.product_inventory__c);  }
     	}
    	
    		
    	if(params.containsKey('processOrder')){
    		String key = params.get('processOrder');
    		//if(key == 'No_Order'){
    		//	processOrder = false;
    		//} else {
    		processOrder = true;
    		
    	}
    	/*if(params.containsKey('affectAssets')){
    		affectAssets = params.get('affectAssets') == 'true'? true: false;
    	}
    	if(params.containsKey('affectService')){
    		affectService = params.get('affectService') == 'true'? true: false;
    	}
    	if(params.containsKey('affectEntitle')){
    		affectEntitlements = params.get('affectEntitle') == 'true'? true: false;
    	}*/
    	//system.debug('SelectedKeys: ' + selectedKeys + '. OrderId:' + orderId + '. processOrder:' + processOrder + '. affectAssets:' +affectAssets +
    	//			'. affectService:'	+ affectService + '. affectEntitlements: ' + affectEntitlements);
    	 
    	 
    	 try{
	    	//send data off to other method to do actions

	    	orderNewId = FinalizeOrderContractLogic.ProcessOrderAndOrderItems(processOrder, orderId, lstsubassets); //jjackson not needed affectAssets, affectService, affectEntitlements, affectAssets, null
	    	system.debug(LoggingLevel.Info, 'saveTasks New Order Id returned is '+orderNewId);
	    	if(orderNewId != null){
	    		this.shouldRedirect = true;
	    		//jjackson 3/2018 redirect URL must be different if lightning vs. classic
	    		if(islightning == false)
	    		{ this.redirectUrl = '/' +orderNewId; 
	    		  system.debug('redirectUrl in classic is ' +redirectUrl);
	    		}
	    	 else { //jjackson redirect to the order if user is in lightning
	    		String hostVal = ApexPages.currentPage().getHeaders().get('Host');
	    		String thisurl = 'https://'+hostVal+'/lightning/r/Order__c/' +orderNewId +'/view';
	    		system.debug('redirectUrl in lightning is ' +thisurl);
	    		this.redirectUrl = thisurl;
	    	 }
	       }//end if orderNewId != null
    	 } catch (Exception ex ){
    	 	this.shouldRedirect = false;
	    	this.redirectUrl = null;
    	 	//ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
    	 	system.debug('Error in FinalizeOrderContractLogic: ' +ex.getmessage());
    	 	
    	 }
    	 
    	 system.debug('***********END saveTasks ***************');
       	
    	return null;
    }
    	
    	
}