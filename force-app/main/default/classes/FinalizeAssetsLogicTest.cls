@isTest
private class FinalizeAssetsLogicTest {

    static testMethod void testCreateNewAssets() {
        Account acct = CreateTestRecords.DefaultHospitalityAccount();
        Id rectypeid =Utilities.RecordTypeNameToId('Contract', 'Contract');
        Contract con = New Contract(recordtypeid = rectypeid, contract_status__c='Draft', accountid=acct.id,
                                   sbqq__renewalterm__c=1, renewal_cycle__c=30, company_code__c='01 Sonifi',
                                   contractterm=60, auto_renew__c=false);
        insert con;
        Product2 p1 = New Product2(Name='Interactive Product Parent', family='Interactive', productcode='CC-123-1234', isactive=true );
        Product2 p2 = New Product2(Name='STAY1000LX', productcode='CC-3030006', family='Interactive', isActive=true);
        Product2 p3 = New Product2(Name='System Information', productcode='CC-70000', isActive=true);
        Product2 p4 = New Product2(Name='Dashboard Monitor', productcode='CC-70101-0103', isActive=true);
        List<Product2> plist = New List<Product2>();
        plist.add(p1);
        plist.add(p2);
        plist.add(p3);
        plist.add(p4);
        insert plist;
        
        SBQQ__Subscription__c subparent = New SBQQ__Subscription__c(Name__c = 'Interactive Product Parent', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p1.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id);
        insert subparent;
        SBQQ__Subscription__c sub1 = New SBQQ__Subscription__c(Name__c = 'STAY1000LX', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p2.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=subparent.id);
        insert sub1;
        
        SBQQ__Subscription__c sub2 = New SBQQ__Subscription__c(Name__c = 'System Information', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p3.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=sub1.id);
        insert sub2;
        
        SBQQ__Subscription__c sub3 = New SBQQ__Subscription__c(Name__c = 'Dashboard Monitor', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p4.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=sub2.id);
        insert sub3;
        
        List<SBQQ__Subscription__c> lstsubs = New List<SBQQ__Subscription__c>();
        lstsubs = [Select Id, Name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, sbqq__contract__r.recordtype.name,
                    product_inventory__c, sbqq__product__r.family, sbqq__product__c, sbqq__product__r.name, marina_resource_ratio__c,
					sbqq__quantity__c, sbqq__regularprice__c, status__c, contract_type__c, product_parent_id__c, fee_schedule__c, platform__c,
					sbqq__account__c, sbqq__account__r.name, sbqq__product__r.productcode, parent__c, parent__r.sbqq__product__r.productcode,
					sbqq__startdate__c, sbqq__enddate__c, parent__r.sbqq__product__r.name, parent__r.product_inventory__c
					from SBQQ__Subscription__c where SBQQ__Contract__c = :con.id ];
					
		Map<Id,SBQQ__Subscription__c> mpsubs = New Map<Id,SBQQ__Subscription__c>();
		for(SBQQ__Subscription__c s :lstsubs)
		{  mpsubs.put(s.id, s);  }
        
        Marina_Service_Mod_Mapping__c marinamod = New Marina_Service_Mod_Mapping__c(Name='CC-70101-0103, 1156',
                                                  Description__c='Dashboard Monitor', Marina_Module_Description__c='Dashboard Monitor',
                                                  Marina_Service_Module__c='1156', Part_Number__c='CC-70101-0103');
        insert marinamod;
        
        FinalizeAssetsContractLogic.CreateNewAssets(mpsubs,con);
   
       List<Asset>lstassets = new List<Asset>();
       lstassets=[Select Id, Name from Asset];
       system.debug('lstassets size is ' +lstassets.size());
       
       List<Marina_Module__c>lstmm = New List<Marina_Module__c>();
       lstmm=[Select id, name from Marina_Module__c];
       system.debug('lstmm size is ' +lstmm.size());
        
    }
    
