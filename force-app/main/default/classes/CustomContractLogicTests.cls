@isTest
private class CustomContractLogicTests {

    static testMethod void createContractLineItems() {
        
    	Account acc = new Account(Name = 'Test Acc');
    	insert acc;
    	Opportunity oppRec = new Opportunity(AccountID=acc.id,Name='Test Opp',StageName='Prospect',CloseDate=system.today().addDays(1));
    	insert oppRec;
        Contract__c lc = new Contract__c(Account_Name__c = acc.id);
        insert lc;
        Product2 p = new Product2(Name = 'Test Product Parent');
        Product2 p2 = new Product2(Name = 'Test Product Package');
        insert new List<Product2>{p, p2};
        Programming__c prgm=new Programming__c(Opportunity__c=oppRec.ID,Product__c=p.id,Price__c=1000,Qty__c=10);
        insert prgm;
        Asset asset1 = new Asset(
        Name = 'Asset 1',
        AccountId = acc.id,
        Product2Id = p.id,
        quantity = 1,
        Price__c = 200.00);
        insert asset1;
        Asset asset2 = new Asset(
        Name = 'Asset 2',
        AccountId = acc.id,
        Product2Id = p2.id,
        Price__c = 200.00,
        quantity = 1,
        Parent_Asset__c = asset1.id);
        insert asset2;
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        Product__c = p.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Renewal_Cycle__c = 1,
        quantity__c = 1,
        price__c = 25.00,
        Name = 'Test Product Parent',
        Product_Inventory__c = asset1.id,
        project_type__c = 'FTG New Rooms',
        equipment_ownership__c = 'CUST');
        insert cli1;
        AppConfig__c appCfg=new AppConfig__c();
        appCfg.Name='Global';
        appCfg.Business_Hours__c='Default';
        appCfg.Entitlement_Product_Family__c='Entitlement';
        appCfg.Service_Contract_Product_Family__c='Warranty';
        insert appCfg;
        
        Test.startTest();
            //Test create conract line items
			
			List<Id> lstassetids = New List<Id>();
			lstassetids.add(asset1.id);
			lstassetids.add(asset2.id);
			CustomContractLogic.createContractLineItems(lstassetids, lc.id);
        	//CustomContractLogic.CreateRelatedRecords(contractLineItemIds, true, null, true, true, true, true, null);
        	CustomContractLogic.ContractUpdate ctrctlogic=new CustomContractLogic.ContractUpdate(lc);
        	
        	//ctrctlogic.ContractUpdate ctrctUpd=new ctrctlogic.ContractUpdate(lc);
        	LIST <Contract_Line_Item__c> contractLItems=new LIST<Contract_Line_Item__c>();
        	contractLItems=CustomContractLogic.getContractItemsforContract(lc.id);
        	
        	
        
        Test.stopTest();
        //requery for the data
        List<Contract_Line_Item__c> cliItems = [ SELECT id FROM Contract_Line_Item__c where product_inventory__c in :lstassetids ];
        
