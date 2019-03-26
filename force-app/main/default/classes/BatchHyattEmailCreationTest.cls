@isTest
public without sharing class BatchHyattEmailCreationTest {
	
	static testmethod void testBatchHyattEmailSchedule()
	{
		//NOTE:  This code tests the batch schedule class, not the batch email creation class
		
	    Account acc = DataGenerator.createAccounts(1, true)[0];
		Account supacc = DataGenerator.createAccounts(1, true)[0];
		Id Rectypeid = Utilities.RecordTypeNameToId('Account', 'Support Office');
		supacc.recordtypeid = rectypeid;
		supacc.name = 'Test Support Office';
		update supacc;
		
		acc.Support_Office__c = supacc.id;
		acc.GIA_Support_Phone_Number__c = '(605) 445-1234';
		acc.Support_Number_Interactive__c = '(605) 445-5678';
		update acc;
		
		Asset bbasset = New Asset(Name = 'Broadband Product Parent', AccountId = acc.Id, Contract_Type__c = 'Interactive;Broadband',
		                                  Quantity = 100, Status = 'Installed Activated' );
		Asset intasset = New Asset(Name = 'Interactive Product Parent', AccountId = acc.Id, Contract_Type__c = 'Interactive;Broadband',
		                                  Quantity = 100, Status = 'Installed Activated' );
		List<Asset> assetlst = New List<Asset>();
		assetlst.add(bbasset);
		assetlst.add(intasset);
		insert assetlst;
		
		Date start = system.today();
		Date endday = system.today().addmonths(12);
		
		Entitlement bbent = New Entitlement(Name = 'Hyatt Stay1000 Entitlement', Accountid = acc.id, Assetid = bbasset.id, 
		                                    startdate = start, enddate = endday );
		Entitlement intent = New Entitlement(Name = 'Hyatt Stay1000 Entitlement', Accountid = acc.id, Assetid = intasset.id, 
		                                    startdate = start, enddate = endday );
		List<Entitlement> entlist = New List<Entitlement>();
		entlist.add(bbent);
		entlist.add(intent);
		insert entlist;
		
		Id suppcaseid = Utilities.RecordTypeNameToId('Case', 'Support Case');
		
		Case bbcase = New Case(Subject = 'Test Broadband Case', AccountId = acc.id, Status = 'Open', Priority = 'Critical',
		                      Origin = 'Customer Incoming Call', assetid = bbasset.id, Case_Product_Type__c = 'Broadband',
		                      Issue_Type__c = 'Software - GIA', Issue_Sub_Type__c = 'Gateway - Nomadix - GIA',
		                      Issue_Details__c = 'Rebooted Server', Issue_Details_Description__c = 'Testing 1234',
		                      Customer_Role__c = 'Front Desk', Customer_Email__c = 'joeblow@hotmail.com', entitlementid = bbent.id,
		                      recordtypeid = suppcaseid );
		                      
		Case intcase = New Case(Subject = 'Test Interactive Case', AccountId = acc.id, Status = 'Open', Priority = 'High',
		                      Origin = 'Customer Incoming Call', assetid = intasset.id, Case_Product_Type__c = 'Interactive',
		                      Issue_Type__c = 'Mobile', Issue_Sub_Type__c = 'Application',
		                      Issue_Details__c = 'App - Install', Issue_Details_Description__c = 'Testing Interactive 1234',
		                      Customer_Role__c = 'Hotel Management', Customer_Email__c = 'joeblow@hotmail.com', entitlementid = intent.id,
		                      recordtypeid = suppcaseid );
		                      
		 List<Case> lstnewcases = New List<Case>();
		 lstnewcases.add(bbcase);
		 lstnewcases.add(intcase);
		 
		 insert lstnewcases;
		 
		 //this forces the batch process to run immediately, not on a schedule
		 BatchHyattEmailSchedule batch = New BatchHyattEmailSchedule();
		 batch.execute(null);
		                      
		                      
	}//end testBatchHyattEmailSchedule                 
		   
	static testmethod void testBatchEmailCreationProcess()
	{
				
		Account acc = DataGenerator.createAccounts(1, true)[0];
		Account supacc = DataGenerator.createAccounts(1, true)[0];
		Id Rectypeid = Utilities.RecordTypeNameToId('Account', 'Support Office');
		supacc.recordtypeid = rectypeid;
		supacc.name = 'Test Support Office';
		update supacc;
		
		acc.Support_Office__c = supacc.id;
		acc.GIA_Support_Phone_Number__c = '(605) 445-1234';
		acc.Support_Number_Interactive__c = '(605) 445-5678';
		update acc;
		
		Asset bbasset = New Asset(Name = 'Broadband Product Parent', AccountId = acc.Id, Contract_Type__c = 'Interactive;Broadband',
		                                  Quantity = 100, Status = 'Installed Activated' );
		Asset intasset = New Asset(Name = 'Interactive Product Parent', AccountId = acc.Id, Contract_Type__c = 'Interactive;Broadband',
		                                  Quantity = 100, Status = 'Installed Activated' );
		List<Asset> assetlst = New List<Asset>();
		assetlst.add(bbasset);
		assetlst.add(intasset);
		insert assetlst;
		
		Date start = system.today();
		Date endday = system.today().addmonths(12);
		
		Entitlement bbent = New Entitlement(Name = 'Hyatt Stay1000 Entitlement', Accountid = acc.id, Assetid = bbasset.id, 
		                                    startdate = start, enddate = endday );
		Entitlement intent = New Entitlement(Name = 'Hyatt Stay1000 Entitlement', Accountid = acc.id, Assetid = intasset.id, 
		                                    startdate = start, enddate = endday );
		List<Entitlement> entlist = New List<Entitlement>();
		entlist.add(bbent);
		entlist.add(intent);
		insert entlist;
		
		Id suppcaseid = Utilities.RecordTypeNameToId('Case', 'Support Case');
		Datetime firstemaildue = system.now().addhours(Integer.valueof(-.5));
		
		Case bbcase = New Case(Subject = 'Test Broadband Case', AccountId = acc.id, Status = 'Open', Priority = 'Critical',
		                      Origin = 'Customer Incoming Call', assetid = bbasset.id, Case_Product_Type__c = 'Broadband',
		                      Issue_Type__c = 'Software - GIA', Issue_Sub_Type__c = 'Gateway - Nomadix - GIA',
		                      Issue_Details__c = 'Rebooted Server', Issue_Details_Description__c = 'Testing 1234',
		                      Customer_Role__c = 'Front Desk', Customer_Email__c = 'joeblow@hotmail.com', entitlementid = bbent.id,
		                      recordtypeid = suppcaseid, hyatt_email_frequency__c = 1, email_notification_due__c = firstemaildue);
		                      
		Case intcase = New Case(Subject = 'Test Interactive Case', AccountId = acc.id, Status = 'Open', Priority = 'High',
		                      Origin = 'Customer Incoming Call', assetid = intasset.id, Case_Product_Type__c = 'Interactive',
		                      Issue_Type__c = 'Mobile', Issue_Sub_Type__c = 'Application',
		                      Issue_Details__c = 'App - Install', Issue_Details_Description__c = 'Testing Interactive 1234',
		                      Customer_Role__c = 'Hotel Management', Customer_Email__c = 'joeblow@hotmail.com', entitlementid = intent.id,
		                      recordtypeid = suppcaseid, hyatt_email_frequency__c = 4, email_notification_due__c = firstemaildue );
		                      
		 List<Case> lstnewcases = New List<Case>();
		 lstnewcases.add(bbcase);
		 lstnewcases.add(intcase);
		 
		 insert lstnewcases;
		 
		 List<Case> lstcases = New List<Case>();
		 
		 lstcases = [ Select Id, subject, accountid, status, priority, origin, assetid, case_product_type__c, customer_role__c,
		               customer_email__c, entitlementid, recordtypeid, hyatt_email_frequency__c, email_notification_due__c from
		               Case ];
		 
		 
		 BatchHyattEmailCreationProcess.CreateEmailNotifications(lstcases);
		
	}//end testBatchEmailCreationProcess
	
	static testmethod void testBatchProcessFailureEmail()
	{
		String Errormessage = 'Test exception string.';
		BatchHyattEmailCreationProcess.BatchProcessFailureNotification(Errormessage, 'BatchProcessFailureNotification');
		
	}//end testBatchProcessFailureEmail
	
}//end class BatchHyattEmailCreationTest