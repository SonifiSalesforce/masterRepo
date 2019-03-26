// *********************************************************************************************
// Filename:     StandardTaskTrigger
// Version:      0.0.1
// Author:       Etherios
// Date Created: 9/16/2013
// Description:  Trigger on the Task object.
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

trigger StandardTaskTrigger on Task (after insert, after update) {
	
	// Check for trigger processing blocked by custom setting
	try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(TaskTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
    
	// Get Support Case Task RecordId
	String supportTaskRecordId = Utilities.RecordTypeNameToId('Task', Definitions.RECORDTYPE_Task_SupportCase);
	
	// Iterate over tasks
	List<Task> supportCaseTaskList = new List<Task>();
	for (Task t : Trigger.new) {
		
		// Check for support case task and add to list if found
		if (t.RecordTypeId == supportTaskRecordId) { supportCaseTaskList.add(t); }
	}
	
	// Check for support case tasks to process and process if found
	if (!supportCaseTaskList.isEmpty()) { TaskTriggerLogic.processSupportTaskUpdate(supportCaseTaskList); }
}