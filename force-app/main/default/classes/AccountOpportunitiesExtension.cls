// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Class for implementing functionalities to support the custom Account
//               Opportunities list page.
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class AccountOpportunitiesExtension
    implements CloneableInterface {
    
    public final Account                        acct                                ;
    public final Boolean                        showAllRecords                      { get; private set; }
    
    public AccountOpportunitiesExtension(ApexPages.StandardController controller) {
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
            AccountOpportunitiesExtension.class, 'getInterfaceObject', LoggingLevel.DEBUG);
        System.debug(this);
        return this;
    }
    
    /* Returns the parent SObject */
    public SObject getParentObject() {
        Utilities.writeLog('Returning parent object', 
            AccountOpportunitiesExtension.class, 'getParentObject', LoggingLevel.DEBUG);
        System.debug(this.acct);
        return this.acct;
    }

    /* Primary Point-of-Contact Id (Not necessarily Owner or Contact objects) */
    public Id getWhoId() {
        return this.acct.OwnerId;
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