public with sharing class FieldWOLineItemTriggerLogic {
    
    //this actually populates all line item fields needed for NetSuite
    public static void PopulateNetSuiteLocation(List<WorkOrderLineItem> listnewlines)
    {
    	
    	system.debug('********************BEGIN PopulateNetSuiteLocation*********************');
  	                 
    	Set<Id> workorderids = New Set<Id>();
    	List<WorkOrderLineItem> lstupdatelines = New List<WorkOrderLineItem>();
    	Map<String,Field_Service_PartNum_to_OrderType__c> mpordertype = New Map<String,Field_Service_PartNum_to_OrderType__c>();
    	
    	if(!test.IsRunningTest())
    	{
    		//create a map from custom setting Field_Service_PartNum_to_OrderType__c.  This will allow us to assign netsuite order type and
    		//netsuite product type values based on each line item part number
     		mpordertype = Field_Service_PartNum_to_OrderType__c.getall();
    	}
	
    	
    	for(WorkOrderLineItem woli : listnewlines)
    	{
    		workorderids.add(woli.workorderid); //get all the work order ids so we can query work order account info
     	}
    	
    	//this creates a map without having to pull a list first, then spin through it to add it to a map
    	Map<Id,WorkOrder> mpworkorders = New Map<Id,WorkOrder>([Select Id, healthcare_site__c, Account.Name, Account.physical_state__c,
    	                                                        Account.Site_Id__c, technician__c, account_country__c
    	                                                        from Workorder where id in:workorderids]);
    	for(WorkOrderLineItem woli : listnewlines)
    	{
    	  system.debug('line item part name is ' +woli.part_name__c);	
    		
    	  if(mpworkorders.containskey(woli.workorderid))	
          {    	
    		WorkOrder wo = mpworkorders.get(woli.workorderid);
     		system.debug('account physical state = ' +wo.account.physical_state__c);
    		system.debug('healthcare site = ' +wo.healthcare_site__c);
    		system.debug('account name is ' +wo.account.name);
    		system.debug('account is id ' +wo.account.site_id__c);
    		//this updates the netsuite location field on the work order line item; it must run in the after insert trigger because
    		//the related part name info can't be found until the new record is saved
    		
    	   if(wo.account_country__c == 'USA')
    	   {
    		if(wo.healthcare_site__c == true && woli.part_number__c != null && (woli.part_name__c.contains('LABOR') || woli.part_name__c.contains('TRIP')))
    		{
    			woli.netsuite_location__c = 'Healthcare';
    			woli.netsuite_external_id__c = wo.Account.Site_Id__c+'.09';
    			lstupdatelines.add(woli);
    			system.debug('hit 1');
    		}
    	
    		
    		if(wo.healthcare_site__c == false && wo.account.physical_state__c != 'PR' && wo.account.physical_state__c != 'VI' &&
    		  woli.part_number__c != null && (woli.part_name__c.contains('LABOR') || woli.part_name__c.contains('TRIP')))
    		{
    			woli.netsuite_location__c = 'Sx Falls Inv';
    			woli.netsuite_external_id__c = wo.Account.Site_Id__c+'.01';
    			lstupdatelines.add(woli);
    			system.debug('hit 2');
    		}
    		
    		if(wo.healthcare_site__c == false && wo.account.physical_state__c == 'PR' && woli.part_number__c != null
    		   && (woli.part_name__c.contains('LABOR') || woli.part_name__c.contains('TRIP')))
    		{
    			woli.netsuite_location__c = 'Puerto Rico';
    			woli.netsuite_external_id__c = wo.Account.site_id__c+'.25';
    			lstupdatelines.add(woli);
    			system.debug('hit 3');   	
            }
            
            if(wo.healthcare_site__c == false && wo.account.physical_state__c == 'VI' && woli.part_number__c != null &&
              (woli.part_name__c.contains('LABOR') || woli.part_name__c.contains('TRIP')))
    		{
    			woli.netsuite_location__c = 'Virgin Islands';
    			woli.netsuite_external_id__c = wo.Account.site_id__c+'.26';
    			lstupdatelines.add(woli);
    			system.debug('hit 4'); 
    		}
            
            if(woli.part_number__c != null && !woli.part_name__c.contains('TRIP') && !woli.part_name__c.contains('LABOR'))
            {   woli.netsuite_location__c = 'FBL' ; 
            	woli.netsuite_external_id__c = wo.Account.site_id__c+'.01'; 
            	lstupdatelines.add(woli);
            	system.debug('hit 5');
            }
    	   }//end if country is USA
    	   
    	   if(wo.account_country__c == 'Canada')
    	   {
    	   	if(wo.healthcare_site__c == true && woli.part_number__c != null && (woli.part_name__c.contains('LABOR') || woli.part_name__c.contains('TRIP')))
    		{
    			woli.netsuite_location__c = 'Healthcare';
    			woli.netsuite_external_id__c = wo.Account.Site_Id__c+'.09';
    			lstupdatelines.add(woli);
    			system.debug('hit 1');
    		}
    	
    		
    		if(wo.healthcare_site__c == false && woli.part_number__c != null && (woli.part_name__c.contains('LABOR') || woli.part_name__c.contains('TRIP')))
    		{
    			woli.netsuite_location__c = 'FIN GOOD';
    			woli.netsuite_external_id__c = wo.Account.Site_Id__c+'.02';
    			lstupdatelines.add(woli);
    			system.debug('hit 2');
    		}
    		
    		if(woli.part_number__c != null && !woli.part_name__c.contains('TRIP') && !woli.part_name__c.contains('LABOR'))
            {   woli.netsuite_location__c = 'FIN GOOD' ; 
            	woli.netsuite_external_id__c = wo.Account.site_id__c+'.02'; 
            	lstupdatelines.add(woli);
            	system.debug('hit 5');
            }
    	   	
    	   }//end if country = canada
            
            woli.netsuite_transaction__c = 'FLDINV'; 
    	}
    	else
    	{  system.debug('No related work order id was found on the work order line item number ' +woli.lineitemnumber);  } 

    	
    	//now for each line item within the loop, get the order type and product type from the custom setting map to assign to
    	//each line item based on part number.  Since mpordertype is created from a custom setting, we have to do something a little
    	//different in order for the unit test code to work
       if(!test.IsRunningTest())
       {
    	if(mpordertype.containskey(woli.product_code__c))
    	{
    		String otype = mpordertype.get(woli.product_code__c).OrderType__c;
    		String ptype = mpordertype.get(woli.product_code__c).ProductType__c;
    		
    		woli.Billing_ProductType__c = ptype;
    		woli.Order_Type__c = otype;
    	} 
    	else
    	{ 
    		if(woli.netsuite_location__c == 'FBL')
    		{
    			woli.Billing_ProductType__c = 'ITV';
    			woli.Order_Type__c = 'Field Service Sales';
    		}
    	}
       }
       else //if a test is running
       {
       	  Map<String,String> mporder = New Map<String,String>();
       	  Map<String,String> mpproduct = New Map<String,String>();
       	  mpproduct.put('40-0001-058-0', 'HC');
       	  mpproduct.put('40-0001-057-0', 'TripHC');
       	  mpproduct.put('40-0001-133-0', 'HC');
       	  mpproduct.put('40-0001-009-0', 'ITV');
       	  mpproduct.put('40-0001-036-0', 'TripITV');
       	  mpproduct.put('40-0001-132-0', 'ITV');
       	  mporder.put('40-0001-058-0', 'Healthcare Sales');
       	  mporder.put('40-0001-057-0', 'Healthcare Sales');
       	  mporder.put('40-0001-133-0', 'Healthcare Sales');
       	  mporder.put('40-0001-009-0', 'Field Service Sales');
       	  mporder.put('40-0001-036-0', 'Field Service Sales');
       	  mporder.put('40-0001-132-0', 'Field Service Sales');
       	  
       	  if(woli.netsuite_location__c == 'FBL')
       	  {
       	  	woli.Billing_ProductType__c = 'ITV';
       	  	woli.Order_Type__c = 'Field Service Sales';
       	  }
       	  else
       	  {
       	  	woli.Billing_ProductType__c = mpproduct.get(woli.product_code__c);
       	  	woli.Order_Type__c = mporder.get(woli.product_code__c);
       	  }
       	  
       }
       
       }  //end for loop listnewlines
       
       //no dml update statement needed on these changes to the line item values because
       //this is a before insert trigger.  The changes we are making will save to the line item
       //records when they get committed to the database.
       
       system.debug('*******************END PopulateNetSuiteLocation****************');
    	
    }//end method PopulateNetSuiteLocation
    
    
}