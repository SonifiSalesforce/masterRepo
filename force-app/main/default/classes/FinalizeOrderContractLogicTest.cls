@isTest
public with sharing class FinalizeOrderContractLogicTest {
    //static testMethod void saveTasks()
    static testMethod void createNewOrder()
    {
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract con = new Contract(AccountId = acc.id);
        insert con;
        List<Product2> products = new List<Product2>();
        Product2 p = new Product2(Name = 'Test Product Parent', ProductCode='CC-Parent');
        products.add(p);
        Product2 p2 = new Product2(Name='Test Line Item 1');
        products.add(p2);
        Product2 p3 = new Product2(Name='Test Line Item 2');
        products.add(p3);
        insert products;
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
           Name__c = 'Test Product Parent',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p.Id,
           SBQQ__Quantity__c = 4,
           Status__c = 'Contract Sent',
           SBQQ__RegularPrice__c = 10.00,
           SBQQ__SubscriptionStartDate__c = Date.Today(),
           SBQQ__SubscriptionEndDate__c = Date.Today().addDays(1));
        insert sub1;
        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
           Name__c = 'Test Line Item 1',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p2.id,
           SBQQ__Quantity__c = 2,
           Status__c = 'Contract Sent',
           SBQQ__RegularPrice__c = 4.00,
           Parent__c = sub1.Id,
           product_parent_id__c = sub1.Id);
        subList.add(sub2);
        SBQQ__Subscription__c sub3 = new SBQQ__Subscription__c(
           Name__c = 'Test Line Item 2',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p3.id,
           SBQQ__Quantity__c = 1,
           Status__c = 'Contract Sent',
           SBQQ__RegularPrice__c = 3.00,
           Parent__c = sub1.Id,
           product_parent_id__c = sub1.Id);
        subList.add(sub3);
        insert subList;

        //Set Test Page Reference
        PageReference pr = Page.ContractLineItemHierarchy;
        pr.getParameters().put('id',con.Id);
        pr.getParameters().put('selectedKeys','['+JSON.serialize(sub1.id) + ',' +JSON.serialize(sub2.id)+ ',' +JSON.serialize(sub3.id)+ ']');
        pr.getParameters().put('processOrder','true');
        //jjackson 12/2018--removed the below parameters because they are no longer needed;
      //  pr.getParameters().put('affectAssets','true');
      //  pr.getParameters().put('affectService','true');
      //  pr.getParameters().put('affectEntitle','true');
     //   pr.getParameters().put('affectMarina','true');

        Test.setCurrentPageReference(pr);
        Test.startTest();
            SubscriptionItemHierarchyExtension controller = new SubscriptionItemHierarchyExtension(
               new ApexPages.StandardController(con));
            //TreeJSON string should not be null
            system.assert(controller.treeJSON != null, 'The JSON String on the controller should not be empty');
			controller.saveTasks();
            //Verify Order Items were created
            List<Order_Item__c> ordersList = [ SELECT Id, Name FROM Order_Item__c];
            system.debug('Test createNewOrder - Number of created Order Items: '+ordersList.size());
            system.assertEquals(3, ordersList.size());  //Three order items should have been created
        Test.stopTest();
    }

    static testMethod void addOrderLines()
    {
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract con = new Contract(AccountId = acc.id);
        insert con;
        List<Product2> products = new List<Product2>();
        Product2 p = new Product2(Name = 'Test Product Parent', ProductCode='CC-Parent');
        products.add(p);
        Product2 p2 = new Product2(Name='Test Line Item 1', ProductCode='CC-Child_01');
        products.add(p2);
        Product2 p3 = new Product2(Name='Test Line Item 2', ProductCode='CC-Child_02');
        products.add(p3);
        insert products;
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
           Name__c = 'Test Product Parent',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p.Id,
           SBQQ__Quantity__c = 1,
           Status__c = 'Contract Sent',
           Equipment_Ownership__c = 'SONIFI',
           Project_Type__c = 'Test Project',
           SBQQ__SubscriptionStartDate__c = Date.Today(),
           SBQQ__SubscriptionEndDate__c = Date.Today().addDays(1));
        insert sub1;
        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
           Name__c = 'Test Line Item 1',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p2.id,
           SBQQ__Quantity__c = 1,
           Status__c = 'Contract Sent',
           SBQQ__RegularPrice__c = 4.00,
           Parent__c = sub1.Id,
           product_parent_id__c = sub1.Id);
        insert sub2;

        //Pull Subscriptions to create Order/Order Items
        List<SBQQ__Subscription__c> subOrderList = [ SELECT id, name__c, sbqq__account__c, sbqq__account__r.name, sbqq__contract__r.Contract_Status__c, parent_productcode__c,
                                                       sbqq__product__c, sbqq__quantity__c, sbqq__regularprice__c, Status__c, product_inventory__c, contract_type__c,
                                                       sbqq__product__r.productcode, product_parent_id__c, equipment_ownership__c, project_type__c, parent__c
                                                     FROM SBQQ__Subscription__c ];

        //Create new Order and Order Items; capture Id of created Order
        Id createdOrder = FinalizeOrderContractLogic.ProcessOrderAndOrderItems(true, null, subOrderList);
        Asset a3 = new Asset(name = 'Test Asset-Sub3', AccountId = acc.id);
        insert a3;

        //Add a new Subscription without related Order Items to test FindAndUpdateOrderItems
        SBQQ__Subscription__c sub3 = new SBQQ__Subscription__c(
           Name__c = 'Test Line Item 2',
           SBQQ__Contract__c = con.Id,
           SBQQ__Product__c = p3.id,
           SBQQ__Quantity__c = 1,
           Status__c = 'Contract Sent',
           SBQQ__RegularPrice__c = 3.00,
           Parent__c = sub1.Id,
           product_parent_id__c = sub1.Id,
           product_inventory__c = a3.Id);
        insert sub3;

        //Set Test Page Reference
        PageReference pr = Page.ContractLineItemHierarchy;
        pr.getParameters().put('id',con.Id);
        pr.getParameters().put('orderId',createdOrder);
        pr.getParameters().put('selectedKeys','['+JSON.serialize(sub2.id)+','+JSON.serialize(sub3.id)+']');
        pr.getParameters().put('processOrder','true');
       // pr.getParameters().put('affectAssets','true');
       // pr.getParameters().put('affectService','true');
       // pr.getParameters().put('affectEntitle','true');
      //  pr.getParameters().put('affectMarina','true');

        Test.setCurrentPageReference(pr);
        Test.startTest();
            SubscriptionItemHierarchyExtension controller = new SubscriptionItemHierarchyExtension(
               new ApexPages.StandardController(con));
            //TreeJSON string should not be null
            system.assert(controller.treeJSON != null, 'The JSON String on the controller should not be empty');
            //Test Delete, Ids are in parameter
			controller.saveTasks();
            List<Order_Item__c> updatedOrderItem = [ SELECT id FROM Order_Item__c WHERE subscription__r.Name__c = 'Test Line Item 2' AND asset__r.Name = 'Test Asset-Sub3' ];
            system.debug('Test addOrderLines - Number of new Order Items: '+updatedOrderItem.size());
            system.assertEquals(1, updatedOrderItem.size());   //Only one Order Line should meet the criteria
        Test.stopTest();
    } 
}