@isTest
public with sharing class FieldWorkOrderTriggerLogicTest {
	
	static testmethod void PopulateWorkOrderExceptionsAndEvents()
	{
		system.debug('Begin Test PopulateWorkOrderExceptionsAndEvents');
		
		Account a = DataGenerator.createAccounts(1, true)[0];
		Account suppAcc = DataGenerator.createAccounts(1, true)[0];
		
		Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
		suppAcc.RecordTypeId = supportOfficeId;
		update suppAcc;
		a.Support_Office__c = suppAcc.Id;
		a.Service_Contract_Exceptions__c = 'Test Exception';
		update a;
		
		Case case1 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case1.AccountId = a.Id;
		case1.Support_Office__c = suppAcc.Id;
		case1.Dispatched__c = true;
		case1.Status='Open';
		case1.Subject = 'Test Subject';
		case1.Priority = 'Low';
		case1.Origin = 'Customer Incoming Call';
		case1.Customer_Name__c = 'Joe Blow';
		case1.Customer_Role__c = 'Engineering';
		case1.Case_Product_Type__c = 'Interactive';
		case1.Issue_Type__c = 'Mobile';
		case1.Issue_Sub_Type__c = 'Content';
		case1.Issue_Details__c = 'Multi Lingual';
		case1.Issue_Details_Description__c = 'Testing Description';
		upsert case1;
		
		Case suppcase = CreateTestRecords.DefaultSupportCase();
		Date start = system.today();
    	Date done = system.today().addmonths(3);
    	ServiceContract sc = New ServiceContract(Name='TestWarranty', accountid=suppcase.accountid,
    	                     startdate=start, enddate=done);
    	insert sc;
    	Entitlement ent = New Entitlement(Name = 'TestTPEntitlement', accountid = suppcase.accountid,
    	startdate=start, enddate=done, servicecontractid=sc.id);
    	insert ent;
    	suppcase.entitlementid = ent.id;
    	suppcase.service_contract_name__c = sc.id;
    	update suppcase;
    	
    	ThirdPartyEntitlementName__c setting = New ThirdPartyEntitlementName__c();
    	setting.Name='TestTPEntitlement';
    	setting.ThirdPartySiteId__c = '0099887';
    	insert setting;
	
		WorkOrder wo = New WorkOrder(Date__c = system.Now(), Accountid = a.id, caseid = case1.id, status='New', invoice_summary__c = 'Work Completed.',
	                             Signature_Name__c = 'Joan Jackson', Customer_Email__c = 'jjackson@sonifi.com', signature_date__c = system.Now(),
	                             submit_for_billing__c = false, customer_title__c = 'GM');
	    insert wo;
	    
	    WorkOrder fwo = New WorkOrder(Date__c = system.Now(), Accountid = suppcase.accountid, caseid = suppcase.id, status = 'New');
	    insert fwo;
    	
    	test.StartTest();
    	
    	WorkOrder getwo = [ Select Id, workordernumber, priority, case_issue_type__c, subject, service_contract_exceptions__c from
    	                    WorkOrder where id = :wo.id LIMIT 1 ];
    	                    
    	List<FieldWorkOrder_Events__c> listevents = New List<FieldWorkOrder_Events__c>();
    	listevents = [ Select Id, Field_Work_Order__c, event_name__c from FieldWorkOrder_Events__c where Field_Work_Order__c = :wo.id ];
    	
    	Id tpfwoid = Utilities.RecordTypeNameToId('WorkOrder', 'Third Party FWO');
    	system.debug('third party fwo rectypeid is ' +tpfwoid);
    	
    	WorkOrder newwo = [ Select Id, entitlementid, entitlement.name, servicecontractid, servicecontract.name, recordtypeid, caseid from WorkOrder where caseid = :suppcase.id LIMIT 1];
    	system.debug('newwo entitlement name is ' +newwo.entitlement.name);
    	system.debug('newwo service contract is ' +newwo.servicecontract.name);
    	system.debug('newwo recordtypeid is ' +newwo.recordtypeid);
    	
    	test.StopTest();
    	
    	system.assert(listevents.size() == 2);
    	system.assert(getwo.service_contract_exceptions__c == 'Test Exception');
    	system.debug(getwo.subject == 'Test Subject');
		
	}//end testPopulateWorkOrderExceptionsAndEvents
	
	static testmethod void testPopulateTech()
	{
		Account a = DataGenerator.createAccounts(1, true)[0];
		Account suppAcc = DataGenerator.createAccounts(1, true)[0];
		
		Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
		suppAcc.RecordTypeId = supportOfficeId;
		upsert suppAcc;
		a.Support_Office__c = suppAcc.Id;
		a.physical_country__c = 'USA';
		a.Service_Contract_Exceptions__c = 'Test Exception';
		upsert a;
		
		Case case1 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case1.AccountId = a.Id;
		case1.Support_Office__c = suppAcc.Id;
		case1.Dispatched__c = true;
		case1.Status='Open';
		case1.Subject = 'Test Subject';
		case1.Priority = 'Low';
		case1.Origin = 'Customer Incoming Call';
		case1.Customer_Name__c = 'Joe Blow';
		case1.Customer_Role__c = 'Engineering';
		case1.Case_Product_Type__c = 'Interactive';
		case1.Issue_Type__c = 'Mobile';
		case1.Issue_Sub_Type__c = 'Content';
		case1.Issue_Details__c = 'Multi Lingual';
		case1.Issue_Details_Description__c = 'Testing Description';
		upsert case1;
	
		WorkOrder wo = New WorkOrder(Date__c = system.Now(), Accountid = a.id, caseid = case1.id, status='New', invoice_summary__c = 'Work Completed.',
	                             Signature_Name__c = 'Joan Jackson', Customer_Email__c = 'jjackson@sonifi.com', signature_date__c = system.Now(),
	                             submit_for_billing__c = false, customer_title__c = 'GM');
    	insert wo;
    	
    	test.StartTest();
    	
    	wo.submit_for_billing__c = true;
    	update wo;
    	
    	WorkOrder getwo = [ Select Id, workordernumber, priority, case_issue_type__c, subject, service_contract_exceptions__c, ownerid,
    	                    submit_for_billing__c, technician__c from
    	                    WorkOrder where id = :wo.id LIMIT 1 ];
    	                    
    	List<FieldWorkOrder_Events__c> listfwoe = [ Select Id, event_type__c, field_work_order__c, event_name__c from
    	                                           FieldWorkOrder_Events__c where field_work_order__c = :getwo.id ];
    	
    	test.StopTest();
    	
    	system.assert(getwo.technician__c != null);
    	system.assert(listfwoe.size() > 0 );
    	
	}//end testPopulateTech
	
	//Note:  There is no separate test method for the approval process because when the submit for billing box is checked on
	//these work orders, that code runs and is covered.
	static testmethod void testTripAndLabor()
	{
		Account a = DataGenerator.createAccounts(1, true)[0];
		Account suppAcc = DataGenerator.createAccounts(1, true)[0];
		Account hca = DataGenerator.createAccounts(1, true)[0];
		Account thirdpartyacc = DataGenerator.CreateAccounts(1,true)[0];
		Account partner = DataGenerator.CreateAccounts(1,true)[0];
		
		Id hcrectype = Utilities.RecordTypeNameToId('Account', 'Healthcare Site');
		Id tpcontracted = Utilities.RecordTypeNameToId('Account', 'Third Party Contracted Service');
		Id tppartner = Utilities.RecordTypeNametoId('Account', 'Third Party');
		Id cfscaseid = Utilities.RecordTypeNametoId('Case', 'Contracted Field Service');
		
		
		Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
		suppAcc.RecordTypeId = supportOfficeId;
		upsert suppAcc;
		a.Support_Office__c = suppAcc.Id;
		a.Service_Contract_Exceptions__c = 'Test Exception';
		a.physical_state__c = 'SD';
		upsert a;
		hca.recordtypeid = hcrectype;
		hca.physical_state__c = 'SD';
		hca.support_office__c = suppAcc.Id;
		upsert hca;
		partner.recordtypeid = tppartner;
		upsert partner;
		thirdpartyacc.recordtypeid = tpcontracted;
		upsert thirdpartyacc;
		
		Account_Third_Party_Partner__c atpp = New Account_Third_Party_Partner__c(Related_Account__c = thirdpartyacc.id, 
		                                          Third_Party_Partner_Account__c = partner.id);
		insert atpp;
		
		
		
		
		Asset a1 = New Asset(accountid = a.id, Name = 'Interactive Product Parent', status = 'Installed Activated', quantity = 100);
		Asset a2 = New Asset(accountid = hca.id, Name = 'FTG Product Parent', status = 'Installed Activated', quantity = 100);
		List<Asset> lstasset = New List<Asset>();
		lstasset.add(a1);
		lstasset.add(a2);
		insert lstasset;
		
		Product2 p1 = New Product2(productcode = '40-0001-058-0', Name = 'LABOR, FS, HEALTHCARE', IsActive = true);
		Product2 p2 = New Product2(productcode = '40-0001-057-0', Name = 'TRIP CHARGE, FS, HEALTHCARE', IsActive = true);
		Product2 p3 = New Product2(productcode = '40-0001-009-0', Name = 'LABOR, FS, iTV/FTG', IsActive = true);
		Product2 p4 = New Product2(productcode = '40-0001-036-0', Name = 'TRIP CHARGE, FS, iTV/FTG', IsActive = true);
		Product2 p5 = New Product2(productcode = '40-0001-132-0', Name = 'LABOR, ITV NON-CHARGEABLE', IsActive = true);
		Product2 p6 = New Product2(productcode = '40-0001-133-0', Name = 'LABOR, HEALTHCARE NON-CHARGEABLE', IsActive = true);
		Product2 p7 = New Product2(productcode = '40-0001-142-0', Name = 'LABOR, THIRD PARTY', IsActive = true);
		Product2 p8 = New Product2(productcode = '40-0001-143-0', Name = 'TRIP, THIRD PARTY', IsActive = true);
		
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
		
		Case case1 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case1.AccountId = a.Id;
		case1.Support_Office__c = suppAcc.Id;
		case1.Dispatched__c = true;
		case1.Status='Open';
		case1.Subject = 'Test Subject';
		case1.Priority = 'Low';
		case1.Origin = 'Customer Incoming Call';
		case1.Case_Product_Type__c = 'Interactive';
		case1.Customer_Name__c = 'Joe Blow';
		case1.Customer_Role__c = 'Engineering';
		case1.Issue_Type__c = 'Mobile';
		case1.Issue_Sub_Type__c = 'Content';
		case1.Issue_Details__c = 'Multi Lingual';
		case1.Issue_Details_Description__c = 'Testing Description';
		case1.Assetid = a1.id;
		upsert case1;
		
		Case case2 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case2.AccountId = hca.Id;
		case2.Support_Office__c = suppAcc.Id;
		case2.Dispatched__c = true;
		case2.Status='Open';
		case2.Subject = 'Test Healthcare Subject';
		case2.Priority = 'Low';
		case2.Origin = 'Customer Incoming Call';
		case2.Customer_Name__c = 'Joe Blow';
		case2.Customer_Role__c = 'Engineering';
		case2.Case_Product_Type__c = 'FTG';
		case2.Issue_Type__c = 'Hardware - FTG';
		case2.Issue_Sub_Type__c = 'Rack - FTG';
		case2.Issue_Details__c = 'Combiner';
		case2.Issue_Details_Description__c = 'Testing HC Description';
		case2.Assetid = a2.id;
		upsert case2;
		
		Case case3 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case3.AccountId = a.Id;
		case3.Support_Office__c = suppAcc.Id;
		case3.Dispatched__c = true;
		case3.Status='Open';
		case3.Subject = 'Test Not Contracted Subject';
		case3.Priority = 'Low';
		case3.Origin = 'Customer Incoming Call';
		case3.Case_Product_Type__c = 'FTG';
		case3.Customer_Name__c = 'Joe Blow';
		case3.Customer_Role__c = 'Engineering';
		case3.Issue_Type__c = 'Hardware - FTG';
		case3.Issue_Sub_Type__c = 'Rack - FTG';
		case3.Issue_Details__c = 'Combiner';
		case3.Issue_Details_Description__c = 'Testing Non-Contracted Description';
		upsert case3;
		
		Case case4 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case4.AccountId = thirdpartyacc.id;
		case4.Dispatched__c = false;
		case4.Status = 'Open';
		case4.Subject = 'Test Contracted Field Service Case';
		case4.recordtypeid = cfscaseid;
		case4.priority = 'Low';
		case4.origin = 'Third Party Field Service';
		case4.case_product_type__c = 'Interactive';
		case4.issue_type__c = 'Hardware';
		case4.issue_sub_type__c = 'DCR/Catcher';
		case4.issue_details__c = 'Bad LNB DCR/Catcher';
		case4.third_party_partner__c = atpp.id;
		case4.partner_ticket_number__c = '12344556';
		upsert case4;
		
		
		
	
		WorkOrder wo1 = New WorkOrder(Date__c = system.Now(), Accountid = a.id, caseid = case1.id, status='New', invoice_summary__c = 'Work Completed.',
	                             Signature_Name__c = 'Joan Jackson', Customer_Email__c = 'jjackson@sonifi.com', signature_date__c = system.Now(),
	                             submit_for_billing__c = false, customer_title__c = 'GM');
 
    	WorkOrder wo2 = New WorkOrder(Date__c = system.Now(), Accountid = hca.id, caseid = case2.id, status='New', invoice_summary__c = 'Healthcare Work Completed.',
	                             Signature_Name__c = 'Joan Jackson', Customer_Email__c = 'jjackson@sonifi.com', signature_date__c = system.Now(),
	                             submit_for_billing__c = false, customer_title__c = 'GM');
	
		WorkOrder wo3 = New WorkOrder(Date__c = system.Now(), Accountid = a.id, caseid = case3.id, status='New', invoice_summary__c = 'NonContracted Work Completed.',
	                             Signature_Name__c = 'Joan Jackson', Customer_Email__c = 'jjackson@sonifi.com', signature_date__c = system.Now(),
	                             submit_for_billing__c = false, customer_title__c = 'GM');
	                             
	    WorkOrder wo4 = New WorkOrder(Date__c = system.Now(), Accountid = thirdpartyacc.id, caseid = case4.id, status='New', invoice_summary__c = 'Contracted Field Service Work.',
	                             Signature_Name__c = 'Joan Jackson', Customer_Email__c = 'jjackson@sonifi.com', signature_date__c = system.Now(),
	                             submit_for_billing__c = false, customer_title__c = 'GM');
	
	
    	List<WorkOrder> lstwo = New List<WorkOrder>();
    	lstwo.add(wo1);
    	lstwo.add(wo2);
    	lstwo.add(wo3);
    	lstwo.add(wo4);
    	insert lstwo;
    	
    	test.StartTest();
    	List<WorkOrder> wolist = [Select Id, workordernumber, submit_for_billing__c, case_product_type__c from WorkOrder ];
    	List<WorkOrder> updwo = New List<WorkOrder>();
    	
    	for(WorkOrder wo : wolist)
    	{
    		wo.submit_for_billing__c = true;
    		updwo.add(wo);
    	}
    	
    	update updwo;
    	
    	List<WorkOrderLineItem> lstlines = New List<WorkOrderLineItem>();
    	lstlines = [Select Id, qty__c, product_code__c, part_number__c, workorderid from WorkOrderLineItem where workorderid in :wolist ];
    	test.StopTest();
    	
    	system.debug('lstlines size is ' +lstlines.size());
    	//system.assert(lstlines.size() == 9);
    	
    	
	}
	
	
	
    
}//end FieldWorkOrderTriggerLogicTest