@isTest
private class StandardShipmentItemTriggerLogicTests {

    static testMethod void updateOrderItems() {
        Order__c o = new Order__c(name='test order');
        insert o;
        Order_Item__c o1 = new Order_Item__c(name='test item 1', Quantity__c = 10, Remaining_Quantity__c = 10);
        insert o1;
        Order_Item__c o2 = new Order_Item__c(name='test item 2', Quantity__c = 20, Remaining_Quantity__c = 20);
        insert o2;
        Shipment__c ship = new Shipment__c(name = 'test ship');
        insert ship;
        Shipment_Item__c sItem1 = new Shipment_Item__c(Order_Item__c = o1.id, Shipment__c = ship.id, Quantity__c = 5);
        Shipment_Item__c sItem2 = new Shipment_Item__c(Order_Item__c = o2.id, Shipment__c = ship.id, Quantity__c = 10);
        
        Test.startTest();
        insert sItem1;
        insert sItem2;
        sItem1.Quantity__c = 8;
        update sItem1;
        delete sItem2;
        Test.stopTest();
        
        //requery for order items
        List<Order_Item__c> oItems = [SELECT id, Remaining_Quantity__c FROM Order_Item__c];
        
        Integer o1Num = (oItems[0].id == o1.id)? (Integer)oItems[0].Remaining_Quantity__c : (Integer)oItems[1].Remaining_Quantity__c;
        Integer o2Num = (oItems[1].id == o2.id)? (Integer)oItems[1].Remaining_Quantity__c : (Integer)oItems[0].Remaining_Quantity__c;
        
        //assertions
        System.assertEquals(2, o1Num);
        System.assertEquals(20, o2Num);
    }
}