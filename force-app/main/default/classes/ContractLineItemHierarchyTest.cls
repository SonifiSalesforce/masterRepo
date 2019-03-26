@isTest
public with sharing class ContractLineItemHierarchyTest
{
    static testMethod void hierarchyDeleteTest()
    {
    	List<Product2> products = new List<Product2>(); 
    	Product2 p = new Product2(Name = 'Test Product');
        products.add(p);
        Product2 p2 = new Product2(Name = 'Test Product2');
        products.add(p2);
        insert products;    	
        Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract__c lc = new Contract__c(Account_Name__c = acc.id);
        insert lc;       
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        Product__c = p.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        quantity__c = 1,
        Delivery_Method__c = 'DirecTV-A-4/4-TH',
        Renewal_Cycle__c = 1);
        insert cli1;
        Contract_Line_Item__c cli2 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        Product__c = p2.Id,
        quantity__c = 1,
        Parent__c = cli1.Id);
        insert cli2;
        
        //Set Test Page Reference
        PageReference pr = Page.ContractLineItemHierarchy;
        pr.getParameters().put('id',lc.Id);
        //JSONify the SelectedIds parameter
        List<String> cliDeleted = new List<String>();
		cliDeleted.add(cli2.Id);
		pr.getParameters().put('selectedKeysJSON', JSON.serialize(cliDeleted));
        Test.setCurrentPageReference(pr);
        Test.startTest();
            ContractLineItemHierarchyExtension controller = new ContractLineItemHierarchyExtension(
            new ApexPages.StandardController(lc));
            //TreeJSON string should not be null
            system.assert(controller.treeJSON != null, 'The JSON String on the controller should not be empty');
            //Test Delete, Ids are in parameter
            controller.deleteContractLineItems();
        Test.stopTest();
        //Should only be 1 CLI left
        List<Contract_Line_Item__c> cliList = [SELECT Id from Contract_Line_Item__c WHERE Id = :cli2.Id];
        system.assert(cliList.size() == 0, 'The CLI selected should be deleted');
    }   
    
    static testMethod void loadOrders()
    {
    	//set test getters
    	Integer numOrders = 0;
    	
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract__c lc = new Contract__c(Account_Name__c = acc.id);
        insert lc;
        Product2 p = new Product2(Name = 'Test Product');
        Product2 p1 = new Product2(Name='Another Test Product');
        insert p;
        insert p1;
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        Product__c = p.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        quantity__c = 1,
        Renewal_Cycle__c = 1);
        insert cli1;
        Contract_Line_Item__c cli2 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        quantity__c = 1,
        Parent__c = cli1.Id, product__c = p1.id);
        
        insert cli2;
        Order__c o1 = new Order__c(name='test Order', Site__c = acc.id, Status__c = 'Order Approved');
        insert o1;
        
        //Set Test Page Reference
        PageReference pr = Page.ContractLineItemHierarchy;
        pr.getParameters().put('id',lc.Id);
        Test.setCurrentPageReference(pr);
        Test.startTest();
            ContractLineItemHierarchyExtension controller = new ContractLineItemHierarchyExtension(
            new ApexPages.StandardController(lc));
            //Test Delete, Ids are in parameter
			numOrders = controller.orderMap.Values().size();
        Test.stopTest();
        
        system.assertEquals(3, numOrders);
    }
    
    static testMethod void saveTasks()
    {
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract__c lc = new Contract__c(Account_Name__c = acc.id);
        insert lc;
        Product2 p = new Product2(Name = 'Test Product Parent');
        Product2 p1 = new Product2(Name='Test Line Item');
        insert p;
        insert p1;
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        Product__c = p.Id,
        quantity__c = 1,
        Status__c = 'Contract Sent',
        Name = 'Test Product Parent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Renewal_Cycle__c = 1);
        insert cli1;
        Contract_Line_Item__c cli2 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        quantity__c = 1,
        Parent__c = cli1.Id, product__c = p1.id);
        insert cli2;
        Order__c o1 = new Order__c(name='test Order', Site__c = acc.id, Status__c = 'Order Approved');
        insert o1;
        
        //Set Test Page Reference
        PageReference pr = Page.ContractLineItemHierarchy;
        pr.getParameters().put('id',lc.Id);
        pr.getParameters().put('orderId',o1.Id);
        pr.getParameters().put('selectedKeys','['+JSON.serialize(cli1.id) + ']');
        pr.getParameters().put('processOrder',o1.id);
        pr.getParameters().put('affectAssets','true');
        pr.getParameters().put('affectService','true');
        pr.getParameters().put('affectEntitle','true');
        pr.getParameters().put('affectMarina','true');
        Test.setCurrentPageReference(pr);
        Test.startTest();
            ContractLineItemHierarchyExtension controller = new ContractLineItemHierarchyExtension(
            new ApexPages.StandardController(lc));
            //TreeJSON string should not be null
            system.assert(controller.treeJSON != null, 'The JSON String on the controller should not be empty');
            //Test Delete, Ids are in parameter
			controller.saveTasks();
        Test.stopTest();

		
    }   
    
    static testMethod void MassUpdate()
    {
    	
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract__c lc = new Contract__c(Account_Name__c = acc.id);
        insert lc;
        Product2 p = new Product2(Name = 'Test Product Parent');
        Product2 p1 = new Product2(Name = 'Test Product1');
        List<Product2> productlist = New List<Product2>();
        productlist.add(p);
        productlist.add(p1);
        insert productlist;
        
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        Product__c = p.Id,
        Name = 'Test Product Parent',
        project_type__c = '',
        quantity__c = 1,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Renewal_Cycle__c = 1);
        
 		Contract_Line_Item__c cli2 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        Product__c = p1.Id,
        Name = 'Test Product',
        project_type__c = '',
        quantity__c = 1,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Renewal_Cycle__c = 1);
 
 		List<Contract_Line_Item__c> clilist = New List<Contract_Line_Item__c>();
 		clilist.add(cli1);
 		clilist.add(cli2);
 		insert clilist;
 		
  		PageReference pr = Page.ContractLineItemHierarchy;
 		pr.getParameters().put('id',lc.Id);
        pr.getParameters().put('selectedKeys','['+JSON.serialize(cli2.id) + ']');
        pr.getParameters().put('selectedProjectType', 'Project Type');
        Test.setcurrentpagereference(pr);
        Test.startTest();
         
        ContractLineItemHierarchyExtension controller = new ContractLineItemHierarchyExtension(
                                                       new ApexPages.StandardController(lc));
        controller.massUpdateFields();
        Test.stopTest();
        
        Contract_Line_Item__c updlcli = [ Select Id, project_type__c from contract_line_item__c where id = :cli2.Id LIMIT 1 ];
        system.debug('CLI Hierarchy Test line item project type is ' +updlcli.project_type__c);

    } 
}