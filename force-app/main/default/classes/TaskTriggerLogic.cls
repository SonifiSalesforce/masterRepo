// *********************************************************************************************
// Filename:     TaskTriggerLogic
// Version:      0.0.1
// Author:       Etherios
// Date Created: 9/16/2013
// Description:  Handles all 
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class TaskTriggerLogic {
	
	private static final String ignoredFields = '|CLARIFY_ID__C|MIGRATION_LOAD__C|';
	
	/**
	 * Processes rules associated with when a support case task is created/updated.
	 * NOTE Assumes that all incoming tasks are support case tasks.
	 */
	public static void processSupportTaskUpdate(List<Task> taskList) {
		
		// Check for records to process
		if (taskList == null || taskList.isEmpty()) { return; }
		
		// Get task fields
		List<String> taskFields = Utilities.getSObjectFields(Task.getSObjectType(), true);
		
		List<CaseComment> commentsToAdd = new List<CaseComment>();
		Map<Id, Case> caseMap = new Map<Id, Case>();
		for (Task t : taskList) {
			try {
				
				Case c;
				if ((caseMap.containsKey(t.WhatId))) {
					c = caseMap.get(t.WhatId);
				} else { 
					c = new Case(Id = t.WhatId);
				}
				
				// Affect hard-coded field updates
				if (t.Case_Status__c != null && t.Case_Status__c != '') { c.Status = t.Case_Status__c; }
				
				// Iterate over task custom fields and update values on the case
				for (String fieldName : taskFields) {
					
					// Check for ignored fields
					if (!ignoredFields.contains('|' + fieldName.toUpperCase() + '|')) {
						
						// Update same-named field on case with task field value
						try { c.put(fieldName, t.get(fieldName)); }
						catch (Exception e) { /* IGNORE ERRORS */ }
						
					}
				}
				
				// Add the case to the list
				caseMap.put(c.Id, c);
				
				// Check for comment
				if (t.Internal_Notes__c != null && t.Internal_Notes__c != '') {
					commentsToAdd.add(new CaseComment(
						CommentBody = t.Internal_Notes__c,
						ParentId = c.Id,
						IsPublished = false
					));
				}
				
			} catch (Exception e) {}
		}
		
		// Check for cases to update
		try { if (!caseMap.isEmpty()) { update caseMap.values(); } }
		catch (Exception e) { System.debug('TaskTriggerLogic.processSupportTaskUpdate. Error updating cases for tasks. Details: ' + e.getMessage()); }
		
		// Check for case comments to update
		try { if (!commentsToAdd.isEmpty()) { insert commentsToAdd; } }
		catch (Exception e) { System.debug('TaskTriggerLogic.processSupportTaskUpdate. Error updating case comments for tasks. Details: ' + e.getMessage()); }
	}
}