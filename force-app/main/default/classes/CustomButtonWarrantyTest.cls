@isTest
private class CustomButtonWarrantyTest {
    
    static testmethod void TestCreateWarrantyandExtension()
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
        
        Asset parentpi = New Asset(Name='Interactive Product Parent', accountid=acct.id, contract__c=con.id, subscription_Item__c=subparent.id,
                                   product2id=p1.id, status='Pending Installation Activate', quantity=100);
        insert parentpi;
        
        subparent.Product_Inventory__c=parentpi.Id;
        update subparent;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(con);
   		CustomButtonWarrantyExtension testbutton = New CustomButtonWarrantyExtension(sc);
   		PageReference pageRef = Page.CustomButtonWarrantyEntitlement;
   		pageRef.getParameters().put('Id', String.valueOf(con.id));
   		Test.setCurrentPage(pageRef);
   		testbutton.CreateUpdateWarrantyEntitle();
        
        List<Entitlement> lstent = New List<Entitlement>();
        List<ServiceContract> lstwarr = New List<ServiceContract>();
        lstwarr=[Select name, id from ServiceContract];
        lstent = [Select Id, Name from Entitlement ];
        system.assert(lstent.size() == 1);
        system.assert(lstwarr.size() == 1);
        
         
    }//end test method 

}//end test class