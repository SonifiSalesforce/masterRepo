// *********************************************************************************************
// Filename:     AccountTriggerLogic
// Version:      0.0.1
// Author:       Etherios
// Date Created: 8/6/2013
// Description:  Contains methods for supporting the trigger on the Account object.
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class AccountTriggerLogic {
	
	public static final String				MESSAGE_DISPATCHED_CASES_FOUND		= 'Dispatched cases found for account. '
																				+ 'Cannot delete the support office or change the support office to an office ' 
																				+ 'without someone assigned to the ' + Definitions.SUPPORTMEMBER_PRIMARY_ENGINEER + ' role.';
	
	/**
	 * Confirms that the updated support office for an account either has a Primary Engineer
	 * assigned OR the account itself does not have any dispatched cases 
	 */
	public static void validateSupportOffice(Map<Id, Account> siteMap) {
		
		// Get support office Ids from site accounts 
		Set<Id> supportOfficeIds = new Set<Id>();
		for (Account site : siteMap.values()) {
			supportOfficeIds.add(site.Support_Office__c);
		}
		
		// Get support office accounts
		Map<Id, Account> supportOfficeMap = new Map<Id, Account>([
			SELECT Id, PrimaryEngineerCount__c
			FROM Account
    		WHERE Id IN :supportOfficeIds
    	]);
    	
    	// Iterate over accounts and check for support office and primary engineer 
    	List<Id> sitesToCheckCasesFor = new List<Id>();
    	for (Account site : siteMap.values()) {
    		if (site.Support_Office__c == null 
    			|| supportOfficeMap.get(site.Support_Office__c).PrimaryEngineerCount__c < 1) {
    			sitesToCheckCasesFor.add(site.Id);
    		}
    	}
    	
    	// Check for accounts that need further checking
    	if (sitesToCheckCasesFor.isEmpty()) { return; }
		
		// Check for dispatched cases for accounts
		List<Case> dispatchedCaseList;
		try {
			dispatchedCaseList = [
				SELECT Id, AccountId
				FROM Case
				WHERE AccountId IN :sitesToCheckCasesFor
				  AND IsClosed = false
				  AND Dispatched__c = true
			];
		} catch (Exception e) {}
		
		// Check for dispatched cases found
		if (dispatchedCaseList == null || dispatchedCaseList.isEmpty()) { return; }
		
		// Set error on all accounts without necessary support office information but with dispatched cases
		for (Case c : dispatchedCaseList) {
			siteMap.get(c.AccountId).addError(MESSAGE_DISPATCHED_CASES_FOUND);
		}
	}
}