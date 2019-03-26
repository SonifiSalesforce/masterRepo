// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 08/07/2013
// Description:  Page extension for displaying product inventory (asset) hierarchy for an account
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
/****LOG***********************************************************************************
   jjackson 09/2018 -- Updating the code to point to the standard Contract and Subscription objects
                       in CPQ instead of legal contract and legal contract line item (custom objects)
   jjackson 11/2017 -- Add Billing Qty, Access Card #, and Receiver ID fields to the
                       line item hierarchy columns. Remove qty, systemid and billing frequency.
   shawks 09/18/2017 - BUG-00176:  Move Delivery Method to Legal Contract Line Items
/*****************************************************************************************/

public with sharing class AccountAssetHierarchyExtension {

    private ApexPages.StandardController controller;      // Standard Page Controller
    public Account AccountRecord {get;set;}                 // ... for an Account
    private Boolean IsPreviousRecordProductFamily = false;
    // map to hold Assets for the Account with Id as the key
    public Asset a {get;set;}
    public Map<Id, Asset> assetMap;
    public string treeJSON {get;set;}
    public List<SelectOption> assetStatusValues{get;set;}
    public String assetStatusSelected{get;set;}
    public String assetStatusQuantity{get;set;}
    public String assetStatusCancel{get;set;} //jjackson 11/2017 add cancel date to mass update    
    //public Contract__C potentialNew {get;set;}
    public Contract potentialNew {get;set;}
    public Map<String, CustomContract> contractMap {get;set;}
    public List<String> contractList {get;set;}
    public String redirectUrl {public get; private set;}
    public Boolean shouldRedirect {public get; private set;}
    public Boolean showAddContractLineItems {public get; private set;}
    public String returnresult = '';
    
    public class CustomContract {
        public String                               contractId                              { get; set; }
        public String                               name                                    { get; set; }
        public String                               key                                     { get; set; }
    }
    
    // Global JSON generator
    public static JSONGenerator gen {
        get {
            if(gen == null)
                gen = JSON.createGenerator(true);
            return gen;
        } 
        set;
    }    
    
    public List<CustomContract> getCustomContracts() {
        if (contractMap == null || contractMap.isEmpty()) { 
            loadContracts();
            if (contractMap  == null || contractMap.isEmpty()) { return null; }
        }
        return contractMap.values();
    }
    public AccountAssetHierarchyExtension(ApexPages.StandardController stdController) {
        controller = stdController;
        this.shouldRedirect = false;
        this.a = new Asset();
               
        this.showAddContractLineItems = false;
        AccountRecord = (Account)controller.getRecord();
        this.contractMap = new Map<String, CustomContract>();
        this.contractList = new List<String>();
        this.assetStatusValues = new List<SelectOption>();
        
        //initialize new temp contract
        //potentialNew = new Contract__c();
        potentialNew = new Contract();
        potentialNew.Status = 'Draft';
        potentialNew.AccountId = AccountRecord.Id;         
        //Created contracts have record type "Contract"
        potentialNew.RecordTypeId = Utilities.RecordTypeNameToId('Contract','Contract Amendment');
        
        //jjackson 4/2017 removed hard-coded profile names and added them to a custom setting called
        //AccountAssetHierarchyProfiles__c that can be queried to get the profiles that should have access
        //to the custom buttons on the vf page; Now if we need to add or remove access, we just change profile names
        //in the custom setting
        List<AccountAssetHierarchyProfiles__c> currentUserProfiles = [SELECT Name FROM AccountAssetHierarchyProfiles__c ];
        Set<String> setprofilenames = New Set<String>();
        if(test.IsRunningTest())
        { setprofilenames.add('System Administrator'); }
        else
        {
        	for(AccountAssetHierarchyProfiles__c pro : currentUserProfiles)
        		{  setprofilenames.add(pro.Name);  }
        }
        List<Profile> lstgetprofilename = [Select Id, Name from Profile where id = :UserInfo.getProfileId() LIMIT 1 ];
        for(Profile p : lstgetprofilename)
        {
               if(setprofilenames.contains(p.name))
               {  this.showAddContractLineItems = true; }
               else
               {  this.showAddContractLineItems = false;  }
        } 

        //intialize select list values
        initializeAssetStatusValues();
        // initialize helper data for getRootNodeOfUserTree function
        populateAssetHierarchy();
        
        //load orders
        loadContracts();
    }
    
    public void initializeAssetStatusValues()
    {
        Schema.DescribeFieldResult assetFieldDescription = Asset.Status.getDescribe();
        assetStatusValues.add(new SelectOption('','--None--'));      
        for (Schema.Picklistentry picklistEntry : assetFieldDescription.getPicklistValues())
        {
            assetStatusValues.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
        }
        
    }
    
    private void populateAssetHierarchy() {
    	//jjackson -- replace references to contract__c and contract_line_item__c with Contract and sbqq__subscription__c
        //shawks - BUG-00176: Update field name of Delivery Method
        // Get role to users mapping in a map with key as role id
        this.assetMap = new Map<Id, Asset>([SELECT 
                                                a.Id, 
                                                a.Name, 
                                                a.Parent_Asset__c, 
                                                a.AccountId, 
                                                a.Description, 
                                                a.Status, 
                                                a.System_Status__c,
                                                a.Term_Start_Date__c,
                                                a.Term_End_Date__c,
                                                a.Cancellation_Date__c,
                                                a.Service_Start_Date__c,
                                                a.Service_End_Date__c,
                                                a.Auto_Renew__c, 
                                                a.Renewal_Cycle__c,
                                                a.Renewal_Term__c,                                         
                                                a.Platform__c,
                                                a.Product2Id, 
                                                a.Product2.Product_Code_Ext_Id__c, 
                                                a.Product2.Family, 
                                                a.Product2.Description, 
                                                a.Product2.ProductCode, 
                                                a.Product2.Name, 
                                                a.Billing_Quantity__c, //jjackson
                                                a.Receiver_ID__c,
                                                a.DTV_Account_Number__c,
                                                a.SerialNumber,
                                                a.System_ID__c,
                                                a.Fee_Schedule__c,
                                                a.Card_ID__c, //jjackson
                                                a.contract__c,
                                                a.contract__r.contractnumber,
                                                a.contract__r.name,
                                                //a.legal_contract__c,       //shawks CPQ - Comment out
                                                //a.legal_contract__r.name,  //shawks CPQ - Comment out
                                               (SELECT 
                                                    Id, 
                                                    AccountId 
                                                FROM 
                                                    Product_Inventory_Line_Items__r) 
                                            FROM 
                                                Asset a 
                                            WHERE 
                                                a.AccountId=:AccountRecord.Id //AND a.product2.productcode like 'CC-%'
                                            ORDER BY 
                                               a.Parent_Asset__c,
                                               a.Product2.Name]);
        //for(Asset a :this.assetmap.values())
        //{
       // 	system.debug(a.name +','+a.parent_asset__c+','+a.legal_contract__r.name+','+a.contract__r.contractnumber+','+a.platform__c+','+a.parent_asset__c+','+a.accountid+','+a.status);
        //}
                                        
        if(this.assetMap.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                                 '<b>No product inventory assigned to account.</b>', 
                                 'To view product inventory for this account, you must first add a product inventory to the account.'));
        }
        getTreeJSON();      
    } 

    
    private void getTreeJSON() {
        gen.writeStartArray();
        this.IsPreviousRecordProductFamily = false;
        for(Asset inventoryProduct : this.assetMap.values()) {
            if(null == inventoryProduct.Parent_Asset__c)
                convertNodeToJSON(inventoryProduct);
        }
        gen.writeEndArray();
        this.treeJSON = gen.getAsString();
        System.debug('JSON is ' + this.treeJSON);
    }
    
    
    
    private void convertNodeToJSON(Asset inventoryProduct){
        //System.debug('convertNodeToJSON ' + inventoryProduct.Product2.Name + 'inventoryProduct.Product_Inventory_Line_Items__r.size()' + inventoryProduct.Product_Inventory_Line_Items__r.size());
        //system.debug('inventoryproduct.parent_asset__c is ' +inventoryproduct.parent_asset__c +' and ispreviousrecordproductfamily is ' +this.IsPreviousRecordProductFamily);
        if(null == inventoryProduct.Parent_Asset__c && !this.IsPreviousRecordProductFamily) {
        	//system.debug('inventoryProduct name is ' +inventoryProduct.name +',' +inventoryProduct.contract__r.contractnumber +',' +inventoryproduct.status +',' +inventoryproduct.legal_contract__r.name);
            gen.writeStartObject();
            gen.writeStringField('title', '');
            gen.writeBooleanField('icon', false);
            gen.writeBooleanField('productFamilyColumnHeader', true);
            gen.writeStringField('columnHeader1', 'Status');
            gen.writeStringField('columnHeader2', 'Term Start');
            gen.writeStringField('columnHeader3', 'Term End');
            gen.writeStringField('columnHeader4', 'System Status');
            gen.writeStringField('columnHeader5', 'Auto Renew');
            gen.writeStringField('columnHeader6', 'Platform');
            gen.writeStringField('columnHeader7', 'Renewal Term');
            gen.writeStringField('columnHeader8', 'Renewal Cycle');
            gen.writeBooleanField('hideCheckbox', true);
            gen.writeBooleanField('unselectable', true);
            gen.writeEndObject();
        }
        gen.writeStartObject();
        if(null != inventoryProduct.Id)
        {
            gen.writeStringField('key', inventoryProduct.Id);
            gen.writeStringField('href','/'+inventoryProduct.Id);
            gen.writeStringField('target', '_top');
        }
        if(null != inventoryProduct.Product2.Name)
            gen.writeStringField('title', inventoryProduct.Product2.Name);
        if(null != inventoryProduct.Status)
            gen.writeStringField('status', inventoryProduct.Status);
        if(null != inventoryProduct.System_Status__c)
            gen.writeStringField('systemStatus', inventoryProduct.System_Status__c);
        if(null != inventoryProduct.Term_Start_Date__c)
            gen.writeStringField('termStart', inventoryProduct.Term_Start_Date__c.format());
        if(null != inventoryProduct.Term_End_Date__c)
            gen.writeStringField('termEnd', inventoryProduct.Term_End_Date__c.format());
        if(null != inventoryProduct.Service_Start_Date__c)
            gen.writeStringField('serviceStart', inventoryProduct.Service_Start_Date__c.format());
        if(null != inventoryProduct.Service_End_Date__c)
            gen.writeStringField('serviceEnd', inventoryProduct.Service_End_Date__c.format());
        if(null != inventoryProduct.Cancellation_Date__c)
            gen.writeStringField('cancelDate', inventoryProduct.Cancellation_Date__c.format());
        if(null != inventoryProduct.Auto_Renew__c)
            gen.writeBooleanField('autoRenew', inventoryProduct.Auto_Renew__c);
        if(null != inventoryProduct.Platform__c)
            gen.writeStringField('platform', inventoryProduct.Platform__c);
        if(null != inventoryProduct.Renewal_Term__c)
            gen.writeNumberField('renewalTerm', inventoryProduct.Renewal_Term__c.intValue());
        if(null != inventoryProduct.Renewal_Cycle__c)
            gen.writeNumberField('renewalCycle', inventoryProduct.Renewal_Cycle__c.intValue());
        if(null == inventoryProduct.Parent_Asset__c)
            gen.writeBooleanField('productFamily', true);
        if(null != inventoryProduct.Billing_Quantity__c) //jjackson
            gen.writeNumberField('quantity', inventoryProduct.Billing_Quantity__c.intValue());   //jjackson  
        if(null != inventoryProduct.Receiver_ID__c)
            gen.writeStringField('receiverAddress', inventoryProduct.Receiver_ID__c);   
        if(null != inventoryProduct.DTV_Account_Number__c)
            gen.writeStringField('dTVAccountNumber', inventoryProduct.DTV_Account_Number__c);   
        if(null != inventoryProduct.SerialNumber)
            gen.writeStringField('serialNumber', inventoryProduct.SerialNumber);
        if(null != inventoryProduct.Card_ID__c)
            gen.writeStringField('systemID', inventoryProduct.Card_ID__c); //jjackson make this the card id instead   
       // if(null != inventoryProduct.Fee_Schedule__c) jjackson--remove this column because there isn't room
       //     gen.writeStringField('feeSchedule', inventoryProduct.Fee_Schedule__c);  
       // jjackson 9/2018 removed for CPQ because no longer using this field    
        //shawks - BUG-00176: Update field name of Delivery Method
      //  if(null != inventoryProduct.Delivery_Method_CLI__c)
     //       gen.writeStringField('deliveryMethod', inventoryProduct.Delivery_Method_CLI__c);            
        gen.writeBooleanField('expanded', false);
        gen.writeBooleanField('hideCheckbox', !this.showAddContractLineItems);
        if(inventoryProduct.Product_Inventory_Line_Items__r.size() == 0) {
            gen.writeBooleanField('folder', false);
            this.IsPreviousRecordProductFamily=false;
        } else {
            gen.writeBooleanField('folder', true);
            gen.writeFieldName('children');
            this.IsPreviousRecordProductFamily = true;
            gen.writeStartArray(); 
            if(null == inventoryProduct.Parent_Asset__c) {
                gen.writeStartObject();
                gen.writeStringField('title', '');
                gen.writeBooleanField('icon', false);
                gen.writeBooleanField('packageColumnHeader', true);
                gen.writeStringField('columnHeader1', 'Status');
                gen.writeStringField('columnHeader2', 'Start Date');
                gen.writeStringField('columnHeader3', 'End Date');
                gen.writeStringField('columnHeader4', 'Cancel Date');
                gen.writeStringField('columnHeader5', 'Billing Qty'); //jjackson
                gen.writeStringField('columnHeader6', 'Receiver ID');
                gen.writeStringField('columnHeader7', 'DirecTV Account');
                gen.writeStringField('columnHeader8', 'Serial Number');
                gen.writeStringField('columnHeader9', 'Access Card ID'); //change system id to access card id
               // gen.writeStringField('columnHeader11', 'Fee Schedule'); jjackson-remove this column
                //gen.writeStringField('columnHeader6', 'Delivery Method'); jjackson-remove this column for CPQ
                gen.writeBooleanField('hideCheckbox', true);
                gen.writeBooleanField('unselectable', true);
                gen.writeEndObject();
            }
            for(Asset inventoryProductLine : inventoryProduct.Product_Inventory_Line_Items__r) {
                convertNodeToJSON(this.assetMap.get(inventoryProductLine.Id));      
            }
            gen.writeEndArray();       
        }
        gen.writeEndObject();
    }  
    
    //load all orders related to the account
     public void loadContracts(){
        //query for the orders
        List<Contract> contractLists = New List<Contract>();
        contractLists = [SELECT id, contractnumber, name, accountid FROM Contract WHERE AccountId =:this.AccountRecord.Id ORDER BY contractnumber];
        System.debug('contracts found are ' + contractLists.size());
        
        //intialize and set the wrapper fields and add it to the map
        CustomContract co1 = new CustomContract();
        co1.key = 'New Contract';
        co1.contractId = 'New Contract';
        co1.name = 'New Contract';
        this.contractList.add(co1.key);
        this.contractMap.put(co1.key, co1);            
        for(Contract o : contractLists){
            CustomContract co = new CustomContract();
            co.key = o.Id;
            co.contractId = o.Id;
            co.name = o.contractnumber;
            this.contractMap.put(co.key, co);
            this.contractList.add(co.key);
        }
        System.debug('contracts options are ' + contractList);
    }
    
    
    public PageReference setAssetStatus()
    {
 
            Map<String, String> params = ApexPages.currentPage().getParameters();
        	assetStatusSelected = params.get('selectedStatus');
        	system.debug('asset status selected '+assetStatusSelected);
        	assetStatusQuantity = params.get('massupdate1');            
        	system.debug('asset status Quantity '+assetStatusQuantity);
        	assetStatusCancel = params.get('massupdate2');
        
  
        
        if((assetStatusValues != null || assetStatusQuantity != null) &&
           ((assetStatusSelected != null && assetStatusSelected != '') || 
            (assetStatusQuantity != null && assetStatusQuantity != '') ||
            (assetStatusCancel != null && assetStatusCancel != '')) 
          )
        {
            //intialize variables
            Id contractId = null;
            List<ID> selectedKeys = new List<ID>();
            //get all the parameters 
            List<Asset> assetList = new List<Asset>();
            //get the parameters and set their values
            if(params.containsKey('selectedKeys')){
                String keys = params.get('selectedKeys');
                System.debug('SelectedKeys::' +keys);
                selectedKeys = (List<ID>) JSON.deserialize(keys, List<ID>.class);
            }
           // System.debug('SelectedKeys: ' + selectedKeys + '. ContractId:' + contractId);
            for(Id assetId : selectedKeys)
            {
                Asset temp = new Asset(Id = assetId);
                if (assetStatusSelected != null && assetStatusSelected != '') {
                   temp.Status = assetStatusSelected;
                }
                if (assetStatusQuantity != null && assetStatusQuantity != '') {
                   temp.Billing_Quantity__c =  Decimal.valueOf(assetStatusQuantity); //jjackson
                }
                if (assetStatusCancel != null && assetStatusCancel != '') //jjackson added this to pull date from Asset mass update dialog box
                {  
                	Date canceldate = FormatToSystemDate(assetStatusCancel); //jjackson added method to format the date entry to system date format
                	temp.cancellation_date__c = canceldate; }
                assetList.add(temp);
                //System.debug('SelectedKeys: added ' + temp);
            }
            try{
                update assetList;
                this.shouldRedirect = true;
                PageReference pageRef = new ApexPages.StandardController(AccountRecord).view();
                pageRef.setRedirect(true);
                this.redirectUrl = pageRef.getUrl();
            } catch (Exception ex ){
                system.debug('update Assets failed : '+ex.getMessage());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
            }
        }
        return null;
    }
    
    //send the contract line items and other attributes to be processed
    public PageReference saveTasks(){
        //intialize variables
        String contractId = null;
        List<ID> selectedKeys = new List<ID>();
        
        //get all the parameters 
        Map<String, String> params = ApexPages.currentPage().getParameters();
        
        //get the parameters and set their values
        if(params.containsKey('contractId')){
            contractId = params.get('contractId') != ''? (String)params.get('contractId'): null;
        }
        if(contractId == 'New Contract')
        {
            try{
                insert potentialNew;
                contractId = potentialNew.Id;
            }
            catch(Exception e)
            {
            system.debug('Cannot insert new temporary Contract '+e.getMessage());
            }        
        }
        
        system.debug('after insert potentialNew contract, id is ' +contractId);
        
        if(params.containsKey('selectedKeys')){
            String keys = params.get('selectedKeys');
            System.debug('SelectedKeys::' +keys);
            selectedKeys = (List<ID>) JSON.deserialize(keys, List<ID>.class);
        }
        System.debug('SelectedKeys: ' + selectedKeys + '. ContractId:' + contractId);
        
        try{
            //send data off to other method to do actions
            returnresult = CustomContractLogicforCPQ.createSubscriptionItems(selectedKeys, (Id)contractId); 
            
            system.debug('returnresult after createSubscriptionItems = ' +returnresult);
            
            //returnresult string should be empty unless createSubscriptionItems returns an error message
            if(!String.isBlank(returnresult))
            { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, returnresult, '')); 
              return null;
            }
            
            
            this.shouldRedirect = true;
            PageReference pageRef = new ApexPages.StandardController(new Contract(Id=contractId)).view();
            pageRef.setRedirect(true);
            this.redirectUrl = pageRef.getUrl();
         } catch (Exception ex ){
            this.shouldRedirect = false;
            this.redirectUrl = '';
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
         }
         
        return null;
    }
    
    public static Date FormatToSystemDate(String datetoformat)
    {
    	Date thisdate;
    	
    	String m = datetoformat.substringBefore('/');
    	String d = datetoformat.substringBetween('/');
    	String y = datetoformat.right(4);
    	
    	thisdate = date.valueof(y+'-'+m+'-'+d);
    	
    	return thisdate;
    }
}