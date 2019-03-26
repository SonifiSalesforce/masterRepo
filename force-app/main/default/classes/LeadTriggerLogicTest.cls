// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Test class for the Lead trigger and associated LeadTriggerLogic class 
// 
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

@isTest
public with sharing class LeadTriggerLogicTest {
	
	@isTest static void testLeadTrigger() {
		
		// Create users for hospitality and healthcare tests
		List<User> users = DataGenerator.createUsers(
			Definitions.PROFILE_SalesUser, 2, false);
		System.assertNotEquals(null, users);
		System.assertNotEquals(true, users.isEmpty());
		System.assertEquals(2, users.size());
		
		// Set user 2 to healthcare sales
		users[1].ProfileId = Utilities.ProfileNameToId(Definitions.PROFILE_HealthcareSales);
		insert users;
		
		// Create accounts
		Integer accountsToCreate = 13;
		List<Account> accounts = DataGenerator.createAccounts(accountsToCreate, false);
		System.assertNotEquals(null, accounts);
		System.assertNotEquals(true, accounts.isEmpty());
		System.assertEquals(accountsToCreate, accounts.size());
		
		// Modify accounts
		Id accountRecordType = Utilities.RecordTypeNameToId('Account', Definitions.RECORDTYPE_AccountThirdParty);
		for (Account a : accounts) {
			a.RecordTypeId = accountRecordType;
		}
		
		// Management account
		accountRecordType = Utilities.RecordTypeNameToId('Account', Definitions.RECORDTYPE_AccountMOL);
		accounts[11].RecordTypeId = accountRecordType; 
		
		// Parent account
		accountRecordType = Utilities.RecordTypeNameToId('Account', Definitions.RECORDTYPE_AccountFlagBrand);
		accounts[12].RecordTypeId = accountRecordType; 
		
		// Insert accounts
		insert accounts;
		
		// Create leads
		List<Lead> leads = new List<Lead>();
		Integer i = 0;
		for (User u : users) {
			i++;
			System.runAs(u) {
				Lead l = new Lead(
					Company = u.Alias + ' Lead',
					LastName = 'CEO',
					Street = i + ' Main Street',
					City = 'Anytown',
					State = 'TX',
					PostalCode = '11111',
					Phone = '214-555-000' + i,
					Email = u.Email,
					Description = u.Alias + ' Lead',
					Current_FTG_Vendor__c = accounts[0].Id,
					Current_FTG_Vendor_Contract_Expiration__c = Date.today().addYears(1),
					Current_PPV_Vendor__c = accounts[1].Id,
					Current_PPV_Vendor_Contract_Expiration__c = Date.today().addYears(2),
					Current_Patient_Education_Provider__c = accounts[2].Id,
					Current_Patient_Ed_Contract_Expiration__c = Date.today().addYears(3),
					Current_Patient_Entertainment_Vendor__c = accounts[3].Id,
					Current_Patient_Entertainment_Expiration__c = Date.today().addYears(4),
					Current_Broadband_Vendor__c = accounts[4].Id,
					Current_Broadband_Contract_Expiration__c = Date.today().addYears(5),
					Dietary_Vendor__c = accounts[5].Id,
					Nurse_Call_Vendor__c = accounts[6].Id,
					EMR_Vendor__c = accounts[7].Id,
					HVAC__c = accounts[8].Id,
					Consultant__c = accounts[9].Id,
					GPO__c = accounts[10].Id,
					Management_Group__c = accounts[11].Id,
					Parent_Account__c = accounts[12].Id
				);
				
				leads.add(l);
			}
		}
		insert leads;
		Integer leadCount = leads.size();
		
		// Get lead conversion status
		String convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel;
		System.assertNotEquals(null, convertedStatus);
		
		// Convert Leads
		for (i = 0; i < leads.size(); i++) {
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(leads[i].Id);
			lc.setConvertedStatus(convertedStatus);
			
			Database.LeadConvertResult lcr = Database.convertLead(lc);
			System.assert(lcr.isSuccess());
		}
		
		// Re-get leads with converted account Ids
		Set<Id> leadIds = new Set<Id>();
		for (Lead l : leads) { leadIds.add(l.Id); }
		leads = [
			
			SELECT ConvertedAccountId, Name, Description, IsConverted,
				Current_FTG_Vendor__c,
				Current_FTG_Vendor_Contract_Expiration__c,
				Current_PPV_Vendor__c,
				Current_PPV_Vendor_Contract_Expiration__c,
				Current_Broadband_Vendor__c,
				Current_Broadband_Contract_Expiration__c,
				Current_Patient_Education_Provider__c,
				Current_Patient_Ed_Contract_Expiration__c,
				Current_Patient_Entertainment_Vendor__c,
				Current_Patient_Entertainment_Expiration__c,
				Dietary_Vendor__c ,
				Nurse_Call_Vendor__c,
				EMR_Vendor__c,
				HVAC__c,
				Consultant__c,
				GPO__c,
				Management_Group__c,
				Parent_Account__c
			FROM Lead 
			WHERE Id IN :leadIds
			
		]; 
		
		Map<Id, Lead> accountToLeadMap = new Map<Id, Lead>();
		for (Lead l : leads) {
			// Ensure that lead was converted
			System.assertEquals(true, l.IsConverted);
			System.debug('*****  CONVERTED LEAD: ' + l.Name + ' with Account: ' + l.ConvertedAccountId);
			accountToLeadMap.put(l.ConvertedAccountId, l);	
		}
		
		// Confirm lead fields moved to parent
		Map<Id, Account> leadAccounts = new Map<Id, Account> ([
			SELECT Id, ParentId, Management_Group__c
			FROM Account
			WHERE Id IN :accountToLeadMap.keyset()
		]);
		
		for (Lead l : leads) {
			Account leadAccount = leadAccounts.get(l.ConvertedAccountId);
			System.assertNotEquals(null, l.Parent_Account__c);
			System.assertEquals(leadAccount.ParentId, l.Parent_Account__c);
			System.assertNotEquals(null, l.Management_Group__c);
			System.assertEquals(leadAccount.Management_Group__c, l.Management_Group__c);
		}
		
		// Confirm Competitors exist
		Set<Id> accountIds = new Set<Id>();
		for (Account a : accounts) { accountIds.add(a.Id); }
		List<Competitor__c> competitors = [
			
			SELECT Id, Name, Site__c, 
				Contract_Expiration_Date__c,
				Vendor_Type__c,
				Vendor__r.Id,
				Site__r.Management_Group__c
			FROM Competitor__c
			WHERE Vendor__r.Id IN :accountIds
		];
		
		// Confirm Vendor Type Values for each competitor
		final Integer expectedCompetitors = leadCount * 5;  // 5 competitor types
		Integer competitorCount = 0;
		for (Competitor__c competitor : competitors) {
			
			competitorCount++;
			System.debug('PROCESSING COMPETITOR: ' + competitor.Vendor_Type__c);
			
			System.assertNotEquals(null, competitor.Site__c);
			System.assertEquals(true, accountToLeadMap.containsKey(competitor.Site__c));
			
			Lead l = accountToLeadMap.get(competitor.Site__c);
			
			if (competitor.Vendor_Type__c == Definitions.VENDOR_TYPE_FTG) {
				System.assertEquals(l.Current_FTG_Vendor__c, competitor.Vendor__r.Id);
				System.assertEquals(l.Current_FTG_Vendor_Contract_Expiration__c, competitor.Contract_Expiration_Date__c);
				System.assertEquals(l.Management_Group__c, competitor.Site__r.Management_Group__c);
			} else if (competitor.Vendor_Type__c == Definitions.VENDOR_TYPE_PPV) {
				System.assertEquals(l.Current_PPV_Vendor__c, competitor.Vendor__r.Id);
				System.assertEquals(l.Current_PPV_Vendor_Contract_Expiration__c, competitor.Contract_Expiration_Date__c);
				System.assertEquals(l.Management_Group__c, competitor.Site__r.Management_Group__c);
			} else if (competitor.Vendor_Type__c == Definitions.VENDOR_TYPE_Broadband) {
				System.assertEquals(l.Current_Broadband_Vendor__c, competitor.Vendor__r.Id);
				System.assertEquals(l.Management_Group__c, competitor.Site__r.Management_Group__c);
			} else if (competitor.Vendor_Type__c == Definitions.VENDOR_TYPE_PatientEducation) {
				System.assertEquals(l.Current_Patient_Education_Provider__c, competitor.Vendor__r.Id);
				System.assertEquals(l.Current_Patient_Ed_Contract_Expiration__c, competitor.Contract_Expiration_Date__c);
			} else if (competitor.Vendor_Type__c == Definitions.VENDOR_TYPE_PatientEntertainment) {
				System.assertEquals(l.Current_Patient_Entertainment_Vendor__c, competitor.Vendor__r.Id);
				System.assertEquals(l.Current_Patient_Entertainment_Expiration__c, competitor.Contract_Expiration_Date__c);
			} else {
				System.assert(false, 'UNEXPECTED RESULT. UNKNOWN VENDOR TYPE: ' + competitor.Vendor_Type__c);
			}
		}
		System.assertEquals(expectedCompetitors, competitorCount);
		System.debug('ALL COMPETITORS PROCESSED.');
		
		// Confirm partners were created
		accountIds.clear();
		for (Lead l : leads) { accountIds.add(l.ConvertedAccountId); }
		List<Partner> partners = [
			
			SELECT AccountFromId, AccountToId, Role
			FROM Partner
			WHERE AccountFromId IN :accountIds
		];
		
		final Integer expectedPartners = leadCount * 5;  // 5 partner types
		Integer partnerCount = 0;
		for (Partner p : partners) {
			
			partnerCount++;
			System.debug('PROCESSING PARTNER: ' + p.Role);
			
			System.assertEquals(true, accountToLeadMap.containsKey(p.AccountFromId));
			Lead l = accountToLeadMap.get(p.AccountFromId);
			
			if (p.Role == Definitions.PARTNER_TYPE_NurseCall) {
				System.assertEquals(p.AccountToId, l.Nurse_Call_Vendor__c);
			} else if (p.Role == Definitions.PARTNER_TYPE_Dietary) {
				System.assertEquals(p.AccountToId, l.Dietary_Vendor__c);
			} else if (p.Role == Definitions.PARTNER_TYPE_EMR) {
				System.assertEquals(p.AccountToId, l.EMR_Vendor__c);
			} else if (p.Role == Definitions.PARTNER_TYPE_HVAC) {
				System.assertEquals(p.AccountToId, l.HVAC__c);
			} else if (p.Role == Definitions.PARTNER_TYPE_Consultant) {
				System.assertEquals(p.AccountToId, l.Consultant__c);
			} else {
				System.assert(false, 'UNEXPECTED RESULT. UNKNOWN ROLE: ' + p.Role);
			}
			
		}
		System.assertEquals(expectedPartners, partnerCount);
		System.debug('ALL PARNERS PROCESSED.');
	}
}