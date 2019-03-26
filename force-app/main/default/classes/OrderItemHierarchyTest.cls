@isTest
public with sharing class OrderItemHierarchyTest 
{
	static testMethod void testInstallWorkOrderCreation()
	{
		Account acc = DataGenerator.createAccounts(1, true).get(0);
		Order__c o = DataGenerator.createOrders(acc.Id, 'Order Approved', 1, true).get(0);
		
		Order_Item__c oi1 = new Order_Item__c(Order__c = o.Id);
		insert oi1;
		Order_Item__c oi2 = new Order_Item__c(Order__c = o.Id, Parent__c = oi1.Id);
		insert oi2;
		
		//Create JSON of Ids
		List<Id> listId = new List<Id>();
		listId.add(oi1.Id);
		listId.add(oi2.Id);
		
		PageReference pr = Page.OrderItemHierarchy;
		pr.getParameters().put('id',o.Id);
		Test.setCurrentPageReference(pr);
		Test.startTest();
		OrderItemHierarchyExtension controller = new OrderItemHierarchyExtension(new ApexPages.StandardController(o));
		controller.selectedKeysJSON = JSON.serialize(listId);
		controller.selectedWoRt = 'Install';
		controller.createWorkOrder();
		List<ApexPages.Message> msgs = Apexpages.getMessages();
		system.assert(msgs.size() == 0, msgs);
		Test.stopTest();
		
		//There should be a work order and 2 associated items
		List<Work_Order__c> woList = [SELECT Id from Work_Order__c];
		system.assert(woList.size() == 1, 'There should be a Work Order, there are '+woList);
		List<Associated_Item__c> aiList = [SELECT Id from Associated_Item__c WHERE Work_Order__c = :woList[0].Id];
		system.assert(aiList.size() == 2, 'There should be 2 Associated Items attached to Work Order, there are '+aiList.size());
	}
}