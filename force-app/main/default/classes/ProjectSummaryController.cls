public without sharing class ProjectSummaryController
{
    private ApexPages.StandardController controller;
    public Work_Order__c workOrder;
    public Boolean isContractor{get;set;}
    public Map<Id,Asset> assetMap{get;set;}
    public List<Associated_Item__c> aItems;
    public Map<Associated_Item__c,Id> aiToOi;
    public Account acct{get;set;}
    public List<Contract__c> contracts{get;set;}
    public Map<Id,List<Order_Item__c>> orderItemIdToChildren{get;set;}
    public Map<Id,List<Id>> orderItemIdToChildrenIds{get;set;}
    public Map<Id,List<Asset>> assetIdToChildren{get;set;}
    public Map<Id,List<Id>> assetIdToChildrenIds{get;set;}
    public Set<Id> assetTopLevelIds{get;set;}
    public Set<Id> topLevelIds{get;set;}
    public Set<Id> cancelLevelIds{get;set;}
    public Map<Id,List<Order_Item__c>> cancelItemIdToChildren{get;set;}
    public Map<Id,List<Id>> cancelItemIdToChildrenIds{get;set;}
    public Map<Id,Order_Item__c> oiInstallMap{get;set;}
    public Map<Id,Order_Item__c> oiInstallIdMap{get;set;}
    public Map<Id,Order_Item__c> oiCancelMap{get;set;}
    //These maps are for checking against whether values should be coloured or not
    //Coloured values are the ones that actually apply in the views
    public Map<Id,String> oiInstallCheckMap{get;set;}
    public Map<Id,String> oiCancelCheckMap{get;set;}
    //These maps are used to check values against in the net new/cancel maps
    public Map<Id,String> assetValuesMap{get;set;}
    public Set<Id> installChanged{get;set;}
    public Set<Id> cancelChanged{get;set;}
    
    public Boolean showAssets{get;set;}
    public static JSONGenerator installgen {
      get {
        if(installgen == null)
          installgen = JSON.createGenerator(true);
        return installgen;
      } 
      set;
    }    
    public static JSONGenerator cancelgen {
      get {
        if(cancelgen == null)
          cancelgen = JSON.createGenerator(true);
        return cancelgen;
      } 
      set;
    }  
    public static JSONGenerator assetgen {
      get {
        if(assetgen == null)
          assetgen = JSON.createGenerator(true);
        return assetgen;
      } 
      set;
    }   
    
    public String installTreeJSON {get;set;}
    public String cancelTreeJSON {get;set;}
    public String assetTreeJSON {get;set;}
    
    
    public ProjectSummaryController(ApexPages.StandardController controller)
    {
        Utilities.writeLog('Entering', ProjectSummaryController.class, 'ProjectSummaryController', LoggingLevel.DEBUG);                             
        
        this.controller = controller;
        workOrder = (Work_Order__c)controller.getRecord();
        workOrder = [SELECT Site__c FROM Work_Order__c WHERE Id = :workOrder.Id];
        if(workOrder.Site__c == null)
        {
            workOrder.addError('No Site found on WorkOrder');
        }
        //Get Profile of current User
        String profileName = Utilities.ProfileIdToName(UserInfo.getProfileId());
         if(profileName == 'Installer Partner User')
         {
           isContractor = true;
         }
         else
         {
           isContractor = false;
         }
        //Quering account
        acct = [SELECT Name, Site_ID__c, Site_Id_Ext_id__c, Physical_Street_Address_Line_1__c, Physical_Street_Address_Line_2__c, Physical_City__c,Physical_State__c,
        Physical_Postal_Code__c, Phone, of_Rooms__c
        from Account WHERE Id = :workOrder.Site__c];
        
        //Querying associated items
        aItems = [SELECT Status__c, Order_Item__c, Order_Item__r.Name, Order_Item__r.Order__c, Name from Associated_Item__c WHERE Work_Order__c = :workOrder.Id];
        Utilities.writeLog('Associated Items ordered' +aItems, ProjectSummaryController.class, 'ProjectSummaryController', LoggingLevel.DEBUG);                             
        
        //Map of Associated Item ids to Order Item ID
        aiToOi = new Map<Associated_Item__c,Id>();
        
        //Sorting out Order accounts, Install, Cancellation
        List<Id> oiIds = new List<Id>();
        List<Id> orderIds = new List<Id>();
        for(Associated_Item__c ai : aItems)
        {
            oiIds.add(ai.Order_Item__c);
            orderIds.add(ai.Order_Item__r.Order__c);
            aiToOi.put(ai,ai.Order_Item__c);
        }
        //Querying Order        
        Map<Id,Order__c> orderMap = new Map<Id,Order__c>([SELECT Id, Legal_Contract__c from Order__c WHERE Id IN :orderIds]);
        
        //Query Assets and Order Items
        assetMap = new Map<Id,Asset>([SELECT Product2.Name, Product2.ProductCode, Product2Id, Parent_Asset__c, Status,  (SELECT Id, Parent_Asset__c FROM Product_Inventory_Line_Items__r) from Asset WHERE AccountId = :workOrder.Site__c ORDER BY Parent_Asset__c]);
        Utilities.writeLog('Assets queried: ' +assetMap, ProjectSummaryController.class, 'ProjectSummaryController', LoggingLevel.DEBUG);                             
       
        List<Order_Item__c> oiInstallList = [SELECT Name, Legal_Contract_Line_Item__r.Legal_Contract__c, Status__c, Parent__c, Parent__r.Parent__r.Parent__r.Parent__r.Parent__r.Parent__c, Product__c, Product__r.Name, (SELECT Id, Status__c, Parent__c from Order_Items__r) from Order_Item__c WHERE Id IN :oiIds AND Order__c IN :orderMap.keyset() ORDER BY Parent__c];
        Utilities.writeLog('Total Order Items queried: ' +oiInstallList, ProjectSummaryController.class, 'ProjectSummaryController', LoggingLevel.DEBUG);                             
        
        List<Order_Item__c> oiCancelList = oiInstallList;
        
        //Get ids for Contracts from ORders
        List<Id> contractIds = new List<Id>();
        for(Order_Item__c oiInstall : oiInstallList)
        {
            contractIds.add(oiInstall.Legal_Contract_Line_Item__r.Legal_Contract__c);
        }
        //Querying Contracts, either contracts looking up to orders or contract lookup off of order
        List<Contract__c> contractsList = [SELECT Name, Scope_of_Work__c, Contract_Type__c, ATSC_Rooms__c, NTSC_Rooms__c, Refurbished_GP__c, Refurbished_FTG_Analog__c, Refurbished_FTG_HD__c, TV_Type__c, 
        Type__c, Contract_Term_months__c, Contract_End_Date__c, Auto_Renew__c, LITs__c, Media_DS_Contract_ID__c, MATV_Waiver__c, SD_Channels__c, HD_Channels__c, 
        Analog_Channels__c, Total_Channels__c,TOD_Sub_K__c, TOD_Project_E__c, PS_DS_Contract_ID__c
        from Contract__c WHERE Id IN :contractIds OR Order__c IN : orderIds];
        //Query contracts into Set
        Set<Contract__c> contractsSet= new Set<Contract__c>();
        contractsSet.addAll(contractsList);
        //Cast Contracts Set back into List
        contracts = new List<Contract__c>();
        contracts.addAll(contractsSet);
        Utilities.writeLog('All Contracts List :' +contracts, ProjectSummaryController.class, 'ProjectSummaryController', LoggingLevel.DEBUG);                             
        
        // put in Set to avoid duplicates
        Set<Order_Item__c> oiInstallSet = new Set<Order_Item__c>();
        Set<Order_Item__c> oiCancelSet = new Set<Order_Item__c>();
        oiInstallSet.addAll(oiInstallList);
        oiCancelSet.addAll(oiCancelList);
        //Create Maps with Id as Product__c to compare against Asset with
        oiInstallMap = new Map<Id,Order_Item__c>();
        oiInstallIdMap = new Map<Id,Order_Item__c>();
        for(Order_Item__c oi : oiInstallSet)
        {
            oiInstallMap.put(oi.Product__c,oi); 
            oiInstallIdMap.put(oi.Id,oi);
        }
        //Compare with Assets to find net new,create Map of Assets
        assetValuesMap = new Map<Id,String>();
        for(Asset a : assetMap.values())
        {
            assetValuesMap.put(a.Id,a.Status);
        }
        
        //Create Cancel Map
        oiCancelMap = new Map<Id,Order_Item__c>();
        for(Order_Item__c oi : oiCancelSet)
        {
            oiCancelMap.put(oi.Id,oi);  
        }
        
        //For Install List we want all parents to match status
        List<Order_Item__c> leafOis = new List<Order_Item__c>();
        for(Order_Item__c oi : oiInstallIdMap.values())
        {
            if(oi.Status__c == 'Pending Installation Activate' || oi.Status__c == 'Pending Installation Deactivate')
                leafOis.add(oi);
        }
        //Get parents previous values as well as change all statuses to pending install
        installChanged = findParents(leafOis, 'Install');
        //oiInstallMap now has net new Order Items
        getInstallTreeJSON();
                
        //For Cancel List we want all parents to match status
        leafOis = new List<Order_Item__c>();
        for(Order_Item__c oi : oiCancelMap.values())
        {
            if(oi.Status__c == 'Pending De-Installation')
                leafOis.add(oi);
        }
        //Get parents previous values as well as change all statuses to pending install
        cancelChanged = findParents(leafOis, 'Cancel');
                

        //oiCancelMap now has net new Order Items        
        getCancelTreeJSON();
        getAssetTreeJSON();    
        Utilities.writeLog('Exiting', ProjectSummaryController.class, 'ProjectSummaryController', LoggingLevel.DEBUG);                                         
    }

    //We're modifying the parents to have the same status as their children so the Install Tree will pick it up
    //No DML is used so Status modification isn't permanent
    //Input is a list of all OIs whos status Install status
    private Set<Id> findParents(List<Order_Item__c> oiList, String typeOi)
    {
        Utilities.writeLog('Entering', ProjectSummaryController.class, 'findParents', LoggingLevel.DEBUG);                            
        Utilities.writeLog('List of Order Items need Parent Modification: '+oiList, ProjectSummaryController.class, 'findParents', LoggingLevel.DEBUG);                           
        
        Set<Id> parentIds = new Set<Id>();
        if(oiList.size() == 0)
            return parentIds;
        try{
            for(Order_Item__c oi : oiList)
            {
                while(oi != null)
                {
                    if(oi.Parent__c != null)
                        parentIds.add(oi.Parent__c);
                    oi = oi.Parent__r;
                }
            }
            Utilities.writeLog('Id list of all Parents: '+parentIds, ProjectSummaryController.class, 'findParents', LoggingLevel.DEBUG);                              
        }
        catch(System.Exception e)
        {
            Utilities.writeLog('Cannot get parent Ids '+e.getStackTraceString(), ProjectSummaryController.class, 'findParents', LoggingLevel.DEBUG);                              
        }
        //Change status of parents based on workOrder
        for(Id parentId : parentIds)
        {
            Order_Item__c parentTempOi;
            if(typeOi == 'Install')
            {
                Utilities.writeLog('Current oiInstallidMap : '+oiInstallIdMap, ProjectSummaryController.class, 'findParents', LoggingLevel.DEBUG);                            
                parentTempOi = oiInstallIdMap.remove(parentId);
                system.debug('parentTempOi '+parentTempOi);
                parentTempOi.Status__c = 'Pending Installation Activate';
                oiInstallIdMap.put(parentId,parentTempOi);
            }
            else if(typeOi == 'Cancel')
            {
                parentTempOi = oiCancelMap.remove(parentId);
                parentTempOi.Status__c = 'Pending De-Installation';
                oiCancelMap.put(parentId,parentTempOi);
            }
            Utilities.writeLog('Order Item whose status is being temporarily changed '+parentTempOi + ' size of children '+parentTempOi.Order_Items__r.size(),
            ProjectSummaryController.class, 'findParents', LoggingLevel.DEBUG);                           
        }    
        Utilities.writeLog('Exiting', ProjectSummaryController.class, 'findParents', LoggingLevel.DEBUG);                             
        return parentIds;   
    }
    /*
    private void filterListsByAssociatedItems()
    {
        for(Associated_Item__c ai : aiToOi.keySet())
        {
            if(ai.Status__c == 'Installed On' || ai.Status__c == 'Installed Off')
            {
                if(oiInstallIdMap.containsKey(ai.Order_Item__c))
                    oiInstallCheckMap.put(ai.Order_Item__c, 'yes');
            }
            else if(ai.Status__c == 'De-Installed')
            {
                if(oiCancelMap.containsKey(ai.Order_Item__c))
                    oiCancelCheckMap.put(ai.Order_Item__c, 'yes');
            }
        }   
    }
    */
    
    private void getAssetTreeJSON() {
        assetgen = JSON.createGenerator(true);
        assetgen.writeStartArray();
        for(Asset ass : this.assetMap.values()) {
          if(null == ass.Parent_Asset__c)
              convertAssetNodeToJSON(ass);
        }
        assetgen.writeEndArray();
        this.assetTreeJSON = assetgen.getAsString();
    }

    private void convertAssetNodeToJSON(Asset ass)
    {
      
        assetgen.writeStartObject();
        if(ass.Id != null)
        assetgen.writeStringField('key', ass.Id);
        if(null != ass.Product2.Name) {
            assetgen.writeStringField('title', ass.Product2.Name);
        }
        assetgen.writeBooleanField('unselectable', true);
        assetgen.writeBooleanField('expanded', true);
        if(ass.Product_Inventory_Line_Items__r.size() == 0) {
          assetgen.writeBooleanField('folder', false);
        } else {
          assetgen.writeBooleanField('folder', true);
          assetgen.writeFieldName('children');
            assetgen.writeStartArray(); 
            for(Asset assLine : ass.Product_Inventory_Line_Items__r) {
                if(assetMap.containsKey(assLine.Id))
              convertAssetNodeToJSON(this.assetMap.get(assLine.Id));    
            }
            assetgen.writeEndArray();       
        }
      assetgen.writeEndObject();
    }  
    
    
    private void getInstallTreeJSON() {
        installgen = JSON.createGenerator(true);
        installgen.writeStartArray();
        for(Order_Item__c oi : this.oiInstallIdMap.values()) {
          if(null == oi.Parent__c)
              convertInstallOrderNodeToJSON(oi);
        }
        installgen.writeEndArray();
        this.installTreeJSON = installgen.getAsString();
    }

    private void convertInstallOrderNodeToJSON(Order_Item__c oi)
    {
        //Filter by Order Item Install Status
        if(oi.Status__c != 'Pending Installation Activate' && oi.Status__c != 'Pending Installation Deactivate')
            return;
        //Check to see if this is real net new
        Boolean netNew = true;
        if(assetValuesMap.containsKey(oi.Id)) //Check if asset with Status installed de/activated exists 
            if(assetValuesMap.get(oi.Id) == 'Installed Activated' || assetValuesMap.get(oi.Id) == 'Installed Deactivated')
                netNew = false;
        if(installChanged.contains(oi.Id))
            netNew = false;
            
        //Start JSON write      
        installgen.writeStartObject();
        if(oi.Id != null)
        installgen.writeStringField('key', oi.Id);
        if(null != oi.Product__r.Name) 
        {
            if(netNew == true)
                installgen.writeStringField('title', oi.Product__r.Name + ' ++ ');
            else
                installgen.writeStringField('title', oi.Product__r.Name);
        }
        if(netNew == true)
            installgen.writeBooleanField('netnew',true);
        installgen.writeBooleanField('unselectable', true);
        installgen.writeBooleanField('expanded', true);
        if(oi.Order_Items__r.size() == 0) {
          installgen.writeBooleanField('folder', false);
        } else {
          installgen.writeBooleanField('folder', true);
          installgen.writeFieldName('children');
            installgen.writeStartArray(); 
            for(Order_Item__c oiLine : oi.Order_Items__r) {
                if(oiInstallIdMap.containsKey(oiLine.Id))
              convertInstallOrderNodeToJSON(this.oiInstallIdMap.get(oiLine.Id));    
            }
            installgen.writeEndArray();       
        }
      installgen.writeEndObject();
    }  
    private void getCancelTreeJSON()
    {
        cancelgen.writeStartArray();
        for(Order_Item__c oi : this.oiCancelMap.values()) {
        if(null == oi.Parent__c)
            convertCancelOrderNodeToJSON(oi);
        }
        cancelgen.writeEndArray();
        this.cancelTreeJSON = cancelgen.getAsString();

    }
    private void convertCancelOrderNodeToJSON(Order_Item__c oi)
    {
        //Filter Order Item by Cancel Node
        if(oi.Status__c != 'Pending De-Installation')
            return;
        //Check to see if this is real net cancel
        Boolean netCancel = true;
        if(assetValuesMap.containsKey(oi.Id)) //Check if asset with Status installed de/activated exists 
            if(assetValuesMap.get(oi.Id) == 'De-Installed')
                netCancel = false;
        if(cancelChanged.contains(oi.Id))
            netCancel = false;
        
        
        //Start JSON write      
        cancelgen.writeStartObject();
        if(oi.Id != null)
        cancelgen.writeStringField('key', oi.Id);
        if(null != oi.Product__r.Name) 
        {
            if(netCancel == true)
                cancelgen.writeStringField('title', oi.Product__r.Name + ' -- ');           
            else
                cancelgen.writeStringField('title', oi.Product__r.Name);
        }
        if(netCancel == true)
            cancelgen.writeBooleanField('netCancel',true);
        cancelgen.writeBooleanField('unselectable', true);
        cancelgen.writeBooleanField('expanded', true);
        if(oi.Order_Items__r.size() == 0) {
          cancelgen.writeBooleanField('folder', false);
        } else {
          cancelgen.writeBooleanField('folder', true);
          cancelgen.writeFieldName('children');
            cancelgen.writeStartArray(); 
            for(Order_Item__c oiLine : oi.Order_Items__r) {
                if(oiCancelMap.containsKey(oiLine.Id))
              convertCancelOrderNodeToJSON(this.oiCancelMap.get(oiLine.Id));    
            }
            cancelgen.writeEndArray();       
        }
      cancelgen.writeEndObject();
    }  
    
}