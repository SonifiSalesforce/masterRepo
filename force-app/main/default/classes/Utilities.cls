// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Class for co-locating generic utility methods
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class Utilities {
	
	private static Map<String, Id>		NameToIdMap							;
	private static Map<Id, String>		IdToNameMap							;
	
	/* Read the Profile Id from the name-to-id map */
	public static Id ProfileNameToId(String theName) {
		if (theName == null || theName == '') { return null; }
		Id theId;
		if (NameToIdMap == null || !NameToIdMap.containsKey(theName)) {
			try {
				theId = [SELECT Id FROM Profile WHERE Name = :theName LIMIT 1].Id;
				updateMaps(theId, theName);
			} catch (Exception e) {
				throw new Exceptions.AppException(
					'UNABLE TO LOCATE PROFILE \'' + theName + '\'. '
					+ 'IF THE NAME HAS CHANGED, PLEASE MAKE THE CORRESPONDING CHANGE IN THE DEFINITIONS CLASS.');
			}
		} else {
			theId = NameToIdMap.get(theName);
		}
		return theId;
	}
	
	/* Passthrough method for symmetry  */
	public static String ProfileIdToName(Id theId) {
		if (theId == null) { return null; }
		String theName;
		if (IdToNameMap == null || !IdToNameMap.containsKey(theId)) {
			try {
				theName = [SELECT Name FROM Profile WHERE Id = :theId LIMIT 1].Name;
				updateMaps(theId, theName);
			} catch (Exception e) {
				throw new Exceptions.AppException('Profile Id \'' + theId + '\' not found.', e);
			}
		} else {
			theName = IdToNameMap.get(theId);
		}
		return theName;
	}

	/* Creates static id and name map objects and adds the new information */
	private static void updateMaps(Id theId, String theName) {
		if (IdToNameMap == null) { IdToNameMap = new Map<Id, String>(); }
		if (NameToIdMap == null) { NameToIdMap = new Map<String, Id>(); }
		NameToIdMap.put(theName, theId);
		IdToNameMap.put(theId, theName);
	}

	/* Read the record type id using the name and getDescribe */
	public static Id RecordTypeNameToId(String sObjectName, String recordTypeName) {
		
		// Check for object name
		if (sObjectName == null || sObjectName == '') {
			throw new Exceptions.IllegalArgumentException('No SObject name provided.');
		}
		
		// Check for record type name
		if (recordTypeName == null || recordTypeName == '') {
			throw new Exceptions.IllegalArgumentException('No RecordType name provided.');
		}
		
		Id recordTypeId;
		try {
			Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sObjectName);
			recordTypeId = objectType.getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
		} catch (Exception e) {
			throw e;
		}
		
		return recordTypeId;
	}
	
	/**
	 * NOTE THIS METHOD HAS BEEN REPLACED WITH THE RecordTypeNameToId METHOD THAT USES 
	 * GETDESCRIBE RATHER THAN SOQL TO READ THE DATA. BECAUSE THE SIGNATURES ARE REVERSED
	 * AND THERE ARE A NUMBER OF REFERENCES TO IT, I LEFT THIS ONE IN TACT. 
	 * PLEASE USE THE OTHER METHOD MOVING FORWARD.
	 */
	public static Id RecordTypeNameToIdWithObject(String recordTypeName, String sObjectName) {
		System.debug(LoggingLevel.ERROR, 'Utilities.RecordTypeNameToIdWithObject. *****  THIS METHOD HAS BEEN DEPRECATED  *****');
		try { return RecordTypeNameToId(sObjectName, recordTypeName); }
		catch (Exception e) {}
		return null;
	}
	
	/** 
	 * Read the record type name using the id
	 * NOTE If you know the object, use this method as it uses getDescribe rather than 
	 * a SOQL query to get the desired info.
	 */
	public static String RecordTypeIdToName(String sObjectName, Id recordTypeId) {
		
		// Check for object name
		if (sObjectname == null || sObjectName == '') {
			throw new Exceptions.IllegalArgumentException('No SObject name provided.');
		}
		
		// Check for record type id
		if (recordTypeId == null) {
			throw new Exceptions.IllegalArgumentException('No RecordType Id provided.');
		}
		
		String recordTypeName;
		try {
			//jjackson 9/2016 needed to update this code to use new recordtype functions
			//Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sObjectname);
			//recordTypeName = objectType.getDescribe().getRecordTypeInfosById().get(recordTypeId).getName();
			
			Map<Id,Schema.RecordTypeInfo> maprectype = Schema.getGlobalDescribe().get(sObjectName).getDescribe().getRecordTypeInfosById();
			if(maprectype.containskey(recordTypeId))
			{
				recordTypeName = maprectype.get(recordTypeId).getName();
			}
			else
			{ throw new Exceptions.IllegalArgumentException('Utilities.RecordTypeIdToName: ERROR Finding record type name for Id ' +recordTypeId); }
			
		} catch (Exception e) {
			throw e;
		}
		
		return recordTypeName;
	}
	
	/**
	 * Returns a Map of type <String,Id> of Record Types for input Object
	 */
	public static Map<String,Id> getRecordTypes(string objectAPIName){
        if(objectAPIName == null || objectAPIName == '')
        {
            return null;
        }        
        Map<String, Schema.SObjectType> sobjectSchemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjType = sobjectSchemaMap.get(objectAPIName) ;
        Schema.DescribeSObjectResult cfrSchema = sObjType.getDescribe() ;
        Map<String,Schema.RecordTypeInfo> RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
        Map<String,Id> rtMap = new Map<String,Id>();
        for(Schema.RecordTypeInfo rti : RecordTypeInfo.values())
        {
			rtMap.put(rti.getName(),rti.getRecordTypeId());        	
        }
        return rtMap;
    }


    /* Returns all fields in an SObject */
    public static List<String> getSObjectFields(String objectName) {
        return getSObjectFields(objectName, false);
    }
            
    /* Returns all fields in an SObject */
    public static List<String> getSObjectFields(String objectName, Boolean customOnly) {
        
        // Check for object name to process
        if (objectName == null) { return null; }
        
        // Get the object type
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            throw new Exceptions.UnsupportedObjectTypeException(
                'Unable to identify object type for object name \'' + objectName + '\'.');
        }
        
        return getSObjectFields(objectType, customOnly);
    }
            
    /* Returns all fields in an SObject */ 
    public static List<String> getSObjectFields(Schema.SObjectType objectType) {
        return getSObjectFields(objectType, false);
    }

    /* Returns all fields in an SObject */ 
    public static List<String> getSObjectFields(Schema.SObjectType objectType, Boolean customOnly) {
        
        // Check for object type 
        if (objectType == null) { return null; }
        
        if (Test.isRunningTest()) { System.debug('Utilities.getSObjectFields. Getting fields for SObjectType ' + objectType.getDescribe().getName()); }
        
        // Get field map
        Map<String, SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        
        //  Iterate over fields and add UPDATEABLE (and potentially CUSTOM) fields to list
        List<String> fieldList = new List<String>();
        for (String f : fieldMap.keySet()) {
            DescribeFieldResult field = fieldMap.get(f).getDescribe();
            if (field.isUpdateable()) {
                if (!customOnly || field.isCustom()) {
                    fieldList.add(field.getName());
                    if (Test.isRunningTest()) { System.debug('Utilities.getSObjectFields. Adding field ' + field.getName()); }
                }
            }
        }
        
        // Return list
        return fieldList;   
    }

    /**
     * Returns a map of field labels to their API names
     */
    public static Map<String, String> getLabelToFieldMap(String sObjectName) {
		Map<String, String> fieldLabelMap = new Map<String, String>();
		DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
		Map<String, SObjectField> fieldMap = describeResult.fields.getMap();
		for (SObjectField f : fieldMap.values()) {
			DescribeFieldResult field = f.getDescribe();
			fieldLabelMap.put(field.getLabel(), field.getName());
		}
		return fieldLabelMap;
    }
    
    /**
     * Returns a map of field API names to their labels (reverse lookup)
     */
    public static Map<String, String> getFieldNameToLabelMap(String sObjectName) {
		Map<String, String> fieldNameMap = new Map<String, String>();
		DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
		Map<String, SObjectField> fieldMap = describeResult.fields.getMap();
		for (SObjectField f : fieldMap.values()) {
			DescribeFieldResult field = f.getDescribe();
			fieldNameMap.put(field.getName(), field.getLabel());
		}
		return fieldNameMap;
    }
    
    /**
     * Writes custom field values from same-named fields in one object to another
     */
    public static void writeCustomFields(sObject fromObject, sObject toObject, List<String> fieldList) {
        
        // Check for objects
        if (fromObject == null || toObject == null) { return; }
        
        // Check for fields
        if (fieldList == null || fieldList.isEmpty()) {
            try { fieldList = Utilities.getSObjectFields(fromObject.getSObjectType(), true); } 
            catch (Exception e) { throw e; }
            if (fieldList == null || fieldList.isEmpty()) { return; }
        }
        
        // Iterate over fields and write values from the fromObject to the toObject
        for (String field : fieldList) {
            try { toObject.put(field, fromObject.get(field)); }
            catch (Exception e) { /* IGNORE ERRORS */ }
        }
    }
    
    /**
     * Executes query and builds list of related list objects 
     * NOTE This provides a centralized location for pulling data for related list fields that
     * cannot be queried on their own (ex. ActivityHistory, NoteAndAttachment) 
     */
    public static List<SObject> getRelatedListData(String query, String relatedListName) {
        
        // Check for query
        if (query == null || query == '') {
            throw new Exceptions.IllegalArgumentException('No query provided.');
        }
        
        // Check for related list
        if (relatedListName == null || relatedListName == '') {
            throw new Exceptions.IllegalArgumentException('No related list name provided.');
        }
        
        // Attempt to execute query
        List<SObject> relatedObjectList = new List<SObject>();
        try {
            List<SObject> queryResultList = Database.query(query);
            if (queryResultList == null) { return null; }
            if (Test.isRunningTest()) { System.debug(queryResultList); }
            
            for (SObject o : queryResultList) {
                if (Test.isRunningTest()) { System.debug(o); }
                List<SObject> relatedList = (List<SObject>)o.getSObjects(relatedListName);
                Utilities.writeLog(
                    'Adding ' + relatedList.size() + ' list items.', 
                    Utilities.class, 'getRelatedListData', LoggingLevel.DEBUG);
                relatedObjectList.addAll((List<SObject>)o.getSObjects(relatedListName));
            }
        } 
        catch (Exception e) { 
            Utilities.writeLog(
                'ERROR Adding list items. Details: ' + e.getMessage(), 
                Utilities.class, 'getRelatedListData', LoggingLevel.DEBUG);
            return null; 
        }
        
        Utilities.writeLog(
            'Returning ' + relatedObjectList.size() + ' list items.', 
            Utilities.class, 'getRelatedListData', LoggingLevel.DEBUG);
        return relatedObjectList;
    }
    
	/**
	 * Clones SObjects based on a generic list of Ids received
	 */
    public static Map<Schema.SObjectType, List<SObject>> cloneSObjects(
            List<Id> cloneableItemIdList, 
            List<SObject> cloneToObjectList,
            Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> objectFieldMap, 
            Boolean insertRecords) {
        
        // Check for cloneable objects
        if (cloneableItemIdList == null || cloneableItemIdList.isEmpty()) {
            throw new Exceptions.IllegalArgumentException('No cloneable items provided for cloning.');
        }
        
        // Check for clone-to objects
        if (cloneToObjectList == null || cloneToObjectList.isEmpty()) {
        
            cloneToObjectList = null; // Force to null to simplify further checking
            Utilities.writeLog('No objects provided to associate cloned items to.', 
                Utilities.class, 'cloneSObjects', LoggingLevel.DEBUG);
        } else if (objectFieldMap == null) {
            // If clone-to objects provided, field map MUST exist
            throw new Exceptions.IllegalArgumentException('No field map provided for cloning.');
        }
        
        // Create map of cloneable item types
        Map<Schema.SObjectType, List<Id>> cloneableItemTypeMap = new Map<Schema.SObjectType, List<Id>>();
        for (Id itemId : cloneableItemIdList) { 
            Schema.SObjectType itemType = itemId.getSObjectType();
            if (cloneableItemTypeMap.containsKey(itemType)) {
                cloneableItemTypeMap.get(itemType).add(itemId);
            } else {
                cloneableItemTypeMap.put(itemType, new List<Id> { itemId });
            }
        }
        
        // Iterate over cloneable item types
        Map<Schema.SObjectType, List<SObject>> cloneableItemsMap = new Map<Schema.SObjectType, List<SObject>>();
        for (Schema.SObjectType cloneableItemType : cloneableItemTypeMap.keyset()) {
            
            // Get fields for cloneable item type
            List<String> fieldList = getSObjectFields(cloneableItemType);
            
            // Query for cloneable item object data
            List<SObject> cloneableItemsList = Database.query(
                  'SELECT ' + String.join(fieldList, ',') + ' '
                + 'FROM ' + cloneableItemType +  ' '
                + 'WHERE Id IN (\'' + String.join(cloneableItemTypeMap.get(cloneableItemType), '\',\'') + '\')'
            );
            
            // Add current list to map
            cloneableItemsMap.put(cloneableItemType, cloneableItemsList);
        }
        
        // Clone SObjects and return result
        return cloneSObjects(cloneableItemsMap, cloneToObjectList, objectFieldMap, insertRecords);
    }
    
    /** 
     * Clones SObjects based on a generic list of Ids received 
     */
    public static Map<Schema.SObjectType, List<SObject>> cloneSObjects (
            List<SObject> cloneableItemsList, 
            List<SObject> cloneToObjectList,
            Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> objectFieldMap, 
            Boolean insertRecords) {
        
        // Check for cloneable objects
        if (cloneableItemsList == null || cloneableItemsList.isEmpty()) {
            throw new Exceptions.IllegalArgumentException('No cloneable items provided for cloning.');
        }
        
        // Check for clone-to objects
        if (cloneToObjectList == null || cloneToObjectList.isEmpty()) {
            cloneToObjectList = null; // Force to null to simplify further checking
            Utilities.writeLog('No objects provided to associate cloned items to.', 
                Utilities.class, 'cloneSObjects', LoggingLevel.DEBUG);
        } else if (objectFieldMap == null) {
            // If clone-to objects provided, field map MUST exist
            throw new Exceptions.IllegalArgumentException('No field map provided for cloning.');
        }
        
        // Create map of cloneable items
        Map<Schema.SObjectType, List<SObject>> cloneableItemsMap = new Map<Schema.SObjectType, List<SObject>>();
        for (SObject item : cloneableItemsList) { 
            Schema.SObjectType itemType = item.getSObjectType();
            if (cloneableItemsMap.containsKey(itemType)) {
                cloneableItemsMap.get(itemType).add(item);
            } else {
                cloneableItemsMap.put(itemType, new List<SObject> { item });
            }
        }
        
        // Clone SObjects and return result
        return cloneSObjects(cloneableItemsMap, cloneToObjectList, objectFieldMap, insertRecords);
    }
    
    /**
     * Clones SObjects based on a generic list of Ids received 
     */
    public static Map<Schema.SObjectType, List<SObject>> cloneSObjects(
            Map<Schema.SObjectType, List<SObject>> cloneableItemsMap, 
            List<SObject> cloneToObjectList,
            Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> objectFieldMap, 
            Boolean insertRecords) {

        // Check for cloneable objects
        if (cloneableItemsMap == null || cloneableItemsMap.isEmpty()) {
            throw new Exceptions.IllegalArgumentException('No cloneable items provided for cloning.');
        }
        
        // Check for clone-to objects
        if (cloneToObjectList == null || cloneToObjectList.isEmpty()) {
            cloneToObjectList = null; // Force to null to simplify further checking
            Utilities.writeLog('No objects provided to associate cloned items to.', 
                Utilities.class, 'cloneSObjects', LoggingLevel.DEBUG);
        } else if (objectFieldMap == null) {
            // If clone-to objects provided, field map MUST exist
            throw new Exceptions.IllegalArgumentException('No field map provided for cloning.');
        }
        
        // Iterate over cloneable items
        Map<Schema.SObjectType, List<SObject>> clonedObjectsMap = new Map<Schema.SObjectType, List<SObject>>();
        for (Schema.SObjectType cloneableItemType : cloneableItemsMap.keyset()) {
            
            if(cloneToObjectList != null){
            // Iterate over clone-to objects
            for (SObject cloneToObject : cloneToObjectList) {
                
                // Get current object type
                Schema.SObjectType cloneToObjectType = cloneToObject.getSObjectType();
                
                // Clone items for current clone-to object
                List<SObject> clonedObjectList = cloneableItemsMap.get(cloneableItemType).deepClone();
                
                // Assign fields
                for (SObject clonedObject : clonedObjectList) {
    
                    try {
                        
                        // Set the owner Id to the current user
                        clonedObject.put('OwnerId', UserInfo.getUserId());
                        
                    } catch (Exception e) {
                        // Log exception in field mapping but ignore.
                        Utilities.writeLog('ERROR Mapping OwnerId to ' + UserInfo.getUserId()
                             + '. Details: ' + e.getMessage(), 
                            Utilities.class, 'cloneSObjects', LoggingLevel.INFO);
                    }
                    
                    // Check for additional fields to clone
                    if (objectFieldMap != null) {
                         
                        // Check for a field mapping of the current objects
                        if (objectFieldMap.containsKey(cloneableItemType)) {
                            
                            if (objectFieldMap.get(cloneableItemType).containsKey(cloneToObjectType)) {
                                
                                Map<Schema.SObjectField, Schema.SObjectField> fieldMap = objectFieldMap.get(cloneableItemType).get(cloneToObjectType);
                                
                                // Iterate over custom field mapping
                                for (Schema.SObjectField cloneableItemField : fieldMap.keyset()) {
                                    
                                    // Get clone-to object field
                                    Schema.SObjectField cloneToObjectField = fieldMap.get(cloneableItemField);
                                    
                                    try {
                                        
                                        // Set value
                                        clonedObject.put(cloneableItemField, cloneToObject.get(cloneToObjectField));
                                        
                                    } catch (Exception e) {
                                        // Log exception in field mapping but ignore.
                                        Utilities.writeLog('ERROR Mapping ' + cloneableItemField 
                                            + ' to ' + cloneToObjectField + '. Details: ' + e.getMessage(), 
                                            Utilities.class, 'cloneSObjects', LoggingLevel.INFO);
                                    }
                                    
                                }
                            }
                            
                        }
                    }
                }
                
                // Add cloned objects to map
                if (clonedObjectsMap.containsKey(cloneableItemType)) {
                    clonedObjectsMap.get(cloneableItemType).addAll(clonedObjectList);
                } else {
                    clonedObjectsMap.put(cloneableItemType, clonedObjectList);
                }
            }
        }
        }
        
        // Check for insert
        if (insertRecords) {
            
            Savepoint sp = Database.setSavepoint();
            
            try {
                // Iterate over cloned object types and insert records
                for (Schema.SObjectType clonedObjectType : clonedObjectsMap.keyset()) {
                    insert clonedObjectsMap.get(clonedObjectType);
                }
            } catch (Exception e) {
                Database.rollback(sp);
                throw e;
            }
        }
        
        // Return cloned objects
        return clonedObjectsMap;
    }
    
    /**
     * Returns the prefix for the current Salesforce url
     * NOTE This should be used for any url that may be used in a portal scenario
     */
    public static String urlPrefix {
    	
    	get {
    		
    		// Reset for each request (even in same context)
    		urlPrefix = null;
    		
			try {
				// NOTE This is not a loop
				while (true) {
					
					// Get the current Url
					String requestUrl = URL.getCurrentRequestUrl().toExternalForm();
					System.debug('Utilities.urlPrefix. Current Request Url: ' + requestUrl);
					
					// Search for end of base path using path separator
					Integer prefixStart = requestUrl.indexOf('.com/');
					if (prefixStart < 0) { break; }
					
					// Find next path separator
					Integer prefixEnd = requestUrl.indexOf('/', prefixStart + 5);
					if (prefixEnd < 0) { break; }
					
					// Check for prefix too short, is "apex" or is an Id
					urlPrefix = requestUrl.substring(prefixStart + 5, prefixEnd);
					if (urlPrefix.length() < 4 || urlPrefix.toLowerCase() == 'apex' || Id.valueOf(urlPrefix) != null) {
						urlPrefix = null;
						break;
					}
					
					System.debug('Utilities.urlPrefix. Prefix: ' + urlPrefix);
					break;
				}
				
			} catch (Exception e) {}
			
			return urlPrefix;
    	}
    	private set;
    }
    
    /**
     * Uses the URL prefix to determine how to build a URL for 
     * redirecting a current page to. 
     */
    public static String getRedirectUrl(String pageUrl) {
    	String prefix = Utilities.urlPrefix;
    	if (pageUrl == null) { pageUrl = ''; }
    	return (prefix == null ? '' : '/' + prefix) + '/' + pageUrl;
    }
    
    /**
     * Uses the URL prefix to determine how to build a URL for use
     * with retURL, cancelURL, and saveURL URL parameters.
     * NOTE This works slightly different than the standard URL.
     * In community URLs, you MUST HAVE the preceding / character while
     * in non-community URLs--at least in Winter '14--you CAN'T have them.
     */
    public static String getReturnUrl(String pageUrl) {
    	String prefix = Utilities.urlPrefix;
    	if (pageUrl == null) { pageUrl = ''; }
    	return (prefix == null ? '' : '/' + prefix + '/') + pageUrl;
    }
    
    /**
     * Returns the list of case statuses that have been designated as "Closed"
     */
    public static List<String> closedCaseStatuses {
    	get {
    		if (closedCaseStatuses == null) {
    			closedCaseStatuses = new List<String>();
	    		try {
	    			for (CaseStatus status : [
							    				SELECT MasterLabel
												FROM CaseStatus
												WHERE IsClosed = true
												ORDER BY SortOrder]) {
						closedCaseStatuses.add(status.MasterLabel);
					}
	    		} catch (Exception e) {}
    		}
    		return closedCaseStatuses;
    	}
    	private set;
    }
    
	/* Writes a log enforcing a consistent format */
	public static void writeLog(String logData, Type classType, String methodName, LoggingLevel logLevel) {
		try { System.debug(logLevel, formatLog(logData, classType, methodName)); }
		catch (Exception e) { /* ignore exception */ }
	}
	
	/* Provides a consistent log format */
	public static String formatLog(String logData, Type classType, String methodName) {
		String logString = '';
		if (classType != null) { logString += String.valueOf(classType) + '.'; }
		if (methodName != null) { logString += methodName + '.'; }
		if (logData != null) { logString += ' ' + logData; }
		return logString.trim();
	}
	
}