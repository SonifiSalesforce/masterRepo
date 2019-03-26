@isTest
private class FinalizeWarrantyEntitlementLogicTest {

    static testmethod void testFinalizeNewWarranty()
    {
        Account acct = CreateTestRecords.DefaultHospitalityAccount();
        Id rectypeid =Utilities.RecordTypeNameToId('Contract', 'Contract');
        Contract con = New Contract(recordtypeid = rectypeid, contract_status__c ='Draft', accountid=acct.id);
        insert con;
        Product2 p1 = New Product2(Name='Interactive Product Parent', family='Interactive', productcode='CC-123-1234', isactive=true );
        Product2 p2 = New Product2(Name='Interactive Entitlement', family = 'Entitlement', productcode='CC-ent-123', isactive=true);
        Product2 p3 = New Product2(Name='Interactive Warranty', family='Warranty', productcode='CC-warr-123', isactive=true);
        List<Product2> plist = New List<Product2>();
        plist.add(p1);
        plist.add(p2);
        plist.add(p3);
        insert plist;
        SBQQ__Subscription__c subparent = New SBQQ__Subscription__c(Name__c = 'Interactive Product Parent', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p1.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id);
        insert subparent;
        SBQQ__Subscription__c subent = New SBQQ__Subscription__c(Name__c = 'Interactive Entitlement', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p2.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=subparent.id);
        SBQQ__Subscription__c subwarr = New SBQQ__Subscription__c(Name__c = 'Interactive Warranty', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p3.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=subparent.id);
        List<SBQQ__Subscription__c> sublist = New List<SBQQ__Subscription__c>();
        sublist.add(subent);
        sublist.add(subwarr);
        insert sublist;
        
        Asset parentpi = New Asset(Name='Interactive Product Parent', accountid=acct.id, contract__c=con.id, subscription_item__c=subparent.id,
                                   product2id=p1.id, status='Pending Installation Activate', quantity=100);
        insert parentpi;
        
        subparent.Product_Inventory__c=parentpi.Id;
        update subparent;
        
        List<SBQQ__Subscription__c> lstallsubs = New List<SBQQ__Subscription__c>();
        lstallsubs=[Select Id, name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, product_inventory__c, product_parent_id__c,
                    sbqq__product__c, sbqq__product__r.name, sbqq__product__r.family, sbqq__quantity__c, status__c, sbqq__account__c from 
                    sbqq__subscription__c ];
        
        String result;
        result = FinalizeWarrantyEntitlementContractLogic.WarrantyandEntitlementProcess(lstallsubs);
        system.debug('result is ' +result);
    }
    
    static testmethod void testExistingWarrantyEntitlement()
    {
        Account acct = CreateTestRecords.DefaultHospitalityAccount();
        Id rectypeid =Utilities.RecordTypeNameToId('Contract', 'Contract');
        Contract con = New Contract(recordtypeid = rectypeid, contract_status__c ='Draft', accountid=acct.id);
        insert con;
        Product2 p1 = New Product2(Name='Interactive Product Parent', family='Interactive', productcode='CC-123-1234', isactive=true );
        Product2 p2 = New Product2(Name='Interactive Entitlement', family = 'Entitlement', productcode='CC-ent-123', isactive=true);
        Product2 p3 = New Product2(Name='Interactive Warranty', family='Warranty', productcode='CC-warr-123', isactive=true);
        List<Product2> plist = New List<Product2>();
        plist.add(p1);
        plist.add(p2);
        plist.add(p3);
        insert plist;
        SBQQ__Subscription__c subparent = New SBQQ__Subscription__c(Name__c = 'Interactive Product Parent', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p1.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id);
        insert subparent;
        SBQQ__Subscription__c subent = New SBQQ__Subscription__c(Name__c = 'Interactive Entitlement', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p2.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=subparent.id);
        SBQQ__Subscription__c subwarr = New SBQQ__Subscription__c(Name__c = 'Interactive Warranty', project_type__c='New Rooms',
                                          equipment_ownership__c = 'CUST', sbqq__contract__c=con.id, sbqq__product__c=p3.id, 
                                          sbqq__quantity__c=100, status__c='Pending Installation Activate', sbqq__account__c=acct.id,
                                          parent__c=subparent.id);
        List<SBQQ__Subscription__c> sublist = New List<SBQQ__Subscription__c>();
        sublist.add(subent);
        sublist.add(subwarr);
        insert sublist;
        
        Asset parentpi = New Asset(Name='Interactive Product Parent', accountid=acct.id, contract__c=con.id, subscription_item__c=subparent.id,
                                   product2id=p1.id, status='Pending Installation Activate', quantity=100);
        insert parentpi;
        
        subparent.Product_Inventory__c=parentpi.Id;
        update subparent;
        
        List<SBQQ__Subscription__c> lstallsubs = New List<SBQQ__Subscription__c>();
        lstallsubs=[Select Id, name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, product_inventory__c, product_parent_id__c,
                    sbqq__product__c, sbqq__product__r.name, sbqq__product__r.family, sbqq__quantity__c, status__c, sbqq__account__c from 
                    sbqq__subscription__c ];
        
        ServiceContract sc = New ServiceContract(Name='Interactive Warranty', product_inventory__c = parentpi.id, subscription__c=subwarr.id, accountid=acct.id);
        Entitlement entrec = New Entitlement(Name = 'Interactive Entitlement', assetid = parentpi.id, 
                                             subscription__c=subparent.id, servicecontractid = sc.id, accountid=acct.id);
        insert sc;
        insert entrec;
        
        
        String result;
        result = FinalizeWarrantyEntitlementContractLogic.WarrantyandEntitlementProcess(lstallsubs);
        system.debug('result is ' +result);
    }    
}