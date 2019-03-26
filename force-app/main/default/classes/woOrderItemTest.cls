@isTest
public class woOrderItemTest
{
    static testMethod void testOrderItemTestCreation()
    {
    	//jjackson due to tests failing on soql query limits being exceeded, cleaned this up to cut down on dml actions
        Account acc = DataGenerator.createAccounts(1,true)[0];
        Order__c woOrder = new Order__c(Name = 'Work Order related Order', Site__c = acc.Id);
        //insert woOrder;
        Order__c testOrder = new Order__c(Site__c = acc.Id);
        List<Order__c> lstorder = new list<Order__c>();
        lstorder.add(woOrder);
        lstorder.add(testOrder);
        insert lstorder;
        
        Order_Item__c woOI1 = new Order_Item__c(Name = 'Work Order related OI', Status__c = 'Pending Installation Activate', Order__c = woOrder.Id);
        //insert woOI1;
        Order_Item__c woOI2 = new Order_Item__c(Name = 'Work Order related OI 2', Status__c = 'Pending Installation Activate', Order__c = woOrder.Id, Parent__c = woOI1.Id);
        //insert woOI2;
        Order_Item__c testOI1 = new Order_Item__c(Order__c = testOrder.Id);
        //insert testOI1;
        Order_Item__c testOI2 = new Order_Item__c(Order__c = testOrder.Id, Parent__c = testOI1.Id);
        //insert testOI2;

        List<Order_Item__c> lstoi = new list<Order_Item__c>();
        lstoi.add(woOI1);
        lstoi.add(woOI2);
        lstoi.add(testOI1);
        lstoi.add(testOI2);
        insert lstoi;
        
        Work_Order__c testWorkOrder = new Work_Order__c(Site__c = acc.Id);
        insert testWorkOrder;
        
        Associated_Item__c testAI1 = new Associated_Item__c(Order_Item__c = woOI1.Id, Work_Order__c = testWorkOrder.Id);
        //insert testAI1;
        Associated_Item__c testAI2 = new Associated_Item__c(Order_Item__c = woOI2.Id, Work_Order__c = testWorkOrder.Id);
        //insert testAI2;
        List<Associated_Item__c> lstai = new list<Associated_Item__c>();
        lstai.add(testAI1);
        lstai.add(testAI2);
        insert lstai;
       
        Set<Id> oiIds = new Set<Id>();
        oiIds.add(testOi1.Id);
        oiIds.add(testOi2.Id);
        
        String jsonSelectedIds = JSON.serialize(oiIds);

        PageReference pr = Page.woOrderItemSelection;
        pr.getParameters().put('id',testWorkOrder.id);
        Test.setCurrentPageReference(pr);
        Test.startTest();
            woOrderItemExtension controller = new woOrderItemExtension(new ApexPages.standardController(testWorkOrder));
            controller.SelectedIds = jsonSelectedIds;
            controller.transferOrderItems();
       
       		List<Associated_Item__c> aiList = [SELECT Id from Associated_Item__c WHERE Work_Order__c = :testWorkOrder.Id];
        	system.assert(aiList.size() == 4, 'There should be 4 Associated Items on Work Order, there are '+aiList.size());

        Test.stopTest();

   		aiList = [SELECT Id from Associated_Item__c WHERE Work_Order__c = :testWorkOrder.Id];
    	system.assert(aiList.size() == 4, 'There should be 2 Associated Items on Work Order, there are '+aiList.size());
			
    }
}