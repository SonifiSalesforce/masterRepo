@isTest
public class CustomOpportunityLogicTest {
	
	@isTest (SeeAllData=true) // MUST set SeeAllData to create oppty products from Pricebook2 
	static void testChangeStage() {
		
		// Create account
		Integer accountsToCreate = 1;
		Account acct = DataGenerator.createAccounts(accountsToCreate, true)[0];
		System.assertNotEquals(null, acct);
		
		// Create opptys
		Integer opptysToCreate = 2;
		List<Opportunity> opptyList = DataGenerator.createOpptys(acct, opptysToCreate, true);
		System.assertNotEquals(null, opptyList);
		System.assertNotEquals(true, opptyList.isEmpty());
		System.assertEquals(opptysToCreate, opptyList.size());
		
		// Create oppty products
		Integer productsToCreate = 3;
		List<Id> opptyIdList = new List<Id>();
		List<PricebookEntry> productList = DataGenerator.createPricebookEntries(productsToCreate, true);
		List<OpportunityLineItem> opptyProductList = new List<OpportunityLineItem>();
		for (Integer i = 0; i < opptyList.size(); i++) {
			opptyIdList.add(opptyList[i].Id);
			opptyProductList.addAll(DataGenerator.createOpptyProducts(opptyList[i], productList, false));
		}
		System.assertNotEquals(null, opptyProductList);
		System.assertNotEquals(true, opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate * productsToCreate, opptyProductList.size());
		insert opptyProductList;
		
		// Test invalid oppty Id list
		try {
			CustomOpportunityLogic.changeStage(null, null);
			System.assert(false, 'UNEXPECTED SUCCESS. EXPECTED EXCEPTION.');
		} catch (Exceptions.IllegalArgumentException illEx) {
			// Expected outcome
		} catch (Exception e) {
			System.assert(false, 'UNEXPECTED EXCEPTION. DETAILS: ' + e.getMessage());
		}
		
		// Test invalid stage
		try {
			CustomOpportunityLogic.changeStage(opptyIdList, null);
			System.assert(false, 'UNEXPECTED SUCCESS. EXPECTED EXCEPTION.');
		} catch (Exceptions.IllegalArgumentException illEx) {
			// Expected outcome
		} catch (Exception e) {
			System.assert(false, 'UNEXPECTED EXCEPTION. DETAILS: ' + e.getMessage());
		}
		
		// Change Stage
		System.assertNotEquals(Definitions.OPPTY_STAGE_ProposalSent, opptyList[0].StageName);
		CustomOpportunityLogic.changeStage(opptyIdList, Definitions.OPPTY_STAGE_ProposalSent);
		
		// Confirm that the stage was changed
		opptyList = [SELECT Id, StageName FROM Opportunity WHERE Id IN :opptyIdList];
		System.assertEquals(Definitions.OPPTY_STAGE_ProposalSent, opptyList[0].StageName);
	}

