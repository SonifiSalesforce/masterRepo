@isTest
public with sharing class SubscriptionItemHierarchyTest {
   static testMethod void hierarchyDeleteTest()
    {
    	List<Product2> products = new List<Product2>(); 
    	Product2 p = new Product2(Name = 'Test Product');
        products.add(p);
        Product2 p2 = new Product2(Name = 'Test Product2');
        products.add(p2);
        insert products;    	
        Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract con = new Contract(AccountId = acc.id);
        insert con;       
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
           Name__c = 'Test Product Parent',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p.Id,
           Status__c = 'Contract Sent',
           SBQQ__SubscriptionStartDate__c = Date.Today(),
           SBQQ__SubscriptionEndDate__c = Date.Today().addDays(1),
           SBQQ__Quantity__c = 1);
        insert sub1;
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
           Name__c = 'Test Product2',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p2.Id,
           SBQQ__Quantity__c = 1,
           Parent__c = sub1.Id);
        insert sub2;

        //Set Test Page Reference
        PageReference pr = Page.ContractLineItemHierarchy;
        pr.getParameters().put('id',con.Id);
        //JSONify the SelectedIds parameter
        List<String> subDeleted = new List<String>();
		subDeleted.add(sub2.Id);
		pr.getParameters().put('selectedKeysJSON', JSON.serialize(subDeleted));
        Test.setCurrentPageReference(pr);
        Test.startTest();
            SubscriptionItemHierarchyExtension controller = new SubscriptionItemHierarchyExtension(
               new ApexPages.StandardController(con));
            //TreeJSON string should not be null
            system.assert(controller.treeJSON != null, 'The JSON String on the controller should not be empty');
            //Test Delete, Ids are in parameter
            controller.deleteContractLineItems();
        Test.stopTest();
        //Should only be 1 subscription left
        List<SBQQ__Subscription__c> subList = [SELECT Id from SBQQ__Subscription__c WHERE Id = :sub2.Id];
        system.assert(subList.size() == 0, 'The Subscription selected should be deleted');
    }

    static testMethod void loadOrders()
    {
    	//set test getters
    	Integer numOrders = 0;
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract con = new Contract(AccountId = acc.id);
        insert con;
        List<Product2> products = new List<Product2>();
        Product2 p = new Product2(Name = 'Test Product');
        products.add(p);
        Product2 p2 = new Product2(Name='Another Test Product');
        products.add(p2);
        insert products;
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
           Name__c = 'Test Product Parent',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p.Id,
           Status__c = 'Contract Sent',
           SBQQ__SubscriptionStartDate__c = Date.Today(),
           SBQQ__SubscriptionEndDate__c = Date.Today().addDays(1),
           SBQQ__Quantity__c = 1);
        insert sub1;
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
           Name__c = 'Test Product2',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p2.id,
           SBQQ__Quantity__c = 1,
           Parent__c = sub1.Id);
        insert sub2;
        List<Order__c> lstOrders = new List<Order__c>();
        Order__c o1 = new Order__c(name='Test Order 1', Site__c = acc.id, Status__c = 'Order Approved');
        lstOrders.add(o1);
        Order__c o2 = new Order__c(name='Test Order 2', Site__c = acc.id, Status__c = 'Order Approved');
        lstOrders.add(o2);
        insert lstOrders;

        //Set Test Page Reference
        PageReference pr = Page.ContractLineItemHierarchy;
        pr.getParameters().put('id',con.Id);
        Test.setCurrentPageReference(pr);
        Test.startTest();
            SubscriptionItemHierarchyExtension controller = new SubscriptionItemHierarchyExtension(
               new ApexPages.StandardController(con));
            //Test Delete, Ids are in parameter
			numOrders = controller.orderMap.Values().size();
        Test.stopTest();

        system.debug('numOrders = '+numOrders);
        system.assertEquals(3, numOrders);
    }

    static testMethod void saveTasks()
    {
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract con = new Contract(AccountId = acc.id);
        insert con;
        List<Product2> products = new List<Product2>();
        Product2 p = new Product2(Name = 'Test Product Parent');
        products.add(p);
        Product2 p2 = new Product2(Name='Test Line Item');
        products.add(p2);
        insert products;
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
           Name__c = 'Test Product Parent',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p.Id,
           SBQQ__Quantity__c = 1,
           Status__c = 'Contract Sent',
           SBQQ__SubscriptionStartDate__c = Date.Today(),
           SBQQ__SubscriptionEndDate__c = Date.Today().addDays(1));
        insert sub1;
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
           Name__c = 'Test Line Item',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p2.id,
           SBQQ__Quantity__c = 1,
           Parent__c = sub1.Id);
        insert sub2;
        Order__c o1 = new Order__c(name='Test Order', Site__c = acc.id, Status__c = 'Order Approved');
        insert o1;

        //Set Test Page Reference
        PageReference pr = Page.ContractLineItemHierarchy;
        pr.getParameters().put('id',con.Id);
        pr.getParameters().put('orderId',o1.Id);
        pr.getParameters().put('selectedKeys','['+JSON.serialize(sub1.id) + ']');
        pr.getParameters().put('processOrder','true');
        pr.getParameters().put('affectAssets','true');
        pr.getParameters().put('affectService','true');
        pr.getParameters().put('affectEntitle','true');
        pr.getParameters().put('affectMarina','true');
        Test.setCurrentPageReference(pr);
        Test.startTest();
            SubscriptionItemHierarchyExtension controller = new SubscriptionItemHierarchyExtension(new ApexPages.StandardController(con));
            //TreeJSON string should not be null
            system.assert(controller.treeJSON != null, 'The JSON String on the controller should not be empty');
            //Test Delete, Ids are in parameter
			controller.saveTasks();
        Test.stopTest();
    }

    static testMethod void hierarchyUpdateStatusTest()
    {
    	List<Product2> products = new List<Product2>(); 
    	Product2 p = new Product2(Name = 'Test Product');
        products.add(p);
        Product2 p2 = new Product2(Name = 'Test Product2');
        products.add(p2);
        insert products;    	
        Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract con = new Contract(AccountId = acc.id);
        insert con;       
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
           Name__c = 'Test Product Parent',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p.Id,
           Status__c = 'Contract Sent',
           SBQQ__SubscriptionStartDate__c = Date.Today(),
           SBQQ__SubscriptionEndDate__c = Date.Today().addDays(1),
           SBQQ__Quantity__c = 1);
        insert sub1;
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
           Name__c = 'Test Product2',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p2.Id,
           SBQQ__Quantity__c = 1,
           Parent__c = sub1.Id);
        insert sub2;

        //Set Test Page Reference
        PageReference pr = Page.ContractLineItemHierarchy;
        pr.getParameters().put('id',con.Id);
        //Select a Subscription to update
        List<String> subUpdatedStatus = new List<String>();
		subUpdatedStatus.add(sub1.Id);
        Test.setCurrentPageReference(pr);
        Test.startTest();
            SubscriptionItemHierarchyExtension controller = new SubscriptionItemHierarchyExtension(
               new ApexPages.StandardController(con));
            //TreeJSON string should not be null
            system.assert(controller.treeJSON != null, 'The JSON String on the controller should not be empty');
            //Update Status of Subscription
            SubscriptionItemHierarchyExtension.updateStatus(subUpdatedStatus, 'Test Status');
        Test.stopTest();
        //Subscription should have a different status
        List<SBQQ__Subscription__c> subList = [SELECT Id from SBQQ__Subscription__c WHERE Id = :sub1.Id and Status__c='Test Status'];
        system.assert(subList.size() == 1, 'The Subscription selected should have a different status');
    }

    static testMethod void MassUpdate()
    {
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract con = new Contract(AccountId = acc.id);
        insert con;
        Product2 p = new Product2(Name = 'Test Product Parent');
        Product2 p2 = new Product2(Name = 'Test Product1');
        List<Product2> productlist = New List<Product2>();
        productlist.add(p);
        productlist.add(p2);
        insert productlist;
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
           Name__c = 'Test Product Parent',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p.Id,
           project_type__c = '',
           SBQQ__Quantity__c = 1,
           Status__c = 'Contract Sent',
           SBQQ__SubscriptionStartDate__c = Date.Today(),
           SBQQ__SubscriptionEndDate__c = Date.Today().addDays(1));
 		SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
           Name__c = 'Test Product',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p2.Id,
           project_type__c = '',
           SBQQ__Quantity__c = 1,
           Status__c = 'Contract Sent',
           SBQQ__SubscriptionStartDate__c = Date.Today(),
           SBQQ__SubscriptionEndDate__c = Date.Today().addDays(1));
 		List<SBQQ__Subscription__c> sublist = New List<SBQQ__Subscription__c>();
 		sublist.add(sub1);
 		sublist.add(sub2);
 		insert sublist;

  		PageReference pr = Page.ContractLineItemHierarchy;
 		pr.getParameters().put('id',con.Id);
        pr.getParameters().put('selectedKeys','['+JSON.serialize(sub2.id) + ']');
        pr.getParameters().put('selectedProjectType', 'Project Type');
        Test.setcurrentpagereference(pr);
        Test.startTest();
        SubscriptionItemHierarchyExtension controller = new SubscriptionItemHierarchyExtension(
                                                       new ApexPages.StandardController(con));
        controller.massUpdateFields();
        Test.stopTest();

        SBQQ__Subscription__c updsub = [ Select Id, project_type__c from SBQQ__Subscription__c where id = :sub2.Id LIMIT 1 ];
        system.debug('Subscription Hierarchy Test line item project type is ' +updsub.project_type__c);
    } 
}