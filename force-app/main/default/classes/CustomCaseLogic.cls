// *********************************************************************************************
// Filename:     CustomCaseLogic
// Version:      0.0.1
// Author:       Etherios
// Date Created: 8/6/2013
// Description:  Provides a centralized location for custom case logic methods.
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

global class CustomCaseLogic {
	
	global static final Integer						DEFAULT_CASE_HISTORY_RECORD_LIMIT		= 200;
	global static final Integer						MAX_CASE_HISTORY_RECORD_LIMIT			= 500;
	
	global class CaseInteractionHistory {
    	public Id									objectId								{ get; set; }
    	public String 								objectName 								{ get; set; }
    	public String 								createdBy 								{ get; set; }
    	public DateTime 							createdDate 							{ get; set; }
    	public String								createdDateFormatted					{ get; set; }
    	public String 								header		 							{ get; set; }
    	public String								details									{ get; set; }
    	
    	public void setCreatedDate(DateTime dt) {
    		this.createdDate = dt;
    		this.createdDateFormatted = dt.format('MM/dd/yyyy') + ' at ' + dt.format('hh:mm:ss a');
    	}
	}
	
	public static Map<String, List<String>> MilestoneStopStatusMap {
		
		get {
			if (MilestoneStopStatusMap == null) {
				MilestoneStopStatusMap = new Map<String, List<String>>();
				try {
					for (MilestoneStopStatus__c record : MilestoneStopStatus__c.getAll().values()) {
						String status = record.CaseStatus__c.toLowerCase();
						String milestone = record.Milestone__c.toLowerCase();
						if (MilestoneStopStatusMap.containsKey(status)) {
							MilestoneStopStatusMap.get(status).add(milestone);
						} else {
							MilestoneStopStatusMap.put(status, new List<String> { milestone });
						}
					}
				} catch (Exception e) {}
			}
			return MilestoneStopStatusMap;
		}
		private set;
	}
/*	
	global static Map<Schema.SObjectType, String> ObjectTypeToNameMap;
	
	global static String GetObjectNameByType(Schema.SObjectType objectType) {
		
		try {
			if (ObjectTypeToNameMap == null) {
				ObjectTypeToNameMap = new Map<Schema.SObjectType, String>();
			} else if (ObjectTypeToNameMap.containsKey(objectType)) {
				return ObjectTypeToNameMap.get(objectType);
			}
			
			String objectName = objectType.getDescribe().getLabel();
			ObjectTypeToNameMap.put(objectType, objectName);
			
			return objectName;
			
		} catch (Exception e) {}
		
		return null;
	}
*/	
    /**
     * Maps dispatched cases to their support office (Id field in Map)
     */
    public static void updateCaseSupportTeam(List<Case> caseTeamList, Boolean updateRecords) {
    	
    	Map<Id, List<Case>> caseTeamMap = new Map<Id, List<Case>>();
    	for (Case c : caseTeamList) {
    		if (caseTeamMap.containsKey(c.Id)) {
    			caseTeamMap.get(c.Id).add(c);
    		} else {
    			caseTeamMap.put(c.Support_Office_Formula__c, new List<Case> { c });
    		}
    	}
    	
    	updateCaseSupportTeam(caseTeamMap, false, updateRecords);
    }
    	
    /**
     * Maps dispatched cases to their support office (Id field in Map)
     */
    public static void updateCaseSupportTeam(Map<Id, List<Case>> caseTeamMap, Boolean updateRecords) {
    	updateCaseSupportTeam(caseTeamMap, false, updateRecords);
    }
    	
    /**
     * Maps dispatched cases to their support office (Id field in Map)
     */
    public static void updateCaseSupportTeam(Map<Id, List<Case>> caseTeamMap, Boolean isNewSupportTeam, Boolean updateRecords) {
    	
    	// Check for case team
    	if (caseTeamMap == null || caseTeamMap.isEmpty()) { return; }
    	
    	// Get support office and team members
    	Map<Id, Account> supportOfficeMap = new Map<Id, Account> ([
    		SELECT Id, Name,
    			(SELECT Id, Role__c, User__c, Contact__c, IsContact__c
    			FROM SupportOfficeMembers__r)
    		FROM Account
    		WHERE Id IN :caseTeamMap.keyset()
    	]);
    	
    	// Build map of support team to team members
    	Map<Id, List<SupportOfficeMember__c>> supportTeamMemberMap = new Map<Id, List<SupportOfficeMember__c>>();
    	for (Id officeId : supportOfficeMap.keyset()) {
    		supportTeamMemberMap.put(officeId, supportOfficeMap.get(officeId).SupportOfficeMembers__r);
    	}
    	
    	// Update cases for support team
    	updateCaseSupportTeam(caseTeamMap, supportTeamMemberMap, isNewSupportTeam, updateRecords);
    }
    
    /**
     * Maps dispatched cases to their support office (Id field in Map)
     */
    public static void updateCaseSupportTeam(
    		Map<Id, List<Case>> caseTeamMap, 
    		Map<Id, List<SupportOfficeMember__c>> supportTeamMemberMap, 
    		Boolean updateRecords) {
    	updateCaseSupportTeam(caseTeamMap, supportTeamMemberMap, false, updateRecords);
    }
    	
    /**
     * Maps dispatched cases to their support office (Id field in Map)
     */
    public static void updateCaseSupportTeam(
    		Map<Id, List<Case>> caseTeamMap, 
    		Map<Id, List<SupportOfficeMember__c>> supportTeamMemberMap, 
    		Boolean isNewSupportTeam, 
    		Boolean updateRecords) {
    	
    	// Check for case and support team
    	if (caseTeamMap == null || caseTeamMap.isEmpty()) { return; }
    	if (supportTeamMemberMap == null || supportTeamMemberMap.isEmpty()) { return; }
    	
    	System.debug('CustomCaseLogic.updateCaseSupportTeam. Updating Case Support Teams.');
    	
    	// Get base support team member roles if we are resetting the entire team
    	List<AcountTeamRoles__c> baseTeamRoles;
    	if (isNewSupportTeam) { baseTeamRoles = AcountTeamRoles__c.getAll().values(); }
    	
    	// Get case field label map for reverse field name lookup (by label)
    	Map<String, String> caseFieldLabelMap = Utilities.getLabelToFieldMap('Case');
    	
    	// Iterate over support offices
    	List<Case> updatedCases = new List<Case>();
    	for (Id officeId : caseTeamMap.keyset()) {
    		
    		System.debug('CustomCaseLogic.updateCaseSupportTeam. Support Team: ' + officeId);
    		
    		List<SupportOfficeMember__c> teamMembers = supportTeamMemberMap.get(officeId);
    		List<Case> cases = caseTeamMap.get(officeId);
			updatedCases.addAll(cases);
    		
    		// Iterate over each case in the list
    		// and assign support team members to same-named fields
    		for (Case c : cases) {
    			
    			System.debug('CustomCaseLogic.updateCaseSupportTeam. Case: ' + c.Id);
    			
    			// Assign support office
    			c.Support_Office__c = officeId;
    			
    			// If new team, clear all previous team member values
    			if (isNewSupportTeam) {
    				for (AcountTeamRoles__c role : baseTeamRoles) {
	    				try {
		    				String fieldName = caseFieldLabelMap.get(role.Name);
		    				if (fieldName != null) { c.put(fieldName, null); }
	    				} catch (Exception e) {}
    				}
    			}
    			
    			// Iterate over support team members
    			for (SupportOfficeMember__c member : teamMembers) {
    				
    				// Primary Engineer is special in that it gets assigned as the owner
    				if (member.Role__c == Definitions.SUPPORTMEMBER_PRIMARY_ENGINEER) {
    					System.debug('CustomCaseLogic.updateCaseSupportTeam. Setting ' + Definitions.SUPPORTMEMBER_PRIMARY_ENGINEER + ' to: ' + member.User__c);
    					c.OwnerId = member.User__c;
    				}
    				
    				try {
	    				// Get member id based on type
	    				Id memberId = member.IsContact__c ? member.Contact__c : member.User__c;
	    				
	    				// Get case field name 
	    				String fieldName = caseFieldLabelMap.get(member.Role__c);
	    				
	    				// Assign member to case field
	    				if (fieldName != null) { 
	    					System.debug('CustomCaseLogic.updateCaseSupportTeam. Setting ' + fieldName + ' to: ' + memberId);
	    					c.put(fieldName, memberId); 
	    				}
    					
    				} catch (Exception e) {}
    			}
    		}
    	}
    	
    	// Check for update flag
    	if (!updateRecords) { return; }
    	
    	System.debug('CustomCaseLogic.updateCaseSupportTeam. Updating ' + updatedCases.size() + ' cases.');
    	update updatedCases;
    }
    
    /**
     * Converts a list of accounts to support office (account) Ids and passes them into 
     * the main getCaseTeamMap() method for creating a map of support offices to cases
     */
    public static Map<Id, List<Case>> getCaseTeamMap(Map<Id, Account> accountMap) {
    	
    	// Check for accounts
    	if (accountMap == null || accountMap.isEmpty()) { return null; }
    	
    	// Build list of account ids
    	List<Id> accountIds = new List<Id>();
    	for (Account a : accountMap.values()) { accountIds.add(a.Id); }
    	
    	// Get support office recordtype Id for comparison 
    	Id supportOfficeRecordTypeId = Utilities.RecordTypeNameToId('Account', Definitions.RECORDTYPE_SupportOffice);
    	
    	// Check for list of support offices
    	// NOTE This assumes the same record type for ALL accounts in list.
    	if (accountMap.values()[0].RecordTypeId == supportOfficeRecordTypeId) {
			return getCaseTeamMap(accountIds);
    	}
    	
		// Get cases for site account Ids
		List<Case> caseList;
		try {
			caseList = [
				SELECT Id, AccountId
				FROM Case
				WHERE AccountId IN :accountIds 
				  AND IsClosed = false
				  AND Dispatched__c = true
			];
		} catch (Exception e) {}
		
		// Check for cases to process
		if (caseList == null) { return null; }
		
		// Map cases to support offices using the site account's support office
		Map<Id, List<Case>> caseTeamMap = new Map<Id, List<Case>>();
		for (Case c : caseList) {
			Account caseAccount = accountMap.get(c.AccountId);
			if (caseTeamMap.containsKey(caseAccount.Support_Office__c)) {
				caseTeamMap.get(caseAccount.Support_Office__c).add(c);
			} else {
				caseTeamMap.put(caseAccount.Support_Office__c, new List<Case> { c });
			}
		}
    	
    	return caseTeamMap;
    }
    
    /**
     * Builds and returns a map of support offices to cases
     */
    public static Map<Id, List<Case>> getCaseTeamMap(List<Id> supportOfficeIds) {
    	
		// Get cases for support office Ids
		List<Case> caseList;
		try {
			caseList = [
				SELECT Id, OwnerId, Support_Office__c
				FROM Case
				WHERE Support_Office__c IN :supportOfficeIds 
				  AND IsClosed = false
				  AND Dispatched__c = true
			];
		} catch (Exception e) {}
		
		// Check for cases to process
		if (caseList == null) { return null; }
		
		// Map cases to support offices
		Map<Id, List<Case>> caseTeamMap = new Map<Id, List<Case>>();
		for (Case c : caseList) {
			if (caseTeamMap.containsKey(c.Support_Office__c)) {
				caseTeamMap.get(c.Support_Office__c).add(c);
			} else {
				caseTeamMap.put(c.Support_Office__c, new List<Case> { c });
			}
		}
    	
    	return caseTeamMap;
    }
    
    /**
     * 
     */
    public static void setCaseEntitlementDetails(Case theCase, Id entitlementId) {
    	
    	// Check for case provided
    	if (theCase == null) { throw new Exceptions.AppException('No case provided.'); }
    	
    	// Check for entitlement id passed
    	if (entitlementId == null) { throw new Exceptions.AppException('No entitlement Id provided.'); }
    	
    	// Get details from entitlement
    	// NOTE Allow errors to propagate here to let the caller know nothing happened to the case
		Entitlement ent = [
			SELECT Id, Name, ServiceContractId, AccountId, AssetId, 
				   Asset.Name, Asset.Product2Id, Asset.Contract_Type__c
			FROM Entitlement
			WHERE Id = :entitlementId
			LIMIT 1
		];
		
		// Check for entitlement found
		if (ent != null) {
			
			theCase.EntitlementId = entitlementId;
			theCase.Service_Contract_Name__c = ent.ServiceContractId;
			theCase.AssetId = ent.AssetId;
			
			if (ent.AssetId != null) {
				
				if (CaseProductTypes__c.getAll().containsKey(ent.Asset.Contract_Type__c)) {
					theCase.Case_Product_Type__c = CaseProductTypes__c.getAll().get(ent.Asset.Contract_Type__c).Product_Inventory__c;
				}
				
				if (ent.Asset.Product2Id != null) {
					theCase.ProductId = ent.Asset.Product2Id;
				}
			}
		}
    }
    
    /**
     * 
     */
    public static void setCaseAssetDetails(Case theCase, Id assetId) {
		
    	// Check for case provided
    	if (theCase == null) { throw new Exceptions.AppException('No case provided.'); }
    	
    	// Check for asset id passed
    	if (assetId == null) { throw new Exceptions.AppException('No asset Id provided.'); }
    	
    	// Get details from asset
    	// NOTE Allow errors to propagate here to let the caller know nothing happened to the case
		Asset ass = [
			SELECT Id, Name, AccountId, Service_Contract__c, Product2Id
			FROM Asset
			WHERE Id = :assetId
			LIMIT 1
		];
		
		// Check for asset found
		if (ass != null) {
			
			theCase.AssetId = assetId;
			theCase.Service_Contract_Name__c = ass.Service_Contract__c;
			
			if (CaseProductTypes__c.getAll().containsKey(ass.Name)) {
				theCase.Case_Product_Type__c = CaseProductTypes__c.getAll().get(ass.Name).Product_Inventory__c;
			}
			
			if (ass.Product2Id != null) {
				theCase.ProductId = ass.Product2Id;
			}
		}
    }
    
    /**
     * Creats a new case from the starter case and record type provided.
     * If neither are provided, creates an empty case with default values.
     * Inserts and returns the created case Id.
     */
/*
	public static Id createCase(Case caseDetails, String caseRecordType) {
    	
    	Id recordTypeId;
    		
		// Check for record type Id
    	if (caseRecordType != null) {
    		
	    	try { 
	    		// Attempt to convert variable to Id
	    		recordTypeId = Id.valueOf(caseRecordType);
	    	}
	    	catch (Exception e) {
	    		// Get record type Id from Name
		    	recordTypeId = Utilities.RecordTypeNameToId('Case', caseRecordType);
	    	}
    	}
	    	
	    try {
	    	Case newCase = (Case)DataGenerator.createSObjectWithDefaultValues('Case', recordTypeId);
	    	
	    	if (caseDetails != null) {
		    	List<String> caseFields = Utilities.getSObjectFields('Case');
		    	for (String fieldName : caseFields) {
		    		try {
			    		object fieldValue = caseDetails.get(fieldName);
			    		if (fieldValue != null) { newCase.put(fieldName, fieldValue); }
		    		} catch (Exception e) {}
		    	}
		    	
		    	// Check for entitlement Id passed
		    	if (caseDetails.EntitlementId != null) {
		    		
		    		try { setCaseEntitlementDetails(newCase, caseDetails.EntitlementId); }
		    		catch (Exception e) {}
		    		
		    	} else if (caseDetails.AssetId != null) {
		    		
		    		try { setCaseAssetDetails(newCase, caseDetails.AssetId); }
		    		catch (Exception e) {}
		    		
		    	}
	    	}
	    	
	    	// Insert new case and return resulting Id
	    	insert newCase;
	    	return newCase.id;
	    	
    	} catch (Exception e) {
    		throw new Exceptions.AppException(e.getMessage());
    	}
    	
    	return null;
    }
*/


    private static boolean FoundServiceContractAndStatus(Case theCase, String serviceContractName)
    {
    	Boolean retValue = false;
    	
    	// First get the custom setting based on the case-ServiceContractName

    	CaseServiceContractStatus__c cscs = CaseServiceContractStatus__c.getinstance(serviceContractName);
    	string delimStatuses;
    	if (cscs != null)
    	{
    		delimStatuses = cscs.Delimited_List_Of_Status__c;
    	}
    	else
    	{
    		delimStatuses = '';
    	}

		//system.debug('delimStatuses: <'+ delimStatuses + '> The Case Status - <' + theCase.Status + '>');
    	//now compare the current case status with the value in delimStatus string
    	//  if it is found then set to false
    	// AM Dispatch Approved
    	if (delimStatuses.contains(theCase.Status))
    	{
    		retValue = true;
    	}
    	
    	return retValue;
    } 

    private static boolean FoundServiceContract(String serviceContractName)
    {
    	Boolean retValue = false;
    	
    	if (serviceContractName <> null)
    	{
	    	CaseServiceContractStatus__c cscs = CaseServiceContractStatus__c.getinstance(serviceContractName);
	    	if (cscs != null)
	    	{
	    		retValue = true;
	    	}
    	}
    	
    	return retValue;
    } 
    
	public static Map<Id,String> casesServiceContracts(List<Case> caseList) {
		List<Case> lcaseList; //local variable used to put query results in
		try {
			lcaseList = [
				SELECT Id, service_contract_name__r.name
				FROM Case
				WHERE Id IN :caseList 
			];
		} catch (Exception e) {}
		
		// Check for cases to process
		if (lcaseList == null) { return null; }
		
		// Map cases to Service Contract Names
		Map<Id,String> caseServiceContractMap = new Map<Id,String>();
		for (Case c : lcaseList) {
				caseServiceContractMap.put(c.Id, c.service_contract_name__r.name);
		}
    	
    	return caseServiceContractMap;
		
	}   
   
    /**
     * Affects timestamps and other status-related fields when the case status changes
     * NOTE Primarily called by the StandardCaseTrigger
     */
    public static void processStatusChange(Map<Id, List<Case>> accountCaseMap, Map<Id,String> caseServiceContractMap) {
    	// Check for incoming data
    	if (accountCaseMap == null || accountCaseMap.isEmpty()) { return; }
    	
        DateTime completionDate = System.now();
        List<String> milestoneNames = new List<String>();
        List<Id> caseIdList = new List<Id>();
        Map<Id, Case> caseMilestoneStopMap = new Map<Id, Case>();
        
        // Build map of clock start statuses
        Map<String, Map<String, CaseStatustoTime__c>> clockResetTimeMap = new Map<String, Map<String, CaseStatustoTime__c>>();
    	try {
	        for (CaseStatustoTime__c clockRule : CaseStatustoTime__c.getAll().values()) {
	        	String statusKey = clockRule.Status__c.toUpperCase();
	        	if (clockResetTimeMap.containsKey(statusKey)) {
	        		clockResetTimeMap.get(statusKey).put(clockRule.Status_Change_Day__c.toUpperCase(), clockRule);
	        	} else {
	        		clockResetTimeMap.put(statusKey, new Map<String, CaseStatustoTime__c> { clockRule.Status_Change_Day__c.toUpperCase() => clockRule } );
	        	}
	        }
    	} catch (Exception e) {}
        
		// Create map of weekdays for quick access
		Map<String, Integer> weekdayMap = new Map<String, Integer>();
		for (Definitions.WEEKDAY wkday : Definitions.WEEKDAY.values()) {
			weekdayMap.put(wkDay.name(), wkDay.ordinal() + 1);
		}
		
        Integer orgUtcOffset = 0;
        try { 
        	orgUtcOffset = Integer.valueOf(AppConfig__c.getValues('Global').CompanyUTCOffset__c * 3600); 
        } catch (Exception e) {
        	System.debug(LoggingLevel.ERROR, 'No Company UTC Offset set in the Global record in the AppConfig custom setting.');
        }
        
		String todayKey = DateTime.now().format('EEEE').toUpperCase();
		Integer todayNum = weekdayMap.get(todayKey);
		
    	for (Id accountId : accountCaseMap.keyset()) {
    		
    		for (Case c : accountCaseMap.get(accountId)) {
    			
    			try{
	    			// Set status timestamps
	    			c.Local_Time_At_Status_Change__c = DateTime.now();
	    			c.Day_At_Status_Change__c = c.Local_Time_At_Status_Change__c.format('EEEE');
	    			
	    			system.debug('Status before check: <' + c.Status + '> --- ServiceContract: <' + caseServiceContractMap.get(c.Id) + '>');
	    			
	    			if (!FoundServiceContract(caseServiceContractMap.get(c.Id)) || FoundServiceContractAndStatus(c, caseServiceContractMap.get(c.Id)) )
	    			{
	    				
		    			// Check for configured clock start status
		    			String statusKey = c.Status.toUpperCase();
		    			if (clockResetTimeMap.containsKey(statusKey) && clockResetTimeMap.get(statusKey).containsKey(todayKey)) {

		    				system.debug('In if for clock resettimemap');
		    				CaseStatustoTime__c clockRule = clockResetTimeMap.get(statusKey).get(todayKey);
		    				
		    				// Get restart day
		    				String restartDayKey = clockRule.Day_to_Restart_Clock__c.toUpperCase();
		    				Integer restartDayNum = weekdayMap.get(restartDayKey);
		    				
		    				// Calculate days offset
		    				Integer daysOffset = restartDayNum - todayNum;
		    				if (daysOffset < 0) { daysOffset = 7 + daysOffset; }
		    				
		    				// Calculate seconds offset (within the same day)
		    				// NOTE Sites that do not support DST will be an hour LATER in DST months
		    				Integer siteDstOffset = (Definitions.IS_DST && !c.Observes_DST__c) ? Definitions.DST_OFFSET : 0;
		    				Integer secondsOffset ;
		    				if(c.UTC_Offset__c != null){
		    					secondsOffset = (c.UTC_Offset__c.intValue() + siteDstOffset) - orgUtcOffset;
		    				}else{
		    					secondsOffset = orgUtcOffset - ( siteDstOffset);
		    				}
		    				
		    				// Find restart day from today
		    				String amPm = clockRule.Time_to_Restart_Clock__c < 12 ? 'AM' : 'PM';
		    				c.Time_to_Restart_Clock__c = DateTime.parse(DateTime.now().addDays(daysOffset).format('M/d/yyyy') + ' ' + clockRule.Time_to_Restart_Clock__c.intValue() + ':00 ' + amPm).addSeconds(secondsOffset);
		    			}
		    			
						// Check milestone statuses
						if (c.SlaExitDate == null && c.SlaStartDate <= completionDate) {
							
							// Check for closed or status in configured stop statuses 
							if (c.IsClosed || MilestoneStopStatusMap.containsKey(c.Status.toLowerCase())) {
								
								// Add case to stop list
								caseMilestoneStopMap.put(c.Id, c);
								
							}
							
						}

	    			}// my end if
    			} catch(Exception e) {}
    		}
    	}
		
		// Check for milestones to update
		if (!caseMilestoneStopMap.isEmpty()) { stopCaseMilestones(caseMilestoneStopMap); }
    }
    
    /**
     * 
     */
    private static void stopCaseMilestones(Map<Id, Case> caseMap) {
    	
    	DateTime completionDate = DateTime.now();
    	
    	List<CaseMilestone> milestonesToUpdate = new List<CaseMilestone>();
    	
    	for (CaseMilestone milestone : [
    									SELECT Id, CaseId, MilestoneType.Name
    									FROM CaseMilestone
    									WHERE CaseId IN : caseMap.keyset()
    									  AND CompletionDate = null]) {
			
	    	try {
				Case c = caseMap.get(milestone.CaseId); 
				if (c.IsClosed) { 
					milestone.CompletionDate = completionDate;
					milestonesToUpdate.add(milestone);
				} else {
					String status = c.Status.toLowerCase();
					if (MilestoneStopStatusMap.containsKey(status)) {
						String milestoneName = milestone.MilestoneType.Name.toLowerCase();
						for (String record : MilestoneStopStatusMap.get(c.Status.toLowerCase())) {
							if (record == milestoneName) {
								milestone.CompletionDate = completionDate;
								milestonesToUpdate.add(milestone);
								break;
							}
						}
					}
				}
	    	} catch (Exception e) {}
	  	}
    	
    	// Check for milestones to update
    	if (!milestonesToUpdate.isEmpty()) { upsert milestonesToUpdate; }
    }
    
    /**
     * Read entire case interaction history (Comments, Activities, etc.)
     */
    global static List<CaseInteractionHistory> GetCaseInteractionHistory(Id caseId) {
    	
    	// Check for case Id passed
    	if (caseId == null) { return null; }
    	
    	return GetCaseInteractionHistory(new List<Id> { caseId }, DEFAULT_CASE_HISTORY_RECORD_LIMIT);
    }
    
    /**
     * Read entire case interaction history (Comments, Activities, etc.)
     */
    global static List<CaseInteractionHistory> GetCaseInteractionHistory(List<Id> caseIdList) {
    	
    	return GetCaseInteractionHistory(caseIdList, DEFAULT_CASE_HISTORY_RECORD_LIMIT);
    }
    
    /**
     * Read entire case interaction history (Comments, Activities, etc.)
     */
    global static List<CaseInteractionHistory> GetCaseInteractionHistory(List<Id> caseIdList, Integer recordsToGet) {
    	
    	// Check for case Ids passed
    	if (caseIdList == null || caseIdList.isEmpty()) { return null; }
    	
    	// Check for record limit
    	if (recordsToGet == null) { recordsToGet = DEFAULT_CASE_HISTORY_RECORD_LIMIT; }
    	else if (recordsToGet < 1) { return null; }
    	else if (recordsToGet > MAX_CASE_HISTORY_RECORD_LIMIT) { recordsToGet = MAX_CASE_HISTORY_RECORD_LIMIT; }
    	
    	// Get case interaction history items
    	List<CaseInteractionHistory> historyList = new List<CaseInteractionHistory>();
    	try {
	    	
	    	historyList.addAll(GetFieldServiceDigest(caseIdList, recordsToGet));
	    	historyList.addAll(GetCaseTasks(caseIdList, recordsToGet));
	    	historyList.addAll(GetCaseComments(caseIdList, recordsToGet));
	    	historyList.addAll(GetCaseEvents(caseIdList, recordsToGet));
	    	// historyList.addAll(GetCaseHistory(caseIdList, recordsToGet));
	    	
	    	// Check for closed case records
	    	for (CaseHistory record : [
										SELECT CaseId, NewValue, CreatedBy.Name, CreatedDate 
										FROM CaseHistory 
										WHERE Field = 'Closed_Case_Summary__c'
  										AND CaseId IN : caseIdList]) {
	    		
	    		// Check for value
	    		// NOTE The NewValue field CANNOT be filtered in the SOQL query so we must do it here.
	    		if (record.NewValue != null) {
	    			
	    			// Create history record
					CaseInteractionHistory history = new CaseInteractionHistory();
					history.objectId = record.CaseId;
					history.objectName = 'Close Summary';
					history.createdBy = record.CreatedBy.Name;
					history.setCreatedDate(record.CreatedDate);
					history.details = (String)record.NewValue;
					
					// Add to history list
					historyList.add(history);
	    		}
	    	}
	    	
	    	// Sort history list
	    	SortHistoryList(historyList);
	    	
    	} catch (Exception e) {
    		System.debug('CustomCaseLogic.GetCaseInteractionHistory. Failed to read interaction history for case. Details: ' + e.getMessage());
    	}
    	
    	return historyList;
    }
    
    /**
     * Read case comments
     */
    global static List<CaseInteractionHistory> GetCaseComments(Id caseId) {
    	
    	// Check for case Id passed
    	if (caseId == null) { return null; }
    	
    	return GetCaseComments(new List<Id> { caseId });
    }
    
    /**
     * Read case comments
     */
    global static List<CaseInteractionHistory> GetCaseComments(List<Id> caseIdList) {
    	
    	return GetCaseComments(caseIdList, DEFAULT_CASE_HISTORY_RECORD_LIMIT);
    }
    
    /**
     * Read case comments
     */
    global static List<CaseInteractionHistory> GetCaseComments(List<Id> caseIdList, Integer recordsToGet) {
    		
    	// Check for case Ids passed
    	if (caseIdList == null || caseIdList.isEmpty()) { return null; }
    	
    	// Check for record limit
    	if (recordsToGet == null) { recordsToGet = DEFAULT_CASE_HISTORY_RECORD_LIMIT; }
    	else if (recordsToGet < 1) { return null; }
    	else if (recordsToGet > MAX_CASE_HISTORY_RECORD_LIMIT) { recordsToGet = MAX_CASE_HISTORY_RECORD_LIMIT; }
    	
    	List<CaseInteractionHistory> historyList = new List<caseInteractionHistory>();
    	
    	try{
    		// Get object name
    		String objectName = SObjectType.CaseComment.getLabel();
    		
    		System.debug('CustomCaseLogic.GetCaseComments. Getting comments for case Ids: ' + caseIdList);
    		
    		for (CaseComment record : [
    									SELECT Id, ParentId, CommentBody, CreatedBy.Name, CreatedDate, IsPublished 
    									FROM CaseComment 
    									WHERE ParentId IN : caseIdList
    									  AND CommentBody != null
    									LIMIT 100
    								   ]) {
					
				System.debug('CustomCaseLogic.GetCaseComments. Comment for : ' + record.ParentId + ' - ' + record.CommentBody);
				CaseInteractionHistory history = new CaseInteractionHistory();
				history.objectId = record.ParentId;
				history.objectName = objectName;
				history.createdBy = record.CreatedBy.Name;
				history.setCreatedDate(record.CreatedDate);
				history.details = (record.IsPublished ? '' : '***** For Internal Use Only ***** \n') + record.CommentBody;
				
    			historyList.add(history);
			}
			
		} catch (Exception e) {
			System.debug('CustomCaseLogic.GetCaseComments. Failed to read comments for case. Details: ' + e.getMessage());
		}
		
		return historyList;    										
    }
	
    /**
     * Read case tasks (open and closed)
     */
    global static List<CaseInteractionHistory> GetCaseTasks(Id caseId) {
    	
    	// Check for case Id passed
    	if (caseId == null) { return null; }
    	
    	return GetCaseTasks(new List<Id> { caseId });
    }
	
    /**
     * Read case tasks (open and closed)
     */
    global static List<CaseInteractionHistory> GetCaseTasks(List<Id> caseIdList) {
    	
    	return GetCaseTasks(caseIdList, DEFAULT_CASE_HISTORY_RECORD_LIMIT);
    }
    
    /**
     * Read case tasks (open and closed)
     */
    global static List<CaseInteractionHistory> GetCaseTasks(List<Id> caseIdList, Integer recordsToGet) {
    	
    	// Check for case Ids passed
    	if (caseIdList == null || caseIdList.isEmpty()) { return null; }
    	
    	// Check for record limit
    	if (recordsToGet == null) { recordsToGet = DEFAULT_CASE_HISTORY_RECORD_LIMIT; }
    	else if (recordsToGet < 1) { return null; }
    	else if (recordsToGet > MAX_CASE_HISTORY_RECORD_LIMIT) { recordsToGet = MAX_CASE_HISTORY_RECORD_LIMIT; }
    	
    	List<CaseInteractionHistory> historyList = new List<CaseInteractionHistory>();
    	
    	try {
    		
    		// Get object name
    		String objectName = SObjectType.Task.getLabel();
    		
    		// Get the case record Tasks
    		for (Task record : [
    						SELECT Id, WhatId, Description, Subject,Task_Origin__c, CreatedBy.Name, CreatedDate,
						    	Case_Product_Type__c, Issue_Type__c, Issue_Sub_Type__c, Issue_Details__c
							FROM Task
							WHERE WhatId IN : caseIdList
							ORDER BY ActivityDate ASC, LastModifiedDate DESC 
							LIMIT 100
						  ]) {
    			
    			CaseInteractionHistory history = new CaseInteractionHistory();
    			history.objectId = record.WhatId;
    			history.objectName = objectName;
    			history.createdBy = record.CreatedBy.Name;
    			history.setCreatedDate(record.CreatedDate);
    			
	    		String header = 'Product Type: ' + (record.Case_Product_Type__c == null ? 'n/a' : record.Case_Product_Type__c);
	    		header += ' / Issue Type: ' + (record.Issue_Type__c == null ? 'n/a' : record.Issue_Type__c);
	    		header += ' / Issue Sub-Type: ' + (record.Issue_Sub_Type__c == null ? 'n/a' : record.Issue_Sub_Type__c);
	    		if (record.Issue_Details__c != null) { header += ' / Issue Details: ' + record.Issue_Details__c; }
	    		header += '\nSubject: ' + (record.Subject == null ? 'n/a' : record.Subject);
	    		if (record.Task_Origin__c != null) { header += ' / Origin: ' + record.Task_Origin__c; }
    			history.header = header;
    			history.details = record.Description;
    			
    			historyList.add(history);
    		}
							
    	} catch (Exception e) {
			System.debug('CustomCaseLogic.GetCaseTasks. Failed to read open activities for case. Details: ' + e.getMessage());
    	}
    										
		return historyList;    										
    }
    
    /**
     * Read case events (open and closed)
     */
    global static List<CaseInteractionHistory> GetCaseEvents(Id caseId) {
    	
    	// Check for case Id passed
    	if (caseId == null) { return null; }
    	
    	return GetCaseEvents(new List<Id> { caseId });
    }
    
    /**
     * Read case events (open and closed)
     */
    global static List<CaseInteractionHistory> GetCaseEvents(List<Id> caseIdList) {
    	
    	return GetCaseEvents(caseIdList, DEFAULT_CASE_HISTORY_RECORD_LIMIT);
    }
    
    /**
     * Read case events (open and closed)
     */
    global static List<CaseInteractionHistory> GetCaseEvents(List<Id> caseIdList, Integer recordsToGet) {
    	
    	// Check for case Ids passed
    	if (caseIdList == null || caseIdList.isEmpty()) { return null; }
    	
    	// Check for record limit
    	if (recordsToGet == null) { recordsToGet = DEFAULT_CASE_HISTORY_RECORD_LIMIT; }
    	else if (recordsToGet < 1) { return null; }
    	else if (recordsToGet > MAX_CASE_HISTORY_RECORD_LIMIT) { recordsToGet = MAX_CASE_HISTORY_RECORD_LIMIT; }
    	
    	List<CaseInteractionHistory> historyList = new List<CaseInteractionHistory>();
    	
    	try {
    		
    		// Get object name
    		String objectName = SObjectType.Event.getLabel();
    		
    		// Get the case record Events
    		for (Event record : [
    						SELECT Id, WhatId, Description, Subject,Task_Origin__c, CreatedBy.Name, CreatedDate,
						    	Case_Product_Type__c, Issue_Type__c, Issue_Sub_Type__c, Issue_Details__c
							FROM Event
							WHERE WhatId IN : caseIdList
							ORDER BY ActivityDate ASC, LastModifiedDate DESC 
							LIMIT 100
						  ]) {
    			
    			CaseInteractionHistory history = new CaseInteractionHistory();
    			history.objectId = record.WhatId;
    			history.objectName = objectName;
    			history.createdBy = record.CreatedBy.Name;
    			history.setCreatedDate(record.CreatedDate);
    			
    			if (record.Subject != null) {
    				history.header = 'Subject: ' + record.Subject 
    					+ (record.Task_Origin__c == null ? '' : '\nOrigin: ' + record.Task_Origin__c);
    			} else if (record.Task_Origin__c != null) {
    				history.header = '\nOrigin: ' + record.Task_Origin__c;
    			}
    			history.details = record.Description;
    			historyList.add(history);
    		}
							
    	} catch (Exception e) {
			System.debug('CustomCaseLogic.GetCaseEvents. Failed to read open activities for case. Details: ' + e.getMessage());
    	}
    										
		return historyList;    										
    }
    
    /**
     * Read field service digest for case
     */
    global static List<CaseInteractionHistory> GetFieldServiceDigest(Id caseId) {
    	
    	// Check for case Id passed
    	if (caseId == null) { return null; }
    	
    	return GetFieldServiceDigest(new List<Id> { caseId });
    	
    }
    
    /**
     * Read field service digest for case
     */
    global static List<CaseInteractionHistory> GetFieldServiceDigest(List<Id> caseIdList) {
    	
    	return GetFieldServiceDigest(caseIdList, DEFAULT_CASE_HISTORY_RECORD_LIMIT);
    }
    
    /**
     * Read field service digest for case
     */
    global static List<CaseInteractionHistory> GetFieldServiceDigest(List<Id> caseIdList, Integer recordsToGet) {
    	
    	// Check for case Id passed
    	if (caseIdList == null || caseIdList.isEmpty()) { return null; }
    	
    	// Check for record limit
    	if (recordsToGet == null) { recordsToGet = DEFAULT_CASE_HISTORY_RECORD_LIMIT; }
    	else if (recordsToGet < 1) { return null; }
    	else if (recordsToGet > MAX_CASE_HISTORY_RECORD_LIMIT) { recordsToGet = MAX_CASE_HISTORY_RECORD_LIMIT; }
    	
    	List<CaseInteractionHistory> historyList = new List<CaseInteractionHistory>();
    	
    	try {
    		
    		// Get object name
    		String objectName = SObjectType.Field_Service_Digest__c.getLabel();
    		
    		// Get field service digests
    		for (Field_Service_Digest__c record : [
    												SELECT Id, Case__c, Name, CheckIn_Time__c, CheckOut_Time__c, Field_Notes__c, 
    														CreatedBy.Name, CreatedDate 
    												FROM Field_Service_Digest__c
    												WHERE Case__c IN : caseIdList
    												LIMIT 100
    											  ]) {
    			
    			CaseInteractionHistory history = new CaseInteractionHistory();
    			history.objectId = record.Case__c;
    			history.objectName = objectName;
    			history.createdBy = record.CreatedBy.Name;
    			history.setCreatedDate(record.CreatedDate);
    			String header = 'Check-In Time: ' + (record.CheckIn_Time__c == null ? 'n/a' : record.CheckIn_Time__c.format());
    			header += '\nCheck-Out Time: ' + (record.CheckOut_Time__c == null ? 'n/a' : record.CheckOut_Time__c.format());
    			history.header = header;
    			history.details = record.Field_Notes__c; 
    			historyList.add(history);
  			}
  			
    	} catch (Exception e) {
    		System.debug('CustomCaseLogic.GetCaseEvents. Failed to read field service digest for case. Details: ' + e.getMessage());
    	}
    										
		return historyList;    										
    }
    
    /**
     * Read case field change history
     */
    global static List<CaseInteractionHistory> GetCaseHistory(Id caseId) {
    	
    	// Check for case Id passed
    	if (caseId == null) { return null; }
    	
    	return GetCaseHistory(new List<Id> { caseId });
    }
    
    /**
     * Read case field change history
     */
    global static List<CaseInteractionHistory> GetCaseHistory(List<Id> caseIdList) {
    	
    	return GetCaseHistory(caseIdList, DEFAULT_CASE_HISTORY_RECORD_LIMIT);
    }
    
    /**
     * Read case field change history
     */
    global static List<CaseInteractionHistory> GetCaseHistory(List<Id> caseIdList, Integer recordsToGet) {
    	
    	// Check for case Ids passed
    	if (caseIdList == null || caseIdList.isEmpty()) { return null; }
    	
    	// Check for record limit
    	if (recordsToGet == null) { recordsToGet = DEFAULT_CASE_HISTORY_RECORD_LIMIT; }
    	else if (recordsToGet < 1) { return null; }
    	else if (recordsToGet > MAX_CASE_HISTORY_RECORD_LIMIT) { recordsToGet = MAX_CASE_HISTORY_RECORD_LIMIT; }
    	
    	List<CaseInteractionHistory> historyList = new List<CaseInteractionHistory>();
    	
    	try {
    		
    		Map<String, String> caseFields = Utilities.getFieldNameToLabelMap('Case');
			
    		for (CaseHistory record : [
    									SELECT Id, CaseId, Field, NewValue, OldValue, CreatedBy.Name, CreatedDate 
    									FROM CaseHistory 
    									WHERE CaseId IN : caseIdList
    									LIMIT 100
    								  ]) {
				
				System.debug('CustomCaseLogic.GetCaseHistory. Processing field \'' + record.Field + '\'.');
				
				// Check for Id fields
				Schema.SObjectType idType;
				try {
					if (record.NewValue != null) { 
						idType = ((Id)record.NewValue).getSObjectType();
						System.debug('CustomCaseLogic.GetCaseHistory. Field \'' + record.Field + '\' value \'' + record.NewValue + '\' IS an Id.');
					} else if (record.OldValue != null) {
						idType = ((Id)record.OldValue).getSObjectType();
						System.debug('CustomCaseLogic.GetCaseHistory. Field \'' + record.Field + '\' value \'' + record.OldValue + '\' IS an Id.');
					}
				} catch (Exception e) {
					System.debug('CustomCaseLogic.GetCaseHistory. Field \'' + record.Field + '\' value IS NOT an Id.');
				}
				
				// Only process if NOT an Id field
				if (idType == null) {
					
					System.debug('CustomCaseLogic.GetCaseHistory. Checking for field \'' + record.Field + '\' in the list of case fields.');
					
					Boolean isIdField = false;
					String fieldName;
					String header;
					if (caseFields.containsKey(record.Field)) {
						fieldName = caseFields.get(record.Field);
						System.debug('CustomCaseLogic.GetCaseHistory. Field \'' + record.Field + '\' found in list of case fields with label \'' + fieldName + '\'.');
					} else if (caseFields.containsKey(record.Field + 'Id')) {
						isIdField = true;
						fieldName = record.Field;
						System.debug('CustomCaseLogic.GetCaseHistory. Field \'' + record.Field + '\' found in list of case fields with label \'' + fieldName + '\'.');
					} else {
						String testField = record.Field.toUpperCase();
						if (testField == 'CREATED') {
							header = 'Created Case.';
						} else {
							System.debug('CustomCaseLogic.GetCaseHistory. Could not locate the field \'' + record.Field + '\' or \'' + record.Field + 'Id\' in the list of Case fields');
						}
					}
					
					if (fieldName != null || header != null) {
						
						System.debug('CustomCaseLogic.GetCaseHistory. Adding record for field \'' + fieldName + '\' to the case history list.');
						
						CaseInteractionHistory history = new CaseInteractionHistory();
						history.objectId = record.CaseId;
						history.objectName = 'Case History';
						history.createdBy = record.CreatedBy.Name;
						history.setCreatedDate(record.CreatedDate);
						
						if (header != null) {
							history.header = header;
						} else {
							
							if (record.NewValue == null) {
								history.header = 'Cleared ' + fieldName + '.';
							} else if (record.OldValue == null) {
								history.header = 'Set ' + fieldName + ' to \'' + record.NewValue + '\'.';
							} else {
								history.header = 'Changed ' + fieldName + ' from \'' + record.OldValue + '\' to \'' + record.NewValue + '\'.';
							}
						}
						
						historyList.add(history);
					}
				}
			}
			
    	} catch (Exception e) {
    		System.debug('CustomCaseLogic.GetCaseEvents. Failed to read field service digest for case. Details: ' + e.getMessage());
    	}
    										
		return historyList;    										
    }
    
    /**
     * Sort case interaction history list in reverse order (showing the most recent history first)
     */
	private static void SortHistoryList(List<CaseInteractionHistory> historyList) {
		
		// Check for history list passed
		if (historyList == null || historyList.isEmpty()) { return; }
		
		Map<DateTime, List<CaseInteractionHistory>> historyMap = new Map<DateTime, List<CaseInteractionHistory>>();
		
		// Iterate over history items
		for (CaseInteractionHistory history : historyList) {
			
			if (historyMap.containsKey(history.createdDate)) {
				historyMap.get(history.createdDate).add(history);
			} else {
				historyMap.put(history.createdDate, new List<CaseInteractionHistory> { history });
			}
			
		}
		
		// Get and sort date key values
		List<DateTime> dateKeys = new List<DateTime>(historyMap.keyset());
		dateKeys.sort();
		
		historyList.clear();
		
		// Reverse iterate over date keys and get list items
		Integer ndx = dateKeys.size();
		while (ndx > 0) {
			ndx--;
			historyList.addAll(historyMap.get(dateKeys[ndx]));
		}
	}
}