    static testmethod void testUpdateAssets()
    {
    	system.debug('begin testupdateassets');
    	
    	Account acct = CreateTestRecords.DefaultHospitalityAccount();
        Id rectypeid =Utilities.RecordTypeNameToId('Contract', 'Contract');
        Contract con = New Contract(recordtypeid = rectypeid, contract_status__c='Draft', accountid=acct.id,
                                   sbqq__renewalterm__c=1, renewal_cycle__c=30, company_code__c='01 Sonifi',
                                   contractterm=60, auto_renew__c=false);
        insert con;
        Product2 p1 = New Product2(Name='Interactive Product Parent', family='Interactive', productcode='CC-123-1234', isactive=true );
        Product2 p2 = New Product2(Name='STAY1000LX', productcode='CC-3030006', family='Interactive', isActive=true);
        Product2 p3 = New Product2(Name='System Information', productcode='CC-70000', isActive=true);
        Product2 p4 = New Product2(Name='Dashboard Monitor', productcode='CC-70101-0103', isActive=true);
        List<Product2> plist = New List<Product2>();
        plist.add(p1);
        plist.add(p2);
        plist.add(p3);
        plist.add(p4);
        insert plist;
        
        SBQQ__Subscription__c subparent = New SBQQ__Subscription__c(Name__c = 'Interactive Product Parent', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p1.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id);
        insert subparent;
        SBQQ__Subscription__c sub1 = New SBQQ__Subscription__c(Name__c = 'STAY1000LX', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p2.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=subparent.id);
        insert sub1;
        
        SBQQ__Subscription__c sub2 = New SBQQ__Subscription__c(Name__c = 'System Information', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p3.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=sub1.id);
        insert sub2;
        
        
        Asset a1 = New Asset(Name='Interactive Product Parent', subscription_item__c = subparent.id, contract__c = con.id, accountid=acct.id,
                             quantity=100, status='Pending Installation Activate');
        insert a1;
        subparent.product_inventory__c = a1.id;
        update subparent;
        
        Asset a2 = New Asset(Name='STAY1000LX', subscription_item__c = sub1.id, contract__c = con.id, accountid=acct.id,
                             quantity=100, status='Pending Installation Activate', parent_asset__c = a1.id);
        insert a2;
        sub1.product_inventory__c = a2.id;
        
        Asset a3 = New Asset(Name='System Information', subscription_Item__c = sub2.id, contract__c = con.id, accountid=acct.id,
                             quantity=100, parent_asset__c=a2.id, status='Pending Installation Activate');
        insert a3;
        
        sub2.product_inventory__c = a3.id;
        
        List<SBQQ__Subscription__c> sublist = New List<SBQQ__Subscription__c>();
        sublist.add(sub1);
        sublist.add(sub2);
        update sublist;
        
        List<SBQQ__Subscription__c> lstchangesubs = New List<SBQQ__Subscription__c>();
        List<SBQQ__Subscription__c> lstupdatesubs = New List<SBQQ__Subscription__c>();
        lstchangesubs = [Select Id, status__c, sbqq__quantity__c from sbqq__subscription__c];
        for(SBQQ__Subscription__c sub : lstchangesubs)
        {
        	sub.status__c = 'Cancelled';
        	sub.sbqq__quantity__c = 200;
        	lstupdatesubs.add(sub);
        }
        
        update lstupdatesubs;
        
        
        List<SBQQ__Subscription__c> lstsubs = New List<SBQQ__Subscription__c>();
        lstsubs = [Select Id, Name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, sbqq__contract__r.recordtype.name,
                    product_inventory__c, sbqq__product__r.family, sbqq__product__c, sbqq__product__r.name, marina_resource_ratio__c,
					sbqq__quantity__c, sbqq__regularprice__c, status__c, contract_type__c, product_parent_id__c, fee_schedule__c, platform__c,
					sbqq__account__c, sbqq__account__r.name, sbqq__product__r.productcode, parent__c, parent__r.sbqq__product__r.productcode,
					sbqq__startdate__c, sbqq__enddate__c, parent__r.sbqq__product__r.name, parent__r.product_inventory__c
					from SBQQ__Subscription__c where SBQQ__Contract__c = :con.id ];
					

					
		Map<Id,SBQQ__Subscription__c> mpsubs = New Map<Id,SBQQ__Subscription__c>();
		for(SBQQ__Subscription__c s :lstsubs)
		{  mpsubs.put(s.id, s);  }
		
		String result;
		result = FinalizeAssetsContractLogic.UpdateExistingAssets(mpsubs, con);
		//system.debug('result line 160 is ' +result);
		List<Asset> lstchangedassets = New List<Asset>();
		lstchangedassets = [Select Id, status, quantity from Asset];
		for(Asset a : lstchangedassets)
		{
			system.assert(a.status == 'Cancelled');
		}
        
    }//end testUpdateAsset
    
