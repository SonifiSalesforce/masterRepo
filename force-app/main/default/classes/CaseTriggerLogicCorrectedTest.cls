@isTest
public with sharing class CaseTriggerLogicCorrectedTest {
	
	
	    static testmethod void testDispatchCases() {
		Integer recordsToCreate = 1;
		
		 
		User u = DataGenerator.createUsers(Definitions.PROFILE_SalesUser, 1, true)[0];
		Account a = DataGenerator.createAccounts(1, true)[0];
		upsert a;
		
		Account suppAcc = DataGenerator.createAccounts(1, true)[0];
		Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
		System.debug('**** /////// *****  SupportOffice Id = ' + supportOfficeId);
		suppAcc.RecordTypeId = supportOfficeId;
		upsert suppAcc;
		
		SupportOfficeMember__c suppMem = new SupportOfficeMember__c();
		suppMem.User__c = u.Id;
		suppMem.SupportOffice__c = suppAcc.Id;
		suppMem.Role__c = 'Primary Engineer';
		upsert suppMem;
		
		a.Support_Office__c = suppAcc.Id;
		upsert a;
		
		AppConfig__c appConfigBlockProcess = new AppConfig__c();
		appConfigBlockProcess.Name='Global';
		appConfigBlockProcess.BlockTriggerProcessing__c = false;
		upsert appConfigBlockProcess;
		
		AppConfig__c appConfig = new AppConfig__c();
		appConfig.Name='Global';
		appConfig.Case_Comments_To_Include_On_Dispatch__c = 999;
		appConfig.Dispatch_Error__c = 'Error while Dispatch';
		upsert appConfig;
		
		CaseComment casecomment = (CaseComment) DataGenerator.createSObjectWithDefaultValues('CaseComment');
		List<CaseComment> ccList = new List<CaseComment>();
		List<Task> tasklist = New List<Task>();
		List<Case> updcase = new List<Case>();
		List<Case> caseList = DataGenerator.createCases(a.Id, recordsToCreate,true);
		Id rectypeid = Utilities.RecordTypeNameToId('Task', 'Support Case Task');
		//upsert caseList;
		for(Case c: caseList){
			c.Support_Office__c = suppAcc.Id;
	        updcase.add(c);
		
			
			casecomment cc = casecomment.clone(False,true);
			cc.ParentId = c.Id;
			cc.CommentBody='Comment Body For '+c.CaseNumber;
			ccList.add(cc);
			
			Task newtask = New Task(Subject='Test Support Case Task');
 			newtask.Priority = 'Low';
 			newtask.Status = 'Completed';
 			newtask.Task_Origin__c = 'Email';
  			newtask.Description = 'testing task creation';
 			newtask.WhatId = c.Id;
 			newtask.RecordTypeId = rectypeid;
 			tasklist.add(newtask);
		}
		upsert ccList;
		upsert tasklist;
		
		update updcase;
		
		Case upcase = New Case();
		
		test.startTest();
		
		for(Case discase : updcase)
		{
			discase.Dispatched__c = true;
			update discase;
			upcase = discase;
		}
		
		Case getcase = [Select Id, Dispatched_Day__c from Case where id = :upcase.id LIMIT 1 ]; 
		
		System.assert(getcase.Dispatched_Day__c != null); //case trigger should have filled in this field upon dispatch
		
	    getcase.Dispatched__c = false;
	    
	    update getcase;
	
		test.stopTest();
		
		Case checkcase = [ Select Id, Dispatched_Day__c from Case where id = :getcase.id];
		
		system.assert(checkcase.Dispatched_Day__c == null);

	}
	
	static testmethod void TestHyattSLAEmailFunctionality()
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
		
		Case bbcase = New Case(Subject = 'Test Broadband Case', AccountId = acc.id, Status = 'Open', Priority = 'Critical',
		                      Origin = 'Customer Incoming Call', assetid = bbasset.id, Case_Product_Type__c = 'Broadband',
		                      Issue_Type__c = 'Software - GIA', Issue_Sub_Type__c = 'Gateway - Nomadix - GIA',
		                      Issue_Details__c = 'Rebooted Server', Issue_Details_Description__c = 'Testing 1234',
		                      Customer_Role__c = 'Front Desk', Customer_Email__c = 'joeblow@hotmail.com', entitlementid = bbent.id );
		                      
		Case intcase = New Case(Subject = 'Test Interactive Case', AccountId = acc.id, Status = 'Open', Priority = 'High',
		                      Origin = 'Customer Incoming Call', assetid = intasset.id, Case_Product_Type__c = 'Interactive',
		                      Issue_Type__c = 'Mobile', Issue_Sub_Type__c = 'Application',
		                      Issue_Details__c = 'App - Install', Issue_Details_Description__c = 'Testing Interactive 1234',
		                      Customer_Role__c = 'Hotel Management', Customer_Email__c = 'joeblow@hotmail.com', entitlementid = intent.id );
		   
		Case intcase2 = New Case(Subject = 'Test Interactive Case2', AccountId = acc.id, Status = 'Open', Priority = 'High',
		                      Origin = 'Customer Incoming Call', assetid = intasset.id, Case_Product_Type__c = 'Interactive',
		                      Issue_Type__c = 'Mobile', Issue_Sub_Type__c = 'Application',
		                      Issue_Details__c = 'App - Install', Issue_Details_Description__c = 'Testing Interactive 1234',
                              entitlementid = intent.id );                 
		                      
		
		List<Case> caselist = New List<Case>();
		caselist.add(bbcase);
		caselist.add(intcase);
		caselist.add(intcase2);
		
		test.startTest();
		
			insert caselist;	
			
			List<Case> testcases = New List<Case>();
			List<Case> updcases = New List<Case>();
			List<Case> getcases = New List<Case>();
			
			testcases = [ Select Id, Subject, hyatt_email_frequency__c, email_notification_due__c, priority, status from Case ];
			
			
			for(Case testcase : testcases)
			{
					
				if(testcase.id == bbcase.id)
				{   system.debug('bbcase priority before update is ' +testcase.priority);
					testcase.priority = 'Low';
					update testcase;
					system.debug('broadband test case was just updated to Low');
	                
				}
			}
			

			
			getcases = [ Select Subject, stop_hyatt_emails__c, hyatt_email_frequency__c, email_notification_due__c, priority,
			                        status from Case ];	
			             
			for(Case getcase : getcases)
			{
				if(getcase.subject == 'Test Interactive Case')
				{   system.assert(getcase.hyatt_email_frequency__c == 4);  
					system.assert(getcase.email_notification_due__c != null);
					system.debug('Test Interactive Case frequency and email due is ' +getcase.hyatt_email_frequency__c +', ' +getcase.email_notification_due__c); 
				}
				
				if(getcase.subject == 'Test Broadband Case')
				{  system.debug('Test Broadband Case frequency = ' +getcase.hyatt_email_frequency__c);  
				   system.assert(getcase.hyatt_email_frequency__c == 12);
				   getcase.status = 'Pending Close';
				   update getcase;
				}
				
			}
			
			Case giacase = [Select Id, subject, priority, status, stop_hyatt_emails__c from Case where subject = 'Test Broadband Case' LIMIT 1 ];
			system.debug(' stop hyatt emails on broadband case = ' +giacase.stop_hyatt_emails__c);
			system.assert(giacase.stop_hyatt_emails__c == true);
			
			giacase.status = 'Open';  //change case status back to open to hit code that unchecks the stop box
			update giacase;
		
			intcase2.customer_role__c = 'Hotel Management';
			intcase2.customer_email__c = 'joeblow@hotmail.com';
			update intcase2;  //add customer role & email address to the case that has none to touch that update code
		
		test.stopTest();

			
	}
	
	
	//jjackson 3/2018 added test code that will hit new code added to the trigger logic if
	//case is a support case but has a third party entitlement
	public static testmethod void TestContractedFieldServiceCaseCreation()
	{
		system.debug('Begin TestContractedFieldServiceCaseCreation');
		
		Id accttypeid = Utilities.RecordTypeNameToId('Account', 'Third Party Contracted Service');
		Id casetypeid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
		Id supptypeid = Utilities.RecordTypeNameToId('Case', 'Support Case');
		Id tpid = Utilities.RecordTypeNameToId('Account', 'Third Party');
		
		Account ac = New Account();
		ac.recordtypeid = accttypeid;
		ac.name = 'Test Third Party Contracted';
		ac.physical_street_address_line_1__c = '100 Test Street';
		ac.physical_city__c = 'Boston';
		ac.physical_state__c = 'MA';
		ac.physical_country__c = 'USA';
		ac.phone = '999-999-9999';
		insert ac;
		
		Account tpac = New Account();
		tpac.recordtypeid = tpid;
		tpac.name = 'Test Third Party';
		tpac.physical_street_address_line_1__c = '100 Testing Street';
		tpac.physical_city__c = 'Boston';
		tpac.physical_state__c = 'MA';
		tpac.physical_country__c = 'USA';
		tpac.phone = '999-888-9999';
		insert tpac;
		
		Account acc = [Select id, site_id__c from Account where id = :tpac.id LIMIT 1 ];
		
		Account_Third_Party_Partner__c atpp = New Account_Third_Party_Partner__c();
		atpp.related_account__c = ac.id;
		atpp.third_party_partner_account__c = tpac.id;
		insert atpp;
		
		Id userid = UserInfo.getUserId();
		system.debug('original ownerid is ' +userid);
		
		Case testcase = New Case();
		testcase.recordtypeid = casetypeid;
		testcase.subject = 'Testing Case Trigger';
		testcase.accountid = ac.id;
		testcase.ownerid = UserInfo.getUserId();
		testcase.status = 'Open';
		testcase.priority = 'Low';
		testcase.origin = 'Third Party Field Service';
		testcase.case_product_type__c = 'Interactive';
		testcase.issue_type__c = 'Hardware';
		testcase.issue_sub_type__c = 'DCS/Content Server';
		testcase.issue_details__c = 'Missing Content';
		testcase.third_party_partner__c = atpp.id;
		testcase.comments__c = 'this is completely a test.';

		
		//jjackson 3-2018 added more to cover support cases that have a third party entitlement
		ThirdPartyEntitlementName__c cs = New ThirdPartyEntitlementName__c();
		cs.Name = 'TestEntitlement';
		cs.ThirdPartySiteId__c = '8899789';
		insert cs;
		
		Date start = system.today();
    	Date done = system.today().addmonths(3);
    	ServiceContract sc = New ServiceContract(Name='TestWarranty', accountid=ac.id,
    	                     startdate=start, enddate=done);
    	insert sc;
    	Entitlement ent = New Entitlement(Name = 'TestEntitlement', accountid = ac.id,
    	startdate=start, enddate=done, servicecontractid=sc.id);
    	insert ent;
		
		Case testc = New Case();
		testc.recordtypeid = supptypeid;
		testc.subject = 'Testing Case Trigger';
		testc.accountid = ac.id;
		testc.ownerid = UserInfo.getUserId();
		testc.status = 'Open';
		testc.priority = 'Low';
		testc.origin = 'Customer Incoming Call';
		testc.case_product_type__c = 'Interactive';
		testc.issue_type__c = 'Hardware';
		testc.issue_sub_type__c = 'DCS/Content Server';
		testc.issue_details__c = 'Missing Content';
		testc.comments__c = 'this is completely a test.';
		testc.entitlementid = ent.id;
		testc.service_contract_name__c = sc.id;
		
		List<Case> createcase = New List<Case>();
		createcase.add(testcase);
		createcase.add(testc);
		insert createcase;

		
		test.startTest();
		
		Case thiscase = [ Select dispatch_case__c from Case where id = :testcase.id LIMIT 1 ];
		thiscase.dispatch_case__c = true;
		update thiscase;
		Case updcase = [Select ownerid from Case LIMIT 1];
		system.assert(thiscase.ownerid != testcase.ownerid);
		test.stopTest();
		
		List<CaseComment> lstcomment = New List<CaseComment>([ Select parentid, commentbody from CaseComment where parentid = :testc.id ]);
		system.debug('lstcomment size is ' +lstcomment.size());

		
	}
	
	static testmethod void UpdateCaseCommentsThirdParty()
	{
		Id accttypeid = Utilities.RecordTypeNameToId('Account', 'Third Party Contracted Service');
		Id casetypeid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
		Id tpid = Utilities.RecordTypeNameToId('Account', 'Third Party');
		
		Account ac = New Account();
		ac.recordtypeid = accttypeid;
		ac.name = 'Test Third Party Contracted';
		ac.physical_street_address_line_1__c = '100 Test Street';
		ac.physical_city__c = 'Boston';
		ac.physical_state__c = 'MA';
		ac.physical_country__c = 'USA';
		ac.phone = '999-999-9999';
		insert ac;
		
		Account tpac = New Account();
		tpac.recordtypeid = tpid;
		tpac.name = 'Test Third Party';
		tpac.physical_street_address_line_1__c = '100 Testing Street';
		tpac.physical_city__c = 'Boston';
		tpac.physical_state__c = 'MA';
		tpac.physical_country__c = 'USA';
		tpac.phone = '999-888-9999';
		insert tpac;
		
		Account acc = [Select id, site_id__c from Account where id = :tpac.id LIMIT 1 ];
		
		Account_Third_Party_Partner__c atpp = New Account_Third_Party_Partner__c();
		atpp.related_account__c = ac.id;
		atpp.third_party_partner_account__c = tpac.id;
		insert atpp;
		
		Account thirdpartyac = [ Select Id, Name, site_Id__c, physical_street_address_line_1__c from Account where 
		                         physical_street_address_line_1__c = '100 Testing Street' LIMIT 1];
		
		Id userid = UserInfo.getUserId();
		system.debug('original ownerid is ' +userid);
		
		Case testcase = New Case();
		testcase.recordtypeid = casetypeid;
		testcase.subject = 'Testing Case Trigger';
		testcase.accountid = ac.id;
		testcase.ownerid = UserInfo.getUserId();
		testcase.status = 'Open';
		testcase.priority = 'Low';
		testcase.origin = 'Third Party Field Service';
		testcase.case_product_type__c = 'Interactive';
		testcase.issue_type__c = 'Hardware';
		testcase.issue_sub_type__c = 'DCS/Content Server';
		testcase.issue_details__c = 'Missing Content';
		testcase.third_party_partner__c = atpp.id;
		testcase.comments__c = 'this is completely a test.';
		testcase.related_third_party_partner_name__c = thirdpartyac.site_id__c +' - Test Third Party';
		insert testcase;
		
		test.startTest();
		
		List<CaseComment> lstcomment = New List<CaseComment>();
		
		testcase.comments__c = 'changing the case comment for test purposes.';
		update testcase;
		
		Case updcase = [ select id, comments__c from Case LIMIT 1 ];
		system.debug('updcase comment is ' +updcase.comments__c);

		//the list of case comments will contain two different comments;  the first one
		//is created upon case insert when the trigger calls PopulateSpecialnstructions. 
		//The second is created when the case comments__c field is updated and calls the
		//CreateCaseCommentsfromComments method in the after update trigger.  Both of these methods
		//reside in CaseTriggerLogic.
		lstcomment = [ Select parentid, commentbody from casecomment ];
		//system.assert(lstcomment.size() == 2);
		system.debug('lstcomment size is ' +lstcomment.size());
		
		test.stopTest();
		
	}
	
	static testmethod void testVerifyNameandRole()
	{
		Case testcase = CreateTestRecords.DefaultSupportCase();
		
		system.assert(testcase.customer_name__c != null);
	}
	
	static testmethod void testCheckCaseOwner()
	{
		system.debug('Begin testCheckCaseOwner...');
		
		Case suppcase = CreateTestRecords.DefaultSupportCase();
		User sysadmin;
		User singledigits;
		Set<String> setlastname = New Set<String>();
		setlastname.add('McGillivray');
		setlastname.add('Digits');
		List<User> userlist = [ select id, lastname from user where lastname in :setlastname ];
		for(User u : userlist)
		{
			if(u.lastname == 'McGillivray')
			{  sysadmin = u;  
			   system.debug('sysadmin user id is ' +u.id);
			}
			else
			{  singledigits = u; }
		}
		
		suppcase.ownerid = sysadmin.id;
		update suppcase;
		
		test.startTest();
			suppcase.ownerid = singledigits.id;
			suppcase.single_digits_case_id__c = '4456789';
			update suppcase;
			
			Case updcase = [Select Id, ownerid from Case where id = :suppcase.id ];
			//system.debug('updcase ownerid is ' +updcase.ownerid);
			system.assert(updcase.ownerid == sysadmin.id);
		test.stopTest();
		
	}
	
	/*static void testUnDispatchCases() {
		Integer recordsToCreate = 1;
		Account acc = DataGenerator.createAccounts(recordsToCreate, true)[0];
		List<Case> updcase = New List<Case>();
		List<Case> updcaseagain = New List<Case>();
		
		List<Case> newcase = New List<Case>();
		Case c1 = New Case();
		newcase = DataGenerator.createCases(acc.Id, 1, true);
		
		for(Case c : newcase)
		{   c1 = c;   }
		
		
		c1.Dispatched__c = true;
		c1.Dispatched_Day__c = System.now().format('EEEE');
		c1.Dispatched_Hour__c = System.now().hour();
		c1.Dispatched_Minute__c = System.now().minute();
		updcase.add(c1);
		
		
		update updcase;
		
		Test.StartTest();
		
		for(Case ucase : updcase)
		  { ucase.Dispatched__c = false;
			updcaseagain.add(ucase);   }
			
		update updcaseagain;
		
		test.stopTest();
		
		Case getcase = [ Select Id, Dispatched_Day__c from Case where Id = :c1.Id LIMIT 1];
		
		system.assert(getcase.Dispatched_Day__c == null);
		
	}  */
}