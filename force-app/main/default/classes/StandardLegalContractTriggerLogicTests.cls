@isTest
private class StandardLegalContractTriggerLogicTests {
   /* shawks 01/2019: CPQ - Comment out methods since email method was updated for out-of-box contract object
    static testmethod void testUpdateLineItems()
	{
		//jjackson 5/2017 This test verifies that when a contract gets start/end dates for the first time,
		//those dates populate down to the legal contract line item and the entitlement/service contract that
		//are related to the contract line item.
		
		Account acc = new Account(Name = 'Test acc');
		insert acc;
		
 		Product2 warrprod = new Product2(Name = 'Test Warranty', ProductCode = 'CC-warpart', Family = 'Warranty');
 		
 		
 		Date startdate = system.today().AddMonths(-2);
 		Date enddate = system.today().AddMonths(12);
 		
		List<Product2> newproducts = New List<Product2>();
 		Product2 entlprod = new Product2(Name = 'Test Entitlement', ProductCode = 'CC-entl', Family = 'Entitlement');
		Product2 parentprod = New Product2(Name = 'Testing Product Parent', ProductCode = 'CC-parent');
    	insert New List<Product2>{warrprod, entlprod, parentprod};
		
        Contract__c Contract1 = new Contract__c(Customer_Signed_Date__c = null, Account_Name__c = acc.id, Status__c = 'Activated', Contract_Term_Months__c = 24);
        
	    insert Contract1;
		
		Contract_Line_Item__c cli1parent = new Contract_Line_Item__c(Legal_Contract__c = Contract1.id, Conversion_Date__c = null, Name = 'Testing Product Parent', Project_Type__c = 'FTG New Rooms', Equipment_Ownership__c = 'CUST', Quantity__c = 50, Status__c = 'Installed Activated',
		                                                             product__c = parentprod.id);
        insert cli1parent;
		
		Asset asset1 = new Asset(Name = 'Testing Product Parent', AccountId = acc.Id, legal_contract__c = Contract1.Id, legal_contract_line_item__c = cli1parent.id, status = 'Installed Activated',
		                         product2id = parentprod.id);
		insert asset1;
		
		ServiceContract servcon1 = new ServiceContract(Name = 'Legacy', Product_Inventory__c = asset1.Id, Legal_Contract_Line_Item__c = cli1parent.Id, accountid = acc.id, term=24);
        insert servcon1;
		
		Entitlement ent1 = new Entitlement(Legal_Contract_Line_Item__c=cli1parent.id, Assetid = asset1.Id, Name='Test 1 Entitlement', AccountId=acc.id, ServiceContractId = servcon1.Id);
		insert ent1;
	
		List<Contract__c> updatecontracts = New List<Contract__c>();
		
		Contract1.contract_start_date__c = Date.Today();
		Contract1.contract_end_date__c = Date.Today().addMonths(24);
		Contract1.auto_renew__c = true;     //shawks BUG00574
		updatecontracts.add(Contract1);
		
		update updatecontracts;
		
		test.StartTest();
		
			List<Contract_Line_Item__c> updparent = [Select Name, Id, term_start_date__c, term_end_date__c, auto_renew__c from Contract_Line_Item__c where
			                                   Name = 'Testing Product Parent'];
			                                   
			for(Contract_Line_Item__c lcli : updparent)
			{
				system.assert(lcli.term_start_date__c == date.today());
				system.assert(lcli.term_end_date__c == date.today().addMonths(24));
				system.assert(lcli.auto_renew__c == true);
			}
											
			//system.debug('Testing Product Parent start/end dates are ' +updparent.term_start_date__c +', ' +updparent.term_end_date__c);

			List<Entitlement> entlist = New List<Entitlement>();
			entlist = [ Select Name, startdate, enddate, legal_contract_line_Item__c, ServiceContract.enddate from Entitlement ];
			
			for(Entitlement updent : entlist)
			{ system.debug('Test 1 entitlement start/end dates are ' +updent.startdate +', ' +updent.enddate); 
			  system.debug('Test 1 entitlement service contract enddate id ' +updent.ServiceContract.enddate);
			  system.assert(updent.startdate == Contract1.contract_start_date__c);
			  system.assert(updent.enddate == Contract1.contract_end_date__c);
			  system.assert(updent.ServiceContract.enddate == Contract1.contract_end_date__c);
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
 		
 		
 		Date startdate = system.today().AddMonths(-2);
 		Date enddate = system.today().AddMonths(12);
 		
		List<Product2> newproducts = New List<Product2>();
 		Product2 entlprod = new Product2(Name = 'Test Entitlement', ProductCode = 'CC-entl', Family = 'Entitlement');
		Product2 parentprod = New Product2(Name = 'Testing Product Parent', ProductCode = 'CC-parent');
    	insert New List<Product2>{warrprod, entlprod, parentprod};
    	
    	Date start = system.today();
    	Date ending = system.today().addMonths(24);
		
        Contract__c Contract1 = new Contract__c(Customer_Signed_Date__c = null, Account_Name__c = acc.id, Status__c = 'Activated', Contract_Term_Months__c = 24,
                                                contract_start_date__c = start, contract_end_date__c = ending);
        
	    insert Contract1;
		
		Contract_Line_Item__c cli1parent = new Contract_Line_Item__c(Legal_Contract__c = Contract1.id, Conversion_Date__c = null, Name = 'Testing Product Parent', Project_Type__c = 'FTG New Rooms', Equipment_Ownership__c = 'CUST', Quantity__c = 50, Status__c = 'Installed Activated',
		                                                             product__c = parentprod.id, term_start_date__c = start, term_end_date__c = ending, auto_renew__c = false );
		insert cli1parent;
		
		Contract_Line_Item__c cliwarranty = New Contract_Line_Item__c(Legal_Contract__c = Contract1.id, Name = 'Test Warranty', product__c = warrprod.id,
		                                                              parent__c = cli1parent.id );
		Contract_Line_Item__c clientl = New Contract_Line_Item__c(Legal_Contract__c = Contract1.id, Name = 'Test Entitlement', product__c = entlprod.id,
		                                                              parent__c = cli1parent.id );
		insert New List<Contract_Line_Item__c>{cliwarranty, clientl};                                                                                                                      
		                                                             
		
		Asset asset1 = new Asset(Name = 'Testing Product Parent', AccountId = acc.Id, legal_contract__c = Contract1.Id, legal_contract_line_item__c = cli1parent.id, status = 'Installed Activated',
		                         product2id = parentprod.id);
		insert asset1;
		
		ServiceContract servcon1 = new ServiceContract(Name = 'Test Warranty', Product_Inventory__c = asset1.Id, Legal_Contract_Line_Item__c = cliwarranty.Id, accountid = acc.id, term=24,
		                                               startdate = start, enddate = ending);
        insert servcon1;
		
		Entitlement ent1 = new Entitlement(Legal_Contract_Line_Item__c=cli1parent.id, Assetid = asset1.Id, Name='Test Entitlement', AccountId=acc.id, ServiceContractId = servcon1.Id,
		                                   startdate = start, enddate = ending);
		insert ent1;
	
		List<Contract__c> updatecontracts = New List<Contract__c>();
		
		Contract1.contract_start_date__c = Date.Today();
		Contract1.contract_end_date__c = Date.Today().addMonths(36);
		Contract1.auto_renew__c = true;     //shawks BUG00574
		updatecontracts.add(Contract1);
		
		update updatecontracts;
		
		test.StartTest();
		
			Contract_Line_Item__c updparent = [Select Name, Id, term_start_date__c, term_end_date__c, auto_renew__c  from Contract_Line_Item__c where
			                                   Name = 'Testing Product Parent' LIMIT 1 ];
											
			system.debug('Testing Product Parent start/end dates are ' +updparent.term_start_date__c +', ' +updparent.term_end_date__c +', ' +updparent.auto_renew__c);

			List<Entitlement> entlist = New List<Entitlement>();
			entlist = [ Select Name, startdate, enddate, legal_contract_line_Item__c, ServiceContract.enddate from Entitlement ];
			
			for(Entitlement updent : entlist)
			{ system.debug('Test 1 entitlement start/end dates are ' +updent.startdate +', ' +updent.enddate); 
			  system.debug('Test 1 entitlement service contract enddate id ' +updent.ServiceContract.enddate);
			  system.assert(updent.startdate == Contract1.contract_start_date__c);
			  system.assert(updent.enddate == Contract1.contract_end_date__c);
			  system.assert(updent.ServiceContract.enddate != Contract1.contract_end_date__c);
			}
			
	    test.StopTest();
		
	}
	
	static testmethod void DeactivateLegalContract()
	{
			//jjackson verify that when a contract is made inactive, the entitlement and servicecontract related to the
			//product parent gets their enddates updated and their status changes to Expired.
		
		Account acc = new Account(Name = 'Test acc');
		insert acc;
		
 		Product2 warrprod = new Product2(Name = 'Test Warranty', ProductCode = 'CC-warpart', Family = 'Warranty');
 		
 		
 		Date startdate = system.today().AddMonths(-2);
 		Date enddate = system.today().AddMonths(12);
 		
		List<Product2> newproducts = New List<Product2>();
 		Product2 entlprod = new Product2(Name = 'Test Entitlement', ProductCode = 'CC-entl', Family = 'Entitlement');
		Product2 parentprod = New Product2(Name = 'Testing Product Parent', ProductCode = 'CC-parent');
    	insert New List<Product2>{warrprod, entlprod, parentprod};
		
        Contract__c Contract1 = new Contract__c(Customer_Signed_Date__c = null, Account_Name__c = acc.id, Status__c = 'Activated', Contract_Term_Months__c = 24,
                                                contract_start_date__c = date.today().addMonths(-3), contract_end_date__c = date.today().addMonths(36));
        
	    insert Contract1;
		
		Contract_Line_Item__c cli1parent = new Contract_Line_Item__c(Legal_Contract__c = Contract1.id, Conversion_Date__c = null, Name = 'Testing Product Parent', Project_Type__c = 'FTG New Rooms', Equipment_Ownership__c = 'CUST', Quantity__c = 50, Status__c = 'Installed Activated',
		                                                             product__c = parentprod.id, term_start_date__c = date.today().addMonths(-3), term_end_date__c = date.today().addMonths(36));
        insert cli1parent;
		
		Asset asset1 = new Asset(Name = 'Testing Product Parent', AccountId = acc.Id, legal_contract__c = Contract1.Id, legal_contract_line_item__c = cli1parent.id, status = 'Installed Activated',
		                         product2id = parentprod.id);
		insert asset1;
		
		ServiceContract servcon1 = new ServiceContract(Name = 'Legacy', Product_Inventory__c = asset1.Id, Legal_Contract_Line_Item__c = cli1parent.Id, accountid = acc.id, term=24,
		                                               startdate = date.today().addMonths(-3), enddate = date.today().addMonths(36));
        insert servcon1;
		
		Entitlement ent1 = new Entitlement(Legal_Contract_Line_Item__c=cli1parent.id, Assetid = asset1.Id, Name='Test 1 Entitlement', AccountId=acc.id, ServiceContractId = servcon1.Id,
		                                   startdate = date.today().addMonths(-3), enddate = date.today().addmonths(36));
		insert ent1;

		Entitlement activeentl = [ Select status, ServiceContract.status from Entitlement where name = 'Test 1 Entitlement'];
		system.assert(activeentl.status == 'Active');
		system.assert(activeentl.ServiceContract.status == 'Active');
		
		test.startTest();
		
			Contract1.status__c = 'Inactive';
			update Contract1;
			
			Entitlement inactiveentl = [ Select status, ServiceContract.status from Entitlement where name = 'Test 1 Entitlement'];
			system.assert(inactiveentl.status == 'Expired');
			system.assert(inactiveentl.ServiceContract.status == 'Expired');
			
		test.StopTest();
		
		
	}//end deactivatelegalcontract
    
   
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
    	
        Contract__c Contract1 = new Contract__c(Customer_Signed_Date__c = Date.Today().addDays(-30), Account_Name__c = acc.id );
        try{insert Contract1; }
        catch(Exception b){
        	system.debug('Error inserting contract in exception b: ' + b.getmessage());
        }
        
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(Legal_Contract__c = Contract1.id, Conversion_Date__c = null, Product__c = prod.Id, Name = prod.Name );
        try{insert cli1;}
        catch(Exception c){
        	system.debug('Error inserting line item in exception c:' + c.getmessage());
        }
        
        Order__c order1 = new Order__c(Site__c = acc.id, Legal_Contract__c = Contract1.Id );
        try{insert order1; }
        catch(Exception d){
        	system.debug('Error inserting order in exception d: '+d.getmessage());
        }
        
        Order_Item__c oi1 = new Order_Item__c(Name = prod.Name, Legal_Contract_Line_Item__c = cli1.Id, Order__c = order1.Id, Product__c = prod.Id, Account__c = acc.Id  );
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
        //system.debug('worecord dates are ' +worecord.FTG_Contracted_Completion_Date__c +', ' +worecord.GP_Contracted_Completion_Date__c);
         //assertions
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
   		
   		Contract__c con = New Contract__c(account_name__c = acc.Id, status__c = 'Ready for Approval');
   		insert con;
   		
   		Contract_Line_Item__c lcli = New Contract_Line_Item__c(Name = 'Group Services', product__c = gsprod.id, legal_contract__c = con.id,
   		                                                       status__c = 'Pending Installation Activate', quantity__c = 100);
   		insert lcli;
   		
   		test.startTest();
   		
   		con.status__c = 'Order Approved';
   		update con;
   		
   		test.stopTest();
      	
   }//end testgroupservicesnotification
   */
}