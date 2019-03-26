@isTest
public with sharing class EmailUtilitiesTest {
    static testMethod void testdoEmailPosts()
    {
    	// List<User> users = [SELECT u.Id, u.Email, u.Name FROM User u WHERE u.Id = '005L0000000rRPo'];
        List<User> users = DataGenerator.createUsers('System Administrator', 3, true);
    	List<String> emailbody = new List<String>();
    	emailbody.add('Hello');
        emailbody.add('Who are you');
        emailbody.add('What are you doing');
    	List<String> ebody = new List<String>();
    	ebody.add('Welcome to the zoo');
        ebody.add('I am user number 1');
        ebody.add('Test three uses for right messages');

    	List<String> elbody = new List<String>();
    	elbody.add('Welcome to the Library');
        elbody.add('I am user number 2');
        elbody.add('Testing which user gets the right messages');

        
        // emailbody.add('Good bye');
    	Map<Id,List<String>> senderMap = new Map<Id, List<String>>();
    	Integer inx = 0;
        for (User user :users) {
              System.debug('=== ' + user.Email);
              if (inx == 1) {
                 senderMap.put(user.Id,ebody);
              } else if (inx == 2) {
              	 senderMap.put(user.Id,elbody);
              } else {
              	senderMap.put(user.Id,emailbody);
              }     
              inx++;
        }
        
        Test.startTest();
        
        EmailUtilities.doEmailPosts(senderMap);

           
        Test.stopTest();
    	
    }

    //shawks: BUG-00717 - Add new parameter for emailing Healthcare Notifications
    static testmethod void testemailturnonnotice()
    {
    	String emailbody;
    	emailbody += 'This is a test';
    	emailbody += 'for creating a turnon notice email';

        Test.startTest();
        EmailUtilities.EmailTurnonNotice(emailbody, 'Test Account Name', 'Install', 'Healthcare');
        EmailUtilities.EmailTurnonNotice(emailbody, 'Test Account Name', 'Deinstall', 'Test Account Type');
        EmailUtilities.EmailTurnonNotice(emailbody, 'Test Account Name', 'Install', 'Test Account Type');
           
        Test.stopTest();
    }

   //shawks: BUG-00717 - Add new method for emailing Healthcare Notifications
   static TestMethod void testEmailNotification()
   {
   	  String email;
      String emailBody;
      List<String> emailAddress = new list<String>();

      emailAddress.add('test@address.com');
      emailBody += 'Here is the body of the test.';
      emailBody += 'This is the last line.';

      Test.startTest();
      EmailUtilities.EmailNotification(emailAddress, 'Testing EmailNotification', emailBody);
      Test.stopTest();
   }

    static testmethod void testcaseviolationnotification()
    {
    	
     	Account acct = New Account(Name = 'Test Account');
    	Id supprectype = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
    	Account suppoffice = New Account(Name = 'Test Support Office', recordtypeid = supprectype);
		List<Account> newaccountlist = New List<Account>();
		newaccountlist.add(acct);
		newaccountlist.add(suppoffice);
		insert newaccountlist;
    	
    	acct.support_office__c = suppoffice.id;
    	update acct;
    	
    	List<User> userlist = DataGenerator.createUsers('Field Service Rep', 3, true);
    	
    	User usertech = userlist[0];
    	User useroncall = userlist[1];
    	User userprimary = userlist[2];
    	
    	SupportOfficeMember__c techsom = New SupportOfficeMember__c(SupportOffice__c = suppoffice.id, user__c=usertech.id, role__c = 'Technician');
    	SupportOfficeMember__c oncallsom = New SupportOfficeMember__c(SupportOffice__c = suppoffice.id, user__c=useroncall.id, role__c='On Call Tech');
    	SupportOfficeMember__c primarysom = New SupportOfficeMember__c(SupportOffice__c = suppoffice.id, user__c=userprimary.id, role__c='Primary Engineer');
    	
    	List<SupportOfficeMember__c> memberlist = New List<SupportOfficeMember__c>();
    	memberlist.add(techsom);
    	memberlist.add(oncallsom);
    	memberlist.add(primarysom);
    	
    	insert memberlist;
    	
    	//SlaProcess entprocess = New SlaProcess(NameNorm = 'TestSLA', StartDateField = 'Case.Dispatched_Date_Time__c', isactive = true);
    	
    	date teststartdate = system.today();
    	date testenddate = system.today().addmonths(6);
    	
    	Entitlement ent = New Entitlement(Name = 'Test Entitlement Type', Type = 'Phone Support', AccountId = acct.id, StartDate = teststartdate,
    	                                  enddate = testenddate);
    	insert ent;
    	
    	Id supportcaseid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
    	
    	Case supportcase = New Case(Subject='New Test Case', AccountId = acct.id, Priority = 'Critical', Origin = 'Customer Incoming Call',
    	                            Case_Product_Type__c = 'Interactive',  Issue_Type__c = 'Hardware', Issue_Sub_type__c = 'Room Terminal',
    	                            Issue_Details__c = 'Testing Support Case', recordtypeid = supportcaseid, Entitlementid = ent.id);
    	insert supportcase;
    	
    	Case supportcasend = New Case(Subject='New Test Case Non-dispatch', AccountId = acct.id, Priority = 'Critical', Origin = 'Customer Incoming Call',
    	                            Case_Product_Type__c = 'Interactive',  Issue_Type__c = 'Hardware', Issue_Sub_type__c = 'Room Terminal',
    	                            Issue_Details__c = 'Testing Support Case', recordtypeid = supportcaseid, Entitlementid = ent.id);
    	                            
    	insert supportcasend;
    	
    	test.StartTest();
    	
    	List<Case> lstnondispatched = New List<Case>();
    	List<Case> lstdispatched = New List<Case>();
    	
    	lstnondispatched.add(supportcasend);
    	
    	EmailUtilities.PendingCaseViolationNotification(lstnondispatched);
    	
    	supportcase.dispatched__c = true;
    	update supportcase;
    	
    	lstdispatched.add(supportcase);
    	
    	EmailUtilities.PendingCaseViolationNotification(lstdispatched);
    	
  
    	
    	test.stopTest();
    	

    }

	static testMethod void GroupServicesNotificationTest()
	{
		Account acc = new Account(Name = 'Test account');
   		insert acc;
   		
   		Product2 gsprod = New Product2(Name = 'Group Services', productcode = 'CC-330040', family = 'Interactive', isactive = true);
   		insert gsprod;
   		
   		//shawks 20180928: CPQ - update to use out-of-box object Contract instead of Contract__c; 
   		//-> Replace: Account_Name__c -> AccountId; status__c -> status
   		//Contract__c con = New Contract__c(account_name__c = acc.Id, contract_status__c = 'Order Approved');
   		Contract con = New Contract(AccountId = acc.Id, Contract_Status__c = 'Order Approved');
   		insert con;

   		//shawks 20180928: CPQ - update to use CPQ object SBQQ__Subscription__c instead of Contract_Line_Item__c;
   		//-> Replace: name -> Name__c; product__c -> SBQQ__Product__c; legal_contract__c -> SBQQ__Contract__c; quantity__c -> SBQQ__Quantity__c
   		//Contract_Line_Item__c lcli = New Contract_Line_Item__c(Name = 'Group Services', product__c = gsprod.id, legal_contract__c = con.id,
   		//                                                       status__c = 'Pending Installation Activate', quantity__c = 100);
   		SBQQ__Subscription__c lcli = New SBQQ__Subscription__c(Name__c = 'Group Services', SBQQ__Product__c = gsprod.id, SBQQ__Contract__c = con.id,
   		                                                       status__c = 'Pending Installation Activate', SBQQ__Quantity__c = 100);
   		insert lcli;
   		
   		//shawks 20180928: CPQ - update to use CPQ object SBQQ__Subscription__c instead of Contract_Line_Item__c
   		//List<Contract_Line_Item__c> lstlcli = New List<Contract_Line_Item__c>();
   		List<SBQQ__Subscription__c> lstlcli = New List<SBQQ__Subscription__c>();
   		
   		lstlcli.add(lcli);
   		
   		EmailUtilities.GroupServicesNotification(lstlcli);
   		
   		
	}//end GroupServicesNotificationTest
	
	static testmethod void ClosedCaseEmailNotificationTest()
    {
    	Account acc = DataGenerator.createAccounts(1, true)[0];
		Account supacc = DataGenerator.createAccounts(1, true)[0];
		Id Rectypeid = Utilities.RecordTypeNameToId('Account', 'Support Office');
		supacc.recordtypeid = rectypeid;
		supacc.name = 'Test Support Office';
		update supacc;
		acc.Support_Office__c = supacc.id;
		update acc;
		
		Asset bbasset = New Asset(Name = 'Broadband Product Parent', AccountId = acc.Id, Contract_Type__c = 'Interactive;Broadband',
		                                  Quantity = 100, Status = 'Installed Activated' );
		insert bbasset;
		
		Date start = system.today();
		Date endday = system.today().addmonths(12);
		
		Entitlement bbent = New Entitlement(Name = 'Hyatt Stay1000 Entitlement', Accountid = acc.id, Assetid = bbasset.id, 
		                                    startdate = start, enddate = endday );
        insert bbent;
		             
		Case bbcase = New Case(Subject = 'Test Broadband Case', AccountId = acc.id, Status = 'Pending Close', Priority = 'Critical',
		                      Origin = 'Customer Incoming Call', assetid = bbasset.id, Case_Product_Type__c = 'Broadband',
		                      Issue_Type__c = 'Software - GIA', Issue_Sub_Type__c = 'Gateway - Nomadix - GIA',
		                      Issue_Details__c = 'Rebooted Server', Issue_Details_Description__c = 'Testing 1234',
		                      Customer_Role__c = 'Front Desk', Customer_Email__c = 'joeblow@hotmail.com', entitlementid = bbent.id,
		                      stop_hyatt_emails__c = true );  
		insert bbcase;
		
		List<Case> lstclosedcase = New List<Case>();
		lstclosedcase.add(bbcase);
		
		EmailUtilities.ClosedCaseEmailNotification(lstclosedcase);

    }//end CreateClosedCaseEmailNotificationTest
	
	static testmethod void testEmailUponApproval()
	{

		Case case1 = CreateTestRecords.DefaultSupportCase();
        Case c = [ Select id, account.name, accountid, account.support_office__c from Case where
                                id = :case1.id LIMIT 1 ];
        
        //to dispatch a case, the support office related to the case's account must have a primary engineer.
        //that's why we have to create a support office member record with role of Primary Engineer.
        SupportOfficeMember__c newmember = CreateTestRecords.CreatePrimaryEngineer(c.account.support_office__c);

		case1.Dispatched__c = true;
		update case1;
	
		WorkOrder wo = CreateTestRecords.DefaultFieldServiceWO(case1.accountid, case1.id);
	
		List<FieldWorkOrder_Events__c> fwoelist = New List<FieldWorkOrder_Events__c>();
		List<FieldWorkOrder_Events__c> updfwoelist = New List<FieldWorkOrder_Events__c>();
	
		fwoelist = [Select Event_Type__c, Field_Work_Order__c, Event_Name__c, Event_Description__c, Hours__c from FieldWorkOrder_Events__c where
	            Field_Work_Order__c = :wo.id ];
	            
	    system.debug('fwoelist size is ' +fwoelist.size());
				
		Map<Id,List<FieldWorkOrder_Events__c>> mpfwoe = New Map<Id, List<FieldWorkOrder_Events__c>>();
		for(FieldWorkOrder_Events__c event : fwoelist)
		{
			event.hours__c = 1;
			updfwoelist.add(event);
		}
	
		update updfwoelist;
	
		for(FieldWorkOrder_Events__c updevent : updfwoelist)
		{
			if(mpfwoe.containskey(updevent.field_work_order__c))
			{
				mpfwoe.get(updevent.field_work_order__c).add(updevent);
			}
			else
			{
				List<FieldWorkOrder_Events__c> templist = New List<FieldWorkOrder_Events__c>();
				templist.add(updevent);
				mpfwoe.put(updevent.field_work_order__c, templist);
			}
	
		}
	
		Map<Id,WorkOrder> mpsubmitted = New Map<Id,WorkOrder>();
	
		test.StartTest();
	
		wo.Submit_For_Billing__c = true;
		update wo;
		
	    WorkOrder updwo = New WorkOrder();
		updwo = [ Select Id, WorkOrderNumber, Date__c, AccountId, Account_Name__c, Account_Site_ID__c, case.id, case_issue_type__c,
		          case_issue_subtype__c, case_issue_details__c, subject, invoice_summary__c, submit_for_billing__c, status,
                  signature_name__c, customer_email__c, contact_email__c, case_number__c,
                  customer_title__c from WorkOrder where id = :wo.id ];
				  
		mpsubmitted.put(updwo.id, updwo);
		
		EmailUtilities.FieldWorkOrderCustomerNotification(mpsubmitted, mpfwoe);
     	test.StopTest();		

	}//end testEmailUponApproval
	
	static testmethod void testThirdPartyQueueNotification()
	{
		
		Account ac = CreateTestRecords.DefaultThirdPartyContractedAccount();
		Account tpac = CreateTestRecords.DefaultThirdPartyAccount();
		Account_Third_Party_Partner__c atpp = CreateTestRecords.LinkAccountToPartner(ac.id, tpac.id);
		
		Case testcase = CreateTestRecords.DefaultContractedFieldServiceCase(ac.id, atpp.id);
		
		testcase.dispatch_case__c = true;
		update testcase;
		List<Case> lstdispatched = New List<Case>();
		Case mycase = New Case();
		Id caseid;
		lstdispatched = [Select Id, casenumber, subject, accountid, ownerid, priority, createddate, comments__c,
		                 related_third_party_partner_name__c, partner_ticket_number__c, site_id_formula__c, dispatch_case__c, recordtypeid,
		                 physical_city__c, physical_state__c  from Case];
		system.debug('lstdispatched in test is ' +lstdispatched.size());
		                 
		                 
		for(Case c : lstdispatched)
		{
			caseid = c.id;
			mycase = c;
		}
		
		
		Map<Id,Case> testmap = New Map<Id,Case>();
		testmap.put(caseid, mycase);
		EmailUtilities.NotifyThirdPartyCaseQueueMembers(lstdispatched, testmap);
		
	}//end testThirdPartyQueueNotification
    
    static testmethod void testFWOThirdPartyNotifications()
    {
        Account tpcsaccount = CreateTestRecords.DefaultThirdPartyContractedAccount();
        Account partneracct = CreateTestRecords.DefaultThirdPartyAccount();
        Account_Third_Party_Partner__c attp = CreateTestRecords.LinkAccountToPartner(tpcsaccount.id, partneracct.id);
        
        Case tpcase = CreateTestRecords.DefaultContractedFieldServiceCase(tpcsaccount.id, attp.id);
        
        Datetime checkin = system.now().addHours(-4);
        Datetime checkout = system.now().addHours(-2);
        
        Field_Service_Digest__c fsdig = New Field_Service_Digest__c(case__c = tpcase.id, checkin_time__c = checkin,
                                        checkout_time__c = checkout);
        insert fsdig;
        
        WorkOrder tpfwo = CreateTestRecords.DefaultThirdPartyFWO(tpcsaccount.id, tpcase.id);
        tpfwo.submit_for_billing__c = true;
        update tpfwo;
        
        tpfwo.Billing_Approved__c = true;
        tpfwo.Status = 'Billing Approved';
        update tpfwo;
  
        Map<Id,WorkOrder> mpwo = New Map<Id,WorkOrder>();
        
        mpwo.put(tpfwo.id, tpfwo);
        
        EmailUtilities.FieldWorkOrderThirdPartyNotification(mpwo);
     
    }
    
    static testmethod void ProCentricNotificationTest()
    {
    	Account acct = CreateTestRecords.DefaultHospitalityAccount();
    	Order__c o = CreateTestRecords.DefaultOrder(acct.id);
    	Order_Item__c oiparent = New Order_Item__c(Name='Interactive Product Parent', status__c = 'Pending Installation Activate',
    	                                            project_type__c = 'Interactive New Rooms', order__c = o.id);
    	insert oiparent;
    	
    	Order_Item__c oichild = New Order_Item__c(Name='Pro:Centric Direct Customization', status__c = 'Pending Installation Activate',
    	                                            project_type__c = 'Interactive New Rooms', order__c = o.id, parent__c=oiparent.id); 
    	insert oichild;                                                                                     
    	
    	
    	
    	Work_Order__c rackbuild = CreateTestRecords.DefaultRackBuild(acct.id);
    	Associated_Item__c aiparent = New Associated_Item__c(Name='Interactive Product Parent', work_order__c = rackbuild.parent_work_order__c,
    	                                                     status__c = 'Pending Installation Activate', order_item__c = oiparent.id);
    	Associated_Item__c aichild = New Associated_Item__c(Name='Pro:Centric Direct Customization', work_order__c = rackbuild.parent_work_order__c,
    	                                                     status__c = 'Pending Installation Activate', order_item__c = oichild.id);
    	List<Associated_Item__c> ailist = New List<Associated_Item__c>();
    	ailist.add(aiparent);
    	ailist.add(aichild);
    	insert ailist;
    	
    	Map<Id,Work_Order__c> mptest = New Map<Id,Work_Order__c>();
    	
    	
    	test.startTest();
    	
    	Date thisdate = system.today();
    	
    	rackbuild.to_warehouse_date__c = thisdate;
    	update rackbuild;
    	
    	List<Associated_Item__c> lstitm = [Select Id, Name, work_order__c from Associated_Item__c where work_order__c = :rackbuild.parent_work_Order__c];
    	
    	mptest.put(rackbuild.parent_work_Order__c, rackbuild);
    	
    	EmailUtilities.SendProCentricNotification(lstitm, mptest);
    	
   } 
	
	
}