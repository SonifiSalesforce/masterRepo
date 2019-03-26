@isTest
private class SiteSurveyTriggerLogicTest {
/*
    static testMethod void createTVTypeSucess(){
		//create test data
		Account acc = DataGenerator.createAccounts(1, true).get(0);
		Account acc1 = DataGenerator.createAccounts(1, true).get(0);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Opportunity opp1 = DataGenerator.createOpptys(acc1, 1, true).get(0);
        insert new TV_Type__c(Model__c='TestMake', Make__c='testMake', Quantity__c=50, Site__c =acc.id);
        insert new TV_Type__c(Model__c='TestMake2', Make__c='testMake2', Quantity__c=50, Site__c =acc.id);
       
        Test.startTest();
        insert new Site_Survey__c(Opportunity__c = opp.id);
        insert new Site_Survey__c(Opportunity__c = opp1.id);
        Test.stopTest();
        
        List<TV_Type__c> types = [SELECT id FROM TV_Type__c];
        
        System.assertEquals(4, types.size());
    }
  */ 
  /* jjackson 2/2016 Don't need to test this because the code for no duplicates is commented out 
     static testMethod void noDupsOfSiteSurvey(){
		//create test data
		String errorMessage;
		Account acc = DataGenerator.createAccounts(1, true).get(0);
		Account acc1 = DataGenerator.createAccounts(1, true).get(0);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, true).get(0);
        Opportunity opp1 = DataGenerator.createOpptys(acc1, 1, true).get(0);
        Site_Survey__c site = new Site_Survey__c(Opportunity__c = opp1.id);
        insert site;
       
        Test.startTest();
        try{
        insert new Site_Survey__c(Opportunity__c = opp.id);
		insert new Site_Survey__c(Opportunity__c = opp1.id);
        } catch (Exception e ){
        	errorMessage = e.getMessage();
		}
        Test.stopTest();
        
        List<Site_Survey__c> sites = [SELECT id FROM Site_Survey__c];
        
        System.assertEquals(2, sites.size());
    }
    */
    
    static testMethod void updateRelatedBids(){
		//create test data
        Site_Survey__c site1 = new Site_Survey__c();
        Site_Survey__c site2 = new Site_Survey__c();
        insert new List<Site_Survey__c>{site1, site2};
        Bid__c bid1 = new Bid__c(Site_Survey__c = site1.id);
        Bid__c bid2 = new Bid__c(Site_Survey__c = site2.id);
        insert new List<Bid__c>{bid1, bid2};
       
        Test.startTest();
        site1.Admin_Additional_Comments__c = 'test comment';
        site2.Approval_Status__c = 'Pending';
        update new List<Site_Survey__c>{site1, site2};
        Test.stopTest();
        
        Map<Id,Bid__c> bids= new Map<Id, Bid__c>([SELECT id, Approval_Status__c FROM Bid__c]);
        
        System.assertEquals(null, bids.get(bid1.id).Approval_Status__c);
        System.assertEquals('Pending', bids.get(bid2.id).Approval_Status__c);
    }
    /*
    static testMethod void updateRelatedParts(){
		//create test data
        Site_Survey__c site1 = new Site_Survey__c();
        Site_Survey__c site2 = new Site_Survey__c();
        insert new List<Site_Survey__c>{site1, site2};
        Part_List__c part1 = new Part_List__c(Site_Survey__c = site1.id);
        Part_List__c part2 = new Part_List__c(Site_Survey__c = site2.id);
        insert new List<Part_List__c>{part1, part2};
       
        Test.startTest();
        site1.Admin_Additional_Comments__c = 'test comment';
        site2.Approval_Status__c = 'Pending';
        update new List<Site_Survey__c>{site1, site2};
        Test.stopTest();
        
        Map<Id,Part_List__c> parts= new Map<Id, Part_List__c>([SELECT id, Approval_Status__c FROM Part_List__c]);
        
        System.assertEquals(null, parts.get(part1.id).Approval_Status__c);
        System.assertEquals('Pending', parts.get(part2.id).Approval_Status__c);
    }*/
}