	@isTest (SeeAllData=true) // MUST set SeeAllData to create oppty products from Pricebook2 
	static void testCloseOpptys() {
		
		// Create account
		Integer accountsToCreate = 1;
		Account acct = DataGenerator.createAccounts(accountsToCreate, true)[0];
		System.assertNotEquals(null, acct);
		
		// Create opptys
		Integer opptysToCreate = 2;
		List<Opportunity> opptyList = DataGenerator.createOpptys(acct, opptysToCreate, true);
		System.assertNotEquals(null, opptyList);
		System.assertNotEquals(true, opptyList.isEmpty());
		System.assertEquals(opptysToCreate, opptyList.size());
		
		OpportunityContactRole oppConRole = new OpportunityContactRole();
		List<OpportunityContactRole> oppConRoleList = new List<OpportunityContactRole>();
		
		List<Contact> cList = DataGenerator.createContacts(acct, opptysToCreate, true);
		for(Integer i=0;i<opptyList.size();i++){
			OpportunityContactRole ocr = oppConRole.clone(false,true);
			ocr.OpportunityId = opptyList[i].Id;
			ocr.ContactId = cList[i].Id; 
			ocr.IsPrimary = true;
			oppConRoleList.add(ocr);
		}
		upsert cList;
		upsert oppConRoleList;
		
		
		// Create oppty products
		Integer productsToCreate = 3;
		List<Id> opptyIdList = new List<Id>();
		List<PricebookEntry> productList = DataGenerator.createPricebookEntries(productsToCreate, true);
		List<OpportunityLineItem> opptyProductList = new List<OpportunityLineItem>();
		for (Integer i = 0; i < opptyList.size(); i++) {
			opptyIdList.add(opptyList[i].Id);
			opptyProductList.addAll(DataGenerator.createOpptyProducts(opptyList[i], productList, false));
		}
		System.assertNotEquals(null, opptyProductList);
		System.assertNotEquals(true, opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate * productsToCreate, opptyProductList.size());
		insert opptyProductList;
		
/*
		// Create oppty products
		Integer productsToCreate = 3;
		List<Id> opptyIdList = new List<Id>();
		List<OpportunityLineItem> opptyProductList = new List<OpportunityLineItem>();
		for (Opportunity oppty : opptyList) {
			opptyIdList.add(oppty.Id);
			List<OpportunityLineItem> opptyProducts = DataGenerator.createOpptyProducts(oppty, productsToCreate, false);
			System.assertNotEquals(null, opptyProducts);
			System.assertNotEquals(true, opptyProducts.isEmpty());
			System.assertEquals(productsToCreate, opptyProducts.size());
			opptyProductList.addAll(opptyProducts);			
		}
		System.assertNotEquals(null, opptyProductList);
		System.assertNotEquals(true, opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate * productsToCreate, opptyProductList.size());
		insert opptyProductList;
*/
		
		// Test invalid oppty Id list
		try {
			CustomOpportunityLogic.closeOpportunities(null, null);
			System.assert(false, 'UNEXPECTED SUCCESS. EXPECTED EXCEPTION.');
		} catch (Exceptions.IllegalArgumentException illEx) {
			// Expected outcome
		} catch (Exception e) {
			System.assert(false, 'UNEXPECTED EXCEPTION. DETAILS: ' + e.getMessage());
		}
		
		// Test invalid stage
		try {
			CustomOpportunityLogic.closeOpportunities(opptyIdList, null);
			System.assert(false, 'UNEXPECTED SUCCESS. EXPECTED EXCEPTION.');
		} catch (Exceptions.IllegalArgumentException illEx) {
			// Expected outcome
		} catch (Exception e) {
			System.assert(false, 'UNEXPECTED EXCEPTION. DETAILS: ' + e.getMessage());
		}
		
		// Close opportunities
		System.assertNotEquals(Definitions.OPPTY_STAGE_ClosedWon, opptyList[0].StageName);
		CustomOpportunityLogic.closeOpportunities(opptyIdList, CustomOpportunityLogic.ClosedStage.CLOSED_WON);
		
		// Confirm that the stage was changed
		opptyList = [SELECT Id, StageName FROM Opportunity WHERE Id IN :opptyIdList];
		System.assertEquals(Definitions.OPPTY_STAGE_ClosedWon, opptyList[0].StageName);
	}
	
