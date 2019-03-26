/****************************************************************

jjackson 10/2018:  removed references to order_item__c.product_inventory__c
and replaced with order_item__c.asset__c.
*****************************************************************/

@isTest
public with sharing class WorkOrderItemHierarchyExtensionTest {

	static testMethod void testBasicWorkOrderHierarchy()
	{
        //Acquire test user of Profile Admin Manager
        Profile pfl = [select id from profile where name='System Administrator'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';
        User testUser = new User(alias = 'testuser', email=randomName ,
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = pfl.Id,  country='United States', CommunityNickname = 'u1',
            timezonesidkey='America/Los_Angeles', username=randomName);
        //Test Sobjects var declaration
        Order_Item__c oi1;
        Order_Item__c oi2;
        Associated_Item__c ai1;
        Associated_Item__c ai2;
        Associated_Item__c ai3;
        Product2 p1 = New Product2(name = 'Test Product Parent', ProductCode = 'CC-test-pp', Family = 'FTG');
        insert p1;
        Product2 p2 = New Product2(name = 'Test product 2', productcode = 'CC-test-product2');
        insert p2;
        
        Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
        Id workOrderRecordTypeRackBuild = Utilities.RecordTypeNameToId('Work_Order__c', 'Rack Build');
        

        
        system.runAs(testUser)
        {
            //Create Account and Asset
            Account acc = DataGenerator.createAccounts(1,true)[0];
  
            //Create Work Order, Order Item and Associated Item
            Work_Order__c wo = new Work_Order__c(RecordTypeId = workOrderRecordType, Site__c = acc.id,
                                                 Install_Manager__c = testuser.id, project_coordinator__c = testuser.id,
                                                 approver__c = testuser.id, division__c = 'Domestic', region__c = 'Western',
                                                 Name = 'testname' );
            insert wo;
 
            //shawks 201810: CPQ - Comment out the code that creates contract and contract line item records; remove references to them
            /*//shawks BUG-00176: Add Contract and Lines since Delivery Method on Legal Contract Line Items now
		    Contract__c lc = new Contract__c(Account_Name__c=acc.id,Status__c='Order Approved', lifetime_value_of_deal__c = 1000,
		                upfront_subsidy__c = 100  );
		    insert lc;
		    Contract_Line_Item__c lcli1 = new Contract_Line_Item__c(Name='Test Product Parent', Legal_Contract__c=lc.id, Project_Type__c='Interactive New Rooms',
		                              Status__c='Pending Installation Activate', Product__c=p1.id, Delivery_Method__c = 'DirecTV-A-4/4-TH',
			                          quantity__c = 100, equipment_ownership__c = 'CUST');
            insert lcli1;

            oi1 = new Order_Item__c(status__c = 'Pending Installation Activate', total_rooms_ordered__c = 100, Legal_Contract_Line_Item__c=lcli1.id,
            */
            oi1 = new Order_Item__c(status__c = 'Pending Installation Activate', total_rooms_ordered__c = 100, total_remaining_rooms__c = 500,  
                                    product__c = p1.id, name = 'Test Product Parent');
            insert oi1;
            
 			oi2 = New Order_Item__c(status__c = 'Pending De-Installation', total_rooms_ordered__c = 600,
                                    total_remaining_rooms__c = 100, product__c = p2.id, name = 'Test Order Item 2',
                                    parent__c = oi1.id);
            insert oi2;
 
            ai1 = new Associated_Item__c();
            ai1.Order_Item__c = oi1.Id;
            ai1.Work_Order__c = wo.Id;
            ai1.Name = 'Test Product Parent';
            ai1.Project_Number__c = 'Test123';
            ai1.Status__c = 'Pending Installation Activate';
            ai1.quantity__c = 100;
            //insert ai1;
            ai2 = new Associated_Item__c();
            ai2.Order_Item__c = oi2.Id;
            ai2.Work_Order__c = wo.Id;
            ai2.Name = 'TestItem2';
            //insert ai2;
            List<Associated_Item__c> lstai = new List<Associated_Item__c>();
            lstai.add(ai1);
            lstai.add(ai2);
            insert lstai;
            
            PageReference pageRef = Page.WorkOrderItemHierarchy; 
            //pageRef.getParameters().put('workOrder', wo);
            //pageRef.getParameters().put('ai', ai1);
            //pageRef.getParameters().put('workOrderRecordType', wo.recordtypeid);
 			Test.setCurrentPageReference(pageRef);
            Test.startTest();
			WorkOrderItemHierarchyExtension vc = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo));
             //jjackson i added all the way down to ai2
            Work_Order__c wofrompage = vc.workOrder;
            Associated_Item__c aifrompage = vc.ai;
            String jsonfrompage = vc.treeJSON;
    		String values = vc.statusValuesJSON;
    		String qvalues = vc.quarterChargedValuesJSON;
    		String yvalues = vc.yearChargedValuesJSON;
    		String prefix = vc.assocItemPrefix;
     		Boolean puser = vc.isPortalUser;
    		Boolean isedit = vc.editMode;
    		String url = vc.saveURL;
    		String returl = vc.returnURL;
    		String rectype = vc.workOrderRecordType;
    		Boolean israck = vc.isRackBuild;
    		Boolean iscustom = vc.isCustomWorkOrder;
    		Boolean iscircuit = vc.isCircuitWorkOrder;
    		Id woparent = vc.workOrderParentId;
			Set<Id> setindev = vc.inDevelopmentIds;
            
            pageRef.getParameters().put('mode', 'edit');
            
            ai2.quantity__c = 100;
            ai2.billing_commencement_date__c = system.today();
            ai1.receiver_channel__c = 30.1;

            vc.saveAssociatedItems();
           
            
            //Insert Child Work Order
            Work_Order__c wo2 = new Work_Order__c(RecordTypeId = workOrderRecordTypeRackBuild, Parent_Work_Order__c = wo.Id);
            insert wo2;
            ai3 = new Associated_Item__c();
            ai3.Order_Item__c = oi1.Id;
            ai3.Work_Order__c = wo2.Id;
            ai3.Name = 'TestItem3';
            insert ai3;
           // lstai.add(ai3);
           // insert lstai;
            PageReference pr = Page.WorkOrderItemHierarchy;
       		pr.getParameters().put('selectedKeys','['+JSON.serialize(ai1.id) + ']');
       		pr.getParameters().put('selectedAssocItemIds','['+JSON.serialize(ai1.id) + ']');
       		
       		pr.getParameters().put('editedData','');
            Test.setCurrentPageReference(pr);

			WorkOrderItemHierarchyExtension con = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo));
	        con.saveAssociatedItems();
	        con.massUpdateFields();
	        con.cloneAssociatedItems();
	        con.submitWorkOrder();
	        con.deleteAssociatedItems();
	        con.returnWorkOrder();
			WorkOrderItemHierarchyExtension con2 = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo2));
	        
            Test.stopTest();
        }
	}

	//shawks BUG-00753:  Quantity Adjustment - Wrong Project Type test
	static testMethod void testWOQtyAdj_WrongProjectType()
	{
	   Integer quantity_initial = 100;
	   Integer quantity_01 = 3;
	   User testUser = DataGenerator.createUsers('System Administrator',1,true)[0];  //Create user
	   Account acc = DataGenerator.createAccounts(1,true)[0];                        //Create Account
	   
	   Id workOrderRecordType_QtyAdj = Utilities.RecordTypeNameToId('Work_Order__c', 'Install Qty Adjustment');
	   //Create an "Install Qty Adjustment" work order without an adjustment Project Type
	   Work_Order__c wo_qty_adj = new Work_Order__c(RecordTypeID = workOrderRecordType_QtyAdj, Site__c = acc.id,
	                                                Name = 'testWorkOrder', Project_Type__c = '');
	   insert wo_qty_adj;

       List<Product2> prod2 = DataGenerator.createProducts(1,true);
       Asset testAsset = DataGenerator.createAssets(prod2,acc.id,'Installed Activated',false)[0];
       testAsset.quantity = quantity_initial;
       insert testAsset;
       
       Product_Activation__c prod_act_initial = new Product_Activation__c(Name=testAsset.Name,Type__c='Activation',
                                                                          Quantity__c=quantity_initial,Product_Inventory__c=testAsset.Id);
       insert prod_act_initial;

       Order_Item__c oi1 = new Order_Item__c(status__c = 'Installed Activated', total_rooms_ordered__c = 100,
                               total_remaining_rooms__c = 500, name = 'Test Order Product Parent');
       insert oi1;
       Order_Item__c oi2 = New Order_Item__c(status__c = 'Installed Activated', total_rooms_ordered__c = 600,
                               total_remaining_rooms__c = 100, name = 'Test Order Item 2',
                               parent__c = oi1.id, asset__c = testAsset.id);
       insert oi2;
       
       Associated_Item__c ai1 = new Associated_Item__c();
       ai1.Name='Test Product Parent';
       ai1.Order_Item__c=oi1.Id;
       ai1.Work_Order__c=wo_qty_adj.Id;
       ai1.quantity__c=quantity_initial;

       Associated_Item__c ai2 = new Associated_Item__c();
       ai2.Name='Test Item2';
       ai2.Order_Item__c=oi2.Id;
       ai2.Work_Order__c=wo_qty_adj.Id;
       ai2.quantity__c=quantity_initial;
       List<Associated_Item__c> lstai = new List<Associated_Item__c>();
       lstai.add(ai1);
       lstai.add(ai2);
       insert lstai;

	   //"Finalize" button
	   PageReference pr = Page.WorkOrderItemHierarchy;
	   pr.getParameters().put('mode', 'edit');
	   WorkOrderItemHierarchyExtension woext = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo_qty_adj));
       pr.getParameters().put('selectedKeys','['+JSON.serialize(ai2.id) + ']');
       pr.getParameters().put('selectedQuantity',String.valueOf(quantity_01));

       List<ApexPages.Message> lstmsgs = new List<ApexPages.Message>();
	   Test.startTest();
	   Test.setCurrentPageReference(pr);
	   woext.massUpdateFields();

	   lstmsgs = Apexpages.getMessages();
	   system.assert(lstmsgs.size() == 1, lstmsgs);  //Should generate a message

       //"Save Items" button
       PageReference pr2 = Page.WorkOrderItemHierarchy;
       pr2.getParameters().put('mode', 'edit');
       pr2.getParameters().put('editedData','[{"RecordId":"'+ai2.Id+'","editedFields":[{"FieldValue":"'+quantity_01+'","FieldName":"Quantity__c"}]}]');
       WorkOrderItemHierarchyExtension woext2 = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo_qty_adj));
       Test.setCurrentPageReference(pr2);
       woext2.saveAssociatedItems();

       List<ApexPages.Message> lstmsgs2 = new List<ApexPages.Message>();
       lstmsgs2 = Apexpages.getMessages();
       system.assert(lstmsgs2.size() == 1, lstmsgs2);  //Should generate a message

       //"Submit Items for Qty Adjustment" button
       PageReference pr3 = Page.WorkOrderItemHierarchy;
       pr3.getParameters().put('mode', 'edit');
       pr3.getParameters().put('selectedKeys','['+JSON.serialize(ai2.id) + ']');
       pr3.getParameters().put('selectedQuantity',String.valueOf(quantity_01));
       WorkOrderItemHierarchyExtension woext3 = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo_qty_adj));
       Test.setCurrentPageReference(pr3);
       woext3.submitQtyAdjust();
	   
	   lstmsgs = Apexpages.getMessages();
	   system.debug('Apex message size: ' +lstmsgs.size());
	   system.debug(lstmsgs);
       system.assert(lstmsgs.size() == 2, lstmsgs);   //Should generate a message
       //Verify the associated item quantity did not change
       Associated_Item__c testAssocItem = [ SELECT Id, Name, Quantity__c FROM Associated_Item__c WHERE Id = :ai2.Id LIMIT 1];
       system.assertEquals(quantity_initial,testAssocItem.Quantity__c, testAssocItem.Quantity__c+' returned instead of '+quantity_initial);
	   Test.stopTest();
	}

	//shawks BUG-00753:  Quantity Adjustment - Adjust Down test
	static testMethod void testWOQtyAdj_Down()
	{
	   Integer quantity_initial = 100;
	   Integer quantity_01 = 3;
	   Integer quantity_02 = 5;

	   User testUser = DataGenerator.createUsers('System Administrator',1,true)[0];  //Create user
	   Account acc = DataGenerator.createAccounts(1,true)[0];                        //Create Account
	   
	   Id workOrderRecordType_QtyAdj = Utilities.RecordTypeNameToId('Work_Order__c', 'Install Qty Adjustment');
	   //Create an "Install Qty Adjustment" work order
	   Work_Order__c wo_qty_adj = new Work_Order__c(RecordTypeID = workOrderRecordType_QtyAdj, Site__c = acc.id,
	                                                Name = 'testWorkOrder', Project_Type__c = 'Adjust Down');
	   insert wo_qty_adj;

       List<Product2> prod2 = DataGenerator.createProducts(1,true);
       Asset testAsset = DataGenerator.createAssets(prod2,acc.id,'Installed Activated',false)[0];
       testAsset.quantity = quantity_initial;
       insert testAsset;
       
       Product_Activation__c prod_act_initial = new Product_Activation__c(Name=testAsset.Name,Type__c='Activation',
                                                                          Quantity__c=quantity_initial,Product_Inventory__c=testAsset.Id);
       insert prod_act_initial;

       Order_Item__c oi1 = new Order_Item__c(status__c = 'Installed Activated', total_rooms_ordered__c = 100,
                               total_remaining_rooms__c = 500, name = 'Test Order Product Parent');
       insert oi1;
       Order_Item__c oi2 = New Order_Item__c(status__c = 'Installed Activated', total_rooms_ordered__c = 600,
                               total_remaining_rooms__c = 100, name = 'Test Order Item 2',
                               parent__c = oi1.id, asset__c = testAsset.id);
       insert oi2;
       
       Associated_Item__c ai1 = new Associated_Item__c();
       ai1.Name='Test Product Parent';
       ai1.Order_Item__c=oi1.Id;
       ai1.Work_Order__c=wo_qty_adj.Id;
       ai1.quantity__c=quantity_initial;

       Associated_Item__c ai2 = new Associated_Item__c();
       ai2.Name='Test Item2';
       ai2.Order_Item__c=oi2.Id;
       ai2.Work_Order__c=wo_qty_adj.Id;
       ai2.quantity__c=quantity_initial;
       List<Associated_Item__c> lstai = new List<Associated_Item__c>();
       lstai.add(ai1);
       lstai.add(ai2);
       insert lstai;

	   //"Finalize" button
	   PageReference pr = Page.WorkOrderItemHierarchy;
	   pr.getParameters().put('mode', 'edit');
	   WorkOrderItemHierarchyExtension woext = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo_qty_adj));
       pr.getParameters().put('selectedKeys','['+JSON.serialize(ai2.id) + ']');
       pr.getParameters().put('selectedQuantity',String.valueOf(quantity_01));

       List<ApexPages.Message> lstmsgs = new List<ApexPages.Message>();
	   Test.startTest();
	   Test.setCurrentPageReference(pr);
	   woext.massUpdateFields();

	   lstmsgs = Apexpages.getMessages();
	   system.assert(lstmsgs.size() == 0, lstmsgs);  //Should not generate a message

       //"Save Items" button
       PageReference pr2 = Page.WorkOrderItemHierarchy;
       pr2.getParameters().put('mode', 'edit');
       pr2.getParameters().put('editedData','[{"RecordId":"'+ai2.Id+'","editedFields":[{"FieldValue":"'+quantity_02+'","FieldName":"Quantity__c"}]}]');
       WorkOrderItemHierarchyExtension woext2 = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo_qty_adj));
       Test.setCurrentPageReference(pr2);
       woext2.saveAssociatedItems();
       List<ApexPages.Message> lstmsgs2 = new List<ApexPages.Message>();
       lstmsgs2 = Apexpages.getMessages();
       system.assert(lstmsgs2.size() == 0, lstmsgs2);  //Should not generate a message

       //"Submit Items for Qty Adjustment" button
       pr2.getParameters().put('selectedAssocItemIDs','['+JSON.serialize(ai2.id) + ']');
       WorkOrderItemHierarchyExtension woext3 = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo_qty_adj));
       woext3.submitQtyAdjust();
	   lstmsgs = Apexpages.getMessages();
       system.assert(lstmsgs.size() == 0, lstmsgs);   //Should not generate a message
       //Verify the associated item quantity and "Installed Quantity" changed properly
       Associated_Item__c testAssocItem = [ SELECT Id, Name, Quantity__c, order_item__r.asset__r.Total_Active_Rooms__c
                                            FROM Associated_Item__c WHERE Id = :ai2.Id LIMIT 1];
       system.debug('Adjust Down - New Installed Qty = '+testAssocItem.order_item__r.asset__r.Total_Active_Rooms__c);
       system.assertEquals(quantity_02,testAssocItem.Quantity__c, testAssocItem.Quantity__c+' returned ai quantity instead of '+quantity_initial);
       system.assertEquals(quantity_initial-quantity_02, testAssocItem.order_item__r.asset__r.Total_Active_Rooms__c,
                           testAssocItem.order_item__r.asset__r.Total_Active_Rooms__c+' returned Installed Qty instead of '+(quantity_initial-quantity_02));
	   Test.stopTest();
	}

	//shawks BUG-00753:  Quantity Adjustment - Adjust Up test
	static testMethod void testWOQtyAdj_Up()
	{
	   Integer quantity_initial = 100;
	   Integer quantity_01 = 3;
	   Integer quantity_02 = 5;

	   User testUser = DataGenerator.createUsers('System Administrator',1,true)[0];  //Create user
	   Account acc = DataGenerator.createAccounts(1,true)[0];                        //Create Account
	   
	   Id workOrderRecordType_QtyAdj = Utilities.RecordTypeNameToId('Work_Order__c', 'Install Qty Adjustment');
	   //Create an "Install Qty Adjustment" work order
	   Work_Order__c wo_qty_adj = new Work_Order__c(RecordTypeID = workOrderRecordType_QtyAdj, Site__c = acc.id,
	                                                Name = 'testWorkOrder', Project_Type__c = 'Adjust Up');
	   insert wo_qty_adj;

       List<Product2> prod2 = DataGenerator.createProducts(1,true);
       Asset testAsset = DataGenerator.createAssets(prod2,acc.id,'Installed Activated',false)[0];
       testAsset.quantity = quantity_initial;
       insert testAsset;
       
       Product_Activation__c prod_act_initial = new Product_Activation__c(Name=testAsset.Name,Type__c='Activation',
                                                                          Quantity__c=(quantity_initial - (quantity_02 - 1)),Product_Inventory__c=testAsset.Id);
       insert prod_act_initial;

       Order_Item__c oi1 = new Order_Item__c(status__c = 'Installed Activated', total_rooms_ordered__c = 100,
                               total_remaining_rooms__c = 500, name = 'Test Order Product Parent');
       insert oi1;

       Order_Item__c oi2 = New Order_Item__c(status__c = 'Installed Activated', total_rooms_ordered__c = 600,
                               total_remaining_rooms__c = 100, name = 'Test Order Item 2',
                               parent__c = oi1.id, asset__c = testAsset.id);
       insert oi2;
       
       Associated_Item__c ai1 = new Associated_Item__c();
       ai1.Name='Test Product Parent';
       ai1.Order_Item__c=oi1.Id;
       ai1.Work_Order__c=wo_qty_adj.Id;
       ai1.quantity__c=quantity_initial;

       Associated_Item__c ai2 = new Associated_Item__c();
       ai2.Name='Test Item2';
       ai2.Order_Item__c=oi2.Id;
       ai2.Work_Order__c=wo_qty_adj.Id;
       ai2.quantity__c=quantity_initial;
       List<Associated_Item__c> lstai = new List<Associated_Item__c>();
       lstai.add(ai1);
       lstai.add(ai2);
       insert lstai;

	   //"Finalize" button
	   PageReference pr = Page.WorkOrderItemHierarchy;
	   pr.getParameters().put('mode', 'edit');
	   WorkOrderItemHierarchyExtension woext = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo_qty_adj));
       pr.getParameters().put('selectedKeys','['+JSON.serialize(ai2.id) + ']');
       pr.getParameters().put('selectedQuantity',String.valueOf(quantity_02));

       List<ApexPages.Message> lstmsgs = new List<ApexPages.Message>();
	   Test.startTest();
	   Test.setCurrentPageReference(pr);
	   woext.massUpdateFields();

	   lstmsgs = Apexpages.getMessages();
	   system.assert(lstmsgs.size() == 1, lstmsgs);  //Should generate a message since quantity will exceed max quantity

       //"Save Items" button
       PageReference pr2 = Page.WorkOrderItemHierarchy;
       pr2.getParameters().put('mode', 'edit');
       pr2.getParameters().put('editedData','[{"RecordId":"'+ai2.Id+'","editedFields":[{"FieldValue":"'+quantity_01+'","FieldName":"Quantity__c"}]}]');
       WorkOrderItemHierarchyExtension woext2 = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo_qty_adj));
       Test.setCurrentPageReference(pr2);
       woext2.saveAssociatedItems();

       //"Submit Items for Qty Adjustment" button
       pr2.getParameters().put('selectedAssocItemIDs','['+JSON.serialize(ai2.id) + ']');
       WorkOrderItemHierarchyExtension woext3 = new WorkOrderItemHierarchyExtension(new ApexPages.StandardController(wo_qty_adj));
       woext3.submitQtyAdjust();

       //Verify the associated item quantity and "Installed Quantity" changed properly
       Associated_Item__c testAssocItem = [ SELECT Id, Name, Quantity__c, order_item__r.asset__r.Total_Active_Rooms__c
                                            FROM Associated_Item__c WHERE Id = :ai2.Id LIMIT 1];
       system.debug('Adjust Up - New Installed Qty = '+testAssocItem.order_item__r.asset__r.Total_Active_Rooms__c);
       system.assertEquals(quantity_01,testAssocItem.Quantity__c, testAssocItem.Quantity__c+' returned ai quantity instead of '+quantity_01);
       system.assertEquals(quantity_initial - (quantity_02 - 1) + quantity_01, testAssocItem.order_item__r.asset__r.Total_Active_Rooms__c,
                           testAssocItem.order_item__r.asset__r.Total_Active_Rooms__c+' returned Installed Qty instead of '+(quantity_initial - (quantity_02 - 1) + quantity_01));
	   Test.stopTest();
	}
}