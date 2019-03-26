public with sharing class StandardSubscriptionTriggerLogic {
	
	static List<Order_Item__c> lstorderitems = New List<Order_Item__c>();
	static List<SBQQ__Subscription__c> lstlcliprodparents = New List<SBQQ__Subscription__c>();
	static List<SBQQ__Subscription__c> lstallchildlines = New List<SBQQ__Subscription__c>(); //all children of product parent lines
	
	public static void GetAllOrderItems(List<SBQQ__Subscription__c> triggernewlclilist)
	{
		Set<Id> lcliids = New Set<Id>();
		List<Order_Item__c> lstitems = New List<Order_Item__c>();
		
		for(SBQQ__Subscription__c lcli : triggernewlclilist)
		{  lcliids.add(lcli.id);  }
		
		lstorderitems = [ Select Id, Name, project_type__c, price__c, quantity__c, unit_selling_price_USD__c, unit_selling_price__c, total_rooms_ordered__c, 
		                  subscription__c, equipment_ownership__c, price_USD__c from Order_Item__c where subscription__c in :lcliids ];
		
		//for(Order_Item__c oitem : lstorderitems)
		//{  system.debug(' order item queried in GetallOrderItems is ' +oitem.Name +', ' +oitem.quantity__c +', ' +oitem.project_type__c );  }
		
    }
	
	public static void GetAllProductParents(List<SBQQ__Subscription__c> triggernewlist, Map<Id,SBQQ__Subscription__c> mptriggerold)
	{
		Set<Id> lcliids = New Set<Id>();
			
		for(SBQQ__Subscription__c cli : triggernewlist)
		{
            if(cli.Name__c.Contains('Product Parent'))
			{ lcliids.add(cli.id);  }
		    else if(cli.product_parent_id__c != null)
		    {  lcliids.add(cli.product_parent_id__c);  }
		}
		
		if(!lcliids.IsEmpty())
		{
			lstlcliprodparents = [ Select Id, Name__c, equipment_ownership__c, status__c, sbqq__quantity__c, project_type__c, sbqq__contract__c from SBQQ__Subscription__c
		                        where id in :lcliids ];  
		
	                  
			lstallchildlines = [ Select Id, Name__c, project_type__c, equipment_ownership__c, product_parent_id__c from SBQQ__Subscription__c where
		                     product_parent_id__c in :lcliids ];  
		}
		                     
		//for(SBQQ__Subscription__c childcli : lstallchildlines)
		//{ system.debug('child lines are ' +childcli.Name +', ' +childcli.Id +', ' +childcli.product_parent_id__c );  }
		                     
		//now that we have a product parent with all its child lines, update certain fields on the child lines
		//if they were changed on the parent
		
		UpdateFieldsonChildLineItems(mptriggerold);
	
	}
	
	
	//if ownership or project type has changed on product parent lines, update all the child lines also
	public static void UpdateFieldsonChildLineItems(Map<Id,SBQQ__Subscription__c> mpoldtrigger)
	{
		system.debug('**********************BEGIN UpdateFieldsonChildLineItems**************************');
		
		Map<Id,SBQQ__Subscription__c> mpchangedprojecttype = New Map<Id,SBQQ__Subscription__c>();
		Map<Id,SBQQ__Subscription__c> mpchangedequipment = New Map<Id,SBQQ__Subscription__c>();
		Map<Id,SBQQ__Subscription__c> mpallprodparents = New Map<Id,SBQQ__Subscription__c>();
		List<SBQQ__Subscription__c> lstupdatechildlines = New List<SBQQ__Subscription__c>();
		
	 if(lstlcliprodparents.size() > 0)
	 {
		for(SBQQ__Subscription__c ppcli : lstlcliprodparents)
		{
			if(ppcli.project_type__c != null && mpoldtrigger.containskey(ppcli.id))
			{
			  if(ppcli.project_type__c != mpoldtrigger.get(ppcli.id).project_type__c)
			  {  mpchangedprojecttype.put(ppcli.id,ppcli);  }
			}
	
			
			if(ppcli.equipment_ownership__c != null && mpoldtrigger.containskey(ppcli.id))
			{  
				if(ppcli.equipment_ownership__c != mpoldtrigger.get(ppcli.id).equipment_ownership__c)
			    {  mpchangedequipment.put(ppcli.id,ppcli);  }
			}
			system.debug('mpchangedprojecttype size is ' +mpchangedprojecttype.size());
			system.debug('mpchangedequipment size is ' +mpchangedequipment.size());
			
			mpallprodparents.put(ppcli.Id,ppcli); //make a map of all prod parents to populate these fields
			                                      //on child lines that don't have values even if parent hasn't changed
		}
		
	 }
	 
	 if(lstallchildlines.size() > 0 )
	 {
		
		for(SBQQ__Subscription__c clichild : lstallchildlines)
		{
			Boolean recupdate = false;	
					
			if(mpchangedprojecttype.size() > 0 && mpchangedprojecttype.containskey(clichild.product_parent_id__c))
			{  clichild.project_type__c = mpchangedprojecttype.get(clichild.product_parent_id__c).project_type__c;
			   recupdate = true;
			}
			else if(clichild.project_type__c == null && mpallprodparents.containskey(clichild.product_parent_id__c) && 
			       mpallprodparents.get(clichild.product_parent_id__c).project_type__c != null)
			{  clichild.project_type__c = mpallprodparents.get(clichild.product_parent_id__c).project_type__c;
			   recupdate = true;
			}
			
			if(mpchangedequipment.size() > 0 && mpchangedequipment.containskey(clichild.product_parent_id__c))
			{  clichild.equipment_ownership__c = mpchangedequipment.get(clichild.product_parent_id__c).equipment_ownership__c;  
			   recupdate = true;
			}
			else if(clichild.equipment_ownership__c == null && mpallprodparents.containskey(clichild.product_parent_id__c)
			         && mpallprodparents.get(clichild.product_parent_id__c).equipment_ownership__c != null)
			{
				clichild.equipment_ownership__c = mpallprodparents.get(clichild.product_parent_id__c).equipment_ownership__c;
				recupdate = true;         	
			}
			
			if(recupdate == true)
			{  lstupdatechildlines.add(clichild);  } 
			
		}//end for loop lstallchildren
	 }
		
		if(lstupdatechildlines.size() > 0)
		{
			try{ update lstupdatechildlines;  }
			catch(Exception ex)
			{ system.debug('ERROR in StandardLegalCLILogic.UpdateFieldsonChildLineItems:  ' +ex.getMessage());  }
		}
		
		system.debug('************************END UpdateFieldsonChildLineItems*************************');
		
		
	}//end UpdateFieldsonChildLineItems
	
	
	//jjackson 5/30/2014 update certain fields on order items when changes are made on the legal contract line item
    public static void UpdateRelatedOrderItems(List<SBQQ__Subscription__c> contritmlist, Map<Id,SBQQ__Subscription__c> trigoldmap)
    {   
    	
    	system.debug('**************************BEGIN UpdateRelatedOrderItems**************************');
    	
    	MAP<ID,SBQQ__Subscription__c> mpprodparent = new Map<ID,SBQQ__Subscription__c>();
       	MAP<Id,SBQQ__Subscription__c> mpallcli = New Map<Id,SBQQ__Subscription__c>();
       	Map<Id,Id> mplineitemtoprodparent = New Map<Id,Id>();
     	String projecttype;
    	Id contractid;
    	List<Order_Item__c> updtdorderitems = new List<Order_Item__c>();
    	Set<ID> lineids = new set<Id>();
    	Set<Id> setids = new Set<Id>();
  	    Map<Id,SBQQ__Subscription__c> lclimap = new Map<Id,SBQQ__Subscription__c>();
  	    Map<Id,SBQQ__Subscription__c> lcliequipmap = new Map<Id,SBQQ__Subscription__c>();
  	    List<Order_Item__c> lstrelatedoi = new List<Order_Item__c>();
  	    List<Order_Item__c> lstupdorderitem = new List<Order_Item__c>();
      //	system.debug('contract item list is ' + contritmlist);
      	for(SBQQ__Subscription__c conitem : contritmlist)  //make a set of all the contract line item id's related to the line items
    	{
    		lineids.add(conitem.Id);
    		mpallcli.put(conitem.Id,conitem); //add all the contract line items to one map
    		
    		//system.debug('equipment ownership in the trigger is ' +conitem.equipment_ownership__c);
    		//system.debug('old equipment ownership is ' +trigoldmap.get(conitem.id).equipment_ownership__c);
    		//system.debug('project type in the trigger is ' +conitem.project_type__c);
    		//system.debug('old project type is ' +trigoldmap.get(conitem.id).project_type__c);
    		
    		if(conitem.project_type__c != null && (conitem.project_type__c != trigoldmap.get(conitem.id).project_type__c))
  			{
   			    lclimap.put(conitem.Id,conitem);  //if the line item's project type has changed, add to the map
   			    system.debug('change in project type, adding line item to map lclimap');
  			}
  			
  			if(conitem.equipment_ownership__c != null && (conitem.equipment_ownership__c != trigoldmap.get(conitem.id).equipment_ownership__c))
  			{
  				lcliequipmap.put(conitem.id,conitem); //if the equipment ownership has changed on the line item, put it in the map
  				system.debug('change in equipment ownership, adding line item to map lcliequipmap');
  			}
  			
   		}//end for contritmlist (trigger.new)
   		
    	//Match the order item to the contract line item and set the project type on the order item
    	//jjackson 4/2016: compare the quantity/price from the contract line item to the order item to see if an update needs to be done
    	for(Order_Item__c orderitem : lstorderitems)
    	{
    		Boolean recupdate = false;
    		Decimal lcliprice;
    		Decimal lcliqty;
    		if(mpallcli.containskey(orderitem.subscription__c))
    		{
    				lcliprice = mpallcli.get(orderitem.subscription__c).sbqq__regularprice__c;
    	    		lcliqty = mpallcli.get(orderitem.subscription__c).sbqq__quantity__c;
    		}
			
			if(lclimap.size() > 0 && lclimap.containskey(orderitem.subscription__c)) 		
    		{
    			String getprojecttype = lclimap.get(orderitem.subscription__c).project_type__c;
    			system.debug('getprojecttype is ' +getprojecttype +'for contract line item ' +lclimap.get(orderitem.subscription__c).Name__c);
    			if(getprojecttype != null||getprojecttype != '')
    			{
    				orderitem.Project_Type__c = getprojecttype;
    				recupdate = true;
    			}
    			
    		}
    		
    		
    		system.debug('UpdateRelatedOrderItems now updating prices and quantiies on order items.');
    			
    	    if(mpallcli.containskey(orderitem.subscription__c))
    	    {
    	    	if(orderitem.quantity__c == null || orderitem.quantity__c != lcliqty)
    	    	{
    	    		orderitem.quantity__c = lcliqty;
    	    		recupdate = true;
    	    	}
    	    	
    	    	if(orderitem.total_rooms_ordered__c == null || orderitem.total_rooms_ordered__c != lcliqty)
    	    	{
    	    		orderitem.total_rooms_ordered__c = lcliqty;
    	    		recupdate = true;
    	    	}
    	    	
    	    	if(orderitem.price__c == null || orderitem.price__c != lcliprice)
    	    	{   orderitem.price__c = lcliprice;
    	    		recupdate = true;
    	    	}
    	    	
    	    	if(orderitem.unit_selling_price__c == null || orderitem.unit_selling_price__c != lcliprice)
    	    	{   orderitem.unit_selling_price__c = lcliprice;
    	    		recupdate = true;
    	    	}
    	    	
    	    	if(orderitem.price_USD__c == null || orderitem.price_USD__c != lcliprice)
    	    	{   orderitem.price_usd__c = lcliprice;
    	    		recupdate = true;
    	    	}
    	    	
    	    	if(orderitem.unit_selling_price_USD__c == null || orderitem.unit_selling_price_USD__c != lcliprice)
    	    	{   orderitem.unit_selling_price_USD__c = lcliprice;
    	    		recupdate = true;
    	    	}
    	    }//end if mpallcli contains key
    	    
    	    //update equipment ownership if it was changed on the contract line item
    	    if(lcliequipmap.size() > 0 && lcliequipmap.containskey(orderitem.subscription__c))
    	    {
    	    	  orderitem.equipment_ownership__c = lcliequipmap.get(orderitem.subscription__c).equipment_ownership__c;
    	    	  recupdate = true;
      	    }
    	    
    	    if(recupdate == true)
    	    { updtdorderitems.add(orderitem);  }
      	} //end order items for loop
       
  
    	//system.debug('Order items updated '+orderitems);
       if(updtdorderitems.size() > 0)
       {
 		 Savepoint sp = Database.setSavepoint();
		 try
		 {
		     update updtdorderitems;

		 }
		 catch(Exception e)
		 { 
		 	Utilities.writeLog('Error in UpdateOrderItemProjectType: '+e.getMessage(), StandardLegalCLILogic.class, 'UpdateOrderItemProjectType', LoggingLevel.DEBUG);
		 	Database.Rollback(sp); 
		 }
       }  //if updtdorderitems.size > 0
      system.debug('***********************END UpdateRelatedOrderItems******************************');
    	
    } // end UpdateRelatedOrderItems

    /*
    	jjackson 9/2018 -- commented out for CPQ because that is not using conversion dates
    public static void updateConversionDate(List<SBQQ__Subscription__c> newList){
        //System.debug('Entering updateConversionDate method...');
        //System.debug('Looking at ' + newList.size() + ' records');
        
        //initialize variables
        Map<Id, Contract__c> id2ContractMap = new Map<id, Contract__c>();
        Set<Id> contractIds = new Set<Id>();
        Set<Integer> cliPos = new Set<Integer>();
        
        for(Integer i = 0; i < newList.size();i++){
            if(newList[i].Conversion_Date__c == null){
                if(newList[i].Legal_Contract__c != null){
                    contractIds.add(newList[i].Legal_Contract__c);
                    cliPos.add(i);
                }
            }
        }
        
        //make a map of the legal contract
        id2ContractMap = new Map<Id, Contract__c>([SELECT id, Conversion_Date__c FROM Contract__c WHERE id IN :contractIds]);
        
        //update the conversion date of the contract line items
        for(Integer i : cliPos){
            if(id2ContractMap.get(newList[i].Legal_Contract__c).Conversion_Date__c != null){
                newList[i].Conversion_Date__c = id2ContractMap.get(newList[i].Legal_Contract__c).Conversion_Date__c;
            }
        }
    } */
    
    //jjackson 8/2016:  made a correction so that product inventory items won't get term start/end dates unless they are at Billing,Installed Activated,
    //or Pending De-Installation; also added code to update the auto renew field on the product inventory item
    //jjackson 4/2016 this method used to update assets, entitlements and service contracts.  Now entitlements and service contracts
    //are being updated based on contract changes (not line item changes). This code now only updates related product inventory line items.
    public static void updateRelatedObjects(Map<Id,SBQQ__Subscription__c> triggerNewMap, String triggertype){
	    system.debug('*******************************BEGIN StandardSubscriptionTriggerLogic.updateRelatedObjects' +triggertype +'**********************');

		List<Asset> aUpdate = new List<Asset>();
		List<Asset> lstrelatedass = new List<Asset>();
		Asset myasset = New Asset();
		Set<String> dateupdatestatus = New Set<String>();
		dateupdatestatus.add('Billing');
		dateupdatestatus.add('Installed Activated');
		dateupdatestatus.add('Pending De-Installation');
	
	if(triggerNewMap.size() > 0)
	{
		//get the non-cancelled/non-de_installed product inventory line items related to the contract line items
		lstrelatedass = [Select term_start_date__c, status, term_end_date__c, subscription_item__c, id, name,
						 quantity, price__c, term__c, service_start_date__c, service_end_date__c, auto_renew__c
		                 from Asset where subscription_item__c in :triggerNewMap.keyset() AND
		                 status not in ('Cancelled', 'De-Installed') ];
		
		//if the contract line item in the trigger has a different term start/end date than what's on the asset, set the date on the asset                 
		for(Asset pi : lstrelatedass)
		{
		  if(triggerNewMap.containskey(pi.subscription_item__c))
		  {
		  	
		  	 Date termstart = triggerNewMap.get(pi.subscription_item__c).sbqq__startdate__c;
		  	 Date termend = triggerNewMap.get(pi.subscription_item__c).sbqq__enddate__c;
		  	 Boolean recupdated = false;
		  	 
		  	 //system.debug('termstart is ' +termstart);
		  	 //system.debug('termend is ' +termend);
			
			if(dateupdatestatus.Contains(pi.status))
			{  	 
		  	 if(pi.term_start_date__c == null && termstart != null)
		  	 { pi.term_start_date__c = termstart;  
	 	 	   recupdated = true;
	 	     }
		  	 
		  	 if(pi.term_start_date__c !=null && termstart != null && pi.term_start_date__c != termstart)
		  	 { pi.term_start_date__c = termstart;  
		  	   recupdated = true;
		  	 }
		  	 
		  	 if(pi.term_end_date__c == null && termend != null)
		  	 { pi.term_end_date__c = termend;  
		  	   recupdated = true;
		  	 }
		  	 
		  	 if(pi.term_end_date__c != null && termend != null && pi.term_end_date__c != termend)
		  	 { pi.term_end_date__c = termend;  
		  	   recupdated = true;
		  	 }
	
		  	 if(pi.service_end_date__c == null && termend != null)
		  	 { pi.service_end_date__c = termend;
		  	   recupdated = true;
		  	 }
		  	 
		  	 if(pi.service_end_date__c != null && (pi.service_end_date__c != termend))
		  	 { pi.service_end_date__c = termend;
		  	   recupdated = true;
		  	 }
		  	 
		  	 //the service start date on the asset should populate when the install work order billing is approved but
		  	 //just in case that didn't happen and the service start date value is blank, set it to the term start date
			 if(pi.service_start_date__c == null)
			 { pi.service_start_date__c = termstart;
			   recupdated = true;
			 }
			}//end if dateupdatestatus
			
		  	 if(pi.quantity == null || pi.quantity != null && pi.quantity != triggerNewMap.get(pi.subscription_item__c).SBQQ__quantity__c)
		  	 { pi.quantity = triggerNewMap.get(pi.subscription_item__c).sbqq__quantity__c;
		  	   recupdated = true;
		  	 }
		  	 
		  	 if(pi.price__c == null || pi.price__c != null && pi.price__c != triggerNewMap.get(pi.subscription_item__c).sbqq__regularprice__c)
		  	 {
		  	 	pi.price__c = triggerNewMap.get(pi.subscription_item__c).sbqq__regularprice__c;
		  	 	recupdated = true;
		  	 }
		  	 
		  
		  	 if(pi.auto_renew__c == false && triggerNewMap.get(pi.subscription_item__c).auto_renew__c == true)
		  	 {
		  	 	pi.auto_renew__c = true;
		  	 	recupdated = true;
		  	 }
		  	 
		  
		  	 system.debug('recupdated boolean in UpdateRelatedObject = ' +recupdated) ;
		  	 
		  	 if(recupdated == true)
		  	 {  aUpdate.add(pi);  
		  	 	//system.debug('asset added to aUpdate list is ' +pi.Name +', ' +pi.term_end_date__c);
		  	 }
		  	 
		  	
			 //system.debug('term start date for asset ' +pi.name +' is ' +termstart);
			 //system.debug('term end for asset ' +pi.name +' is ' +termend);
			 //system.debug('quantity for asset ' +pi.name +' is' +pi.quantity);
			 //system.debug('price for asset ' +pi.name +' is ' +pi.price__c);	
			 
			 
		  }
	   			
		} //end for lstrelatedass 
	}//end if      

		system.debug('aUpdate size is ' +aUpdate.size());

 		 if(aUpdate.size() > 0)
		 {
		 	try
		 	{ update aUpdate;  }
		 	catch(Exception e)
		 	{ system.debug('Error in StandardSubscriptionTriggerLogic.updateRelatedObjects: ' +e.getMessage());  }
		 	
		 }
		 
		// Asset getasset = [Select Id, Name, term_end_date__c from Asset where id = :myasset.id LIMIT 1];
		 
		// system.debug('getasset term_end_date__c is ' +getasset.term_end_date__c + ', ' +getasset.name);
		 
		 system.debug('********************END updateRelatedObjects  ' +triggertype +'  **************************');
	    
  } //end updateRelatedObjects method
	
  public static void rollUpChannelSummary(List<SBQQ__Subscription__c> cliList)
  {
  	system.debug('***************************BEGIN STANDARDSUBSCRIPTIONTRIGGERLOGIC.ROLLUPCHANNELSUMMARY*************************');
    
    Set<String> parentcliIds = new Set<String>();
    for(SBQQ__Subscription__c cli : cliList)
    {
      if(cli.Product_Parent_Id__c != null)
      {
          parentcliIds.add(cli.Product_Parent_Id__c); 
          system.debug('product parent id added is ' +cli.product_parent_id__c);
      }
    }
    
    List<SBQQ__Subscription__c> childclis = New List<SBQQ__Subscription__c>();
    
    
    if(parentcliIds != null)
    {
    	childclis = [SELECT Id, Name__c, Product_Parent_Id__c,SBQQ__Product__r.Channel_Type__c, sbqq__product__r.family, status__c
                     FROM SBQQ__Subscription__c 
    	             WHERE Product_Parent_Id__c != null AND product_parent_id__c IN :parentcliIds
    	               //shawks Post-CPQ Imp - Need to find the family of the FTG Product Parent
                       AND (sbqq__product__r.family = 'FTG'
                         OR parent__r.sbqq__product__r.family = 'FTG'
                         OR parent__r.parent__r.sbqq__product__r.family = 'FTG'
                         OR parent__r.parent__r.parent__r.sbqq__product__r.family = 'FTG'
                         OR parent__r.parent__r.parent__r.parent__r.sbqq__product__r.family = 'FTG')
                       AND (Status__c = 'Installed Activated' OR Status__c = 'Pending Installation Activate' OR Status__c = 'Pending De-Installation')];
    }
    //Create map of parent cli id to list of child clis
    Map<Id,List<SBQQ__Subscription__c>> parentcliMap = new Map<Id,List<SBQQ__Subscription__c>>();

    if(childclis.size() > 0)
    {
 
    	for(SBQQ__Subscription__c cli : childclis)
    	{
      		if(parentcliMap.containsKey(cli.Product_Parent_Id__c))
      		{
        		parentcliMap.get(cli.Product_Parent_Id__c).add(cli);
      		}
      		else
      		{
        		List<SBQQ__Subscription__c> temp = new List<SBQQ__Subscription__c>();
        		temp.add(cli);
        		parentcliMap.put(cli.Product_Parent_Id__c,temp);
      		}
     // system.debug('line item in the loop is ' +cli.name + ', ' +cli.product_parent_id__c);
    	}
    }
      //Loop through list of clis
    List<SBQQ__Subscription__c> parentcliList = new List<SBQQ__Subscription__c>();
   
    if(parentcliMap.size() > 0)
    {
    	for(Id parentcliId : parentcliMap.keyset())
    	{
      		Integer HD = 0;
      		Integer SD = 0;
      		Integer Analog = 0;
      		for(SBQQ__Subscription__c cli : parentcliMap.get(parentcliId))
      		{
        		if(cli.SBQQ__Product__r.Channel_Type__c == 'HD')
          		{	HD ++;  }
        		else if(cli.SBQQ__Product__r.Channel_Type__c == 'SD')
          		{  SD ++;  }
        		else if(cli.SBQQ__Product__r.Channel_Type__c == 'Analog')  
         		{  Analog++;  }
      		}
      		SBQQ__Subscription__c temp = new SBQQ__Subscription__c(Id = parentcliId);
      		temp.HD_Channel_Count__c = HD;
      		temp.SD_Channel_Count__c = SD;
      		temp.Analog_Channel_Count__c = Analog;
      		parentcliList.add(temp);
    	 }
    }

    if(parentcliList.size() > 0)
    {
    	try
    	{  update parentcliList;  }
    	catch(Exception ex)
    	{  system.debug('Error updating channel counts in RollupChannelSummary: ' +ex.getMessage());  }
    }
    
    system.debug('*******************END STANDARDSUBSCRIPTIONTRIGGERLOGIC.ROLLUPCHANNELSUMMARY*********************************');
  }  
  
  public static void PopulateProductParentIdField(List<SBQQ__Subscription__c> triggernewlist)
  {
  		system.debug('***********BEGIN POPULATEPRODUCTPARENTIDFIELD****************');
  		system.debug('triggernewlist size is ' +triggernewlist.size());
  	   Set<Id> conids = New Set<Id>();
  	   List<SBQQ__Subscription__c> lstupdsubs = New List<SBQQ__Subscription__c>();
  	   List<SBQQ__Subscription__c> lstprodparents = New List<SBQQ__Subscription__c>();
  	   List<SBQQ__Subscription__c> lstsubs = New List<SBQQ__Subscription__c>();
  	   Map<Id, SBQQ__Subscription__c> mpprodparent = New Map<Id,SBQQ__Subscription__c>();
  	   Boolean hasid = true;
  

  	   for(SBQQ__Subscription__c s : triggernewlist)
  	   {
  	   	  if(s.product_parent_id__c == null )
  	   	  { conids.add(s.sbqq__contract__c);
  	   	    hasid = false;  
  	   	  }

  	   }
  	   
  	   system.debug('conids size is ' +conids.size());
  	   
  	   if(conids.size() > 0)
  	   {
  	   		lstprodparents = [Select sbqq__contract__c, id, parent__c, parent__r.parent__c, product_parent_id__c,
  	                     parent__r.parent__r.parent__c, sbqq__product__r.name from SBQQ__Subscription__c where
  	                     sbqq__contract__c in :conids AND (product_parent_id__c = null OR (sbqq__product__r.name like '%Product Parent'))];
  	   }                  
  	   system.debug('lstprodparents size is ' +lstprodparents.size());
  	   
  	   
  	 if(lstprodparents.size() > 0)
  	 {
  	   for(sbqq__subscription__c sub :lstprodparents)
  	   {
  	   	   if(sub.sbqq__product__r.name.contains('Product Parent'))
  	   	   { mpprodparent.put(sub.id, sub);  }
  	   }
  	   
  	   system.debug('mpprodparent size is ' +mpprodparent.size());
  	   
  	   for(sbqq__subscription__c s :lstprodparents)
  	   {
  	   		system.debug(s.sbqq__product__r.name +', ' +s.parent__c);
  	   		system.debug(s.sbqq__product__r.name +', ' +s.parent__r.parent__c);
  	   		system.debug(s.sbqq__product__r.name +', ' +s.parent__r.parent__r.parent__c);
  	   		system.debug(s.sbqq__product__r.name +', ' +s.parent__r.parent__r.parent__c);
  	   		
  	   		for(Id key :mpprodparent.keyset())
  	   		{
  	   			system.debug('key is ' +key);
  	   			
  	   			if(s.parent__c != null && s.parent__c == key && !lstupdsubs.contains(s))
  	   			{
  	   				s.product_parent_id__c = key;
  	   				lstupdsubs.add(s);
  	   			}
  	   			else if(s.parent__r.parent__c != null && s.parent__r.parent__c == key && !lstupdsubs.contains(s))
  	   			{
  	   				s.product_parent_id__c = key;
  	   				lstupdsubs.add(s);
  	   			}
  	   			else if(s.parent__r.parent__r.parent__c != null && s.parent__r.parent__r.parent__c == key &&
  	   			         !lstupdsubs.contains(s))
  	   			{
  	   				s.product_parent_id__c = key;
  	   				lstupdsubs.add(s);
  	   			}
  	   		
  	   			SBQQ__Subscription__c sub = mpprodparent.get(key);
  	   			sub.product_parent_id__c = sub.id;
  	   			if(!lstupdsubs.contains(sub))	
  	   			{	lstupdsubs.add(sub);  }
  	   		}
  	   		
  	   		
  	   }
  	 }
  	   	if(lstupdsubs.size()>0)
  	   	{  update lstupdsubs; }
  	                                         
  	   
  	   
  	   system.debug('**************end POPULATEPRODUCTPARENTIDFIELD********');
  }                                       
    
}