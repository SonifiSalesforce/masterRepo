@isTest
private class StandardAssetTriggerLogicTests {

    static testMethod void updateContractLineItem() {
    	//create test data
        Account acc = new Account(Name='test aCC');
        insert acc;
    
        //shawks 20180928: CPQ - update to use out-of-box object Contract instead of Contract__c; replace Account_Name__c with AccountId
        //Contract__c con = new Contract__c(Account_Name__c = acc.id);
        Contract con = new Contract(AccountId = acc.id);
        insert con;
        
        Product2 p1 = new Product2(Name= 'Test product1');
        Product2 p2 = New Product2(Name='Test Product2');
        insert p1;
        insert p2;
        
        //shawks 20180928: CPQ - update to use CPQ object SBQQ__Subscription__c instead of Contract_Line_Item__c; replace Legal_Contract__c with SBQQ__Contract__c
        //-> replace: Name -> Name__c; quantiy__c -> SBQQ__Quantity__c; product__c -> SBQQ__Product__c
        //Contract_Line_Item__c cli1 = new Contract_Line_Item__c(Name = 'Test cli', Legal_Contract__c = con.id, quantity__c = 10, product__c=p1.id);
        //SBQQ__Subscription__c cli1 = new SBQQ__Subscription__c(SBQQ__Account__c = 'Test cli', SBQQ__Contract__c = con.id, SBQQ__Quantity__c = 10, SBQQ__Product__c=p1.id);
        SBQQ__Subscription__c cli1 = new SBQQ__Subscription__c(Name__c = 'Test cli', SBQQ__Contract__c = con.id, SBQQ__Quantity__c = 10, SBQQ__Product__c=p1.id);
        //insert cli1;
        
        //Contract_Line_Item__c cli2 = new Contract_Line_Item__c(Name = 'Test cli 2', Legal_Contract__c = con.id, quantity__c = 10, product__c=p2.id);
        SBQQ__Subscription__c cli2 = new SBQQ__Subscription__c(Name__c = 'Test cli 2', SBQQ__Contract__c = con.id, SBQQ__Quantity__c = 10, SBQQ__Product__c=p2.id);
        //insert cli2;
        //jjackson do one insert for contract line items
        insert new list<SBQQ__Subscription__c>{cli1,cli2};
        
        //shawks 20180928: CPQ - Replace Legal_Contract_Line_Item__c with Subscription__c
        //Asset a1 = new Asset(Legal_Contract_Line_Item__c = cli1.id, name = 'test asset', AccountId = acc.id, Status = 'Billing', Term_Start_Date__c = date.newInstance(2013, 1, 1),Term__c=12, Manually_Override_Term_End_Date__c = false);
        //Asset a2 = new Asset(Legal_Contract_Line_Item__c = cli2.id, name = 'test asset 2', AccountId = acc.id,Term_Start_Date__c = date.newInstance(2013, 12, 31),Term__c=48, Manually_Override_Term_End_Date__c = false);
        Asset a1 = new Asset(Subscription_item__c = cli1.id, name = 'test asset', AccountId = acc.id, Status = 'Billing', Term_Start_Date__c = date.newInstance(2013, 1, 1),Term__c=12, Manually_Override_Term_End_Date__c = false);
        Asset a2 = new Asset(Subscription_item__c = cli2.id, name = 'test asset 2', AccountId = acc.id,Term_Start_Date__c = date.newInstance(2013, 12, 31),Term__c=48, Manually_Override_Term_End_Date__c = false);
        insert a2;
        a2.Status = 'Billing';
        a1.Status = 'Installed Activated';
        
        //start test
        Test.StartTest();
        insert a1;
        
        update new list<Asset>{a1, a2};
        
        Test.stopTest();
        
        //requery the results
        //shawks 20180928: CPQ - update to use CPQ object SBQQ__Subscription__c instead of Contract_Line_Item__c
        //List<Contract_Line_Item__c> cliList = [SELECT id, Status__c FROM Contract_Line_Item__c ];
        List<SBQQ__Subscription__c> cliList = [SELECT id, Status__c FROM SBQQ__Subscription__c ];
        
        //assertions
        System.assertEquals('Installed Activated', cliList[0].Status__c);
        System.assertEquals('Billing', cliList[1].Status__c);
    }
    
    //jjackson 8/2016 this code commented out of the trigger logic, so also taking away the unit test
    
