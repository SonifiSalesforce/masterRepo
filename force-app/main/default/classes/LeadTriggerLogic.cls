// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Class for associating converted Lead fields with Accounts 
// 
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

global class LeadTriggerLogic {
	
	// Processes converted leads.
	// NOTE Assumes received leads have just been converted.
	// To that end, no additional safeguards are in place to ensure that this is true.
	global static void ProcessLeadConversion(Set<Lead> leads) {
		
		Utilities.writeLog(
			'**********    START', 
			LeadTriggerLogic.class, 'ProcessLeadConversion', LoggingLevel.DEBUG); 
			
		// Check for leads
		if (leads == null) { 
			Utilities.writeLog(
				'**********    NOTHING TO DO', 
				LeadTriggerLogic.class, 'ProcessLeadConversion', LoggingLevel.DEBUG); 
			return; 
		}
		
		// Set<Id> leadIds = new Set<Id>();
		// for (Lead l : leads) { leadIds.add(l.Id); }
		Map<Id, Lead> leadMap = new Map<Id, Lead> ([
			SELECT Id, 
				ConvertedAccountId,
				Parent_Account__c,
				Management_Group__c,
				Dietary_Vendor__c,
				Nurse_Call_Vendor__c,
				EMR_Vendor__c,
				HVAC__c,
				Consultant__c,
				Current_FTG_Vendor__c, 
				Current_FTG_Vendor_Contract_Expiration__c,
				Current_PPV_Vendor__c,
				Current_PPV_Vendor_Contract_Expiration__c,
				Current_Broadband_Vendor__c,
				Current_Broadband_Contract_Expiration__c,
				Current_Patient_Education_Provider__c,
				Current_Patient_Ed_Contract_Expiration__c,
				Current_Patient_Entertainment_Vendor__c,
				Current_Patient_Entertainment_Expiration__c
			FROM Lead
			WHERE Id IN :leads
		]);

		// Get Account Ids
		Set<Id> accountIds = new Set<Id>();
		for (Lead l : leadMap.values()) {
			accountIds.add(l.ConvertedAccountId);
		}
		// Get accounts
		Map<Id, Account> accountMap = new Map<Id, Account>([
			
			SELECT Id, ParentId, Name
			FROM Account
			WHERE Id IN :accountIds
		
		]);
		
		Partner p;
		Competitor__c competitor;
		List<Competitor__c> competitors = new List<Competitor__c>();
		List<Partner> partners = new List<Partner>();
		
		// Process leads
		for (Lead l : leads) {
			
			// Get converted account
			Account leadAccount = accountMap.get(l.ConvertedAccountId);
			
			Utilities.writeLog(
				'Processing lead \'' + l.Name + '\' (' + l.Id + ') with Account \'' + leadAccount.Name + '\'', 
				LeadTriggerLogic.class, 'ProcessLeadConversion', LoggingLevel.DEBUG); 
			
/*
			// Check for healthcare
			if (l.RecordTypeId == Utilities.RecordTypeNameToId('Account', Definitions.RECORDTYPE_HealthcareLeads)) {
				
			} else {
				
				// ASSUME Hospitality
				
			}
*/
			// Update converted account fields
			if (l.Parent_Account__c != null) {
				leadAccount.ParentId = l.Parent_Account__c;
			}
			
			if (l.Management_Group__c != null) {
				leadAccount.Management_Group__c = l.Management_Group__c;
			}
			
			// Check for FTG Vendor
			if (l.Current_FTG_Vendor__c != null) {
				
				// Create competitor
				competitor = new Competitor__c(
					Site__c = leadAccount.Id,
					Vendor__c = l.Current_FTG_Vendor__c,
					Vendor_Type__c = Definitions.VENDOR_TYPE_FTG,
					Contract_Expiration_Date__c = l.Current_FTG_Vendor_Contract_Expiration__c
				);
				
				// Add competitor to list
				competitors.add(competitor);
			}
			
			// Check for PPV Vendor
			if (l.Current_PPV_Vendor__c != null) {
				
				// Create competitor
				competitor = new Competitor__c(
					Site__c = leadAccount.Id,
					Vendor__c = l.Current_PPV_Vendor__c,
					Vendor_Type__c = Definitions.VENDOR_TYPE_PPV,
					Contract_Expiration_Date__c = l.Current_PPV_Vendor_Contract_Expiration__c
				);
				
				// Add competitor to list
				competitors.add(competitor);
			}

			// Check for Broadband Vendor
			if (l.Current_Broadband_Vendor__c != null) {
				
				// Create competitor
				competitor = new Competitor__c(
					Site__c = leadAccount.Id,
					Vendor__c = l.Current_Broadband_Vendor__c,
					Vendor_Type__c = Definitions.VENDOR_TYPE_Broadband,
					Contract_Expiration_Date__c = l.Current_Broadband_Contract_Expiration__c
				);
				
				// Add competitor to list
				competitors.add(competitor);
			}
			
			// Check for Patient Education Vendor
			if (l.Current_Patient_Education_Provider__c != null) {
				
				// Create competitor
				competitor = new Competitor__c(
					Site__c = leadAccount.Id,
					Vendor__c = l.Current_Patient_Education_Provider__c,
					Vendor_Type__c = Definitions.VENDOR_TYPE_PatientEducation,
					Contract_Expiration_Date__c = l.Current_Patient_Ed_Contract_Expiration__c
				);
				
				// Add competitor to list
				competitors.add(competitor);
			}
			
			// Check for Patient Entertainment Vendor
			if (l.Current_Patient_Entertainment_Vendor__c != null) {
								
				// Create competitor
				competitor = new Competitor__c(
					Site__c = leadAccount.Id,
					Vendor__c = l.Current_Patient_Entertainment_Vendor__c,
					Vendor_Type__c = Definitions.VENDOR_TYPE_PatientEntertainment,
					Contract_Expiration_Date__c = l.Current_Patient_Entertainment_Expiration__c
				);
				
				// Add competitor to list
				competitors.add(competitor);
			}
			
			
			/* CHECK PARTNER ACCOUNTS */
			
			// Check for Nurse Call Partner
			if (l.Nurse_Call_Vendor__c != null) {
				
				// Create partner
				p = new Partner(
					AccountFromId = leadAccount.Id,
					AccountToId = l.Nurse_Call_Vendor__c,
					Role = Definitions.PARTNER_TYPE_NurseCall
				);
				
				// Add partner to list
				partners.add(p);
			}
			
			// Check for Dietary Partner
			if (l.Dietary_Vendor__c != null) {
				
				// Create partner
				p = new Partner(
					AccountFromId = leadAccount.Id,
					AccountToId = l.Dietary_Vendor__c,
					Role = Definitions.PARTNER_TYPE_Dietary
				);
				
				// Add partner to list
				partners.add(p);
			}
			
			// Check for EMR Vendor
			if (l.EMR_Vendor__c != null) {
				
				// Create partner
				p = new Partner(
					AccountFromId = leadAccount.Id,
					AccountToId = l.EMR_Vendor__c,
					Role = Definitions.PARTNER_TYPE_EMR
				);
				
				// Add partner to list
				partners.add(p);
			}
			
			// Check for HVAC Vendor
			if (l.HVAC__c != null) {
				
				// Create partner
				p = new Partner(
					AccountFromId = leadAccount.Id,
					AccountToId = l.HVAC__c,
					Role = Definitions.PARTNER_TYPE_HVAC
				);
				
				// Add partner to list
				partners.add(p);
			}
			
			// Check for Consultant Vendor
			if (l.Consultant__c != null) {
				
				// Create partner
				p = new Partner(
					AccountFromId = leadAccount.Id,
					AccountToId = l.Consultant__c,
					Role = Definitions.PARTNER_TYPE_Consultant
				);
				
				// Add partner to list
				partners.add(p);
			}
			
			// Put updated lead account back into the map (for updating)
			accountMap.put(leadAccount.Id, leadAccount);
		}
		
		try {
			
			// Update accounts
			update accountMap.values();
			
			// Add competitors
			insert competitors;
			
			// Add partners
			insert partners;
			
		} catch (Exception e) {
			
			// NOTE We should Log error. 
			// But there is no reason to rollback any successful changes here.
			
			Utilities.writeLog(
				'ERROR FAILED TO CONVERT LEAD FIELDS. DETAILS: ' + e.getMessage(), 
				LeadTriggerLogic.class, 'ProcessLeadConversion', LoggingLevel.ERROR); 
			
		}
		
		Utilities.writeLog(
			'**********    END', 
			LeadTriggerLogic.class, 'ProcessLeadConversion', LoggingLevel.DEBUG); 
	}
}