@isTest
public with sharing class FieldWOLineItemTrigLogicTest {
    
    static testmethod void testPopulateNetSuiteLocation()
    {
    	Account a = DataGenerator.createAccounts(1, true)[0];
    	Account acan = DataGenerator.createAccounts(1, true)[0];
		Account suppAcc = DataGenerator.createAccounts(1, true)[0];
		Account hca = DataGenerator.createAccounts(1, true)[0];
		
		Id hosrectype = Utilities.RecordTypeNameToId('Account', 'Hospitality Site');
		system.debug('hosrectype = ' +hosrectype);
		Id hcrectype = Utilities.RecordTypeNameToId('Account', 'Healthcare Site');
		system.debug('hcrectype = ' +hcrectype);
		
		Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
		suppAcc.RecordTypeId = supportOfficeId;
		upsert suppAcc;
		a.Support_Office__c = suppAcc.Id;
		a.Service_Contract_Exceptions__c = 'Test Exception';
		a.physical_state__c = 'SD';
		a.physical_country__c = 'USA';
		a.recordtypeid = hosrectype;
		upsert a;
		
		acan.support_office__c = suppAcc.Id;
		acan.physical_state__c = 'ON';
		acan.physical_country__c = 'Canada';
		acan.recordtypeid = hosrectype;
		upsert acan;
		
		hca.recordtypeid = hcrectype;
		hca.physical_state__c = 'SD';
		hca.physical_country__c = 'USA';
		upsert hca;
		
		Account apr = DataGenerator.createAccounts(1, true)[0];
		apr.physical_state__c = 'PR';
		apr.physical_country__c = 'USA';
		apr.support_office__c = suppAcc.Id;
		apr.recordtypeid = hosrectype;
		upsert apr;
		
		Asset a1 = New Asset(accountid = a.id, Name = 'Interactive Product Parent', status = 'Installed Activated', quantity = 100);
		Asset a2 = New Asset(accountid = hca.id, Name = 'FTG Product Parent', status = 'Installed Activated', quantity = 100);
		Asset a3 = New Asset(accountid = apr.id, Name = 'Interactive Product Parent', status = 'Installed Activated', quantity = 100);
		Asset a4 = New Asset(accountid = acan.id, Name = 'Interactive Product Parent', status = 'Installed Activated', quantity = 100);
		List<Asset> lstasset = New List<Asset>();
		lstasset.add(a1);
		lstasset.add(a2);
		lstasset.add(a3);
		lstasset.add(a4);
		insert lstasset;
		
		Product2 p1 = New Product2(productcode = '40-0001-058-0', Name = 'LABOR, FS, HEALTHCARE', IsActive = true);
		Product2 p2 = New Product2(productcode = '40-0001-057-0', Name = 'TRIP CHARGE, FS, HEALTHCARE', IsActive = true);
		Product2 p3 = New Product2(productcode = '40-0001-009-0', Name = 'LABOR, FS, iTV/FTG', IsActive = true);
		Product2 p4 = New Product2(productcode = '40-0001-036-0', Name = 'TRIP CHARGE, FS, iTV/FTG', IsActive = true);
		Product2 p5 = New Product2(productcode = '40-0001-132-0', Name = 'LABOR, NON-CHARGEABLE', IsActive = true);
		Product2 p6 = New Product2(productcode = '40-0026-022-0', Name = 'FAN, 40MM, ASSY', IsActive = true);
		Product2 p7 = New Product2(productcode = '40-0030-001-0', Name = 'COMPUTER, CGC, 10R128FD40E', IsActive = true);
		Product2 p8 = New Product2(productcode = '40-0001-133-0', Name = 'LABOR, Healthcare Non-Chargeable', IsActive = true);
		List<Product2> newpartslist = New List<Product2>();
		newpartslist.add(p1);
		newpartslist.add(p2);
		newpartslist.add(p3);
		newpartslist.add(p4);
		newpartslist.add(p5);
		newpartslist.add(p6);
		newpartslist.add(p7);
		newpartslist.add(p8);
		
		insert newpartslist;
		
		Id screctype = Utilities.RecordTypeNameToId('Case', 'Support Case');
		
		Case case1 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case1.AccountId = a.Id;
		case1.Support_Office__c = suppAcc.Id;
		case1.Dispatched__c = true;
		case1.Status='Open';
		case1.Subject = 'Test Subject';
		case1.Priority = 'Low';
		case1.Origin = 'Customer Incoming Call';
		case1.Case_Product_Type__c = 'Interactive';
		case1.Issue_Type__c = 'Mobile';
		case1.Issue_Sub_Type__c = 'Content';
		case1.Issue_Details__c = 'Multi Lingual';
		case1.Issue_Details_Description__c = 'Testing Description';
		case1.Assetid = a1.id;
		case1.recordtypeid = screctype;
		upsert case1;
		
		Case case2 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case2.AccountId = hca.Id;
		case2.Support_Office__c = suppAcc.Id;
		case2.Dispatched__c = true;
		case2.Status='Open';
		case2.Subject = 'Test Healthcare Subject';
		case2.Priority = 'Low';
		case2.Origin = 'Customer Incoming Call';
		case2.Case_Product_Type__c = 'FTG';
		case2.Issue_Type__c = 'Hardware - FTG';
		case2.Issue_Sub_Type__c = 'Rack - FTG';
		case2.Issue_Details__c = 'Combiner';
		case2.Issue_Details_Description__c = 'Testing HC Description';
		case2.Assetid = a2.id;
		case2.recordtypeid = screctype;
		upsert case2;
		
		Case case3 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case3.AccountId = apr.Id;
		case3.Support_Office__c = suppAcc.Id;
		case3.Dispatched__c = true;
		case3.Status='Open';
		case3.Subject = 'Test Subject';
		case3.Priority = 'Low';
		case3.Origin = 'Customer Incoming Call';
		case3.Case_Product_Type__c = 'Interactive';
		case3.Issue_Type__c = 'Mobile';
		case3.Issue_Sub_Type__c = 'Content';
		case3.Issue_Details__c = 'Multi Lingual';
		case3.Issue_Details_Description__c = 'Testing Description';
		case3.Assetid = a3.id;
		case3.recordtypeid = screctype;
		upsert case3;
		
		Case case4 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case4.AccountId = acan.Id;
		case4.Support_Office__c = suppAcc.Id;
		case4.Dispatched__c = true;
		case4.Status='Open';
		case4.Subject = 'Test Subject';
		case4.Priority = 'Low';
		case4.Origin = 'Customer Incoming Call';
		case4.Case_Product_Type__c = 'Interactive';
		case4.Issue_Type__c = 'Mobile';
		case4.Issue_Sub_Type__c = 'Content';
		case4.Issue_Details__c = 'Multi Lingual';
		case4.Issue_Details_Description__c = 'Testing Description';
		case4.Assetid = a4.id;
		case4.recordtypeid = screctype;
		upsert case4;
		
		Id worectype = Utilities.RecordTypeNameToId('WorkOrder', 'FWO');
		system.debug('worectype = ' +worectype);
	
		WorkOrder wo1 = New WorkOrder(Date__c = system.Now(), Accountid = a.id, caseid = case1.id, status='New', invoice_summary__c = 'Work Completed.',
	                             Signature_Name__c = 'Joan Jackson', Customer_Email__c = 'jjackson@sonifi.com', signature_date__c = system.Now(),
	                             submit_for_billing__c = false, customer_title__c = 'GM', recordtypeid = worectype);
 
    	WorkOrder wo2 = New WorkOrder(Date__c = system.Now(), Accountid = hca.id, caseid = case2.id, status='New', invoice_summary__c = 'Healthcare Work Completed.',
	                             Signature_Name__c = 'Joan Jackson', Customer_Email__c = 'jjackson@sonifi.com', signature_date__c = system.Now(),
	                             submit_for_billing__c = false, customer_title__c = 'GM', recordtypeid = worectype);
	                             
	    WorkOrder wo3 = New WorkOrder(Date__c = system.Now(), Accountid = apr.id, caseid = case3.id, status='New', invoice_summary__c = 'Test Puerto Rico site.',
	                             Signature_Name__c = 'Joan Jackson', Customer_Email__c = 'jjackson@sonifi.com', signature_date__c = system.Now(),
	                             submit_for_billing__c = false, customer_title__c = 'GM', recordtypeid = worectype);
	                             
	    WorkOrder wo4 = New WorkOrder(Date__c = system.Now(), Accountid = acan.id, caseid = case4.id, status='New', invoice_summary__c = 'Test Canadian site.',
	                             Signature_Name__c = 'Joan Jackson', Customer_Email__c = 'jjackson@sonifi.com', signature_date__c = system.Now(),
	                             submit_for_billing__c = false, customer_title__c = 'GM', recordtypeid=worectype);                         
	
    	List<WorkOrder> lstwo = New List<WorkOrder>();
    	lstwo.add(wo1);
    	lstwo.add(wo2);
    	lstwo.add(wo3);
    	lstwo.add(wo4);
    	insert lstwo;
    	
    	test.StartTest();
    	
    	List<WorkOrderLineItem> lstnewwoli = New List<WorkOrderLineItem>();
    	WorkOrderLineItem line1 = New WorkOrderLineItem(part_number__c = p6.id, qty__c = 1, workorderid = wo1.id);
    	WorkOrderLineItem line2 = New WorkOrderLineItem(part_number__c = p7.id, qty__c = 1, workorderid = wo2.id);
    	lstnewwoli.add(line1);
    	lstnewwoli.add(line2);
    	insert lstnewwoli;
    	
    	List<WorkOrder> wolist = [Select Id, workordernumber, submit_for_billing__c, case_product_type__c from WorkOrder ];
    	List<WorkOrder> updwo = New List<WorkOrder>();
    	
    	for(WorkOrder wo : wolist)
    	{
    		wo.submit_for_billing__c = true;
    		updwo.add(wo);
    	}
    	
    	update updwo;
    	
    	List<WorkOrderLineItem> lstlines = New List<WorkOrderLineItem>();
    	lstlines = [Select Id, qty__c, product_code__c, part_number__c, workorderid, billing_producttype__c, part_number__r.name,
    	            order_type__c, netsuite_location__c, workorder.account_country__c from WorkOrderLineItem where workorderid in :wolist ];
    	test.StopTest();
    	
    	system.debug('from workorderlineitem test lstlines size is ' +lstlines.size());
    	
    	for(WorkOrderLineItem woli : lstlines)
    	{
    		if(woli.product_code__c == '40-0026-022-0' && woli.workorder.account_country__c == 'USA')
    		{
    			system.assert(woli.netsuite_location__c == 'FBL');
    			system.assert(woli.billing_producttype__c == 'ITV');
    			system.assert(woli.order_type__c == 'Field Service Sales');
    		}
    		
    		if(woli.product_code__c == '40-0001-058-0' && woli.workorder.account_country__c == 'USA')
    		{
    			system.assert(woli.netsuite_location__c == 'Healthcare');
    			system.assert(woli.billing_producttype__c == 'HC');
    			system.assert(woli.order_type__c == 'Healthcare Sales');
    		}
    		
    		if(woli.product_code__c == '40-0001-009-0' && woli.workorder.account_country__c == 'Canada')
    		{
    			system.assert(woli.netsuite_location__c == 'FIN GOOD');
    			
    		}
    		
    		if(!woli.part_number__r.name.contains('TRIP') && !woli.part_number__r.name.contains('LABOR') && woli.workorder.account_country__c == 'Canada')
    		{
    			system.assert(woli.netsuite_location__c == 'FIN GOOD');
    		}
    		
    	}
    }
}