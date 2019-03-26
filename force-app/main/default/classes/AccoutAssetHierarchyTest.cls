@isTest
public with sharing class AccoutAssetHierarchyTest
{
    //shawks 201810: CPQ - update to use out-of-box object Contract instead of Contract__c and use CPQ object SBQQ__Subscription__c instead of Contract_Line_Item__c
    static testMethod void hierarchyTest()
    {
    	//jjackson 11/2017 added the card_ID__c field to the asset test record because
    	//this value now pulls to the asset hierarchy vf page
        Account acc = DataGenerator.createAccounts(1,true)[0];
        Product2 p = new Product2(Name = 'TestProduct', productCode = 'CC-Test01');  //shawks CPQ - Added productCode since include in populateAssetHierarchy query
        insert p;
        Asset a1 = new Asset(AccountId = acc.Id, Name = 'Test Asset 1', Product2Id = p.Id);
        insert a1;

        //shawks BUG-00176: Add Contract and Lines since Delivery Method on Legal Contract Line Items now
		//Contract__c lc = new Contract__c(Account_Name__c=acc.id,Status__c='Order Approved', lifetime_value_of_deal__c = 1000, upfront_subsidy__c = 100);
		Contract lc = new Contract(AccountId=acc.id, Contract_Status__c='Order Approved', upfront_subsidy__c = 100);
		insert lc;

		//Contract_Line_Item__c lcli1 = new Contract_Line_Item__c(Name='Test Product Parent', Legal_Contract__c=lc.id, Project_Type__c='Interactive New Rooms',
		//                              Status__c='Pending Installation Activate', Product__c=p.id, Delivery_Method__c = 'DirecTV-A-4/4-TH',
		//	                          quantity__c = 100, equipment_ownership__c = 'CUST');
		SBQQ__Subscription__c lcli1 = new SBQQ__Subscription__c(Name__c='Test Product Parent', SBQQ__Contract__c=lc.id, Project_Type__c='Interactive New Rooms',
		                              Status__c='Pending Installation Activate', SBQQ__Product__c=p.id, SBQQ__Quantity__c = 100, equipment_ownership__c = 'CUST');
		insert lcli1;
        //Dummy test values
        Asset a2 = new Asset(
        AccountId = acc.Id,
        Name = 'Test Asset 2',
        Status = 'Installed',
        Product2Id = p.Id,
        System_Status__c = 'Operational',
        Term_Start_Date__c = Date.today(),
        Term_End_Date__c = Date.today().addDays(1),
        Service_Start_Date__c = Date.today(),
        Service_End_Date__c = Date.today(),        
        Cancellation_Date__c = Date.today(),
        Auto_Renew__c = true,
        Platform__c = 'RIVER',
        Renewal_Term__c = 1,
        Renewal_Cycle__c = 1,
        Parent_Asset__c = a1.Id,
        Quantity = 10,
        Billing_Quantity__c = 10,
        //legal_contract_line_item__c = lcli1.Id,
        Subscription_Item__c = lcli1.Id,
        Receiver_ID__c = 'test',
        DTV_Account_Number__c = '123',
        SerialNumber = 'test',
        System_ID__c = '123',
        card_ID__c = '6789',
        Fee_Schedule__c = 'Monthly');
        //Delivery_Method__c = 'DirecTV-A-4/4-TH');
        insert a2;

        PageReference pr = Page.AccountAssetHierarchy;
        pr.getParameters().put('id',acc.Id);
        pr.getParameters().put('selectedStatus', 'Cancelled');
        pr.getParameters().put('massupdate1', '100');
        pr.getParameters().put('massupdate2', '01/01/2017');
        Test.setCurrentPageReference(pr);
        Test.startTest();
            AccountAssetHierarchyExtension controller = new AccountAssetHierarchyExtension(new ApexPages.StandardController(acc));
			controller.setAssetStatus();

        Test.stopTest();
        system.assert(controller.assetMap.isEmpty() != true, 'The assetMap in the controller should not be empty');  //shawks CPQ - Verify query returns records
        system.assert(controller.treeJSON != null, 'The JSON String in the controller should not be null');
    }

    //shawks 201810: CPQ - update to use out-of-box object Contract instead of Contract__c
    static testmethod void loadContracts(){
    	Account acc = DataGenerator.createAccounts(1,true)[0];
    	//contract
    	//Contract__c con1 = new Contract__c(Account_Name__c = acc.id, Status__c = 'Draft');
    	Contract con1 = new Contract(AccountId = acc.id, Contract_Status__c = 'Draft');
    	insert con1;

    	PageReference pr = Page.AccountAssetHierarchy;
        pr.getParameters().put('id',acc.Id);
        Test.setCurrentPageReference(pr);
        Test.startTest();
            AccountAssetHierarchyExtension controller = new AccountAssetHierarchyExtension(new ApexPages.StandardController(acc));
            controller.loadContracts();
        Test.stopTest();

        //assertions
        System.assertEquals(2, controller.contractMap.Values().size());
    }

    //shawks 201810: CPQ - update to use out-of-box object Contract instead of Contract__c and use CPQ object SBQQ__Subscription__c instead of Contract_Line_Item__c
    //                   - Since SBQQ__Quantity__c is a required field for Subscription need to include quantity for Asset record
    static testmethod void saveContract(){
    	Account acc = DataGenerator.createAccounts(1,true)[0];
    	Product2 p = new Product2(Name = 'TestProduct');
        insert p;
        Asset a1 = new Asset(AccountId = acc.Id, Name = 'Test Asset 1', Product2Id = p.Id, Quantity = 1);
        insert a1;
    	//Contract__c con1 = new Contract__c(Account_Name__c = acc.id, Status__c = 'Draft');
    	Contract con1 = new Contract(AccountId = acc.id, Contract_Status__c = 'Draft');
    	insert con1;

    	PageReference pr = Page.AccountAssetHierarchy;
        pr.getParameters().put('id',acc.Id);
        pr.getParameters().put('contractId', con1.id);
        pr.getParameters().put('selectedKeys','['+JSON.serialize(a1.id) + ']');
        Test.setCurrentPageReference(pr);
        Test.startTest();
            AccountAssetHierarchyExtension controller = new AccountAssetHierarchyExtension(new ApexPages.StandardController(acc));
            controller.saveTasks();
        Test.stopTest();

        //List<Contract_Line_Item__c> cList = [SELECT id FROM Contract_Line_Item__c WHERE Product__c=:a1.Product2Id];
        List<SBQQ__Subscription__c> cList = [SELECT id FROM SBQQ__Subscription__c WHERE SBQQ__Product__c=:a1.Product2Id];

        //assertions
        System.assertEquals(1, cList.size());
    }
}