// *********************************************************************************************
// Filename:     CustomAccountLogic
// Version:      0.0.1
// Author:       Etherios
// Date Created: 8/6/2013
// Description:  Provides a centralized location for custom account logic methods.
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class CustomAccountLogic {
	
	/**
	 * Updates the support office on cases related to the passed list of accounts
	 * 
	 * NOTE This WILL result in firing the Case Trigger that watches for updates
	 * to the support office.
	 */
	public static void updateSupportOffice(Map<Id, Account> siteMap) {
		
		// Check for site map
		if (siteMap == null || siteMap.isEmpty()) { return; }
		
		// Get case team map
		Map<Id, List<Case>> caseTeamMap = CustomCaseLogic.getCaseTeamMap(siteMap);
		if (caseTeamMap == null || caseTeamMap.isEmpty()) { return; }
		
		// Update case records
		CustomCaseLogic.updateCaseSupportTeam(caseTeamMap, true, true);
	}
}