/*  CHANGE LOG

	jjackson 9/2015  As part of service max project, added equipment ownership field to order items.  Changed the
    order item hierarchy on the visual force page to display Part Ownership (Equipment_Ownership__c) instead of Installation Status.
*/

public class OrderItemHierarchyExtension
{
    Id orderId;
    Order__c theOrder;
    public Map<Id, Order_Item__c> oiMap;
    public String treeJSON {get;set;}
    public List<Id> selectIdList{get;set;}
    public List<SelectOption> woRts{get;set;}
    public String selectedWoRt{get;set;}
    //For Redirecting page to WorkOrder
    public String redirectUrl {public get; private set;}
    public Boolean shouldRedirect {public get; private set;}
    public String selectedKeysJSON {get;set;}
    private Map<String,Id> rtMap;
    public Boolean isPortalUser {get;set;}
	public List<String> recordTypes{get;set;}
    
    public static JSONGenerator gen {
      get {
        if(gen == null)
          gen = JSON.createGenerator(true);
        return gen;
      } 
      set;
    }    
    
    public OrderItemHierarchyExtension(ApexPages.StandardController controller)
    {
    	User currentUser = [SELECT u.Id, u.Name, u.IsPortalEnabled FROM User u WHERE u.Id = :userInfo.getUserId() LIMIT 1][0];
    	this.isPortalUser = currentUser.IsPortalEnabled;
    	selectedKeysJSON = '[]';
    	shouldRedirect = false;
        this.orderId = ((Order__c)controller.getRecord()).Id;
        theOrder = [SELECT Id, Site__c, Contracted_Completion_Date__c, TeamTrack_ID__c, Project_Type__c from Order__c WHERE Id = :orderId];
        //Setup Custom Setting for Work Orde Record Types
        Set<String> recordTypesSet = Work_Order_Record_Types__c.getAll().keySet();
        recordTypes = new List<String>();
        recordTypes.addAll(recordTypesSet);
        recordTypes.sort();
        
        system.debug('Creatable record types are '+recordTypes);
        populateHierarchy(); 
    }
    public void passSelected()
    {       
        //Placeholder function  
    }
    public PageReference createWorkOrder()
    {
        //Convert the comma separated string into List of ID
        /*  Validation for creating Work Orders sans Items
        if(selectedKeysJSON == '' || selectedKeysJSON == null || selectedKeysJSON == '[]')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                       'No Order Items selected', ''));
            return null;
        }
        */
        List<Id> listIds;
        try
        {
        	listIds = (List<ID>) JSON.deserialize(selectedKeysJSON, List<ID>.class);
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in deserializing JSON: '+e.getMessage())); 
        	system.debug('Exception in deserializing JSON '+e.getMessage());
        }
        //Filter the Order items based on type to decide Work Order Record Type
        Map<Id,Order_Item__c> oiMap = new Map<Id,Order_Item__c>([SELECT Name, Status__c, Total_Remaining_Rooms__c, Contracted_Completion_Date__c from Order_Item__c WHERE ID In :listIds]);
        Boolean isInstall = false;
        Boolean isDeinstall = false;
        String workOrderType;
        for(Order_Item__c oi : oiMap.values())
        {
            if(oi.Status__c == 'Pending Install')
                isInstall = true;
            if(oi.Status__c == 'Pending De-Install')
                isDeinstall = true;
        }
        //if only one status then work order is install or deinstall
        //if both then upgrade
        if(isInstall && !isDeinstall)
            workOrderType = 'Install';
        else if(!isInstall && isDeinstall)
            workOrderType = 'De-Install';
        else
            workOrderType = null;
            
        rtMap = Utilities.getRecordTypes('Work_Order__c');
             //       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
              //         ''+rtMap.get('Upgrade').getName(), ''));
        //Compare the right Record type to selected and error if they do not match.
        if((workOrderType != selectedWoRt) && (workOrderType != null))
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                       'Cannot create Work Order of Record Type '+selectedWoRt+' should be of Record Type '+workOrderType, ''));
        	return null;
        }
        system.debug('Selected Work Order record Type is '+selectedWoRt);
        //Create the Work Order first and then attach Associated Items
        try
        {
	        Work_Order__c wo = new Work_Order__c();
	        wo.Site__c = theOrder.Site__c;
	        wo.Contracted_Completion_Date__c = theOrder.Contracted_Completion_Date__c;
	        wo.TeamTrack_ID__c = theOrder.TeamTrack_ID__c;
	        wo.Project_Type__c = theOrder.Project_Type__c;
	        wo.RecordTypeId = rtMap.get(selectedWoRt);
	        insert wo;
	        //List of associated items to attach to work order
	        List<Associated_Item__c> aiList = new List<Associated_Item__c>();
	        for(Id oiId : listIds)
	        {
	            Associated_Item__c ai = new Associated_Item__c(
	            Work_Order__c = wo.Id, 
	            Order_Item__c = oiId,
	            Status__c = oiMap.get(oiId).Status__c,
	            Name = oiMap.get(oiId).Name,
	            Quantity__c = oiMap.get(oiId).Total_Remaining_Rooms__c,
	            Contracted_Completion_Date__c=oiMap.get(oiId).Contracted_Completion_Date__c);
	            aiList.add(ai);
	        }
	        //Insert associated items
	        insert aiList;
	        //Set work order URL to redirect
			redirectUrl = '/'+wo.Id;
			shouldRedirect=true;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                       'Cannot create Work Order: '+e.getMessage(), ''));
        }
        return null;
    }
    private void populateHierarchy() 
    {
        this.oiMap = new Map<Id, Order_Item__c>([SELECT 
                            Name,   
                            Product__r.Name,
                            Status__c,
                            Equipment_Ownership__c,  //Installation_Status__c
                            Total_Rooms_Ordered__c,
                            Total_Remaining_Rooms__c,
                            Contracted_Completion_Date__c,
                            Price__c,
                            Parent__c,
                            (SELECT Id, Parent__c FROM Order_Items__r)
                          FROM 
                               Order_Item__c  
                          WHERE 
                            Order__c = :orderId
                          ORDER BY 
                              Parent__c]);
                            
      if(this.oiMap.size() > 0){
           getTreeJSON();
      } else {
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                       '<b>No Order Items on Order.</b>', 
                       ''));
      }
    } 
    
    private void getTreeJSON() {
        gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for(Order_Item__c oi : this.oiMap.values()) {
          if(null == oi.Parent__c)
              convertNodeToJSON(oi);
        }
        gen.writeEndArray();
        this.TreeJSON = gen.getAsString();
    }
    private void convertNodeToJSON(Order_Item__c oi)
    {
      
        gen.writeStartObject();
        if(oi.Id != null)
        {
          gen.writeStringField('key', oi.Id);
          gen.writeStringField('href','/'+oi.Id);
          gen.writeStringField('target', '_top');
        }
        if(null != oi.Product__r.Name) 
            gen.writeStringField('title', oi.Product__r.Name);
        if(null != oi.Parent__c)
            gen.writeStringField('parentkey',oi.Parent__c);
        if(null != oi.Status__c)
            gen.writeStringField('status', oi.Status__c);
//        if(null != oi.Installation_Status__c)
//            gen.writeStringField('installationstatus', oi.Installation_Status__c);
        if(null != oi.Equipment_Ownership__c)
            gen.writeStringField('equipownership', oi.equipment_ownership__c);
        if(null != oi.Total_Rooms_Ordered__c)
            gen.writeNumberField('roomsordered', oi.Total_Rooms_Ordered__c);
        if(null != oi.Total_Remaining_Rooms__c)
            gen.writeNumberField('remainingrooms', oi.Total_Remaining_Rooms__c);
        if(null != oi.Price__c)
            gen.writeNumberField('price', oi.Price__c);
        gen.writeBooleanField('unselectable', true);
        gen.writeBooleanField('expanded', true);
        gen.writeBooleanField('hideCheckbox', this.isPortalUser);
        if(oi.Order_Items__r.size() == 0) {
          gen.writeBooleanField('folder', false);
        } else {
          gen.writeBooleanField('folder', true);
          gen.writeFieldName('children');
            gen.writeStartArray(); 
            for(Order_Item__c oiLine : oi.Order_Items__r) {
                if(oiMap.containsKey(oiLine.Id))
              convertNodeToJSON(this.oiMap.get(oiLine.Id));    
            }
            gen.writeEndArray();       
        }
      gen.writeEndObject();
    }  
    
}