@istest
public with sharing class WorkOrderTriggerLogicTestTurnOnNotice {
	
	
	static testMethod void testTurnOnNoticeAfterApproval()
	{
			Account acc = DataGenerator.createAccounts(1,true)[0];
			acc.of_Rooms__c = 100;
			acc.Physical_City__c = 'Sioux Falls';
			acc.Physical_State__c = 'SD';
			acc.Name = 'TestAccount';
			update acc;
			
			List<User> userlist = new List<User>();
			User newuser;
			userlist = DataGenerator.CreateUsers('System Administrator',1,true);
			for(User recuser : userlist)
			{  newuser = recuser;   }
			
			Product2 parentproduct = new Product2(Name='Test Product Parent', ProductCode='CC-testpp');
			insert parentproduct;
			Product2 pkgproduct = new Product2(Name='TestPackage', ProductCode='CC-pkg');
			insert pkgproduct;
			Product2 childproduct = new Product2(Name='TestChild', ProductCode='CC-child');
			insert childproduct;
					
			//shawks 201810: CPQ - Replace Contract__c object references with Contract object
			//-> Replace: Account_Name__c -> AccountId; Status__c -> Contract_Status__c; Removed lifetime_value_of_deal__c since not included on object or needed for test
			//Contract__c lc = new Contract__c(Account_Name__c=acc.id,Status__c='Order Approved', lifetime_value_of_deal__c = 1000, upfront_subsidy__c = 100  );
			//Contract lc = new Contract(AccountId=acc.id, Status='Order Approved', upfront_subsidy__c = 100);
			Contract lc = new Contract(AccountId=acc.id, Contract_Status__c='Order Approved', upfront_subsidy__c = 100);
			insert lc;

			//shawks 201810: CPQ - Replace contract_line_item___c object references with SBQQ__Subscription__c object
			//-> Replace: Name -> Name__c; Legal_Contract__c -> SBQQ__Contract__c; product__c -> SBQQ__Product__c; Quantiy__c -> SBQQ__Quantity__c
			//Contract_Line_Item__c lcli1 = new Contract_Line_Item__c(Name='Test Product Parent', Legal_Contract__c=lc.id, Project_Type__c='Interactive New Rooms',Status__c='Pending Installation Activate', Product__c=parentproduct.id,
			//                                                        quantity__c = 100, equipment_ownership__c = 'CUST');
			SBQQ__Subscription__c lcli1 = new SBQQ__Subscription__c(Name__c='Test Product Parent', SBQQ__Contract__c=lc.id, Project_Type__c='Interactive New Rooms',
			                                                        Status__c='Pending Installation Activate', SBQQ__Product__c=parentproduct.id,
			                                                        SBQQ__Quantity__c = 100, equipment_ownership__c = 'CUST');
			insert lcli1;

			//Contract_Line_Item__c lcli2 = new Contract_Line_Item__c(Name='TestPackage', Legal_Contract__c=lc.id, Parent__c=lcli1.Id, Product__c=pkgproduct.id,Status__c='Pending Installation Activate', quantity__c = 100);
			//Contract_Line_Item__c lcli3 = new Contract_Line_Item__c(Name='TestChild', Legal_Contract__c=lc.id, Parent__c=lcli1.id,Product__c=childproduct.id, Status__c='Pending Installation Activate', quantity__c = 100);
			SBQQ__Subscription__c lcli2 = new SBQQ__Subscription__c(Name__c='TestPackage', SBQQ__Contract__c=lc.id, Parent__c=lcli1.Id, SBQQ__Product__c=pkgproduct.id,Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);
			SBQQ__Subscription__c lcli3 = new SBQQ__Subscription__c(Name__c='TestChild', SBQQ__Contract__c=lc.id, Parent__c=lcli1.id,SBQQ__Product__c=childproduct.id, Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);
			
			//List<Contract_Line_Item__c> lclilist = new list<Contract_Line_Item__c>();
			List<SBQQ__Subscription__c> lclilist = new list<SBQQ__Subscription__c>();
			lclilist.add(lcli2);
			lclilist.add(lcli3);
			insert lclilist;
			
			//shawks 201810: CPQ - Replace: legal_contract_line_item__c -> Subscription__c
			//Asset parentasset = New Asset(Name = 'Test Product Parent', legal_contract_line_item__c = lcli1.Id, status = 'Pending Installation Activate', accountid = acc.id);
			Asset parentasset = New Asset(Name = 'Test Product Parent', Subscription_item__c = lcli1.Id, status = 'Pending Installation Activate', accountid = acc.id);
			insert parentasset;
			
			//Asset pkgasset = New Asset(Name = 'TestPackage', parent_asset__c = parentasset.id, legal_contract_line_item__c = lcli2.id, status = 'Pending Installation Activate', accountid = acc.id);
			//Asset childasset = New Asset(Name = 'TestChild', parent_asset__c = parentasset.id, legal_contract_line_item__c = lcli3.id, status = 'Pending De-Installation', accountid = acc.id);
			Asset pkgasset = New Asset(Name = 'TestPackage', parent_asset__c = parentasset.id, Subscription_item__c = lcli2.id, status = 'Pending Installation Activate', accountid = acc.id);
			Asset childasset = New Asset(Name = 'TestChild', parent_asset__c = parentasset.id, Subscription_item__c = lcli3.id, status = 'Pending De-Installation', accountid = acc.id);
			List<Asset> addasset = New List<Asset>();
			addasset.add(pkgasset);
			addasset.add(childasset);
			insert addasset;
			
			Order__c neworder = new Order__c(Name='TestOrder',Status__c='Order Approved', Site__c=acc.id);
			insert neworder;
			
			//shawks 201810: CPQ - Replace: Legal_Contract_Line_Item__c -> Subscription__c
        	Order_Item__c oi1 = new Order_Item__c(Name='Test Product Parent',Product__c=parentproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.Today(),
        	                                      //Order__c = neworder.id, Legal_Contract_Line_Item__c=lcli1.id, Status__c='Billing', asset__c = parentasset.id,
        	                                      Order__c = neworder.id, Subscription__c=lcli1.id, Status__c='Billing', asset__c = parentasset.id,
        	                                      total_remaining_rooms__c = 100) ;
         	insert oi1;
         	
         	Order_Item__c oi2 = new Order_Item__c(Name = 'TestPackage', Product__c=pkgproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.today(),
        	                                      //Order__c=neworder.id,Parent__c=oi1.id,Legal_Contract_Line_Item__c=lcli2.id,Status__c='Billing', asset__c = pkgasset.id,
        	                                      Order__c=neworder.id,Parent__c=oi1.id,Subscription__c=lcli2.id,Status__c='Billing', asset__c = pkgasset.id,
        	                                      total_remaining_rooms__c = 100);
         	
        	Order_Item__c oi3 = new Order_Item__c(Name = 'TestChild', Product__c=childproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.today(),
        	                                      //Order__c=neworder.id,Parent__c=oi1.id,Legal_Contract_Line_Item__c=lcli3.id,Status__c='Billing', asset__c = childasset.id,
        	                                      Order__c=neworder.id,Parent__c=oi1.id,Subscription__c=lcli3.id,Status__c='Billing', asset__c = childasset.id,
        	                                      total_remaining_rooms__c = 100);
        	List<Order_Item__c> addoi = New List<Order_Item__c>();
        	addoi.add(oi2);
        	addoi.add(oi3);
        	insert addoi;
  	
        	Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
            Work_Order__c wo = new Work_Order__c(RecordTypeId=workOrderRecordType,Status__c='Billing/Go Live',Site__c=acc.id,Install_Manager__c=newuser.id,
                               Project_Coordinator__c=newuser.id,Approver__c=newuser.id, Division__c='Domestic',Region__c='Midwest',
                               Approval_Status__c = 'Pending Billing Approval');
            insert wo;
 
        	Associated_Item__c ai1 = new Associated_Item__c(Name='Test Product Parent', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
        	                                                Order_Item__c=oi1.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=true,
        	                                                Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=75);
        	Associated_Item__c ai2 = new Associated_Item__c(Name='TestPackage', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
        	                                                Order_Item__c=oi2.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=true,
        	                                                Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=75);
  
         	Associated_Item__c ai3 = new Associated_Item__c(Name='TestChild', Status__c='De-Installed', Billing_Commencement_Date__c=system.today(),
        	                                                Order_Item__c=oi3.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=true,
        	                                                Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=100);
        	                                                
        	List<Associated_Item__c> lstaitems = new list<Associated_Item__c>();
        	lstaitems.add(ai1);
        	lstaitems.add(ai2);
        	lstaitems.add(ai3);
        	
        	Test.startTest();
        	insert lstaitems;
    	
        	wo.Approval_Status__c = 'Billing Approved';
  
        	update wo;
        	//WorkOrderTriggerLogic.CreateTurnOnNotice(lstaitems);
   

        	
        	Work_Order__c updworkorder = [ Select Id, Name, Approval_Status__c from Work_Order__c LIMIT 1 ];
        	List<Associated_Item__c> lstupdai = new List<Associated_Item__c>();
        	lstupdai = [ Select Name, Status__c, Added_to_TurnonNotice__c, submitted_for_billing__c, order_item__r.total_remaining_rooms__c,
        	             order_item__r.asset__r.status, order_item__r.asset__r.service_start_date__c, id, (Select associated_item__c, Id, Name from Product_Activation__r) from Associated_Item__c ];
        	
        	system.debug('work order approval status is ' +updworkorder.Approval_Status__c);
            
            for(Associated_Item__c recai : lstupdai)
            {
            	system.assertequals(false, recai.Added_to_Turnonnotice__c);
				system.debug('Assoc Item is ' +recai.Name +', ' +recai.status__c +', ' +recai.order_item__r.total_remaining_rooms__c);
				system.debug('Assoc Item is ' +recai.Name +', ' +recai.order_item__r.asset__r.status +', ' +recai.order_item__r.asset__r.service_start_date__c);
				system.assertequals(true, recai.submitted_for_billing__c);
			  if(recai.Name == 'Test Product Parent' || recai.Name == 'TestPackage')
			  {
			  	system.assertequals(recai.status__c, 'Installed Activated');
				system.assertequals(recai.order_item__r.asset__r.status, 'Billing');
				system.assert(recai.order_item__r.total_remaining_rooms__c == 25);
			  }
            }
            
            List<Product_Activation__c> lstnewpa = New List<Product_Activation__c>();
            for(Associated_Item__c ai : lstupdai )
            {
            	for(Product_Activation__c pa : ai.Product_Activation__r)
            	{ lstnewpa.add(pa);  }
            }
            system.assert(lstnewpa.size() == 3);
          	test.stopTest();

	}

	//shawks:BUG-00717 - Test for Healthcare Turn On Notice
	static testMethod void testTurnOnNoticeHealthcare()
	{
			Account acc = DataGenerator.createAccounts(1,true)[0];
			acc.of_Rooms__c = 100;
			acc.Physical_City__c = 'Sioux Falls';
			acc.Physical_State__c = 'SD';
			acc.Name = 'TestAccount';
			acc.Type = 'Healthcare Site';
			update acc;
			
			List<User> userlist = new List<User>();
			User newuser;
			userlist = DataGenerator.CreateUsers('System Administrator',1,true);
			for(User recuser : userlist)
			{  newuser = recuser;   }
			
            Product2 parentproduct = new Product2(Name='Test Product Parent', ProductCode='CC-testpp');
            Product2 pkgproduct = new Product2(Name='TestPackage', ProductCode='CC-pkg');
            Product2 childproduct = new Product2(Name='TestChild', ProductCode='CC-child');
            Product2 parentproduct02 = new Product2(Name='Test Product Parent02', ProductCode='CC-testpp02');
            Product2 pkgproduct02 = new Product2(Name='TestPackage02', ProductCode='CC-pkg02');
            Product2 parentproduct03 = new Product2(Name='Test Product Parent03', ProductCode='CC-testpp03');
            Product2 childproduct03 = new Product2(Name='TestChild03', ProductCode='CC-child03');

            List<Product2> lstproduct2 = New List<Product2>();
            lstproduct2.add(parentproduct);
            lstproduct2.add(pkgproduct);
            lstproduct2.add(childproduct);
            lstproduct2.add(parentproduct02);
            lstproduct2.add(pkgproduct02);
            lstproduct2.add(parentproduct03);
            lstproduct2.add(childproduct03);
            insert lstproduct2;

			//shawks 201810: CPQ - Replace Contract__c object references with Contract object
			//-> Replace: Account_Name__c -> AccountId; Status__c -> Contract_Status__c; Removed lifetime_value_of_deal__c since not included on object or needed for test
			//Contract__c lc = new Contract__c(Account_Name__c=acc.id,Status__c='Order Approved', lifetime_value_of_deal__c = 1000, upfront_subsidy__c = 100  );
			Contract lc = new Contract(AccountId=acc.id,Contract_Status__c='Order Approved', upfront_subsidy__c = 100);
			insert lc;

			//shawks 201810: CPQ - Replace contract_line_item___c object references with SBQQ__Subscription__c object
			//-> Replace: Name -> Name__c; Legal_Contract__c -> SBQQ__Contract__c; product__c -> SBQQ__Product__c; Quantiy__c -> SBQQ__Quantity__c
			/*Contract_Line_Item__c lcli1 = new Contract_Line_Item__c(Name='Test Product Parent', Legal_Contract__c=lc.id, Project_Type__c='Interactive New Rooms',Status__c='Pending Installation Activate', Product__c=parentproduct.id,
			                                                        quantity__c = 100, equipment_ownership__c = 'CUST');
			Contract_Line_Item__c lcli2 = new Contract_Line_Item__c(Name='TestPackage', Legal_Contract__c=lc.id, Parent__c=lcli1.Id, Product__c=pkgproduct.id,Status__c='Pending Installation Activate', quantity__c = 100);
			Contract_Line_Item__c lcli3 = new Contract_Line_Item__c(Name='TestChild', Legal_Contract__c=lc.id, Parent__c=lcli1.id,Product__c=childproduct.id, Status__c='Pending Installation Activate', quantity__c = 100);

			Contract_Line_Item__c lcli02_1 = new Contract_Line_Item__c(Name='Test Product Parent02', Legal_Contract__c=lc.id, Project_Type__c='Interactive New Rooms',Status__c='Pending Installation Activate', Product__c=parentproduct02.id,
			                                                        quantity__c = 100, equipment_ownership__c = 'CUST');
			Contract_Line_Item__c lcli02_2 = new Contract_Line_Item__c(Name='TestPackage02', Legal_Contract__c=lc.id, Parent__c=lcli02_1.Id, Product__c=pkgproduct02.id,Status__c='Pending Installation Activate', quantity__c = 100);
			
			Contract_Line_Item__c lcli03_1 = new Contract_Line_Item__c(Name='Test Product Parent03', Legal_Contract__c=lc.id, Project_Type__c='Interactive New Rooms',Status__c='Pending Installation Activate', Product__c=parentproduct03.id,
			                                                        quantity__c = 100, equipment_ownership__c = 'CUST');
			Contract_Line_Item__c lcli03_2 = new Contract_Line_Item__c(Name='TestChild03', Legal_Contract__c=lc.id, Parent__c=lcli03_1.id,Product__c=childproduct03.id, Status__c='Pending Installation Activate', quantity__c = 100);

            List<Contract_Line_Item__c> lclilist = new list<Contract_Line_Item__c>();
            */
			SBQQ__Subscription__c lcli1 = new SBQQ__Subscription__c(Name__c='Test Product Parent', SBQQ__Contract__c=lc.id, Project_Type__c='Interactive New Rooms',Status__c='Pending Installation Activate', SBQQ__Product__c=parentproduct.id,
			                                                        SBQQ__Quantity__c = 100, equipment_ownership__c = 'CUST');
			SBQQ__Subscription__c lcli2 = new SBQQ__Subscription__c(Name__c='TestPackage', SBQQ__Contract__c=lc.id, Parent__c=lcli1.Id, SBQQ__Product__c=pkgproduct.id,Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);
			SBQQ__Subscription__c lcli3 = new SBQQ__Subscription__c(Name__c='TestChild', SBQQ__Contract__c=lc.id, Parent__c=lcli1.id,SBQQ__Product__c=childproduct.id, Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);

			SBQQ__Subscription__c lcli02_1 = new SBQQ__Subscription__c(Name__c='Test Product Parent02', SBQQ__Contract__c=lc.id, Project_Type__c='Interactive New Rooms',Status__c='Pending Installation Activate', SBQQ__Product__c=parentproduct02.id,
			                                                        SBQQ__Quantity__c = 100, equipment_ownership__c = 'CUST');
			SBQQ__Subscription__c lcli02_2 = new SBQQ__Subscription__c(Name__c='TestPackage02', SBQQ__Contract__c=lc.id, Parent__c=lcli02_1.Id, SBQQ__Product__c=pkgproduct02.id,Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);
			
			SBQQ__Subscription__c lcli03_1 = new SBQQ__Subscription__c(Name__c='Test Product Parent03', SBQQ__Contract__c=lc.id, Project_Type__c='Interactive New Rooms',Status__c='Pending Installation Activate', SBQQ__Product__c=parentproduct03.id,
			                                                        SBQQ__Quantity__c = 100, equipment_ownership__c = 'CUST');
			SBQQ__Subscription__c lcli03_2 = new SBQQ__Subscription__c(Name__c='TestChild03', SBQQ__Contract__c=lc.id, Parent__c=lcli03_1.id,SBQQ__Product__c=childproduct03.id, Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);

            List<SBQQ__Subscription__c> lclilist = new list<SBQQ__Subscription__c>();
            lclilist.add(lcli1);
            lclilist.add(lcli2);
            lclilist.add(lcli3);
            lclilist.add(lcli02_1);
            lclilist.add(lcli02_2);
            lclilist.add(lcli03_1);
            lclilist.add(lcli03_2);
            insert lclilist;
			
            //shawks 201810: CPQ - Replace: legal_contract_line_item__c -> Subscription__c
            //Asset parentasset = New Asset(Name = 'Test Product Parent', legal_contract_line_item__c = lcli1.Id, status = 'Pending Installation Activate', accountid = acc.id);
            //Asset parentasset02 = New Asset(Name = 'Test Product Parent02', legal_contract_line_item__c = lcli02_1.Id, status = 'Pending Installation Activate', accountid = acc.id);
            //Asset parentasset03 = New Asset(Name = 'Test Product Parent03', legal_contract_line_item__c = lcli03_1.Id, status = 'Pending Installation Activate', accountid = acc.id);
            Asset parentasset = New Asset(Name = 'Test Product Parent', Subscription_item__c = lcli1.Id, status = 'Pending Installation Activate', accountid = acc.id);
            Asset parentasset02 = New Asset(Name = 'Test Product Parent02', Subscription_item__c = lcli02_1.Id, status = 'Pending Installation Activate', accountid = acc.id);
            Asset parentasset03 = New Asset(Name = 'Test Product Parent03', Subscription_item__c = lcli03_1.Id, status = 'Pending Installation Activate', accountid = acc.id);

            List<Asset> lstparentasset = New List<Asset>();
            lstparentasset.add(parentasset);
            lstparentasset.add(parentasset02);
            lstparentasset.add(parentasset03);
            insert lstparentasset;
			
			//Asset pkgasset = New Asset(Name = 'TestPackage', parent_asset__c = parentasset.id, legal_contract_line_item__c = lcli2.id, status = 'Pending Installation Activate', accountid = acc.id);
			//Asset childasset = New Asset(Name = 'TestChild', parent_asset__c = parentasset.id, legal_contract_line_item__c = lcli3.id, status = 'Pending De-Installation', accountid = acc.id);
			//Asset pkgasset02 = New Asset(Name = 'TestPackage02', parent_asset__c = parentasset02.id, legal_contract_line_item__c = lcli02_2.id, status = 'Pending Installation Activate', accountid = acc.id);
			//Asset childasset03 = New Asset(Name = 'TestChild03', parent_asset__c = parentasset03.id, legal_contract_line_item__c = lcli03_2.id, status = 'Pending De-Installation', accountid = acc.id);
			Asset pkgasset = New Asset(Name = 'TestPackage', parent_asset__c = parentasset.id, Subscription_item__c = lcli2.id, status = 'Pending Installation Activate', accountid = acc.id);
			Asset childasset = New Asset(Name = 'TestChild', parent_asset__c = parentasset.id, Subscription_item__c = lcli3.id, status = 'Pending De-Installation', accountid = acc.id);
			Asset pkgasset02 = New Asset(Name = 'TestPackage02', parent_asset__c = parentasset02.id, Subscription_item__c = lcli02_2.id, status = 'Pending Installation Activate', accountid = acc.id);
			Asset childasset03 = New Asset(Name = 'TestChild03', parent_asset__c = parentasset03.id, Subscription_item__c = lcli03_2.id, status = 'Pending De-Installation', accountid = acc.id);

			List<Asset> addasset = New List<Asset>();
			addasset.add(pkgasset);
			addasset.add(childasset);
			addasset.add(pkgasset02);
			addasset.add(childasset03);
			insert addasset;
			
			Order__c neworder = new Order__c(Name='TestOrder',Status__c='Order Approved', Site__c=acc.id);
			insert neworder;
			
			//shawks 201810: CPQ - Replace: Legal_Contract_Line_Item__c -> Subscription__c
        	Order_Item__c oi1 = new Order_Item__c(Name='Test Product Parent',Product__c=parentproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.Today(),
        	                                      //Order__c = neworder.id, Legal_Contract_Line_Item__c=lcli1.id, Status__c='Billing', asset__c = parentasset.id,
        	                                      Order__c = neworder.id, Subscription__c=lcli1.id, Status__c='Billing', asset__c = parentasset.id,
        	                                      total_remaining_rooms__c = 100) ;
        	Order_Item__c oi02_1 = new Order_Item__c(Name='Test Product Parent02',Product__c=parentproduct02.id,Account__c=acc.id,Billing_Commencement_Date__c=system.Today(),
        	                                      //Order__c = neworder.id, Legal_Contract_Line_Item__c=lcli02_1.id, Status__c='Billing', asset__c = parentasset02.id,
        	                                      Order__c = neworder.id, Subscription__c=lcli02_1.id, Status__c='Billing', asset__c = parentasset02.id,
        	                                      total_remaining_rooms__c = 100) ;
        	Order_Item__c oi03_1 = new Order_Item__c(Name='Test Product Parent03',Product__c=parentproduct03.id,Account__c=acc.id,Billing_Commencement_Date__c=system.Today(),
        	                                      //Order__c = neworder.id, Legal_Contract_Line_Item__c=lcli03_1.id, Status__c='Billing', asset__c = parentasset03.id,
        	                                      Order__c = neworder.id, Subscription__c=lcli03_1.id, Status__c='Billing', asset__c = parentasset03.id,
        	                                      total_remaining_rooms__c = 100) ;

            List<Order_Item__c> addoiparent = New List<Order_Item__c>();
            addoiparent.add(oi1);
            addoiparent.add(oi02_1);
            addoiparent.add(oi03_1);
            insert addoiparent;

         	Order_Item__c oi2 = new Order_Item__c(Name = 'TestPackage', Product__c=pkgproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.today(),
        	                                      //Order__c=neworder.id,Parent__c=oi1.id,Legal_Contract_Line_Item__c=lcli2.id,Status__c='Billing',
        	                                      Order__c=neworder.id,Parent__c=oi1.id,Subscription__c=lcli2.id,Status__c='Billing',
        	                                      asset__c = pkgasset.id,Project_Type__c='Healthcare',total_remaining_rooms__c = 100);
        	Order_Item__c oi3 = new Order_Item__c(Name = 'TestChild', Product__c=childproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.today(),
        	                                      //Order__c=neworder.id,Parent__c=oi1.id,Legal_Contract_Line_Item__c=lcli3.id,Status__c='Billing',
        	                                      Order__c=neworder.id,Parent__c=oi1.id,Subscription__c=lcli3.id,Status__c='Billing',
        	                                      asset__c = childasset.id,Project_Type__c='Healthcare',total_remaining_rooms__c = 100);
         	Order_Item__c oi02_2 = new Order_Item__c(Name = 'TestPackage02', Product__c=pkgproduct02.id,Account__c=acc.id,Billing_Commencement_Date__c=system.today(),
        	                                      //Order__c=neworder.id,Parent__c=oi02_1.id,Legal_Contract_Line_Item__c=lcli02_2.id,Status__c='Billing',
        	                                      Order__c=neworder.id,Parent__c=oi02_1.id,Subscription__c=lcli02_2.id,Status__c='Billing',
        	                                      asset__c = pkgasset02.id,Project_Type__c='Healthcare',total_remaining_rooms__c = 100);
        	Order_Item__c oi03_2 = new Order_Item__c(Name = 'TestChild03', Product__c=childproduct03.id,Account__c=acc.id,Billing_Commencement_Date__c=system.today(),
        	                                      //Order__c=neworder.id,Parent__c=oi03_1.id,Legal_Contract_Line_Item__c=lcli03_2.id,Status__c='Billing',
        	                                      Order__c=neworder.id,Parent__c=oi03_1.id,Subscription__c=lcli03_2.id,Status__c='Billing',
        	                                      asset__c = childasset03.id,Project_Type__c='Healthcare',total_remaining_rooms__c = 100);

        	List<Order_Item__c> addoi = New List<Order_Item__c>();
        	addoi.add(oi2);
        	addoi.add(oi3);
        	addoi.add(oi02_2);
        	addoi.add(oi03_2);
        	insert addoi;
  	
        	Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
            Work_Order__c wo = new Work_Order__c(RecordTypeId=workOrderRecordType,Status__c='Billing/Go Live',Site__c=acc.id,Install_Manager__c=newuser.id,
                               Project_Coordinator__c=newuser.id,Approver__c=newuser.id, Division__c='Domestic',Region__c='Midwest',
                               Approval_Status__c = 'Pending Billing Approval',PO__c = 'PO-12345',CreatedByID=newuser.id);

            Work_Order__c wo02 = new Work_Order__c(RecordTypeId=workOrderRecordType,Status__c='Billing/Go Live',Site__c=acc.id,Install_Manager__c=newuser.id,
                               Project_Coordinator__c=newuser.id,Approver__c=newuser.id, Division__c='Domestic',Region__c='Midwest',
                               Approval_Status__c = 'Pending Billing Approval',PO__c = 'PO-54321',CreatedByID=newuser.id);

            Work_Order__c wo03 = new Work_Order__c(RecordTypeId=workOrderRecordType,Status__c='Billing/Go Live',Site__c=acc.id,Install_Manager__c=newuser.id,
                               Project_Coordinator__c=newuser.id,Approver__c=newuser.id, Division__c='Domestic',Region__c='Midwest',
                               Approval_Status__c = 'Pending Billing Approval',CreatedByID=newuser.id,De_Installation_Date__c=system.today());

            List<Work_Order__c> lstwo = New List<Work_Order__c>();
            lstwo.add(wo);
            lstwo.add(wo02);
            lstwo.add(wo03);
            insert lstwo;
 
        	Associated_Item__c ai1 = new Associated_Item__c(Name='Test Product Parent', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
        	                                                Order_Item__c=oi1.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=true,
        	                                                Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=75);
        	Associated_Item__c ai2 = new Associated_Item__c(Name='TestPackage', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
        	                                                Order_Item__c=oi2.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=true,
        	                                                Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=75);
         	Associated_Item__c ai3 = new Associated_Item__c(Name='TestChild', Status__c='De-Installed', Billing_Commencement_Date__c=system.today(),
        	                                                Order_Item__c=oi3.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=true,
        	                                                Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=100);

        	Associated_Item__c ai02_1 = new Associated_Item__c(Name='Test Product Parent02', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
        	                                                   Order_Item__c=oi02_1.id,Work_Order__c=wo02.id,Added_to_TurnonNotice__c=true,
        	                                                   Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=75);
        	Associated_Item__c ai02_2 = new Associated_Item__c(Name='TestPackage02', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
        	                                                   Order_Item__c=oi02_2.id,Work_Order__c=wo02.id,Added_to_TurnonNotice__c=true,
        	                                                   Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=75);
  
          	Associated_Item__c ai03_1 = new Associated_Item__c(Name='Test Product Parent03', Status__c='De-Installed', Billing_Commencement_Date__c=system.today(),
        	                                                   Order_Item__c=oi03_1.id,Work_Order__c=wo03.id,Added_to_TurnonNotice__c=true,
        	                                                   Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=75);
         	Associated_Item__c ai03_2 = new Associated_Item__c(Name='TestChild03', Status__c='De-Installed', Billing_Commencement_Date__c=system.today(),
        	                                                   Order_Item__c=oi03_2.id,Work_Order__c=wo03.id,Added_to_TurnonNotice__c=true,
        	                                                   Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=100);

        	List<Associated_Item__c> lstaitems = new list<Associated_Item__c>();
        	lstaitems.add(ai1);
        	lstaitems.add(ai2);
        	lstaitems.add(ai3);
        	lstaitems.add(ai02_1);
        	lstaitems.add(ai02_2);
        	lstaitems.add(ai03_1);
        	lstaitems.add(ai03_2);
        	insert lstaitems;

        	wo.Approval_Status__c = 'Billing Approved';
        	wo02.Approval_Status__c = 'Billing Approved';
        	wo03.Approval_Status__c = 'Billing Approved';
  
        	List<Work_Order__c> lstwoupdate = New List<Work_Order__c>();
        	lstwoupdate.add(wo);
        	lstwoupdate.add(wo02);
        	lstwoupdate.add(wo03);

        	Test.startTest();
        	update lstwoupdate;

        	Work_Order__c updworkorder = [ Select Id, Name, Approval_Status__c from Work_Order__c LIMIT 1 ];
        	List<Associated_Item__c> lstupdai = new List<Associated_Item__c>();
        	lstupdai = [ Select Name, Status__c, Added_to_TurnonNotice__c, submitted_for_billing__c, order_item__r.total_remaining_rooms__c,
        	             order_item__r.asset__r.status, order_item__r.asset__r.service_start_date__c, id, (Select associated_item__c, Id, Name from Product_Activation__r) from Associated_Item__c ];
        	
        	system.debug('work order approval status is ' +updworkorder.Approval_Status__c);
            
            for(Associated_Item__c recai : lstupdai)
            {
            	system.assertequals(false, recai.Added_to_Turnonnotice__c);
				system.debug('Assoc Item is ' +recai.Name +', ' +recai.status__c +', ' +recai.order_item__r.total_remaining_rooms__c);
				system.debug('Assoc Item is ' +recai.Name +', ' +recai.order_item__r.asset__r.status +', ' +recai.order_item__r.asset__r.service_start_date__c);
				system.assertequals(true, recai.submitted_for_billing__c);
			  if(recai.Name == 'Test Product Parent' || recai.Name == 'TestPackage')
			  {
			  	system.assertequals(recai.status__c, 'Installed Activated');
				system.assertequals(recai.order_item__r.asset__r.status, 'Billing');
				system.assert(recai.order_item__r.total_remaining_rooms__c == 25);
			  }
            }
            
            List<Product_Activation__c> lstnewpa = New List<Product_Activation__c>();
            for(Associated_Item__c ai : lstupdai )
            {
            	for(Product_Activation__c pa : ai.Product_Activation__r)
            	{ lstnewpa.add(pa);  }
            }
            system.assert(lstnewpa.size() == 7);
          	test.stopTest();
	}

	static testMethod void testActivateServiceContractswithTerm()
	{
		    system.debug('running test testActivateServiceContractswithTerm');
			Account acc = DataGenerator.createAccounts(1,true)[0];
			acc.of_Rooms__c = 100;
			acc.Physical_City__c = 'Sioux Falls';
			acc.Physical_State__c = 'SD';
			acc.Name = 'TestAccount';
			update acc;
			
			List<User> userlist = new List<User>();
			User newuser;
			userlist = DataGenerator.CreateUsers('System Administrator',1,true);
			for(User recuser : userlist)
			{  newuser = recuser;   }
			
			Product2 parentproduct = new Product2(Name='Test Product Parent', ProductCode='CC-testpp');
			Product2 pkgproduct = new Product2(Name='TestPackage', ProductCode='CC-pkg');
			Product2 childproduct = new Product2(Name='TestChild', ProductCode='CC-child');
			Product2 warrantyproduct = new Product2(Name='Warranty Test', ProductCode='CC-tstWarr', Family='Warranty');
			insert new List<Product2>{parentproduct,pkgproduct,childproduct,warrantyproduct};
			
			//shawks 201810: CPQ - Replace Contract__c object references with Contract object
			//-> Replace: Account_Name__c -> AccountId; Status__c -> Contract_Status__c; Removed lifetime_value_of_deal__c since not included on object or needed for test
			//Contract__c LegalContract = new Contract__c(Account_Name__c=acc.id,Status__c='Order Approved', lifetime_value_of_deal__c = 1000, upfront_subsidy__c = 100);
			Contract LegalContract = new Contract(AccountId=acc.id,Contract_Status__c='Order Approved', upfront_subsidy__c = 100);
			insert LegalContract;

			//Contract__c con = [ Select Id from Contract__c where Id = :LegalContract.Id LIMIT 1 ];
			Contract con = [ Select Id from Contract where Id = :LegalContract.Id LIMIT 1 ];
			Id conid = con.id;
			
			//shawks 201810: CPQ - Replace contract_line_item___c object references with SBQQ__Subscription__c object
			//-> Replace: Name -> Name__c; Legal_Contract__c -> SBQQ__Contract__c; product__c -> SBQQ__Product__c; Quantiy__c -> SBQQ__Quantity__c
			//Contract_Line_Item__c lcli1 = new Contract_Line_Item__c(Name='Test Product Parent', Legal_Contract__c=conid, Project_Type__c='Interactive New Rooms',Status__c='Pending Installation Activate', Product__c=parentproduct.id,
			//                                                        quantity__c = 100);
			SBQQ__Subscription__c lcli1 = new SBQQ__Subscription__c(Name__c='Test Product Parent', SBQQ__Contract__c=conid, Project_Type__c='Interactive New Rooms',
			                                                        Status__c='Pending Installation Activate', SBQQ__Product__c=parentproduct.id, SBQQ__Quantity__c = 100);
			insert lcli1;
			
			//Contract_Line_Item__c lcli2 = new Contract_Line_Item__c(Name='TestPackage', Legal_Contract__c=conid, Parent__c=lcli1.Id, Product__c=pkgproduct.id,Status__c='Pending Installation Activate', quantity__c = 100);
			SBQQ__Subscription__c lcli2 = new SBQQ__Subscription__c(Name__c='TestPackage', SBQQ__Contract__c=conid, Parent__c=lcli1.Id, SBQQ__Product__c=pkgproduct.id,Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);
			insert lcli2;
			
			//Contract_Line_Item__c lcli3 = new Contract_Line_Item__c(Name='TestChild', Legal_Contract__c=conid, Parent__c=lcli2.id,Product__c=childproduct.id, Status__c='Pending Installation Activate', quantity__c = 100);
			SBQQ__Subscription__c lcli3 = new SBQQ__Subscription__c(Name__c='TestChild', SBQQ__Contract__c=conid, Parent__c=lcli2.id,SBQQ__Product__c=childproduct.id, Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);
			insert lcli3;
			
			//Contract_Line_Item__c lcli4 = new Contract_Line_Item__c(Name='Warranty Test', Legal_Contract__c=conid, Parent__c=lcli1.Id, Product__c=warrantyproduct.id,Status__c='Pending Installation Activate', quantity__c = 100);
			SBQQ__Subscription__c lcli4 = new SBQQ__Subscription__c(Name__c='Warranty Test', SBQQ__Contract__c=conid, Parent__c=lcli1.Id, SBQQ__Product__c=warrantyproduct.id,Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);
			insert lcli4;

			//shawks 201810: CPQ - Replace: Legal_Contract_Line_Item__c -> Subscription__c
			//ServiceContract servicecon = new ServiceContract(Name='Warranty Test',Legal_Contract_Line_Item__c=lcli4.Id,Term=12, AccountId=acc.Id, NotificationNeeded__c = false);
			ServiceContract servicecon = new ServiceContract(Name='Warranty Test',Subscription__c=lcli4.Id,Term=12, AccountId=acc.Id, NotificationNeeded__c = false);
			
			Order__c neworder = new Order__c(Name='TestOrder',Status__c='Order Approved', Site__c=acc.id);
			insert neworder;

        	//shawks 201810: CPQ - Replace: Legal_Contract_Line_Item__c -> Subscription__c
        	Order_Item__c oi1 = new Order_Item__c(Name='Test Product Parent',Product__c=parentproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.Today(),
        	                                      //Order__c = neworder.id, Legal_Contract_Line_Item__c=lcli1.id, Status__c='Billing') ;
        	                                      Order__c = neworder.id, Subscription__c=lcli1.id, Status__c='Billing') ;
         	insert oi1;
        	
        	Order_Item__c oi2 = new Order_Item__c(Name = 'TestPackage', Product__c=pkgproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.today(),
        	                                      //Order__c=neworder.id,Parent__c=oi1.id,Legal_Contract_Line_Item__c=lcli2.id,Status__c='Billing');
        	                                      Order__c=neworder.id,Parent__c=oi1.id,Subscription__c=lcli2.id,Status__c='Billing');
        	insert oi2;
        	
          	Order_Item__c oi3 = new Order_Item__c(Name = 'TestChild', Product__c=childproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.today(),
        	                                      //Order__c=neworder.id,Parent__c=oi2.id,Legal_Contract_Line_Item__c=lcli3.id,Status__c='Billing');
        	                                      Order__c=neworder.id,Parent__c=oi2.id,Subscription__c=lcli3.id,Status__c='Billing');
        	insert oi3;
        	
        	Order_Item__c oi4 = new Order_Item__c(Name = 'Test Warranty', Product__c=warrantyproduct.Id, Account__c=acc.Id,Billing_Commencement_Date__c=system.today(),
        	                                       //Order__c=neworder.Id,Parent__c=oi1.Id,Legal_Contract_Line_Item__c=lcli4.Id,Status__c='Billing');
        	                                       Order__c=neworder.Id,Parent__c=oi1.Id,Subscription__c=lcli4.Id,Status__c='Billing');
            insert oi4;
            	
			test.startTest();
			        	
        	Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
            Work_Order__c wo = new Work_Order__c(RecordTypeId=workOrderRecordType,Status__c='In Progress',Site__c=acc.id,Install_Manager__c=newuser.id,
                               Project_Coordinator__c=newuser.id,Approver__c=newuser.id, Division__c='Domestic',Region__c='Midwest',
                               Approval_Status__c = 'Pending Billing Approval');
            insert wo;
         	
        	Associated_Item__c ai1 = new Associated_Item__c(Name='Test Product Parent', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
        	                                                Order_Item__c=oi1.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=false,
        	                                                Submitted_for_Billing__c=true,Flagged_for_Billing__c=true,Quantity__c=100);
        	Associated_Item__c ai2 = new Associated_Item__c(Name='TestPackage', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
        	                                                Order_Item__c=oi2.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=false,
        	                                                Submitted_for_Billing__c=true,Flagged_for_Billing__c=true,Quantity__c=100);
  
         	Associated_Item__c ai3 = new Associated_Item__c(Name='TestChild', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
        	                                                Order_Item__c=oi3.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=false,
        	                                                Submitted_for_Billing__c=true,Flagged_for_Billing__c=true,Quantity__c=100);
        	
        	Associated_Item__c ai4 = new Associated_Item__c(Name='Test Warranty', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
        	                                                Order_Item__c=oi4.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=false,
        	                                                Submitted_for_Billing__c=true,Flagged_for_Billing__c=true,Quantity__c=100);
        	                                                
        	List<Associated_Item__c> lstaitems = new list<Associated_Item__c>();
        	lstaitems.add(ai1);
        	lstaitems.add(ai2);
        	lstaitems.add(ai3);
        	lstaitems.add(ai4);
        	insert lstaitems;
        	
        	wo.Approval_Status__c = 'Billing Approved';
        	wo.Status__c = 'Billing/Go Live';  //this tests ActivateServiceContracts for service contract that has a term value
  
        	update wo;
        	//WorkOrderTriggerLogic.CreateTurnOnNotice(lstaitems);
        	
        	Work_Order__c updworkorder = [ Select Id, Name, Approval_Status__c from Work_Order__c where Id = :wo.Id LIMIT 1 ];
        	List<ServiceContract> servcon = [Select Id, Term, Name, StartDate, EndDate from ServiceContract ];
        	system.debug('servcon size for test with term is ' +servcon.size());
        	for(ServiceContract recservcon :servcon)
        	{	system.assertEquals(ai4.Billing_Commencement_Date__c,recservcon.StartDate);
        		system.assertEquals(ai4.Billing_Commencement_Date__c.addMonths(12),recservcon.EndDate);
        	}
        	
        	test.stopTest();

	}
	
     static testMethod void testActivateServiceContractswithNoTerm()
     {
     	    system.debug('running test testActivateServiceContractswithNoTerm');
			Account acc = DataGenerator.createAccounts(1,true)[0];
			acc.of_Rooms__c = 100;
			acc.Physical_City__c = 'Sioux Falls';
			acc.Physical_State__c = 'SD';
			acc.Name = 'TestAccount';
			update acc;
			
			List<User> userlist = new List<User>();
			User newuser;
			userlist = DataGenerator.CreateUsers('System Administrator',1,true);
			for(User recuser : userlist)
			{  newuser = recuser;   }
			
			Product2 parentproduct = new Product2(Name='Test Product Parent', ProductCode='CC-testpp');
			Product2 pkgproduct = new Product2(Name='TestPackage', ProductCode='CC-pkg');
			Product2 childproduct = new Product2(Name='TestChild', ProductCode='CC-child');
			Product2 warrantyproduct = new Product2(Name='Warranty Test', ProductCode='CC-tstWarr', Family='Warranty');
			insert new List<Product2>{parentproduct,pkgproduct,childproduct,warrantyproduct};
			
			//shawks 201810: CPQ - Replace Contract__c object references with Contract object
			//-> Replace: Account_Name__c -> AccountId; Status__c -> Contract_Status__c
			//Contract__c con = new Contract__c(Account_Name__c=acc.id,Status__c='Order Approved');
			Contract con = new Contract(AccountId=acc.id,Contract_Status__c='Draft');
			insert con;

			//shawks 201810: CPQ - Replace contract_line_item___c object references with SBQQ__Subscription__c object
			//-> Replace: Name -> Name__c; Legal_Contract__c -> SBQQ__Contract__c; product__c -> SBQQ__Product__c; Quantiy__c -> SBQQ__Quantity__c
			//Contract_Line_Item__c lcli1 = new Contract_Line_Item__c(Name='Test Product Parent', Legal_Contract__c=con.id, Project_Type__c='Interactive New Rooms',Status__c='Pending Installation Activate', Product__c=parentproduct.id,
			//                                equipment_ownership__c = 'CUST', quantity__c = 100);
			SBQQ__Subscription__c lcli1 = new SBQQ__Subscription__c(Name__c='Test Product Parent', SBQQ__Contract__c=con.id, Project_Type__c='Interactive New Rooms',Status__c='Pending Installation Activate', SBQQ__Product__c=parentproduct.id,
			                                equipment_ownership__c = 'CUST', SBQQ__Quantity__c = 100);
			insert lcli1;
			
			//Contract_Line_Item__c lcli2 = new Contract_Line_Item__c(Name='TestPackage', Legal_Contract__c=con.id, Parent__c=lcli1.Id, Product__c=pkgproduct.id,Status__c='Pending Installation Activate', quantity__c = 100);
			SBQQ__Subscription__c lcli2 = new SBQQ__Subscription__c(Name__c='TestPackage', SBQQ__Contract__c=con.id, Parent__c=lcli1.Id, SBQQ__Product__c=pkgproduct.id,Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);
			insert lcli2;
			
			//Contract_Line_Item__c lcli3 = new Contract_Line_Item__c(Name='TestChild', Legal_Contract__c=con.id, Parent__c=lcli2.id,Product__c=childproduct.id, Status__c='Pending Installation Activate', quantity__c = 100);
			SBQQ__Subscription__c lcli3 = new SBQQ__Subscription__c(Name__c='TestChild', SBQQ__Contract__c=con.id, Parent__c=lcli2.id,SBQQ__Product__c=childproduct.id, Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);
			insert lcli3;
			
			//Contract_Line_Item__c lcli4 = new Contract_Line_Item__c(Name='Warranty Test', Legal_Contract__c=con.id, Parent__c=lcli1.Id, Product__c=warrantyproduct.id,Status__c='Pending Installation Activate', quantity__c = 100);
			SBQQ__Subscription__c lcli4 = new SBQQ__Subscription__c(Name__c='Warranty Test', SBQQ__Contract__c=con.id, Parent__c=lcli1.Id, SBQQ__Product__c=warrantyproduct.id,Status__c='Pending Installation Activate', SBQQ__Quantity__c = 100);
			insert lcli4;

			//shawks 201810: CPQ - Replace: legal_contract_line_item__c -> Subscription__c
			//ServiceContract servicecon = new ServiceContract(Name='Warranty Test',Legal_Contract_Line_Item__c=lcli4.Id, AccountId=acc.Id, NotificationNeeded__c = false);
			ServiceContract servicecon = new ServiceContract(Name='Warranty Test',Subscription__c=lcli4.Id, AccountId=acc.Id, NotificationNeeded__c = false);
			insert servicecon;

			Order__c neworder = new Order__c(Name='TestOrder',Status__c='Order Approved', Site__c=acc.id);
			insert neworder;

        	//shawks 201810: CPQ - Replace: Legal_Contract_Line_Item__c -> Subscription__c
        	Order_Item__c oi1 = new Order_Item__c(Name='Test Product Parent',Product__c=parentproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.Today(),
        	                                      //Order__c = neworder.id, Legal_Contract_Line_Item__c=lcli1.id, Status__c='Billing') ;
        	                                      Order__c = neworder.id, Subscription__c=lcli1.id, Status__c='Billing') ;
         	insert oi1;
       	
        	Order_Item__c oi2 = new Order_Item__c(Name = 'TestPackage', Product__c=pkgproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.today(),
        	                                      //Order__c=neworder.id,Parent__c=oi1.id,Legal_Contract_Line_Item__c=lcli2.id,Status__c='Billing');
        	                                      Order__c=neworder.id,Parent__c=oi1.id,Subscription__c=lcli2.id,Status__c='Billing');
        	insert oi2;
        	
        	Order_Item__c oi3 = new Order_Item__c(Name = 'TestChild', Product__c=childproduct.id,Account__c=acc.id,Billing_Commencement_Date__c=system.today(),
        	                                      //Order__c=neworder.id,Parent__c=oi2.id,Legal_Contract_Line_Item__c=lcli3.id,Status__c='Billing');
        	                                      Order__c=neworder.id,Parent__c=oi2.id,Subscription__c=lcli3.id,Status__c='Billing');
        	insert oi3;
        	
        	Order_Item__c oi4 = new Order_Item__c(Name = 'Test Warranty', Product__c=warrantyproduct.Id, Account__c=acc.Id,Billing_Commencement_Date__c=system.today(),
        	                                       //Order__c=neworder.Id,Parent__c=oi1.Id,Legal_Contract_Line_Item__c=lcli4.Id,Status__c='Billing');
        	                                       Order__c=neworder.Id,Parent__c=oi1.Id,Subscription__c=lcli4.Id,Status__c='Billing');
            insert oi4;
                    	
   			test.startTest();
			        	
        	Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
            Work_Order__c wo = new Work_Order__c(RecordTypeId=workOrderRecordType,Status__c='In Progress',Site__c=acc.id,Install_Manager__c=newuser.id,
                               Project_Coordinator__c=newuser.id,Approver__c=newuser.id, Division__c='Domestic',Region__c='Midwest',
                               Approval_Status__c = 'Pending Billing Approval');
            insert wo;
       
          	//for this test, set Added_to_TurnonNotice to false so we don't generate a turn-on notice
        	
        	Date bcd = system.today();
        	
        	Associated_Item__c ai1 = new Associated_Item__c(Name='Test Product Parent', Status__c='Billing', Billing_Commencement_Date__c=bcd,
        	                                                Order_Item__c=oi1.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=false,
        	                                                Submitted_for_Billing__c=true,Flagged_for_Billing__c=true,Quantity__c=100);
        	Associated_Item__c ai2 = new Associated_Item__c(Name='TestPackage', Status__c='Billing', Billing_Commencement_Date__c=bcd,
        	                                                Order_Item__c=oi2.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=false,
        	                                                Submitted_for_Billing__c=true,Flagged_for_Billing__c=true,Quantity__c=100);
  
         	Associated_Item__c ai3 = new Associated_Item__c(Name='TestChild', Status__c='Billing', Billing_Commencement_Date__c=bcd,
        	                                                Order_Item__c=oi3.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=false,
        	                                                Submitted_for_Billing__c=true,Flagged_for_Billing__c=true,Quantity__c=100);
        	
        	Associated_Item__c ai4 = new Associated_Item__c(Name='Test Warranty', Status__c='Billing', Billing_Commencement_Date__c=bcd,
        	                                                Order_Item__c=oi4.id,Work_Order__c=wo.id,Added_to_TurnonNotice__c=false,
        	                                                Submitted_for_Billing__c=true,Flagged_for_Billing__c=true,Quantity__c=100);
        	                                                
        	List<Associated_Item__c> lstaitems = new list<Associated_Item__c>();
        	lstaitems.add(ai1);
        	lstaitems.add(ai2);
        	lstaitems.add(ai3);
        	lstaitems.add(ai4);
        	insert lstaitems;
        	
        	wo.Approval_Status__c = 'Billing Approved';
        	wo.Status__c = 'Billing/Go Live';  //this tests ActivateServiceContracts for service contract that has a term value
  
        	update wo;
        	//WorkOrderTriggerLogic.CreateTurnOnNotice(lstaitems);
 
        	//Work_Order__c updworkorder = [ Select Id, Name, Approval_Status__c from Work_Order__c where Id = :wkorder.Id LIMIT 1 ];
        	List<ServiceContract> servcon = [Select Id, Term, Name, StartDate, EndDate, NotificationNeeded__c from ServiceContract ];
        	system.debug('servcon size is ' +servcon.size());
        	for(ServiceContract recservcon :servcon)
        	{	system.assertEquals(ai4.Billing_Commencement_Date__c,recservcon.StartDate);
        		system.assertEquals(recservcon.NotificationNeeded__c, true);
        	}
        	
        	    	
	}

    //shawks:BUG-00717 - Test for Healthcare Notifications
    static testMethod void testCreateHCNotification()
    {
        Id crewRecordType = Utilities.RecordTypeNameToId('Account', 'Partner/Contractor');
        Account acc_crew01 = DataGenerator.createAccounts(1,true)[0];
        acc_crew01.Physical_City__c = 'Sioux Falls';
        acc_crew01.Physical_State__c = 'SD';
        acc_crew01.RecordTypeId = crewRecordType;
        acc_crew01.Name = 'TestCrew01';

        Account acc_crew02 = DataGenerator.createAccounts(1,true)[0];
        acc_crew02.Physical_City__c = 'Sioux Falls';
        acc_crew02.Physical_State__c = 'SD';
        acc_crew02.RecordTypeId = crewRecordType;
        acc_crew02.Name = 'TestCrew02';

        Account acc_site01 = DataGenerator.createAccounts(1,true)[0];
        acc_site01.of_Rooms__c = 100;
        acc_site01.Physical_City__c = 'Sioux Falls';
        acc_site01.Physical_State__c = 'SD';
        acc_site01.Name = 'TestAccount01';
        acc_site01.Type = 'Healthcare Site';

        Account acc_site02 = DataGenerator.createAccounts(1,true)[0];
        acc_site02.of_Rooms__c = 100;
        acc_site02.Physical_City__c = 'Sioux Falls';
        acc_site02.Physical_State__c = 'SD';
        acc_site02.Name = 'TestAccount02';
        acc_site02.Type = 'Healthcare Site';

        List<Account> acc = New List<Account>();
        acc.add(acc_crew01);
        acc.add(acc_crew02);
        acc.add(acc_site01);
        acc.add(acc_site02);
        update acc;

        List<User> userlist = new List<User>();
        User newuser;
        userlist = DataGenerator.CreateUsers('System Administrator',1,true);
        for(User recuser : userlist)
        {  newuser = recuser;   }
			
        Product2 parentproduct01 = new Product2(Name='Test Product Parent01', ProductCode='CC-testpp01');
        insert parentproduct01;
        Product2 parentproduct02 = new Product2(Name='Test Product Parent02', ProductCode='CC-testpp02');
        insert parentproduct02;
        Product2 childproduct = new Product2(Name='TestChild', ProductCode='CC-child');
        insert childproduct;

        //shawks 201810: CPQ - Replace Contract__c object references with Contract object
		//-> Replace: Account_Name__c -> AccountId; Status__c -> Contract_Status__c; Removed lifetime_value_of_deal__c since not included on object or needed for test
        //Contract__c lc = new Contract__c(Account_Name__c=acc_site01.id,Status__c='Order Approved',lifetime_value_of_deal__c=1000,upfront_subsidy__c = 100  );
        Contract lc = new Contract(AccountId=acc_site01.id, Contract_Status__c='Order Approved', upfront_subsidy__c = 100);
        insert lc;

        //shawks 201810: CPQ - Replace contract_line_item___c object references with SBQQ__Subscription__c object
	    //-> Replace: Name -> Name__c; Legal_Contract__c -> SBQQ__Contract__c; product__c -> SBQQ__Product__c; Quantiy__c -> SBQQ__Quantity__c
        /*Contract_Line_Item__c lcli1 = new Contract_Line_Item__c(Name='Test Product Parent01', Legal_Contract__c=lc.id, Project_Type__c='Interactive New Rooms',
                                                                Status__c='Pending Installation Activate', Product__c=parentproduct01.id,
                                                                quantity__c = 100, equipment_ownership__c = 'CUST');
        Contract_Line_Item__c lcli2 = new Contract_Line_Item__c(Name='Test Product Parent02', Legal_Contract__c=lc.id, Project_Type__c='Interactive New Rooms',
                                                                Status__c='Pending Installation Activate', Product__c=parentproduct02.id,
                                                                quantity__c = 100, equipment_ownership__c = 'CUST');
        List<Contract_Line_Item__c> lclilist = new list<Contract_Line_Item__c>();
        */
        SBQQ__Subscription__c lcli1 = new SBQQ__Subscription__c(Name__c='Test Product Parent01', SBQQ__Contract__c=lc.id, Project_Type__c='Interactive New Rooms',
                                                                Status__c='Pending Installation Activate', SBQQ__Product__c=parentproduct01.id,
                                                                SBQQ__Quantity__c = 100, equipment_ownership__c = 'CUST');
        SBQQ__Subscription__c lcli2 = new SBQQ__Subscription__c(Name__c='Test Product Parent02', SBQQ__Contract__c=lc.id, Project_Type__c='Interactive New Rooms',
                                                                Status__c='Pending Installation Activate', SBQQ__Product__c=parentproduct02.id,
                                                                SBQQ__Quantity__c = 100, equipment_ownership__c = 'CUST'); 
        List<SBQQ__Subscription__c> lclilist = new list<SBQQ__Subscription__c>();
        lclilist.add(lcli1);
        lclilist.add(lcli2);
        insert lclilist;

        //shawks 201810: CPQ - Replace: legal_contract_line_item__c -> Subscription__c
        //Asset parentasset01 = New Asset(Name = 'Test Product Parent01', legal_contract_line_item__c = lcli1.Id, status = 'Pending Installation Activate', accountid = acc_site01.id);
        //Asset parentasset02 = New Asset(Name = 'Test Product Parent02', legal_contract_line_item__c = lcli2.Id, status = 'Pending Installation Activate', accountid = acc_site01.id);
        Asset parentasset01 = New Asset(Name = 'Test Product Parent01', Subscription_item__c = lcli1.Id, status = 'Pending Installation Activate', accountid = acc_site01.id);
        Asset parentasset02 = New Asset(Name = 'Test Product Parent02', Subscription_item__c = lcli2.Id, status = 'Pending Installation Activate', accountid = acc_site01.id);

        List<Asset> addasset = New List<Asset>();
        addasset.add(parentasset01);
        addasset.add(parentasset02);
        insert addasset;

        Order__c neworder = new Order__c(Name='TestOrder',Status__c='Order Approved', Site__c=acc_site01.id);
        insert neworder;

        //shawks 201810: CPQ - Replace: Legal_Contract_Line_Item__c -> Subscription__c
        Order_Item__c oi1 = new Order_Item__c(Name='Test Product Parent01',Product__c=parentproduct01.id,Account__c=acc_site01.id,
                                              //Billing_Commencement_Date__c=system.Today(),Order__c=neworder.id,Legal_Contract_Line_Item__c=lcli1.id,
                                              Billing_Commencement_Date__c=system.Today(),Order__c=neworder.id,Subscription__c=lcli1.id,
                                              Status__c='Billing', asset__c = parentasset01.id,total_remaining_rooms__c = 100) ;

        Order_Item__c oi2 = new Order_Item__c(Name='Test Product Parent02',Product__c=parentproduct02.id,Account__c=acc_site01.id,
                                              //Billing_Commencement_Date__c=system.today(),Order__c=neworder.id,Legal_Contract_Line_Item__c=lcli2.id,
                                              Billing_Commencement_Date__c=system.today(),Order__c=neworder.id,Subscription__c=lcli2.id,
                                              Status__c='Billing', asset__c = parentasset02.id,total_remaining_rooms__c = 100, Project_Type__c = 'Healthcare');

        List<Order_Item__c> addoi = New List<Order_Item__c>();
        addoi.add(oi1);
        addoi.add(oi2);
        insert addoi;

        Id workOrderRecordType_Install = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
        Id workOrderRecordType_Sched = Utilities.RecordTypeNameToId('Work_Order__c', 'Schedules');
        Work_Order__c wo_01 = new Work_Order__c(RecordTypeId=workOrderRecordType_Install,Status__c='Billing/Go Live',Site__c=acc_site01.id,
                                                Install_Manager__c=newuser.id,Project_Coordinator__c=newuser.id,Approver__c=newuser.id, Division__c='Domestic',
                                                Region__c='Midwest',Approval_Status__c = 'Pending Billing Approval',
                                                PO__c = 'PO-12345',Crew__c=acc_crew01.id,CreatedByID=newuser.id);

        Work_Order__c wo_02 = new Work_Order__c(RecordTypeId=workOrderRecordType_Install,Status__c='Billing/Go Live',Site__c=acc_site01.id,
                                                Install_Manager__c=newuser.id,Project_Coordinator__c=newuser.id,Approver__c=newuser.id, Division__c='Domestic',
                                                Region__c='Midwest',Approval_Status__c = 'Pending Billing Approval',Crew__c=acc_crew01.id,CreatedByID=newuser.id);

        Work_Order__c wo_03 = new Work_Order__c(RecordTypeId=workOrderRecordType_Sched,Status__c='Billing/Go Live',Site__c=acc_site01.id,
                                                Install_Manager__c=newuser.id,Project_Coordinator__c=newuser.id,Approver__c=newuser.id, Division__c='Domestic',
                                                Region__c='Midwest',Approval_Status__c = 'Pending Billing Approval',
                                                PO__c = 'PO-54321');

        Work_Order__c wo_04 = new Work_Order__c(RecordTypeId=workOrderRecordType_Sched,Status__c='Billing/Go Live',Site__c=acc_site01.id,
                                                Install_Manager__c=newuser.id,Project_Coordinator__c=newuser.id,Approver__c=newuser.id, Division__c='Domestic',
                                                Region__c='Midwest',Approval_Status__c = 'Pending Billing Approval');


        List<Work_Order__c> lstworkOrder = New List<Work_Order__c>();
        lstworkOrder.add(wo_01);
        lstworkOrder.add(wo_02);
        lstworkOrder.add(wo_03);
        lstworkOrder.add(wo_04);
        insert lstworkOrder;

        Associated_Item__c ai1 = new Associated_Item__c(Name='Test Product Parent01', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
	                                                    Order_Item__c=oi1.id,Work_Order__c=wo_03.id,Added_to_TurnonNotice__c=true,
                                                        Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=75,project_number__c ='Test123');

        Associated_Item__c ai2 = new Associated_Item__c(Name='Test Product Parent02', Status__c='Billing', Billing_Commencement_Date__c=system.today(),
	                                                    Order_Item__c=oi2.id,Work_Order__c=wo_03.id,Added_to_TurnonNotice__c=true,
                                                        Submitted_for_Billing__c=false,Flagged_for_Billing__c=true,Quantity__c=75,project_number__c ='Test321');

        List<Associated_Item__c> lstaitems = new list<Associated_Item__c>();
        lstaitems.add(ai1);
        lstaitems.add(ai2);
        insert lstaitems;

        wo_01.Equipment_Delivery_Date__c = System.today();

        wo_02.Equipment_Delivery_Date__c = System.today();
        wo_02.Install_Complete_Date__c  = System.today();
        wo_02.Site__c = acc_site02.id;
        wo_02.Crew__c = acc_crew02.id;

        wo_03.Billing_Date__c = System.today();

        wo_04.Billing_Date__c = System.today();
        wo_04.Site__c = acc_site02.id;

        List<Work_Order__c> lstworkOrder_Update01 = New List<Work_Order__c>();
        lstworkOrder_Update01.add(wo_01);
        lstworkOrder_Update01.add(wo_02);
        lstworkOrder_Update01.add(wo_03);
        lstworkOrder_Update01.add(wo_04);

        Test.startTest();
        update lstworkOrder_Update01;

        wo_01.Install_Complete_Date__c = System.today();
        wo_01.Site__c = acc_site02.id;
        wo_01.Crew__c = acc_crew02.id;

        List<Work_Order__c> lstworkOrder_Update02 = New List<Work_Order__c>();
        lstworkOrder_Update02.add(wo_01);
        lstworkOrder_Update02.add(wo_02);
        update lstworkOrder_Update02;

        test.stopTest();
	}  
}