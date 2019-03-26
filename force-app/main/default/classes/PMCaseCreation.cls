public with sharing class PMCaseCreation {
	
	/**
	 * Gets the list of PM frequencies for creating PMs (based on current month) 
	 */
	public static List<Integer> PMFrequencyList {
		
		get {
			if (PMFrequencyList == null) {
				
				// This will ensure that, regardless of the outcome below, the PM list is only
				// retrieved once and is never NULL after that attempt.
				PMFrequencyList = new List<Integer>();

				try { 
					//Getting the PMFrequencies from Custom Settings
					Map<String,PMCaseSchedule__c> PMCaseSchedule = PMCaseSchedule__c.getAll(); 
				   	String month = '|' + DateTime.now().month().format() + '|';
					for(PMCaseSchedule__c pm :  PMCaseSchedule.Values()){
						if (pm.Creation_Months__c.contains(month)) {
							PMFrequencyList.add(Integer.valueOf(pm.Name));
						}
					}
				} catch (Exception e) {
					System.debug(LoggingLevel.ERROR, 'PMCaseCreation.PMFrequencyList. Failed to retrieve PM frequencies. Details: ' + e.getMessage());
				}
			}
			return PMFrequencyList;
		}
		private set;
	}
	
	/**
	 * Creates PM cases and closes any existing PM cases (system created)
	 */
	public static void CreatePMCases(List<Entitlement> entitlementList) {
		
		// Check for entitlements to process
		if (entitlementList == null || entitlementList.isEmpty()) { return; }
		
		System.debug(LoggingLevel.INFO, 'PMCaseCreation.CreatePMCases. Creating PM cases for ' + entitlementList.size() + ' entitlements.');
		
		List<Id> assetIdList;
		List<Case> pmCaseList;
		
		try {
			// Get case record type map
			Map<String, PMCaseRecordtypes__c> pmRecordTypeMap = PMCaseRecordtypes__c.getAll();
			Map<String, Schema.RecordTypeInfo> caseRecordTypeMap = Case.getSObjectType().getDescribe().getRecordTypeInfosByName();
			
			assetIdList = new List<Id>();
			pmCaseList = new List<Case>();
			
			Case baseCase = (Case)DataGenerator.createSObjectWithDefaultValues('Case');
			baseCase.Priority = 'Low';
			baseCase.System_Created__c = true;
			
			// Iterate over entitlements
			for (Entitlement entl : entitlementList) {
				
				// NOTE This will allow us to succeed or fail on an individual PM creation basis
				try {
					
					// Check for recordType configured
					if (pmRecordTypeMap.containsKey(entl.Asset.Product2.Name)) {
						
						String pmRecordTypeName = pmRecordTypeMap.get(entl.Asset.Product2.Name).PM_Recordtype__c;
						
						if (caseRecordTypeMap.containsKey(pmRecordTypeName)) {
							
							String pmRecordTypeId = caseRecordTypeMap.get(pmRecordTypeName).getRecordTypeId();
							
							// Create PM Case
							Case pmCase = baseCase.clone(false, true);
							pmCase.RecordTypeId = pmRecordTypeId;
							pmCase.AccountId = entl.AccountId;
							pmCase.AssetId = entl.AssetId;
							pmCase.ProductId = entl.Asset.Product2Id;
							pmCase.EntitlementId = entl.Id;
							pmCase.Service_Contract_Name__c = entl.ServiceContractId;
							
							// Add case to map
							assetIdList.add(entl.AssetId);
							pmCaseList.add(pmCase);
							
						} else {
							System.debug(LoggingLevel.ERROR, 'PMCaseCreation.CreatePMCases. No Case Record Type found matching \'' + pmRecordTypeName + '\'.');
						}
						
					} else {
						System.debug(LoggingLevel.ERROR, 'PMCaseCreation.CreatePMCases. No PM Record Type configured for product \'' + entl.Asset.Product2.Name + '\'.');
					}
					
				} catch (Exception e) {
					System.debug(LoggingLevel.ERROR, 'PMCaseCreation.CreatePMCases. Failed to generate PM case for entitlement ' 
							+ entl.Id + '. Details: ' + e.getMessage());
				}
			}
		} catch (Exception e) {
			System.debug(LoggingLevel.ERROR, 'PMCaseCreation.CreatePMCases. Failed to generate PM cases. Details: ' + e.getMessage());
			return;
		}
		
		// Check for PM cases created 
		if (pmCaseList == null || pmCaseList.isEmpty()) { 
			System.debug(LoggingLevel.INFO, 'PMCaseCreation.CreatePMCases. No entitlements found to create PM cases for.');
			return;
		}
		
		System.debug(LoggingLevel.INFO, 'PMCaseCreation.CreatePMCases. Identified ' + pmCaseList.size() + ' PM cases to create.');
		
		// Identify currently open PM cases and close them
		// List<Case> pmCasesToClose = closePMCases(assetIdList, false);
		
		System.Savepoint sp = Database.setSavepoint();
		try {
			
			// Add cases to close
			// pmCaseList.addAll(pmCasesToClose);
			closePMCases(assetIdList, true);
			
			// Initially insert PM cases without dispatched flag (Chad - dispatch trigger only works on update [by design])
			Database.insert(pmCaseList, false);
			
			// Iterate over PM cases and set dispatched flag
			for (Case c : pmCaseList) { c.Dispatched__c = true; }
			
			// Update all affected cases
			Database.update(pmCaseList, false);
			
		} catch (Exception e) {
			Database.rollback(sp);
			System.debug(LoggingLevel.ERROR, 'PMCaseCreation.CreatePMCases. Failed to insert/update PM cases. Details: ' + e.getMessage());
		}
	}
	
	/**
	 * 
	 */
	public static List<Case> closePMCases(List<Id> caseIdList, Boolean updateRecords) {
		
		// Check for case Ids passed
		if (caseIdList == null || caseIdList.isEmpty()) { return new List<Case>(); }
		
		try {
			List<Case> pmCasesToClose = [
				SELECT Id 
				FROM Case 
				WHERE AssetId IN : caseIdList
				  AND System_Created__c = true
				  AND Status NOT IN ('Closed', 'Closed - Completed', 'Closed - Error', 'Closed - Incomplete')
                 //jjackson 1/2014:  added status condition so cases already closed will not be pulled into
                 //the list of cases to be set to Closed - Incomplete.  Wanted to use NOT LIKE Closed%
                 //as the condition but NOT LIKE is not supported in Apex.				  
			];
			
			// Set status for each to closed
			for (Case c : pmCasesToClose) { c.Status = Definitions.CASE_STATUS_INCOMPLETE; }
			
			System.debug(LoggingLevel.INFO, 'PMCaseCreation.closePMCases. Identified ' + pmCasesToClose.size() + ' PM cases to close.');
			
			// Check for update records
			if (updateRecords) { update pmCasesToClose; }
			
			// Return identified/updated records
			return pmCasesToClose;
			
		} catch (Exception e) {
			System.debug(LoggingLevel.ERROR, 'PMCaseCreation.closePMCases. Failed to retrieve PM cases to close. Details: ' + e.getMessage());
		}
		
		return new List<Case>();
	}
}