   /* static testMethod void updateEndDates() {
    	//create test data
        Account acc = new Account(Name='test aCC');
        insert acc;
    
        Contract__c con = new Contract__c(Account_Name__c = acc.id);
        insert con;
        
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(Name = 'Test cli', Legal_Contract__c = con.id, quantity__c = 10);
        insert cli1;
        
        Contract_Line_Item__c cli2 = new Contract_Line_Item__c(Name = 'Test cli 2', Legal_Contract__c = con.id, quantity__c = 10);
        insert cli2;
        
        List<Asset> assets = new List<Asset>();
        
        assets.add(new Asset(Legal_Contract_Line_Item__c = cli1.id, name = 'test asset', AccountId = acc.id, Status = 'Billing', Term_Start_Date__c = date.newInstance(2013, 1, 1),Term__c=12, Manually_Override_Term_End_Date__c = false));
        
        assets.add(new Asset(Legal_Contract_Line_Item__c = cli2.id, name = 'test asset 2', AccountId = acc.id,Term_Start_Date__c = date.newInstance(2013, 12, 31),Term__c=48, Manually_Override_Term_End_Date__c = false));
        
        assets.add(new Asset(Legal_Contract_Line_Item__c = cli2.id, name = 'test asset 3', AccountId = acc.id,Term_Start_Date__c = date.newInstance(2013, 12, 31),Term__c=12, Term_End_Date__c = date.newInstance(2014, 1, 1), Manually_Override_Term_End_Date__c = true));
        
        assets.add(new Asset(Legal_Contract_Line_Item__c = cli2.id, name = 'test asset 4', AccountId = acc.id, Manually_Override_Term_End_Date__c = false));
        
        //start test
        Test.StartTest();
        insert assets;        
        Test.stopTest();
        
        //requery the results
        Asset asset1 = [SELECT Id, Term_End_Date__c FROM Asset WHERE ID = :assets[0].Id][0];
        Asset asset2 = [SELECT Id, Term_End_Date__c FROM Asset WHERE ID = :assets[1].Id][0];
        Asset asset3 = [SELECT Id, Term_End_Date__c FROM Asset WHERE ID = :assets[2].Id][0];
        Asset asset4 = [SELECT Id, Term_End_Date__c FROM Asset WHERE ID = :assets[3].Id][0];
        
        //assertions
        //System.assertEquals(date.newInstance(2014, 1, 1), asset1.Term_End_Date__c);
        //System.assertEquals(date.newInstance(2018, 1, 1),  asset2.Term_End_Date__c);
        //System.assertEquals(date.newInstance(2014, 1, 1),  asset3.Term_End_Date__c);
        //System.assertEquals(null,  asset4.Term_End_Date__c);
    }*/
    static testMethod void testRollupSummary()
    {
    	Account a = new Account(Name = 'TestAsset');
    	insert a;
        System.debug(LoggingLevel.DEBUG,'testRollupSummary start');
    	Product2 p0 = new Product2(Name = 'Test Productparent', Family = 'FTG'); 
    	//insert p0;
    	Product2 p1 = new Product2(Name = 'Test Producthd', Channel_Type__c = 'HD');
    	//insert p1;
    	Product2 p2 = new Product2(Name = 'Test Productanalog', Channel_Type__c = 'Analog');
    	//insert p2;
    	Product2 p3 = new Product2(Name = 'Test Productsd', Channel_Type__c = 'SD');
    	Product2 p4 = new Product2(Name = 'Local Programming Fee', productcode = 'CC-localprogramming', price_category__c = 'Locals Programming');
    	//insert p3;
    	//jjackson do one insert for products
    	try {insert new list<Product2>{p0,p1,p2,p3,p4}; }
    	catch(Exception e){
    		system.debug('Exception e inserting products: ' +e.getmessage());
    	}
     	Asset ass1 = new Asset(AccountId = a.Id, Name = 'Test Asset', Product2Id = p0.Id, Status = 'Installed Activated');
    	try {insert ass1; }
    	catch(Exception ex){
    		system.debug('Exception ex inserting ass1: ' +ex.getmessage());
    	}
     	Asset ass2 = new Asset(AccountId = a.Id, Name = 'Test Asset', Parent_Asset__c = ass1.Id, Product2Id = p1.Id, Status = 'Installed Activated', Product_Parent_Id__c = ass1.id);
    	Asset ass3 = new Asset(AccountId = a.Id, Name = 'Test Asset', Parent_Asset__c = ass1.Id, Product2Id = p2.Id, Status = 'Installed Activated', Product_Parent_Id__c = ass1.id);
    	Asset ass4 = new Asset(AccountId = a.Id, Name = 'Test Asset', Parent_Asset__c = ass1.Id, Product2Id = p3.Id, Status = 'Installed Activated', Product_Parent_Id__c = ass1.id);
    	Asset ass5 = new Asset(AccountId = a.Id, Name = 'Local Program Asset', Parent_Asset__c = ass1.Id, Product2Id = p4.Id, Status = 'Installed Activated', Product_Parent_Id__c = ass1.id,
    	                       quantity = 45, price__c = 5.00);
        Asset ass6 = new Asset(AccountId = a.Id, Name = 'Local Program Asset 2', Parent_Asset__c = ass1.Id, Product2Id = p4.Id, Status = 'Installed Activated', Product_Parent_Id__c = ass1.id,
                               quantity = 1, price__c = 100.00);	                       

    	Test.startTest();
       
    	//insert ass2;
		//insert ass3;
		//insert ass4;
		//jjackson 8/2014 do one insert
		try { insert new list<Asset>{ass2,ass3,ass4,ass5,ass6};  }
		catch(Exception b){
			system.debug('Exception b inserting child assets: ' + b.getmessage());
		}
		
		ass4.Status = 'Billing';
		try { update ass4;  }
		catch(Exception c){
			system.debug('Exception c updating ass4: ' + c.getmessage());
		}
    	Test.stopTest();
    	
    	//Asset getass1 = [SELECT HD_Channel_Count__c, SD_Channel_Count__c, Analog_Channel_Count__c from Asset WHERE Id = :ass1.Id][0];
    	//system.debug('channel count rollup is hd, sd, analog: ' +getass1.HD_Channel_Count__c +', ' +getass1.SD_Channel_Count__c + ', ' +getass1.Analog_Channel_Count__c);
    	//system.assert(getass1.HD_Channel_Count__c == 1, 'HD channel count is ' +getass1.HD_Channel_Count__c);
    	//system.assert(getass1.SD_Channel_Count__c == 1, 'SD Channel count is '+getass1.SD_Channel_Count__c);
    	//system.assert(getass1.Analog_Channel_Count__c == 1, 'Analog Channel count is '+getass1.Analog_Channel_Count__c);  
    } 
}