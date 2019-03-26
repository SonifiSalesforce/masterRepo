/*LOG
	shawks 02/2019 - CPQ: Comment out all since not needed after using out-of-box Subscription object

	jjackson 4/2016:  made a lot of code changes because the original code was written poorly.  Added "global"
	lists that are populated by the GetAllOrderItems and GetAllProductParents methods.  Then those can be
	used by the rest of the class as needed without having to requery the same objects a bunch of times.  Updated
	code so that when certain things change on product parent line items (equipment ownership and project type), the
	child line items automatically update with the new values.  Updated code so that these changes also update the
	project type and equipment ownership values on related order items.  Updated code so that line item quantity
	and price are written to related order items and related product inventory line items.
	
	jjackson 4/2016 BUG-00589 When term start/end dates are added to contract line items, populate the related
	product inventory line items as well.  While fixing this functionality I removed all the old code that used to
	update entitlements and service contracts.  That code now runs when start/end dates are changed on the legal contract.
	
	jjackson 9/2015 Service Max Project:  Add equipment ownership from contract line item product parents to
	the related order item.  This must be done with code because there is no relationship from contract line item
	to order item, only the other way around.

*/


public with sharing class StandardLegalCLILogic {
/*shawks CPQ comment out start
	static List<Order_Item__c> lstorderitems = New List<Order_Item__c>();
	static List<Contract_Line_Item__c> lstlcliprodparents = New List<Contract_Line_Item__c>();
	static List<Contract_Line_Item__c> lstallchildlines = New List<Contract_Line_Item__c>(); //all children of product parent lines
	
	public static void GetAllOrderItems(List<Contract_Line_Item__c> triggernewlclilist)
	{
		Set<Id> lcliids = New Set<Id>();
		List<Order_Item__c> lstitems = New List<Order_Item__c>();
		
		for(Contract_Line_Item__c lcli : triggernewlclilist)
		{  lcliids.add(lcli.id);  }
		
		lstorderitems = [ Select Id, Name, project_type__c, price__c, quantity__c, unit_selling_price_USD__c, unit_selling_price__c, total_rooms_ordered__c, 
		                  legal_contract_line_item__c, equipment_ownership__c, price_USD__c from Order_Item__c where legal_contract_line_item__c in :lcliids ];
		
		//for(Order_Item__c oitem : lstorderitems)
		//{  system.debug(' order item queried in GetallOrderItems is ' +oitem.Name +', ' +oitem.quantity__c +', ' +oitem.project_type__c );  }
		
    }
	
	public static void GetAllProductParents(List<Contract_Line_Item__c> triggernewlist, Map<Id,Contract_Line_Item__c> mptriggerold)
	{
		Set<Id> lcliids = New Set<Id>();
			
		for(Contract_Line_Item__c cli : triggernewlist)
		{
			if(cli.Name.Contains('Product Parent'))
			{ lcliids.add(cli.id);  }
		    else
		    {  lcliids.add(cli.product_parent_id__c);  }
		}
		
		lstlcliprodparents = [ Select Id, Name, equipment_ownership__c, status__c, quantity__c, project_type__c, legal_contract__c from Contract_Line_Item__c
		                        where id in :lcliids ];  
		
	                  
		lstallchildlines = [ Select Id, Name, project_type__c, equipment_ownership__c, product_parent_id__c from Contract_Line_Item__c where
		                     product_parent_id__c in :lcliids ];  
		                     
		//for(Contract_Line_Item__c childcli : lstallchildlines)
		//{ system.debug('child lines are ' +childcli.Name +', ' +childcli.Id +', ' +childcli.product_parent_id__c );  }
		                     
		//now that we have a product parent with all its child lines, update certain fields on the child lines
		//if they were changed on the parent
		
		UpdateFieldsonChildLineItems(mptriggerold);
	
	}
	
	
	//if ownership or project type has changed on product parent lines, update all the child lines also
	public static void UpdateFieldsonChildLineItems(Map<Id,Contract_Line_Item__c> mpoldtrigger)
	{
		system.debug('**********************BEGIN UpdateFieldsonChildLineItems**************************');
		
		Map<Id,Contract_Line_Item__c> mpchangedprojecttype = New Map<Id,Contract_Line_Item__c>();
		Map<Id,Contract_Line_Item__c> mpchangedequipment = New Map<Id,Contract_Line_Item__c>();
		Map<Id,Contract_Line_Item__c> mpallprodparents = New Map<Id,Contract_Line_Item__c>();
		List<Contract_Line_Item__c> lstupdatechildlines = New List<Contract_Line_Item__c>();
		
		
		for(Contract_Line_Item__c ppcli : lstlcliprodparents)
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
		
		for(Contract_Line_Item__c clichild : lstallchildlines)
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
		
		if(lstupdatechildlines.size() > 0)
		{
			try{ update lstupdatechildlines;  }
			catch(Exception ex)
			{ system.debug('ERROR in StandardLegalCLILogic.UpdateFieldsonChildLineItems:  ' +ex.getMessage());  }
		}
		
		system.debug('************************END UpdateFieldsonChildLineItems*************************');
		
		
	}//end UpdateFieldsonChildLineItems
	
	
	//jjackson 5/30/2014 update certain fields on order items when changes are made on the legal contract line item
    public static void UpdateRelatedOrderItems(List<Contract_Line_Item__c> contritmlist, Map<Id,Contract_Line_Item__c> trigoldmap)
    {   
    	
    	system.debug('**************************BEGIN UpdateRelatedOrderItems**************************');
    	
    	MAP<ID,Contract_Line_Item__c> mpprodparent = new Map<ID,Contract_Line_Item__c>();
       	MAP<Id,Contract_Line_Item__c> mpallcli = New Map<Id,Contract_Line_Item__c>();
       	Map<Id,Id> mplineitemtoprodparent = New Map<Id,Id>();
     	String projecttype;
    	Id contractid;
    	List<Order_Item__c> updtdorderitems = new List<Order_Item__c>();
    	Set<ID> lineids = new set<Id>();
    	Set<Id> setids = new Set<Id>();
  	    Map<Id,Contract_Line_Item__c> lclimap = new Map<Id,Contract_Line_Item__c>();
  	    Map<Id,Contract_Line_Item__c> lcliequipmap = new Map<Id,Contract_Line_Item__c>();
  	    List<Order_Item__c> lstrelatedoi = new List<Order_Item__c>();
  	    List<Order_Item__c> lstupdorderitem = new List<Order_Item__c>();
      //	system.debug('contract item list is ' + contritmlist);
      	for(Contract_Line_Item__c conitem : contritmlist)  //make a set of all the contract line item id's related to the line items
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
    		if(mpallcli.containskey(orderitem.legal_contract_line_item__c))
    		{
    				lcliprice = mpallcli.get(orderitem.legal_contract_Line_item__c).price__c;
    	    		lcliqty = mpallcli.get(orderitem.legal_contract_line_item__c).quantity__c;
    		}
			
			if(lclimap.size() > 0 && lclimap.containskey(orderitem.legal_contract_line_item__c)) 		
    		{
    			String getprojecttype = lclimap.get(orderitem.legal_contract_line_item__c).project_type__c;
    			system.debug('getprojecttype is ' +getprojecttype +'for contract line item ' +lclimap.get(orderitem.legal_contract_line_item__c).Name);
    			if(getprojecttype != null||getprojecttype != '')
    			{
    				orderitem.Project_Type__c = getprojecttype;
    				recupdate = true;
    			}
    			
    		}
    		
    		
    		system.debug('UpdateRelatedOrderItems now updating prices and quantiies on order items.');
    			
    	    if(mpallcli.containskey(orderitem.legal_contract_line_item__c))
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
    	    if(lcliequipmap.size() > 0 && lcliequipmap.containskey(orderitem.legal_contract_line_item__c))
    	    {
    	    	  orderitem.equipment_ownership__c = lcliequipmap.get(orderitem.legal_contract_line_item__c).equipment_ownership__c;
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

    public static void updateConversionDate(List<Contract_Line_Item__c> newList){
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
    }
    
    //jjackson 8/2016:  made a correction so that product inventory items won't get term start/end dates unless they are at Billing,Installed Activated,
    //or Pending De-Installation; also added code to update the auto renew field on the product inventory item
    //jjackson 4/2016 this method used to update assets, entitlements and service contracts.  Now entitlements and service contracts
    //are being updated based on contract changes (not line item changes). This code now only updates related product inventory line items.
	public static void updateRelatedObjects(Map<Id,Contract_Line_Item__c> triggerNewMap, String triggertype){
	    system.debug('*******************************BEGIN StandardLegalLCLILogic.updateRelatedObjects' +triggertype +'**********************');

		List<Asset> aUpdate = new List<Asset>();
		List<Asset> lstrelatedass = new List<Asset>();
		Asset myasset = New Asset();
		Set<String> dateupdatestatus = New Set<String>();
		dateupdatestatus.add('Billing');
		dateupdatestatus.add('Installed Activated');
		dateupdatestatus.add('Pending De-Installation');
		
		//get the non-cancelled/non-de_installed product inventory line items related to the contract line items
		lstrelatedass = [Select term_start_date__c, status, term_end_date__c, legal_contract_Line_Item__c, id, name,
						 quantity, price__c, term__c, service_start_date__c, service_end_date__c, auto_renew__c
		                 from Asset where legal_contract_line_Item__c in :triggerNewMap.keyset() AND
		                 status not in ('Cancelled', 'De-Installed') ];
		
		//if the contract line item in the trigger has a different term start/end date than what's on the asset, set the date on the asset                 
		for(Asset pi : lstrelatedass)
		{
		  if(triggerNewMap.containskey(pi.legal_contract_line_item__c))
		  {
		  	
		  	 Date termstart = triggerNewMap.get(pi.legal_contract_line_item__c).term_start_date__c;
		  	 Date termend = triggerNewMap.get(pi.legal_contract_line_item__c).term_end_date__c;
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
			
		  	 if(pi.quantity == null || pi.quantity != null && pi.quantity != triggerNewMap.get(pi.legal_contract_line_item__c).quantity__c)
		  	 { pi.quantity = triggerNewMap.get(pi.legal_contract_Line_Item__c).quantity__c;
		  	   recupdated = true;
		  	 }
		  	 
		  	 if(pi.price__c == null || pi.price__c != null && pi.price__c != triggerNewMap.get(pi.legal_contract_Line_item__c).price__c)
		  	 {
		  	 	pi.price__c = triggerNewMap.get(pi.legal_contract_line_item__c).price__c;
		  	 	recupdated = true;
		  	 }
		  	 
		  	 if(pi.auto_renew__c == false && triggerNewMap.get(pi.legal_contract_line_item__c).auto_renew__c == true)
		  	 {
		  	 	pi.auto_renew__c = true;
		  	 	recupdated = true;
		  	 }
		  	 
		  	 
		  	 system.debug('recupdated boolean in UpdateRelatedObject = ' +recupdated) ;
		  	 
		  	 if(recupdated == true)
		  	 {  aUpdate.add(pi);  
		  	 	system.debug('asset added to aUpdate list is ' +pi.Name +', ' +pi.term_end_date__c);
		  	 }
		  	 
		  	
			 //system.debug('term start date for asset ' +pi.name +' is ' +termstart);
			 //system.debug('term end for asset ' +pi.name +' is ' +termend);
			 //system.debug('quantity for asset ' +pi.name +' is' +pi.quantity);
			 //system.debug('price for asset ' +pi.name +' is ' +pi.price__c);	
			 
			 
		  }
	   			
		} //end for lstrelatedass       

		system.debug('aUpdate size is ' +aUpdate.size());

 		 if(aUpdate.size() > 0)
		 {
		 	try
		 	{ update aUpdate;  }
		 	catch(Exception e)
		 	{ system.debug('Error in StandardLegalCLILogic.updateRelatedObjects: ' +e.getMessage());  }
		 	
		 }
		 
		// Asset getasset = [Select Id, Name, term_end_date__c from Asset where id = :myasset.id LIMIT 1];
		 
		// system.debug('getasset term_end_date__c is ' +getasset.term_end_date__c + ', ' +getasset.name);
		 
		 system.debug('********************END updateRelatedObjects  ' +triggertype +'  **************************');
	    
  } //end updateRelatedObjects method
	
  public static void rollUpChannelSummary(List<Contract_Line_Item__c> cliList)
  {
  	system.debug('***************************BEGIN STANDARDLEGALCLILOGIC.ROLLUPCHANNELSUMMARY*************************');
    
    Set<String> parentcliIds = new Set<String>();
    for(Contract_Line_Item__c cli : cliList)
    {
      if(cli.Product_Parent_Id__c != null)
      {
          parentcliIds.add(cli.Product_Parent_Id__c); 
          system.debug('line items in trigger are ' +cli.name +', ' +cli.product_parent_id__c);  
      }
    }
    List<Contract_Line_Item__c> childclis = [SELECT Id, Name, Product_Parent_Id__c,Product__r.Channel_Type__c 
    from Contract_Line_Item__c 
    WHERE Product_Parent_Id__c IN :parentcliIds
    AND Product_Parent_Family__c = 'FTG'
	AND (Status__c = 'Installed Activated' OR Status__c = 'Pending Installation Activate' OR Status__c = 'Pending De-Installation')];
    
    //Create map of parent cli id to list of child clis
    
    Map<Id,List<Contract_Line_Item__c>> parentcliMap = new Map<Id,List<Contract_Line_Item__c>>();
    for(Contract_Line_Item__c cli : childclis)
    {
      if(parentcliMap.containsKey(cli.Product_Parent_Id__c))
      {
        parentcliMap.get(cli.Product_Parent_Id__c).add(cli);
      }
      else
      {
        List<Contract_Line_Item__c> temp = new List<Contract_Line_Item__c>();
        temp.add(cli);
        parentcliMap.put(cli.Product_Parent_Id__c,temp);
      }
     // system.debug('line item in the loop is ' +cli.name + ', ' +cli.product_parent_id__c);
    }
    //Loop through list of clis
    List<Contract_Line_Item__c> parentcliList = new List<Contract_Line_Item__c>();
    for(Id parentcliId : parentcliMap.keyset())
    {
      Integer HD = 0;
      Integer SD = 0;
      Integer Analog = 0;
      for(Contract_Line_Item__c cli : parentcliMap.get(parentcliId))
      {
        if(cli.Product__r.Channel_Type__c == 'HD')
          HD ++;
        else if(cli.Product__r.Channel_Type__c == 'SD')
          SD ++;
        else if(cli.Product__r.Channel_Type__c == 'Analog')  
          Analog++;
      }
      Contract_Line_Item__c temp = new Contract_Line_Item__c(Id = parentcliId);
      temp.HD_Channel_Count__c = HD;
      temp.SD_Channel_Count__c = SD;
      temp.Analog_Channel_Count__c = Analog;
      parentcliList.add(temp);
    }

    if(parentcliList.size() > 0)
    {
    	try
    	{  update parentcliList;  }
    	catch(Exception ex)
    	{  system.debug('Error updating channel counts in RollupChannelSummary: ' +ex.getMessage());  }
    }
    
    system.debug('*******************END STANDARDLEGALCLILOGIC.ROLLUPCHANNELSUMMARY*********************************');
  }
  CPQ comment out END*/
  /*  jjackson 4/2016   replaced by UpdateRelatedOrderItems, which combines updating of all things on order items into one method
  public static void UpdateEquipmentOwnership_on_OrderItem(List<Contract_Line_Item__c> trignewlist, 
                                                           Map<Id,Contract_Line_Item__c> trigoldmap)
  {
  	system.debug('************************START UpdateEquipmentOwnership_on_OrderItem********************');
  	
  	Set<Id> setids = new Set<Id>();
  	Map<Id,Contract_Line_Item__c> lclimap = new Map<Id,Contract_Line_Item__c>();
  	List<Order_Item__c> lstrelatedoi = new List<Order_Item__c>();
  	List<Order_Item__c> lstupdorderitem = new List<Order_Item__c>();
  	
  	//check to see whether the equipment ownership value on the product parent line item was changed
  	//if so, add the line item id to a set that can be used to query for related order items
  	for(Contract_Line_Item__c reclcli : trignewlist)
  	{
  		if(reclcli.Equipment_Ownership__c != trigoldmap.get(reclcli.id).Equipment_Ownership__c && 
  		   reclcli.Name.Contains('Product Parent'))
  		{
  			setids.add(reclcli.id);
  			lclimap.put(reclcli.Id,reclcli);  //if line item meets the criteria, add it to a map for future use
  		}
 
  	}
  	
  	//look for the order item records that are related to the contract line items that had the equipment ownership change
  	if(!setids.IsEmpty())
  	{
  		
  		for(Order_Item__c oi : lstorderitems)  //loop through the global order item list to find ids that match the set
  		{
  			if(setids.contains(oi.legal_contract_line_item__c))
  			{ lstrelatedoi.add(oi);  }
  		}
 
  	}
  	
  	if(!lstrelatedoi.IsEmpty())
  	{
  		for(Order_Item__c recoi : lstrelatedoi)
  		{
  		  if(lclimap.containskey(recoi.legal_contract_line_item__c))
  		  {	recoi.equipment_ownership__c = lclimap.get(recoi.legal_contract_line_item__c).equipment_ownership__c;  
  		    lstupdorderitem.add(recoi);  
  		    system.debug('updated order item record ' +recoi.Name +', ' +recoi.Id);
  		  }
  		}
  	}
  	
  	try{update lstupdorderitem;  }
  	catch(Exception ex)
  	{system.debug('ERROR in UpdateEquipmentOwnership while updating order items:  ' +ex.getMessage());   }
  		
  	
     system.debug('*****************************END UpdateEquipmentOwnership_on_OrderItem********************************');  	
  	
  }//end UpdateEquipmentOwnership
  */                          	
}