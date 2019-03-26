/* Filename: BatchPM.cls
 * Purpose:	Batch PM
 * Author:	Etherios for Sonifi
 *
 * Copyright 2013 by Author, all rights reserved
 *
 * History
 *
 * jjackson 1/2015 Add new field PM_Opt_Out__c from Account object to the
 * entitlement query so that accounts opting out of PM visits are excluded
 * from the query and get no PM cases.
 * -----------------------------------------------------------------------------
 * 2013-09-03 Nicholas G. Koopman Jr. Created
*/


global class BatchPM implements Database.Batchable<sObject> {
	
	global Database.Querylocator start(Database.BatchableContext context) {
		
		// Check for PMs to create (based on current month)
		if (PMCaseCreation.PMFrequencyList.isEmpty()) { return null; }
		
		String batchQuery =
				  'SELECT Id, Name, AccountId, Status, Account.PM_Opt_Out__c, AssetId, ServiceContractId, '
				+        'Asset.Name, Asset.Product2Id, Asset.Product2.Name '
				+ 'FROM Entitlement '
				+ 'WHERE PM_Frequency__c IN (' + String.join(PMCaseCreation.PMFrequencyList, ',') + ') '
				+ '  AND Status = \'Active\''
				+ '  AND Account.PM_Opt_Out__c = FALSE';
				
		// Get Entitlement/Asset details
		try { return Database.getQuerylocator(batchQuery); } 
		catch (Exception e) { return null; }
	}
	
	global void execute(Database.BatchableContext context, List<sObject> sObjects) {
		
		// Check for records to process
		if(sObjects == null || sObjects.isEmpty()) { return; }
		
		// Process records
		PMCaseCreation.CreatePMCases((List<Entitlement>)sObjects);

	}
	
	global void finish(Database.BatchableContext context) {
		// No cleanup logic...
	}
}

   
/* To execute this class in the system log:

BatchPM batchProcess = new BatchPM();
Database.executeBatch(batchProcess);

*/