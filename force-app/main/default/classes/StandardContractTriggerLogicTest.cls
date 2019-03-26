@isTest
private class StandardContractTriggerLogicTest {
   static testmethod void testUpdateLineItems()
	{
		//jjackson 5/2017 This test verifies that when a contract gets start dates for the first time,
		//those dates populate down to the legal contract line item and the entitlement/service contract that
		//are related to the contract line item.
		Account acc = new Account(Name = 'Test acc');
		insert acc;

		Product2 parentprod = New Product2(Name = 'Testing Product Parent', ProductCode = 'CC-parent');
    	insert New List<Product2>{parentprod};

        Contract Contract1 = new Contract(CustomerSignedDate = null, AccountId = acc.id, Contract_Status__c = 'Activated', ContractTerm = 24);
	    insert Contract1;

		SBQQ__Subscription__c subparent = new SBQQ__Subscription__c(SBQQ__Contract__c = Contract1.id, Conversion_Date__c = null, Name__c = 'Testing Product Parent', 
		                                     Project_Type__c = 'FTG New Rooms', Equipment_Ownership__c = 'CUST', SBQQ__Quantity__c = 50, Status__c = 'Installed Activated',
		                                     SBQQ__Product__c = parentprod.id);
        insert subparent;

		Asset asset1 = new Asset(Name = 'Testing Product Parent', AccountId = acc.Id, Contract__c = Contract1.Id, Subscription_item__c = subparent.id,
		                         status = 'Installed Activated', product2id = parentprod.id);
		insert asset1;

		ServiceContract servcon1 = new ServiceContract(Name = 'Legacy', Product_Inventory__c = asset1.Id, Subscription__c = subparent.Id, accountid = acc.id, term=24);
        insert servcon1;

		Entitlement ent1 = new Entitlement(Subscription__c=subparent.id, Assetid = asset1.Id, Name='Test 1 Entitlement', AccountId=acc.id, ServiceContractId = servcon1.Id);
		insert ent1;

		List<Contract> updatecontracts = New List<Contract>();
		Contract1.StartDate = Date.Today();
		updatecontracts.add(Contract1);
		update updatecontracts;

		test.StartTest();
			Contract ContractRecord = [ SELECT Id, StartDate, EndDate FROM Contract LIMIT 1 ];
			
			List<SBQQ__Subscription__c> parentsub = [Select Name__c, Id, SBQQ__SubscriptionStartDate__c, SBQQ__SubscriptionEndDate__c
			                                         From SBQQ__Subscription__c Where Name__c = 'Testing Product Parent'];

			system.debug('Test 1 contractrec start/end dates are ' +ContractRecord.StartDate +', ' +ContractRecord.EndDate);

			for(SBQQ__Subscription__c subrecord : parentsub)
			{
				system.debug('Test 1 subscription start/end dates are ' +subrecord.SBQQ__SubscriptionStartDate__c +', ' +subrecord.SBQQ__SubscriptionEndDate__c);
				system.assert(subrecord.SBQQ__SubscriptionStartDate__c == ContractRecord.StartDate); //date.today());
				system.assert(subrecord.SBQQ__SubscriptionEndDate__c == ContractRecord.EndDate); //date.today().addMonths(24));
			}

			List<Entitlement> entlist = New List<Entitlement>();
			//entlist = [ Select Name, startdate, enddate, Subscription__c, ServiceContract.enddate from Entitlement ];
			entlist = [ Select Name, startdate, enddate, Subscription__c, ServiceContract.startdate, ServiceContract.enddate from Entitlement ];
			
			for(Entitlement updent : entlist)
			{ system.debug('Test 1 entitlement start/end dates are ' +updent.startdate +', ' +updent.enddate); 
			  //system.debug('Test 1 service contract end date is ' +updent.ServiceContract.enddate);
			  system.debug('Test 1 service contract start/end dates are ' +updent.ServiceContract.startdate +', ' +updent.ServiceContract.enddate);
			  //Verify dates were updated
			  system.assert(updent.startdate == ContractRecord.StartDate);
			  system.assert(updent.enddate == ContractRecord.EndDate);
			  system.assert(updent.ServiceContract.enddate == ContractRecord.EndDate);
			}
	    test.StopTest();
	}
	
