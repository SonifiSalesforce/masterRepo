public with sharing class AssociatedItemTriggerLogic {

    public static void WorkOrderEmailNotification(List<Associated_Item__c> aiList, Map<Id,Associated_Item__c> triggerOld, String action)
    {
        Utilities.writeLog('Entered WorkOrderEmailUpdate....'+aiList.size(), AssociatedItemTriggerLogic.class, 'WorkOrderEmailNotification', LoggingLevel.DEBUG);
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> aiIds = new Set<Id>();
        for(Associated_Item__c ai : aiList)
        {
        	if(action != 'Update')
        	{
	            aiIds.add(ai.Id);
    	        workOrderIds.add(ai.Work_Order__c);
        	}
			else
			{
				if(ai.Status__c == 'Cancelled' && triggerOld.get(ai.Id).Status__c != 'Cancelled')//Item was updated to cancelled
				{
		            aiIds.add(ai.Id);
	    	        workOrderIds.add(ai.Work_Order__c);
				}
			}
        }
        aiList = [SELECT Work_Order__c, Order_Item__r.Product_Parent_Id__c, Order_Item__r.Name, Order_Item__r.Product_Parent_Family__c, Order_Item__r.Product__r.Family, Order_Item__r.Product__r.Name, Order_Item__r.Product__r.Circuit__c, Order_Item__r.Product__r.Customization_Needed__c from Associated_Item__c WHERE Id IN :aiIds];
        //system.debug('Associated Items queried '+aiList);
        Map<Id,Work_Order__c> woList = new Map<Id,Work_Order__c>([SELECT Site__r.Name, Work_Order_Number__c, Site__r.Physical_City__c, Site__r.Physical_State__c, OwnerId, Name, Install_Manager__c, Project_Coordinator__c, Status__c, RecordTypeId, (SELECT Work_Order__c, Order_Item__r.Product__r.Name, Order_Item__r.Product_Parent_Id__c, Order_Item__r.Name, Order_Item__r.Product__r.Family, Order_Item__r.Product__r.Circuit__c, Order_Item__r.Product__r.Customization_Needed__c from Associated_Items__r WHERE Id IN :aiIds) from Work_Order__c WHERE Id IN :workOrderIds]);
	    //system.debug('Work Orders queried '+woList);
   
        //create a map of associatedItems to work order
        Map<Id,Work_Order__c> woMap = new Map<Id,Work_Order__c>();
        Set<Id> parentOiIds = new Set<Id>();
        for(Associated_Item__c ai : aiList)
        {
            parentOiIds.add(ai.Order_Item__r.Product_Parent_Id__c);
            woMap.put(ai.Id,woList.get(ai.Work_Order__c));
        }
        
        //Query product parent order items
        Map<Id,Order_Item__c> parentOis = new Map<Id,Order_Item__c>([SELECT Name,Product__r.Name, Product__r.Family from Order_Item__c WHERE Id IN :parentOiIds]);
       // system.debug('Parent Order Items queried '+parentOis);
        
        //Map of record types to status value
        List<WorkOrderStatusNotification__c> statusList = WorkOrderStatusNotification__c.getall().values(); 
        Map<String,Set<String>> recordTypeStatusMap = new Map<String,Set<String>>();
        for(WorkOrderStatusNotification__c status : statusList)
        {
            Set<String> tempList = new Set<String>();
            for(String s : status.Status_Values__c.split(','))
            {
                tempList.add(s);
            }           
            recordTypeStatusMap.put(status.Name, tempList);
        }
        //Map of recordtypeIds to name
        Map<String,Schema.RecordTypeInfo> recordTypeSchemaMap = Schema.SObjectType.Work_Order__c.getRecordTypeInfosByName();
        
        Map<Id,String> recordTypeNameMap = new Map<Id,String>();
        recordTypeNameMap.put(recordTypeSchemaMap.get('Circuits').getRecordTypeId(),'Circuits');
        recordTypeNameMap.put(recordTypeSchemaMap.get('Customization').getRecordTypeId(),'Customization');
        recordTypeNameMap.put(recordTypeSchemaMap.get('Rack Build').getRecordTypeId(),'Rack Build');
        recordTypeNameMap.put(recordTypeSchemaMap.get('Schedules').getRecordTypeId(),'Schedules');
        recordTypeNameMap.put(recordTypeSchemaMap.get('Install').getRecordTypeId(),'Install');
        recordTypeNameMap.put(recordTypeSchemaMap.get('De-Install').getRecordTypeId(),'De-Install');
        
        //Map of User to List of String to hold messages
        Map<Id,List<String>> userMessageMap = new Map<Id,List<String>>();
        for(Work_Order__c wo : woList.values())
        {
            
            Map<String, List<String>> productParentMap = new Map<String,List<String>>();
            Boolean doNotSend = false;
            
            String message = '';
            if(action == 'Insert')
                message += 'Associated Items have been added to the Work Order: '+wo.Work_Order_Number__c+' <br/>';
            else if(action == 'Delete')
                message += 'Associated Items have been removed from the Work Order: '+wo.Work_Order_Number__c+' <br/>';
            else if(action == 'Update')
                message += 'Associated Items have been cancelled from the Work Order: '+wo.Work_Order_Number__c+' <br/>';
            
            message += wo.Name+'<br/><br/>';                
            message += 'Site: '+wo.Site__r.Name+'<br/>';
            message += 'City: '+wo.Site__r.Physical_City__c+'<br/>';
            message += 'State: '+wo.Site__r.Physical_State__c+'<br/><br/>';
            if(action == 'Insert')
                message += 'The Items added are :<br/><br/>';
            else if(action == 'Delete')
                message += 'The Items removed are :<br/><br/>';
            else if(action == 'Update')
            	message += 'The Items cancelled are <br/><br/>';
            	
            system.debug('Message Header is '+message);
            
            String woRecordType = recordTypeNameMap.get(wo.RecordTypeId);
            if(recordTypeStatusMap.containsKey(woRecordType) && recordTypeStatusMap.get(woRecordType).contains(wo.Status__c))
            {
                for(Associated_Item__c ai : wo.Associated_Items__r)
                {
                    if(parentOis.containsKey(ai.Order_Item__r.Product_Parent_Id__c))
                        productParentMap = addToStringList(productParentMap,parentOis.get(ai.Order_Item__r.Product_Parent_Id__c).Name,ai.Order_Item__r.Product__r.Name);
                    else
                        productParentMap = addToStringList(productParentMap,ai.Order_Item__r.Product__r.Name,ai.Order_Item__r.Product__r.Name);
                }
            }
            else //Does not contain status or is an exception status
            {
                for(Associated_Item__c ai : wo.Associated_Items__r)
                //Exception cases
                if(woRecordType == 'Circuits')
                {
                    if(wo.Status__c == 'On Hold' && ai.Order_Item__r.Product__r.Circuit__c == true)
                    {
                        if(parentOis.containsKey(ai.Order_Item__r.Product_Parent_Id__c))
                            productParentMap = addToStringList(productParentMap,parentOis.get(ai.Order_Item__r.Product_Parent_Id__c).Name,ai.Order_Item__r.Product__r.Name);
	                    else
	                        productParentMap = addToStringList(productParentMap,ai.Order_Item__r.Product__r.Name,ai.Order_Item__r.Product__r.Name);
                            
                    }
                }
                else if(woRecordType == 'Customization')
                {
                    if(wo.Status__c == 'Hotel Not Ready' && ai.Order_Item__r.Product__r.Customization_Needed__c == true)
                    {
                        if(parentOis.containsKey(ai.Order_Item__r.Product_Parent_Id__c))
                            productParentMap = addToStringList(productParentMap,parentOis.get(ai.Order_Item__r.Product_Parent_Id__c).Name,ai.Order_Item__r.Product__r.Name);
	                    else
	                        productParentMap = addToStringList(productParentMap,ai.Order_Item__r.Product__r.Name,ai.Order_Item__r.Product__r.Name);
                    }
                }
                else if(woRecordType == 'Schedules')
                {
                    if(wo.Status__c == 'On Hold' && ai.Order_Item__r.Product__r.Family == 'Interactive')
                    {
                        if(parentOis.containsKey(ai.Order_Item__r.Product_Parent_Id__c))
                            productParentMap = addToStringList(productParentMap,parentOis.get(ai.Order_Item__r.Product_Parent_Id__c).Name,ai.Order_Item__r.Product__r.Name);
	                    else
	                        productParentMap = addToStringList(productParentMap,ai.Order_Item__r.Product__r.Name,ai.Order_Item__r.Product__r.Name);

                    }
                    if(parentOis.containsKey(ai.Order_Item__r.Product_Parent_Id__c))
                    {
                    	if(parentOis.get(ai.Order_Item__r.Product_Parent_Id__c).Product__r.Family == 'Direct Sale')
	                    	doNotSend = true;
                    }
                }               
                
            }
           // system.debug('productparent map '+productParentMap);
            //creating the products based on parents so we can get structure on listing of items
            for(String productParent : productParentMap.keyset())
            {
                message += productParent+'<br/>';
                for(String childProduct : productParentMap.get(productParent))
                {
                    message+= '&nbsp;&nbsp;&nbsp;&nbsp;'+childProduct+'<br/>';
                }   
            }
            
            Set<Id> notificationMembers = new Set<Id>();
            notificationMembers.add(wo.OwnerId);
            if(woRecordType == 'Install' || woRecordType == 'De-Install')
            {
                if(wo.Install_Manager__c != null)
                    notificationMembers.add(wo.Install_Manager__c);
                if(wo.Project_Coordinator__c != null)
                    notificationMembers.add(wo.Project_Coordinator__c);         
            }
            system.debug('notification list '+notificationMembers);
            
            if(doNotSend == false && productParentMap.size() > 0)//productParentMap is 0 if no cases match, and no email will be sent for this work order
            {
                for(Id uId : notificationMembers)
                {
                    addToList(userMessageMap, uId, message);
                }
            }
        }
       // system.debug(Logginglevel.ERROR, 'userMessageMap is '+userMessageMap);
        EmailUtilities.doEmailPosts(userMessageMap);
        
    }
    
    private static Map<Id,List<String>> addToList(Map<Id,List<String>> userMessageMap, Id userId, String message)
    {
        if(userMessageMap.containsKey(userId))
        {
            userMessageMap.get(userId).add(message);
        }
        else
        {
            List<String> tempList = new List<String>();
            tempList.add(message);
            userMessageMap.put(userId,tempList);
        }
        return userMessageMap;
    }
    private static Map<String,List<String>> addToStringList(Map<String,List<String>> productParentMap, String productParent, String message)
    {
        if(productParentMap.containsKey(productParent))
        {
            productParentMap.get(productParent).add(message);
        }
        else
        {
            List<String> tempList = new List<String>();
            tempList.add(message);
            productParentMap.put(productParent,tempList);
        }
        return productParentMap;
    }
    

	//jjackson 5/2016 modified and pretty much rewritten from the original code for more efficiency
     public static void WorkOrderNameUpdate(List<Associated_Item__c> aiList, List<Work_Order__c> lstworkorders, List<Order_Item__c> lstorderitems)
    {
        system.debug('********************BEGIN AssociatedItemTriggerLogic.WorkOrderNameUpdate************************');

        //look to see if there are any product parents being inserted in trigger.new
        //create a map that will capture work order id and list of product parent names;
        //at this point a work order is already created so we just have to add the product parent
        //abbreviations to the name
        
        Map<Id,List<String>> wotoprodparent = New Map<Id,List<String>>();
        List<Work_Order__c> woUpdate = New List<Work_Order__c>();
        
        //Get Record Type Ids Map of Id to Name
        Map<Id,Schema.RecordTypeInfo> recordTypeNameMap;
        try { recordTypeNameMap = Schema.getGlobalDescribe().get('Work_Order__c').getDescribe().getRecordTypeInfosById(); }
        catch (Exception e) { throw e; }
        
        for(Associated_Item__c ai : aiList) //capture all product parent line items in the trigger and match them to work order id
        {
        	if(ai.Name.Contains('Product Parent'))
        	{
        		
        		if(wotoprodparent.containsKey(ai.work_order__c))
        		{
            		wotoprodparent.get(ai.work_order__c).add(ai.Name);
        		}
        		else
        		{
            		List<String> tempList = new List<String>();
            		tempList.add(ai.Name);
            		wotoprodparent.put(ai.work_order__c,tempList);
        		}
        	}
        }
        
       
        //only populate parent work orders with new name because update on work order record
        //will trigger new method that populates child work orders
        //this code assumes that associated items are only created after a work order exists
        //it would not make sense to create associated items before a work order 
        
        //get the list of product parents from the custom setting to determine work order name abbreviation
        List<Product_Parent_Usage__c> csproductparent = New List<Product_Parent_Usage__c>();
        csproductparent = Product_Parent_Usage__c.getAll().values(); //getall().values() returns full list of custom setting object
        
        //now put the list into a map with product parent name as key
        Map<String,String> mpparenttoabbrev = New Map<String,String>();
        if(test.isRunningTest())
        {
        	mpparenttoabbrev.put('Interactive Product Parent', 'Interactive');
        	mpparenttoabbrev.put('FTG Product Parent', 'FTG');
        	mpparenttoabbrev.put('Broadband Product Parent', 'GIA');
        	mpparenttoabbrev.put('Direct Sale Product Parent', 'DS');
        	mpparenttoabbrev.put('Professional Solutions Product Parent', 'PS');
        	mpparenttoabbrev.put('DRE Product Parent', 'DRE');
        	mpparenttoabbrev.put('SONIFI Select Product Parent', 'SS');
        	mpparenttoabbrev.put('SoniCast Product Parent', 'SC');
        	mpparenttoabbrev.put('Public Viewing Product Parent', 'PV');	
        
        }
        else
        {
        	for(Product_Parent_Usage__c cs : csproductparent)
        	{  mpparenttoabbrev.put(cs.Name, cs.wo_name_abbrev__c);  
           	//system.debug('abbreviations in custom setting are ' +cs.Name +', ' +cs.wo_name_abbrev__c);
        	}
        }
          
        for(Work_Order__c wo : lstworkorders) //lstworkorder are the work orders related to the records in the trigger
        {
          if(wo.parent_work_order__c == null) //only process parent work orders here
          {
            String woName = wo.Name;
            //system.debug('current work order name in aitriggerlogic is ' +woName);
            String newname = '';
            String fullname = '';
            String truncname = '';
            List<String> lstnewprodparents = New List<String>();
            Set<String> setabbrev = New Set<String>();
            Boolean addprodparent = false;
            
            if(wotoprodparent.containskey(wo.Id)) //only process name change if a new product parent is being inserted
            {   lstnewprodparents = wotoprodparent.get(wo.Id);
            	
            	//system.debug('aitriggerlogic.workordernameupdate lstnewprodparents size is ' +lstnewprodparents.size());
            	
            	for(String ppname : lstnewprodparents)
            	{   //system.debug('aitriggerlogic.workordernameupdate lstnewprodparents contains ' +ppname);
            		if(mpparenttoabbrev.containskey(ppname))
            		{
            			String abbrev = mpparenttoabbrev.get(ppname);
            			if(!wo.Name.Contains(abbrev)) //if the work order name does not contain the abbreviation, flag the work order
            			{ addprodparent = true;
            			  setabbrev.add(abbrev); //add the new product parent abbreviation to the string set
            			}
            		}
            	}//end for loop lstnewprodparents
            }//end if wotoprodparent.containskey
            if(addprodparent == true) //if there are new product parents to add to the work order name, get the current abbreviations
            {
            
            	Boolean Broadband = false;
            	Boolean FTG = false;
            	Boolean iTV = false;
            	Boolean DRE = false;
            	Boolean Professional = false;
            	Boolean PV = false;
            	Boolean DirectSale = false;
            	Boolean SS = false;
            	Boolean HCTab = false;
            	Boolean SC = false;
            	Boolean TIE = false;
            	Boolean SCR = false;
            
            	if((woName.Contains('Interactive')||woName.Contains('ITV'))||(setabbrev != null && setabbrev.contains('Interactive')))
            	{  iTV = true;  }
            	if((woName.Contains('GIA')||woName.Contains('BB'))||(setabbrev != null && setabbrev.contains('GIA')))
            	{  Broadband = true;  }
            	if(woName.Contains('FTG')||(setabbrev != null && setabbrev.contains('FTG')))
            	{  FTG = true;  }
            	if(woName.Contains('DRE')||(setabbrev != null && setabbrev.contains('DRE')))
            	{  DRE = true;  }
            	if(woName.Contains('PS')||(setabbrev != null && setabbrev.contains('PS')))
            	{  Professional = true;  }
            	if(woName.Contains('PV')||(setabbrev != null && setabbrev.contains('PV')))
            	{  PV = true;  }
            	if(woName.Contains('DS')||(setabbrev != null && setabbrev.contains('DS')))
            	{  DirectSale = true;  }
            	if(woName.Contains('SS')||(setabbrev != null && setabbrev.contains('SS')))
            	{  SS = true;  }
            	if(woName.Contains('HCTab')||(setabbrev != null && setabbrev.contains('HCTab')))
            	{  HCTab = true;  }
            	if(woName.Contains('SC')||(setabbrev != null && setabbrev.contains('SC')))
            	{  SC = true;  }
            	if(woName.Contains('TIE')||(setabbrev != null && setabbrev.contains('TIE')))
            	{  TIE = true;  }
            	if(woName.Contains('SCR')||(setabbrev != null && setabbrev.contains('SCR')))
            	{  SCR = true;  }
            	
            	String baseName = ''; 
            	basename = wo.Site__r.Site_ID__c + ' - ' + recordTypeNameMap.get(wo.RecordTypeId).getName() + ' - ';
 
            	if(iTV)
                	newname +='Interactive-';
            	if(FTG == true)
                	newname +='FTG-';
                if(DRE)
                    newname +='DRE-';
             	if(Broadband)
                	newname +='GIA-';
            	if(PV)
                	newname +='PV-';
            	if(HCTab)
                	newname += 'HCTab-';    
            	if(SS)
                	newname += 'SS-'; //BUG-00456
                if(SC)    
                    newname += 'SC-' ;
                if(SCR)
                    newname += 'SCR-'; 
                if(TIE)
                    newname += 'TIE-';   
            	if(Professional)
                	newname +='PS-';
            	if(DirectSale)
                	newname +='DS';

            //system.debug('newname = ' +newname);
            //Remove the last character
            //Name field is 80 characters maximum, if it is greater will truncate
            if(newname != '' || newname != null)
            { fullname = basename + newname;  }
            else
            { fullname = basename;  }
            
            //system.debug('associtemtriggerlogic.workordernameupdate fullname = ' +fullname);
            
            if(fullname.length() > 79)
            {    truncname = fullname.substring(0,79);  }
            else
            {    truncname = fullname;   }
                
            wo.Name = truncname;
  
            woUpdate.add(wo);
          }//end if addprodparent = true    
       }//end if parent work order is null
     }//end for loop workorder list
 		if(woUpdate.size() > 0)
 		{
 			try{ update woUpdate;  }
 			catch(Exception e)
 			{ system.debug('ERROR in AssocItemTriggerLogic.WorkOrderNameUpdate:  ' +e.getMessage()); } 			
 		}
 
      system.debug('********************END AITriggerLogic.WorkOrderNameUpdate***********************');
    }//end class workordernameupdate
    
    //jjackson 4/2016 created method just for changing wo name when product parent work order items are
    //deleted instead of trying to make the workordernameupdate class also accommodate deletions
    public static void RemoveProductParent(List<Associated_Item__c> lstdeletedai, List<Work_Order__c> lstworkords)
    {	
    	system.debug('*********************BEGIN AITriggerLogic.RemoveProductParent*********************');
    	
    	List<Work_Order__c> woUpdate = New List<Work_Order__c>();
    	Map<Id,String> mpwoname = New Map<Id,String>();
    	Map<Id,List<Associated_Item__c>> mpwotoailist = New Map<Id,List<Associated_Item__c>>();
    	//Get a list of all the product parents in the custom setting and put into a map
    	Map<String,Product_Parent_Usage__c> csppusage = New Map<String,Product_Parent_Usage__c>();
    	List<Product_Parent_Usage__c> cslstppusage = New List<Product_Parent_Usage__c>();
    	cslstppusage = Product_Parent_Usage__c.getall().values(); //TODO EXAMPLE CODE: Create a list from a custom setting
    	for(Product_Parent_Usage__c ppu : cslstppusage)
    	{  csppusage.put(ppu.Name, ppu);  }
    	
    	for(Work_Order__c wo : lstworkords)
    	{
    		if(wo.parent_work_order__c != null)
    		{  mpwoname.put(wo.id,wo.name);  }
   		}
    	
    	for(Associated_Item__c delai : lstdeletedai)
    	{
    		if(mpwotoailist.containskey(delai.work_order__c))
    		{  mpwotoailist.get(delai.work_order__c).add(delai);  }
    		else
    		{
    			List<Associated_Item__c> tempList = new List<Associated_Item__c>();
            	tempList.add(delai);
            	mpwotoailist.put(delai.work_order__c,tempList);	
    		}
    	}//end for loop lstdeletedai
    	
    	//Get Record Type Ids Map of Id to Name
        Map<Id,Schema.RecordTypeInfo> recordTypeNameMap;
        try { recordTypeNameMap = Schema.getGlobalDescribe().get('Work_Order__c').getDescribe().getRecordTypeInfosById(); }
        catch (Exception e) { throw e; }
    	
    	for(Work_Order__c wo : lstworkords)
    	{
 			List<Associated_Item__c> lstrelatedpp = New List<Associated_Item__c>();
 			Set<String> setppabbrevs = New Set<String>();
 			if(test.isRunningTest()) //we must populate the set if test is running because we can't pull from custom setting later
 			{
 				setppabbrevs.add('FTG'); //the unit test is only deleting FTG so that's all that needs to be in the set
 			}
 			String woname = '';
 			String woabbrevs = '';
 			Boolean removeflag = false;
 			
 		  if(wo.parent_work_order__c == null)  //if this is a parent work order
 		  {
 			if(mpwotoailist.containskey(wo.id))  //if the work order2associated item map contains the work order id as key
 			{
 				lstrelatedpp = mpwotoailist.get(wo.id); //then get the list of related product parent assoc items
 				if(!test.isRunningTest())
 				{	for(Associated_Item__c ai : lstrelatedpp)
 					{
 				   		if(csppusage.containskey(ai.Name)) //loop thru each product parent to get the correct abbreviation
 				   		{
 				   	  		String abbrev = csppusage.get(ai.Name).wo_name_abbrev__c;
 				   	  		setppabbrevs.add(abbrev); //if the product parent is in the custom setting map, put the abbrev in the set
 				   		}
 					}
 				}//end if test is not running 				
 			}//end if mpwotoailist containskey
 			
 			if(!setppabbrevs.IsEmpty())  //if the set of product parent abbrevs isn't empty
 			{
 				woabbrevs = wo.Name.substringAfterLast(' '); //get the abbreviations contained in the work order name
 				if(woabbrevs != null ||woabbrevs != '') //if the abbreviation substring isn't empty
 				{
 					for(String str :setppabbrevs) //loop through the prod parent set of abbrevs
 					{  
 						if(woabbrevs.Contains(str)) //if any of the prod parent abbrevs are in the work order name
 						{  removeflag = true;  } //set the remove flag to true because we have to re-do the work order name
 					}                            //without the product parent abbrevations in the delete trigger
 				}
 			}
 			
 			if(removeflag = true)
 			{
 				//first get the base name for the work order without abbreviations
 				String rectypename = recordTypeNameMap.get(wo.recordtypeid).getName();
 				String basename = wo.site__r.site_id__c +' - ' +rectypename +' - ';
 				String addabbrevs = '';
 				String fullname = '';
 				String truncname = '';
 				
 				//for each product parent type, check to see if the abbreviation is in the current
 				//work order name but not in the set of product parent abbreviations being deleted.
 				//if the condition is met, add the abbreviation back into the work order name.
 				//Must be added in this order to meet the preference of the Installations dept.
 				if((woabbrevs.Contains('Interactive')||woabbrevs.Contains('ITV'))&&!setppabbrevs.Contains('Interactive'))
 				{  addabbrevs += 'Interactive-';  }
 				
 				if(woabbrevs.Contains('FTG')&&!setppabbrevs.Contains('FTG'))
 				{  addabbrevs += 'FTG-';  }
 				
 				if(woabbrevs.Contains('DRE')&&!setppabbrevs.Contains('DRE'))
 				{  addabbrevs += 'DRE-';  }
 				
 				if(woabbrevs.Contains('GIA')&&!setppabbrevs.Contains('GIA'))
 				{  addabbrevs += 'GIA-';  }
 
 				if(woabbrevs.Contains('PV')&&!setppabbrevs.Contains('PV'))
 				{  addabbrevs += 'PV-';  }
 				
 				if(woabbrevs.Contains('HCTab')&&!setppabbrevs.Contains('HCTab'))
 				{  addabbrevs += 'HCTab-';  }
 				
 				if(woabbrevs.Contains('SS')&&!setppabbrevs.Contains('SS'))
 				{  addabbrevs += 'SS-';  }
 
 				if(woabbrevs.Contains('SC')&&!setppabbrevs.Contains('SC'))
 				{  addabbrevs += 'SC-';  }
 				
 				if(woabbrevs.Contains('SCR')&&!setppabbrevs.Contains('SCR'))
 				{  addabbrevs += 'SCR-'; }
 				
 				if(woabbrevs.Contains('TIE')&&!setppabbrevs.Contains('TIE'))
 				{  addabbrevs += 'TIE-';  }
 				
 				if(woabbrevs.Contains('PS')&&!setppabbrevs.Contains('PS'))
 				{  addabbrevs += 'PS-';  }
 				
 				if(woabbrevs.Contains('DS')&&!setppabbrevs.Contains('DS'))
 				{  addabbrevs += 'DS';  }
 				
 				if(addabbrevs != null || addabbrevs != '')
 				{
 					fullname = basename + addabbrevs;
 					if(fullname.length() > 79)
            		{  truncname = fullname.substring(0,79);  }
            		else
            		{  truncname = fullname;   }
                
            		wo.Name = truncname;
            		woUpdate.add(wo);
 				}
 				else
 				{
 					wo.Name = basename;
 					woUpdate.add(wo);
 				}
 			} //end if removeflag = true
  		  }//end if parent work order is null
     	}//end for loop lstworkords
 
    	
    	if(woUpdate.size() > 0 || !woUpdate.IsEmpty())
    	{
    		try{ update woUpdate;  }
    		catch(Exception e)
    		{  system.debug('ERROR in AITriggerLogic.RemoveProductParent:  ' +e.getMessage());  }
    	}
    	 
		system.debug('**********************END AITriggerLogic.RemoveProductParent*********************');    	
    }//end class RemoveProductParent
    
    //jjackson 7/18/2014 for Incident BUG-00361  Use associated item product parent lines to find install clock start dates
    //on the related contract and populate them into the work order.  This should take place upon insert of associated items to
    //work order
    public static void GetInstallClockStartDates (List<Associated_Item__c> lstassitems, List<Work_Order__c> lstworkorders, List<Order_Item__c> lstorderitems)
    {
    	system.debug('Entered AssociatedItemTriggerLogic.GetInstallClockStartDates');
    	
    	Map<ID,ID> mpoitowo = new Map<ID,ID>();
        String ProdParentNames;
        Boolean runtriggercode = false;
       
       if(Test.isRunningTest())
        { ProdParentNames = 'FTG Product Parent|Interactive Product Parent'; }
       else
        { Config_Settings__c cs = Config_Settings__c.getInstance('AssocItemProductParentsforInstallClock');
    	  ProdParentNames = cs.String_Config__c; }
    	  
    	Set<Id> setconlineitems = new Set<Id>();
       	Map<ID,ID> mpoitolcli = new Map<ID,ID>();
     	
    	//system.debug('config setting string = ' +ProdParentNames);
    	
    	for(Associated_Item__c recaitem : lstassitems)
    	{ 
    	  if(ProdParentNames.contains(recaitem.Name))
    	  {
    		mpoitowo.put(recaitem.Work_Order__c,recaitem.Order_Item__c);
            runtriggercode = true;
    	  }
    	}
     
      if(runtriggercode == true)
      { 
       if(!lstorderitems.isEmpty())
       {
           
        for(Order_Item__c recorderitem : lstorderitems)
        {
        	setconlineitems.add(recorderitem.Legal_Contract_Line_Item__c);
        	mpoitolcli.put(recorderitem.id,recorderitem.Legal_Contract_Line_Item__c);

        }
        //system.debug('setconlineitems is ' +setconlineitems);
   
        Map<ID,ID> mplclitolc = new Map<ID,ID>();
        Set<ID> setcontracts = new Set<ID>();
		Map<Id,Date> mpcontractftgdt = new Map<Id,Date>();
        Map<Id,Date> mpcontractinterdt = new Map<Id,Date>();
		
        List<Contract_Line_Item__c> lstlcli = [ Select Id, Legal_Contract__c from Contract_Line_Item__c where id in :setconlineitems ];
        //system.debug('lcli list size is ' +lstlcli.size());
        
       for(Contract_Line_Item__c reclcli : lstlcli)
        {
        	mplclitolc.put(reclcli.id,reclcli.Legal_Contract__c);
			setcontracts.add(reclcli.Legal_Contract__c);
        }
        
        List<Contract__c> lstcontract = [ Select id,FTG_Clock_Start_Date__c,Interactive_Clock_Start_Date__c from Contract__c where id in :setcontracts ];
        
       
        for(Contract__c reccontract : lstcontract)
        {
        	mpcontractftgdt.put(reccontract.Id,reccontract.FTG_Clock_Start_Date__c);
        	mpcontractinterdt.put(reccontract.Id,reccontract.Interactive_Clock_Start_Date__c);
        }
        
        List<Work_Order__c> lstupdworkorders = new List<Work_Order__c>();
   
        //system.debug('list of work orders is ' +lstworkorders);
    
        for(Work_Order__c recworkorder : lstworkorders)
        {
        	Date dtftgclockstart = mpcontractftgdt.get(mplclitolc.get(mpoitolcli.get(mpoitowo.get(recworkorder.id))));
        	Date dtgpclockstart = mpcontractinterdt.get(mplclitolc.get(mpoitolcli.get(mpoitowo.get(recworkorder.id))));
        	Date dtftgcontractedcompletion;
        	Date dtgpcontractedcompletion;
        	
        	if(dtftgclockstart != null)
        	  { dtftgcontractedcompletion = dtftgclockstart.addDays(60); }
        	else
        	  { dtftgcontractedcompletion = null; }
        	  
        	if(dtgpclockstart != null)
        	  { dtgpcontractedcompletion = dtgpclockstart.addDays(90); }
        	else
        	  { dtgpcontractedcompletion = null; }
        	  
        	//system.debug('ftgclockstart and ftgcontractedcompletion are ' +dtftgclockstart + ', ' +dtftgcontractedcompletion);
        	//system.debug('gpclockstart and gpcontractedcompletion are ' +dtgpclockstart + ', ' +dtgpcontractedcompletion);
        	  
        	recworkorder.FTG_Contracted_Completion_Date__c = dtftgcontractedcompletion;
        	recworkorder.GP_Contracted_Completion_Date__c = dtgpcontractedcompletion;
        	
        	lstupdworkorders.add(recworkorder);
         }
          
        	try
        	{
        		update lstupdworkorders;

        	}
        	catch(Exception ex){ 
                  system.debug('Exception in GetInstallClockStartDates: '+ex.getMessage());
        	}
       }
      }      
       
    }
    
    //jjackson 9/2014 BUG-00331 update order item/order status when work order item/work order status changes
    public static void UpdateOrderItemStatus(List<Associated_Item__c> lsttriggernew, Map<ID,Associated_Item__c> mptriggerold, List<Order_Item__c> lstorderitems)
    {
       system.debug('Entering UpdateOrderItemStatus**************');
       Map<ID,Order_Item__c> mporditm = new map<ID,Order_Item__c>();
       List<Order_Item__c> lstupdorderitems = new list<Order_Item__c>();
       
       for(Order_Item__c recorditm : lstorderitems)	
       {
       	 mporditm.put(recorditm.id,recorditm);
       }
       
       for(Associated_Item__c recassocitm : lsttriggernew)
       {
         	Order_Item__c recorditm = new Order_Item__c(); //reinstantiate the variable for every new associated item record
         	//if new status does not equal old status and this is not a partial install, update status of related order item
         	if(recassocitm.Status__c != mptriggerold.get(recassocitm.id).Status__c && recassocitm.Partial_Order__c == false)
         	{
         		recorditm = mporditm.get(recassocitm.order_item__c);
         		recorditm.Status__c = recassocitm.Status__c;
                lstupdorderitems.add(recorditm);  		
         	}
         	
         	//system.debug('old status and new status are ' +mptriggerold.get(recassocitm.id).Status__c +', ' + recassocitm.Status__c);
       }    	
       
       try
        	{
        		update lstupdorderitems;

        	}
        	catch(Exception ex){ 
                  system.debug('Exception in UpdateOrderItemStatus: '+ex.getMessage());
        	}
        	
        system.debug('Finished UpdateOrderItemStatus***************************');
    }

	public static List<Work_Order__c> GetWorkOrderList(Set<ID> workorderids)
	{
		List<Work_Order__c> lstworkorders = new list<Work_Order__c>();
		lstworkorders = [Select Id, Site__c, Site__r.Site_ID__c, GP_Contracted_Completion_Date__c,
		                FTG_Contracted_Completion_Date__c, RecordTypeId, Parent_Work_Order__c, Name from Work_Order__c where id in :workorderids ];
		                
		return lstworkorders;
	}
	
	public static List<Order_Item__c> GetOrderItemList(Set<ID> orderitemids)
	{
	   List<Order_Item__c> lstorderitem = new list<Order_Item__c>();
	   lstorderitem = [SELECT Id, Name, Product__r.Name, Product__r.Family, Legal_Contract_Line_Item__c, Order__c, asset__c from Order_Item__c WHERE Id IN :orderitemids];
	   
	   return lstorderitem;
	}

}