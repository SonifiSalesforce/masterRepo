// *********************************************************************************************
// Filename:     StandardAccountTrigger
// Version:      0.0.1
// Author:       Etherios
// Date Created: 8/6/2013
// Description:  Trigger on the Account object.
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

trigger StandardAccountTrigger on Account (before update, after insert, after update) {
	
	// Check for trigger processing blocked by custom setting
	try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(AccountTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
	
	Boolean hasOld = (Trigger.oldMap != null && !Trigger.oldMap.isEmpty());
	
	// Check for changes
	Map<Id, Account> updatedAccountMap = new Map<Id, Account>();
	for (Account acct : Trigger.new) {
		Id newSupportOffice = acct.Support_Office__c;
		Id oldSupportOffice;
		if (hasOld && Trigger.oldMap.containsKey(acct.Id)) {
			oldSupportOffice = Trigger.oldMap.get(acct.Id).Support_Office__c;
		}
		
		// Check for change in support office
		if (newSupportOffice != oldSupportOffice) {
			updatedAccountMap.put(acct.Id, acct);
		}
	}
	
	// Check for no significant changes
	if (updatedAccountMap.isEmpty()) { return; }
	
	if (Trigger.isBefore) {
		
		// BEFORE UPDATE
		
		// Before the account is updated, we must validate that 
		// the new support office contains a Primary Engineer 
		// OR there are no dispatched cases for the account
		
		AccountTriggerLogic.validateSupportOffice(updatedAccountMap);
		
	} else {
		
		// AFTER INSERT, UPDATE
		
		// After insert/update, we must check for dispatched cases
		// and update them with the new support office information
		
		CustomAccountLogic.updateSupportOffice(updatedAccountMap);
	}
	
}