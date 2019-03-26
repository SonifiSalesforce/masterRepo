public with sharing class CreateTestRecords {
	
	public static Account DefaultSupportOfficeAccount()
	{
		system.debug('Creating DefaultSupportOfficeAccount');
		
		Id suppofficerectype = Utilities.RecordTypeNameToId('Account', 'Support Office');
		
		Account so = New Account(Name = 'Midwest Zone 19 Test', Type = 'Support Office', recordtypeid = suppofficerectype,
		                         account_status__c = 'Active', Major_Account_Flag__c='None', phone = '9998881234',
		                         fax = '8887775555', physical_street_address_line_1__c = '225 Testing Street',
		                         physical_city__c = 'Sioux Falls', physical_state__c = 'SD',
		                         physical_postal_code__c = '57104', Time_Zone__c = 'America/Chicago',
		                         site_id_ext_id__c = '807766A', Industry='Service', Region__c = 'Western',
		                         Area__c = 'Western-US', Zone__c = 'Denver');
		
		insert so;
		return so;
	}
	
	//pass in the id of a support office account to link the primary engineer to the support office;
	//you must create a supportofficemember linked to support office account in order to dispatch a
	//support case during a test
	public static SupportOfficeMember__c CreatePrimaryEngineer(Id suppofficeid)
	{
		Id myid = UserInfo.getUserId();
		
		SupportOfficeMember__c member = New SupportOfficeMember__c(SupportOffice__c = suppofficeid, user__c = myid,
		                                role__c = 'Primary Engineer');
		
		insert member;
		return member;
		
	}
	
	
	public static Account DefaultHospitalityAccount()
	{	
		system.debug('Creating DefaultHospitalityAccount');
		
		Id acctrectype = Utilities.RecordTypeNameToId('Account', 'Hospitality Site');
		
	
		Account a = New Account(Name = 'Test Hotel Account', Type = 'Hotel Site', recordtypeid = acctrectype,
		                         account_status__c = 'Active', Major_Account_Flag__c='None', phone = '9958881234',
		                         fax = '8817775555', physical_street_address_line_1__c = '222 Testing Street',
		                         physical_city__c = 'Sioux Falls', physical_state__c = 'SD',
		                         physical_postal_code__c = '57104', Time_Zone__c = 'America/Chicago',
		                         of_rooms__c = 100);
		                         
		insert a;
		return a;                         
	}
	
	public static Account DefaultHealthcareAccount()
	{
		system.debug('Creating DefaultHealthcareAccount');
		
		Id hcrectype = Utilities.RecordTypeNameToId('Account', 'Healthcare Site');
		
	
		Account a = New Account(Name = 'Test Healthcare Account', Type = 'Healthcare Site', recordtypeid = hcrectype,
		                         account_status__c = 'Active', Major_Account_Flag__c='None', phone = '9998881234',
		                         fax = '8917775555', physical_street_address_line_1__c = '223 Testing Street',
		                         physical_city__c = 'Sioux Falls', physical_state__c = 'SD',
		                         physical_postal_code__c = '57104', Time_Zone__c = 'America/Chicago',
		                         of_rooms__c = 100);
		                         
		insert a;
		return a;                  
	}
	
	public static Account DefaultThirdPartyContractedAccount()
	{	
		system.debug('Creating DefaultThirdPartyContractedAccount');
		
		Id acctrectype = Utilities.RecordTypeNameToId('Account', 'Third Party Contracted Service');
		
		
		Account a = New Account(Name = 'Test Third Party Location', recordtypeid = acctrectype,
		                         account_status__c = 'Active', Major_Account_Flag__c='None', phone = '9998871234',
		                         fax = '8837775555', physical_street_address_line_1__c = '223 Testing Street',
		                         physical_city__c = 'Sioux Falls', physical_state__c = 'SD',
		                         physical_postal_code__c = '57104', Time_Zone__c = 'America/Chicago',
		                         of_rooms__c = 100);
		                         
		insert a;
		return a;                         
	}
	
	public static Account DefaultThirdPartyAccount()
	{	
		system.debug('Creating DefaultThirdPartyAccount');
		
		Id acctrectype = Utilities.RecordTypeNameToId('Account', 'Third Party');
		
		
		Account a = New Account(Name = 'Third Party Company', Type = 'Partner', recordtypeid = acctrectype,
		                         account_status__c = 'Active', Major_Account_Flag__c='None', phone = '9998861234',
		                         fax = '8897775555', physical_street_address_line_1__c = '221 Testing Street',
		                         physical_city__c = 'Sioux Falls', physical_state__c = 'SD',
		                         physical_postal_code__c = '57104', Time_Zone__c = 'America/Chicago',
		                         service_response_email__c = 'jjackson@sonifi.com');
		                         
		insert a;
		return a;                         
	}
	
	public static Account_Third_Party_Partner__c LinkAccountToPartner(Id acctid, Id partnerid)
	{
		Account_Third_Party_Partner__c atpp = New Account_Third_Party_Partner__c(Related_Account__c = acctid,
		                                      Third_Party_Partner_Account__c = partnerid, Third_Party_Unique_id__c = 'abc12345');
		                                      
		insert atpp;
		
		return atpp;                                      
	}
	
	public static Case DefaultSupportCase()
	{
		system.debug('Creating DefaultSupportCase');
		
		Id suppcaseid = Utilities.RecordTypeNameToId('Case', 'Support Case');
		Account acc = DefaultHospitalityAccount();
		Account supportoffice = DefaultSupportOfficeAccount();
		acc.support_office__c = supportoffice.id;
		update acc;
		
		Case newcase = New Case(Subject='Test Subject', accountid=acc.id, status='Open', priority='Low',
		                        Origin='Customer Incoming Call', recordtypeid=suppcaseid,
		                        case_product_type__c = 'Interactive', Issue_Type__c = 'Connectivity',
		                        Issue_Sub_Type__c = 'Circuit', Issue_Details__c = 'Circuit - Hotel',
		                        Customer_Name__c = 'Joe Blow', Customer_Role__c = 'Engineer');
		
		insert newcase;
		return newcase;
		
	}
	
	//create a contracted field service case by passing in the account id of the third party contracted service
	//account and the id of the account third party partner record related to that account
	public static Case DefaultContractedFieldServiceCase(Id acctid, Id atppid)
	{
		Id concaseid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
		
		Case cfscase = new Case(Subject = 'Testing Contracted Field Service Case', AccountId = acctid, Status = 'Open',
		                       Priority = 'Low', Origin = 'Third Party Field Service', Case_Product_Type__c = 'Interactive',
		                       Issue_Type__c = 'Software', Issue_Sub_Type__c = 'Content', Issue_Details__c = 'Local Guide',
		                       Third_Party_Partner__c = atppid, Partner_Ticket_Number__c = '789567', recordtypeid = concaseid);
		                       
	    insert cfscase;
	    return cfscase;	                       
	}
	
	
	public static WorkOrder DefaultFieldServiceWO(Id acctid, Id caseid)
	{
		Id fwoid = Utilities.RecordTypeNameToId('WorkOrder', 'FWO');
		
		Datetime thisdate = system.now();
		
		WorkOrder fwo = New WorkOrder(recordtypeid = fwoid, date__c = thisdate, AccountId = acctid, Caseid = caseid,
		                              priority = 'Low', Status = 'New', signature_name__c = 'Joe Blow', Signature_Date__c = thisdate,
		                              customer_title__c = 'Manager', customer_email__c = 'jjackson@sonifi.com',
		                              Invoice_Summary__c = 'This is a test of a regular field work order' );
		                              
		insert fwo;
		return fwo;
	}
	
	public static WorkOrder DefaultThirdPartyFWO(Id acctid, Id caseid)
	{
		Id fwoid = Utilities.RecordTypeNameToId('WorkOrder', 'Third Party FWO');
		
		Datetime thisdate = system.now();
		
		WorkOrder fwo = New WorkOrder(recordtypeid = fwoid, date__c = thisdate, AccountId = acctid, Caseid = caseid,
		                              priority = 'Low', Status = 'New', signature_name__c = 'Joe Blow', Signature_Date__c = thisdate,
		                              customer_title__c = 'Manager', customer_email__c = 'jjackson@sonifi.com',
		                              Invoice_Summary__c = 'This is a test of a third party fwo' );
		                              
		insert fwo;
		return fwo;
	}
    
    public static Opportunity DefaultHospitalityOpportunity(Id acctid)
    {
    	Opportunity opp = New Opportunity();
    	
    	Id hotelrectype = Utilities.RecordTypeNameToId('Opportunity', 'Healthcare Opportunities');
    	
    	opp.Name = 'TestOpportunity';
    	opp.recordtypeid = hotelrectype;
    	opp.Accountid = acctid;
    	opp.Quota_Categories__c = 'GP New Rooms';
    	opp.stagename = 'Proposal';
    	opp.closedate = system.today().addmonths(1);
    	opp.of_rooms_opportunity__c = 100;
    	
    	insert opp;
    	
    	return opp;
    	
    }
    
    public static Opportunity DefaultHeathcareOpportunity(Id hcacctid)
    {
    	Opportunity opp = New Opportunity();
    	
    	Id hcrectype = Utilities.RecordTypeNameToId('Opportunity', 'Healthcare Opportunities');
    	opp.Name = 'TestHCOpportunity';
    	opp.Accountid = hcacctid;
    	opp.Quota_Categories__c = 'GP New Rooms';
    	opp.stagename = 'Proposal';
    	opp.closedate = system.today().addmonths(1);
    	opp.of_rooms_opportunity__c = 100;
    	
    	insert opp;
    	
    	return opp;
    }
    
    public static Quote DefaultHospitalityQuote(Id oppid)
    {
    	Quote quo = New Quote();
    	
    	quo.name = 'TestQuote';
    	quo.opportunityid = oppid;
     	quo.expirationdate = system.today().addmonths(3);
    	quo.iTV_system_installation__c = 15000.00;
    	quo.service_support_per_month__c = 5.00;
    	quo.one_time_add_on_services__c = 5000.00;
    	
    	insert quo;
    	return quo;
    	
    }
    
    
    //create contacts related to a hospitality account. pass in the number of contacts you want created.
    public static List<Contact> DefaultHospitalityContacts(Id acctid, Integer createthismany)
    {
    	List<Contact> insertcontactlist = New List<Contact>();
    	for(integer i = 0; i < createthismany; i++)
    	{
    		Contact newcontact = New Contact();
    		newcontact.firstname = 'Test'+i;
    		newcontact.lastname='Name'+i;
    		newcontact.accountid = acctid;
    		newcontact.role__c = 'Installation Contact';
    		newcontact.status__c = 'Active';
    		newcontact.phone = '605-999-134'+i;
    		insertcontactlist.add(newcontact);
    		system.debug(newcontact);
    		
    	}
    	
    	insert insertcontactlist;
    	
    	return insertcontactlist;
    	
    }
    
    public static Work_Order__c DefaultInstallWorkOrder(Id acctid)
    {
    	String rectypeid = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
    	Work_Order__c wo = New Work_Order__c();
    	String currentuserid = UserInfo.getUserId();
    	
    	wo.recordtypeid = rectypeid;
    	wo.name = 'Install Work Order';
    	wo.site__c = acctid;
    	wo.ownerid = currentuserid;
    	wo.approver__c = currentuserid;
    	wo.install_manager__c = currentuserid;
    	wo.project_coordinator__c = currentuserid;
    	wo.division__c = 'Domestic';
    	wo.region__c = 'North';
    	wo.status__c = 'Schedule Work Order';
    	
    	insert wo;
    	
    	return wo;
    	
    }
    
    public static Work_Order__c DefaultRackBuild(Id accid)
    {
    	String rectypeid = Utilities.RecordTypeNameToId('Work_Order__c', 'Rack Build');
    	Work_Order__c rackwo = New Work_Order__c();
    	String userid = UserInfo.getUserId();
    	Work_Order__c parentwo = DefaultInstallWorkOrder(accid);
    	
    	rackwo.recordtypeid = rectypeid;
    	rackwo.site__c = accid;
    	rackwo.install_manager__c = userid;
    	rackwo.name = 'Rack Build Work Order';
    	rackwo.parent_work_order__c = parentwo.id;
    	rackwo.status__c = 'Not Started';
    	
    	insert rackwo;
    	
    	return rackwo;
    }
    
    public static Order__c DefaultOrder(Id accid)
    {
    	Order__c neworder = New Order__c();
    	neworder.site__c = accid;
    	neworder.name = 'Test Order';
    	neworder.status__c = 'Order Approved';
    	
    	insert neworder;
    	
    	return neworder;
    }
}