	static testmethod void UpdateContractLineItemsNoLegacy()
	{
		//this verifies that if the contract end date changes beyond the end date of a non-legacy service contract,
		//the entitlement end date gets updated but the service contract end date does not get updated
		Account acc = new Account(Name = 'Test acc');
		insert acc;

 		Product2 warrprod = new Product2(Name = 'Test Warranty', ProductCode = 'CC-warpart', Family = 'Warranty');
 		Product2 entlprod = new Product2(Name = 'Test Entitlement', ProductCode = 'CC-entl', Family = 'Entitlement');
		Product2 parentprod = New Product2(Name = 'Testing Product Parent', ProductCode = 'CC-parent');
    	insert New List<Product2>{warrprod, entlprod, parentprod};

    	Date start = system.today();
    	Date ending = system.today().addMonths(24).addDays(-1);
    	Date newEnding = system.today().addMonths(36).addDays(-1);

        //Contract must be inserted with a "Draft" status and then updated to "Activated"
        Contract Contract1 = new Contract(CustomerSignedDate = null, AccountId = acc.id, Contract_Status__c = 'Activated', 
                                          ContractTerm = 24, StartDate = start, EndDate = ending);
	    insert Contract1;

		SBQQ__Subscription__c sub1parent = new SBQQ__Subscription__c(SBQQ__Contract__c = Contract1.id, Conversion_Date__c = null, Name__c = 'Testing Product Parent',
		                                                             Project_Type__c = 'FTG New Rooms', Equipment_Ownership__c = 'CUST', SBQQ__Quantity__c = 50,
		                                                             Status__c = 'Installed Activated', SBQQ__Product__c = parentprod.id, SBQQ__SubscriptionStartDate__c = start,
		                                                             SBQQ__SubscriptionEndDate__c = ending);
		insert sub1parent;

		SBQQ__Subscription__c subwarranty = New SBQQ__Subscription__c(SBQQ__Contract__c = Contract1.id, Name__c = 'Test Warranty', SBQQ__Product__c = warrprod.id,
		                                                              parent__c = sub1parent.id, SBQQ__Quantity__c = 1);
		SBQQ__Subscription__c subentl = New SBQQ__Subscription__c(SBQQ__Contract__c = Contract1.id, Name__c = 'Test Entitlement', SBQQ__Product__c = entlprod.id,
		                                                              parent__c = sub1parent.id, SBQQ__Quantity__c = 1);
		insert New List<SBQQ__Subscription__c>{subwarranty, subentl};                                                                                                                      

		Asset asset1 = new Asset(Name = 'Testing Product Parent', AccountId = acc.Id, Contract__c = Contract1.Id, Subscription_item__c = sub1parent.id, status = 'Installed Activated',
		                         product2id = parentprod.id);
		insert asset1;

		ServiceContract servcon1 = new ServiceContract(Name = 'Test Warranty', Product_Inventory__c = asset1.Id, Subscription__c = subwarranty.Id, accountid = acc.id, term=24,
		                                               startdate = start, enddate = ending);
        insert servcon1;

		Entitlement ent1 = new Entitlement(Subscription__c=sub1parent.id, Assetid = asset1.Id, Name='Test Entitlement', AccountId=acc.id, ServiceContractId = servcon1.Id,
		                                   startdate = start, enddate = ending);
		insert ent1;

		List<Contract> updatecontracts = New List<Contract>();
		Contract1.StartDate = Date.Today();
		Contract1.ContractTerm = 36;
		Contract1.endDate = newEnding;
		Contract1.auto_renew__c = true;     //shawks BUG00574
		updatecontracts.add(Contract1);
		update updatecontracts;

        //Find contract values for asserts
        Contract ContractRecord = [ SELECT Id, StartDate, EndDate FROM Contract LIMIT 1 ];

		test.StartTest();

		List<Entitlement> entlist = New List<Entitlement>();
		entlist = [ Select Name, startdate, enddate, Subscription__c, ServiceContract.enddate from Entitlement ];

		for(Entitlement updent : entlist){
             system.debug('Test NoLegacy Contract start/end dates are ' +ContractRecord.startdate +', ' +ContractRecord.enddate);
             system.debug('Test NoLegacy entitlement start/end dates are ' +updent.startdate +', ' +updent.enddate); 
			 system.debug('Test NoLegacy service contract end date is ' +updent.ServiceContract.enddate);
			 //Verify Entitlement dates updated and the Service Contract end date did not update
			 system.assert(updent.startdate == ContractRecord.StartDate);
			 system.assert(updent.enddate == ContractRecord.EndDate);
			 system.assert(updent.ServiceContract.enddate != ContractRecord.EndDate);
		}
	    test.StopTest();
	}
	
