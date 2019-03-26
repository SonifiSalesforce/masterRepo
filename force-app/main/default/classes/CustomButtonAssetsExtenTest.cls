@isTest
private class CustomButtonAssetsExtenTest {

    static testmethod void testFinalizeContractCreateAssets()
    {
        Account acct = CreateTestRecords.DefaultHospitalityAccount();
        Id rectypeid =Utilities.RecordTypeNameToId('Contract', 'Contract');
        Contract con = New Contract(recordtypeid = rectypeid, Contract_status__c='Draft', accountid=acct.id,
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
        
        Marina_Service_Mod_Mapping__c marinamod = New Marina_Service_Mod_Mapping__c(Name='CC-70101-0103, 1156',
                                                  Description__c='Dashboard Monitor', Marina_Module_Description__c='Dashboard Monitor',
                                                  Marina_Service_Module__c='1156', Part_Number__c='CC-70101-0103');
        insert marinamod;
        

       ApexPages.StandardController sc = new ApexPages.StandardController(con);
       CustomButtonAssetsExtension testbutton = New CustomButtonAssetsExtension(sc);
       PageReference pageRef = Page.CustomButtonCreateUpdateAssets;
       pageRef.getParameters().put('Id', String.valueOf(con.id));
       Test.setCurrentPage(pageRef);
       testbutton.CreateUpdateAssets();
        
       List<Asset>lstassets = new List<Asset>();
       lstassets=[Select Id, Name from Asset];
       system.assert(lstassets.size() == 4);
       
    }
    
    static testmethod void testCreateExtendedWarranty()
    {
        Account acct = CreateTestRecords.DefaultHospitalityAccount();
        Id rectypeid =Utilities.RecordTypeNameToId('Contract', 'Contract Amendment');
        Date ewstart = system.today().addmonths(1);
        Contract con = New Contract(recordtypeid = rectypeid, Contract_status__c='Draft', accountid=acct.id,
                                   sbqq__renewalterm__c=1, renewal_cycle__c=30, company_code__c='01 Sonifi', initial_term__c = 12,
                                   contractterm=12, auto_renew__c=false, extended_warranty_start_date__c=ewstart);
        insert con;
        Product2 p1 = New Product2(Name='Interactive Product Parent', family='Interactive', productcode='CC-123-1234', isactive=true );
  		Product2 p2 = New Product2(Name='Extended Warranty Stay1000', Family='Warranty', productCode='CC-110057',
                                   isActive = true);
        List<Product2> plist = New List<Product2>();
        plist.add(p1);
        plist.add(p2);
        insert plist;
        
        SBQQ__Subscription__c subparent = New SBQQ__Subscription__c(Name__c = 'Interactive Product Parent', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p1.id, 
                                          sbqq__quantity__c=100, status__c='Installed Activated', sbqq__account__c=acct.id);
        insert subparent;
        SBQQ__Subscription__c sub1 = New SBQQ__Subscription__c(Name__c = 'Extended Warranty Stay1000', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p2.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=subparent.id);
        insert sub1;
        
        Asset a1 = New Asset(Name='Interactive Product Parent', Accountid = acct.id, product2id=p1.id, subscription_item__c=subparent.id, status='Installed Activated',
                             quantity=100, contract__c = con.id);
        insert a1;
        
        subparent.product_inventory__c = a1.id;
        update subparent;
        
        Date startent = system.today().addmonths(-2);
        Date endent = system.today().addmonths(6);
        system.debug('startent is ' +startent);
        system.debug('endent is ' +endent);
        
        Entitlement e = New Entitlement(Name='Interactive Entitlement', accountid=acct.id, assetid=a1.id, subscription__c=subparent.id,
                                        startdate=startent, enddate=endent);
        insert e;
        
        ServiceContract warr = New ServiceContract(Name='Interactive Warranty', accountid=acct.id, product_inventory__c=a1.id, startdate=startent,
                                  enddate=endent);
        insert warr;
        
        e.servicecontractid = warr.id;
        update e;
        
       ApexPages.StandardController sc = new ApexPages.StandardController(con);
       CustomButtonAssetsExtension testbutton = New CustomButtonAssetsExtension(sc);
       PageReference pageRef = Page.CustomButtonCreateUpdateAssets;
       pageRef.getParameters().put('Id', String.valueOf(con.id));
       Test.setCurrentPage(pageRef);
       testbutton.CreateUpdateAssets();
    } 
}