	@isTest (SeeAllData=true) // MUST set SeeAllData to create oppty products from Pricebook2 
	static void testCloseOpportunitiesByProduct() {
		
		// Create account
		Integer accountsToCreate = 1;
		Account acct = DataGenerator.createAccounts(accountsToCreate, true)[0];
		System.assertNotEquals(null, acct);
		
		// Create opptys
		Integer opptysToCreate = 2;
		List<Opportunity> opptyList = DataGenerator.createOpptys(acct, opptysToCreate, true);
		System.assertNotEquals(null, opptyList);
		System.assertNotEquals(true, opptyList.isEmpty());
		System.assertEquals(opptysToCreate, opptyList.size());
		
		// Create oppty products
		Integer productsToCreate = 3;
		List<Id> opptyIdList = new List<Id>();
		List<PricebookEntry> productList = DataGenerator.createPricebookEntries(productsToCreate, true);
		List<OpportunityLineItem> opptyProductList = new List<OpportunityLineItem>();
		for (Integer i = 0; i < opptyList.size(); i++) {
			opptyIdList.add(opptyList[i].Id);
			opptyProductList.addAll(DataGenerator.createOpptyProducts(opptyList[i], productList, false));
		}
		System.assertNotEquals(null, opptyProductList);
		System.assertNotEquals(true, opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate * productsToCreate, opptyProductList.size());
		insert opptyProductList;
		
/*
		// Create oppty products
		Integer productsToCreate = 3;
		List<Id> opptyIdList = new List<Id>();
		List<OpportunityLineItem> opptyProductList = new List<OpportunityLineItem>();
		for (Opportunity oppty : opptyList) {
			opptyIdList.add(oppty.Id);
			List<OpportunityLineItem> opptyProducts = DataGenerator.createOpptyProducts(oppty, productsToCreate, false);
			System.assertNotEquals(null, opptyProducts);
			System.assertNotEquals(true, opptyProducts.isEmpty());
			System.assertEquals(productsToCreate, opptyProducts.size());
			opptyProductList.addAll(opptyProducts);			
		}
		System.assertNotEquals(null, opptyProductList);
		System.assertNotEquals(true, opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate * productsToCreate, opptyProductList.size());
		insert opptyProductList;
*/
		
		// Test invalid oppty Id list
		try {
			CustomOpportunityLogic.CloseOpportunitiesByProduct(null, null);
			System.assert(false, 'UNEXPECTED SUCCESS. EXPECTED EXCEPTION.');
		} catch (Exceptions.IllegalArgumentException illEx) {
			// Expected outcome
		} catch (Exception e) {
			System.assert(false, 'UNEXPECTED EXCEPTION. DETAILS: ' + e.getMessage());
		}
		
		// Test invalid stage map
		try {
			CustomOpportunityLogic.CloseOpportunitiesByProduct(opptyIdList, null);
			System.assert(false, 'UNEXPECTED SUCCESS. EXPECTED EXCEPTION.');
		} catch (Exceptions.IllegalArgumentException illEx) {
			// Expected outcome
		} catch (Exception e) {
			System.assert(false, 'UNEXPECTED EXCEPTION. DETAILS: ' + e.getMessage());
		}
		
		// Build map
		Map<Id, CustomOpportunityLogic.OpptyProductStage> productStageMap = new Map<Id, CustomOpportunityLogic.OpptyProductStage>();
		CustomOpportunityLogic.OpptyProductStage productStage = new CustomOpportunityLogic.OpptyProductStage();
		
		productStage.productId = opptyProductList[0].PricebookEntryId;
		productStage.productName = 'Test Product 1';
		productStage.stage = Definitions.OPPTY_STAGE_ClosedWon;
		productStage.reason = 'Product Stage Reson for ClosedWon';
		productStageMap.put(productStage.productId, productStage);
		
		productStage.productId = opptyProductList[1].PricebookEntryId;
		productStage.productName = 'Test Product 2';
		productStage.stage = Definitions.OPPTY_STAGE_ClosedLost;
		productStage.reason = 'Product Stage Reson for ClosedLost';
		productStageMap.put(productStage.productId, productStage);
		
		// Close opportunities
		CustomOpportunityLogic.CloseOpportunitiesByProduct(opptyIdList, productStageMap);
		
		// Confirm that the stage was changed
		// opptyList = [SELECT Id, StageName FROM Opportunity WHERE Id IN :opptyIdList];
		// System.assertEquals(Definitions.OPPTY_STAGE_ClosedWon, opptyList[0].StageName);
	}





	@isTest (SeeAllData=true) // MUST set SeeAllData to create oppty products from Pricebook2 
	static void testCreateSiteSurveyFromOpportunity() {
		
		// Create account
		Integer accountsToCreate = 1;
		Account acct = DataGenerator.createAccounts(accountsToCreate, true)[0];
		System.assertNotEquals(null, acct);
		
		// Create opptys
		Integer opptysToCreate = 2;
		List<Opportunity> opptyList = DataGenerator.createOpptys(acct, opptysToCreate, true);
		System.assertNotEquals(null, opptyList);
		System.assertNotEquals(true, opptyList.isEmpty());
		System.assertEquals(opptysToCreate, opptyList.size());
		Integer counter = 0;
		
		for (Integer i = 0; i < opptyList.size(); i++) {
            CustomOpportunityLogic.createSiteSurvey(opptyList[i].Id, counter);
            counter = counter +1;
		}


	}









}