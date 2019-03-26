@isTest
public with sharing class WorkOrderRelatedCreationTest {
	static testMethod void testWorkOrderCreation()
	{
		ChildWorkOrderRecordTypes__c cs = new ChildWorkOrderRecordTypes__c(Name = 'Rack Build');
		insert cs;
		
		//Get Work Order Parent Record type
        Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
		Work_Order__c wo = new Work_Order__c(RecordTypeId = workOrderRecordType);
		insert wo;
		Order_Item__c oi = new Order_Item__c();
		insert oi;
		Associated_Item__c ai = new Associated_Item__c(Work_Order__c = wo.Id, Order_Item__c = oi.Id);
		insert ai;
		PageReference pr = Page.WorkOrderRelatedCreation;
		pr.getParameters().put('Id',wo.id);
		Test.setCurrentPageReference(pr);
		Test.startTest();
		List<Work_Order__c> temp = new List<Work_Order__c>();
		temp.add(wo);
		WorkOrderRelatedCreationExtension con = new WorkOrderRelatedCreationExtension(new ApexPages.StandardSetController(temp));
		for(WorkOrderRelatedCreationExtension.RecordTypeSelect sel : con.WorkOrderTypes)
		{
			sel.checked = true;
		}
		con.saveRelatedWorkOrders();
		Test.stopTest();
		List<Work_Order__c> children = [SELECT Id from Work_Order__c WHERE Parent_Work_Order__c = :wo.Id];
		system.assert(children.size() == 1, 'There should have been one child work order created, there are '+children.size());
	}
}