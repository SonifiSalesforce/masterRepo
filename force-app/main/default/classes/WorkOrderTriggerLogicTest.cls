@isTest
public with sharing class WorkOrderTriggerLogicTest {

	
    static testMethod void WorkOrderTriggerLogicTest()
    {
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest WorkOrderTriggerLogicTest Test .  **********    START');
        Account a = DataGenerator.createAccounts(1,true)[0];
         Work_Order__c wo = (Work_Order__c)DataGenerator.createSObjectWithDefaultValues('Work_Order__c',null);
        system.debug('account id is ' +a.id);
        wo.Site__c = a.Id;
        insert wo;
        Site_Photo__c ss = (Site_Photo__c)DataGenerator.createSObjectWithDefaultValues('Site_Photo__c',null);
        ss.Site__c = a.Id;
        insert ss;      
        Test.startTest();
        wo.Status__c = 'Complete';
        update wo;
        Test.stopTest();
        List<Site_Photo__c> ssList = [SELECT Id from Site_Photo__c WHERE Id = :ss.Id];
        system.assert(ssList.size() == 0, 'Site Photos remaining' +ssList.size());
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest WorkOrderTriggerLogicTest Test .  **********    Finished');
    }
    
    static testMethod void sitePhotoDeletionBulkTest()
    {
    	System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest sitePhotoDeletionBulkTest Test .  **********    START');
        List<Account> aList = new List<Account>();
        for(Integer i = 0; i < 300; i++)
        {
            aList.add(new Account(Name = 'TestAccount'+i));
        }
        insert aList;
        List<Work_Order__c> woList = new List<Work_Order__c>();
        List<Site_Photo__c> ssList = new List<Site_Photo__c>();
        for(Account a : aList)
        {
            Work_Order__c wo = new Work_Order__c();
            wo.Site__c = a.Id;
            woList.add(wo);
        }
        insert woList;
        for(Integer i = 0; i < aList.size(); i++)
        {
            Site_Photo__c ss = new Site_Photo__c(
            Site__c = aList[i].Id);
            ssList.add(ss);
        }
        insert ssList;
        //Get list of Site Survey Ids to query later
        List<ID> ssListIDs = new List<ID>();
        for(Site_Photo__c ss : ssList)
        {
            ssListIDs.add(ss.Id);
        }
        for(Work_Order__c wo : woList)
        {
            wo.Status__c = 'Complete';
        }
        update woList;
        ssList = [SELECT Id from Site_Photo__c WHERE ID IN:ssListIDs];
        system.assert(ssList.size() == 0);
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest sitePhotoDeletionBulkTest Test .  **********    Finished ');
    }
    
    static testMethod void testUpdateTVTypeRelated2Acc()
    {
    	System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testUpdateTVTypeRelated2Acc Test .  **********    START');
        Account a = DataGenerator.createAccounts(1,true)[0];
        List<Work_Order__c> woList = new List<Work_Order__c>();
        for(integer i = 0; i < 5; i++){
            Work_Order__c wo = new Work_Order__c();
            wo.Site__c = a.Id;
            woList.add(wo);
        }
        insert woList;
        
        insert new List<TV_Type__c>{new TV_Type__c(Work_Order__c = woList[0].id, Other_Manufacturer__c='other manu', Other_Model__c = 'other model'), new TV_Type__c(Site__c = a.id, Other_Manufacturer__c='other manu', Other_Model__c = 'other model'), new TV_Type__c(Site__c = a.id, Other_Manufacturer__c='other manu', Other_Model__c = 'other model'), new TV_Type__c(Work_Order__c = woList[1].id, Other_Manufacturer__c='other manu', Other_Model__c = 'other model')};
        
        Test.startTest();
        woList[0].Status__c = 'Install Complete';
        update woList[0];
        Test.stopTest();
        List<TV_Type__c> tvList = [SELECT Id from TV_Type__c WHERE Site__c = :a.Id];
        system.assertEquals(1, tvList.size());
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testUpdateTVTypeRelated2Acc Test .  **********   Finished');
    }

/*  jjackson 3/2016 no longer need this test because old product activation code is deprecated
    static testMethod void testProductActivationBillingNoInstall()
    {
    	System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingNoInstall Test .  **********    START');
        //Acquire test user of Profile Admin Manager
        Profile pfl = [select id from profile where name='Contracts Admin Manager'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';
        User testUser = new User(alias = 'testuser', email=randomName ,
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = pfl.Id,  country='United States', CommunityNickname = 'u1',
            timezonesidkey='America/Los_Angeles', username=randomName);
        //Test Sobjects var declaration
        Asset ass1;
        Asset ass2;
        Order_Item__c oi1;
        Order_Item__c oi2;
        Associated_Item__c ai1;
        Associated_Item__c ai2;
        Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
        system.runAs(testUser)
        {
            //Create Account and Asset
            Account acc = DataGenerator.createAccounts(1,true)[0];
            ass1 = new Asset();
            ass1.AccountId = acc.Id;
            ass1.Name = 'Part Inventory Test Asset Install';
            ass1.Status = 'Pending Install';
            //insert ass1;
            ass2 = new Asset();
            ass2.AccountId = acc.Id;
            ass2.Name = 'Part Inventory Test Asset DeInstall';
            ass2.Status = 'Pending De-Install';
            //insert ass2;
            List<Asset> lstasset = new List<Asset>();
            lstasset.add(ass1);
            lstasset.add(ass2);
            insert lstasset;
            //Create Work Order, Order Item and Associated Item
            Work_Order__c wo = new Work_Order__c(RecordTypeId = workOrderRecordType);
            insert wo;
            oi1 = new Order_Item__c();
            oi1.Asset__c = ass1.Id;
            oi1.Status__c ='Pending Installation Activate';
            oi1.Total_Rooms_Ordered__c = 500;
            oi1.Total_Remaining_Rooms__c = 500;
            //insert oi1;
            oi2 = new Order_Item__c();
            oi2.Asset__c = ass2.Id;
            oi2.Status__c = 'Pending De-Installation';
            oi2.Total_Rooms_Ordered__c = 600;
            oi2.Total_Remaining_Rooms__c = 100;
            List<Order_Item__c> lstoi = new List<Order_Item__c>();
            lstoi.add(oi1);
            lstoi.add(oi2);
            insert lstoi;
            //insert oi2;
            ai1 = new Associated_Item__c();
            ai1.Order_Item__c = oi1.Id;
            ai1.Work_Order__c = wo.Id;
            ai1.Flagged_for_Billing__c = true;
            ai1.Submitted_for_Billing__c = false;
      
            //insert ai1;
            ai2 = new Associated_Item__c();
            ai2.Order_Item__c = oi2.Id;
            ai2.Work_Order__c = wo.Id;
            ai2.Flagged_for_Billing__c = true;
            ai2.Submitted_for_Billing__c = false;
            //insert ai2;
            List<Associated_Item__c> lstai = new List<Associated_Item__c>();
            lstai.add(ai1);
            lstai.add(ai2);
            insert lstai;
            Test.startTest();
                //Update Associated Item fields and set Work Order to complete
            ai1.Quantity__c = 500;
            ai1.Status__c = 'Installed Activated';
            //update ai1;
            ai2.Quantity__c = -100 ;  
            ai2.Status__c = 'De-Installed';
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingNoInstall Test .  **********   Associated Item 2 status set to: '+ai2.Status__c+' id '+ai2.Id);
            //update ai2;
            List<Associated_Item__c> lstaitem = new List<Associated_Item__c>();
            lstaitem.add(ai1);
            lstaitem.add(ai2);
            update lstaitem;
            wo.Status__c = 'Billing/Go Live';
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingNoInstall Test .  **********   WorK Order update status set to: '+ wo.Status__c );            
            update wo;
        
            Test.stopTest();
            //Assert Part Activation with type Activation is inserted on Asset
            //Assert Field updates went to Order Item
            List<Product_Activation__c> paList = [SELECT id from Product_Activation__c WHERE Product_Inventory__c = :ass1.Id OR Product_Inventory__c = :ass2.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingNoInstall Test .  **********   There should be > 0 Product Activation, there are : '+paList.size());
            system.assert(paList.size() > 0, 'There should be one Product Activation, there are : '+paList.size());
            //jjackson get all order items with one query and loop through
            List<Order_Item__c> lstupdoi = [Select Id, Status__c from Order_Item__c where Id = :oi1.id OR Id = :oi2.Id];
            for(Order_Item__c oi : lstupdoi)
            {
            	if(oi.Id == oi1.Id)
            	{
            		System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingNoInstall Test .  **********   Status should be Installed On, is: '+oi.Status__c);
                    system.assert(oi.Status__c == 'Installed Activated', 'Status should be Installed On, is: '+oi.Status__c);
            	}
            	else
            	{
            		 System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingNoInstall Test .  **********   Status should be pending deinstall, is: '+oi.Status__c);
                     system.assert(oi.Status__c == 'De-Installed', 'Status should be pending deinstall, is: '+oi.Status__c);
            	}
            }
            //oi1 = [SELECT Status__c from Order_Item__c WHERE Id = :oi1.Id];
            
            //Testing partial deinstall
            //oi2 = [SELECT Status__c from Order_Item__c WHERE Id = :oi2.Id];
            
            ass2 = [SELECT Status from Asset WHERE Id = :ass2.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingNoInstall Test .  **********   Asset status should be Billing , is :'+ass2.Status);
            system.assert(ass2.Status == 'Billing', 'Asset status should be Billing , is :'+ass2.Status);
            
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingNoInstall Test .  **********    Finished');
        }
    }*/

    
    static testMethod void testProductActivationBillingAfterInstall()
    {
    	System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingAfterInstall Test .  **********    START');
        Id uid = Userinfo.getUserId();
        Account acc = DataGenerator.createAccounts(1,true)[0];
        RecordType rectyperec = [ Select Id, Name from RecordType where Name = 'Install' LIMIT 1 ];
        Id workOrderRecordType = rectyperec.Id;
        
        //create and insert the asset recs that are needed by product activations
        Asset assetparent = New Asset(accountid = acc.id, name = 'Test Asset Product Parent', status = 'Installed Activated');
        insert assetparent;
        Asset ass1 = new Asset(accountid = acc.id, name = 'Test Asset1 Install', status = 'Pending Installation Activate', parent_asset__c = assetparent.id);
        Asset ass2 = new Asset(accountid = acc.id, name = 'Test Asset2 Deinstall', status = 'Pending De-Installation', parent_asset__c = assetparent.id);
        List<Asset> insertassets = new List<Asset>();
        insertassets.add(ass1);
        insertassets.add(ass2);
        insert insertassets;
        
        //create and insert the order item recs that are needed by the associated items
        Order_Item__c oiparent = New Order_Item__c(asset__c=assetparent.id, status__c = 'Installed Activated', total_rooms_ordered__c = 500,
                                                   total_remaining_rooms__c = 500, name = 'Test Product Parent');
        insert oiparent;
        Order_Item__c oi1 = New Order_Item__c(asset__c = ass1.id, status__c = 'Pending Installation Activate',
                                              total_rooms_ordered__c = 500, total_remaining_rooms__c = 500, Name = 'Testoi1', parent__c = oiparent.id);
        Order_Item__c oi2 = New Order_Item__c(asset__c = ass2.id, status__c = 'Pending De-Installation',
                                              total_rooms_ordered__c = 600, total_remaining_rooms__c = 600, Name = 'Testoi2', parent__c = oiparent.id);
        List<Order_Item__c> insertoi = New List<Order_Item__c>();
        insertoi.add(oi1);
        insertoi.add(oi2);
        insert insertoi;
        
        //Create the work order that is needed by the associated items
        Work_Order__c wo = new Work_Order__c(RecordTypeId = workOrderRecordType, site__c = acc.Id, install_manager__c = uid,
	                                               approver__c = uid, Division__c = 'Domestic', Region__c = 'Southwest', project_coordinator__c = uid,
	                                               ownerid = uid, approval_status__c = 'Pending Billing Approval');
        insert wo;
        
        //create the associated items
        Associated_Item__c ai1 = New Associated_Item__c(order_item__c = oi1.id, work_order__c = wo.id, flagged_for_billing__c = true,
                                                        Name = 'Testai1', quantity__c = 0);
        Associated_Item__c ai2 = New Associated_Item__c(order_item__c = oi2.id, work_order__c = wo.id, flagged_for_billing__c = true,
                                                        Name = 'Testai2', quantity__c = 0);
        Test.startTest();
          insert new List<Associated_Item__c>{ai1, ai2};  //jjackson put this inside the test because SOQL limitations were being exceeded
                //Update Associated Item fields and set Work Order to complete
            List<Associated_Item__c> lstassocitm = [ Select Id, Status__c, Name, Quantity__c from Associated_Item__c];
            List<Associated_Item__c> lstupdaitem = new List<Associated_Item__c>();
            for(Associated_Item__c recai : lstassocitm )
            {
            	if(recai.Name == 'Testai1')
            	{
            		recai.Quantity__c = 500;
            		recai.Status__c = 'Billing';
            		lstupdaitem.add(recai);
            	}
            	if(recai.Name == 'Testai2')
            	{
            		recai.Quantity__c = 600;
            		recai.Status__c = 'De-Installed';
            		lstupdaitem.add(recai);
            	}
            		
            }
 
            update lstupdaitem;
            wo.Approval_Status__c = 'Billing Approved';
            wo.status__c = 'Billing/Go Live';
            wo.Previous_Status_Complete__c = true;
            update wo;
        
            Test.stopTest();
            //Assert Part Activation with type Activation is inserted on Asset
            //Assert Field updates went to Order Item
            List<Product_Activation__c> paList = [SELECT id from Product_Activation__c WHERE Product_Inventory__c in(:ass1.Id, :ass2.Id)];
            //system.debug('testProductActivationBillingAfterInstall Test . There should be one Product Activation, there are : '+paList.size());
            system.assert(paList.size() > 0, 'There should be two Product Activations, there are : '+paList.size());
            //jjackson Do one select statement for order items and loop through
            List<Order_Item__c> lstoi = [Select Id, Status__c, Name from Order_Item__c ];
   
            //jjackson Order item status is changing to same status as associated item due to new code on the associated item trigger logic
            for(Order_Item__c oi : lstoi)
            {
            	system.debug('order item after ai update is ' + oi);
            	if(oi.Name == 'Testoi1' )
            	{
            		//System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingAfterInstall Test .  **********Status should be Billing, is: '+oi.Status__c);
                    system.assert(oi.Status__c == 'Installed Activated', 'Status should be Installed Activated, is: '+oi.Status__c);
            	}
            	if(oi.Name == 'Testoi2')
            	{
            		//System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationBillingAfterInstall Test .  ********** Status should be De-Installed, is: '+oi.Status__c);
                    system.assert(oi.Status__c == 'De-Installed', 'Status should be De-Installed, is: '+oi.Status__c);
            	}
            }
  
            Asset updass2 = [SELECT Status from Asset WHERE Name = 'Test Asset2 Deinstall' LIMIT 1];
            //System.debug('testProductActivationBillingAfterInstall Test.  Asset status should be Pending De-Installation, is :'+updass2.Status);
            system.assert(updass2.Status == 'De-Installed', 'Asset status should be De-Installed, is :'+updass2.Status);
                    
    } //end testProductActivationBillingAfterInstall
    
 /* jjackson 3/2016 don't need all these product activation test methods now that the old code is replaced  
    static testMethod void testProductActivationInstallNoBilling()
    {
        //Acquire test user of Profile Admin Manager
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallNoBilling Test .  **********    START');
        Profile pfl = [select id from profile where name='Contracts Admin Manager'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';
        User testUser = new User(alias = 'testuser', email=randomName ,
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = pfl.Id,  country='United States', CommunityNickname = 'u1',
            timezonesidkey='America/Los_Angeles', username=randomName);
        //Test Sobjects var declaration
        Asset ass1;
        Asset ass2;
        Order_Item__c oi1;
        Order_Item__c oi2;
        Associated_Item__c ai1;
        Associated_Item__c ai2;
        Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
        system.runAs(testUser)
        {
            //Create Account and Asset
            Account acc = DataGenerator.createAccounts(1,true)[0];
            ass1 = new Asset();
            ass1.AccountId = acc.Id;
            ass1.Name = 'Part Inventory Test Asset Install';
            ass1.Status = 'Pending Install';
            //insert ass1;
            ass2 = new Asset();
            ass2.AccountId = acc.Id;
            ass2.Name = 'Part Inventory Test Asset DeInstall';
            ass2.Status = 'Pending De-Install';
            //insert ass2;
            List<Asset> lstasset = new list<Asset>();
            lstasset.add(ass1);
            lstasset.add(ass2);
            insert lstasset;
            //Create Work Order, Order Item and Associated Item
            Work_Order__c wo = new Work_Order__c(RecordTypeId = workOrderRecordType);
            insert wo;
            oi1 = new Order_Item__c();
            oi1.Name = 'oi1Name';
            oi1.Asset__c = ass1.Id;
            oi1.Status__c ='Pending Installation Activate';
            oi1.Total_Rooms_Ordered__c = 500;
            oi1.Total_Remaining_Rooms__c = 500;
            //insert oi1;
            oi2 = new Order_Item__c();
            oi2.Name = 'oi2Name';
            oi2.Asset__c = ass2.Id;
            oi2.Status__c = 'Pending De-Installation';
            oi2.Total_Rooms_Ordered__c = 600;
            oi2.Total_Remaining_Rooms__c = 100;
            //insert oi2;
            List<Order_Item__c> lstorderitem = new list<Order_Item__c>();
            lstorderitem.add(oi1);
            lstorderitem.add(oi2);
            insert lstorderitem;
            ai1 = new Associated_Item__c();
            ai1.Order_Item__c = oi1.Id;
            ai1.Work_Order__c = wo.Id;
            ai1.Flagged_for_Billing__c = true;
            //insert ai1;
            ai2 = new Associated_Item__c();
            ai2.Order_Item__c = oi2.Id;
            ai2.Work_Order__c = wo.Id;
            ai2.Flagged_for_Billing__c = true;
            //insert ai2;
            List<Associated_Item__c> lstassocitem = new list<Associated_Item__c>();
            lstassocitem.add(ai1);
            lstassocitem.add(ai2);
            insert lstassocitem;
            Test.startTest();
                //Update Associated Item fields and set Work Order to complete
            ai1.Quantity__c = 500;
            ai1.Status__c = 'Installed Activated';
            update ai1;
            ai2.Quantity__c = -50;
            ai2.Status__c = 'De-Installed';
            update ai2;
            wo.Status__c = 'Install Complete';
            wo.Previous_Status_Go_Live__c = false;
            update wo;

            Test.stopTest();
            
                    
            Set<Id> oidset = new set<Id>();
            oidset.add(oi1.id);
            oidset.add(oi2.id);
        
            //Assert Part Activation with type Activation is inserted on Asset
            //Assert Field updates went to Order Item
            List<Product_Activation__c> paList = [SELECT id from Product_Activation__c WHERE Product_Inventory__c = :ass1.Id OR Product_Inventory__c = :ass2.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallNoBilling Test .  **********  There should be one Product Activation, there are : '+paList.size());
            //system.assert(paList.size() == 0 , 'There should be one Product Activation, there are : '+paList.size());
            List<Order_Item__c> oilist = [ Select Id, Name, Status__c from Order_Item__c where Id in :oidset ];
            //jjoi1 = [SELECT Status__c from Order_Item__c WHERE Id = :oi1.Id];
            //jjSystem.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallNoBilling Test .  **********  Status should be Installed Activated, is: '+oi1.Status__c);
            //system.assert(oi1.Status__c == 'Installed Activated', 'Status should be Installed Activated, is: '+oi1.Status__c);
            //Testing partial deinstall
            //jjoi2 = [SELECT Status__c from Order_Item__c WHERE Id = :oi2.Id];
            //jjackson
            for(Order_Item__c oirec : oilist)
            {     System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallNoBilling Test .  **********   Status is '+oirec.Status__c +'for order item ' +oirec.Name);  }
            //system.assert(oi2.Status__c == 'De-Installed', 'Status should be pending deinstall, is: '+oi2.Status__c);
            
            ass2 = [SELECT Status from Asset WHERE Id = :ass2.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallNoBilling Test .  ********** Asset status should be Pending De-Installation , is :'+ass2.Status);
            //system.assert(ass2.Status == 'De-Installed', 'Asset status should be Pending De-Installation , is :'+ass2.Status);
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallNoBilling Test .  **********    Finished');
        }
    }
   
    static testMethod void testProductActivationInstallAfterBilling()
    {
    	//jjackson 10/7/2014 also tests UpdateOrderStatus method
    	System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallAfterBilling Test .  **********    START');
        //Acquire test user of Profile Admin Manager
        Profile pfl = [select id from profile where name='Contracts Admin Manager'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';
        User testUser = new User(alias = 'testuser', email=randomName ,
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = pfl.Id,  country='United States', CommunityNickname = 'u1',
            timezonesidkey='America/Los_Angeles', username=randomName);
        //Test Sobjects var declaration
        Asset ass1;
        Asset ass2;
        Order_Item__c oi1;
        Order_Item__c oi2;
        Associated_Item__c ai1;
        Associated_Item__c ai2;
        Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
        system.runAs(testUser)
        {
            //Create Account and Asset
            Account acc = DataGenerator.createAccounts(1,true)[0];
            ass1 = new Asset();
            ass1.AccountId = acc.Id;
            ass1.Name = 'Part Inventory Test Asset Install';
            ass1.Status = 'Pending Install';
            //insert ass1;
            ass2 = new Asset();
            ass2.AccountId = acc.Id;
            ass2.Name = 'Part Inventory Test Asset DeInstall';
            ass2.Status = 'Pending De-Install';
            //insert ass2;
            //jjackson bulk up by adding asset records to a list and insert once
            List<Asset> lstasset = new list<Asset>();
            lstasset.add(ass1);
            lstasset.add(ass2);
            insert lstasset;
            
            //Create Work Order, Order Item and Associated Item
            Work_Order__c wo = new Work_Order__c(RecordTypeId = workOrderRecordType);
            insert wo;
            oi1 = new Order_Item__c();
            oi1.Name = 'oi1Name';
            oi1.Asset__c = ass1.Id;
            oi1.Status__c ='Pending Installation Activate';
            oi1.Total_Rooms_Ordered__c = 500;
            oi1.Total_Remaining_Rooms__c = 500;
           
            //insert oi1;
            oi2 = new Order_Item__c();
            oi2.Name = 'oi2Name';
            oi2.Asset__c = ass2.Id;
            oi2.Status__c = 'Pending De-Installation';
            oi2.Total_Rooms_Ordered__c = 600;
            oi2.Total_Remaining_Rooms__c = 100;
            
            //insert oi2;
            List<Order_Item__c> lstorderitem = new list<Order_Item__c>();
            lstorderitem.add(oi1);
            lstorderitem.add(oi2);
            insert lstorderitem;
            ai1 = new Associated_Item__c();
            ai1.Order_Item__c = oi1.Id;
            ai1.Work_Order__c = wo.Id;
            ai1.Flagged_for_Billing__c = true;
            //insert ai1;
            ai2 = new Associated_Item__c();
            ai2.Order_Item__c = oi2.Id;
            ai2.Work_Order__c = wo.Id;
            ai2.Flagged_for_Billing__c = true;
            //insert ai2;
            List<Associated_Item__c> lstassocitem = new list<Associated_Item__c>();
            lstassocitem.add(ai1);
            lstassocitem.add(ai2);
            insert lstassocitem;
            Test.startTest();
                //Update Associated Item fields and set Work Order to complete
            ai1.Quantity__c = 500;
            ai1.Status__c = 'Installed Activated';
            update ai1;
            ai2.Quantity__c = -50;
            ai2.Status__c = 'De-Installed';
            update ai2;
            wo.Status__c = 'Install Complete';
            wo.Previous_Status_Go_Live__c = false;
            update wo;

            List<Product_Activation__c> paList = [SELECT id from Product_Activation__c WHERE Product_Inventory__c = :ass1.Id OR Product_Inventory__c = :ass2.Id];
        
            Test.stopTest();
            //Assert Part Activation with type Activation is inserted on Asset
            //Assert Field updates went to Order Item
            
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallAfterBilling Test .  ********** There should be one Product Activation, there are : '+paList.size());
            //system.assert(paList.size() == 0 , 'There should be one Product Activation, there are : '+paList.size());
            List<Order_Item__c> lstoi = [Select Id, Name, Status__c from Order_Item__c where Id = :oi1.id OR Id = :oi2.id];
            //jjoi1 = [SELECT Status__c from Order_Item__c WHERE Id = :oi1.Id];
            for(Order_Item__c oirec : lstoi)
              {  System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallAfterBilling Test .  ********** Status is: '+oirec.Status__c +'for order item ' +oirec.Name);  }
            //system.assert(oi1.Status__c == 'Installed Activated', 'Status should be Installed Activated, is: '+oi1.Status__c);
            //Testing partial deinstall
            //jjoi2 = [SELECT Status__c from Order_Item__c WHERE Id = :oi2.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallAfterBilling Test .  ********** Status should be pending deinstall, is: '+oi2.Status__c);
            //system.assert(oi2.Status__c == 'De-Installed', 'Status should be pending deinstall, is: '+oi2.Status__c);
            ass2 = [SELECT Status from Asset WHERE Id = :ass2.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallAfterBilling Test .  **********  Asset status should be Pending De-Installation , is :'+ass2.Status);
            //system.assert(ass2.Status == 'De-Installed', 'Asset status should be Pending De-Installation , is :'+ass2.Status);
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInstallAfterBilling Test .  **********    Finished');
        }
    }

    static testMethod void testWorkOrderScheduleDeauthorization()
    {
    	System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testWorkOrderScheduleDeauthorization Test .  **********    START');
        //Acquire test user of Profile Admin Manager
        Profile pfl = [select id from profile where name='Contracts Admin Manager'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';
        User testUser = new User(alias = 'testuser', email=randomName ,
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = pfl.Id,  country='United States', CommunityNickname = 'u1',
            timezonesidkey='America/Los_Angeles', username=randomName);
        //Test Sobjects var declaration
        Asset ass1;
        Asset ass2;
        Order_Item__c oi1;
        Order_Item__c oi2;
        Associated_Item__c ai1;
        Associated_Item__c ai2;
        Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Schedules');
        system.runAs(testUser)
        {
            //Create Account and Asset
            Account acc = DataGenerator.createAccounts(1,true)[0];
            ass1 = new Asset();
            ass1.AccountId = acc.Id;
            ass1.Name = 'Part Inventory Test Asset Install';
            ass1.Status = 'Pending Install';
            //insert ass1;
            ass2 = new Asset();
            ass2.AccountId = acc.Id;
            ass2.Name = 'Part Inventory Test Asset DeInstall';
            ass2.Status = 'Pending De-Install';
            //insert ass2;
            //Create Work Order, Order Item and Associated Item
            List<Asset> lstasset = new list<Asset>();
            lstasset.add(ass1);
            lstasset.add(ass2);
            insert lstasset;
            Work_Order__c wo = new Work_Order__c(RecordTypeId =workOrderRecordType);
            insert wo;
            oi1 = new Order_Item__c();
            oi1.Asset__c = ass1.Id;
            oi1.Status__c ='Pending Installation Activate';
            oi1.Total_Rooms_Ordered__c = 500;
            oi1.Total_Remaining_Rooms__c = 500;
            //insert oi1;
            oi2 = new Order_Item__c();
            oi2.Asset__c = ass2.Id;
            oi2.Status__c = 'Pending De-Installation';
            oi2.Total_Rooms_Ordered__c = 600;
            oi2.Total_Remaining_Rooms__c = 100;
            //insert oi2;
            List<Order_Item__c> lstorderitm = new list<Order_Item__c>();
            lstorderitm.add(oi1);
            lstorderitm.add(oi2);
            insert lstorderitm;
            ai1 = new Associated_Item__c();
            ai1.Order_Item__c = oi1.Id;
            ai1.Work_Order__c = wo.Id;
            ai1.Flagged_for_Billing__c = true;
            //insert ai1;
            ai2 = new Associated_Item__c();
            ai2.Order_Item__c = oi2.Id;
            ai2.Work_Order__c = wo.Id;
            ai2.Flagged_for_Billing__c = true;
            //insert ai2;
            List<Associated_Item__c> lstassocitm = new list<Associated_Item__c>();
            lstassocitm.add(ai1);
            lstassocitm.add(ai2);
            insert lstassocitm;
            Test.startTest();
                //Update Associated Item fields and set Work Order to complete
            ai1.Quantity__c = 500;
            ai1.Status__c = 'Installed Activated';
            ai1.System_Status__c = 'Operational';
            //update ai1;
            ai2.Quantity__c = -50;
            ai2.Status__c = 'De-Installed';
            ai2.System_Status__c = 'Operational';
            //update ai2;
            List<Associated_Item__c> lstupditems = new list<Associated_Item__c>();
            lstupditems.add(ai1);
            lstupditems.add(ai2);
            update lstupditems;
            wo.Status__c = 'Complete';
            wo.Previous_Status_Go_Live__c = false;
            update wo;
        
            Test.stopTest();
            //Assert Part Activation with type Activation is inserted on Asset
            //Assert Field updates went to Order Item
            List<Product_Activation__c> paList = [SELECT id from Product_Activation__c WHERE Product_Inventory__c = :ass1.Id OR Product_Inventory__c = :ass2.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testWorkOrderScheduleDeauthorization Test .  **********  There should be one Product Activation, there are : '+paList.size());
            system.assert(paList.size() == 0 , 'There should be one Product Activation, there are : '+paList.size());
            oi1 = [SELECT System_Status__c from Order_Item__c WHERE Id = :oi1.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testWorkOrderScheduleDeauthorization Test .  ********** Order Item System Status should be Operational, is: '+oi1.System_Status__c);
            system.assert(oi1.System_Status__c == 'Operational', 'Order Item System Status should be Operational, is: '+oi1.System_Status__c);
            ass2 = [SELECT System_Status__c from Asset WHERE Id = :ass2.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testWorkOrderScheduleDeauthorization Test .  **********  Asset Syste status should be Operational , is :'+ass2.System_Status__c);
            system.assert(ass2.System_Status__c == 'Operational', 'Asset Syste status should be Operational , is :'+ass2.System_Status__c);
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testWorkOrderScheduleDeauthorization Test .  **********    Finished');
        }
    }
    

    
    static testMethod void testWorkOrderRackBuild()
    {
    	System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testWorkOrderRackBuild Test .  **********    START');
        //Acquire test user of Profile Admin Manager
        Profile pfl = [select id from profile where name='Installation Division Manager'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';
        User testUser = new User(alias = 'testuser', email=randomName ,
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = pfl.Id,  country='United States', CommunityNickname = 'u1',
            timezonesidkey='America/Los_Angeles', username=randomName);
        //Test Sobjects var declaration
        Asset ass1;
        Order_Item__c oi1;
        Associated_Item__c ai1;
        Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Rack Build');
        system.runAs(testUser)
        {
            //Create Account and Asset
            Account acc = DataGenerator.createAccounts(1,true)[0];
            ass1 = new Asset();
            ass1.AccountId = acc.Id;
            ass1.Name = 'Part Inventory Test Asset Install';
            ass1.Status = 'Pending Install';
            insert ass1;
            //Create Work Order, Order Item and Associated Item
            Work_Order__c wo = new Work_Order__c(RecordTypeId =workOrderRecordType);
            insert wo;
            oi1 = new Order_Item__c();
            oi1.Asset__c = ass1.Id;
            oi1.Status__c ='Pending Installation Activate';
            oi1.Total_Rooms_Ordered__c = 500;
            oi1.Total_Remaining_Rooms__c = 500;
            insert oi1;
            ai1 = new Associated_Item__c();
            ai1.Order_Item__c = oi1.Id;
            ai1.Work_Order__c = wo.Id;
            ai1.Flagged_for_Billing__c = true;
            insert ai1;
            Test.startTest();
                //Update Associated Item fields and set Work Order to complete
            ai1.Card_ID__c = '123';
            ai1.Receiver_ID__c = '345';
            ai1.Serial_Number__c = '456';
            update ai1;
            wo.Status__c = 'Complete';
            wo.Previous_Status_Go_Live__c = false;
            update wo;
        
            Test.stopTest();
            ass1 = [SELECT Card_ID__c, Receiver_ID__c, SerialNumber from Asset WHERE Id = :ass1.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testWorkOrderRackBuild Test .  **********   results cardid '+ass1.Card_ID__C);
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testWorkOrderRackBuild Test .  **********   results recv id '+ass1.Receiver_ID__C);
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testWorkOrderRackBuild Test .  **********   results serial number '+ass1.SerialNumber);
            system.assert(ass1.Card_ID__C == '123');
            system.assert(ass1.Receiver_ID__C == '345');
            system.assert(ass1.SerialNumber == '456');
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testWorkOrderRackBuild Test .  **********    FINISHED');
        }
    }

     
    static testMethod void testProductActivationRackBuildChild()
    {
    	System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationRackBuildChild Test .  **********    START');
        //Acquire test user of Profile Admin Manager
        Profile pfl = [select id from profile where name='System Administrator'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';
        User testUser = new User(alias = 'testuser', email=randomName ,
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = pfl.Id,  country='United States', CommunityNickname = 'u1',
            timezonesidkey='America/Los_Angeles', username=randomName);
        //Test Sobjects var declaration
        Asset ass1;
        Asset ass2;
        Order_Item__c oi1;
        Order_Item__c oi2;
        Associated_Item__c ai1;
        Associated_Item__c ai2;
        Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
        Id workOrderRecordTypeRackBuild = Utilities.RecordTypeNameToId('Work_Order__c', 'Rack Build');
        
        system.runAs(testUser)
        {
            //Create Account and Asset
            Account acc = DataGenerator.createAccounts(1,true)[0];
            ass1 = new Asset();
            ass1.AccountId = acc.Id;
            ass1.Name = 'Part Inventory Test Asset Install';
            ass1.Status = 'Pending Install';
            //insert ass1;  jjackson 7/2014  Bulking up these inserts so as not to run trigger so many times
            ass2 = new Asset();
            ass2.AccountId = acc.Id;
            ass2.Name = 'Part Inventory Test Asset DeInstall';
            ass2.Status = 'Pending De-Install';
            //insert ass2;
            List<Asset> lstasset = new list<Asset>();  //jjackson add records to a list then insert
            lstasset.add(ass1);
            lstasset.add(ass2);
            insert lstasset;
            //Create Work Order, Order Item and Associated Item
            Work_Order__c wo = new Work_Order__c(RecordTypeId = workOrderRecordType);
            insert wo;
            oi1 = new Order_Item__c();
            oi1.Asset__c = ass1.Id;
            oi1.Status__c ='Pending Installation Activate';
            oi1.Total_Rooms_Ordered__c = 500;
            oi1.Total_Remaining_Rooms__c = 500;
            //insert oi1;
            oi2 = new Order_Item__c();
            oi2.Asset__c = ass2.Id;
            oi2.Status__c = 'Pending De-Installation';
            oi2.Total_Rooms_Ordered__c = 600;
            oi2.Total_Remaining_Rooms__c = 100;
            //insert oi2;
            List<Order_Item__c> lstoi = new list<Order_Item__c>();   //jjackson
            lstoi.add(oi1);
            lstoi.add(oi2);
            insert lstoi;
            
            ai1 = new Associated_Item__c();
            ai1.Card_ID__c = '123';
            ai1.Receiver_ID__c = '345';
            ai1.Serial_Number__c = '456';
            ai1.Order_Item__c = oi1.Id;
            ai1.Work_Order__c = wo.Id;
            ai1.Flagged_for_Billing__c = true;
            ai1.Submitted_for_Billing__c = false;
            //insert ai1;
            ai2 = new Associated_Item__c();
            ai2.Order_Item__c = oi2.Id;
            ai2.Work_Order__c = wo.Id;
            ai2.Flagged_for_Billing__c = true;
            ai2.Submitted_for_Billing__c = false;
            //insert ai2;
            List<Associated_Item__c> lstai = new list<Associated_Item__c>();  //jjackson
            lstai.add(ai1);
            lstai.add(ai2);
            insert lstai;
                //Update Associated Item fields and set Work Order to complete
            ai1.Quantity__c = 500;
            ai1.Status__c = 'Installed Activated';
            //update ai1;
            ai2.Quantity__c = -50;
            ai2.Status__c = 'De-Installed';
            //update ai2;
            List<Associated_Item__c> lstupdai = new list<Associated_Item__c>(); //jjackson
            lstupdai.add(ai1);
            lstupdai.add(ai2);
            update lstupdai;
            
            wo.Status__c = 'Install Complete';
            wo.Previous_Status_Go_Live__c = false;
            update wo;
            Test.startTest();
            //Create Child Work Order
            Work_Order__c woChild = new Work_Order__c(RecordTypeId = workOrderRecordTypeRackBuild,Parent_Work_Order__c = wo.Id);
            insert woChild;
            woChild.Status__c = 'Complete';
			update woChild;
			        
            Test.stopTest();
            
            ass1 = [SELECT Card_ID__c, Receiver_ID__c, SerialNumber from Asset WHERE Id = :ass1.Id];
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationRackBuildChild Test .  ********** results' +ass1.Card_ID__C);
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationRackBuildChild Test .  ********** results' +ass1.Receiver_ID__C);
            System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationRackBuildChild Test .  ********** results' +ass1.SerialNumber);
            //system.assert(ass1.Card_ID__C == '123','Card ID on asset should be 123, is '+ass1.Card_Id__c);
            //system.assert(ass1.Receiver_ID__C == '345');
            //system.assert(ass1.SerialNumber == '456');
        }
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationRackBuildChild Test .  **********  Finished');
    }


    static testMethod void testProductActivationInsertionBulk()
    {
    	System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInsertionBulk Test .  **********    START');
        //Create Assets
        Account acc = DataGenerator.createAccounts(1,true)[0];
        List<Asset> assList = new List<Asset>();
        for(Integer i = 0; i < 200; i++)
        {
            assList.add(new Asset(AccountId = acc.Id, Name = 'Test Asset'+i, Status = 'Pending Install'));
        }
        insert assList;
        
        //Create Work Orders
        List<Work_Order__c> woList = new List<Work_Order__c>();
        for(Integer i = 0; i < 200; i++)
        {
            woList.add(new Work_Order__c());
        }
        insert woList;
        
        //Create Order Items
        List<Order_Item__c> oiList = new List<Order_Item__c>();
        for(Integer i = 0; i < 200; i++)
        {
            Order_Item__c temp = new Order_Item__c();
            temp.Asset__c = assList.get(i).Id;
            temp.Status__c = 'Pending Install';
            temp.Total_Rooms_Ordered__c = 100;
            temp.Total_Remaining_Rooms__c = 100;
            oiList.add(temp);
        }
        insert oiList;
        
        //Create Associated Items
        List<Associated_Item__c> aiList = new List<Associated_Item__c>();
        for(Integer i = 0; i < 200 ; i++)
        {
            Associated_Item__c temp = new Associated_Item__c();
            temp.Order_Item__c = oiList.get(i).Id;
            temp.Work_Order__c = woList.get(i).Id;
            temp.Quantity__c = 100;
            // temp.Status__c = 'Installed On';
            temp.Status__c = 'Installed Activated';
            temp.Flagged_for_billing__c = true; 
            temp.Submitted_for_Billing__c = false;
            
            ailist.add(temp);
        }
        insert aiList;
        
        //Start Test
        Test.startTest();
        for(Work_Order__c wo : woList)
        {
            // wo.Status__c = 'Install Complete';
            wo.Status__c = 'Billing/Go Live';
            wo.Previous_Status_Complete__c = false;
            
        }
        update woList;
        
        Test.stopTest();
        
        List<Product_Activation__c> paList = [SELECT Id from Product_Activation__c];
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInsertionBulk Test .  ********** Should be 200 Product Activations, there are : '+paList.size());
        //system.assert(paList.size() == 200, 'Should be 200 Product Activations, there are : '+paList.size());
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInsertionBulk Test .  **********    Finished');
        
    }


    static testMethod void testProductActivationInsertionBulkonSingleWorkOrder()
    {
    	System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInsertionBulkonSingleWorkOrder Test .  **********    START');
        //Create Assets
       
        Account acc = DataGenerator.createAccounts(1,true)[0];
        List<Asset> assList = new List<Asset>();
        //Start Test
        Test.startTest();


        for(Integer i = 0; i < 200; i++)
        {
            assList.add(new Asset(AccountId = acc.Id, Name = 'Test Asset'+i, Status = 'Pending Install'));
        }
        insert assList;
        
        //Create Work Orders
        Work_Order__c wo = new Work_Order__c();
        insert wo;
        
        //Create Order Items
        List<Order_Item__c> oiList = new List<Order_Item__c>();
        for(Integer i = 0; i < 200; i++)
        {
            Order_Item__c temp = new Order_Item__c();
            temp.Asset__c = assList.get(i).Id;
            temp.Status__c = 'Pending Install';
            temp.Total_Rooms_Ordered__c = 100;
            temp.Total_Remaining_Rooms__c = 100;
            oiList.add(temp);
        }
        insert oiList;
        
        //Create Associated Items
        List<Associated_Item__c> aiList = new List<Associated_Item__c>();
        for(Integer i = 0; i < 200 ; i++)
        {
            Associated_Item__c temp = new Associated_Item__c();
            temp.Order_Item__c = oiList.get(i).Id;
            temp.Work_Order__c = wo.Id;
            temp.Quantity__c = 100;
            // temp.Status__c = 'Installed On';
            temp.Status__c = 'Installed Activated';
            temp.Flagged_for_billing__c = true; 
            temp.Submitted_for_Billing__c = false;
            ailist.add(temp);
        }
        insert aiList;
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInsertionBulkonSingleWorkOrder Test .  **********  ailist insert '+aiList.size());
        
        // wo.Status__c = 'Install Complete';
        wo.Status__c = 'Billing/Go Live';
        wo.Previous_Status_Complete__c = false;
        update wo;
        
        Test.stopTest();
        
        List<Product_Activation__c> paList = [SELECT Id from Product_Activation__c];
        //system.assert(paList.size() == 200, 'Should be 200 Product Activations, there are : '+paList.size());
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest testProductActivationInsertionBulkonSingleWorkOrder Test .  **********    Finished');
    }
    
    */
}