@isTest
private class ShipmentExtensionTests {

    static testMethod void loadData() {
    	Account acc = new Account(Name='Test acc');
    	insert acc;
    	
    	Work_Order__c work = new Work_Order__c(Site__c = acc.id, Name='Test work');
    	insert work;
    	
    	//create products
    	Product2 prod1 = new Product2(Name='Product 1', IsActive= true);
    	Product2 prod2 = new Product2(Name='Product 2', IsActive= true);
    	Product2 prod3 = new Product2(Name='Product 3', IsActive= true);
    	Product2 prod4 = new Product2(Name='Product 4', IsActive= true);
    	insert new List<Product2>{prod1,prod2,prod3,prod4};
    	
        Shipment__c ship = new Shipment__c(Name='testing', Work_Order__c = work.id);
        insert ship;
        
        String recordTypeId = (String)Utilities.RecordTypeNameToId('Order__c', 'Part Order');
        Order__c o1 = new Order__c(Name='Order 1', Status__c = 'Order Approved', Site__c = acc.id, RecordTypeId = recordTypeId);
        Order__c o2 = new Order__c(Name='Order 2', Status__c = 'Order Approved', Site__c = acc.id, RecordTypeId = recordTypeId);
        Order__c o3 = new Order__c(Name='Order 3', Status__c = 'Invoiced', Site__c = acc.id, RecordTypeId = recordTypeId);
        insert new List<Order__c>{o1,o2,o3};
        
        //create order items
        Order_Item__c oi1 = new Order_Item__c(Name = 'OI 1', Order__c = o1.id, Price__c = 50, Quantity__c =10, Remaining_Quantity__c =10, Product__c = prod1.id);
        Order_Item__c oi2 = new Order_Item__c(Name = 'OI 2', Order__c = o1.id, Price__c = 50, Quantity__c =10, Remaining_Quantity__c =10, Product__c = prod2.id);
        
        Order_Item__c oi3 = new Order_Item__c(Name = 'OI 3', Order__c = o2.id, Price__c = 50, Quantity__c =10, Remaining_Quantity__c =10, Product__c = prod3.id);
        Order_Item__c oi4 = new Order_Item__c(Name = 'OI 4', Order__c = o2.id, Price__c = 50, Quantity__c =10, Remaining_Quantity__c =10, Product__c = prod4.id);
        
        insert new List<Order_Item__c>{oi1,oi2,oi3,oi4};
        
        Shipment_Item__c si1 = new Shipment_Item__c(Shipment__c = ship.id, Order_Item__c = oi1.id, Quantity__c = 5);
        insert si1;
        
        //put in the test page
	    PageReference pageRef = Page.Shipment;
		pageRef.getParameters().put('Id', ship.id);
		Test.setCurrentPageReference(pageRef);
		
		//make the standard controller
	    ApexPages.StandardController controller = new ApexPages.StandardController(ship);
	
	    
        Test.StartTest();
        // now pass it to the extension
	    ShipmentExtension stdController = new ShipmentExtension(controller);
	    System.assert(stdController != null); // controller has successfully been created
	    stdController.orderNameAndId = o2.id;
	    stdController.orderName = 'OI';
	    stdController.loadOrderItems();
	    stdController.getOrderIds();
	    stdController.getSelectedOrders();
	    stdController.getOrders();
        Test.stopTest();
        
        //assertions
        System.assertEquals(1, stdController.id2OrderSelectedMap.KeySet().size());
        System.assertEquals(3, stdController.ordersAndIds.size());
        System.assertEquals(2, stdController.id2OrderMap.Values().size());
    }
    
    static testmethod void addAndDeleteMethods(){
    	Account acc = new Account(Name='Test acc');
    	insert acc;
    	
    	Work_Order__c work = new Work_Order__c(Site__c = acc.id, Name='Test work');
    	insert work;
    	
    	//create products
    	Product2 prod1 = new Product2(Name='Product 1', IsActive= true);
    	Product2 prod2 = new Product2(Name='Product 2', IsActive= true);
    	Product2 prod3 = new Product2(Name='Product 3', IsActive= true);
    	Product2 prod4 = new Product2(Name='Product 4', IsActive= true);
    	insert new List<Product2>{prod1,prod2,prod3,prod4};
    	
        Shipment__c ship = new Shipment__c(Name='testing', Work_Order__c = work.id);
        insert ship;
        
        String recordTypeId = (String)Utilities.RecordTypeNameToId('Order__c', 'Part Order');
        Order__c o1 = new Order__c(Name='Order 1', Status__c = 'Order Approved', Site__c = acc.id, RecordTypeId = recordTypeId);
        Order__c o2 = new Order__c(Name='Order 2', Status__c = 'Order Approved', Site__c = acc.id, RecordTypeId = recordTypeId);
        Order__c o3 = new Order__c(Name='Order 3', Status__c = 'Invoiced', Site__c = acc.id, RecordTypeId = recordTypeId);
        insert new List<Order__c>{o1,o2,o3};
        
        //create order items
        Order_Item__c oi1 = new Order_Item__c(Name = 'OI 1', Order__c = o1.id, Price__c = 50, Quantity__c =10, Remaining_Quantity__c =10, Product__c = prod1.id);
        Order_Item__c oi2 = new Order_Item__c(Name = 'OI 2', Order__c = o1.id, Price__c = 50, Quantity__c =10, Remaining_Quantity__c =10, Product__c = prod2.id);
        
        Order_Item__c oi3 = new Order_Item__c(Name = 'OI 3', Order__c = o2.id, Price__c = 50, Quantity__c =10, Remaining_Quantity__c =10, Product__c = prod3.id);
        Order_Item__c oi4 = new Order_Item__c(Name = 'OI 4', Order__c = o2.id, Price__c = 50, Quantity__c =10, Remaining_Quantity__c =10, Product__c = prod4.id);
        
        insert new List<Order_Item__c>{oi1,oi2,oi3,oi4};
        
        Shipment_Item__c si1 = new Shipment_Item__c(Shipment__c = ship.id, Order_Item__c = oi1.id, Quantity__c = 5);
        insert si1;
        
        //put in the test page
	    PageReference pageRef = Page.Shipment;
		pageRef.getParameters().put('Id', ship.id);
		Test.setCurrentPageReference(pageRef);
		
		//make the standard controller
	    ApexPages.StandardController controller = new ApexPages.StandardController(ship);
	
	    
        Test.StartTest();
        // now pass it to the extension
	    ShipmentExtension stdController = new ShipmentExtension(controller);
	    System.assert(stdController != null); // controller has successfully been created
	    stdController.loadOrderItems();
	    stdController.orderItemId = oi3.id;
	    stdController.addOrderItem();
	    Integer addedOneItem = stdController.id2OrderSelectedMap.Values().size();
	    stdController.orderItemId = oi1.id;
	    stdController.deleteOrderItem();
	    Integer deletedOneItem = stdController.id2OrderSelectedMap.Values().size();
	    stdController.id2OrderSelectedMap.get(oi3.id).shipItem.Quantity__c = 5;
	    stdController.saveShipmentItem();
	    //add all the items
	    stdController.addAllItems();
	    Test.StopTest();
	    
	    //assertions
	    System.assertEquals(2, addedOneItem);
	    System.assertEquals(1, deletedOneItem);
	    SYstem.assertNotEquals(1, stdController.id2OrderSelectedMap.Values().size());
    }
}