    static testmethod void testContractAmendment()
    {
    	Account acct = CreateTestRecords.DefaultHospitalityAccount();
        Id rectypeid =Utilities.RecordTypeNameToId('Contract', 'Contract Amendment');
        Contract con = New Contract(recordtypeid = rectypeid, contract_status__c='Draft', accountid=acct.id,
                                   sbqq__renewalterm__c=1, renewal_cycle__c=30, company_code__c='01 Sonifi',
                                   contractterm=60, auto_renew__c=false);
        insert con;
        Product2 p1 = New Product2(Name='Interactive Product Parent', family='Interactive', productcode='CC-123-1234', isactive=true );
        Product2 p2 = New Product2(Name='STAY1000LX', productcode='CC-3030006', family='Interactive', isActive=true);
        Product2 p3 = New Product2(Name='System Information', productcode='CC-70000', isActive=true);
        Product2 p4 = New Product2(Name='Dashboard Monitor', productcode='CC-70101-0103', isActive=true);
        List<Product2> plist = New List<Product2>();
        plist.add(p1);
        plist.add(p2);
        plist.add(p3);
        plist.add(p4);
        insert plist;
        
        Marina_Service_Mod_Mapping__c marinamod = New Marina_Service_Mod_Mapping__c(Name='CC-70101-0103, 1156',
                                                  Description__c='Dashboard Monitor', Marina_Module_Description__c='Dashboard Monitor',
                                                  Marina_Service_Module__c='1156', Part_Number__c='CC-70101-0103');
        insert marinamod;
        
        SBQQ__Subscription__c subparent = New SBQQ__Subscription__c(Name__c = 'Interactive Product Parent', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p1.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id);
        insert subparent;
        SBQQ__Subscription__c sub1 = New SBQQ__Subscription__c(Name__c = 'STAY1000LX', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p2.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=subparent.id);
        insert sub1;
        
        SBQQ__Subscription__c sub2 = New SBQQ__Subscription__c(Name__c = 'System Information', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p3.id, 
                                          sbqq__quantity__c=100, status__c='Cancelled', sbqq__account__c=acct.id,
                                          parent__c=sub1.id);
        insert sub2;
        
        SBQQ__Subscription__c sub3 = New SBQQ__Subscription__c(Name__c = 'Dashboard Monitor', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p4.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=sub1.id);
        insert sub3;
        
        
        
        
        Asset a1 = New Asset(Name='Interactive Product Parent', subscription_item__c = subparent.id, contract__c = con.id, accountid=acct.id,
                             quantity=100, status='Pending Installation Activate');
        insert a1;
        subparent.product_inventory__c = a1.id;
        update subparent;
        
        Asset a2 = New Asset(Name='STAY1000LX', subscription_item__c = sub1.id, contract__c = con.id, accountid=acct.id,
                             quantity=100, status='Pending Installation Activate', parent_asset__c = a1.id);
        insert a2;
        sub1.product_inventory__c = a2.id;
        
        Asset a3 = New Asset(Name='System Information', subscription_item__c = sub2.id, contract__c = con.id, accountid=acct.id,
                             quantity=100, parent_asset__c=a2.id, status='Pending Installation Activate');
        insert a3;
        sub2.product_inventory__c = a3.id;
        
        List<SBQQ__Subscription__c> sublist = New List<SBQQ__Subscription__c>();
        sublist.add(sub1);
        sublist.add(sub2);
        update sublist;
        
        List<SBQQ__Subscription__c> lstsubs = New List<SBQQ__Subscription__c>();
        lstsubs = [Select Id, Name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, sbqq__contract__r.recordtype.name,
                    product_inventory__c, sbqq__product__r.family, sbqq__product__c, sbqq__product__r.name, marina_resource_ratio__c,
					sbqq__quantity__c, sbqq__regularprice__c, status__c, contract_type__c, product_parent_id__c, fee_schedule__c, platform__c,
					sbqq__account__c, sbqq__account__r.name, sbqq__product__r.productcode, parent__c, parent__r.sbqq__product__r.productcode,
					sbqq__startdate__c, sbqq__enddate__c, parent__r.sbqq__product__r.name, parent__r.product_inventory__c
					from SBQQ__Subscription__c where SBQQ__Contract__c = :con.id ];
					
		Map<Id, SBQQ__Subscription__c> testmap = New Map<Id, SBQQ__Subscription__c>();
		for(SBQQ__Subscription__c s : lstsubs)
		{  testmap.put(s.id, s);  }
		
		FinalizeAssetsContractLogic.UpdateExistingAssets(testmap,con);
		
		List<Asset> lstasset = New List<Asset>();
		lstasset = [ Select Name from Asset where name = 'Dashboard Monitor'];
		system.assert(lstasset.size() == 1);
		
		List<Marina_Module__c> lstmm = New List<Marina_Module__c>();
		lstmm = [select Id, name from marina_module__c];
		system.assert(lstmm.size() == 1);
		
    }//end testContractAmendment
    
