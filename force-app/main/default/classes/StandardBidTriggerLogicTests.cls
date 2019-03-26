@isTest
private class StandardBidTriggerLogicTests {

    static testMethod void updateBidLineItems() {
    	//create test data
        Bid__c bid1 = new Bid__c(Approval_Status__c = 'Pending');
        Bid__c bid2 = new Bid__c(Approval_Status__c = 'Approved');
        insert new List<Bid__c>{bid1, bid2};
        
        Bid_Line_Item__c bli1 = new Bid_Line_Item__c(Bid__c = bid1.id, Conversion_Date__c = Date.Today().addDays(-30));
        Bid_Line_Item__c bli2 = new  Bid_Line_Item__c(Bid__c = bid2.id, Conversion_Date__c = Date.Today().addDays(-30));
        insert new List<Bid_Line_Item__c>{bli1, bli2};
        
        Test.startTest();
        bid1.Approval_Status__c = 'Approved';
        bid2.Approval_Status__c = 'Pending';
        update new List<Bid__c>{bid1, bid2};
        Test.stopTest();
        
        //requery the data
        Map<Id, Bid_Line_Item__c> bidLineMap = new Map<Id, Bid_Line_Item__c>([SELECT id, Conversion_Date__c  FROM Bid_Line_Item__c]);
        
        //assertions
        System.assertEquals(Date.Today(), bidLineMap.get(bli1.id).Conversion_Date__c);
        System.assertEquals(Date.Today().addDays(-30), bidLineMap.get(bli2.id).Conversion_Date__c);
    }
    
    static testMethod void updateRelatedPartListSelected(){
    	//create test data
    	Site_Survey__c site = new Site_Survey__c();
    	insert site;
    	Part_List__c p1 = new Part_List__c(Site_Survey__c = site.id);
    	Part_List__c p2 = new Part_List__c(Site_Survey__c = site.id);
    	insert new List<Part_List__c>{p1, p2};
    	
    	Bid__c b1 = new Bid__c(Site_Survey__c = site.id, Part_List__c = p1.id);
    	Bid__c b2 = new Bid__c(Site_Survey__c = site.id, Part_List__c = p2.id, Selected_Bid__c = true);
    	
    	Test.startTest();
    	insert new List<Bid__c>{b1,b2};
    	b1.Selected_Bid__c = true;
    	update b1;
    	
    	Test.stopTest();
    	
    	//query for the results
    	List<Part_List__c> parts = [SELECT id, Part_List_Selected__c FROM Part_List__c];
    	
    	//assertions
    	System.assertEquals(true, parts[0].Part_List_Selected__c);
    	System.assertEquals(true, parts[1].Part_List_Selected__c);
    }
}