@isTest public class OpportunityListControllerTest {
	
	@isTest static void testInit() {
		
		// Create oppty list controller
		OpportunityListController controller = new OpportunityListController();
		
		//Setting values for Custom Settings
		List<String> stageNameList = new List<String>();
		stageNameList.add('Assigned to Rep');
		stageNameList.add('Contract Requested');
		stageNameList.add('Contract Sent');
		stageNameList.add('Desktop Review Required');
		stageNameList.add('MATV Results Sent');
		
		List<OpportunityStage__c> stageList = new List<OpportunityStage__c>();
		for(Integer i=0;i<2;i++){
			OpportunityStage__c opportunityStages = new OpportunityStage__c();
			opportunityStages.Name =stageNameList[i];
			opportunityStages.SortOrder__c = i+1;
			stageList.add(opportunityStages);
		}
		upsert stageList;
		
		// Check select option lists
		System.assertNotEquals(null, controller.opportunityStages);
		System.assertNotEquals(null, controller.opportunityCloseStages);
	}
	
	@isTest static void testGetRecordList() {
		
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
		
		// Init page
		OpportunitiesExtension pageExt = new OpportunitiesExtension(new ApexPages.StandardController(opptyList[0]));
		OpportunityListController listCtrl = new OpportunityListController();
		listCtrl.cloneableInterfaceObject = pageExt;
		listCtrl.showAllRecords = true;
		
		// Get records
		List<Opportunity> opptys = listCtrl.getRecordList();
		System.assertNotEquals(null, opptys);
		System.assertNotEquals(true, opptys.isEmpty());
		System.assertEquals(opptysToCreate - 1, opptys.size());
	}

	@isTest (SeeAllData=true) // MUST set SeeAllData to create oppty products from Pricebook2 
	static void testReadOpptyProducts() {
		
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
		List<OpportunityLineItem> opptyProductList = DataGenerator.createOpptyProducts(opptyList[0], opptysToCreate, false);
		System.assertNotEquals(null, opptyProductList);
		System.assertNotEquals(true, opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate, opptyProductList.size());
		List<Id> opptyIdList = new List<Id>();
		for (Integer i = 0; i < opptyList.size(); i++) {
			opptyIdList.add(opptyList[i].Id); 
			opptyProductList[i].OpportunityId = opptyList[i].Id; 
		}
		insert opptyProductList;
		
		// Init page
		PageReference pageRef = Page.Opportunities;
		Test.setCurrentPage(pageRef);
		OpportunitiesExtension pageExt = new OpportunitiesExtension(new ApexPages.StandardController(opptyList[0]));
		OpportunityListController listCtrl = new OpportunityListController();
		listCtrl.cloneableInterfaceObject = pageExt;
		listCtrl.showAllRecords = true;
		
		// Read oppty products
		System.assertEquals(null, listCtrl.opptyProductList);
		ApexPages.currentPage().getParameters().put('opportunityIdList', String.join(opptyIdList, ','));
		ApexPages.currentPage().getParameters().put('newStage', Definitions.OPPTY_STAGE_ProposalSent);
		listCtrl.readOpportunityProducts();
		System.assertNotEquals(null, listCtrl.opptyProductList);
		System.assertNotEquals(true, listCtrl.opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate, listCtrl.opptyProductList.size());
	}

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
		List<OpportunityLineItem> opptyProductList = DataGenerator.createOpptyProducts(opptyList[0], opptysToCreate, false);
		System.assertNotEquals(null, opptyProductList);
		System.assertNotEquals(true, opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate, opptyProductList.size());
		List<Id> opptyIdList = new List<Id>();
		for (Integer i = 0; i < opptyList.size(); i++) {
			opptyIdList.add(opptyList[i].Id); 
			opptyProductList[i].OpportunityId = opptyList[i].Id; 
		}
		insert opptyProductList;
		
		// Init page
		PageReference pageRef = Page.Opportunities;
		Test.setCurrentPage(pageRef);
		OpportunitiesExtension pageExt = new OpportunitiesExtension(new ApexPages.StandardController(opptyList[0]));
		OpportunityListController listCtrl = new OpportunityListController();
		listCtrl.cloneableInterfaceObject = pageExt;
		listCtrl.showAllRecords = true;
		
		// Change Stage
		ApexPages.currentPage().getParameters().put('opportunityIdList', String.join(opptyIdList, ','));
		ApexPages.currentPage().getParameters().put('newStage', Definitions.OPPTY_STAGE_ProposalSent);
		listCtrl.changeOpportunityStage();
		