	static testmethod void DeactivateContract()
	{
		//jjackson verify that when a contract is made inactive, the entitlement and servicecontract related to the
		//product parent gets their enddates updated and their status changes to Expired.
		Account acc = new Account(Name = 'Test acc');
		insert acc;

 		Product2 warrprod = new Product2(Name = 'Test Warranty', ProductCode = 'CC-warpart', Family = 'Warranty');
 		Product2 entlprod = new Product2(Name = 'Test Entitlement', ProductCode = 'CC-entl', Family = 'Entitlement');
		Product2 parentprod = New Product2(Name = 'Testing Product Parent', ProductCode = 'CC-parent');
    	insert New List<Product2>{warrprod, entlprod, parentprod};

        Contract Contract1 = new Contract(CustomerSignedDate = null, AccountId = acc.id, Contract_Status__c = 'Activated', 
                                          ContractTerm = 24, StartDate = date.today().addMonths(-3));
	    insert Contract1;

		SBQQ__Subscription__c sub1parent = new SBQQ__Subscription__c(SBQQ__Contract__c = Contract1.id, Conversion_Date__c = null, Name__c = 'Testing Product Parent',
		                                                             Project_Type__c = 'FTG New Rooms', Equipment_Ownership__c = 'CUST',
		                                                             SBQQ__Quantity__c = 50, Status__c = 'Installed Activated', SBQQ__Product__c = parentprod.id,
		                                                             SBQQ__SubscriptionStartDate__c = date.today().addMonths(-3),
		                                                             SBQQ__SubscriptionEndDate__c = date.today().addMonths(36));
        insert sub1parent;
		
		Asset asset1 = new Asset(Name = 'Testing Product Parent', AccountId = acc.Id, Contract__c = Contract1.Id, Subscription_item__c = sub1parent.id,
		                         status = 'Installed Activated', product2id = parentprod.id);
		insert asset1;
		
		ServiceContract servcon1 = new ServiceContract(Name = 'Legacy', Product_Inventory__c = asset1.Id, Subscription__c = sub1parent.Id, accountid = acc.id, term=24,
		                                               startdate = date.today().addMonths(-3), enddate = date.today().addMonths(36));
        insert servcon1;
		
		Entitlement ent1 = new Entitlement(Subscription__c=sub1parent.id, Assetid = asset1.Id, Name='Test 1 Entitlement', AccountId=acc.id, ServiceContractId = servcon1.Id,
		                                   startdate = date.today().addMonths(-3), enddate = date.today().addmonths(36));
		insert ent1;

		Entitlement activeentl = [ Select status, ServiceContract.status from Entitlement where name = 'Test 1 Entitlement'];
		system.assert(activeentl.status == 'Active');
		system.assert(activeentl.ServiceContract.status == 'Active');

		test.startTest();
			Contract1.Contract_Status__c = 'Inactive';
			update Contract1;
			
			Entitlement inactiveentl = [ Select status, ServiceContract.status from Entitlement where name = 'Test 1 Entitlement'];
			system.assert(inactiveentl.status == 'Expired');
			system.assert(inactiveentl.ServiceContract.status == 'Expired');
		test.StopTest();
	}//end DeactivateContract

   //jjackson 7/1/2014 test GetClockStartDates to verify code runs all the way through to populating the work order dates
   static testMethod void updateContractInstallStartDates() {
    	//create test data
    	Account acc = new Account(Name = 'Test acc');
    	try{
    	insert acc; }
    	catch(Exception e){
    		system.debug('Error inserting account in updateContractInstall ' + e.getmessage());
    	}

    	Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'CC-TEST', Description = 'Test Part Number');
    	try{
    		insert prod;
    	}
    	catch(Exception a){
    		system.debug('Error inserting product in exception a: ' + a.getmessage());
    	}

