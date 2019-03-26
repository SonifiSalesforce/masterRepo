@isTest
private class FinalizeContractExtensionTests {

    static testMethod void loadOrders()
    {
    	//set test getters
    	Integer numOrders = 0;
    	
    	Id rectypeid = Utilities.RecordTypeNameToId('Contract__c', 'Contract Amendment');
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract__c lc = new Contract__c(Account_Name__c = acc.id);
        insert lc;
        Contract__c amend = New Contract__c(Account_Name__c = acc.id, recordtypeid = rectypeid, extended_warranty_start_date__c = system.today());
        insert amend;        
        Product2 p = new Product2(Name = 'Test Product Parent');
        Product2 p2 = New Product2(Name = 'Child Line');
        Product2 p3 = New Product2(Name = 'Extended Warranty STAY1000', Family = 'Warranty' );
        List<Product2> createproducts = New List<Product2>();
        createproducts.add(p);
        createproducts.add(p2);
        createproducts.add(p3);
        insert createproducts;
        
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        Product__c = p.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Name = 'Test Product Parent',
        equipment_ownership__c = 'CUST',
        project_type__c = 'Other',
        Renewal_Cycle__c = 1);
        insert cli1;
        
        Contract_Line_Item__c cli2 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        product__c = p2.Id,
        Name = 'Child Line',
        Parent__c = cli1.Id);
        insert cli2;
        
        //jjackson 5/2017 create another product parent line item and an extended warranty line item for the contract amendment
        Contract_Line_Item__c cliamend = new Contract_Line_Item__c(
        Legal_Contract__c = amend.Id,
        Product__c = p.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Name = 'Test Product Parent',
        equipment_ownership__c = 'CUST',
        project_type__c = 'FTG New Rooms',
        Renewal_Cycle__c = 1);
        insert cliamend;
        
        Contract_Line_Item__c amend2 = new Contract_Line_Item__c(
        Legal_Contract__c = amend.Id,
        product__c = p3.Id,
        Name = 'Extended Warranty STAY1000',
        Parent__c = cliamend.Id);
        insert amend2;
        
        Order__c o1 = new Order__c(name='test Order', Site__c = acc.id, Status__c = 'Order Approved');
        insert o1;
        
        //Set Test Page Reference
        PageReference pr = Page.FinalizeContract;
        pr.getParameters().put('id',lc.Id);
        Test.setCurrentPageReference(pr);
        Test.startTest();
            FinalizeContractExtension controller = new FinalizeContractExtension(
            new ApexPages.StandardController(lc));
            
            //Test load
			numOrders = controller.orderMap.Values().size();
        Test.stopTest();
        
        system.assertEquals(3, numOrders);
        
        //jjackson 5/2017 pass the contract amendment into the controller to cover the extended warranty code
        PageReference ref = Page.FinalizeContract;
        ref.getParameters().put('id', amend.id);
        Test.setCurrentPageReference(ref);
        FinalizeContractExtension cont = New FinalizeContractExtension(new ApexPages.StandardController(amend));
    }
    
    //added by jjackson 6/12/2014
    static testMethod void VerifyProjectType()
    {
    	Id rectypeid = Utilities.RecordTypeNameToId('Contract__c', 'Contract Amendment');
    	
        Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract__c lc = new Contract__c(Account_Name__c = acc.id);
        insert lc;
        
        Contract__c amend = New Contract__c(Account_Name__c = acc.id, recordtypeid = rectypeid, extended_warranty_start_date__c = system.today());
        insert amend;        
        Product2 p2 = New Product2(Name = 'Child Line');
        insert p2;
        Product2 p3 = New Product2(Name = 'Extended Warranty STAY1000', Family = 'Warranty' );
        insert p3;
        Product2 p = new Product2(Name = 'FTG Product Parent');
        insert p;
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(
        Name = 'FTG Product Parent',
        Legal_Contract__c = lc.Id,
        Quantity__c = 100,
        Product__c = p.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Renewal_Cycle__c = 1
        );
        insert cli1;
        
        Contract_Line_Item__c cliamend = new Contract_Line_Item__c(
        Legal_Contract__c = amend.Id,
        Product__c = p.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Name = 'FTG Product Parent',
        equipment_ownership__c = 'CUST',
        project_type__c = 'FTG New Rooms',
        Renewal_Cycle__c = 1);
        insert cliamend;
        
        Contract_Line_Item__c amend2 = new Contract_Line_Item__c(
        Legal_Contract__c = amend.Id,
        product__c = p3.Id,
        Name = 'Extended Warranty STAY1000',
        Parent__c = cliamend.Id);
        insert amend2;
        
        //Set Test Page Reference
        PageReference pr = Page.FinalizeContract;
        pr.getParameters().put('id',lc.Id);
        pr.getParameters().put('processOrder','New_Order');
        Test.setCurrentPageReference(pr);
        Test.startTest();
            FinalizeContractExtension controller = new FinalizeContractExtension(
            new ApexPages.StandardController(lc));
            Boolean testpass = controller.VerifyProjectType(lc);
            
        Test.stopTest();
        
       system.assert(testpass);
       // system.debug('testpass = ' +testpass);
        
        PageReference ref = Page.FinalizeContract;
        Test.setCurrentPage(ref);
        ApexPages.currentPage().getParameters().put('id', amend.id);
        ref.getParameters().put('affectService', 'true');
        FinalizeContractExtension ext = New FinalizeContractExtension(new ApexPages.StandardController(amend));
        Boolean pass = ext.VerifyProjectType(amend);
    
    }
    static testMethod void saveTasks()
    {
    	Id rectypeid = Utilities.RecordTypeNameToId('Contract__c', 'Contract Amendment');
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
        Contract__c lc = new Contract__c(Account_Name__c = acc.id);
        insert lc;
        Contract__c amend = New Contract__c(Account_Name__c = acc.id, recordtypeid = rectypeid, extended_warranty_start_date__c = system.today());
        insert amend;        
        Product2 p2 = New Product2(Name = 'Child Line');
        insert p2;
        Product2 p3 = New Product2(Name = 'Extended Warranty STAY1000', Family = 'Warranty' );
        insert p3;
        Product2 p = new Product2(Name = 'FTG Product Parent');
        insert p;
        //create product parent line
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        Product__c = p.Id, name='FTG Product Parent',
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        project_type__c = 'FTG New Rooms',
        equipment_ownership__c = 'CUST',
        Renewal_Cycle__c = 1);
        insert cli1;
        
        //create child line
        Contract_Line_Item__c cli2 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        product__c = p2.id, Name='Child Line',
        Parent__c = cli1.Id);
        insert cli2;
        Order__c o1 = new Order__c(name='test Order', Site__c = acc.id);
        insert o1;
        
        //jjackson 5/2017 test finalize button when contract is an amendment with extended warranty line item
        //test product parent
        Contract_Line_Item__c cliamend = new Contract_Line_Item__c(
        Legal_Contract__c = amend.Id,
        Product__c = p.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        project_type__c = 'FTG New Rooms',
        equipment_ownership__c = 'CUST',
        Auto_Renew__c = true,
        Name = 'FTG Product Parent',
        Renewal_Cycle__c = 1);
        insert cliamend;
        
        //warranty line item
        Contract_Line_Item__c amend2 = new Contract_Line_Item__c(
        Legal_Contract__c = amend.Id,
        product__c = p3.Id,
        Name = 'Extended Warranty STAY1000',
        Parent__c = cliamend.Id);
        insert amend2;
        
        
        //Set Test Page Reference
        PageReference pr = Page.FinalizeContract;
        pr.getParameters().put('id',lc.Id);
        pr.getParameters().put('orderId',o1.Id);
        pr.getParameters().put('selectedKeys','['+JSON.serialize(cli1.id) + ']');
        pr.getParameters().put('processOrder',o1.id);
        pr.getParameters().put('affectAssets','true');
        pr.getParameters().put('affectService','true');
        pr.getParameters().put('affectEntitle','true');
        Test.setCurrentPageReference(pr);
        Test.startTest();
            FinalizeContractExtension controller = new FinalizeContractExtension(
            new ApexPages.StandardController(lc));
            //Test saveTasks 
			controller.saveTasks();
        Test.stopTest();
        
        PageReference ref = Page.FinalizeContract;
        Test.setCurrentPage(ref);
        ref.getParameters().put('affectService', 'true');
        FinalizeContractExtension ext = New FinalizeContractExtension(new ApexPages.StandardController(amend));
        ext.saveTasks();
        
    }     
}