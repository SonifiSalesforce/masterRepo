@isTest
public with sharing class OrderItemTriggerLogicTest {


	static testMethod void testOrderItemUpdate()
	{
		
		
		System.debug(LoggingLevel.DEBUG,'Dan testOrderItemUpdate Test .  **********    START');	
        User testUser =  DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 1, false).get(0);
        User testUser2 =  DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 1, false).get(0);

        //Acquire test user of Profile Admin Manager
        Profile pfl = [select id from profile where name='System Administrator'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';
        String randomName2 = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';

        List<Order_Item__c> orderlist = new List<Order_Item__c>();

        testUser.email=randomName;
        testUser.emailencodingkey='UTF-8';
        testUser.lastname='Testing';
        testUser.languagelocalekey='en_US';
        testUser.localesidkey='en_US';
        testUser.profileid = pfl.Id;
        testUser.country='United States';
        testUser.CommunityNickname = 'u1';
        testUser.timezonesidkey='America/Los_Angeles';
        testUser.username=randomName;
        insert testUser;

        testUser2.email=randomName2;
        testUser2.emailencodingkey='UTF-8';
        testUser2.lastname='Testing';
        testUser2.languagelocalekey='en_US';
        testUser2.localesidkey='en_US';
        testUser2.profileid = pfl.Id;
        testUser2.country='United States';
        testUser2.CommunityNickname = 'u2';
        testUser2.timezonesidkey='America/Los_Angeles';
        testUser2.username=randomName2;
        insert testUser2;


        Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
        system.runAs(testUser)
        {
			Account acc = DataGenerator.createAccounts(1, true).get(0);
		
            //Create Work Order, Order Item and Associated Item
            Work_Order__c work = new Work_Order__c(RecordTypeId = workOrderRecordType);
	    	work.Install_Manager__c = testUser.id;
	    	
	    	insert work;

	    	Work_Order__c work2 = new Work_Order__c(RecordTypeId = workOrderRecordType);
	    	work2.Install_Manager__c = testUser2.id;
	    	insert work2;
	
	
			Order__c o = DataGenerator.createOrders(acc.Id, 'Order Approved', 1, true).get(0);
			o.name='test Order';
			update o;
		
			// create 3 Order Items
			Order_Item__c oi1 = new Order_Item__c(Order__c = o.Id,name='test Order 1', Status__c = 'In Development', Total_Rooms_Ordered__c = 231);
			// insert oi1;
			Order_Item__c oi2 = new Order_Item__c(Order__c = o.Id,name='test Order 2', Status__c = 'In Development', Total_Rooms_Ordered__c = 231);
			// insert oi2;
			Order_Item__c oi3 = new Order_Item__c(Order__c = o.Id,name='test Order 3',  Status__c = 'In Development', Total_Rooms_Ordered__c = 231);
			// insert oi3;
			orderlist.add(oi1);
			orderlist.add(oi2);
			orderlist.add(oi3);
			insert orderlist;
			Associated_Item__c aItem1 = new Associated_Item__c(Name = 'Associated Item Grand 1', Order_Item__c = oi1.id, Work_Order__c = work.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
			Associated_Item__c aItem2 = new Associated_Item__c(Name = 'Associated Item Grand 2', Order_Item__c = oi2.id, Work_Order__c = work.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
			Associated_Item__c aItem3 = new Associated_Item__c(Name = 'Associated Item Grand 3', Order_Item__c = oi3.id, Work_Order__c = work2.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
		
			insert new List<Associated_Item__c>{aItem1, aItem2, aItem3};		


        	// perform test by changing different fields to the Order_Item__C and update the changes
            Test.startTest();

            	oi1.Status__c = 'Pending Installation Activate';
            	oi2.Status__c = 'Pending Installation Activate';
            	oi3.Status__c = 'Pending Installation Activate';
            	oi3.Total_Rooms_Ordered__c = 225;
            	update orderlist;

            Test.stopTest();
        }

         orderlist = [Select Id, Status__c, Total_Rooms_Ordered__c from Order_Item__c where Status__c = 'Pending Installation Activate'];

            System.debug(LoggingLevel.DEBUG,'Dan OrderItemTriggerLogic Test .  **********    Done '+orderlist.size());
            system.assertEquals(3, orderlist.size());
            for (Order_Item__c oiv : orderlist) {
            	System.debug(LoggingLevel.DEBUG,'Dan OrderItemTriggerLogic Test .  **********   test results '+oiv.Status__c+' id '+oiv.id);
                system.assertEquals('Pending Installation Activate' , oiv.Status__c);
            }		
     
            System.debug(LoggingLevel.DEBUG,'Dan testOrderItemUpdate Test .  **********    Done '+orderlist.size());
		
	}
	
	static testMethod void testOrderItemDelete()
	{
		
		
		System.debug(LoggingLevel.DEBUG,'Dan testOrderItemDelete Test .  **********    START');	
        User testUser =  DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 1, false).get(0);
        User testUser2 =  DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 1, false).get(0);

        //Acquire test user of Profile Admin Manager
        Profile pfl = [select id from profile where name='System Administrator'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';
        String randomName2 = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';

        List<Order_Item__c> orderlist = new List<Order_Item__c>();

        testUser.email=randomName;
        testUser.emailencodingkey='UTF-8';
        testUser.lastname='Testing';
        testUser.languagelocalekey='en_US';
        testUser.localesidkey='en_US';
        testUser.profileid = pfl.Id;
        testUser.country='United States';
        testUser.CommunityNickname = 'u1';
        testUser.timezonesidkey='America/Los_Angeles';
        testUser.username=randomName;
        insert testUser;

        testUser2.email=randomName2;
        testUser2.emailencodingkey='UTF-8';
        testUser2.lastname='Testing';
        testUser2.languagelocalekey='en_US';
        testUser2.localesidkey='en_US';
        testUser2.profileid = pfl.Id;
        testUser2.country='United States';
        testUser2.CommunityNickname = 'u2';
        testUser2.timezonesidkey='America/Los_Angeles';
        testUser2.username=randomName2;
        insert testUser2;


        Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
        system.runAs(testUser)
        {
			Account acc = DataGenerator.createAccounts(1, true).get(0);
		
            //Create Work Order, Order Item and Associated Item
            Work_Order__c work = new Work_Order__c(RecordTypeId = workOrderRecordType);
	    	work.Install_Manager__c = testUser.id;
	    	
	    	insert work;

	    	Work_Order__c work2 = new Work_Order__c(RecordTypeId = workOrderRecordType);
	    	work2.Install_Manager__c = testUser2.id;
	    	insert work2;
	
	
			Order__c o = DataGenerator.createOrders(acc.Id, 'Order Approved', 1, true).get(0);
			o.name='test Order';
			update o;
		
			// create 3 Order Items
			Order_Item__c oi1 = new Order_Item__c(Order__c = o.Id,name='test Order 1', Status__c = 'In Development', Total_Rooms_Ordered__c = 231);
			// insert oi1;
			Order_Item__c oi2 = new Order_Item__c(Order__c = o.Id,name='test Order 2', Status__c = 'In Development', Total_Rooms_Ordered__c = 231);
			// insert oi2;
			Order_Item__c oi3 = new Order_Item__c(Order__c = o.Id,name='test Order 3',  Status__c = 'In Development', Total_Rooms_Ordered__c = 231);
			// insert oi3;
			orderlist.add(oi1);
			orderlist.add(oi2);
			orderlist.add(oi3);
			insert orderlist;
			Associated_Item__c aItem1 = new Associated_Item__c(Name = 'Associated Item Grand 1', Order_Item__c = oi1.id, Work_Order__c = work.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
			Associated_Item__c aItem2 = new Associated_Item__c(Name = 'Associated Item Grand 2', Order_Item__c = oi2.id, Work_Order__c = work.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
			Associated_Item__c aItem3 = new Associated_Item__c(Name = 'Associated Item Grand 3', Order_Item__c = oi3.id, Work_Order__c = work2.id, Billing_Commencement_Date__c = Date.Today(), Quantity__c =50);
		
			insert new List<Associated_Item__c>{aItem1, aItem2, aItem3};		


        	// perform test by changing different fields to the Order_Item__C and update the changes
            Test.startTest();

            	oi1.Status__c = 'Pending Installation Activate';
            	oi2.Status__c = 'Pending Installation Activate';
            	oi3.Status__c = 'Pending Installation Activate';
            	oi3.Total_Rooms_Ordered__c = 225;
            	update orderlist;
            	System.debug(LoggingLevel.DEBUG,'Dan OrderItemTriggerLogic Test .  **********   Delete '+oi2);
            	delete oi2;

            Test.stopTest();
        }

         orderlist = [Select Id, Status__c, Total_Rooms_Ordered__c from Order_Item__c where Status__c = 'Pending Installation Activate'];

            System.debug(LoggingLevel.DEBUG,'Dan OrderItemTriggerLogic Test .  **********    Done '+orderlist.size());
            system.assertEquals(2, orderlist.size());
            for (Order_Item__c oiv : orderlist) {
            	System.debug(LoggingLevel.DEBUG,'Dan OrderItemTriggerLogic Test .  **********   test results '+oiv.Status__c+' id '+oiv.id);
                 system.assertEquals('Pending Installation Activate' , oiv.Status__c);
            }		
     
            System.debug(LoggingLevel.DEBUG,'Dan testOrderItemDelete Test .  **********    Done '+orderlist.size());
		
	}
    static testMethod void testRollupSummary()
    {
        System.debug(LoggingLevel.DEBUG,'testRollupSummary start');
    	Product2 p0 = new Product2(Name = 'Test Product', Family = 'FTG'); 
    	insert p0;
    	Product2 p1 = new Product2(Name = 'Test Product', Channel_Type__c = 'HD');
    	insert p1;
    	Product2 p2 = new Product2(Name = 'Test Product', Channel_Type__c = 'Analog');
    	insert p2;
    	Product2 p3 = new Product2(Name = 'Test Product', Channel_Type__c = 'SD');
    	insert p3;
    	
    	Order_Item__c o1 = new Order_Item__c(Product__c = p0.Id, Status__c = 'Installed Activated');
    	insert o1;
    	Order_Item__c o2 = new Order_Item__c(Parent__c = o1.Id, Product__c = p1.Id, Status__c = 'Installed Activated', Product_Parent_Id__c = o1.id);
    	Order_Item__c o3 = new Order_Item__c(Parent__c = o1.Id, Product__c = p2.Id, Status__c = 'Installed Activated', Product_Parent_Id__c = o1.id);
    	Order_Item__c o4 = new Order_Item__c(Parent__c = o1.Id, Product__c = p3.Id, Status__c = 'Installed Activated', Product_Parent_Id__c = o1.id);

    	Test.startTest();

    	insert o2;
		insert o3;
		insert o4;    	
		o4.Status__c = 'Billing';
		update o4;
    	Test.stopTest();
    	o1 = [SELECT HD_Channel_Count__C, SD_Channel_Count__c, Analog_Channel_Count__c from Order_Item__c WHERE Id = :o1.Id][0];
    	system.assert(o1.HD_Channel_Count__c == 1, 'HD channel count is ' +o1.HD_Channel_Count__c);
    	system.assert(o1.SD_Channel_Count__c == 1, 'SD Channel count is '+o1.SD_Channel_Count__c);
    	system.assert(o1.Analog_Channel_Count__c == 1, 'Analog Channel count is '+o1.Analog_Channel_Count__c);  
    	  	
    }
	
	
}