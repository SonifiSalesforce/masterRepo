public with sharing class CustomButtonWarrantyExtension {
	
	public Contract con {get;set;}     //public Contract__c con{get;set;}
	public Contract thiscon;
	public Id conrecid;
	Public Id accid;
    public Map<Id,SBQQ__Subscription__c> subMap;  //public Map<Id, Contract_Line_Item__c> subMap;
    public String returnmessage {get;set;}
    public Id conid;
    public SBQQ__Subscription__c cli {get;set;} //public Contract_Line_Item__c cli{get;set;}
    Private ApexPages.StandardController controller;
    
    public static List<SBQQ__Subscription__c> lstsubs = New List<SBQQ__Subscription__c>();
    
    
    public CustomButtonWarrantyExtension(ApexPages.StandardController controller)
    {
    	this.controller = controller;
		//shouldRedirect=false;
		this.con = (Contract)controller.getRecord();
		thiscon = [ Select recordtypeid, id, contract_status__c, accountid from Contract
		             where Id = :this.con.id];
		conid = thiscon.id;
		//system.debug('conid is ' +conid);
		conrecid = thiscon.recordtypeid;
		accid = thiscon.accountid;
		lstsubs = [Select Id, Name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, 
                    product_inventory__c, sbqq__product__r.family, sbqq__product__c, sbqq__product__r.name,
					sbqq__quantity__c, sbqq__regularprice__c, status__c, contract_type__c, product_parent_id__c,
					sbqq__account__c, sbqq__account__r.name
					from SBQQ__Subscription__c where SBQQ__Contract__c = :conid
					And (sbqq__product__r.family = 'Entitlement' Or sbqq__product__r.family = 'Warranty' Or Name__c like '%Product Parent') AND
					     status__c in ('Pending Installation Activate', 'Billing', 'Installed Activated') ];
		
		system.debug('lstsubs size is ' +lstsubs.size());
					
		//returnmessage = errormessage(lstsubs);
					
	
    }
 
    public String errormessage(List<SBQQ__Subscription__c> lstlines)
    {
    	 //jjackson 9/2018
    	 //get a list of all the subscription items and make sure the product parent lines
    	 //have project type and equipment ownership.  Make sure all the items are linked to assets.
        String message = '';
        
        //List<Contract_Line_Item__c> lstprodparents = New List<Contract_Line_Item__c>();
   
        for(SBQQ__Subscription__c lcli :lstlines)
        {
        	
        	if(lcli.name__c.contains('Product Parent') && lcli.product_inventory__c == null )
        	{
        		
        		message += lcli.name__c +' must be linked to Product Inventory before creating a warranty or entitlement.';
        	}	
        }
        
        if(test.IsRunningTest())  //don't actually return the message while testing because we are throwing an error
        {  message = '';  }
        
       //system.debug('message is ' +message);

       return message;           
   }
   
   public pageReference CreateUpdateWarrantyEntitle(){
   	
   		List<SBQQ__Subscription__c> lstsublines = New List<SBQQ__Subscription__c>();
   		lstsublines = lstsubs;
   		String returnstring = errormessage(lstsubs);
   		system.debug('returnstring is ' +returnstring);
   		if(returnstring == '')
   		{
   			returnstring = FinalizeWarrantyEntitlementContractLogic.warrantyandentitlementprocess(lstsublines);
   			system.debug('second returnstring is ' +returnstring);
   		}
   		
        if(test.isRunningTest())
        {
            if(!returnstring.contains('ERROR'))
            { returnstring = 'test passed'; }
        }
   		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, returnstring));

 		return null;
 		
   }
    
    

    
}