@IsTest
public class GlobalWebServicesTest{

    static testmethod void testCreateSiteSurvey()
    {   
        Id rectype = Utilities.RecordTypeNameToId('Account', 'Hospitality Site');
        Account acc = New Account(Type='Hotel Site', Phone='999-777-8888', Fax='888-111-2222', recordtypeid=rectype,
                                physical_street_address_line_1__c = '3900 Innovation Street', Physical_City__c='Sioux Falls',
                                physical_state__c='SD', physical_postal_code__c='57107', Name='Test Hotel');

        insert acc;
        Date thisdate = system.today();
        Opportunity opp = new Opportunity(AccountId=acc.id, quota_categories__c = 'GP New Rooms', StageName='Contract',
                                          probability = 75, of_rooms_opportunity__c=100, Name='Test Hotel Opp', 
                                          CloseDate=thisdate);
        insert opp;
        
        test.StartTest();
            String ret = GlobalWebServices.createSiteSurveyFromOpportunity(opp.id, 0);
            system.assert(ret=='Site Survey Created Successfully');
        test.StopTest();
    }

    static testmethod void testgetRecordTypeId()
    {
        test.StartTest();
            Id rectypeid = GlobalWebServices.getRecordTypeId('Case', 'Support Case');
            List<RecordType> reclist = new List<RecordType>();
            reclist = [ Select Id, Name from RecordType where name = 'Support Case' LIMIT 1];
            Id reclistid = reclist[0].Id;
            system.assert(rectypeid==reclistid);
        test.StopTest();

    }

    static testmethod void testWorkOrderCompletion()
    {
        String myid = UserInfo.getUserId();
        Id rectypeid = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
        Account a = DataGenerator.createAccounts(1,true)[0];
        Work_Order__c wo = New Work_Order__c(site__c = a.id, name=a.site_id__c, ownerid = myid, approver__c = myid,
    	                                     install_manager__c = myid, project_coordinator__c = myid, division__c = 'Domestic',
    	                                     region__c = 'Southeast', status__c = 'Billing/Go Live', approval_status__c = 'Billing Approved',
    	                                     recordtypeid = rectypeid);
        insert wo;
        
        Date thisdate = system.today();

		test.StartTest();
        	String result1 = GlobalWebServices.workOrderCompletion(wo.id, myid, myid);
        	//system.assert(result1=='Install Complete Date is required.');
        	Work_Order__c woinstall = [Select Id, Install_Complete_date__c from Work_Order__c where Id = :wo.id LIMIT 1 ];
        	woinstall.Install_Complete_Date__c = thisdate;
        	update woinstall;
        	
        	String nextresult = GlobalWebServices.workOrderCompletion(woinstall.id, myid, myid);
        	system.assert(nextresult=='true');
        	
    }
    
    static testmethod void CreateThirdPartyCaseTest()
    {
    	Account a = DataGenerator.CreateAccounts(1,true)[0];
    	Account partner = DataGenerator.CreateAccounts(1,true)[0];
    	Id rectypeid = Utilities.RecordTypeNameToId('Account', 'Third Party');
    	Id recid = Utilities.RecordTypeNameToId('Account', 'Third Party Contracted Service');
    	a.recordtypeid = recid;
    	partner.recordtypeid = rectypeid;
    	List<Account> updacctlist = New List<Account>();
    	updacctlist.add(a);
    	updacctlist.add(partner);
    	update updacctlist;
    	    	
    	Account_Third_Party_Partner__c atpp = New Account_Third_Party_Partner__c();
    	atpp.related_account__c = a.id;
    	atpp.third_Party_partner_account__c = partner.id;
    	insert atpp;
    	
    	test.StartTest();
    	Account_Third_Party_Partner__c tpp = [ Select Id, related_account__c, third_party_partner_account__c from
    	                                       Account_Third_Party_Partner__c where related_account__c = :a.id LIMIT 1];
    	                                       
    	String getreturn = GlobalWebServices.CreateThirdPartyCase(tpp.id);
    	system.assert(getreturn.contains('500'));  //the CreateThirdPartyCase method returns the new case's id, which all start with 500
    	
    	test.StopTest();
    }
    
    static testmethod void testCreateCTILog()
    {
    	
    	Account a = DataGenerator.CreateAccounts(1,true)[0];
    	
    	Id recid = Utilities.RecordTypeNameToId('Case', 'Support Case');
    	Case c = New Case( accountid=a.id, recordtypeid = recid, subject = 'testing 12345', status = 'Open', Priority='Low',
    	                    Origin='Customer Incoming Call', Case_Product_Type__c = 'FTG', Issue_Type__c='Hardware - FTG',
    	                    Issue_Sub_Type__c = 'Distribution - FTG', Issue_Details__c = 'Amplifiers');
    	                    
    	insert c;
    	
    	
    	String callid = '78926738testcallid';
    	String caseid = String.valueof(c.id);
    	
    	test.StartTest();
    		String returnmsg = GlobalWebServices.CreateCTILog(caseid, callid);
    		system.assert(returnmsg == null); //if the cti log creates successfully, the web service method returns empty string
        test.stopTest();
    }
    
    static testmethod void testGetResult()
    {
    	String ret = '5008976ttt';
    	
    	test.startTest();
    		Boolean istrue = GlobalWebServices.getResult(ret);
    		system.assert(istrue==true); //if the string passed into the method starts with 500, the method returns true
    	test.stopTest();
    }

}