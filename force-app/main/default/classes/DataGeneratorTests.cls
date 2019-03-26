@isTest
public with sharing class DataGeneratorTests {

	@isTest static void testCreateUsers() {
		
		// Attempt to create with invalid profile
		List<User> users = DataGenerator.createUsers('INVALID', 0, false);
		System.assertEquals(null, users);

		// Attempt to create 0 users
		users = DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 0, false);
		System.assertNotEquals(null, users);
		System.assertEquals(true, users.isEmpty());
		
		// Attempt to create 1 user
		users = DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 1, false);
		System.assertNotEquals(null, users);
		System.assertEquals(false, users.isEmpty());
		System.assertEquals(1, users.size());
		
		// Attempt to create 200 users AND insert them
		users = DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 200, true);
		System.assertNotEquals(null, users);
		System.assertEquals(false, users.isEmpty());
		System.assertEquals(200, users.size());
		
		// Confirm that all 200 are in the database
		Set<Id> userIds = new Set<Id>();
		for (User u : users) { userIds.add(u.Id); }
		users.clear();
		users = [SELECT Id, Name FROM User WHERE Id IN :userIds];
		System.assertNotEquals(null, users);
		System.assertEquals(false, users.isEmpty());
		System.assertEquals(200, users.size());
	}
	
	@isTest static void testCreateAccounts() {
			
		// Create running user
		User u = DataGenerator.createUsers(
			Definitions.PROFILE_SalesUser, 1, true)[0];
		
		System.runAs(u) {
			
			// Test create no accounts
			List<Account> accounts = DataGenerator.createAccounts(0, true);
			System.assertNotEquals(null, accounts);
			System.assertEquals(true, accounts.isEmpty());
			
			// Test create 200 account
			accounts = DataGenerator.createAccounts(200, true);
			System.assertNotEquals(null, accounts);
			System.assertNotEquals(true, accounts.isEmpty());
			
			List<Id> accIdsList = new List<Id>();
			For(Account a : accounts){
				accIdsList.add(a.Id);
			} 
			
			// Confirm that all 200 are in the database
			List<Account> testAccount = [SELECT Id FROM Account WHERE Id IN :accIdsList];
			System.assertNotEquals(null, testAccount);
			System.assertEquals(200,testAccount.size());
			
			
			
		}
	}
	
	@isTest static void testCreateOpptys() {
			
		Account opptyAccount;
		List<Opportunity> opptys;
		
		// Create running user
		User u = DataGenerator.createUsers(
			Definitions.PROFILE_SalesUser, 1, true)[0];
		
		System.runAs(u) {
			
			// Test invalid account
			try {
				opptys = DataGenerator.createOpptys(opptyAccount, 1, false);
				System.assert(false, 'UNEXPECTED RESULT. EXPECTED EXCEPTION.');
			} catch (Exceptions.IllegalArgumentException e) {
				// EXPECTED RESULT
			} catch (Exception e) {
				System.assert(false, 'UNEXPECTED EXCEPTION. DETAILS: ' + e.getMessage());
			}
			System.assertEquals(null, opptys);
			
			// Create account
			opptyAccount = DataGenerator.createAccounts(1, true)[0];
			
			// Test create no opptys
			opptys = DataGenerator.createOpptys(opptyAccount, 0, true);
			System.assertNotEquals(null, opptys);
			System.assertEquals(true, opptys.isEmpty());
			
			// Test create 1 oppty
			opptys = DataGenerator.createOpptys(opptyAccount, 1, true);
			System.assertNotEquals(null, opptys);
			System.assertNotEquals(true, opptys.isEmpty());

			Opportunity testOp = [SELECT Id FROM Opportunity WHERE Id = :opptys[0].Id];
			System.assertNotEquals(null, testOp);
			System.assertEquals(testOp.Id, opptys[0].Id);
			
			// Test create 200 oppty
			List<Opportunity> testOppty = DataGenerator.createOpptys(opptyAccount, 200, true);
			System.assertNotEquals(null, testOppty);
			System.assertNotEquals(true, testOppty.isEmpty());
			
			List<Id> opptyIDs = new List<Id>();
			for(Opportunity oppr : testOppty){
				opptyIDs.add(oppr.Id);
			}
			
			List<Opportunity> opptyList = [SELECT Id FROM Opportunity WHERE Id IN :opptyIDs];
			System.assertNotEquals(null,opptyList);
			System.assertEquals(200,opptyList.size());
		}
	}
	
	@isTest static void testCreateTasks() {
		
		// Create running user
		User u = DataGenerator.createUsers(
			Definitions.PROFILE_SalesUser, 1, true)[0];
		
		System.runAs(u) {
			
			// Create account
			Account opptyAccount = DataGenerator.createAccounts(1, true)[0];
			System.assertNotEquals(null, opptyAccount);
			
			// Create oppty
			Opportunity oppty = DataGenerator.createOpptys(opptyAccount, 1, true)[0];
			System.assertNotEquals(null, oppty);
			
			List<Task> tasks;
			try {
				tasks = DataGenerator.createTasks(null, 1, false);
				System.assert(false, 'UNEXPECTED RESULT. EXPECTED EXCEPTION.');
			} catch (Exceptions.IllegalArgumentException e) {
				// EXPECTED RESULT
			} catch (Exception e) {
				System.assert(false, 'UNEXPECTED EXCEPTION. DETAILS: ' + e.getMessage());
			}
			System.assertEquals(null, tasks);

			// Test create no tasks
			tasks = DataGenerator.createTasks(oppty, 0, true);
			System.assertNotEquals(null, tasks);
			System.assertEquals(true, tasks.isEmpty());
			
			// Test create 1 tasks
			tasks = DataGenerator.createTasks(oppty, 1, true);
			System.assertNotEquals(null, tasks);
			System.assertNotEquals(true, tasks.isEmpty());
			
			Task testTask = [SELECT Id FROM Task WHERE Id = :tasks[0].Id];
			System.assertNotEquals(null, testTask);
			System.assertEquals(testTask.Id, tasks[0].Id);
			
			// Test create 200 tasks
			List<Task> testTasks = DataGenerator.createTasks(oppty, 200, true);
			System.assertNotEquals(null, testTasks);
			System.assertNotEquals(true, testTasks.isEmpty());
			
			List<Id> taskIds = new List<Id>();
			for(Task t : testTasks){
				taskIds.add(t.Id);
			}
			
			List<Task> testTaskList = [SELECT Id FROM Task WHERE Id IN :taskIds];
			System.assertNotEquals(null, testTaskList);
			System.assertEquals(200,testTaskList.size());
		}
	}

	@isTest static void testCreateEvents() {
		
		// Create running user
		User u = DataGenerator.createUsers(
			Definitions.PROFILE_SalesUser, 1, true)[0];
		
		System.runAs(u) {
			
			// Create account
			Account opptyAccount = DataGenerator.createAccounts(1, true)[0];
			System.assertNotEquals(null, opptyAccount);
			
			// Create oppty
			Opportunity oppty = DataGenerator.createOpptys(opptyAccount, 1, true)[0];
			System.assertNotEquals(null, oppty);
			
			List<Event> events;
			try {
				events = DataGenerator.createEvents(null, 1, false);
				System.assert(false, 'UNEXPECTED RESULT. EXPECTED EXCEPTION.');
			} catch (Exceptions.IllegalArgumentException e) {
				// EXPECTED RESULT
			} catch (Exception e) {
				System.assert(false, 'UNEXPECTED EXCEPTION. DETAILS: ' + e.getMessage());
			}
			System.assertEquals(null, events);

			// Test create no events
			events = DataGenerator.createEvents(oppty, 0, true);
			System.assertNotEquals(null, events);
			System.assertEquals(true, events.isEmpty());
			
			// Test create 1 events
			events = DataGenerator.createEvents(oppty, 1, true);
			System.assertNotEquals(null, events);
			System.assertNotEquals(true, events.isEmpty());
			
			Event testEvent = [SELECT Id FROM Event WHERE Id = :events[0].Id];
			System.assertNotEquals(null, testEvent);
			System.assertEquals(testEvent.Id, events[0].Id);
			
			// Test create 200 events
			List<Event> testEvents = DataGenerator.createEvents(oppty, 200, true);
			System.assertNotEquals(null, testEvents);
			System.assertNotEquals(true, testEvents.isEmpty());
			
			List<Id> eventIds = new List<Id>();
			for(Event e : testEvents){
				eventIds.add(e.Id);
			}
			
			List<Event> testEventList = [SELECT Id FROM Event WHERE Id IN : eventIds];
			System.assertNotEquals(null, testEventList);
			System.assertEquals(200,testEventList.size());
		}
	}
	
	@isTest(seeAllData=true) 
	static void testCreateProducts() {
		Integer recordsToCreate = 200;
		List<Product2> productList = DataGenerator.createProducts(recordsToCreate, true);
		System.assertNotEquals(null,productList);
		System.assertEquals(recordsToCreate,productList.size());
	}
	
	@isTest(seeAllData = true)
	static void testCreateOpptyProducts(){
		
		Account acc = DataGenerator.createAccounts(1, true)[0];
		Opportunity oppty = DataGenerator.createOpptys(acc, 1, true)[0];
		
		Integer recordsToCreate = 200;
		List<OpportunityLineItem> opptyProd = DataGenerator.createOpptyProducts(oppty, recordsToCreate, true);
		System.assertNotEquals(null,opptyProd);
		System.assertEquals(recordsToCreate, opptyProd.size());
	}
	
	@isTest(seeAllData = true)
	static void testCreateOpptyProducts2(){
		
		Account acc = DataGenerator.createAccounts(1, true)[0];
		Opportunity oppty = DataGenerator.createOpptys(acc, 1, true)[0];
		
		Integer recordsToCreate = 200;
		List<Product2> productList = DataGenerator.createProducts(recordsToCreate, true);
		List<OpportunityLineItem> opptyProd = DataGenerator.createOpptyProducts(oppty, productList, true);
		System.assertNotEquals(null,opptyProd);
		System.assertEquals(recordsToCreate, opptyProd.size());
	}
	
	@isTest static void testCreateContacts(){
		Integer recordsToCreate = 200;
		Account acc =  DataGenerator.createAccounts(1,true)[0];
		List<Contact> contactList = DataGenerator.createContacts(acc, recordsToCreate, true);
		System.assertNotEquals(null,contactList);
		
		List<Contact> contactListData = [Select Id,Name from Contact where AccountId =:acc.Id];
		System.assertNotEquals(null,contactListData);
		System.assertEquals(recordsToCreate, contactListData.size());
		
	}
	
	@isTest static void testCreateCases(){
		Integer recordsToCreate = 200;
		Account acc =  DataGenerator.createAccounts(1,true)[0];
		List<Case> caseList = DataGenerator.createCases(acc.Id, recordsToCreate, true);
		System.assertNotEquals(null,caseList);
		
		List<Case> caseListData = [Select Id,CaseNumber from Case where AccountId =:acc.Id];
		System.assertNotEquals(null,caseListData);
		System.assertEquals(recordsToCreate, caseListData.size());
		
	}	
	
	@isTest static void testCreateNotes(){
		Integer recordsToCreate = 200;
		Account acc =  DataGenerator.createAccounts(1,true)[0];
		List<Note> noteList = DataGenerator.createNotes(acc, recordsToCreate, true);
		System.assertNotEquals(null,noteList);
		
		List<Note> noteListData = [Select Id,Title,Body from Note where ParentId =:acc.Id];
		System.assertNotEquals(null,noteListData);
		System.assertEquals(recordsToCreate, noteListData.size());
		
	}
	
	@isTest static void testCreateOrders(){
		Integer recordsToCreate = 200;
		Account acc =  DataGenerator.createAccounts(1,true)[0];
		
		List<Order__c> orderList = DataGenerator.createOrders(acc.Id,Definitions.ORDER_STATUS_APPROVED, recordsToCreate, true);
		System.assertNotEquals(null,orderList);
		
		List<Order__c> orderListData = [Select Id,Site__c,Status__c from Order__c where Site__c =:acc.Id];
		System.assertNotEquals(null,orderListData);
		System.assertEquals(recordsToCreate, orderListData.size());
		
	}
	
	@isTest static void testCreateOrderItems(){
		Integer recordsToCreate = 200;
		Account acc =  DataGenerator.createAccounts(1,true)[0];
		List<Product2> productList = DataGenerator.createProducts(recordsToCreate, true);
		List<Asset> assetList = DataGenerator.createAssets(productList, acc.Id, Definitions.ORDER_STATUS_APPROVED, true);
		Order__c ordr = DataGenerator.createOrders(acc.Id,Definitions.ORDER_STATUS_APPROVED, recordsToCreate, true)[0];
		
		List<Order_Item__c> orderItemsList = DataGenerator.createOrderItems(ordr.Id, assetList, Definitions.ORDER_STATUS_APPROVED, true);
		System.assertNotEquals(null,orderItemsList);
		
		List<Order_Item__c> orderItemsListData = [Select Id,Name,Asset__c from Order_Item__c where  Order__c =:ordr.Id];
		System.assertNotEquals(null,orderItemsListData);
		System.assertEquals(recordsToCreate, orderItemsListData.size());
		
	}
	
	@isTest static void testCreateSObjectWithDefaultValues() {
		
		//  Test Invalid name
		Lead l;
		try {
			l = (Lead)DataGenerator.createSObjectWithDefaultValues('INVALID');
			System.assert(false, 'UNEXPECTED RESULT. EXPECTED ERROR.');
		} catch (Exception e) {
			// This was expected
		}
		System.assertEquals(null, l);
		
		// Get hospitality lead record type
		Id leadRecordType = Utilities.RecordTypeNameToId('Lead', Definitions.RECORDTYPE_HospitalityLeads);
		System.assertNotEquals(null, leadRecordType);
		
		// Test success
		l = (Lead)DataGenerator.createSObjectWithDefaultValues('Lead', leadRecordType);
		System.assertNotEquals(null, l);
	}
}