    static testmethod void testExtendedWarranty()
    {
    	Account acct = CreateTestRecords.DefaultHospitalityAccount();
        Id rectypeid =Utilities.RecordTypeNameToId('Contract', 'Contract Amendment');
        Date startew = system.today().adddays(-1);
        Contract con = New Contract(recordtypeid = rectypeid, contract_status__c='Draft', accountid=acct.id,
                                   sbqq__renewalterm__c=1, renewal_cycle__c=30, company_code__c='01 Sonifi',
                                   contractterm=60, auto_renew__c=false, extended_warranty_start_date__c = startew);
        insert con;
        
        id conrectype = Utilities.RecordTypeNameToId('Contract', 'Contract');
        Date con1start = system.today().addmonths(-3);
        Date con1end = system.today().addmonths(57);
        Contract con1 = New Contract(recordtypeid = conrectype, contract_status__c='Activated', accountid=acct.id,
                                   sbqq__renewalterm__c=1, renewal_cycle__c=30, company_code__c='01 Sonifi',
                                   contractterm=60, auto_renew__c=false, startdate=con1start, enddate = con1end);
        insert con1;
        
        Product2 p1 = New Product2(Name='Interactive Product Parent', family='Interactive', productcode='CC-123-1234', isactive=true );
        insert p1;
        
        Product2 p2 = New Product2(Name='Extended Warranty', family='Warranty', productcode='CC-110057', isactive=true );
        insert p2;
        
        Product2 p3 = New Product2(Name='Service & Maintenance', family='Entitlement', productcode='CC-110031', isactive=true);
        insert p3;
        
        Product2 p4 = New Product2(Name='Some Warranty', family='Warranty', productcode='CC-warr-123', isactive=true);
        
		SBQQ__Subscription__c con1sub = New SBQQ__Subscription__c(Name__c = 'Interactive Product Parent', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con1.id, sbqq__product__c=p1.id, 
                                          sbqq__quantity__c=100, status__c='Installed Activated', sbqq__account__c=acct.id);
                                          
                                          
        
        SBQQ__Subscription__c subparent = New SBQQ__Subscription__c(Name__c = 'Interactive Product Parent', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p1.id, 
                                          sbqq__quantity__c=100, status__c='Installed Activated', sbqq__account__c=acct.id);
        insert subparent;
        
        
        Asset a1 = New Asset(Name='Interactive Product Parent', subscription_item__c = subparent.id, contract__c = con.id, accountid=acct.id,
                             quantity=100, status='Installed Activated');
        insert a1;
        
        subparent.product_inventory__c = a1.id;
        update subparent;
        
        SBQQ__Subscription__c subwarr = New SBQQ__Subscription__c(Name__c = 'Extended Warranty', project_type__c='New Rooms', parent__c=subparent.id,
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p2.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id);
        insert subwarr;
        
        SBQQ__Subscription__c oldwarr = New SBQQ__Subscription__c(Name__c = 'Some Warranty', project_type__c='New Rooms', parent__c=subparent.id,
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con1.id, sbqq__product__c=p2.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id);
        insert oldwarr;
        
        test.startTest();
                                          
        Date startent = system.today().addmonths(-3);
        Date endent = system.today().addmonths(6);
        system.debug('startent is ' +startent);
        system.debug('endent is ' +endent);
        
        Entitlement e = New Entitlement(Name='Service & Maintenance', accountid=acct.id, assetid=a1.id, subscription__c=con1sub.id,
                                        startdate=startent, enddate=endent);
        insert e;
        
        ServiceContract warr = New ServiceContract(Name='Some Warranty', accountid=acct.id, product_inventory__c=a1.id, startdate=startent,
                                  enddate=endent, subscription__c = oldwarr.id);
        insert warr;
        
        e.servicecontractid = warr.id;
        update e;
        
        List<SBQQ__Subscription__c> lstsubs = New List<SBQQ__Subscription__c>();
        lstsubs = [Select Id, Name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, sbqq__contract__r.recordtype.name,
                    product_inventory__c, sbqq__product__r.family, sbqq__product__c, sbqq__product__r.name, marina_resource_ratio__c,
					sbqq__quantity__c, sbqq__regularprice__c, status__c, contract_type__c, product_parent_id__c, fee_schedule__c, platform__c,
					sbqq__account__c, sbqq__account__r.name, sbqq__product__r.productcode, parent__c, parent__r.sbqq__product__r.productcode,
					sbqq__startdate__c, sbqq__enddate__c, parent__r.sbqq__product__r.name, parent__r.product_inventory__c
					from SBQQ__Subscription__c where SBQQ__Contract__c = :con.id];
					
	    for(SBQQ__Subscription__c s :lstsubs)
	    {
	    	system.debug('subscription name: ' +s.name__c +',' +s.parent__c +',' +s.sbqq__product__r.name);
	    }
        
        String result;
        result = FinalizeAssetsContractLogic.CreateExtendedWarrantyServiceContract(lstsubs, con);
        
        List<ServiceContract> lstsc = New List<ServiceContract>();
        lstsc = [Select Id, Name from ServiceContract where name = 'Extended Warranty'];
        system.assert(lstsc.size() == 1);
        
        test.stopTest();
        
    	
    }  //end testExtendedWarranty
}