// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Class for implementing functionalities in support of the Notes & Attachments
//				 page.
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public class OpportunityNotesAndAttachmentsExtension
	implements CloneableInterface {
    
    public final Opportunity 					oppty								;
    public final Boolean 						showAllRecords 						{ get; private set; }
    
    public OpportunityNotesAndAttachmentsExtension(ApexPages.StandardController controller) {
		try {
			Id opptyId = ((Opportunity)controller.getRecord()).Id;
			oppty = [
				SELECT Id, Name, OwnerId, AccountId,
					   Account.Management_Group__c
				FROM Opportunity WHERE Id = :opptyId
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
    		OpportunityNotesAndAttachmentsExtension.class, 'getInterfaceObject', LoggingLevel.DEBUG);
		System.debug(this);
		return this;
	}
	
    /* Returns the parent SObject */
	public SObject getParentObject() {
    	Utilities.writeLog('Returning parent object', 
    		OpportunityNotesAndAttachmentsExtension.class, 'getParentObject', LoggingLevel.DEBUG);
    	System.debug(this.oppty);
		return this.oppty;
	}

	/* Primary Point-of-Contact Id (Not necessarily Owner or Contact objects) */
	public Id getWhoId() {
		return this.oppty.AccountId;
	}
	
    /* Returns a list of objects that can be parents of the cloned activities. */
    public List<SObject> getCloneToItems() {
    	
    	Utilities.writeLog('Reading accounts for current opportunity', 
    		OpportunityNotesAndAttachmentsExtension.class, 'getParentObject', LoggingLevel.DEBUG);
    	
		Id accountId = oppty.Account.Management_Group__c == null ? oppty.AccountId : oppty.Account.Management_Group__c;
		
    	List<Opportunity> cloneToItems = [
    		SELECT Id, Name, OwnerId
    		FROM Opportunity
    		WHERE (AccountId = :accountId OR Account.Management_Group__c = :accountId)
    		  AND Id != :this.oppty.Id
    		  AND OwnerId = :UserInfo.getUserId()
    	];
    	
    	Utilities.writeLog('Returning ' + cloneToItems.size() + ' opportunities.', 
    		OpportunityNotesAndAttachmentsExtension.class, 'getParentObject', LoggingLevel.DEBUG);
    		
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