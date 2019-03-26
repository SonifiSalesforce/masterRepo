// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Class for implementing functionalities to support custom list components
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public virtual class CustomListController {
    
    transient public Boolean                    hasPageError                            { get; protected set; }
    transient public ApexPages.Message          pageError                               { get; protected set; } 

    public Boolean                              showAllRecords                          { get; set; }
    
    protected List<SObject>                     recordList                              ;
    protected List<SObject>                     cloneToItemsList                        ;
    
    public String getRedirectUrl() {
    	
    	if (showAllRecords) {
    		return ApexPages.currentPage().getUrl();
    	}
    	
    	if(parentObject == null){
    		return null;
    	}else{
    		return '/' + parentObject.Id;
    	}
    }
    
    /* Parent interface object */
    public CloneableInterface cloneableInterfaceObject {
        get;
        set {
            if (value == null) {
                hasPageError = true;
                pageError = new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    'Unable to read list data from parent object.',
                    'No parent provided.');
                return;
            }
            cloneableInterfaceObject = value;
        } 
    }
    
    /* List's parent SObject */
    public SObject parentObject {
        get {
            if (parentObject == null) {
                if (cloneableInterfaceObject == null) { return null; }
                parentObject = cloneableInterfaceObject.getParentObject();
            }
            return parentObject;
        }
        protected set;
    }
    
    /* List's parent object's name */
    public String parentObjectName {
        get {
            if (parentObjectName == null) {
                if (parentObject == null) { return null; }
                parentObjectName = parentObject.getSObjectType().getDescribe().getName();
            }
            return parentObjectName;
        }
        protected set;
    }
    
    /* List's parent object's owner Id */
    public Id parentObjectOwner {
        get {
            if (parentObjectOwner == null) {
                if (parentObject == null) { return null; }
                parentObjectOwner = (Id)parentObject.get('OwnerId');
            }
            return parentObjectOwner;
        }
        protected set;
    }
    
    public String parentObjectRecordName {
    	get {
    		if (parentObjectRecordName == null) {
    			if (parentObject == null) { return null; }
    			parentObjectRecordName = String.valueOf(parentObject.get('Name'));
    		}
    		return parentObjectRecordName;
    	}
    	private set;
    }
    
    /* List's parent object's "who" Id */
    public Id parentObjectWho {
        get {
            if (parentObjectWho == null) {
                if (parentObject == null) { return null; }
                parentObjectWho = cloneableInterfaceObject.getWhoId();
            }
            return parentObjectWho;
        }
        protected set;
    }
    
    /* Cloneable Item to Object Field Map */
    protected Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> itemObjectFieldMap {
        get {
            if (itemObjectFieldMap == null) {
                itemObjectFieldMap = cloneableInterfaceObject.getItemObjectFieldMap();
            }
            return itemObjectFieldMap;
        }
        protected set;
    }
    
    /* Serializes clone-to items */
    public String getCloneToItemsJson() {
        if (cloneToItemsList == null) {
            Utilities.writeLog('No items to return.', 
                CustomListController.class, 'getCloneToItemsJson', LoggingLevel.DEBUG);
            return '';
        } 

        Utilities.writeLog('Returning ' + cloneToItemsList.size() + ' items.', 
            CustomListController.class, 'getCloneToItemsJson', LoggingLevel.DEBUG);
        return JSON.serialize(cloneToItemsList);
    }
    
    /* Gets a list of objects that can be parents of the cloned objects. 
     * NOTE This is implemented in this fashion to ensure this list is only
     * pulled when specifically requested by the user */
    public virtual void getCloneToItems() {
        
        Utilities.writeLog('Requesting clone-to items from parent...', 
            CustomListController.class, 'getCloneToItems', LoggingLevel.DEBUG);
        
        cloneToItemsList = cloneableInterfaceObject.getCloneToItems();
        if (cloneToItemsList == null) {
            Utilities.writeLog('No items receivedfrom parent.', 
                CustomListController.class, 'getCloneToItems', LoggingLevel.DEBUG);
        } else {
            Utilities.writeLog('Received ' + cloneToItemsList.size() + ' items from parent.', 
                CustomListController.class, 'getCloneToItems', LoggingLevel.DEBUG);
        }
    }
    
    /* Clone Items */
    public virtual PageReference cloneItems() {
        
        String pageParam = ApexPages.currentPage().getParameters().get('cloneableItemIdList');
        if (pageParam == '') { return null; }

        List<Id> cloneableItemIdList = pageParam.split(',');
        if (cloneableItemIdList == null || cloneableItemIdList.isEmpty()) { return null; }

        Utilities.writeLog(
            'Activity Id List: ' + pageParam, 
            CustomListController.class, 'cloneItems', LoggingLevel.DEBUG);
        
        pageParam = ApexPages.currentPage().getParameters().get('cloneToIdList');
        if (pageParam == '') { return null; }

        List<Id> cloneToIdList = pageParam.split(',');
        if (cloneToIdList == null || cloneableItemIdList.isEmpty()) { return null; }

        Utilities.writeLog(
            'Clone-To Id List: ' + cloneToIdList, 
            CustomListController.class, 'cloneItems', LoggingLevel.DEBUG);
        
        // Iterate over clone-to ids and create sobjects
        List<SObject> cloneToObjectList = new List<SObject>();
        for (Id cloneToId : cloneToIdList) {
            Schema.SObjectType idType = cloneToId.getSObjectType();
            SObject cloneToObject = idType.newSObject(cloneToId);
            cloneToObjectList.add(cloneToObject);
        }
        
        // Clone objects
        Utilities.cloneSObjects(cloneableItemIdList, cloneToObjectList, itemObjectFieldMap, true);
        
        return null;
    }

     /* Delete items */
    public virtual PageReference deleteItems() {
        
        String pageParam = ApexPages.currentPage().getParameters().get('deletedItemIdList');
        if (pageParam == '') { return null; }
        
        List<Id> deletedItemIdList = pageParam.split(',');
        if (deletedItemIdList == null || deletedItemIdList.isEmpty()) { return null; }
        
        Utilities.writeLog(
            'Items-To-Delete List: ' + pageParam, 
            CustomListController.class, 'deleteItems', LoggingLevel.DEBUG);
        
        Schema.SObjectType idType;
        
        // Iterate over objects and determine type for each
        List<SObject> itemsToDeleteList = new List<SObject>();
        for (Id thisId : deletedItemIdList) {
            idType = thisId.getSObjectType();
            itemsToDeleteList.add(idType.newSObject(thisId));
        }
        
        // Check for items to delete
        if (!itemsToDeleteList.isEmpty()) {
            delete itemsToDeleteList;
        }
        
        return null;
    }
}