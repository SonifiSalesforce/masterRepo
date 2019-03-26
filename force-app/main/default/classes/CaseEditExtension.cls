// *********************************************************************************************
// Filename:	 CaseEditExtension
// Version:      0.0.1
// Author:       Etherios
// Date Created: 9/4/2013
// Description:  Extension class for custom Support Case Edit VFP. 
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

global class CaseEditExtension {
	
	global class MilestoneDetail {
		public String								name									{ get; set; }
		public String								description								{ get; set; }
		public String								timeToComplete							{ get; set; }
		public Integer								sortOrder								{ get; set; }
	}
	
	global class EntitlementOption {
		public String 								name									{ get; set; }
		public String								description								{ get; set; }
		public String								priority								{ get; set; }
		public Integer								sortOrder								{ get; set; }
		public List<MilestoneDetail>				milestones								{ get; set; }
	}
	
	global class EntitlementDetails {
		public Id									entitlementId							{ get; set; }
		public String								entitlementName							{ get; set; }
		public Id									serviceContractId						{ get; set; }
		public String								serviceContractName						{ get; set; }
		List<EntitlementOption>						entitlementOptions						{ get; set; }
	}
	
	public String									newCaseId								{ get; set; }
	public String									casePriority							{ get; set; }
	public String 									internalComments						{ get; set; }
	public String 									externalComments						{ get; set; }
	public String									milestoneSynopsis						{ get; set; }
	public String 									createdDateFormatted					{ get; set; }
	
	private ApexPages.StandardController 			theController							;
	private Case 									theCase									;
	private Boolean 								isNew 									= false;
	
	/**
	 * Constructor
	 */
	public CaseEditExtension(ApexPages.StandardController controller) {
		theController = controller;
		theCase = (Case)controller.getRecord();
		if (theCase == null ) { theCase = new Case(); }
		if (theCase.Id == null) { isNew = true; }
		initializeCase();
	}
	
	/**
	 * 
	 */
	public Id baseEntitlementId {
		get {
			if (baseEntitlementId == null) {
				baseEntitlementId = Id.valueOf(AppConfig__c.getValues('Global').Not_Contracted_Entitlement__c);
			}
			return baseEntitlementId;
		}
		private set;
	}
	
	/**
	 * 
	 */
	public Boolean applyAssignmentRules {
		get {
			if (applyAssignmentRules == null) { applyAssignmentRules = false; }
			return applyAssignmentRules; 
		} 
		set; 
	}
	
	/**
	 * Build map of Case field set API names to labels for use in VFP
	 */
	public Map<String, String> fieldSetNames {
		get {
			if (fieldSetNames == null) { getFieldSetInfo(); }
			return fieldSetNames;
		}
		private set;
	}
	
	public Map<String, Map<String, Integer>> fieldSetTabOrder {
		get {
			if (fieldSetNames == null) { getFieldSetInfo(); }
			return fieldSetTabOrder;
		}
		private set;
	}
	
	private void getFieldSetInfo() {
		
		fieldSetNames = new Map<String, String>();
		fieldSetTabOrder = new Map<String, Map<String, Integer>>();
		
		// Iterate over configured field sets
		for (Schema.FieldSet fs : Schema.SObjectType.Case.fieldSets.getMap().values()) {
/*			
			// Iterate over fields in the field set to create tab order mapping
			Map<Integer, String> fieldMap = new Map<Integer, String>();
			List<Schema.FieldSetMember> fieldList = fs.getFields();
			Integer leftColNdx = 1;
			Integer rightColNdx = (fieldList.size() / 2) + 1;
			
			for (Integer ndx = 0; ndx < fieldList.size(); ndx+=2) {
				fieldMap.put(leftColNdx, fieldList[ndx].getLabel());
				fieldMap.put(rightColNdx, fieldList[ndx + 1].getLabel());
				leftColNdx++;
				rightColNdx++;
			}
			
			List<Integer> keyset = new List<Integer>(fieldMap.keyset());
			keyset.sort();
			
			Map<String, Integer> tabMap = new Map<String, Integer>();
			for (Integer key : keyset) { tabMap.put(fieldMap.get(key), key); }
*/			
			String fieldName = fs.getName();
			
			// Add to field set name map
			fieldSetNames.put(fieldName, fs.getLabel());
			
			// Add to tab order map
//			fieldSetTabOrder.put(fieldName, tabMap);
		}
		
	}
	
	/**
	 * 
	 */
	private void initializeCase() {
		
		Id assetId;
		Id entitlementId;
		
		// Attempt to push page parameters into case fields
		Map<String, String> pageParams = ApexPages.currentPage().getParameters();
		for (String param : pageParams.keyset()) {
			
			param = param.toLowerCase();
			String value = pageParams.get(param);
			
			if (param == 'def_account_id') {
				
				theController.getRecord().put('AccountId', value);
				System.debug('CaseEditExtension.initializeCase. Setting Account Id to ' + value);
				
			} else if (param == 'def_entitlement_id') {
				
				System.debug('CaseEditExtension.initializeCase. Setting Entitlement Id to ' + value);
				
				entitlementId = Id.valueOf(value);
				theController.getRecord().put('EntitlementId', value);
				
				try {
					EntitlementDetails details = CaseEditExtension.GetServiceContract(value);
					System.debug(details);
					if (details != null && details.serviceContractId != null) {
						System.debug('CaseEditExtension.initializeCase. Setting Service Contract Id to ' + details.serviceContractId);
						theController.getRecord().put('Service_Contract_Name__c', details.serviceContractId); 
					}
				} catch (Exception e) {}
				
			} else if (param == 'recordtype') {
				
				System.debug('CaseEditExtension.initializeCase. Setting RecordType Id to ' + value);
				theController.getRecord().put('RecordTypeId', value);
				
			} else {
				try {
					System.debug('CaseEditExtension.initializeCase. Attempting to assign page parameter ' + param + ' value \'' + value + '\' to the case.');
					
					if (param == 'entitlementid') { entitlementId = Id.valueOf(value); } 
					else if (param == 'assetid') { assetId = Id.valueOf(value); }
					
					theController.getRecord().put(param, value);
					
				} catch (Exception e) {}
			}
		}
		
		// Check for new case
		if (isNew) {
			System.debug('CaseEditExtension.initializeCase. Case is new.');
			DateTime rightNow = DateTime.now();
			try { theController.getRecord().put('CreatedDate', rightNow); }
			catch (Exception e) {}
			theController.getRecord().put('OwnerId', UserInfo.getUserId());
			theController.getRecord().put('Date_Time_Initiated__c', rightNow);
			createdDateFormatted = rightNow.format('M/d/yyyy h:m a');
			
			// NOTE If we are running tests, there is no way to get data into this field
			if (!Test.isRunningTest()) { theController.getRecord().put('Priority', ''); }
			
	    	// Check for entitlement Id passed
	    	if (entitlementId != null) {
	    		
	    		try { CustomCaseLogic.setCaseEntitlementDetails((Case)theController.getRecord(), entitlementId); }
	    		catch (Exception e) {}
	    	
	    	// Check for asset Id passed	
	    	} else if (assetId != null) {
	    		
	    		try { CustomCaseLogic.setCaseAssetDetails((Case)theController.getRecord(), assetId); }
	    		catch (Exception e) {}
	    		
	    	}
		}
	}
	
	/**
	 * 
	 */
	public String closedCaseStatusJSON {
		get {
			if (closedCaseStatusJSON == null) {
				closedCaseStatusJSON = JSON.serialize(Utilities.closedCaseStatuses);
			}
			return closedCaseStatusJSON;
		}
		private set;
	}
	
	/**
	 * 
	 */
	private Boolean saveCaseDetails() {
		
		try {
			
			// NOTE WE MUST RE-GET THE CASE HERE AS THE USER'S UPDATES
			// HAVE BEEN SAVED INTO THE CONTROLLER OBJECT--NOT THE CASE OBJECT 
			theCase = (Case)theController.getRecord();
			
			// Check for new
			if (isNew) {
				// Check for Id set
				if (newCaseId != null && newCaseId != '') {
					try { 
						System.debug(LoggingLevel.DEBUG, 'Case Id ' + newCaseId + ' found for new case. Saving new case with Id.');
						Case newCase = new Case(Id=Id.valueOf(newCaseId));
						List<String> caseFields = Utilities.getSObjectFields(Case.getSObjectType(), false);
						for (String fieldName : caseFields) {
							object fieldValue = theCase.get(fieldName);
							if (fieldValue != null) {
								try { newCase.put(fieldName, theCase.get(fieldName)); }
								catch (Exception e) {}
							}
						}
						theCase = newCase;
					}
					catch (Exception e) {}
				}
			}
			
			// Check assignment rules flag
			if (applyAssignmentRules) {
				
				System.debug('CaseEditExtension.saveCaseDetails. Applying assignment rules.');
				
				// Set options for applying assignment rules
				Database.DMLOptions options = new Database.DMLOptions();
				options.assignmentRuleHeader.useDefaultRule = true;
				theCase.setOptions(options);
				
			}
			
			// Check for milestone synopsis to write
			if (milestoneSynopsis != null && milestoneSynopsis != '') {
				theCase.Case_Milestone_Synopsis__c = milestoneSynopsis;
			}
			
			// Check for priority
			if (casePriority != null && casePriority != '') {
				theCase.Priority = casePriority;
			}
			
			// Save edited field values
			upsert theCase;
			
			// Check for internal comments and save
			List<CaseComment> caseComments = new List<CaseComment>();
			if (internalComments != null && internalComments != '') {
				caseComments.add(new CaseComment(
					CommentBody = internalComments,
					ParentId = theCase.Id,
					IsPublished = false
				));
			}
			
			// Check for internal comments and save
			if (externalComments != null && externalComments != '') {
				caseComments.add(new CaseComment(
					CommentBody = externalComments,
					ParentId = theCase.Id,
					IsPublished = true
				));
			}
			
			if (!caseComments.isEmpty()) { insert caseComments; }
			
			return true;
			
		} catch (Exception e) {
       		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
		        			     '<b>Failed to save case details.</b>', e.getMessage()));
		}
		
		return false;
	}

	/**
	 * Save edits and redirect to appropriate page
	 */
	public PageReference Save() {
		
		// Save case details
		if (!saveCaseDetails()) { return null; }
		
		// Send to view page
		// PageReference redirectTo = new PageReference(Utilities.urlPrefix + theCase.Id);
		PageReference redirectTo = new PageReference(Utilities.getRedirectUrl(theCase.Id));
		redirectTo.setRedirect(true);
		return redirectTo;
	}
	
	/**
	 * Save edits and redirect to appropriate page
	 */
	public PageReference SaveAndClose() {
		
		// Save case details
		if (!saveCaseDetails()) { return null; }
		
		// Send to close page
		//PageReference redirectTo = new PageReference(Utilities.urlPrefix + theCase.Id + '/s?retUrl=%2f' + theCase.Id);
		//redirectTo.getParameters().put('returl', EncodingUtil.urlEncode(Utilities.urlPrefix + theCase.Id, 'UTF-8'));
		PageReference redirectTo = new PageReference(Utilities.getRedirectUrl(theCase.Id + 's'));
		
		String returnUrl = Utilities.getReturnUrl(theCase.Id);
		redirectTo.getParameters().put('retURL',  returnUrl);
		redirectTo.getParameters().put('cancelURL',  returnUrl);
		
		redirectTo.setRedirect(true);
		return redirectTo;
	}
	
	/**
	 * Save edits and redirect to appropriate page
	 */
	public PageReference SaveAndNew() {
		
		// Save case details
		if (!saveCaseDetails()) { return null; }
		
		// Send to view page
		PageReference redirectTo = Page.CaseEdit;
		redirectTo.getParameters().put('RecordType', theCase.RecordTypeId);
		if (theCase.AccountId != null) { redirectTo.getParameters().put('AccountId', theCase.AccountId); }
		
		redirectTo.setRedirect(true);
		return redirectTo;
	}
	
	/**
	 * Cancel edit and redirect to appropriate page
	 */
	public PageReference Cancel() {
		
		theController.cancel();
		
		PageReference redirectTo;
		String redirectUrl = ApexPages.currentPage().getParameters().get('retURL');
		if (redirectUrl == null || redirectUrl == '') {
			if (theCase == null || theCase.Id == null) {
				// redirectTo = new PageReference(Utilities.urlPrefix + '500/o');
				redirectTo = new PageReference(Utilities.getRedirectUrl('500/o'));
			} else {
				redirectTo = new ApexPages.StandardController(theCase).view();
			}
		} else {
			redirectTo = new PageReference(EncodingUtil.urlDecode(redirectUrl, 'UTF-8'));
		}
		
		redirectTo.setRedirect(true);
		return redirectTo;
	}
	
	/**
	 * 
	 */
	@RemoteAction
	global static List<CustomFlashNotificationLogic.FlashNotification> GetFlashNotifications(Id accountId) {
		try { return CustomFlashNotificationLogic.GetFlashNotifications(accountId); } 
		catch (Exception e) {}
		return null;
	}
	
	/**
	 * 
	 */
	@RemoteAction
	global static Id GetBaseEntitlementId() {
		try { return Id.valueOf(AppConfig__c.getValues('Global').Not_Contracted_Entitlement__c); }
		catch (Exception e) { 
			throw new Exceptions.AppException('Could not read base entitlement Id '
				+ 'from the Not_Contracted_Entitlement__c field of the Global record '
				+ 'in the App Config custom setting. Details: ' + e.getMessage());
		}
	}
	
	/**
	 * 
	 */
	@RemoteAction
	global static EntitlementDetails GetServiceContract(Id entitlementId) {
		
		System.debug('CaseEditExtension.GetServiceContract. Entitlement Id: ' + entitlementId);
		
		Entitlement theEntitlement;
		try {
			theEntitlement = [
				SELECT Id, Name, ServiceContractId, ServiceContract.Name
				FROM Entitlement
				WHERE Id = :entitlementId
				LIMIT 1
			];
		} catch (Exception e) {
			System.debug(LoggingLevel.ERROR, 'CaseEditExtension.GetServiceContract. Failed to read entitlement for Id ' 
				+ entitlementId + '. Details: ' + e.getMessage());
		}
		
		// Check for entitlement data returned
		if (theEntitlement == null) { return null; }
		
		// Add header
		EntitlementDetails entitlementDetail = new EntitlementDetails();
		entitlementDetail.entitlementId = theEntitlement.Id;
		entitlementDetail.entitlementName = theEntitlement.Name;
		entitlementDetail.serviceContractId = theEntitlement.ServiceContractId;
		entitlementDetail.serviceContractName = theEntitlement.ServiceContract.Name;
		
		// Return options map
		return entitlementDetail;
	}
	
	/**
	 * 
	 */
	@RemoteAction
	global static EntitlementDetails GetEntitlementDetails(Id entitlementId) {
		
		Map<String, String> entitlementFieldMap = new Map<String, String>();
		Map<String, SObjectField> fieldMap = Entitlement.getSObjectType().getDescribe().fields.getMap();
		for (String f : fieldMap.keySet()) {
		    DescribeFieldResult field = fieldMap.get(f).getDescribe();
		    String fieldName = field.getName();
		    if (fieldName.toUpperCase().contains('_SEVERITY_DESCRIPTION')) {
		    	System.debug('CaseEditExtension.GetEntitlementDetails. Adding field ' + fieldName);
			    entitlementFieldMap.put(fieldName, field.getLabel());
		    }
		}
		
		Entitlement theEntitlement;
		try {
			
			String query = 'SELECT Id, Name, SlaProcessId, SlaProcess.Name, SlaProcess.Description, ServiceContractId, ServiceContract.Name, ' 
							+ String.join(new List<String>(entitlementFieldMap.keyset()), ',') + ' '
							+ ' FROM Entitlement '
							+ ' WHERE Id = \'' + entitlementId + '\'';
			System.debug('CaseEditExtension.GetEntitlementDetails. Entitlement Query: ' + query);
			theEntitlement = Database.query(query);
				
		} catch (Exception e) {
        	throw new Exceptions.AppException('Could not read details for entitlement. Details: ' + e.getMessage());
		}
		
		// Check for no entitlement found
		if (theEntitlement == null) { throw new Exceptions.AppException('No entitlement data found.'); }
		if (theEntitlement.SlaProcessId == null) { throw new Exceptions.AppException('Entitlement has no process associated with it.'); }
		
		Map<String, Integer> entitlementSortOrderMap = new Map<String, Integer>();
		for (MilestoneSortOrder__c record : MilestoneSortOrder__c.getAll().values()) {
			try { entitlementSortOrderMap.put(record.Name.toLowerCase(), Integer.valueOf(record.Order__c)); }
			catch (Exception e) {}
		}
		
		// Create entitlement options from severity description fields
		Map<String, EntitlementOption> entitlementOptions = new Map<String, EntitlementOption>();
		for (String fieldName : entitlementFieldMap.keyset()) {
			
			// NOTE Not all entitlements will have severity descriptions for each of the
			// milestones defined for that process. If no severity description is present
			// in the entitlement, we do not want to create a record for it on our page
			String description = theEntitlement.get(fieldName) == null ? null : String.valueOf(theEntitlement.get(fieldName));
			
			if (description != null) {
				EntitlementOption eo = new EntitlementOption();
				eo.priority = fieldName.substring(0, fieldName.indexOf('_'));
				eo.name = entitlementFieldMap.get(fieldName);
				eo.description = description;
				if (entitlementSortOrderMap.containsKey(eo.priority.toLowerCase())) {
					eo.sortOrder = entitlementSortOrderMap.get(eo.priority.toLowerCase());
				} else {
					eo.sortOrder = 999;
				}
				eo.milestones = new List<MilestoneDetail>();
				entitlementOptions.put(eo.priority.toUpperCase(), eo);
				System.debug('CaseEditExtension.GetEntitlementDetails. Adding entitlement option ' + eo.priority.toUpperCase() + ': ' + eo);
			} else {
				System.debug('CaseEditExtension.GetEntitlementDetails. No description found for ' + fieldName);
			}
		}
		
		if (entitlementOptions.isEmpty()) { return null; }
		
		// Add configured milestones from Milestone Details custom setting to the map
		String entitlementName = theEntitlement.SlaProcess.Name.toUpperCase();
		System.debug('CaseEditExtension.GetEntitlementDetails. EntitlementName ' + entitlementName);
		for(MilestoneDetails__c detail : MilestoneDetails__c.getAll().values()) {
			
			String priorityKey = detail.Priority__c.toUpperCase();
			System.debug('CaseEditExtension.GetEntitlementDetails. Milestone Entitlement Name ' + detail.Entitlement__c + '; Priority ' + priorityKey);
			
			// Check for matching entitlement (process) and entitlement option
			if (detail.Entitlement__c.toUpperCase() == entitlementName
				&& entitlementOptions.containsKey(priorityKey)) {
				
				// Create milestone
				MilestoneDetail md = new MilestoneDetail();
				md.name = detail.Milestone__c;
				md.description = detail.Description__c == null ? '' : detail.Description__c;
				md.timeToComplete = String.valueOf(detail.TimeAllowed__c);
				md.sortOrder = Integer.valueOf(detail.Order__c);
				
				// Add to entitlement milestones
				entitlementOptions.get(priorityKey).milestones.add(md);
			}
		}
		
		// Create entitlement details header
		EntitlementDetails entitlementDetail = new EntitlementDetails();
		entitlementDetail.entitlementId = theEntitlement.Id;
		entitlementDetail.entitlementName = theEntitlement.Name;
		entitlementDetail.serviceContractId = theEntitlement.ServiceContractId;
		entitlementDetail.serviceContractName = theEntitlement.ServiceContract.Name;
		entitlementDetail.entitlementOptions = new List<EntitlementOption>();
		
		// Sort entitlement options
		Map<Integer, EntitlementOption> sortMap = new Map<Integer, EntitlementOption>();
		for (EntitlementOption option : entitlementOptions.values()) {
			sortMap.put(option.sortOrder, option);
		}
		
		List<Integer> sortKeys = new List<Integer>(sortMap.keyset());
		sortKeys.sort();
		
		// Iterate over the option indices to build the sorted list
		for (Integer key : sortKeys) {
			entitlementDetail.entitlementOptions.add(sortMap.get(key));
		}
		
		// Return options map
		return entitlementDetail;
	}
	
	/**
	 * 
	 */
	@RemoteAction
	global static List<CustomCaseLogic.CaseInteractionHistory> GetCaseInteractionHistory(Id caseId) {
		try { return CustomCaseLogic.GetCaseInteractionHistory(caseId); } 
		catch (Exception e) {}
		return null;
	}
	
	/* 
	 * 
	 */
	@RemoteAction
	global static Case CreateCase(String ownerIdString, String createdOn, String accountIdString, String entitlementIdString, String serviceContractIdString) {
		try {
			Case newCase = (Case)DataGenerator.createSObjectWithDefaultValues('Case', Utilities.RecordTypeNameToId('Case', 'Support Case'));
			newCase.AccountId = Id.valueOf(accountIdString);
			newCase.OwnerId = Id.valueOf(ownerIdString);
			if (entitlementIdString != null && entitlementIdString != '' && entitlementIdString.substring(0, 3) != '000') { newCase.EntitlementId = Id.valueOf(entitlementIdString); }
			if (serviceContractIdString != null && serviceContractIdString != '' && serviceContractIdString.substring(0, 3) != '000') { newCase.Service_Contract_Name__c = Id.valueOf(serviceContractIdString); }
			newCase.Date_Time_Initiated__c = DateTime.parse(createdOn);
			insert newCase;
			return [SELECT Id, CaseNumber FROM Case WHERE Id = :newCase.Id LIMIT 1];
		} catch (Exception e) {
			throw new Exceptions.AppException('Could not create case. Details: ' + e.getMessage());
		}
		return null;
	}
}