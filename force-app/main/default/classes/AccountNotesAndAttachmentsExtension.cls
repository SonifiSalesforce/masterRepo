// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Class for implementing functionalities to support the custom Account
//               Notes & Attachments list page.
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public class AccountNotesAndAttachmentsExtension
    implements CloneableInterface {
    
    public final Account                        acct                                ;
    public final Boolean                        showAllRecords                      { get; private set; }
    
    public AccountNotesAndAttachmentsExtension(ApexPages.StandardController controller) {
        try {
            Id accountId = ((Account)controller.getRecord()).Id;
            acct = [
                SELECT Id, Name, ParentId, OwnerId, 
                       Account.Management_Group__c
                FROM Account WHERE Id = :accountId
            ];
            
            // Set showAllRecords property
            String pageParam = ApexPages.currentPage().getParameters().get('showAll');
            if (pageParam != null && pageParam.toLowerCase() == 'true') {
                showAllRecords = true;
            } else {
                showAllRecords = false;
            }
        }
        catch (Exception e) {}
    }
    
    /* *************************************************************************************
     * CloneableInterface Methods
     */
    
    /* Returns the interface object itself  */
    public CloneableInterface getCloneableInterface() {
        Utilities.writeLog('Returning cloneable interface object', 
            AccountNotesAndAttachmentsExtension.class, 'getInterfaceObject', LoggingLevel.DEBUG);
        System.debug(this);
        return this;
    }
    
    /* Returns the parent SObject */
    public SObject getParentObject() {
        Utilities.writeLog('Returning parent object', 
            AccountNotesAndAttachmentsExtension.class, 'getParentObject', LoggingLevel.DEBUG);
        System.debug(this.acct);
        return this.acct;
    }

    /* Primary Point-of-Contact Id (Not necessarily Owner or Contact objects) */
    public Id getWhoId() {
        return this.acct.OwnerId;
    }
    
    /* Returns a list of objects that can be parents of the cloned activities. */
    public List<SObject> getCloneToItems() {
    	
		Id accountId = acct.Management_Group__c == null ? acct.Id : acct.Management_Group__c;
		
    	List<Opportunity> cloneToItems = [
    		SELECT Id, Name, OwnerId
    		FROM Opportunity
    		WHERE (AccountId = :accountId OR Account.Management_Group__c = :accountId)
    		  AND OwnerId = :UserInfo.getUserId()
    	];
    	
    	Utilities.writeLog('Returning ' + cloneToItems.size() + ' opportunities.', 
    		AccountNotesAndAttachmentsExtension.class, 'getCloneToItems', LoggingLevel.DEBUG);
    		
    	return cloneToItems;
    }
    
    /* Returns a field map for cloning records */
    public Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> getItemObjectFieldMap() {
    	
		Schema.SObjectType opptyObjectType = Opportunity.getSObjectType();
		
		Map<Schema.SObjectField, Schema.SObjectField> fieldMap = 
				new Map<Schema.SObjectField, Schema.SObjectField>();
		
		Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>> objectFieldMap = 
				new Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>();
		
		Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> itemObjectFieldMap =
			new Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>>();
		
		// Build item-object map for Note
		fieldMap.put(Note.ParentId, Opportunity.Id);
		objectFieldMap.put(opptyObjectType, fieldMap);
		itemObjectFieldMap.put(Note.getSObjectType(), objectFieldMap);
		
		// Clear maps for next object
		fieldMap = new Map<Schema.SObjectField, Schema.SObjectField>();
		objectFieldMap = new Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>();
		
		// Build item-object map for Attachment
		fieldMap.put(Attachment.ParentId, Opportunity.Id);
		objectFieldMap.put(opptyObjectType, fieldMap);
		itemObjectFieldMap.put(Attachment.getSObjectType(), objectFieldMap);
			
    	return itemObjectFieldMap;
    }
}