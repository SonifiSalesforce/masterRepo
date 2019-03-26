// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/15/2013
// Description:  Lead object trigger event handler
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

trigger StandardLeadTrigger on Lead (after update) {
	
	System.debug(
		LoggingLevel.DEBUG,
		'StandardLeadTrigger.  **********    START');
		
	// Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(LeadTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
    
    Set<Lead> leads = new Set<Lead>();
	
	// Determine which leads, if any, are being converted
	for (Lead l : Trigger.new) {
		
		// Check for lead converted AND has account to affect
		if (!l.IsDeleted && l.IsConverted && l.ConvertedAccountId != null) {
			
			System.debug(
				LoggingLevel.DEBUG,
				'StandardLeadTrigger.  Checking converted lead...');
				 
			// Check for lead not previously converted
			if (Trigger.oldMap == null 
					|| !Trigger.oldMap.containsKey(l.Id)
					|| !Trigger.oldMap.get(l.Id).IsConverted) {
				
				// Add lead to set
				leads.add(l);
			}
 		}
	}
	
	// Check for leads to process
	if (leads.isEmpty()) {
		System.debug(
			LoggingLevel.DEBUG,
			'StandardLeadTrigger.  **********    NOTHING TO DO'); 
		return; 
	}
	
	// Process leads
	LeadTriggerLogic.ProcessLeadConversion(leads);

	System.debug(
		LoggingLevel.DEBUG,
		'StandardLeadTrigger.  **********    END');
}