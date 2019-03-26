// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Utilities test class
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

@isTest
public with sharing class UtilitiesTests2 {
	
	@isTest static void testProfileConversions() {
		
		Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'testProfileConversions', LoggingLevel.INFO);
		system.debug('TEST STARTED: testProfileConversions');
		
		Id profileId = Utilities.ProfileNameToId(Definitions.PROFILE_SystemAdmin);
		String profileName = Utilities.ProfileIdToName(profileId);
		System.assertEquals(profileName, Definitions.PROFILE_SystemAdmin);
		
		profileId = Utilities.ProfileNameToId(Definitions.PROFILE_HealthcareSales);
		profileName = Utilities.ProfileIdToName(profileId);
		System.assertEquals(profileName, Definitions.PROFILE_HealthcareSales);
		
		profileId = Utilities.ProfileNameToId(Definitions.PROFILE_SalesUser);
		profileName = Utilities.ProfileIdToName(profileId);
		System.assertEquals(profileName, Definitions.PROFILE_SalesUser);
		
		//Utilities.writeLog('TEST COMPLETE', UtilitiesTests2.class, 'testProfileConversions', LoggingLevel.INFO);
		
		system.debug('TEST COMPLETE:  testProfileConversions');
	}
	
	@isTest static void testRecordTypeConversions() {

		//Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'testRecordTypeConversions', LoggingLevel.INFO);
		system.debug('TEST STARTED:  testRecordTypeConversions');
		
		Id recordTypeId = Utilities.RecordTypeNameToId('Lead', Definitions.RECORDTYPE_HealthcareLeads);
		String recordTypeName = Utilities.RecordTypeIdToName('Lead', recordTypeId);
		System.assertEquals(recordTypeName, Definitions.RECORDTYPE_HealthcareLeads);

		recordTypeId = Utilities.RecordTypeNameToId('Lead', Definitions.RECORDTYPE_HospitalityLeads);
		recordTypeName = Utilities.RecordTypeIdToName('Lead', recordTypeId);
		System.assertEquals(recordTypeName, Definitions.RECORDTYPE_HospitalityLeads);

		//Utilities.writeLog('TEST COMPLETE', UtilitiesTests2.class, 'testRecordTypeConversions', LoggingLevel.INFO);
		system.debug('TEST COMPLETED:  testRecordtypeConversions');
	}
	
	@isTest(seeAllData=true) static void testRecordTypeIdToName() {
		
		//Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'testRecordTypeIdToName', LoggingLevel.INFO);
		system.debug('TEST STARTED:  testRecordTypeIdtoName');
		
		RecordType recordType =[Select Id,Name,sobjecttype from RecordType where sobjecttype = 'Case' Limit 1];
	 	Id recordTypeId = recordType.Id;
		
		String recordTypeIdToName = Utilities.RecordTypeIdToName('Case', recordTypeId);
		System.assertNotEquals(null,recordTypeIdToName);
		
		//Utilities.writeLog('TEST COMPLETE, rec type name returned is ' +recordTypeIdToName, UtilitiesTests2.class, 'testRecordTypeIdToName', LoggingLevel.INFO);
		system.debug('TEST COMPLETE:  testRecordtypeIdToName');
	}
	
	@isTest(seeAllData=true) static void testRecordTypeNameToIdWithObject() {
		
		//Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'RecordTypeNameToIdWithObject', LoggingLevel.INFO);
		system.debug('TEST STARTED:  testRecordTypeNametoidWithObject');
		
		Id recordTypeNameToIdWithObject = Utilities.RecordTypeNameToIdWithObject(Definitions.RECORDTYPE_Case_SupportCase, 'Case');
		System.assertNotEquals(null,recordTypeNameToIdWithObject);
		
		
		//Utilities.writeLog('TEST COMPLETE', UtilitiesTests2.class, 'RecordTypeNameToIdWithObject', LoggingLevel.INFO);
		system.debug('TEST COMPLETE:  testRecordtypeNametoIdWithObject');
	}
	
	@isTest(seeAllData=true) static void testRecordTypeNameToId() {
		
		//Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'testRecordTypeNameToId', LoggingLevel.INFO);
		system.debug('TEST STARTED:  testRecordTypeNameToId');
		
		Id recordTypeNameToId = Utilities.RecordTypeNameToIdWithObject(Definitions.RECORDTYPE_Case_SupportCase,'Case');
		System.assertNotEquals(null,recordTypeNameToId);
		
		recordTypeNameToId = Utilities.RecordTypeNameToId('Case',Definitions.RECORDTYPE_Case_SupportCase);
		System.assertNotEquals(null,recordTypeNameToId);
		
		//Utilities.writeLog('TEST COMPLETE', UtilitiesTests2.class, 'testRecordTypeNameToId', LoggingLevel.INFO);
		system.debug('TEST COMPLETE:  testRecordTypeNameToId');
		
	}
	
	@isTest static void testGetRecordTypes(){
		//Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'testGetRecordTypes', LoggingLevel.INFO);
		system.debug('TEST STARTED:  testGetRecordType');
		
		Map<String,Id> getRecordTypes = Utilities.getRecordTypes('Order__c');
		System.assertNotEquals(null,getRecordTypes);
		
		//Utilities.writeLog('TEST COMPLETE', UtilitiesTests2.class, 'testGetRecordTypes', LoggingLevel.INFO);
		system.debug('TEST COMPLETE:  testGetRecordType');
		
	}
	
	@isTest(seeAllData=true) static void testProfileIdToName(){
		Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'testProfileIdToName', LoggingLevel.INFO);
		
		//RecordType recordType =[Select Id,Name from RecordType Limit 1];
		Profile recordType = [Select Id,Name from Profile Limit 1];
	 	Id recordTypeId = recordType.Id;
	 	
	 	
		String profileIdToName = Utilities.ProfileIdToName(recordTypeId);
		System.assertNotEquals(null,profileIdToName);
		
		Utilities.writeLog('TEST COMPLETE', UtilitiesTests2.class, 'testProfileIdToName', LoggingLevel.INFO);
	}
	
	@isTest static void testGetLabelToFieldMap(){
		Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'testGetLabelToFieldMap', LoggingLevel.INFO);
		
		Map<String, String> getLabelToFieldMap = Utilities.getLabelToFieldMap('Order__c');
		System.assertNotEquals(null,getLabelToFieldMap);
		
		Utilities.writeLog('TEST COMPLETE', UtilitiesTests2.class, 'testGetLabelToFieldMap', LoggingLevel.INFO);
	}
	
	@isTest static void testgetFieldNameToLabelMap(){
		Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'testgetFieldNameToLabelMap', LoggingLevel.INFO);
		
		Map<String, String> getLabelToFieldMap = Utilities.getFieldNameToLabelMap('Order__c');
		System.assertNotEquals(null,getLabelToFieldMap);
		
		Utilities.writeLog('TEST COMPLETE', UtilitiesTests2.class, 'testgetFieldNameToLabelMap', LoggingLevel.INFO);
	}
	
	/*@isTest static void testurlPrefix(){
		Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'testurlPrefix', LoggingLevel.INFO);
		
		String str = Utilities.urlPrefix;
		System.assertNotEquals(null,str);
		
		Utilities.writeLog('TEST COMPLETE', UtilitiesTests2.class, 'testurlPrefix', LoggingLevel.INFO);
	}*/
	
	@isTest(seeAllData = true) static void testclosedCaseStatuses(){
		Utilities.writeLog('TEST STARTED', UtilitiesTests2.class, 'testclosedCaseStatuses', LoggingLevel.INFO);
		
		List<CaseStatus> caseStatus = [SELECT MasterLabel
											FROM CaseStatus
											WHERE IsClosed = true
											ORDER BY SortOrder];
		System.debug('caseStatus is : '+caseStatus);
		
		List<String> closedCaseStatuses = Utilities.closedCaseStatuses;
		System.assertNotEquals(null,closedCaseStatuses);
		Utilities.writeLog('TEST COMPLETE', UtilitiesTests2.class, 'testclosedCaseStatuses', LoggingLevel.INFO);
		
	}
	 
