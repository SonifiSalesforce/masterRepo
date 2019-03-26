/****LOG***********************************************************************************
   shawks 10/2018   -- CPQ:        Comment out Delivery Method references since not used in CPQ
   jjackson 10/2018 -- replaced reference to order_item__c.product_inventory__c with asset__c
       so that the product_inventory__c field can be deleted
   shawks 11/21/2017 - BUG-00753:  New Work Order to update Installed Qty for Product Inventory
   shawks 09/18/2017 - BUG-00176:  Move Delivery Method to Legal Contract Line Items
   shawks 03/30/2017 - BUG-00700:  Add(Price)/Remove(Partial) Work Order Item Columns
/*****************************************************************************************/
public with sharing class WorkOrderItemHierarchyExtension {

    public Work_Order__c workOrder {get;set;}
    public Associated_Item__c ai{get;set;}
    public string treeJSON {get;set;}
    public string statusValuesJSON {get;set;}
    public string monthChargedValuesJSON {get;set;}
    public string quarterChargedValuesJSON {get;set;}
    public string yearChargedValuesJSON {get;set;}
    public String assocItemPrefix {get;set;}
    public String redirectUrl {get;set;}
    public Boolean shouldRedirect {get; set;}
    public String alertMessage {get; set;}
    public Boolean isPortalUser {get;set;}
    public Boolean editMode {get;set;}
    public String saveURL {get;set;}
    public String returnURL {get;set;}
    public String workOrderRecordType {get;set;}
    public Boolean isRackBuild {get;set;}
    public Boolean isCustomWorkOrder {get;set;}
    public Boolean isCircuitWorkOrder {get;set;}
    public Boolean isQtyAdjustWorkOrder {get;set;}  //shawks BUG-00753: Add to track Qty Adjust WO type
    public Integer intAdjQty {get;set;}  //shawks BUG-00753: Use to determine if increment or decrement quantity
    public Id workOrderParentId{get;set;}
	public Set<Id> inDevelopmentIds{get;set;}
	
    public static List<String> AssociatedItemFields {
        get {
            if (AssociatedItemFields == null) {
                AssociatedItemFields = Utilities.getSObjectFields(Associated_Item__c.getSObjectType(), false);
            }
            return AssociatedItemFields;
        }
        private set;
    }
    
    public static List<String> WorkOrderFields {
        get {
            if (WorkOrderFields == null) {
                WorkOrderFields = Utilities.getSObjectFields(Work_Order__c.getSObjectType(), false);
            }
            return WorkOrderFields;
        }
        private set;
    }

    public Map<ID, Associated_Item__c> assocItemMap {
        get {
            if(assocItemMap==null)
                assocItemMap = new Map<ID, Associated_Item__c>();
            return assocItemMap;
        }
        set;
    }

    public Map<ID, List<Associated_Item__c>> orderAssocItemMap {
        get {
            if(orderAssocItemMap==null)
                orderAssocItemMap = new Map<ID, List<Associated_Item__c>>();
            return orderAssocItemMap;
        }
        set;
    }

    public Map<ID, Order_Item__c> orderMap  {
        get {
            if(orderMap==null)
                orderMap = new Map<ID, Order_Item__c>();
            return orderMap;
        }
        set;
    }

    public static JSONGenerator gen {
        get {
            if(gen == null)
                gen = JSON.createGenerator(true);
            return gen;
        }
        set;
    }

    public class EditedField {
        public string FieldName {get;set;}
        public string FieldValue {get;set;}

        public EditedField(){}
    }

    public class EditedAssociatedItem {
        public string RecordId {get;set;}
        public List<EditedField> editedFields {get;set;}

        public EditedAssociatedItem() {
            RecordId = ' ';
            editedFields = new List<EditedField>();
        }

        public EditedAssociatedItem(String recdId,List<EditedField> edfields ) {
            RecordId = recdId;
            editedFields = edfields.clone();
        }

    }

    public string editedFieldJSON {
        get {
            return JSON.serialize(new EditedField());
        }
        set;
    }

    public string editedAssociatedItemJSON {
        get {
            return JSON.serialize(new EditedAssociatedItem());
        }
        set;
    }

    public WorkOrderItemHierarchyExtension(ApexPages.StandardController controller)
    {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'WorkOrderItemHierarchyExtension', LoggingLevel.DEBUG);
        this.editMode = false;
        this.saveURL = null;
        this.returnURL = null;

        if(ApexPages.currentPage().getParameters().containsKey('mode')) {
            if(ApexPages.currentPage().getParameters().get('mode').equalsIgnoreCase('edit'))
                this.editMode = true;
        }

        if(ApexPages.currentPage().getParameters().containsKey('saveURL')) {
            this.saveURL = ApexPages.currentPage().getParameters().get('saveURL');
        }

        if(ApexPages.currentPage().getParameters().containsKey('retURL')) {
            this.returnURL = ApexPages.currentPage().getParameters().get('retURL');
        }

        User currentUser = [SELECT u.Id, u.Name, u.IsPortalEnabled FROM User u WHERE u.Id = :userInfo.getUserId() LIMIT 1][0];
        this.isPortalUser = currentUser.IsPortalEnabled;

        Schema.DescribeSObjectResult dsr = Associated_Item__c.SObjectType.getDescribe();
        this.assocItemPrefix = dsr.getKeyPrefix();
        this.shouldRedirect = false;
        setStatusPicklistValues();
        setMonthChargedPicklistValues();
        setQuarterChargedPicklistValues();
        setYearChargedPicklistValues();

        Work_Order__c currentWorkOrder= (Work_Order__c)controller.getRecord();
        //shawks BUG-00753: Add Site Name, Site Type, Project Type, Work Order Number, and CreatedBy to SOQL
        currentWorkOrder = [SELECT RecordTypeId, Approver__c, Install_Manager__c, Parent_Work_Order__c,
                            Site__r.Name, Site__r.Type, Project_Type__c, Work_Order_Number__c, CreatedBy.Name
							FROM Work_Order__c WHERE Id = :currentWorkOrder.Id];        
        if(currentWorkOrder.Parent_Work_Order__c != null)
        	workOrderParentId = currentWorkOrder.Parent_Work_Order__c;
        this.workOrder = currentWorkOrder;
        	
        if(Utilities.RecordTypeIdToName('Work_Order__c', currentWorkOrder.RecordTypeId) == 'Rack Build')
            this.isRackBuild = true;
        else
            this.isRackBuild = false;

        if(Utilities.RecordTypeIdToName('Work_Order__c', currentWorkOrder.RecordTypeId) == 'Circuits')
            this.isCircuitWorkOrder = true;
        else
            this.isCircuitWorkOrder = false;

        if(Utilities.RecordTypeIdToName('Work_Order__c', currentWorkOrder.RecordTypeId) == 'Customization')
            this.isCustomWorkOrder = true;
        else
            this.isCustomWorkOrder = false;
        
        //shawks BUG-00753: Add to detemine if "Install Qty Adjustment" WO type and if +/- the quantity
        if(Utilities.RecordTypeIdToName('Work_Order__c', currentWorkOrder.RecordTypeId) == 'Install Qty Adjustment'){
           this.isQtyAdjustWorkOrder = true;
           //Adjust Up -> 1; Adjust Down -> (-1); Other -> 0
           if(currentWorkOrder.Project_Type__c == 'Adjust Up'){
              intAdjQty = 1;}
           else if(currentWorkOrder.Project_Type__c == 'Adjust Down'){
              intAdjQty = -1;}
           else{
              intAdjQty = 0;}
        }
        else{
           this.isQtyAdjustWorkOrder = false;
        }
        this.ai = new Associated_Item__c(Billing_Commencement_Date__c=null);
        //populate set of indevelopment items
        this.inDevelopmentIds = new Set<Id>();
        populateInDevelopment();
        //Initialize data for hierarchy
        populateHierarchy();
			
        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'WorkOrderItemHierarchyExtension', LoggingLevel.DEBUG);
    }

    public PageReference saveAssociatedItems() {
         Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'saveAssociatedItems', LoggingLevel.DEBUG);

        if (ApexPages.currentPage().getParameters().containsKey('editedData')) {
            String jsonString = ApexPages.currentPage().getParameters().get('editedData');
            Utilities.writeLog('jsonString....' + jsonString, WorkOrderItemHierarchyExtension.class, 'saveAssociatedItems', LoggingLevel.DEBUG);
			
			//Returning for null data
			if(jsonString == '')
				return null;
            List<EditedAssociatedItem> editAssociatedItems = (List<EditedAssociatedItem>) JSON.deserialize(jsonString,List<EditedAssociatedItem>.class);
            Utilities.writeLog('editAssociatedItems.size()....' + editAssociatedItems.size(), WorkOrderItemHierarchyExtension.class, 'saveAssociatedItems', LoggingLevel.DEBUG);

            if (editAssociatedItems.size() > 0) {
                List<Associated_Item__c> associatedItems = new List<Associated_Item__c>();
                //shawks BUG-00753: if an “Install Qty Adjustment” work order create SET and MAP used for quantity comparisons
                set<Id> itemids = new set<Id>();
                list<Associated_Item__c> selectedlist = new list<Associated_Item__c>();
                map<Id, Associated_Item__c> mpassocitems = new map<Id, Associated_Item__c>();
                if(this.isQtyAdjustWorkOrder){
                   for(EditedAssociatedItem selectedItem: editAssociatedItems){
                      itemids.add(selectedItem.RecordId);
                   }
                   //Use SOQL to retrieve Associated_Item__c info
                   selectedlist = [ SELECT Id, Name, order_item__r.asset__r.quantity, order_item__r.asset__r.Total_Active_Rooms__c
                                    FROM associated_item__c WHERE Id IN :itemids ];
                   for(Associated_Item__c assocItem : selectedlist){  //Create Map
                      mpassocitems.put(assocItem.Id, assocItem);
                   }
                }  //End of if(this.isQtyAdjustWorkOrder)
                for(EditedAssociatedItem editAI : editAssociatedItems) {
                    Associated_Item__c associatedItem = new Associated_Item__c(Id = editAI.RecordId);
                    for(EditedField editField : editAI.editedFields) {
                        //shawks BUG-00753: if an “Install Qty Adjustment” work order, only change quantity if valid adjustment quantity
                        if(this.isQtyAdjustWorkOrder) {
                           if(editField.FieldName == 'Quantity__c') {
                              Integer newintval =  Integer.valueof(editField.FieldValue);
                              Integer maxQty = Integer.valueof(mpassocitems.get(editAI.RecordId).order_item__r.asset__r.quantity);
                              Integer currentQty = Integer.valueof(mpassocitems.get(editAI.RecordId).order_item__r.asset__r.total_active_rooms__c);
                              if(intAdjQty == 0){
                                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '<b>Change not saved</b>', 
                                    'Incorrect Project Type on Work Order'));
                                 return null;
                              }
                              else if(currentQty+(intAdjQty*math.abs(newintval)) <= maxQty){
                                 associatedItem.put(editField.FieldName,math.abs(newintval));
                              }
                              else {
                                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '<b>Change not saved</b>', 
                                    'Quantity Adjustment is too large for <b>'+mpassocitems.get(editAI.RecordId).name+'</b>'));
                                 return null;
                              }  //END if(editField.FieldName == 'Quantity__c')
                           }
                        } else if (editField.FieldName == 'Billing_Commencement_Date__c') {
                            if(editField.FieldValue!=''){
	                            date mydate = date.parse(editField.FieldValue);
	                            associatedItem.put(editField.FieldName,mydate);
                        	} else {
                        		associatedItem.put(editField.FieldName,null);
                        	}
                        } else if (editField.FieldName == 'Quantity__c' ) {
                            Integer newintval =  Integer.valueof(editField.FieldValue);
                            associatedItem.put(editField.FieldName,newintval);
                            
                        } else if (editField.FieldName == 'Mod_Channel__c' ) {
                            Decimal newintval =  Decimal.valueof(editField.FieldValue);
                            associatedItem.put(editField.FieldName,newintval);
                        } else if (editField.FieldName == 'Receiver_Channel__c' ) {
                            Integer newintval =  Integer.valueof(editField.FieldValue);
                            associatedItem.put(editField.FieldName,newintval);
                        /*shawks - BUG-00700 - Remove Partial
                        } else if (editField.FieldName == 'Partial_Order__c' ) {
                            if (editField.FieldValue == 'true')
                            {
                               associatedItem.put(editField.FieldName,true);
                            } else {
                                associatedItem.put(editField.FieldName,false);
                            }
                        /*/
                        } else {
                            associatedItem.put(editField.FieldName,editField.FieldValue);
                        }
                    }
                    associatedItems.add(associatedItem);
                }

                Savepoint sp = Database.setSavepoint();
                try{
                    update associatedItems;
                    populateHierarchy();

                    // commented out per BUG-00253 jjohnson20140917
                    //this.shouldRedirect = true;
                    //PageReference pageRef = new ApexPages.StandardController(this.workOrder).view();
                    //pageRef.setRedirect(true);
                    //this.redirectUrl = pageRef.getUrl();
                    
                }
                catch(DMLException dmlEx) {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                               '<b>An Error has occurred. No Order Items selected from this Work Order have been updated.</b>',
                                                               'Exception....Cause:' + dmlEx.getCause() + '::Message:' + dmlEx.getMessage()));
                    Utilities.writeLog('DMLException....Cause:' + dmlEx.getCause() + '::Message:' + dmlEx.getMessage()+'::Fields:'+dmlEx.getDmlFieldNames(0), WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);
                }
                catch(Exception ex) {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                               '<b>An Error has occurred.No Order Items selected from this Work Order have been updated.</b>',
                                                               'Exception....Cause:' + ex.getCause() + '::Message:' + ex.getMessage()));
                    Utilities.writeLog('Exception....Cause:' + ex.getCause() + '::Message:' + ex.getMessage(), WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);
                }
            }
        }

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'saveAssociatedItems', LoggingLevel.DEBUG);

        return null;
    }

    public PageReference cloneAssociatedItems() {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);

        if (ApexPages.currentPage().getParameters().containsKey('selectedAssocItemIDs')) {
            String jsonString = ApexPages.currentPage().getParameters().get('selectedAssocItemIDs');
            List<ID> selectedIds = (List<ID>) JSON.deserialize(jsonString,List<ID>.class);
            List<ID> associatedItemIDs = new List<ID>();
            for(ID selectedID : selectedIds){
                if(String.valueOf(selectedID).startsWith(this.assocItemPrefix)){
                    associatedItemIDs.add(selectedID);
                }
            }
            Utilities.writeLog('associatedItemIDs List::'+associatedItemIDs, WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);
            List<Associated_Item__c> selectedAssociatedItems = retrieveAssociatedItems(associatedItemIDs);
            if(selectedAssociatedItems.size()>0){
                Savepoint sp = Database.setSavepoint();
                try{
                    List<Associated_Item__c> cloneAssociateItems =  selectedAssociatedItems.deepClone();
                    //Reset submitted for billing flag, this prevents it from being billed if true
                    for(Associated_item__c ai : cloneAssociateItems)
                    {
                    	ai.Submitted_for_Billing__c = false;
                    }
                    insert(cloneAssociateItems);
                    populateHierarchy();

                    this.shouldRedirect = true;
                    PageReference pageRef = Page.WorkOrderItemHierarchy;
                    pageRef.getParameters().put('Id',this.workOrder.Id);
                    pageRef.getParameters().put('mode','edit');
                    pageRef.getParameters().put('saveURL',this.saveURL);
                    pageRef.getParameters().put('retURL',this.returnURL);
                    pageRef.setRedirect(true);
                    this.redirectUrl = pageRef.getUrl();
                }
                catch(DMLException dmlEx) {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                               '<b>An Error has occurred.No Order Items selected from this Work Order have been cloned.</b>',
                                                               'Exception....Cause:' + dmlEx.getCause() + '::Message:' + dmlEx.getMessage()));
                    Utilities.writeLog('DMLException....Cause:' + dmlEx.getCause() + '::Message:' + dmlEx.getMessage()+'::Fields:'+dmlEx.getDmlFieldNames(0), WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);
                }
                catch(Exception ex) {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                               '<b>An Error has occurred.No Order Items selected from this Work Order have been cloned.</b>',
                                                               'Exception....Cause:' + ex.getCause() + '::Message:' + ex.getMessage()));
                    Utilities.writeLog('Exception....Cause:' + ex.getCause() + '::Message:' + ex.getMessage(), WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);
                }
            }
        }

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);
        return null;
    }
    public PageReference massUpdateFields()
    {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        String keys = params.get('selectedKeys');
        String selectedStatus = params.get('selectedStatus');
        String selectedQuantity = params.get('selectedQuantity');
        String selectedMonthCharged = params.get('selectedMonthCharged');
        String selectedYearCharged = params.get('selectedYearCharged');
        String selectedQuarterCharged = params.get('selectedQuarterCharged');
        String selectedBCD = params.get('selectedBCD');
        String blankBCD = params.get('blankBCD');

        system.debug('selectedbcd is ' +selectedBCD);
        system.debug('selectedStatus is ' +selectedStatus);
        system.debug('params are '+params);
        system.debug('input parameters into mass update are '+selectedStatus+'  '+selectedQuantity+'   '+selectedMonthCharged+'   '+selectedYearCharged + selectedBCD);
        if(keys != null || selectedStatus != null || selectedQuantity != null || selectedQuarterCharged != null || selectedMonthCharged != null || selectedYearCharged != null || selectedBCD != null)
        {
            //intialize variables
            Id contractId = null;
            //get all the parameters
            List<String> selectedKeysString = new List<String>();
            List<Id> selectedKeys = new List<Id>();
            List<Associated_Item__c> asList = new List<Associated_Item__c>();
            List<Associated_Item__c> selectedlist = new list<Associated_Item__c>();   //**** added by Joan
            //get the parameters and set their values
            if(params.containsKey('selectedKeys')){
                System.debug('SelectedKeys::' +keys);
                selectedKeysString = (List<String>) JSON.deserialize(keys, List<String>.class);
           
            }
            //remove Non Ids from List
            Set<Id> itemid = new set<Id>();
            for(String selectedKey : selectedKeysString)
            {
                if(selectedKey.startsWith(Associated_Item__c.sObjectType.getDescribe().getKeyPrefix()))
                {
                	//Make sure we don't include in development items
                	if(!this.inDevelopmentIds.contains(selectedKey))
                    	selectedKeys.add((Id)selectedKey);
                    	itemid.add((Id)selectedKey);
                }
            }
            System.debug('SelectedKeys: ' + selectedKeys );
            
            //shawks BUG-00753: add quantities from asset used later for comparisons
            selectedlist = [ Select Name, Id, Status__c, order_item__r.asset__r.quantity, order_item__r.asset__r.Total_Active_Rooms__c
                             from Associated_Item__c where Id IN :itemid ];  //***added by Joan
            map<Id, Associated_Item__c> statusmap = new map<Id, Associated_Item__c>();  //***added by Joan
            for(Associated_Item__c assitem : selectedlist) //***added by Joan --create a map of line item id and field data
            {
                	     statusmap.put(assitem.id, assitem);
                	     system.debug('key value pair for statusmap is ' + assitem.id + ', ' + assitem);
                	     system.debug('associated item status is ' +assitem.Name +', ' +assitem.status__c +', ' +assitem.Id);
            }
            String currentstatus;

            for(Id asId : selectedKeys)
            {
            	system.debug('inside selectedKeys loop and key id is ' +asId);
                Associated_Item__c temp = new Associated_Item__c(Id = asId);

                //shawks BUG-00753: IF not an "Install Qty Adjustment" work order set the following values (quantity always set if changed)
                if(!this.isQtyAdjustWorkOrder){
                   if(selectedStatus != null && selectedStatus != '' && selectedStatus != '--None--') {
                      currentstatus = statusmap.get(asId).Status__c;
                      system.debug('Id and currentstatus = ' + asId + ', ' + currentstatus);
                   
                	   //jjackson 4/2014 BUG-00233 made changes to how status values get updated
                	   //must validate that the current status is changing to an eligible status value before
                	   //updating the line item
   
                       temp.status__c = currentstatus;
                                        
                       { if (currentstatus == 'Pending Installation Activate')
                    	   if (selectedStatus == 'Billing' || selectedStatus == 'Cancelled')
                    	      temp.Status__c = selectedStatus;
                       }
                    	   
                       { if (currentstatus == 'Pending De-Installation')
                    	   if (selectedStatus == 'De-Installed' || selectedStatus == 'Cancelled')
                    	      temp.Status__c = selectedStatus;
                       }
                    	   
                       { if (currentstatus == 'Pending Installation Deactivate')
                    	   if(selectedStatus == 'Installed Deactivated' || selectedStatus == 'Cancelled')
                    	      temp.Status__c = selectedStatus;
                       }
                    	   
                       { if (currentstatus == 'Billing')
                    	   if(selectedStatus == 'Installed Deactivated' || selectedStatus == 'Installed Activated')
                    	      temp.Status__c = selectedStatus;
                       }
                    
                       { if (currentstatus == 'Cancelled' || currentstatus == 'Installed Activated' || currentstatus == 'De-Installed' || currentstatus == 'Installed Deactivated')
                    	    temp.Status__c = selectedStatus;
                       }

                   }
                
                   if(selectedQuarterCharged != null && selectedQuarterCharged != '' && selectedQuarterCharged != '--None--')
                       temp.Quarter_Assigned_To__c = selectedQuarterCharged;
                   if(blankBCD == 'true')
                	   temp.Billing_Commencement_Date__c = null;
            	   else 
            	   {
	                   if(selectedBCD != null && selectedBCD != '')
	                       temp.Billing_Commencement_Date__c = Date.parse(selectedBCD);
            	   }
                   if(selectedMonthCharged != null && selectedMonthCharged != '' && selectedMonthCharged != '--None--')
                       temp.Month_Cha__c = selectedMonthCharged;
                   if(selectedYearCharged != null && selectedYearCharged != '' && selectedYearCharged != '--None--')
                       temp.Year_Charged_To__c = selectedYearCharged;
                } //End of if(!this.isQtyAdjustWorkOrder)

                if(selectedQuantity != null && selectedQuantity != '')
                   if(this.isQtyAdjustWorkOrder) {  //shawks BUG-00753: Need to check if adjustment will make larger than allowed quantity
                      Decimal maxQty = statusmap.get(asId).order_item__r.asset__r.quantity;
                      Decimal currentQty = statusmap.get(asId).order_item__r.asset__r.total_active_rooms__c;
                      if(intAdjQty == 0){
                         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '<b>Change not saved</b>', 
                            'Incorrect Project Type on Work Order'));
                         return null;
                      }
                      else if(currentQty+(intAdjQty*math.abs(Decimal.valueOf(selectedQuantity))) <= maxQty) {
                         temp.Quantity__c = math.abs(Decimal.valueOf(selectedQuantity));
                      }
                      else{  //Will exceeded max quantity -> throw error and exit
                         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '<b>Change not saved</b>', 
                            'Quantity Adjustment is too large for <b>'+statusmap.get(asId).name+'</b>'));
                         return null;
                      }
                   }
                   else {
                      temp.Quantity__c = Decimal.valueOf(selectedQuantity);
                   }
                asList.add(temp);
            }
            try{
                update asList;
                this.shouldRedirect = true;
                PageReference pageRef = Page.WorkOrderItemHierarchy;
                pageRef.getParameters().put('Id',this.workOrder.Id);
                pageRef.getParameters().put('mode','edit');
                pageRef.getParameters().put('saveURL',this.saveURL);
                pageRef.getParameters().put('retURL',this.returnURL);
                pageRef.setRedirect(true);
                this.redirectUrl = pageRef.getUrl();
            } catch (Exception ex ){
                system.debug('update Associated Items failed : '+ex.getMessage());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, ex.getMessage()));
				return null;
            }
        }
		return null;
    }


    public PageReference submitWorkOrder()
    {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'submitWorkOrder', LoggingLevel.DEBUG);
        Work_Order__c currentWorkOrder = [SELECT RecordTypeId, Approver__c, Install_Manager__c, Parent_Work_Order__c from Work_Order__c WHERE Id = :workorder.Id];
        
        if(currentWorkOrder.Approver__c == null || currentWorkOrder.Install_Manager__c == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
           '<b>An Error has occured</b>',
	       'There must be an Approver and Install Manager before items can be submitted for Billing'));
	       return null;
        	
        }
        if (ApexPages.currentPage().getParameters().containsKey('selectedAssocItemIDs')) {
            String jsonString = ApexPages.currentPage().getParameters().get('selectedAssocItemIDs');
            List<ID> selectedIds = (List<ID>) JSON.deserialize(jsonString,List<ID>.class);
            List<Associated_Item__c> selectedAssociatedItems = new List<Associated_Item__c>();
            for(ID selectedID : selectedIds){
                if(String.valueOf(selectedID).startsWith(this.assocItemPrefix)){
                    selectedAssociatedItems.add(New Associated_Item__c(ID=selectedID));
                }
            }
            if(selectedAssociatedItems.size()>0){
            	this.alertMessage = 'Selected items are processing. Do not resubmit.';
                Savepoint sp = Database.setSavepoint();
  
                for(Associated_Item__c ai : selectedAssociatedItems)
                {
                    ai.Flagged_for_Billing__c = true;
                }
                try{
                    populateHierarchy();
                    //Update workorder status as well
                    this.workorder.Billing_Approval_Needed__c = true;
                    update(workorder);
                    update(selectedAssociatedItems);
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
					req1.setComments('Submitting WorkOrder for approval.');
					req1.setObjectId(workorder.id);
			        Approval.ProcessResult result = Approval.process(req1);
			        system.debug('Submitting Approval Success' +result.isSuccess());


                    if(UserInfo.getUserId() == workOrder.Approver__c)
                	{
				        List<Id> newWorkItemIds = result.getNewWorkitemIds();
				        // Instantiate the new ProcessWorkitemRequest object and populate it
				        Approval.ProcessWorkitemRequest req2 = 
				            new Approval.ProcessWorkitemRequest();
				        req2.setComments('Submitter is Approver, Auto approving');
				        req2.setAction('Approve');
				        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
				        
				        // Use the ID from the newly created item to specify the item to be worked
				        req2.setWorkitemId(newWorkItemIds.get(0));
				        
				        // Submit the request for approval
				        Approval.ProcessResult result2 =  Approval.process(req2);
						system.debug('Autoapproving result:'+result2.isSuccess());
				        
                	}

                    this.shouldRedirect = true;
                    PageReference pageRef = Page.WorkOrderItemHierarchy;
                    pageRef.getParameters().put('Id',this.workOrder.Id);
                    pageRef.getParameters().put('mode','edit');
                    pageRef.getParameters().put('saveURL',this.saveURL);
                    pageRef.getParameters().put('retURL',this.returnURL);
                    pageRef.setRedirect(true);
                    this.redirectUrl = pageRef.getUrl();

                }
                catch(DMLException dmlEx) {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                               '<b>An Error has occurred.No Order Items selected from this Work Order have been submitted.</b>',
                                                               'Exception....Cause:' + dmlEx.getCause() + '::Message:' + dmlEx.getMessage()));
                    Utilities.writeLog('DMLException....Cause:' + dmlEx.getCause() + '::Message:' + dmlEx.getMessage()+'::Fields:'+dmlEx.getDmlFieldNames(0), WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);
                }
                catch(Exception ex) {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                               '<b>An Error has occurred.No Order Items selected from this Work Order have been submitted.</b>',
                                                               'Exception....Cause:' + ex.getCause() + '::Message:' + ex.getMessage()));
                    Utilities.writeLog('Exception....Cause:' + ex.getCause() + '::Message:' + ex.getMessage(), WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);
                }
            }
        }
        return null;
    }

    //shawks BUG-00753: Process selected records to create Product Activations for related assets
    public PageReference submitQtyAdjust()
    {
       Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'submitQtyAdjust', LoggingLevel.DEBUG);
       if(intAdjQty == 0){
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '<b>Not Submitted</b>', 
                      'Incorrect Project Type on Work Order'));
          return null;
       }
       if (ApexPages.currentPage().getParameters().containsKey('selectedAssocItemIDs')) {
          String jsonString = ApexPages.currentPage().getParameters().get('selectedAssocItemIDs');
          List<ID> selectedIds = (List<ID>) JSON.deserialize(jsonString,List<ID>.class);
          List<Associated_Item__c> selectedAssociatedItems = new List<Associated_Item__c>();
          for(ID selectedID : selectedIds){
             if(String.valueOf(selectedID).startsWith(this.assocItemPrefix)){
                selectedAssociatedItems.add(New Associated_Item__c(ID=selectedID));
             }
          }
          if(selectedAssociatedItems.size()>0){
             this.alertMessage = 'Selected items are processing. Do not resubmit.';
             Savepoint sp = Database.setSavepoint();
			 //Find current values for selected associated items to use for production activations
			 list<Associated_Item__c> lstcurAssocItems = new list<Associated_Item__c>
				                     ([ SELECT Id, Name, Work_Order__r.Project_Type__c, Order_Item__r.asset__c, Project_Type__c, Quantity__c,
				                        order_item__r.asset__r.quantity,              //Max quantity
				                        order_item__r.asset__r.Total_Active_Rooms__c  //Current quantity
				                        FROM Associated_Item__c WHERE Id IN :selectedIds AND Status__c <> 'Adjustment Completed' ]);
             if(lstcurAssocItems.size() > 0) { //Check if any records meet the above criterial
                list<Product_Activation__c> lstinsertpa = new list<Product_Activation__c>();
                for(Associated_Item__c ai : lstcurAssocItems){
                   ai.status__c = 'Adjustment Completed';
                   Product_activation__c newpa = New Product_activation__c();
                   newpa.Name = ai.Name;
                   newpa.Product_Inventory__c = ai.order_item__r.asset__c;
                   newpa.Associated_Item__c = ai.Id;
                   newpa.Type__c = ai.Work_Order__r.Project_Type__c;
                   //Verify new quantity does not exceed the maximum value allowed
                   if(ai.order_item__r.asset__r.Total_Active_Rooms__c+(intAdjQty*math.abs(ai.Quantity__c)) <= ai.order_item__r.asset__r.quantity){
                      newpa.Quantity__c = intAdjQty*(math.abs(ai.Quantity__c));
                   }
                   else{
                      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '<b>Quantity Adjustment was not processed</b>', 
                                        'Quantity Adjustment value is too large for <b>'+ai.Name+'</b>'));
                      return null;
                   }
				   lstinsertpa.add(newpa);
                }
                try{
                   //Update associated item status and insert product activation records
                   update(lstcurAssocItems);
                   insert(lstinsertpa);
                   eventEmail();  //Send email notifying that Quantity Adjustment completed

                   this.shouldRedirect = true;
                   PageReference pageRef = Page.WorkOrderItemHierarchy;
                   pageRef.getParameters().put('Id',this.workOrder.Id);
                   pageRef.getParameters().put('mode','edit');
                   pageRef.getParameters().put('saveURL',this.saveURL);
                   pageRef.getParameters().put('retURL',this.returnURL);
                   pageRef.setRedirect(true);
                   this.redirectUrl = pageRef.getUrl();
                }
                catch(DMLException dmlEx) {
                   Database.rollback(sp);
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                           '<b>An Error has occurred.No Order Items selected from this Work Order have been submitted.</b>',
                                                           'Exception....Cause:' + dmlEx.getCause() + '::Message:' + dmlEx.getMessage()));
                   Utilities.writeLog('DMLException....Cause:' + dmlEx.getCause() + '::Message:' + dmlEx.getMessage()+'::Fields:'+dmlEx.getDmlFieldNames(0), WorkOrderItemHierarchyExtension.class, 'submitQtyAdjust', LoggingLevel.DEBUG);
                }
                catch(Exception ex) {
                   Database.rollback(sp);
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                           '<b>An Error has occurred.No Order Items selected from this Work Order have been submitted.</b>',
                                                           'Exception....Cause:' + ex.getCause() + '::Message:' + ex.getMessage()));
                   Utilities.writeLog('Exception....Cause:' + ex.getCause() + '::Message:' + ex.getMessage(), WorkOrderItemHierarchyExtension.class, 'submitQtyAdjust', LoggingLevel.DEBUG);
                }
             }  //End of if(lstcurAssocItems.size() > 0)
             else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '<b>Quantity Adjustment was not processed</b>', 
                                     'None of the selected lines meet the criterial to be submitted.'));
                return null;
             }
          }  //End of if(selectedAssociatedItems.size()>0)
       }   
       Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'submitQtyAdjust', LoggingLevel.DEBUG);
       return null;
    }


    public PageReference deleteAssociatedItems() {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'deleteAssociatedItems', LoggingLevel.DEBUG);

        if (ApexPages.currentPage().getParameters().containsKey('selectedAssocItemIDs')) {
            String jsonString = ApexPages.currentPage().getParameters().get('selectedAssocItemIDs');
            List<ID> selectedIds = (List<ID>) JSON.deserialize(jsonString,List<ID>.class);
            List<Associated_Item__c> selectedAssociatedItems = new List<Associated_Item__c>();
            for(ID selectedID : selectedIds){
                if(String.valueOf(selectedID).startsWith(this.assocItemPrefix)){
                    selectedAssociatedItems.add(New Associated_Item__c(ID=selectedID));
                }
            }
            if(selectedAssociatedItems.size()>0){
                Savepoint sp = Database.setSavepoint();
                try{
                    delete(selectedAssociatedItems);
                    populateHierarchy();

                    this.shouldRedirect = true;
                    PageReference pageRef = Page.WorkOrderItemHierarchy;
                    pageRef.getParameters().put('Id',this.workOrder.Id);
                    pageRef.getParameters().put('mode','edit');
                    pageRef.getParameters().put('saveURL',this.saveURL);
                    pageRef.getParameters().put('retURL',this.returnURL);
                    pageRef.setRedirect(true);
                    this.redirectUrl = pageRef.getUrl();
                }
                catch(DMLException dmlEx) {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                               '<b>An Error has occurred.No Order Items selected from this Work Order have been deleted.</b>',
                                                               'Exception....Cause:' + dmlEx.getCause() + '::Message:' + dmlEx.getMessage()));
                    Utilities.writeLog('DMLException....Cause:' + dmlEx.getCause() + '::Message:' + dmlEx.getMessage()+'::Fields:'+dmlEx.getDmlFieldNames(0), WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);
                }
                catch(Exception ex) {
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                               '<b>An Error has occurred.No Order Items selected from this Work Order have been delete.</b>',
                                                               'Exception....Cause:' + ex.getCause() + '::Message:' + ex.getMessage()));
                    Utilities.writeLog('Exception....Cause:' + ex.getCause() + '::Message:' + ex.getMessage(), WorkOrderItemHierarchyExtension.class, 'cloneAssociatedItems', LoggingLevel.DEBUG);
                }
            }
        }

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'deleteAssociatedItems', LoggingLevel.DEBUG);
        return null;
    }

    public PageReference returnWorkOrder() {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'returnWorkOrder', LoggingLevel.DEBUG);

        PageReference pageRef = new ApexPages.StandardController(this.workOrder).view();
        pageRef.setRedirect(true);

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'returnWorkOrder', LoggingLevel.DEBUG);
        return pageRef;
    }


    private void populateHierarchy()
    {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'populateHierarchy', LoggingLevel.DEBUG);
		String workOrderId;
		if(workOrderParentId != null)
			workOrderId = workOrderParentId;
		else
			workOrderId = this.workOrder.Id;
		system.debug('work order of associated item id is '+workOrderId);
        // Get role to users mapping in a map with key as role id
        //shawks CPQ: Comment out Delivery Method
        //shawks BUG-00700 : Remove Partial; Add Price
        //shawks BUG-00176: Add Delivery Method
        this.assocItemMap = new Map<Id, Associated_Item__c>([SELECT
                                                                a.Id,
                                                                a.Name,
                                                                a.Order_Item__c,
                                                                a.Work_Order__c,
                                                                a.Quantity__c,
                                                                a.Price__c,
                                                                a.Contracted_Completion_Date__c,
                                                                a.Billing_Commencement_Date__c,
                                                                a.Status__c,
                                                                a.Mod_Channel__c,
                                                                a.Receiver_Channel__c,
                                                                a.Receiver_ID__c,
                                                                a.Card_ID__c,
                                                                a.Serial_Number__c,
                                                                a.Project_Number__c,
                                                                a.Month_Cha__c,
                                                                a.Quarter_Assigned_To__c,
                                                                a.Year_Charged_To__c,
                                                                a.Project_Type__c,
                                                                a.Order_Item__r.Product__r.Family,
                                                                a.Order_Item__r.Product__r.Circuit__c,
                                                                a.Order_Item__r.Product__r.Customization_Needed__c,
                                                                a.Order_Item__r.Product__r.Channel__c
                                                               //,a.Delivery_Method__c
                                                             FROM
                                                                Associated_Item__c a
                                                             WHERE
                                                                a.Work_Order__c = :workOrderId]);

        if(this.assocItemMap.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                                       '<b>No Order Items have been associated to this Work Order.</b>',
                                                       'To view contract line items for this contract, you must first add a contract line item to the contract.'));
        } else {
            List<Associated_Item__c> assocItems;

            for(Associated_Item__c assocItem : this.assocItemMap.values()) {

                if (!this.orderAssocItemMap.containsKey(assocItem.Order_Item__c)) {
                    assocItems = new List<Associated_Item__c>();
                } else {
                    assocItems = this.orderAssocItemMap.get(assocItem.Order_Item__c);
                }
                assocItems.add(assocItem);
                this.orderAssocItemMap.put(assocItem.Order_Item__c,assocItems);
            }
            //shawks CPQ: Comment out Delivery Method
            //shawks BUG-00176: Add Delivery Method
            this.orderMap = new Map<ID, Order_Item__c>([SELECT
                                                           o.ID,
                                                           o.Name,
                                                           o.Parent__c,
                                                           o.Product__c,
                                                           o.Product__r.ProductCode,
                                                           o.Product__r.Name,
                                                           o.Product__r.Family,
                                                           o.Product__r.Channel__c,
                                                           o.Product__r.Circuit__c,
                                                           o.Product__r.Customization_Needed__c,
                                                           o.Project_Type__c,
                                                           //o.Delivery_Method__c,
                                                           (SELECT
                                                                ID,
                                                                Parent__c
                                                            FROM
                                                                Order_Items__r)
                                                        FROM
                                                           Order_Item__c o
                                                        WHERE
                                                           o.ID IN :this.orderAssocItemMap.keySet()
                                                        ORDER BY
                                                           o.Parent__c]);

        }
        
        if(isRackBuild)
        	getTreeJSONRackBuild();
    	else
        	getTreeJSON();

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'populateHierarchy', LoggingLevel.DEBUG);
    }
	private void populateInDevelopment()
	{
		String workOrderId;
		if(workOrderParentId != null)
			workOrderId = workOrderParentId;
		else
			workOrderId = this.workOrder.Id;
		Map<Id,Associated_Item__c> inDevMap = new Map<Id,Associated_Item__c>([SELECT id from Associated_Item__c WHERE Work_Order__c = :workOrderId AND Status__c = 'In Development']);
		this.inDevelopmentIds = inDevMap.keySet();		
	}
    private void getTreeJSON() {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);
        Utilities.writeLog('this.orderMap.size()::'+this.orderMap.size(), WorkOrderItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);
        gen = JSON.createGenerator(true);
        gen.writeStartArray();
        convertNodeToJSONtblHdr();
        for(Order_Item__c oi : this.orderMap.values()) {
          //Utilities.writeLog('Looping through orderMap oi.ID:'+oi.ID+'::oi.Product__r.Name:'+oi.Product__r.Name, WorkOrderItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);

          if(null == oi.Parent__c)
          {
             convertNodeToJSON(oi);
          }
        }
        gen.writeEndArray();
        this.treeJSON = gen.getAsString();

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);
    }

    private void getTreeJSONRackBuild()
    {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'getTreeJSONRackBuild', LoggingLevel.DEBUG);
        Utilities.writeLog('this.orderMap.size()::'+this.orderMap.size(), WorkOrderItemHierarchyExtension.class, 'getTreeJSONRackBuild', LoggingLevel.DEBUG);
        gen = JSON.createGenerator(true);
        gen.writeStartArray();
        convertNodeToJSONtblHdr();
        for(Order_Item__c oi : this.orderMap.values()) {
          Utilities.writeLog('Looping through orderMap oi.ID:'+oi.ID+'::oi.Product__r.Name:'+oi.Product__r.Name, WorkOrderItemHierarchyExtension.class, 'getTreeJSON', LoggingLevel.DEBUG);

          if(null == oi.Parent__c)
          {
            if (oi.Product__r.Family == 'FTG')
            {
                convertNodeToJSONRackBuild(oi);
            }
            else
                convertNodeToJSON(oi);
          }
        }
        gen.writeEndArray();
        this.treeJSON = gen.getAsString();

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'getTreeJSONRackBuild', LoggingLevel.DEBUG);
    }

    private void convertNodeToJSONRackBuild(Order_Item__c oi)//Special function to call on top level 'FTG' product order items
    {

       // Utilities.writeLog('Starting....'+oi.Product__r.Name + '::oi.ID:'+oi.ID + '::oi.Product__r.Family:'+oi.Product__r.Family + ' channel '+oi.Product__r.Channel__c , WorkOrderItemHierarchyExtension.class, 'convertNodeToJSONRackBuild', LoggingLevel.DEBUG);
  
        Boolean parentLevel = false;

        String baseURL = null;
        if(Site.getCurrentSiteUrl() != null)
             baseURL = Site.getCurrentSiteUrl();
        //Only write if Product is Channel
        // Change code to test for Family, if NULL just display it.  OR
        //  If Family = FTG and Channel_c true display it OR
        //  if Family = Interactive  display it OR
        //  if Family = Broadband  display it
        if((oi.Product__r.Channel__c == true && oi.Order_Items__r.size() == 0) || oi.Parent__c == null)
        {
            gen.writeStartObject();
            if(null != oi.Product__r.Name)
                gen.writeStringField('title', oi.Product__r.Name);

            gen.writeBooleanField('orderItemParent', true);

            Utilities.writeLog('oi.projectType.Name:'+oi.Product__r.Name + '::oi.project_type:'+oi.Project_Type__c, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
            if(null != oi.Project_Type__c) {
               gen.writeStringField('projectType', oi.Project_Type__c);
            } else {
               gen.writeStringField('projectType', ' ');
            }
            gen.writeBooleanField('unselectable', false);
            gen.writeBooleanField('hideCheckbox', this.isPortalUser);
            gen.writeBooleanField('expanded', true);
            gen.writeBooleanField('folder', true);
            //Write key field if it is FTG product parent node
            if(oi.Product__r.Family == 'FTG')
                gen.writeStringField('key','FTG');

            if(oi.Parent__c != null){
                Order_Item__c parentOI = this.orderMap.get(oi.Parent__c);
                if(null == parentOI.Parent__c) {
                    parentLevel = true;
                }
            }
            Decimal modNumber;
            if(oi.Order_Items__r.size() > 0 || this.orderAssocItemMap.containsKey(oi.ID)) {

                gen.writeFieldName('children');
                gen.writeStartArray();

                for(Associated_Item__c assocItem : this.orderAssocItemMap.get(oi.ID)) {
                    modNumber = assocItem.Mod_Channel__c;
                   // Utilities.writeLog('assocItem.Name:'+assocItem.Name + '::assocItem.ID:'+assocItem.ID+':: Family '+assocItem.Order_Item__r.Product__r.Family, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
                    gen.writeStartObject();
                    gen.writeStringField('key', assocItem.Id);
                    if(baseUrl != null){
                        gen.writeStringField('href', baseURL + assocItem.Id);
                    } else {
                        gen.writeStringField('href', '/' + assocItem.Id);
                    }
                    gen.writeStringField('target', '_top');
                   // Utilities.writeLog('Setting Title:'+assocItem.Name, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
                    if(null != assocItem.Name)
                        gen.writeStringField('title', assocItem.Name);
                   String channelValue = String.ValueOf(assocItem.Mod_Channel__c);

                   if (null != channelValue) {
                   	 gen.writeStringField('modChannel', channelValue);
                   } else {
                   	 gen.writeStringField('modChannel', '');
                   }

                   String receiverValue = String.ValueOf(assocItem.Receiver_Channel__c);
                   if (null != receiverValue) {
                   	  gen.writeStringField('receiverChannel', receiverValue);
                   } else {
                   	  gen.writeStringField('receiverChannel', '');
                   }

                   if(null != assocItem.Receiver_ID__c) {
                       gen.writeStringField('receiverId', assocItem.Receiver_ID__c);
                   } else {
                       gen.writeStringField('receiverId','');
                   }

                   if(null != assocItem.Card_ID__c) {
                       gen.writeStringField('cardidNumber', assocItem.Card_ID__c);
                   } else {
                       gen.writeStringField('cardidNumber','');
                   }

                   if(null != assocItem.Serial_Number__c) {
                       gen.writeStringField('serialNumber', assocItem.Serial_Number__c);
                   } else {
                       gen.writeStringField('serialNumber','');
                   }

                   if(null == oi.Parent__c) {
                       gen.writeBooleanField('displayProjectNumber', true);
                   } else {
                       gen.writeBooleanField('displayProjectNumber', false);
                   }
                   if(null != assocItem.Project_Number__c) {
                       gen.writeStringField('projectNumber', assocItem.Project_Number__c);
                   } else {
                       gen.writeStringField('projectNumber','');
                   }

                   if(null != assocItem.Status__c) {
                      gen.writeStringField('status', assocItem.Status__c);
                   }
					
                   String quantityValue = String.ValueOf(assocItem.Quantity__c);
                   if(quantityValue != null)
                   		gen.writeStringField('quantity', quantityValue);
 
                   //shawks CPQ: Comment out Delivery Method
                   /*//shawks BUG-00176 - Add Delivery Method
                   if(null != assocItem.Delivery_Method__c) {
                       gen.writeStringField('deliveryMethod', assocItem.Delivery_Method__c);
                   } else {
                       gen.writeStringField('deliveryMethod','');
                   }
                   */
                    gen.writeBooleanField('RackbuildorderItem',true);

                    gen.writeBooleanField('orderItemParent', false);
                    gen.writeBooleanField('parentLevel', parentLevel);
                    gen.writeBooleanField('unselectable', true);
                    gen.writeBooleanField('expanded', true);
                    gen.writeBooleanField('folder', false);
                    if (assocItem.Status__c == 'In Development') {        
                        gen.writeBooleanField('hideCheckbox', true);
                    } else {
                        gen.writeBooleanField('hideCheckbox', this.isPortalUser);    
                    }        
                    gen.writeEndObject();
                }

                for(Order_Item__c oiLine : oi.Order_Items__r) {
                    if(this.orderMap.containsKey(oiLine.Id)) {
                        convertNodeToJSONRackBuild(this.orderMap.get(oiLine.Id));
                    }
                }

                gen.writeEndArray();
            }
            if(modNumber != null)
                gen.writeNumberField('mod',modNumber);
            if(null != oi.Product__r.Name)
            {
                gen.writeStringField('title',oi.Product__r.Name);
            }

            gen.writeEndObject();
        }
        else
        {
            for(Order_Item__c oiLine : oi.Order_Items__r) {
                if(this.orderMap.containsKey(oiLine.Id)) {
                    convertNodeToJSONRackBuild(this.orderMap.get(oiLine.Id));
                }
            }
        }
        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'convertNodeToJSONRackBuild', LoggingLevel.DEBUG);
    }


    private void convertNodeToJSON(Order_Item__c oi)
    {


        Utilities.writeLog('Starting.... parent '+oi.Parent__c, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
       // Utilities.writeLog('oi.Product__r.Name:'+oi.Product__r.Name + '::oi.ID:'+oi.ID, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
        // Utilities.writeLog('oi.Product__r.Family:'+oi.Product__r.Family + '::oi.ID:'+oi.ID, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);

        Boolean parentLevel = false;

        String baseURL = null;
        if(Site.getCurrentSiteUrl() != null)
             baseURL = Site.getCurrentSiteUrl();

        gen.writeStartObject();

        if(null != oi.Product__r.Name)
            gen.writeStringField('title', oi.Product__r.Name);

        gen.writeBooleanField('orderItemParent', true);

        // Utilities.writeLog('oi.projectType.Name:'+oi.Product__r.Name + '::oi.project_type:'+oi.Project_Type__c, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
        if(null != oi.Project_Type__c) {
           gen.writeStringField('projectType', oi.Project_Type__c);
        } else {
           gen.writeStringField('projectType', ' ');
        }
        gen.writeBooleanField('unselectable', false);
        gen.writeBooleanField('hideCheckbox', this.isPortalUser);
        gen.writeBooleanField('expanded', true);
        gen.writeBooleanField('folder', true);


        if(oi.Parent__c != null){
            Order_Item__c parentOI = this.orderMap.get(oi.Parent__c);
            if(null == parentOI.Parent__c) {
                parentLevel = true;
            }
        }

        if(oi.Order_Items__r.size() > 0 || this.orderAssocItemMap.containsKey(oi.ID)) {
            gen.writeFieldName('children');
            gen.writeStartArray();

            for(Associated_Item__c assocItem : this.orderAssocItemMap.get(oi.ID)) {
              //Utilities.writeLog('assocItem.Name:'+assocItem.Name + '::assocItem.ID:'+assocItem.ID+ '::assocItem.circuit '+assocItem.Order_Item__r.Product__r.Circuit__c, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);

				
                gen.writeStartObject();
                gen.writeStringField('key', assocItem.Id);
                if(baseUrl != null){
                    gen.writeStringField('href', baseURL + assocItem.Id);
                } else {
                    gen.writeStringField('href', '/' + assocItem.Id);
                }
               String channelValue = String.ValueOf(assocItem.Mod_Channel__c);

			   if(isCircuitWorkOrder && assocItem.Order_Item__r.Product__r.Circuit__c == true)
			   {
			   	 gen.writeBooleanField('circuit',true);
			   }
			   if(isCustomWorkOrder && assocItem.Order_Item__r.Product__r.Customization_Needed__c == true)
			   {
			     gen.writeBooleanField('customization',true);
			   }
               if (null != channelValue) {
               	 gen.writeStringField('modChannel', channelValue);
               } else {
               	 gen.writeStringField('modChannel', '');
               }

               String receiverValue = String.ValueOf(assocItem.Receiver_Channel__c);
               if (null != receiverValue) {
	           	  gen.writeStringField('receiverChannel', receiverValue);
               } else {
               	  gen.writeStringField('receiverChannel', '');
               }

	           if(null != assocItem.Receiver_ID__c) {
                   gen.writeStringField('receiverId', assocItem.Receiver_ID__c);
               } else {
                   gen.writeStringField('receiverId','');
               }

               if(null != assocItem.Card_ID__c) {
                   gen.writeStringField('cardidNumber', assocItem.Card_ID__c);
               } else {
                   gen.writeStringField('cardidNumber','');
               }

               if(null != assocItem.Serial_Number__c) {
                   gen.writeStringField('serialNumber', assocItem.Serial_Number__c);
               } else {
                   gen.writeStringField('serialNumber','');
               }

               //shawks CPQ: Comment out Delivery Method
               /*//shawks - BUG-00176:  Add Delivery Method
               if(null != assocItem.Delivery_Method__c) {
                   gen.writeStringField('deliveryMethod', assocItem.Delivery_Method__c);
               } else {
                   gen.writeStringField('deliveryMethod','');
               }
               */
               if(null == oi.Parent__c) {
                   gen.writeBooleanField('displayProjectNumber', true);
               } else {
                   gen.writeBooleanField('displayProjectNumber', false);
               }
               if(null != assocItem.Project_Number__c) {
                   gen.writeStringField('projectNumber', assocItem.Project_Number__c);
               } else {
                   gen.writeStringField('projectNumber','');
               }
                gen.writeStringField('target', '_top');
                //Utilities.writeLog('Setting Title:'+assocItem.Name, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
                if(null != assocItem.Name)
                    gen.writeStringField('title', assocItem.Name);
               // Utilities.writeLog('Setting contractedCompletionDate:'+assocItem.Contracted_Completion_Date__c, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
                if(null != assocItem.Contracted_Completion_Date__c){
                    gen.writeStringField('contractedCompletionDate', assocItem.Contracted_Completion_Date__c.format());
                }else{
                    gen.writeStringField('contractedCompletionDate', '');
                }
                if (null != assocItem.Project_Type__c) {
                   gen.writeStringField('projectType', assocItem.Project_Type__c);
                }else{
                    gen.writeStringField('projectType', '');
                }
                //Utilities.writeLog('Setting billingDate:'+assocItem.Billing_Commencement_Date__c, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
                if(null != assocItem.Billing_Commencement_Date__c) {
                    gen.writeStringField('billingDate', assocItem.Billing_Commencement_Date__c.format());
                }else{
                    gen.writeStringField('billingDate', '');
                }
                //Utilities.writeLog('After Setting billingDate:', WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);

                if(String.valueOf(assocItem.Quantity__c)==null || String.valueOf(assocItem.Quantity__c)=='')
                    Utilities.writeLog('Before Setting quantity:', WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);

                Utilities.writeLog('Setting quantity:'+String.valueOf(assocItem.Quantity__c), WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
                if(null != assocItem.Quantity__c) {
                    String quantityValue = String.ValueOf(assocItem.Quantity__c);
                    gen.writeStringField('quantity', quantityValue);
                } else {
                    gen.writeStringField('quantity', '0');
                }
                /*shawks BUG-00700 - Remove Partial; Add Price
                //Utilities.writeLog('Setting partialOrder:'+assocItem.Partial_Order__c, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
                if(null != assocItem.Partial_Order__c) {
                    gen.writeBooleanField('partialOrder', assocItem.Partial_Order__c);
                } else {
                    gen.writeBooleanField('partialOrder', false);
                }
                /*/
                if (0 != assocItem.Price__c) {
                   //gen.writeStringField('price', assocItem.Price__c.format());
                   gen.writeStringField('price', String.ValueOf(assocItem.Price__c));
                } else {
                   gen.writeStringField('price', '0.00');
                }
                //Utilities.writeLog('Setting status:'+assocItem.Status__c, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
                if(null != assocItem.Status__c) {
                    gen.writeStringField('status', assocItem.Status__c);
                }
                //Utilities.writeLog('Setting displayProjectNumber::oi.Parent__c:'+oi.Parent__c, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
                if(null == oi.Parent__c) {
                    gen.writeBooleanField('displayProjectNumber', true);
                } else {
                    gen.writeBooleanField('displayProjectNumber', false);
                }
                //Utilities.writeLog('Setting projectNumber:'+assocItem.Project_Number__c, WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
                if(null != assocItem.Project_Number__c) {
                    gen.writeStringField('projectNumber', assocItem.Project_Number__c);
                } else {
                    gen.writeStringField('projectNumber','');
                }
                if(null != assocItem.Month_Cha__c) {
                    gen.writeStringField('monthCharged', assocItem.Month_Cha__c);
                } else {
                    gen.writeStringField('monthCharged','');
                }
                if(null != assocItem.Quarter_Assigned_To__c) {
                    gen.writeStringField('quarterCharged', assocItem.Quarter_Assigned_To__c);
                } else {
                    gen.writeStringField('quarterCharged','');
                }
                if(null != assocItem.Year_Charged_To__c) {
                    gen.writeStringField('yearCharged', assocItem.Year_Charged_To__c);
                } else {
                    gen.writeStringField('yearCharged','');
                }
                gen.writeBooleanField('RackbuildorderItem',this.isRackBuild);

                gen.writeBooleanField('orderItemParent', false);
                gen.writeBooleanField('parentLevel', parentLevel);
                gen.writeBooleanField('expanded', true);
                gen.writeBooleanField('folder', false);
                if (assocItem.Status__c == 'In Development') {        
                    gen.writeBooleanField('hideCheckbox', true);
                    gen.writeBooleanField('unselectable', true);
                } else {
                    gen.writeBooleanField('hideCheckbox', this.isPortalUser); 
                    gen.writeBooleanField('unselectable',  this.isPortalUser);                  
                }                        
                gen.writeEndObject();
              
            }

            for(Order_Item__c oiLine : oi.Order_Items__r) {
                if(this.orderMap.containsKey(oiLine.Id)) {
                    convertNodeToJSON(this.orderMap.get(oiLine.Id));
                }
            }

            gen.writeEndArray();
        }
        gen.writeEndObject();

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'convertNodeToJSON', LoggingLevel.DEBUG);
    }

private void convertNodeToJSONtblHdr()
    {
     Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'convertNodeToJSONtblHdr', LoggingLevel.DEBUG);

        gen.writeStartObject();
        gen.writeStringField('title', '');
        gen.writeBooleanField('icon', false);
        gen.writeBooleanField('orderItemColumnHeader', true);

        if (this.isRackBuild)
        {
           gen.writeStringField('columnHeader1', 'Mod <br> Channel');
           gen.writeStringField('columnHeader2', 'Receiver <br> Channel');
           gen.writeStringField('columnHeader3', 'Receiver <br> ID');
           gen.writeStringField('columnHeader4', 'Card ID');
           gen.writeStringField('columnHeader5', 'Serial <br> Number');
           gen.writeStringField('columnHeader6', 'Project <br> Number');
           gen.writeStringField('columnHeader7', 'Status');
           gen.writeStringField('columnHeader8', 'Quantity');
           //shawks CPQ: Comment out Delivery Method
           //shawks BUG-00176 - Add Delivery Method
           //gen.writeStringField('columnHeader9', 'Delivery<br>Method');
        } else {
           gen.writeStringField('columnHeader1', 'Status');
           gen.writeStringField('columnHeader2', 'Billing <br> Date');
           gen.writeStringField('columnHeader3', 'Project <br> Type');
           gen.writeStringField('columnHeader4', 'Quantity');
           gen.writeStringField('columnHeader5', 'Month <br> Charged');
           gen.writeStringField('columnHeader6', 'Quarter <br> Assigned');
           gen.writeStringField('columnHeader7', 'Year <br> Charged');
           gen.writeStringField('columnHeader8', 'Project <br> Number');
           //shawks BUG-00700 - Remove Partial; Add Price
           //gen.writeStringField('columnHeader9', 'Partial');
           gen.writeStringField('columnHeader9', 'Price');
        }
        gen.writeBooleanField('hideCheckbox', true);
        gen.writeBooleanField('unselectable', true);
        gen.writeEndObject();
        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'convertNodeToJSONtblHdr', LoggingLevel.DEBUG);

    }

    private void setStatusPicklistValues() {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'setStatusPicklistValues', LoggingLevel.DEBUG);

        Schema.DescribeFieldResult fieldResult = Associated_Item__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<SelectOption> options = new List<SelectOption>();
        gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for( Schema.PicklistEntry f : ple) {
            gen.writeStartObject();
            gen.writeStringField('label', f.getLabel());
            gen.writeStringField('value', f.getValue());
            gen.writeEndObject();
        }
        gen.writeEndArray();
        this.statusValuesJSON= gen.getAsString();

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'setStatusPicklistValues', LoggingLevel.DEBUG);
    }

    private void setMonthChargedPicklistValues() {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'setMonthChargedPicklistValues', LoggingLevel.DEBUG);

        Schema.DescribeFieldResult fieldResult = Associated_Item__c.Month_Cha__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<SelectOption> options = new List<SelectOption>();
        gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for( Schema.PicklistEntry f : ple) {
            gen.writeStartObject();
            gen.writeStringField('label', f.getLabel());
            gen.writeStringField('value', f.getValue());
            gen.writeEndObject();
        }
        gen.writeEndArray();
        this.monthChargedValuesJSON= gen.getAsString();

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'setMonthChargedPicklistValues', LoggingLevel.DEBUG);
    }

    private void setQuarterChargedPicklistValues() {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'setQuarterChargedPicklistValues', LoggingLevel.DEBUG);

        Schema.DescribeFieldResult fieldResult = Associated_Item__c.Quarter_Assigned_To__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<SelectOption> options = new List<SelectOption>();
        gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for( Schema.PicklistEntry f : ple) {
            gen.writeStartObject();
            gen.writeStringField('label', f.getLabel());
            gen.writeStringField('value', f.getValue());
            gen.writeEndObject();
        }
        gen.writeEndArray();
        this.quarterChargedValuesJSON= gen.getAsString();

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'setQuarterChargedPicklistValues', LoggingLevel.DEBUG);
    }

    private void setYearChargedPicklistValues() {
        Utilities.writeLog('Starting....', WorkOrderItemHierarchyExtension.class, 'setYearChargedPicklistValues', LoggingLevel.DEBUG);

        Schema.DescribeFieldResult fieldResult = Associated_Item__c.Year_Charged_To__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<SelectOption> options = new List<SelectOption>();
        gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for( Schema.PicklistEntry f : ple) {
            gen.writeStartObject();
            gen.writeStringField('label', f.getLabel());
            gen.writeStringField('value', f.getValue());
            gen.writeEndObject();
        }
        gen.writeEndArray();
        this.yearChargedValuesJSON= gen.getAsString();

        Utilities.writeLog('Ending....', WorkOrderItemHierarchyExtension.class, 'setYearChargedPicklistValues', LoggingLevel.DEBUG);
    }
    
     /*Method to return all Contract Line Items for given contract Line Item ID */
    private List<Associated_Item__c> retrieveAssociatedItems(List<ID> associatedItemIDs) {

            List<Associated_Item__c> associatedItems=new List<Associated_Item__c>();
            string dbQry='';
            for (string associatedItemField:AssociatedItemFields){
                if (dbqry==''){
                    dbqry =associatedItemField+',';
                }
                else {
                dbqry +=associatedItemField+',';
                }

            }
            Utilities.writeLog('AssociatedItemFields Field List::'+AssociatedItemFields, WorkOrderItemHierarchyExtension.class, 'retrieveAssociatedItems', LoggingLevel.DEBUG);

            dbQry ='SELECT '+ dbqry + 'Order_Item__c,Work_Order__c From Associated_Item__c WHERE ID IN (\'' + String.join(associatedItemIDs, '\',\'') + '\')';
            Utilities.writeLog('AssociatedItemFields dbQry::'+dbQry, WorkOrderItemHierarchyExtension.class, 'retrieveAssociatedItems', LoggingLevel.DEBUG);

            associatedItems= Database.query(dbQry);
            return associatedItems;
    }
    
     /*Method to return all Contract Line Items for given contract Line Item ID */
    private Work_Order__c retrieveWorkOrder(Id workOrderID) {

            string dbQry=null;
            for (string workOrderField:WorkOrderFields){
                if (dbqry==null){
                    dbqry =workOrderField;
                }
                else {
                	dbqry +=','+workOrderField;
                }

            }
            Utilities.writeLog('WorkOrderFields Field List::'+WorkOrderFields, WorkOrderItemHierarchyExtension.class, 'retrieveParentWorkOrder', LoggingLevel.DEBUG);

            dbQry ='SELECT '+ dbqry + ' From Work_Order__c WHERE ID IN (\'' + workOrderID + '\')';
            Utilities.writeLog('WorkOrderFields dbQry::'+dbQry, WorkOrderItemHierarchyExtension.class, 'retrieveParentWorkOrder', LoggingLevel.DEBUG);

            List<Work_Order__c> workOrders = Database.query(dbQry);
            return workOrders[0];
    }
     //shawks BUG-00753: Notify by email that event occurred
    public void eventEmail()
    {
       System.Debug('***********************START eventEmail*****************************');
       String emailSubject;
       String emailBody = '';
       String email;
       List<String> emailAddress = new list<String>();

       if(test.isRunningTest()) {
          email = 'shawks@sonifi.com';
	      emailSubject = this.workOrder.site__r.name+':  '+this.workOrder.project_type__c+' - TEST';  //Project Type of Work Order
       }
       else {
	      if(this.workOrder.site__r.type == 'Healthcare Site') {
             emailSubject = this.workOrder.site__r.name+':  '+this.workOrder.project_type__c;  //Project Type of Work Order
             EmailAddress_TON__c cs = EmailAddress_TON__c.getInstance('HealthcareEmailNotification');
             email = cs.EmailAddress__c;
          }
          else {
             emailSubject = this.workOrder.project_type__c+':  '+this.workOrder.site__r.name;  //Project Type of Work Order
   	         EmailAddress_TON__c cs = EmailAddress_TON__c.getInstance('TurnOnNotice');
	         email = cs.EmailAddress__c;
          }
       }
       emailAddress.add(email);
 
       emailBody += 'Site ID: '+this.workOrder.site__r.name+'\n';
       emailBody += 'Work Order #: '+this.workOrder.work_order_number__c+'\n';
       emailBody += 'Event: '+this.workOrder.project_type__c+'\n';
       emailBody += 'Event Date: '+Date.today().format()+'\n';
       emailBody += 'Created by: '+this.workOrder.createdby.name+'\n';

       //Send email with EmailNotification call
       try {
          EmailUtilities.EmailNotification(emailAddress, emailSubject, emailBody);
       }
       catch(Exception ex) {
          System.Debug('Error in eventEmail: ' +ex.getMessage());
       }
       System.Debug('*************************END eventEmail***************************');
    }
}