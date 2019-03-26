// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 08/07/2013
// Description:  Page extension for displaying programming  hierarchy for an opportunity
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
/****LOG***********************************************************************************
   shawks 201811 - CPQ: Replace Contract__c object reference with Contract object
/*****************************************************************************************/
// *********************************************************************************************
public with sharing class OpportunityProgrammingHeirarchyExtension {
    
    private ApexPages.StandardController controller;
    public Opportunity opportunityRecord {get;set;}
    public List<String> contractList {get;set;}
    //public Contract__C potentialNew {get;set;}  //shawks CPQ - update to use Contract
    public Contract potentialNew {get;set;}
    public Boolean showAddContractLineItems{get;set;}
	public Map<String, CustomContract> contractMap {get;set;}    
    public Boolean shouldRedirect {public get; private set;}    
    public String redirectUrl {public get; private set;}    
    public Map<Id, Programming__c> programmingMap {get;set;}
    public string treeJSON {get;set;}
    public boolean isPreviousRecordNode{get;set;}
    public String strAppliedQuote {get;set;}
    public String strPrimaryQuote {get;set;}
    
	public class CustomContract {
		public String								contractId								{ get; set; }
		public String 								name									{ get; set; }
		public String								key										{ get; set; }
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
    
    public OpportunityProgrammingHeirarchyExtension(ApexPages.StandardController controller){
        this.opportunityRecord = (Opportunity)controller.getRecord();
        //shawks CPQ - Add Applied_Quote__c, SBQQ__PrimaryQuote__c, and SBQQ__Contracted__c to SOQL so can reference on VF page
        this.opportunityRecord = [SELECT AccountId, Applied_Quote__c, SBQQ__PrimaryQuote__c, SBQQ__Contracted__c from Opportunity WHERE Id = :opportunityRecord.Id][0];
        strPrimaryQuote = '';
        strAppliedQuote = '';
        //Check if opportunity is linked to both CPQ (has primary quote) and SPT Quotes (has applied quote) -> ERROR (should not have both) 
        if ((String)opportunityRecord.SBQQ__PrimaryQuote__c <> NULL && (String)opportunityRecord.SBQQ__PrimaryQuote__c <> ''
             && (String)opportunityRecord.Applied_Quote__c  <> NULL && (String)opportunityRecord.Applied_Quote__c  <> '') {
           strPrimaryQuote = (String)opportunityRecord.SBQQ__PrimaryQuote__c;
           strAppliedQuote = (String)opportunityRecord.Applied_Quote__c;
        //Check if primary quote set (CPQ) and no applied quote -> Prepare to create CPQ contract
        } else if ((String)opportunityRecord.SBQQ__PrimaryQuote__c <> NULL && (String)opportunityRecord.SBQQ__PrimaryQuote__c <> '') {
           strPrimaryQuote = (String)opportunityRecord.SBQQ__PrimaryQuote__c;
        } else {  //Else -> Prepare to create SPT contract
           strAppliedQuote = '';
           strPrimaryQuote = '';
        }

        this.contractList = new List<String>();
        this.contractMap = new Map<String, CustomContract>();        
        this.shouldRedirect = false;
        //shawks CPQ - Update to use Contract
        //potentialNew = new Contract__c();
        //potentialNew.Status__c = 'Draft';
		//potentialNew.Account_Name__c = opportunityRecord.AccountId;
		//potentialNew.RecordTypeId = Utilities.RecordTypeNameToId('Contract__c','Contract');
        //potentialNew.Opportunity__c = opportunityRecord.Id;
		potentialNew = new Contract();
        potentialNew.Contract_Status__c = 'Draft';
		potentialNew.AccountId = opportunityRecord.AccountId;
        //Created contracts have record type "Contract"
        potentialNew.RecordTypeId = Utilities.RecordTypeNameToId('Contract','Contract');
        potentialNew.SBQQ__Opportunity__c = opportunityRecord.Id;
        //showAddContract
		List<Profile> currentUserProfiles = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
		String currentUserProfileName = currentUserProfiles[0].Name;
		List<OpportunityProgrammingHierarchyAdd__c> csList = [SELECT Name from OpportunityProgrammingHierarchyAdd__c WHERE Name = :currentUserProfileName];
		system.debug('csList '+csList);
		if(csList.size() > 0) {
			this.showAddContractLineItems = true;
		} else {
			this.showAddContractLineItems = false;
		}
        
        
        populateProgrammingHeirarchy();
        
        //Load Contracts
        //loadContracts();
        
    }
    private void populateProgrammingHeirarchy(){
        this.programmingMap = new Map<Id, Programming__c>([Select   Id, 
                                                                    Name, // labeled programming Id 
                                                                    ProductName__c, 
                                                                    ProductCode__c, 
                                                                    Qty__c, 
                                                                    Price__c, //price per unit 
                                                                    Total__c, 
                                                                    CreatedById, 
                                                                    CreatedDate,
                                                                    Parent__c,
                                                                    (Select Id, 
                                                                    	    Parent__c
                                                                       From Programming__r)
                                                            FROM    
                                                                    Programming__c
                                                            WHERE   
                                                                    Opportunity__c=: opportunityRecord.Id
                                                            ORDER BY
                                                                    Parent__c,
                                                                    ProductName__c  ]);
        if(this.programmingMap.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                                 '<b>No programming inventory assigned to opportunity.</b>', 
                                 'To view programming for this opportunity, you must first add programming to the opportunity.'));
        }
        getTreeJSON();  
    
    } 
    
    //load all orders related to the account 
     public void loadContracts(){
     	//query for the orders
		//shawks CPQ - update to use Contract
		//List<Contract__c> contractLists = [SELECT id, Name, RecordTypeId, RecordType.Name, Contract_Type__c FROM Contract__c WHERE Account_Name__c =:this.opportunityRecord.AccountId AND Status__c != 'Activated' AND Status__c != 'Cancelled' AND Status__c != 'Inactive' ORDER BY Name];
		List<Contract> contractLists = [SELECT id, ContractNumber, RecordTypeId, RecordType.Name, Contract_Type__c FROM Contract
		                                   WHERE AccountId =:this.opportunityRecord.AccountId AND Contract_Status__c != 'Activated'
		                                     AND Contract_Status__c != 'Cancelled' AND Contract_Status__c != 'Inactive'
		                                   ORDER BY ContractNumber];
		System.debug('contracts found are ' + contractLists);

		//intialize and set the wrapper fields and add it to the map
		CustomContract co1 = new CustomContract();
		co1.key = 'New Contract';
		co1.contractId = 'New Contract';
		co1.Name = 'New Contract';
		this.contractList.add(co1.key);
		this.contractMap.put(co1.key, co1);
		//for(Contract__c o : contractLists){
		for(Contract o : contractLists){
			CustomContract co = new CustomContract();
			co.key = o.Id;
			co.contractId = o.Id;
			co.name = o.ContractNumber + ' : ' + o.RecordType.Name;
			this.contractMap.put(co.key, co);
			this.contractList.add(co.key);
		}
		
		System.debug('contracts options are ' + contractList);
	}
    public void saveTasks(){
    	//intialize variables
    	String contractId = null;
    	List<ID> selectedKeys = new List<ID>();
    	
    	//get all the parameters 
    	Map<String, String> params = ApexPages.currentPage().getParameters();
    	
    	//get the parameters and set their values
    	if(params.containsKey('contractId')){
    		contractId = params.get('contractId') != ''? (String)params.get('contractId'): null;
    	}
    	//Delete potential new if not selected
    	if(contractId == 'New Contract')
    	{
	        try{
	        	insert potentialNew;
	        	contractId = potentialNew.Id;
	        }
	        catch(Exception e)
	        {
	        	system.debug('Cannot insert new temporary Contract');
	        }    		
    	}
    	if(params.containsKey('selectedKeys')){
    		String keys = params.get('selectedKeys');
    		System.debug('SelectedKeys::' +keys);
    		selectedKeys = (List<ID>) JSON.deserialize(keys, List<ID>.class);
    	}
    	System.debug('SelectedKeys: ' + selectedKeys + '. ContractId:' + contractId);
    	
		try{
	    	//send data off to other method to do actions
	    	//shawks CPQ - use new method in new class
	    	//CustomContractLogic.createContractLineItemsFromOpportunity(selectedKeys, contractId, this.opportunityRecord.Id, Boolean.valueOf(params.get('appendToContractBoolean'))); 
	    	CustomContractLogicforCPQ.createSubscriptionsFromOpportunity(selectedKeys, contractId, this.opportunityRecord.Id,
	    	                                                             this.opportunityRecord.AccountId, Boolean.valueOf(params.get('appendToContractBoolean')));
	    	this.shouldRedirect = true;
	    	this.redirectUrl = '/' + contractId;
    	 } catch (Exception ex ){
    	 	system.debug('Failed to create Contract Line Items '+ex.getMessage());
    	 	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
    	 	
    	 }
    	
    }
	
    
    
    
    public void getTreeJSON(){
        gen.writeStartArray();
        
        for(Programming__c program : this.programmingMap.values()){
            if(program.Parent__c == null) {
                convertNodeToJSON(program);
            }
        }
        gen.writeEndArray();
        this.treeJSON = gen.getAsString();
        System.debug('JSON is '+ this.treeJSON);
    }
    
    public void convertNodeToJSON(Programming__c program){
        gen.writeStartObject();
        if(program.Id!=null)
        {
            gen.writeStringField('key', program.Id);
            gen.writeStringField('href','/'+program.Id);
            gen.writeStringField('target', '_top');
        }
        if(program.Name!=null)
        {
            gen.writeStringField('title', program.ProductName__c);
        }
        System.debug(Logginglevel.INFO, 'Product Name : ' + program.ProductName__c);
        if(program.ProductName__c!=null)
        {
            gen.writeStringField('productName', program.ProductName__c );
        }
        if(program.ProductCode__c!=null){
            gen.writeStringField('productCode', program.ProductCode__c);
        }
        if(program.Qty__c!=null){
            gen.writeStringField('quantity', program.Qty__c.format());
        }
        if(program.Price__c!=null){
            gen.writeStringField('price', program.Price__c.format());
        }
        if(program.Total__c!=null){
            gen.writeStringField('total', program.Total__c.format());
        }
        if(program.CreatedById!=null){
            gen.writeStringField('createdById', program.CreatedById);
        }
        if(program.CreatedDate!=null){
            gen.writeStringField('createdDate', program.CreatedDate.format());
        }
        
        if(program.Programming__r.size() == 0) {
        	gen.writeBooleanField('folder', false);
        } else {
        	gen.writeBooleanField('folder', true);
        	gen.writeFieldName('children');
        	gen.writeStartArray(); 
            for(Programming__c programmingLineItem : program.Programming__r) {
            	if(this.programmingMap.containsKey(programmingLineItem.Id)){
            		convertNodeToJSON(this.programmingMap.get(programmingLineItem.Id));	
            	}	
            }
            gen.writeEndArray();       
        }
        
        gen.writeEndObject();
        
    }
    
    //shawks CPQ - Add check to Opportunity field "Contracted" to create contract 
    public void updateAsContracted() {
    	Opportunity updOppContract = this.opportunityRecord;
    	updOppContract.SBQQ__Contracted__c = true;
    	update updOppContract;

    	system.debug('Updating opportunity and creating CPQ contract');
    }
}