		// Confirm that the stage was changed
		opptyList = [SELECT Id, StageName FROM Opportunity WHERE Id IN :opptyIdList];
		System.assertEquals(Definitions.OPPTY_STAGE_ProposalSent, opptyList[0].StageName);
	}
	
	@isTest (SeeAllData=true) // MUST set SeeAllData to create oppty products from Pricebook2 
	static void testCloseOpportunity() {
		
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
		List<OpportunityLineItem> opptyProductList = DataGenerator.createOpptyProducts(opptyList[0], opptysToCreate, false);
		System.assertNotEquals(null, opptyProductList);
		System.assertNotEquals(true, opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate, opptyProductList.size());
		List<Id> opptyIdList = new List<Id>();
		for (Integer i = 0; i < opptyList.size(); i++) {
			opptyIdList.add(opptyList[i].Id); 
			opptyProductList[i].OpportunityId = opptyList[i].Id; 
		}
		insert opptyProductList;
		
		// Init page
		PageReference pageRef = Page.Opportunities;
		Test.setCurrentPage(pageRef);
		OpportunitiesExtension pageExt = new OpportunitiesExtension(new ApexPages.StandardController(opptyList[0]));
		OpportunityListController listCtrl = new OpportunityListController();
		listCtrl.cloneableInterfaceObject = pageExt;
		listCtrl.showAllRecords = true;
		
		// Close oppty
		ApexPages.currentPage().getParameters().put('opportunityIdList', String.join(opptyIdList, ','));
        ApexPages.currentPage().getParameters().put('stage', Definitions.OPPTY_STAGE_ClosedLost);
		ApexPages.currentPage().getParameters().put('closeReason', 'Other');
		ApexPages.currentPage().getParameters().put('closeDescription', 'Just because');
		listCtrl.closeOpportunity();
		
		// Confirm that the stage was changed
		opptyList = [SELECT Id, StageName FROM Opportunity WHERE Id IN :opptyIdList];
		System.assertEquals(Definitions.OPPTY_STAGE_ClosedLost, opptyList[0].StageName);
	}

	@isTest (SeeAllData=true) // MUST set SeeAllData to create oppty products from Pricebook2 
	static void testCloseOpportunityByProduct() {
		
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
		List<OpportunityLineItem> opptyProductList = DataGenerator.createOpptyProducts(opptyList[0], opptysToCreate, false);
		System.assertNotEquals(null, opptyProductList);
		System.assertNotEquals(true, opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate, opptyProductList.size());
		List<Id> opptyIdList = new List<Id>();
		for (Integer i = 0; i < opptyList.size(); i++) {
			opptyIdList.add(opptyList[i].Id); 
			opptyProductList[i].OpportunityId = opptyList[i].Id; 
		}
		insert opptyProductList;
		
		// Init page
		PageReference pageRef = Page.Opportunities;
		Test.setCurrentPage(pageRef);
		OpportunitiesExtension pageExt = new OpportunitiesExtension(new ApexPages.StandardController(opptyList[0]));
		OpportunityListController listCtrl = new OpportunityListController();
		listCtrl.cloneableInterfaceObject = pageExt;
		listCtrl.showAllRecords = true;
		
		// Build list
		List<CustomOpportunityLogic.OpptyProductStage> productStageList = new List<CustomOpportunityLogic.OpptyProductStage>();
		
		CustomOpportunityLogic.OpptyProductStage productStage = new CustomOpportunityLogic.OpptyProductStage();
		productStage.productId = opptyProductList[0].PricebookEntryId;
		productStage.productName = 'Test Product 1';
		productStage.stage = Definitions.OPPTY_STAGE_ClosedWon;
		productStageList.add(productStage);
		
		productStage = new CustomOpportunityLogic.OpptyProductStage();
		productStage.productId = opptyProductList[1].PricebookEntryId;
		productStage.productName = 'Test Product 2';
		productStage.stage = Definitions.OPPTY_STAGE_ClosedLost;
		productStageList.add(productStage);
		
		ApexPages.currentPage().getParameters().put('opportunityIdList', String.join(opptyIdList, ','));
        ApexPages.currentPage().getParameters().put('stageChangeJson', JSON.serialize(productStageList));
        
		// Read oppty products
		listCtrl.readOpportunityProducts();
		System.assertNotEquals(null, listCtrl.opptyProductList);
		System.assertNotEquals(true, listCtrl.opptyProductList.isEmpty());
		System.assertEquals(opptysToCreate, listCtrl.opptyProductList.size());
		
		// Close oppty products
        System.debug('opptyIdList: ' + String.join(opptyIdList, ','));
        System.debug('Stage JSON: ' + JSON.serialize(productStageList));
		listCtrl.closeOpportunityByProduct();
		
		// Confirm that the stage was changed
		// opptyList = [SELECT Id, StageName FROM Opportunity WHERE Id IN :opptyIdList];
		// System.assertEquals(Definitions.OPPTY_STAGE_ClosedWON, opptyList[0].StageName);
	}
	
	
	@isTest static void testSortByHeader(){
		Integer opptysToCreate = 2;
		Account acct = DataGenerator.createAccounts(opptysToCreate, true)[0];
		List<Opportunity> opptyList = DataGenerator.createOpptys(acct, opptysToCreate, true);
		OpportunitiesExtension pageExt = new OpportunitiesExtension(new ApexPages.StandardController(opptyList[0]));
		OpportunityListController controller = new OpportunityListController();
		
		controller.cloneableInterfaceObject = pageExt;
		controller.showAllRecords = true;
		
		PageReference pageRef = Page.Opportunities;
		pageRef.getParameters().put('sortColumn','OpptyName');
		Test.setCurrentPage(pageRef);
		
		for(Opportunity o : opptyList){
			o.Name = 'Opportunity Name';
			o.CloseDate = System.now().addDays(1).date();
			o.StageName = 'Stage Name';
			
		}
		upsert opptyList;
		
		List<Opportunity> getRecordList = controller.getRecordList();
		System.assertNotEquals(null,getRecordList);
		
		PageReference sortByHeader = controller.sortByHeader();
		System.assertEquals(null,sortByHeader);
		
		pageRef.getParameters().put('sortColumn','CloseDate');
		Test.setCurrentPage(pageRef);
		sortByHeader = controller.sortByHeader();
		System.assertEquals(null,sortByHeader);
		
		pageRef.getParameters().put('sortColumn','SiteName');
		Test.setCurrentPage(pageRef);
		sortByHeader = controller.sortByHeader();
		System.assertEquals(null,sortByHeader);
		
		pageRef.getParameters().put('sortColumn','StageName');
		Test.setCurrentPage(pageRef);
		sortByHeader = controller.sortByHeader();
		System.assertEquals(null,sortByHeader);
		
		pageRef.getParameters().put('sortColumn','RoomCount');
		Test.setCurrentPage(pageRef);
		sortByHeader = controller.sortByHeader();
		System.assertEquals(null,sortByHeader);
		
	}
	
}