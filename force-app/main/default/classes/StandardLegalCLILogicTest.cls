@isTest
public with sharing class StandardLegalCLILogicTest {
    /*shawks 02/2019 - CPQ: Comment out all since not needed after using out-of-box Subscription object
    static testMethod void testRollupSummary()
    {
		Account a = new Account(Name = 'Test Account');
		insert a;
    	Product2 p0 = new Product2(Name = 'Test Product', Family = 'FTG'); 
    	insert p0;
    	Product2 p1 = new Product2(Name = 'Test Product', Channel_Type__c = 'HD');
    	insert p1;
    	Product2 p2 = new Product2(Name = 'Test Product', Channel_Type__c = 'Analog');
    	insert p2;
    	Product2 p3 = new Product2(Name = 'Test Product', Channel_Type__c = 'SD');
    	insert p3;
    	Contract__c c = new Contract__c(Account_Name__c = a.Id);
    	insert c;
           
     	Contract_Line_Item__c o1 = new Contract_Line_Item__c(Legal_Contract__c = c.Id, Product__c = p0.Id, Status__c = 'Installed Activated', quantity__c = 1);
    	insert o1;
    	Contract_Line_Item__c o2 = new Contract_Line_Item__c(Legal_Contract__c = c.Id, Parent__c = o1.Id, Product__c = p1.Id, Status__c = 'Installed Activated', Product_Parent_Id__c = o1.id, quantity__c = 1);
    	Contract_Line_Item__c o3 = new Contract_Line_Item__c(Legal_Contract__c = c.Id, Parent__c = o1.Id, Product__c = p2.Id, Status__c = 'Installed Activated', Product_Parent_Id__c = o1.id, quantity__c = 1);
    	Contract_Line_Item__c o4 = new Contract_Line_Item__c(Legal_Contract__c = c.Id, Parent__c = o1.Id, Product__c = p3.Id, Status__c = 'Installed Activated', Product_Parent_Id__c = o1.id, quantity__c = 1);

    	Test.startTest();

    	insert o2;
		insert o3;
		insert o4;    	
		o4.Status__c = 'Billing';
		update o4;
		
    	Test.stopTest();
    	o1 = [SELECT HD_Channel_Count__C, SD_Channel_Count__c, Analog_Channel_Count__c from Contract_Line_Item__c WHERE Id = :o1.Id][0];
    	system.assert(o1.HD_Channel_Count__c == 1, 'HD channel count is ' +o1.HD_Channel_Count__c);
    	system.assert(o1.SD_Channel_Count__c == 1, 'SD Channel count is '+o1.SD_Channel_Count__c);
    	system.assert(o1.Analog_Channel_Count__c == 1, 'Analog Channel count is '+o1.Analog_Channel_Count__c);  
    }
    
    //jjackson 9/2015 added testing for equipment ownership on order items
    //jjackson 5/2016 expanded this test to include testing for update of project type and ownership changes on all
    //line items from parent; testing of quantity update on product inventory (asset) when changed on contract line item.
    static testMethod void testUpdateProjectType()
    {
    	Account a1 = new Account(Name = 'New Test Account');
		insert a1;

    	Contract__c c1 = new Contract__c(Account_Name__c = a1.Id);
    	insert c1;
    	    	
    	//jjackson 6/3/2014 must associate the line items with products to test the trigger after update code on line item hierarchy
        Product2 prodparent1 = new Product2(ProductCode = 'test-1234-567', Family = 'Interactive', Name = 'Test Product Parent');
        Product2 pkgpart = new Product2(ProductCode = 'pkg-222-333', Family = 'Interactive', Name = 'Test Package line part');
        Product2 childpart = new Product2(ProductCode = 'child-111-444', Family = 'Interactive', Name = 'Test child line part');
        //Product2 subchildpart = new Product2(ProductCode = 'subchild-333-444', Family = 'Interactive', Name = 'Test subchild line part');
        insert new List<Product2>{prodparent1,pkgpart,childpart};
        
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(Legal_Contract__c = c1.id, Conversion_Date__c = null, Product__c = prodparent1.id, Project_Type__c = 'Interactive New Rooms', Equipment_Ownership__c = 'SONIFI', Name='Test Product Parent', quantity__c = 1);
        insert cli1;
        Contract_Line_Item__c clipkg = new Contract_Line_Item__c(Legal_Contract__c = c1.id, Conversion_Date__c = null, Product__c = pkgpart.id, parent__c = cli1.id, Project_Type__c = 'Interactive New Rooms', Name='Test Package line part', quantity__c = 1);
        insert clipkg;
        Contract_Line_Item__c clichild = new Contract_Line_Item__c(Legal_Contract__c = c1.id, Conversion_Date__c = null, Product__c = childpart.id, parent__c = clipkg.id, Project_Type__c = 'Interactive New Rooms', Name='Test child line part', quantity__c = 1);
        insert clichild;
        
        Asset ass1 = New Asset(Legal_Contract__c = c1.id, legal_contract_line_item__c = cli1.id, product2id = prodparent1.id, Name = 'Test Product Parent',
                             quantity = 1, accountid = a1.id, status = 'Installed Activated');
        insert ass1;
                             
        Asset ass2 = New Asset(Legal_Contract__c = c1.id, legal_contract_line_item__c = clipkg.id, product2id = pkgpart.id, Name = 'Test Package Line part',
                             quantity = 1, accountid = a1.id, parent_asset__c = ass1.id, status = 'Pending Installation Activate');
        insert ass2;
        
        Asset ass3 = New Asset(Legal_Contract__c = c1.id, legal_contract_line_item__c = clichild.id, product2id = childpart.id, Name = 'Test Child Part',
                             quantity = 1, accountid = a1.id, parent_asset__c = ass2.id, status = 'Pending Installation Activate');
        insert ass3;

 
        //jjackson 6/3/2014 Must create an order and order items for this test to determine whether update to Project_Type__c field
        //on the contract line item updates project_type__ c on the order item
        Order__c order1 = new Order__c(site__c = a1.id, legal_contract__c = c1.id, Project_Type__c = 'New Installation' );
        insert order1;
        system.debug('order1 id is ' + order1.id);
        
        Order_Item__c oi1 = new Order_Item__c(name = 'Test oi Product Parent', account__c = a1.Id, order__c = order1.Id, Legal_Contract_Line_Item__c = cli1.id,  Project_Type__c = 'Interactive Room Change');
        insert oi1;
        Order_Item__c oi2 = new Order_Item__c(name = 'Test oi2 Package', account__c = a1.Id, order__c = order1.Id, Legal_Contract_Line_Item__c = clipkg.id, Project_Type__c = 'Interactive Room Change', parent__c = oi1.id);
        insert oi2;
  
        List<Contract_Line_Item__c> contritmlist = new list <Contract_Line_Item__c>();
        List<Contract_Line_Item__c> updqtylist = New List<Contract_Line_Item__c>();
        List<Contract_Line_Item__c> updcontritem = New List<Contract_Line_Item__c>();
        Set<Id> lcliset = new set<Id>();
        

		
        Test.StartTest();
    
    	contritmlist = [Select Id, Name, Product__c, Parent__c, Legal_Contract__c, Project_Type__c, Equipment_Ownership__c from Contract_Line_Item__c where Legal_Contract__c = :c1.Id  ];
            
        for(Contract_Line_Item__c contritm : contritmlist)
        {
           	if(contritm.Name == 'Test Product Parent')
        	{ contritm.Equipment_Ownership__c = 'CUST';
        	  contritm.Project_Type__c = 'FTG New Rooms';
        	  contritm.term_start_date__c = system.today();
        	  contritm.term_end_date__c = system.today();
         	  contritm.price__c = 50.00;
         	  contritm.quantity__c = 2;
        	  updcontritem.add(contritm);
        	  
        	}
        	else
        	{  	contritm.quantity__c = 2; 
        	    updcontritem.add(contritm);
        	}
        }
        update updcontritem;
        
        List<Order_Item__c> orditemlist = new list<Order_Item__c>();
        orditemlist = [Select Id, Name, project_type__c, equipment_ownership__c, legal_contract_line_item__c from Order_Item__c ];
        
        List<Asset> assetlist = New List<Asset>();
        assetlist = [Select Id, Name, quantity, term_end_date__c, service_end_date__c, price__c from Asset ];
 
             
        Test.StopTest();
    	
    	//jjackson 6/3/2014 verify the related order items were updated when the project type on the contract line item was updated
        //jjackson 9/2015 verify the equipment ownership on the related order item updated when the ownership was changed on the lcli


		
		system.debug('test order item list size is ' +orditemlist.size());
		system.debug('test assetlist size is ' +assetlist.size());
		
        for(Order_Item__c orditem : orditemlist)
        {
       		//system.debug('project type on ' +orditem.name +' is ' +orditem.project_type__c);
       		//system.debug('for order item ' +orditem.name +' equipment ownership is ' +orditem.equipment_ownership__c);
       		system.assert(orditem.project_type__c == 'FTG New Rooms');
       		system.assert(orditem.equipment_ownership__c == 'CUST');
  
        }
        
        for(Asset assetrec : assetlist)
        {
        	//system.debug('asset name in loop is ' +assetrec.name +' and term end date is ' +assetrec.term_end_date__c);
        	//system.debug('asset name in loop is ' +assetrec.name +' and service end date is ' +assetrec.service_end_date__c);
        	//system.debug('asset name in loop is ' +assetrec.name + ' and quantity is ' +assetrec.quantity);
        	//system.debug('asset name in loop is ' +assetrec.name +' and price is ' +assetrec.price__c);
        	
        	if(assetrec.name == 'Test Product Parent')
        	{
        		system.assert(assetrec.quantity == 2);
        		system.assert(assetrec.term_end_date__c == system.today());
        		system.assert(assetrec.service_end_date__c == system.today());
        		system.assert(assetrec.price__c == 50.00);
        		
        	}
        	else
        	{
        		system.assert(assetrec.quantity == 2.00);
        	}
        }
    }
*/
}