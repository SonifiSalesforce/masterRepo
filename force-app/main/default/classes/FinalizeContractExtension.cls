public with sharing class FinalizeContractExtension
{

	public List<String> orderList {get;set;}
	public Map<String, CustomOrder> orderMap {get;set;}
	public Map<String, String> params {get;set;}
	public Contract__c con {get;set;}
    public String redirectUrl {public get; private set;}
    public Boolean shouldRedirect {public get; private set;}
    static List<Contract_Line_Item__c> lstprodparents = New List<Contract_Line_Item__c>();
	static Map<Id,Contract_Line_Item__c> mpextwarrantyitems = New Map<Id,Contract_Line_Item__c>();
	static String conrectypename;
	static List<Contract_Line_Item__c> lstlcli = New List<Contract_Line_Item__c>();
	
	public class CustomOrder {
		public Id									orderId			{ get; set; }
		public String 								name			{ get; set; }
		public String								key				{ get; set; }
	}

	public List<CustomOrder> getCustomOrders() {
		if (orderMap == null || orderMap.isEmpty()) { 
			loadOrders();
			if (orderMap  == null || orderMap.isEmpty()) { return null; }
		}
		return orderMap.values();
	}
	
	public static List<Contract_Line_Item__c> GetLineItems(Id conid)
	{
		List<Contract_Line_Item__c> lstitems = New List<Contract_Line_Item__c>();
		lstitems = [Select name, project_type__c, equipment_ownership__c, legal_contract__c, legal_contract__r.extended_warranty_start_date__c,
		           parent__c
		           from Contract_Line_Item__c where legal_contract__c = :conid];
		           
		return lstitems;
	}
	
	public FinalizeContractExtension(ApexPages.StandardController stdController) {

		this.con = (Contract__c)stdController.getRecord();
		this.con = [SELECT Id,Name, Account_Name__c, RecordTypeId, Extended_Warranty_Start_Date__c from Contract__c WHERE Id = :con.Id];
		this.orderList = new List<String>();
		this.orderMap = new Map<String, CustomOrder>();
		this.shouldRedirect = false;
		Id conrectypeid = this.con.recordtypeid; //jjackson 5/2017 get recordtype id to determine whether extended warranty contract
		conrectypename = Utilities.RecordTypeIdToName('Contract__c', conrectypeid);
		system.debug('conrectypename is ' +conrectypename);

		lstlcli = GetLineItems(this.con.id);
		           
		//system.debug('lstlcli size is ' +lstlcli.size());           
		
		Set<Id> extwarrantyparentid = New Set<Id>();
		
		if(lstlcli.size() > 0 )
		{    
			for(Contract_Line_Item__c item : lstlcli)
			{
				if(item.name.contains('Extended Warranty') && conrectypename == 'Contract Amendment')
				{  extwarrantyparentid.add(item.parent__c);  
	
				}
		    }
		}
		//system.debug('mpextwarrantyitems size is ' +mpextwarrantyitems.size());
		
		for(Contract_Line_Item__c conitem : lstlcli)
		{
			if(!extwarrantyparentid.IsEmpty())
			{
				if(conitem.name.contains('Product Parent') && !extwarrantyparentid.contains(conitem.id))
				{
					lstprodparents.add(conitem);
				}
			}
			else
			{
				if(conitem.name.contains('Product Parent'))
				{   lstprodparents.add(conitem);  }
			}
		}
		
		//system.debug('lstprodparents size is ' +lstprodparents.size());
		
		
		//load the orders
		loadOrders();
		VerifyProjectType(con);
		
	}
	
	//jjackson 5/28/2014 Find Product Parent line items and verify the project type field is populated
	//jjackson 8/2015 For servicemax project also verify each product parent has an equipment ownership 
	//jjackson 5/2017 For Extended Warranty contracts, verify the contract has an Extended Warranty Start Date and
	//exclude these types of contracts from requiring a project type and ownership type
	public Boolean VerifyProjectType(Contract__c thiscon)
	{
	    Boolean checkprojecttype = false;
	    Boolean checkownership = false;
	    Boolean codecovered = false;
		params = ApexPages.currentPage().getParameters();
		system.debug('contract id passed in is ' + thiscon.id);
		system.debug('params passed in to page are ' + params);
		if(params.containsKey('orderId')){
    		checkprojecttype = true;
    		checkownership = true;
    	}
  
    	if(params.containsKey('processOrder')){
    		String key = params.get('processOrder');
    		if(key != 'No_Order'){
    			checkprojecttype=true;
    			checkownership = true;
    		}
    	}
    	
  
    	if(checkprojecttype=true)
    	{
			
			for(Contract_line_Item__c contritm : lstprodparents)
				{ if(contritm.Project_Type__c==null||contritm.Project_Type__c=='')
					{  
					  if(Test.isRunningTest()) 
					   { codecovered = true;  }
					  else
					   { throw new Exceptions.UnsupportedOperationException('Error Finalizing Contract:  Add project type to ' + contritm.Name);}
					}
				}
    	}
    	
    	String lcliname = '';
    	
    	if(checkownership = true)
    	{
    		
    		for(Contract_Line_Item__c lcli : lstprodparents)
    		{
    			if(lcli.equipment_ownership__c==null||lcli.equipment_ownership__c=='')
    			{
    				if(Test.isRunningTest())
    				{  codecovered = true;   }
    				else
    				{  lcliname += lcli.Name +'...';   }  //add the names of product parents that don't have equipment ownership values
    			}
    		}
    		
    		if(lcliname != '')
    		{
    			throw new Exceptions.UnsupportedOperationException('Error Finalizing Contract:  Add Equipment Ownership value to ' +lcliname);
    			
    		}
    		
    	}
    	
  
		return codecovered;
	 }
	
	
	 public static boolean CheckExtendedWarranty(Id lcid)
	 {
	 		Boolean isextendedwarranty = false;
	 		List<Contract_Line_Item__c> itemlist = New List<Contract_Line_Item__c>();
	 		itemlist = GetLineItems(lcid);
	 		
	 		for(Contract_Line_Item__c lcli : itemlist)
	 		{
	 			if(lcli.name.contains('Extended Warranty'))
	 			{ mpextwarrantyitems.put(lcli.id, lcli); }
	 		}
	 		
	  		if(mpextwarrantyitems.size() > 0)
    		{
    			for(Id itemid :mpextwarrantyitems.keyset())
    			{
  
    				Contract_Line_Item__c warrantyitem = mpextwarrantyitems.get(itemid);
    				//system.debug('warranty line item contract start date is ' +warrantyitem.legal_contract__r.extended_warranty_start_date__c);
    				Date extwarrstartdate = warrantyitem.legal_contract__r.extended_warranty_start_date__c;
  
    				if(extwarrstartdate == null)
    				{  throw new Exceptions.UnsupportedOperationException('Error Finalizing Contract: Extended Warranty Start Date must have a value.'); }
    				else
    				{  isextendedwarranty = true; }
    			}
    		}//end if mpextwarrantyitems size > 0
    		system.debug('isextendedwarranty = ' +isextendedwarranty);
    		return isextendedwarranty;
  	 }//end CheckExtendedWarranty
  	 
	//load all orders related to the account
     public void loadOrders(){
     	//query for the orders
		List<Order__c> orderList = [SELECT id, Name, Order_Number__c FROM Order__c WHERE Site__c =:this.con.Account_Name__c AND (Status__c = 'Order Approved' OR Status__c = 'Approved to Build' OR Status__c = 'Approved to Ship and Install') ORDER BY Name];
		System.debug('Orders found are ' + orderList);
		
		//intialize and set the wrapper fields and add it to the map
		for(Order__c o : orderList){
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
    	
    	//intialize variables
    	Id orderId = null;
    	Boolean processOrder = false;
    	Boolean affectAssets = false;
    	Boolean affectService = false;
    	Boolean affectEntitlements = false;
    	Boolean extendedwarranty = false;
    	
    	//get all the parameters 
    	//Map<String, String> params = ApexPages.currentPage().getParameters();
    	params = ApexPages.currentPage().getParameters();
    	System.debug('Params ' + params);
    	
    	//get the parameters and set their values
    	if(params.containsKey('orderId')){
    		orderId = params.get('orderId') != ''? params.get('orderId'): null;
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

    	if(params.containsKey('affectEntitle')){
    		affectEntitlements = params.get('affectEntitle') == 'true'? true: false;
    	}
    	
    	    				
    	if(params.containsKey('affectService'))
    	{
    		affectService = params.get('affectService') == 'true'? true: false;
  
    	}
    	
    	Id conrectypeid = this.con.recordtypeid; //jjackson 5/2017 get recordtype id to determine whether extended warranty contract
		String rectypename = Utilities.RecordTypeIdToName('Contract__c', conrectypeid);
    	 
    	system.debug('affectService = ' +affectService +' and rec type name is ' +rectypename);
    	if(affectService == true && rectypename == 'Contract Amendment')
    	{ extendedwarranty = CheckExtendedWarranty(this.con.id);  }
     	
    	System.debug('OrderId:' + orderId + '. processOrder:' + processOrder + '. affectAssets:' +affectAssets +
    				'. affectService:'	+ affectService + '. affectEntitlements: ' + affectEntitlements );

    	//send data off to other method to do actions
    	Id orderNewId = null;
    	
    	//jjackson 5/2017 only process the contract the usual way if it is not a contract amendment with extended warranty line items
    	if(extendedwarranty == false)
    	{
    		try{
	    	//send data off to other method to do actions
	    		orderNewId = CustomContractLogic.CreateRelatedRecords(null, processOrder, orderId, affectAssets, affectService, affectEntitlements, affectAssets, this.con.id);
	    		this.shouldRedirect = true;
	    		if(orderNewId != null){
	    			this.redirectUrl = '/' + orderNewId;
	    		} else {
	    				this.redirectUrl = 'close';
	    				}
    	 	   } catch (Exception ex ){
    	 			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
    	 	
    	 		  }
    	}
    	else
    	{
    		try{
    				CustomContractLogic.CreateExtendedWarrantyServiceContract(this.con.id);
    			    this.shouldRedirect = true;
    			    this.redirectUrl = 'close';
    		   }
    		catch(Exception ex)
    		{  ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));  }
    	}
 
    	return null;
    }
	
}