/*	
	@isTest static void testCloneSObjects() {
		
		User u = DataGenerator.createUsers(
			Definitions.PROFILE_SalesUser, 1, true)[0];
		System.assertNotEquals(null, u.Id);
		
		Account a = DataGenerator.createAccounts(1, true)[0];
		System.assertNotEquals(null, a.Id);
		
		List<Opportunity> cloneToObjectList = DataGenerator.createOpptys(a, 2, true);
		System.assertNotEquals(null, cloneToObjectList);
		System.assertEquals(2, cloneToObjectList.size());
		
		Opportunity cloneFromObject = cloneToObjectList.remove(0);
		
		System.runAs(u) {
			
			Note n = DataGenerator.createNotes(cloneFromObject, 1, true)[0];
			System.assertNotEquals(null, n.Id);
			
			Event e = DataGenerator.createEvents(cloneFromObject, 1, true)[0];
			System.assertNotEquals(null, e.Id);
			
			Test.startTest();
			
			List<Id> cloneableItemIdList = new List<Id> { n.Id, e.Id };
			
			Schema.SObjectType opptyObjectType = Opportunity.getSObjectType();
			
			Map<Schema.SObjectField, Schema.SObjectField> fieldMap = 
					new Map<Schema.SObjectField, Schema.SObjectField>();
			
			Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>> objectFieldMap = 
					new Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>();
			
			Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> itemObjectFieldMap =
				new Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>>();
			
			// Build item-object map
			fieldMap.put(Note.ParentId, Opportunity.Id);
			System.debug(LoggingLevel.ERROR, 'Note Field Map: ' + fieldMap);
			objectFieldMap.put(opptyObjectType, fieldMap);
			System.debug(LoggingLevel.ERROR, 'Object Field Map: ' + objectFieldMap);
			itemObjectFieldMap.put(Note.getSObjectType(), objectFieldMap);
			
			fieldMap = new Map<Schema.SObjectField, Schema.SObjectField>();
			objectFieldMap = new Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>();
			
			fieldMap.put(Event.WhatId, Opportunity.Id);
			System.debug(LoggingLevel.ERROR, 'Event Field Map: ' + fieldMap);
			objectFieldMap.put(opptyObjectType, fieldMap);
			System.debug(LoggingLevel.ERROR, 'Object Field Map: ' + objectFieldMap);
			itemObjectFieldMap.put(Event.getSObjectType(), objectFieldMap);

			for (Schema.SObjectType itemType : itemObjectFieldMap.keyset()) {
				System.debug(LoggingLevel.ERROR, 'Item-Object Field Map (' + itemType +'): ' + itemObjectFieldMap.get(itemType));
			}
			
			// Clone
			
			
			Map<Schema.SObjectType, List<SObject>> clonedObjectsMap = 
				Utilities.cloneSObjects(cloneableItemIdList, cloneToObjectList, itemObjectFieldMap, true);
			
			clonedObjectsMap = Utilities.cloneSObjects(cloneableItemIdList, null, itemObjectFieldMap, true);
			System.assertNotEquals(null, clonedObjectsMap);	
			// Clone Two
			List<Sobject> cloneableItemList = new List<Sobject> { n, e };
			
			clonedObjectsMap = Utilities.cloneSObjects(cloneableItemList, null, itemObjectFieldMap, true);
			System.assertNotEquals(null, clonedObjectsMap);
			
			clonedObjectsMap = Utilities.cloneSObjects(cloneableItemList, cloneToObjectList, itemObjectFieldMap, true);
			
			//End Clone Two
			
			Test.stopTest(); 
			
			// Check data
			List<Id> objectIds = new List<Id>();
			for (Opportunity o : cloneToObjectList) {
				objectIds.add(o.Id);
			}
			 
        	List<Note> noteList = [
        		SELECT Id, CreatedById, CreatedBy.Name
        		FROM Note
        		WHERE ParentId = :cloneToObjectList[0].Id
        	];
			System.assertNotEquals(null, noteList);
			//System.assertEquals(1, noteList.size());
			
        	List<Event> eventList = [
				SELECT Id, OwnerId, Owner.Name
		    	FROM Event
				WHERE WhatId = :cloneToObjectList[0].Id
        	];
			System.assertNotEquals(null, eventList);
			//System.assertEquals(1, eventList.size());
		}
	}
*/	
	
	@isTest static void testGetSObjectFields() {
		List<String> strList =Utilities.getSObjectFields('Opportunity');
		System.assertNotEquals(null,strList);
		
		strList =Utilities.getSObjectFields('Opportunity',true);
		System.assertNotEquals(null,strList);
		 
		strList =Utilities.getSObjectFields(Opportunity.getsobjectType());
		System.assertNotEquals(null,strList);
		
		strList =Utilities.getSObjectFields(Opportunity.getsobjectType(),true);
		System.assertNotEquals(null,strList);
	}
	
	@isTest static void testGetRelatedListData() {
		Account acc =  DataGenerator.createAccounts(1,true)[0];
		List<Task> t = DataGenerator.createTasks(acc, 2, true);
		System.assertNotEquals(null,t);
		
		        	String query = 
        			'SELECT '
        				+ '(SELECT Id, OwnerId, Owner.Name, ActivityDate, Subject, Status '
        				+ 'FROM Tasks '
		        		+ 'ORDER BY ActivityDate DESC, LastModifiedDate DESC ) '
	        		+ 'FROM Account '
	        		+ 'WHERE Id = \'' + acc.Id + '\'';
        		
        List<SObject> listData = Utilities.getRelatedListData(query,'Tasks' );
        System.assertNotEquals(null,listData);
		
	}
	
	@isTest static void testWriteCustomFields(){
		Integer recordsToCreate = 100;
		Account acc =  DataGenerator.createAccounts(1,true)[0];

		Case toCase = DataGenerator.createCases(acc.Id, recordsToCreate, true)[0];
		Case fromCase = DataGenerator.createCases(acc.Id, recordsToCreate, true)[0];
		Task fromTask = DataGenerator.createTasks(fromCase, recordsToCreate, true)[0];
		fromTask.Issue_Details_Description__c = 'Test Issue_Details_Description__c';
		fromTask.Issue_Sub_Type__c = 'Test Issue_Sub_Type__c';
		fromTask.Migration_Load__c = 'Test Migration_Load__c';
		fromTask.Clarify_ID__c = 'Test Clarify_ID__c';
		fromTask.Case_Product_Type__c = 'Test Case_Product_Type__c';
		fromTask.Issue_Type__c = 'Test Issue_Type__c';
		fromTask.Issue_Details__c = 'Test Issue_Details__c';
		fromTask.Services_Installed__c = 'Test Services_Installed__c';
		upsert fromTask;
		
		List<String> fieldNames = new List<String>();
		fieldNames.add('Issue_Details_Description__c');
		fieldNames.add('Issue_Sub_Type__c');
		fieldNames.add('Migration_Load__c');
		fieldNames.add('Clarify_ID__c');
		fieldNames.add('Case_Product_Type__c');
		fieldNames.add('Issue_Type__c');
		fieldNames.add('Issue_Details__c');
		fieldNames.add('Services_Installed__c');
		
		Utilities.writeCustomFields(fromTask, toCase, fieldNames);
		upsert toCase;
		String query = 'Select Id,'+String.join(fieldNames,',')+' from Case where Id = \''+toCase.Id +'\' ';
		
		Case caseNew = Database.query(query);
		System.assertNotEquals(null,caseNew);
	}
}