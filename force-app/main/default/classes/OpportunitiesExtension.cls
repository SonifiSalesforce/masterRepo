// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Class for implementing functionalities to support the custom Opportunities
//               list page.
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class OpportunitiesExtension
    implements CloneableInterface {
    
    public final Opportunity					oppty								;
    public final Boolean                        showAllRecords                      { get; private set; }
    
    public OpportunitiesExtension(ApexPages.StandardController controller) {
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
            OpportunitiesExtension.class, 'getInterfaceObject', LoggingLevel.DEBUG);
        System.debug(this);
        return this;
    }
    
    /* Returns the parent SObject */
    public SObject getParentObject() {
        Utilities.writeLog('Returning parent object', 
            OpportunitiesExtension.class, 'getParentObject', LoggingLevel.DEBUG);
        System.debug(this.oppty);
        return this.oppty;
    }

    /* Primary Point-of-Contact Id (Not necessarily Owner or Contact objects) */
    public Id getWhoId() {
        return this.oppty.OwnerId;
    }
    
    /* Returns a list of objects that can be parents of the cloned activities. */
    public List<SObject> getCloneToItems() {
        return null;
    }
    
    /* Returns a field map for cloning records */
    public Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> getItemObjectFieldMap() {
        return null;
    }
}