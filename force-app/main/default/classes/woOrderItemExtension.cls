public class woOrderItemExtension
{
    public Id workOrderId{get;set;}
    public Id originalWorkOrderId{get;set;}
    private String saveURL;
    private String retURL;
    public Work_Order__c wo{get;set;}
    public Map<Id, Order_Item__c> oiSelectMap{get;set;}
    public Map<Id, Order_Item__c> woOrderItemMap{get;set;}
    Map<Id,Order__c> orderList{get;set;}
    public Boolean showOrderSelect{get;set;}
    public Boolean showWorkOrder{get;set;}
    public static JSONGenerator oiGen {
      get {
        if(oiGen == null)
          oiGen = JSON.createGenerator(true);
        return oiGen;
      }
      set;
    }
    public static JSONGenerator woGen {
      get {
        if(woGen == null)
          woGen = JSON.createGenerator(true);
        return woGen;
      }
      set;
    }
    //Create set of Ids of Assoicated items. so if an Associated item for that Order Item already exists do not recreate
    Set<Id> woOrderItemIds {get;set;}
    public String oiTreeJSON{get;set;}
    public String woTreeJSON{get;set;}
    public Map<Id,List<Order_Item__c>> orderOiMap{get;set;}
    public String selectedIds{get;set;}
    public String woRecordType{get;set;}
    public List<Associated_Item__c> aiList{get;set;}
    public Map<Id,String> installParentsMap{get;set;}
    public Map<Id,String> deinstallParentsMap{get;set;}

    public woOrderItemExtension(ApexPages.StandardController controller)
    {
    	Utilities.writeLog('Entering', woOrderItemExtension.class, 'woOrderItemExtension', LoggingLevel.DEBUG);    	
        oiTreeJSON = '{}';
        woTreeJSON = '{}';

        Work_Order__c currentWorkOrder= (Work_Order__c)controller.getRecord();
        originalWorkOrderId = currentWorkOrder.Id; //Keeping the child Id here
        currentWorkOrder = [SELECT RecordTypeId, Parent_Work_Order__c from Work_Order__c WHERE Id = :currentWorkOrder.Id];
        if(currentWorkOrder.Parent_Work_Order__c != null)
        	workOrderId = currentWorkOrder.Parent_Work_Order__c;
        else
        	workOrderId = currentWorkOrder.Id;
        	
        //If Id not found in Parameter
        if(workOrderId == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
           '<b>No Work Order ID specified</b>', ''));
           return;
        }
        saveURL = ApexPages.currentPage().getParameters().get('saveURL');
        retURL = ApexPages.currentPage().getParameters().get('retURL');
        this.wo = [SELECT Name,Site__c, RecordTypeId from Work_Order__c WHERE Id = :workOrderId];
        woRecordType = Utilities.RecordTypeIdToName('Work_Order__c', wo.RecordTypeId);    	
    	Utilities.writeLog('Work Order Record Type: '+woRecordType, woOrderItemExtension.class, 'woOrderItemExtension', LoggingLevel.DEBUG);    	

		/*
        aiList = [SELECT Work_Order__c, Order_Item__r.Name, Order_Item__r.Product__c, Order_Item__r.Order__c FROM Associated_Item__c Where Work_Order__c = :workOrderId];
    	Utilities.writeLog('Associated Items of WorkOrders queried: '+aiList, woOrderItemExtension.class, 'woOrderItemExtension', LoggingLevel.DEBUG);    	

        List<Id> orderIds = new List<Id>();
        for(Associated_Item__c ai : aiList)
        {
            orderIds.add(ai.Order_Item__r.Order__c);
        }
    	*/


        //Orders selected are open orders from the same site
        orderList = new Map<Id, Order__c>([SELECT Id, Name, Order_Number__c from Order__c WHERE Site__c = :wo.Site__c AND Status__c != 'Order Fulfilled']);
    	Utilities.writeLog('List of Orders attached to WorkOrder: '+orderList, woOrderItemExtension.class, 'woOrderItemExtension', LoggingLevel.DEBUG);    	

        orderOiMap = new Map<Id, List<Order_Item__c>>();
        if(orderList.size() == 0)
 		{	
            //No orders related to Work Order, do not show
            showOrderSelect = false;
 		}
        else
        {
            //Setup Order Item tree
            showOrderSelect = true;
            populateOrderItemHierarchy();

            //Setup Work Order tree
            woOrderItemMap = new Map<Id, Order_Item__c>();
            populateWorkOrderHierarchy();
            if(woOrderItemMap.size() > 0)
            {
                showWorkOrder = true;
                getWorkOrderTreeJSON();

            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                       'No Order Items on current Work Order', ''));
		    	Utilities.writeLog('No Order Items on current Work Order', woOrderItemExtension.class, 'woOrderItemExtension', LoggingLevel.DEBUG);    	
            }

            //Populate Select Tree JSON with workOrder order item ids loaded
            if(oiSelectMap.size() > 0)
            {
                getSelectTreeJSON();
            }
        }
    	Utilities.writeLog('Exiting controller oiSelectMap: '+oiSelectMap, woOrderItemExtension.class, 'woOrderItemExtension', LoggingLevel.DEBUG);    	
    	Utilities.writeLog('Exiting controller woOrderItemMap: '+woOrderItemMap, woOrderItemExtension.class, 'woOrderItemExtension', LoggingLevel.DEBUG);    	

    }


    public PageReference transferOrderItems()
    {
      //Convert the comma separated string into List of ID
      if(selectedIds == '' || selectedIds == null)
      {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                       'No Order Items selected', ''));
        return null;
      }

      Boolean existing = false;
      Integer count = 0;

      Set<Id> listIds = (Set<ID>) JSON.deserialize(selectedIds, Set<ID>.class);
	  system.debug(LoggingLevel.ERROR, 'Deserialized list Ids '+listIds);		
      //Remove ids for Order that may be part of list
      if(listIds.size() > 0)
      {
          Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
          String oiKeyPrefix =  gd.get('Order_Item__c').getDescribe().getKeyPrefix();
          for(Id oiId : listIds)
          {
            if(oiId.getSObjectType().getDescribe().getKeyPrefix() != oiKeyPrefix)
            {
			    system.debug(LoggingLevel.ERROR, 'Removing from list Ids '+oiId);		
                listIds.remove(oiId);
            }
          }
      }
	  system.debug(LoggingLevel.ERROR, 'Deserialized list Ids after removal'+listIds);		
      
      //Map for getting Status of Order Item to transfer to Associated Item
      Map<Id,Order_Item__c> oiMap = new Map<Id,Order_Item__c>([SELECT Status__c, Name, Total_Remaining_Rooms__c, Contracted_Completion_Date__c from Order_Item__c WHERE Id IN :listIds]);
      Map<Id,Associated_Item__c> aiMap = new Map<Id,Associated_Item__c>([SELECT Id from Associated_Item__c WHERE Work_Order__c = :workOrderId]);
	  system.debug(LoggingLevel.ERROR, 'oiMap is '+oiMap);
	  system.debug(LoggingLevel.ERROR, 'oiMap is '+aiMap);
      //List for Inserting Associated Items
      List<Associated_Item__c> aiSelectedList = new List<Associated_Item__c>();
      if(listIds.size() > 0)
      {
        try{
		  system.debug(LoggingLevel.ERROR, 'Loop through list Ids ');	
		  system.debug(LoggingLevel.ERROR, 'Loop: work order items Ids '+woOrderItemIds);	
          for(Id oiId: listIds)
          {
          	existing = false;
          	system.debug(LoggingLevel.ERROR,'On ID: '+oiId);
                 for(Id woiId : woOrderItemIds)
                 {
                     if(woiId == oiMap.get(oiId).id)
                     {
                     	 system.debug(LoggingLevel.ERROR, 'Order Item exists on WorkOrder');
                         existing = true;
                         Utilities.writeLog('transferOrderItems: match dup '+oiMap.get(oiId).id,woOrderItemExtension.class,  'transferOrderItems', LoggingLevel.DEBUG);
                     }
                }
                if (existing == false)
                {
             	 system.debug('Order Item does not exist on WorkOrder');
                  Associated_Item__c ai = new Associated_Item__c(
                  Work_Order__c = this.wo.Id,
                  Order_Item__c = oiId,
                  Status__c = oiMap.get(oiId).Status__c,
                  Quantity__c = oiMap.get(oiId).Total_Remaining_Rooms__c,
                  Contracted_Completion_Date__c = oiMap.get(oiId).Contracted_Completion_Date__c,
                  Name = oiMap.get(oiId).Name);
                  aiSelectedList.add(ai);
                  // Utilities.writeLog('transferOrderItems: mapdata '+oiMap.get(oiId).id+' name '+oiMap.get(oiId).Name,woOrderItemExtension.class,  'transferOrderItems', LoggingLevel.DEBUG);
                  count++;
                }
          }
          system.debug(LoggingLevel.ERROR, 'Count of associated items to create is '+count);
          if (count > 0)
          {
             insert aiSelectedList;

             //Repopulate the tree
             populateWorkOrderHierarchy();
             if(woOrderItemMap.size() > 0)
             {
               getWorkOrderTreeJSON();
             }
             if(oiSelectMap.size() > 0)
             {
               getSelectTreeJSON();
             }
          } // If count greater then 0
          //revertParentStatuses();
          selectedIds = null;
          //Return Page Reference to page with id Parameter
          return null;
        }
        catch(Exception e){
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                       'Error while transferring Order Items: '+e.getMessage(),
                       ''));

        }
     }
     return null;
    }

    public PageReference cancelTransfer()
    {
    	PageReference pr = Page.WorkOrderItemHierarchy;
    	pr.setRedirect(true);
    	pr.getParameters().put('Id',this.originalWorkOrderId);
    	pr.getParameters().put('saveURL',this.saveURL);
    	pr.getParameters().put('retURL',this.retURL);
    	pr.getParameters().put('mode','edit');
    	return pr;
    }


    private void populateWorkOrderHierarchy()
    {
    	Utilities.writeLog('Entering', woOrderItemExtension.class, 'populateWorkOrderHierachy', LoggingLevel.DEBUG);    	
    	
        aiList = [SELECT Work_Order__c, Order_Item__r.Product__c, Order_Item__r.Name, Order_Item__c FROM Associated_Item__c Where Work_Order__c = :workOrderId];
    	Utilities.writeLog('Requerying Associated Item list on Work Order: '+aiList, woOrderItemExtension.class, 'populateWorkOrderHierarchy', LoggingLevel.DEBUG);    	

        woOrderItemIds = new Set<Id>();
        for(Associated_Item__c ai: aiList)
        {
            woOrderItemIds.add(ai.Order_Item__c);
        }
        system.debug(LoggingLevel.ERROR, 'Current Order Items on Work Order '+woOrderItemIds);
        woOrderItemMap = new Map<Id, Order_Item__c>([SELECT Id, Name, Parent__c, Product__r.Name, Price__c, (SELECT Id, Parent__c FROM Order_Items__r) from Order_Item__c WHERE Id IN :woOrderItemIds]);
    	Utilities.writeLog('Exiting', woOrderItemExtension.class, 'populateWorkOrderHierachy', LoggingLevel.DEBUG);    	
    }
    private void populateOrderItemHierarchy()
    {
    	Utilities.writeLog('Entering', woOrderItemExtension.class, 'populateOrderItemHierarchy', LoggingLevel.DEBUG);    	

        //Query Order Items then take actino based on workOrder Record Type
    	this.oiSelectMap = new Map<Id, Order_Item__c>([SELECT
                            Name,
                            Product__r.Name,
                            Status__c,
                            Installation_Status__c,
                            Total_Rooms_Ordered__c,
                            Total_Remaining_Rooms__c,
                            Price__c,
                            Order__c,
                            Parent__c,Parent__r.Parent__r.Parent__r.Parent__r.Parent__r.Parent__c,
                            (SELECT Id, Name, Status__c, Parent__c FROM Order_Items__r)
                          FROM
                               Order_Item__c
                          WHERE
                            Order__c IN :orderList.keyset()
                          ORDER BY
                              Parent__c]);
    	Utilities.writeLog('Parents Unmodifed Order Item Selection Map: '+oiSelectMap, woOrderItemExtension.class, 'populateOrderItemHierarchy', LoggingLevel.DEBUG);    	

       	for(Id oiid :this.oiSelectMap.KeySet())
       	{
       		system.debug('order item in map is ' +oiSelectMap.get(oiid));
       	}
       
        //Modify the parents of queried Order Items
   		if(woRecordType == 'Install')
   		{
	   		List<Order_Item__c> leafOis = new List<Order_Item__c>();
	   		for(Order_Item__c oi : oiSelectMap.values())
	  		{
	 	    	if(oi.Status__c == 'Pending Installation Activate' || oi.Status__c == 'Pending Installation Deactivate')
	            	leafOis.add(oi);
	    	}
	    	//Get parents previous values as well as change all statuses to pending install
	    	findParents(leafOis);
   		}
        else if(woRecordType == 'De-Install')
       	{
			List<Order_Item__c> leafOis = new List<Order_Item__c>();
			for(Order_Item__c oi : oiSelectMap.values())
			{
				if(oi.Status__c == 'Pending De-Installation')
					leafOis.add(oi);
			}
       		findParents(leafOis);
       }
		Utilities.writeLog('Modification of Parents on Install, Deinstall complete', woOrderItemExtension.class, 'populateOrderItemHierarchy', LoggingLevel.DEBUG);    	

       if(oiSelectMap.size() > 0)
        {
            //Create Map from Order Id to Order Items
            for(Order_Item__c oi : oiSelectMap.values())
            {
                if(orderOiMap.containsKey(oi.Order__c))
                {
                    orderOiMap.get(oi.Order__c).add(oi);
                }
                else
                {
                    List<Order_Item__c> oiTempList = new List<Order_Item__c>();
                    oiTempList.add(oi);
                    orderOiMap.put(oi.Order__c, oiTempList);
                }
            }
	    	Utilities.writeLog('Map of Order to Order Items: '+orderOiMap, woOrderItemExtension.class, 'populateOrderItemHierarchy', LoggingLevel.DEBUG);    	
        }
        else
        {
            //No Order Items to select to move
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                       '<b>No Order Items on Orders related to Work Order for Transfer.</b>',
                       ''));
            showOrderSelect = false;
        }

    	Utilities.writeLog('Exiting', woOrderItemExtension.class, 'populateOrderItemHierarchy', LoggingLevel.DEBUG);    	
    }

    //We're modifying the parents to have the same status on Install and Deinstall Work Orders for the Tree construction to pick them up.
    //No DML is used so Status modification isn't permanent
    //Input is a list of all OIs whos status matches Work Order Type
    private void findParents(List<Order_Item__c> oiList)
    {
    	Utilities.writeLog('Entering', woOrderItemExtension.class, 'findParents', LoggingLevel.DEBUG);    	
    	Utilities.writeLog('List of Order Items need Parent Modification: '+oiList, woOrderItemExtension.class, 'findParents', LoggingLevel.DEBUG);    	
    	
        if(oiList.size() == 0)
            return;
        Set<Id> parentIds = new Set<Id>();
        try{
	        for(Order_Item__c oi : oiList)
	        {
	        	system.debug('order item outside while statement: ' +oi);
	        	
	            while(oi != null)
	            {	
	            	system.debug('order item inside while statement: ' +oi);
	            	
	                if(oi.Parent__c != null)
	                    parentIds.add(oi.Parent__c);
	                    system.debug('oi parent__c is ' +oi.parent__c);
	                oi = oi.Parent__r;
	                system.debug('oi parent__r is ' +oi.parent__r);
	            }
	        }
    		Utilities.writeLog('Id list of all Parents: '+parentIds, woOrderItemExtension.class, 'findParents', LoggingLevel.DEBUG);    	
        }
        catch(System.Exception e)
        {
    		Utilities.writeLog('Cannot get parent Ids '+e.getStackTraceString(), woOrderItemExtension.class, 'findParents', LoggingLevel.DEBUG);    	
        }
        //Change status of parents based on workOrder
        for(Id parentId : parentIds)
        {
        	system.debug('parentId is ' +parentId);
        	Order_Item__c parentTempOi;
        	
        	if(oiSelectMap.ContainsKey(parentId))
            {  parentTempOi = oiSelectMap.remove(parentId); }
            else
            {
            	system.debug('ERROR:  Order Item Not Found in oiSelectMap is id  ' +parentId);
            }
            if(woRecordType == 'Install')
            	parentTempOi.Status__c = 'Pending Installation Activate';
            else if(woRecordType == 'De-Install')
            	parentTempOi.Status__c = 'Pending De-Installation';
    		Utilities.writeLog('Order Item whose status is being temporarily changed '+parentTempOi + ' size of children '+parentTempOi.Order_Items__r.size(),
    		woOrderItemExtension.class, 'findParents', LoggingLevel.DEBUG);    	
            oiSelectMap.put(parentId,parentTempOi);
        }
		Utilities.writeLog('Exiting', woOrderItemExtension.class, 'findParents', LoggingLevel.DEBUG);    	
    }

    private void getWorkOrderTreeJSON()
    {
		Utilities.writeLog('Entering', woOrderItemExtension.class, 'getWorkOrderTreeJSON', LoggingLevel.DEBUG);    	

        woGen = JSON.createGenerator(true);
        woGen.writeStartArray();
        //Write the Work Order in first
        woGen.writeStartObject();
        if(wo.Id != null)
        {
            woGen.writeStringField('key',this.wo.Id);
            woGen.writeStringField('href','/'+wo.Id);
            woGen.writeStringField('target','_top');
        }
        woGen.writeStringField('title','Work Order : '+wo.Name);
        woGen.writeBooleanField('expanded',true);
        if(woOrderItemMap.size() == 0)
            woGen.writeBooleanField('folder',false);
        else
        {
            woGen.writeBooleanField('folder',true);
            woGen.writeFieldName('children');
            woGen.writeStartArray();
            for(Order_Item__c oiLine : woOrderItemMap.values())
                if(oiLine.Parent__c == null)
                    convertWOOrderItemToJSON(oiLine);
            woGen.writeEndArray();
        }
        woGen.writeEndObject();
        woGen.writeEndArray();
        this.woTreeJSON = woGen.getAsString();

		Utilities.writeLog('Exiting', woOrderItemExtension.class, 'getWorkOrderTreeJSON', LoggingLevel.DEBUG);    	
    }
    private void getSelectTreeJSON()
    {
		Utilities.writeLog('Entering', woOrderItemExtension.class, 'getSelectTreeJSON', LoggingLevel.DEBUG);    	

        oiGen = JSON.createGenerator(true);
        oiGen.writeStartArray();
        for(Order__c o : orderList.values())
        {
			Utilities.writeLog('Calling convertOrderToJSON on Order: '+o, woOrderItemExtension.class, 'getSelectTreeJSON', LoggingLevel.DEBUG);    	
            convertOrderToJSON(o);
        }
        oiGen.writeEndArray();
        this.oiTreeJSON = oiGen.getAsString();

		Utilities.writeLog('Exiting', woOrderItemExtension.class, 'getSelectTreeJSON', LoggingLevel.DEBUG);    	
    }
    private void convertWOOrderItemToJSON(Order_Item__c oi)
    {
        woGen.writeStartObject();
        if(oi.Id != null)
        {
            woGen.writeStringField('key', oi.Id);
            woGen.writeStringField('href','/'+oi.Id);
            woGen.writeStringField('target','_top');
        }
        if(null != oi.Product__r.Name) {
            woGen.writeStringField('title', oi.Product__r.Name);
        }
        if(null != oi.Price__c)
            woGen.writeNumberField('price', oi.Price__c);
        woGen.writeBooleanField('expanded', true);
        if(oi.Order_Items__r.size() == 0) {
          woGen.writeBooleanField('folder', false);
        } else {
          woGen.writeBooleanField('folder', true);
          woGen.writeFieldName('children');
            woGen.writeStartArray();
            for(Order_Item__c oiLine : oi.Order_Items__r) {
                if(woOrderItemMap.containsKey(oiLine.Id))
                    convertWOOrderItemToJSON(this.woOrderItemmap.get(oiLine.Id));
            }
            woGen.writeEndArray();
        }
      woGen.writeEndObject();
    }
    private void convertOrderToJSON(Order__c o)
    {
		Utilities.writeLog('Entering', woOrderItemExtension.class, 'convertOrderToJSON', LoggingLevel.DEBUG);    	
    	
        oiGen.writeStartObject();
        if(o.Id != null)
        {
            oiGen.writeStringField('key',o.Id);
            oiGen.writeStringField('href','/'+o.Id);
            oiGen.writeStringField('target','_top');
        }
        if(o.Name != null)
            oiGen.writeStringField('title',o.Order_Number__c + ' : '+o.Name);
        oiGen.writeBooleanField('expanded', true);
        oiGen.writeBooleanField('unselectable',true);
        if(!orderOiMap.containsKey(o.Id) || orderOiMap.get(o.id).size() == 0)  //Filters out Orders with out Order Items
            oiGen.writeBooleanField('folder',false);
        else
        {
            oiGen.writeBooleanField('folder',true);
            oiGen.writeFieldName('children');
            oiGen.writeStartArray();
            for(Order_Item__c oiLine : orderOiMap.get(o.Id))
                if(oiLine.Parent__c == null)
                {
					Utilities.writeLog('Calling convertOiToJSON on OrderItem: '+oiLine, woOrderItemExtension.class, 'convertOrderToJSON', LoggingLevel.DEBUG);    	
                    convertOiToJSON(oiLine);
                }
            oiGen.writeEndArray();
        }
        oiGen.writeEndObject();

		Utilities.writeLog('Exiting', woOrderItemExtension.class, 'convertOrderToJSON', LoggingLevel.DEBUG);    	
    }
    private void convertOIToJSON(Order_Item__c oi)
    {
		Utilities.writeLog('Entering', woOrderItemExtension.class, 'convertOIToJSON', LoggingLevel.DEBUG);    	
    	
        //Check to see if Status has correct value on Order Item for Work Order Record Type
/* *
        if(woRecordType == 'Install' && !(oi.Status__c == 'Pending Installation Activate'
                    || oi.Status__c == 'Pending Installation Deactivate'))
        {
			Utilities.writeLog('Order item does not belong on Selection for Install Work Order', woOrderItemExtension.class, 'convertOIToJSON', LoggingLevel.DEBUG);    	
            return;
        }
        else if (woRecordType == 'De-Install' && oi.Status__c != 'Pending De-Installation')
        {
			Utilities.writeLog('Order item does not belong on Selection for DeInstall Work Order', woOrderItemExtension.class, 'convertOIToJSON', LoggingLevel.DEBUG);    	
            return;
        }
*/
        //Check if Order Item is Existing on Work Order,  add Existing tag to it
        Boolean existing = false;
        for(Id oiId : woOrderItemIds)
        {
            if(oiId == oi.Id)
            {
                existing = true;
            }
        }
		
		Utilities.writeLog('Order Item exists on Work Order already: '+existing, woOrderItemExtension.class, 'convertOIToJSON', LoggingLevel.DEBUG);    	

        oiGen.writeStartObject();
        if(oi.Id != null)
        {
            oiGen.writeStringField('key', oi.Id);
            oiGen.writeStringField('href','/'+oi.Id);
            oiGen.writeStringField('target', '_top');
        }
        if(null != oi.Product__r.Name) {
            if(existing)
                oiGen.writeStringField('title', oi.Product__r.Name + ' -- EXISTING');
            else
                oiGen.writeStringField('title', oi.Product__r.Name);

        }
        if(null != oi.Price__c)
            oiGen.writeNumberField('price', oi.Price__c);
        oiGen.writeBooleanField('expanded', true);
        oiGen.writeBooleanField('unselectable',false);

        if (existing) {
           oiGen.writeBooleanField('hideCheckbox', true);
        } else {
           oiGen.writeBooleanField('hideCheckbox', false);
        }
        if(oi.Order_Items__r.size() == 0) {
          oiGen.writeBooleanField('folder', false);
        } else {
          oiGen.writeBooleanField('folder', true);
          oiGen.writeFieldName('children');
            oiGen.writeStartArray();
            for(Order_Item__c oiLine : oi.Order_Items__r)
            {
                if(oiSelectMap.containsKey(oiLine.Id))
                {
					Utilities.writeLog('Calling convertOIToJSON on OrderItem: '+oiSelectMap.get(oiLine.Id), woOrderItemExtension.class, 'convertOIToJSON', LoggingLevel.DEBUG);    	
                    convertOIToJSON(this.oiSelectMap.get(oiLine.Id));
                }
            }
            oiGen.writeEndArray();
        }
      	oiGen.writeEndObject();
		
		Utilities.writeLog('Exiting', woOrderItemExtension.class, 'convertOIToJSON', LoggingLevel.DEBUG);    	
    }
    public void passSelected()
    {
        //Placeholder function
    }

}