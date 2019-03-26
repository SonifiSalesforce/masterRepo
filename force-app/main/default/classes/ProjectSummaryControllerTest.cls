@isTest
public with sharing class ProjectSummaryControllerTest 
{
	static testMethod void testBasicSummary()
	{
		//Create Site
		Account acc = DataGenerator.createAccounts(1, true).get(0);
		
		//Create Order
		Order__c o = new Order__c(Site__c = acc.Id);
		insert o;
					
		Contract__c con = new Contract__c(Order__c = o.Id, Account_Name__c = acc.id);
		insert con;
		
		Product2 p2 = new Product2(Name = 'testProduct');
		insert p2;
		
		Order_Item__c oi1 = new Order_Item__c(Product__c = p2.Id, Order__c = o.Id, Status__c = 'Pending Installation Activate');
		//insert oi1;   jjackson 7/2014 consolidate records into a list and made one insert
		Order_Item__c oi2 = new Order_Item__c(Product__c = p2.Id, Order__c = o.Id, Status__c = 'Pending Installation Activate', Parent__c = oi1.Id);
		//insert oi2;
		Order_Item__c oi3 = new Order_Item__c(Product__c = p2.Id, Order__c = o.Id, Status__c = 'Pending Cancellation');
		//insert oi3;
		List<Order_Item__c> lstoi = new list<Order_Item__c>();
		lstoi.add(oi1);
		lstoi.add(oi2);
		lstoi.add(oi3);
		insert lstoi;
		
		
		Asset ass = new Asset(AccountId = acc.id, Product2Id = p2.id, Name = 'testAsset');
		insert ass;
		
		Work_Order__c wo = new Work_Order__c(Site__c = acc.Id);
		insert wo;
		
		Associated_Item__c ai1 = new Associated_Item__c(Work_Order__c = wo.Id, Order_Item__c = oi1.Id);
		//insert ai1;
		Associated_Item__c ai2 = new Associated_Item__c(Work_Order__c = wo.Id, Order_Item__c = oi2.Id);
		//insert ai2;
		Associated_Item__c ai3= new Associated_Item__c(Work_Order__c = wo.Id, Order_Item__c = oi3.Id);
		//insert ai3;
		List<Associated_Item__c> lstai = new list<Associated_Item__c>();
		lstai.add(ai1);
		lstai.add(ai2);
		lstai.add(ai3);
		insert lstai;
		
		PageReference pr = Page.Project_Summary;
		pr.getParameters().put('id',wo.Id);
		Test.setCurrentPageReference(pr);
		Test.startTest();
		
		ProjectSummaryController controller = new ProjectSummaryController(new ApexPages.StandardController(wo));
		
		Test.stopTest();
	}
}