        //system.debug('cliItems list size is ' +cliItems.size());
        System.assertEquals(2, cliItems.size());
        LIST<ID> pgmIDs=new LIST<ID>();
        	pgmIDs.add(prgm.ID);
        	CustomContractLogic.createContractLineItemsFromOpportunity(pgmIDs, lc.id, oppRec.ID, true);
    }
    
    static testMethod void createContractLIRelatedrecords(){
    	Account acc = DataGenerator.createAccounts(1,true)[0];
       

		Contract__c lc = new Contract__c(Account_Name__c=acc.id);
        insert lc;
        Product2 p = new Product2(Name = 'Warranty',Family='Warranty',ProductCode='1234');
        
        Product2 p1 = new Product2(Name = 'Service Contract',Family='Entitlement',ProductCode='12345');
                
        Product2 p2 = new Product2(Name = 'FTG Product Parent',Family='FTG',ProductCode='123456');
        
        //jjackson 6/12/2013  Added 3 more products to test getting project type for each level of the lcli hierarchy
        Product2 p3 = new Product2(Name = 'FTG Package Line', Family='FTG', ProductCode='2222222');
        
        Product2 p4 = new Product2(Name = 'FTG Child Line', Family = 'FTG', ProductCode='333333');
        
        Product2 p5 = new Product2(Name = 'FTG Subchild Line', Family = 'FTG', ProductCode = '444444');
        
        insert new List<Product2>{p,p1,p2,p3,p4,p5};
        
        
        AppConfig__c appCfg=new AppConfig__c();
        appCfg.Name='Global';
        appCfg.Business_Hours__c='Default';
        appCfg.Entitlement_Product_Family__c='Entitlement';
        appCfg.Service_Contract_Product_Family__c='Warranty';
        insert appCfg;
        
        
        Marina_Service_Mod_Mapping__c mptstMarina=new Marina_Service_Mod_Mapping__c();
        mptstMarina.Name='1234';
        mptstMarina.part_number__c = '123456'; //shawks BUG-00220 - Add so setting value is matched on product2.ProductCode
        mptstMarina.Marina_Class__c='test';
        mptstMarina.Marina_Module_Description__c='test';
        mptstMarina.Marina_Service_Module__c='test SM';
        insert mptstMarina;
        
        //jjackson product parent line item
        Contract_Line_Item__c cli = new Contract_Line_Item__c(
        Name = 'FTG Product Parent',
        Legal_Contract__c = lc.Id,
        Product__c = p2.Id,
        Status__c = 'Contract Sent',
        Project_Type__c = 'FTG New Rooms',
        quantity__c = 1,
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Renewal_Cycle__c = 1);
        insert cli;
        
        //jjackson warranty line item
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(
        Name = 'Warranty',
        Legal_Contract__c = lc.Id,
        Product__c = p.Id,
        quantity__c = 1,
        Status__c = 'Contract Sent',
        Project_Type__c = 'FTG New Rooms',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Renewal_Cycle__c = 1,
        Parent__c=cli.id);
        insert cli1;
        
        //jjackson entitlement line item
        Contract_Line_Item__c cli2 = new Contract_Line_Item__c(
        Name = 'Service Contract',
        Legal_Contract__c = lc.Id,
        Product__c = p1.Id,
        quantity__c = 1,
        Parent__c = cli.Id);
        insert cli2;
        
        //jjackson 6/12/2013 adding 3 more line items to establish line item hierarchy
        Contract_Line_Item__c cli3 = new Contract_Line_Item__c(
        Name = 'FTG Package Line',
        Legal_Contract__c = lc.Id,
        Parent__c = cli.Id,
        Product__c = p3.Id,
        Project_Type__c = 'FTG New Rooms',
        Status__c = 'Contract Sent',
        quantity__c = 1,
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Renewal_Cycle__c = 1);
        insert cli3;
        
        Contract_Line_Item__c cli4 = new Contract_Line_Item__c(
        Name = 'FTG Child Line',
        Legal_Contract__c = lc.Id,
        Parent__c = cli3.Id,
        Product__c = p4.Id,
        Status__c = 'Contract Sent',
        quantity__c = 1,
        Project_Type__c = 'FTG New Rooms',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Renewal_Cycle__c = 1);
        insert cli4;
        
        Contract_Line_Item__c cli5 = new Contract_Line_Item__c(
        Name = 'FTG Subchild Line',
        Legal_Contract__c = lc.Id,
        Parent__c = cli4.Id,
        Product__c = p5.Id,
        Project_Type__c = 'FTG New Rooms',
        Status__c = 'Contract Sent',
        quantity__c = 1,
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Renewal_Cycle__c = 1);
        insert cli5;
        
        
        LIST<ID> lstCntrLI=new LIST<ID>();
        
        Test.startTest();
        
        lstCntrLI.add(cli.id);
        lstCntrLI.add(cli1.id);
        lstCntrLI.add(cli2.id);
  
        ID OrderID=CustomContractLogic.CreateRelatedRecords(lstCntrLI, true, null, true, true, true, true, null);
        //CustomContractLogic.processContractStatusChange(lc);
       	ID OrdernewID=CustomContractLogic.CreateRelatedRecords(lstCntrLI, true, OrderID, true, true, true, true, null);
   
 		List<ServiceContract> lstservcon = [Select Id, Name from ServiceContract ];
 		List<Entitlement> lstentl = [Select Id, Name from Entitlement ];
       	
       	//jjackson 6/12/2013  Create a list of line item records to pass into methods
       	List<Contract_Line_Item__c> contritemlist = new list<Contract_Line_Item__c>();
       	contritemlist.add(cli);
       	contritemlist.add(cli3);
       	contritemlist.add(cli4);
       	contritemlist.add(cli5);
       	
       	Map<ID,String> parentmap = new map<ID,String>();
   //    	parentmap = CustomContractLogic.getProductParents(contritemlist);
   //    	Boolean contains = parentmap.containsKey(cli.id);
       	
       	//String returnedproject = CustomContractLogic.ParentProjectType(parentmap,cli5,contritemlist);
        //shawks BUG-00220 - Used to verify Marina Modules not duplicated since CreateRelatedRecords used more than once
        LIST<marina_module__c> lstmarina = [SELECT id FROM marina_module__c ];
        
        Test.stopTest();
        
        //jjackson 6/12/2014 Verify the map passed back contains the product parent record
        //verify the project type passed back = the project type on the product parent line item
        //verify there is only 1 service contract and 1 entitlement even though CreateRelatedRecords ran twice
      //  system.assert(contains);
      //  system.assertEquals('FTG New Rooms', returnedproject);
        system.assertEquals(lstservcon.size(), 1);
        system.assertEquals(lstentl.size(), 1);
        //shawks BUG-00220 - Verify Marina Modules not duplicated since CreateRelatedRecords used more than once
        system.assertEquals(1, lstmarina.size());
 
    }
    
    static testmethod void ExtendedWarrantyServiceContract()
    {
    	Id conrectype = Utilities.RecordTypeNameToId('Contract__c', 'Contract Amendment');
    	
    	Account acc = DataGenerator.createAccounts(1,true)[0];

        Product2 p = new Product2(Name = 'Warranty',Family='Warranty',ProductCode='1234');
        
        Product2 p1 = new Product2(Name = 'Entitlement',Family='Entitlement',ProductCode='12345');
                
        Product2 p2 = new Product2(Name = 'FTG Product Parent',Family='FTG',ProductCode='123456');
        
        Product2 p3 = new Product2(Name = 'FTG Child Line', Family = 'FTG', ProductCode='333333');
        
        Product2 p4 = new Product2(Name = 'Extended Warranty STAY1000', Family = 'Warranty', ProductCode = '23456');
        insert new List<Product2>{p,p1,p2,p3,p4};
        
        Contract__c lc = new Contract__c(Account_Name__c = acc.id);
        insert lc;
        
        Contract__c amend = New Contract__c(Account_Name__c = acc.id, recordtypeid = conrectype, extended_warranty_start_date__c = system.today());
        insert amend; 
        
        Contract_Line_Item__c cli1 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        Product__c = p2.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Name = 'FTG Product Parent',
        equipment_ownership__c = 'CUST',
        project_type__c = 'Other',
        Renewal_Cycle__c = 1);
        insert cli1;
        
        Contract_Line_Item__c cli2 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        parent__c = cli1.id,
        Product__c = p3.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Name = 'FTG Child Line',
        Renewal_Cycle__c = 1);
        insert cli2;
        
        Contract_Line_Item__c cli3 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        parent__c = cli1.id,
        Product__c = p.Id,
        Status__c = 'Contract Sent',
        Auto_Renew__c = true,
        Name = 'Warranty',
        Renewal_Cycle__c = 1);
        insert cli3;
        
        Contract_Line_Item__c cli4 = new Contract_Line_Item__c(
        Legal_Contract__c = lc.Id,
        parent__c = cli1.id,
        Product__c = p1.Id,
        Status__c = 'Contract Sent',
        Auto_Renew__c = true,
        Name = 'Entitlement',
        Renewal_Cycle__c = 1);
        insert cli4;
        
        Contract_Line_Item__c cli5 = new Contract_Line_Item__c(
        Legal_Contract__c = amend.Id,
        Product__c = p2.Id,
        Status__c = 'Contract Sent',
        Term_Start_Date__c = Date.Today(),
        Term_End_Date__c = Date.Today().addDays(1),
        Auto_Renew__c = true,
        Name = 'FTG Product Parent',
        Renewal_Cycle__c = 1);
        insert cli5;
        
        Contract_Line_Item__c cli6 = new Contract_Line_Item__c(
        Legal_Contract__c = amend.Id,
        parent__c = cli5.id,
        Product__c = p4.Id,
        Status__c = 'Contract Sent',
        Auto_Renew__c = true,
        Name = 'Extended Warranty STAY1000',
        Renewal_Cycle__c = 1);
        insert cli6;
         
        Asset a1 = New Asset(Name = 'FTG Product Parent', accountid = acc.id, product2id = p2.id, status = 'Installed Activated', 
                                     legal_contract__c = lc.id, legal_contract_line_item__c = cli1.id );
                                     
        insert a1;
        
        cli1.product_inventory__c = a1.id;
        update cli1;
        
        Entitlement ent = New Entitlement(Name = 'Entitlement', accountid = acc.id, assetid = a1.id, legal_contract_line_item__c = cli1.id,
                                          startdate = system.today().addDays(-5), enddate = system.today().addmonths(3));
        insert ent;
        
        ServiceContract sc = New ServiceContract(Name = 'Warranty', accountid = acc.id, legal_contract_line_item__c = cli3.id,
                                                 product_inventory__c = a1.id, startdate = system.today().addDays(-5),
                                                 enddate = system.today().addmonths(3));
        insert sc;
        
        ent.servicecontractid = sc.id;
        update ent;

        test.startTest();
                
        	CustomContractLogic.CreateExtendedWarrantyServiceContract(amend.id);
        	
        	List<ServiceContract> lstnewsc = New List<ServiceContract>();
        	lstnewsc = [Select id, name, legal_contract_line_item__c, product_inventory__c, startdate, enddate from
        	            ServiceContract where name = 'Extended Warranty STAY1000' ];
        	            
        	system.debug('lstnewsc size is ' +lstnewsc.size());
        	
        test.stopTest();
        
        
    }//end testmethod extended warranty service contract
}