        Contract Contract1 = new Contract(CustomerSignedDate = Date.Today().addDays(-30), AccountId = acc.id,
                                  ContractTerm = 3, startDate = Date.Today().addDays(-30), Contract_Status__c = 'Activated');
        try{insert Contract1; }
        catch(Exception b){
        	system.debug('Error inserting contract in exception b: ' + b.getmessage());
        }

        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(SBQQ__Contract__c = Contract1.id, Name__c = prod.Name, Conversion_Date__c = null, SBQQ__Product__c = prod.Id,
                                             SBQQ__Quantity__c = 1);
        try{insert sub1;}
        catch(Exception c){
        	system.debug('Error inserting line item in exception c:' + c.getmessage());
        }

        Order__c order1 = new Order__c(Site__c = acc.id);
        try{insert order1; }
        catch(Exception d){
        	system.debug('Error inserting order in exception d: '+d.getmessage());
        }
        
        Order_Item__c oi1 = new Order_Item__c(Name = prod.Name, Subscription__c  = sub1.Id, Order__c = order1.Id, Product__c = prod.Id, Account__c = acc.Id);
        try{insert oi1; }
        catch(Exception f){
        	system.debug('Error inserting order item in exception f: ' + f.getmessage());
        }
        
        Work_Order__c wo = new Work_Order__c(Name = 'New Work Order', Project_Type__c = 'New Installation', Site__c = acc.Id );
        try{insert wo; }
        catch(Exception g){
        	system.debug('Error inserting work order in exception g: ' + g.getmessage());
        }
        
        Associated_Item__c ai1 = new Associated_Item__c(Name = prod.Name, Order_Item__c = oi1.Id, Work_Order__c = wo.Id  );
        try{insert ai1; }
        catch(Exception h){
        	system.debug('Error inserting associated item in exception h: ' + h.getmessage());
        }

        Test.startTest();
        //Following clock start fields are currently needed for Hilton contract obligations
           Contract1.Installation_Clock_Started__c = True;
           Contract1.FTG_Clock_Start_Date__c = Date.Today();
           Contract1.Interactive_Clock_Start_Date__c = Date.Today();
           try { update Contract1; }
           catch(Exception i){
        	   system.debug('Error updating contract1 in exception i: ' +i.getmessage());
           }
        Test.stopTest();
        
        //query the work order data now that contract has been updated
        Work_Order__c worecord = [Select id, FTG_Contracted_Completion_Date__c, GP_Contracted_Completion_Date__c from Work_Order__c where ID = :wo.id LIMIT 1 ];
        system.debug('Test ContractedCompletion WO FTG/GP completion dates are ' +worecord.FTG_Contracted_Completion_Date__c +', ' +worecord.GP_Contracted_Completion_Date__c);

        //Test assertions
        System.assertEquals(Date.Today().addDays(60), worecord.FTG_Contracted_Completion_Date__c);
        System.assertEquals(Date.Today().addDays(90), worecord.GP_Contracted_Completion_Date__c);
   }

   //jjackson 9/2016  added this to cover the code that sends out an email when there is a group services line item
   //there is no way to verify that an email gets sent in a test, but the code will be covered
   static testmethod void TestGroupServicesNotification()
   {
   		Account acc = new Account(Name = 'Test account');
   		insert acc;

   		Product2 gsprod = New Product2(Name = 'Group Services', productcode = 'CC-330040', family = 'Interactive', isactive = true);
   		insert gsprod;

        Contract con = New Contract(AccountId = acc.Id, Contract_Status__c = 'Ready for Approval');
   		insert con;

   		SBQQ__Subscription__c subscription = New SBQQ__Subscription__c(Name__c = 'Group Services', SBQQ__Product__c = gsprod.id, SBQQ__Contract__c = con.id,
   		                                                       status__c = 'Pending Installation Activate', SBQQ__Quantity__c = 100);
   		insert subscription;

   		test.startTest();
   		con.Contract_Status__c = 'Order Approved';
   		update con;
   		test.stopTest();
   }   //end testgroupservicesnotification
}