@isTest
public with sharing class StandardSubscriptionTriggerLogicTest {
    static testMethod void testRollupSummary()
    {
		Account a = new Account(Name = 'Test Account');
		insert a;

    	Product2 p0 = new Product2(Name = 'Test Product Parent', Family = 'FTG'); 
    	Product2 p1 = new Product2(Name = 'Test Product HD', Channel_Type__c = 'HD');
    	Product2 p2 = new Product2(Name = 'Test Product Analog', Channel_Type__c = 'Analog');
    	Product2 p3 = new Product2(Name = 'Test Product SD', Channel_Type__c = 'SD');
    	Product2 p4 = new Product2(Name = 'Test Product SD2', Channel_Type__c = 'SD');
    	insert New List<Product2>{p0, p1, p2, p3, p4};

    	Contract c = new Contract(AccountId = a.Id);
    	insert c;

     	SBQQ__Subscription__c s1 = new SBQQ__Subscription__c(SBQQ__Account__c = a.id, SBQQ__Contract__c = c.Id, SBQQ__Product__c = p0.Id, Status__c = 'Installed Activated', 
     	                                                     SBQQ__Quantity__c = 1, Name__c='Test Product Parent');
    	insert s1;
    	SBQQ__Subscription__c s2 = new SBQQ__Subscription__c(SBQQ__Account__c = a.id, SBQQ__Contract__c = c.Id, SBQQ__Product__c = p1.Id, Status__c = 'Installed Activated', 
    	                                                     SBQQ__Quantity__c = 1, Name__c = 'Test Product HD', Parent__c = s1.Id);
//???    	                                                     Name__c = 'Test Product HD', Product_Parent_Id__c = s1.id, Parent__c = s1.Id);
    	SBQQ__Subscription__c s3 = new SBQQ__Subscription__c(SBQQ__Account__c = a.id, SBQQ__Contract__c = c.Id, SBQQ__Product__c = p2.Id, Status__c = 'Installed Activated', 
    	                                                     SBQQ__Quantity__c = 1, Name__c = 'Test Product Analog', Parent__c = s1.Id);
//???    	                                                     Name__c='Test Product Analog', Product_Parent_Id__c = s1.id, Parent__c = s1.Id);
    	SBQQ__Subscription__c s4 = new SBQQ__Subscription__c(SBQQ__Account__c = a.id, SBQQ__Contract__c = c.Id, SBQQ__Product__c = p3.Id, Status__c = 'Installed Activated',
    	                                                     SBQQ__Quantity__c = 1, Name__c = 'Test Product SD', Parent__c = s1.Id);
//???    	                                                     Name__c='Test Product SD', Product_Parent_Id__c = s1.id, Parent__c = s1.Id);
    	insert New List<SBQQ__Subscription__c>{s2, s3, s4};
    	

    	Test.startTest();
//???		s4.Status__c = 'Pending Installation Activate';
//???		update s4;
		
SBQQ__Subscription__c s5 = new SBQQ__Subscription__c(SBQQ__Account__c = a.id, SBQQ__Contract__c = c.Id, SBQQ__Product__c = p4.Id, Status__c = 'Installed Activated', 
                                                     SBQQ__Quantity__c = 1, Name__c = 'Test Product SD Child', Parent__c = s4.Id);
insert s5;
    	Test.stopTest();

//<<???
List<SBQQ__Subscription__c> lsttstsubs = [ SELECT Id, Name__c, Product_Parent_Id__c,SBQQ__Product__r.Channel_Type__c, sbqq__product__r.family, status__c
                     FROM SBQQ__Subscription__c
                     WHERE Product_Parent_Id__c <> NULL
//???                                         ]; 
/*    	             WHERE Product_Parent_Id__c != null AND product_parent_id__c IN :parentcliIds
 */ 
AND SBQQ__Product__r.Channel_Type__c <> NULL
                       AND (sbqq__product__r.family = 'FTG'
                         OR parent__r.sbqq__product__r.family = 'FTG'
                         OR parent__r.parent__r.sbqq__product__r.family = 'FTG'
                         OR parent__r.parent__r.parent__r.sbqq__product__r.family = 'FTG'
                         OR parent__r.parent__r.parent__r.parent__r.sbqq__product__r.family = 'FTG')
                       AND (Status__c = 'Installed Activated' OR Status__c = 'Pending Installation Activate' OR Status__c = 'Pending De-Installation')];

system.debug('CPQ: Sub Count = '+ lsttstsubs.size());

//???>>
//???    	SBQQ__Subscription__c sub1 = [ SELECT HD_Channel_Count__C, SD_Channel_Count__c, Analog_Channel_Count__c from SBQQ__Subscription__c WHERE Id = :s1.Id ][0];
SBQQ__Subscription__c sub1 = [ SELECT name, name__c, HD_Channel_Count__C, SD_Channel_Count__c, Analog_Channel_Count__c from SBQQ__Subscription__c WHERE Id = :s1.Id ][0];
system.debug('CPQ:  Sub Name: '+sub1.name+'; '+sub1.name__c);
        system.debug('HD/SD/Analog values: '+ sub1.HD_Channel_Count__c+', '+sub1.SD_Channel_Count__c+', '+sub1.Analog_Channel_Count__c);
    	system.assert(sub1.HD_Channel_Count__c == 1, 'HD channel count is ' +sub1.HD_Channel_Count__c);
    	system.assert(sub1.Analog_Channel_Count__c == 1, 'Analog Channel count is '+sub1.Analog_Channel_Count__c);
    	system.assert(sub1.SD_Channel_Count__c == 2, 'SD Channel count is '+sub1.SD_Channel_Count__c);
    }

    //jjackson 9/2015 added testing for equipment ownership on order items
    //jjackson 5/2016 expanded this test to include testing for update of project type and ownership changes on all
    //line items from parent; testing of quantity update on product inventory (asset) when changed on contract line item.
    static testMethod void testUpdateProjectType()
    {
    	Account a1 = new Account(Name = 'New Test Account');
		insert a1;

    	Contract c1 = new Contract(AccountId = a1.Id);
    	insert c1;

    	//jjackson 6/3/2014 must associate the line items with products to test the trigger after update code on line item hierarchy
        Product2 prodparent1 = new Product2(ProductCode = 'test-1234-567', Family = 'Interactive', Name = 'Test Product Parent');
        Product2 pkgpart = new Product2(ProductCode = 'pkg-222-333', Family = 'Interactive', Name = 'Test Package line part');
        Product2 childpart = new Product2(ProductCode = 'child-111-444', Family = 'Interactive', Name = 'Test child line part');
        //Product2 subchildpart = new Product2(ProductCode = 'subchild-333-444', Family = 'Interactive', Name = 'Test subchild line part');
        insert new List<Product2>{prodparent1,pkgpart,childpart};

        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(SBQQ__Contract__c = c1.id, Conversion_Date__c = null, SBQQ__Product__c  = prodparent1.id, Project_Type__c = 'Interactive New Rooms', Equipment_Ownership__c = 'SONIFI', Name__c='Test Product Parent', SBQQ__Quantity__c = 1);
        insert sub1;
        SBQQ__Subscription__c clipkg = new SBQQ__Subscription__c(SBQQ__Contract__c = c1.id, Conversion_Date__c = null, SBQQ__Product__c  = pkgpart.id, parent__c = sub1.id, Project_Type__c = 'Interactive New Rooms', Name__c='Test Package line part', SBQQ__Quantity__c = 1);
        insert clipkg;
        SBQQ__Subscription__c clichild = new SBQQ__Subscription__c(SBQQ__Contract__c = c1.id, Conversion_Date__c = null, SBQQ__Product__c  = childpart.id, parent__c = clipkg.id, Project_Type__c = 'Interactive New Rooms', Name__c='Test child line part', SBQQ__Quantity__c = 1);
        insert clichild;

        Asset ass1 = New Asset(Contract__c = c1.id, Subscription_item__c = sub1.id, product2id = prodparent1.id, Name = 'Test Product Parent',
                             quantity = 1, accountid = a1.id, status = 'Installed Activated');
        insert ass1;

        Asset ass2 = New Asset(Contract__c = c1.id, Subscription_item__c = clipkg.id, product2id = pkgpart.id, Name = 'Test Package Line part',
                             quantity = 1, accountid = a1.id, parent_asset__c = ass1.id, status = 'Pending Installation Activate');
        insert ass2;

        Asset ass3 = New Asset(Contract__c = c1.id, Subscription_item__c = clichild.id, product2id = childpart.id, Name = 'Test Child Part',
                             quantity = 1, accountid = a1.id, parent_asset__c = ass2.id, status = 'Pending Installation Activate');
        insert ass3;

        //jjackson 6/3/2014 Must create an order and order items for this test to determine whether update to Project_Type__c field
        //on the contract line item updates project_type__ c on the order item
        Order__c order1 = new Order__c(site__c = a1.id, Project_Type__c = 'New Installation' );
        insert order1;
        system.debug('order1 id is ' + order1.id);

        Order_Item__c oi1 = new Order_Item__c(name = 'Test oi Product Parent', account__c = a1.Id, order__c = order1.Id, Subscription__c = sub1.id,  Project_Type__c = 'Interactive Room Change');
        insert oi1;
        Order_Item__c oi2 = new Order_Item__c(name = 'Test oi2 Package', account__c = a1.Id, order__c = order1.Id, Subscription__c = clipkg.id, Project_Type__c = 'Interactive Room Change', parent__c = oi1.id);
        insert oi2;

        List<SBQQ__Subscription__c> sublist = new list <SBQQ__Subscription__c>();
        List<SBQQ__Subscription__c> updsub = New List<SBQQ__Subscription__c>();

        Test.StartTest();
    	sublist = [ Select Id, Name__c, SBQQ__Product__c, Parent__c, SBQQ__Contract__c, Project_Type__c, Equipment_Ownership__c from SBQQ__Subscription__c where SBQQ__Contract__c = :c1.Id  ];
            
        for(SBQQ__Subscription__c subscrpt : sublist)
        {
           	if(subscrpt.Name__c == 'Test Product Parent')
        	{ subscrpt.Equipment_Ownership__c = 'CUST';
        	  subscrpt.Project_Type__c = 'FTG New Rooms';
        	  subscrpt.SBQQ__SubscriptionStartDate__c = system.today();
        	  subscrpt.SBQQ__SubscriptionEndDate__c = system.today();
         	  subscrpt.SBQQ__RegularPrice__c = 50.00;
         	  subscrpt.SBQQ__Quantity__c = 2;
        	  updsub.add(subscrpt);
        	}
        	else
        	{  	subscrpt.SBQQ__Quantity__c = 2; 
        	    updsub.add(subscrpt);
        	}
        }
        update updsub;
        
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
}