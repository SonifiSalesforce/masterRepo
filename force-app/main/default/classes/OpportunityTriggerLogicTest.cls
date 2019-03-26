@isTest
public with sharing class OpportunityTriggerLogicTest 
{
    static testMethod void opportunityContractRequest()
    {

        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest opportunityNoRelatedContractRequest Test .  **********    START');
        
        //jjackson 6/2018 replacing these methods with new methods from the CreateTestRecords class
        //List<Account> accounts = DataGenerator.createAccounts(1, true);
        //List<Contact> contacts = DataGenerator.createContacts(accounts[0], 1, true);
        //List<Opportunity> opportunities = DataGenerator.createOpptys(accounts[0], 1, true);
        //Opportunity o = opportunities[0];
        //Contact c = contacts[0];
        
        Account a = CreateTestRecords.DefaultHospitalityAccount();
        Account a2 = CreateTestRecords.DefaultHealthcareAccount();
        Account suppoffice = CreateTestRecords.DefaultSupportOfficeAccount();
        List<Account> acclist = New List<Account>();
        a.support_office__c = suppoffice.id;
        a2.support_office__c = suppoffice.id;
        acclist.add(a);
        acclist.add(a2);
        update acclist;
        
        Opportunity o1 = CreateTestRecords.DefaultHospitalityOpportunity(a.id);
        Opportunity o2 = CreateTestRecords.DefaultHeathcareOpportunity(a2.id);
        List<Contact> conlist = CreateTestRecords.DefaultHospitalityContacts(a.id, 1);
        List<Contact> c2list = CreateTestRecords.DefaultHospitalityContacts(a2.id, 1);
		Contact c1 = New Contact();
		Contact c2 = New Contact();
		for(Contact c : conlist)
		{ c1 = c; }
		for(Contact con : c2list)
		{  c2 = con;  }
        o1.proposal_recipient__c = c1.id;
        o2.proposal_recipient__c = c2.id;
        List<Opportunity> lstopp = New List<Opportunity>();
        lstopp.add(o1);
        lstopp.add(o2);
        update lstopp;
        
        //jjackson 4/18 adding a contact to the proposal_recipient__c field auto-creates the opportunitycontactrole record
       // OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=contacts[0].Id,IsPrimary=true);
       // insert ocr;
		
		//check the contract request box on the opportunity and run the trigger by doing an update -- this will create a case
		//then uncheck it and check it again to verify the first case closes and the 2nd case is created.
		
		test.startTest();
		
		List<Opportunity> Opplist = [Select Id, Create_Contract_Request__c, AccountId, Account.name from Opportunity ];
		List<Opportunity> lstupdopp = New List<Opportunity>();
		for(Opportunity o : Opplist)
		{ o.Create_Contract_Request__c = true; 
		  lstupdopp.add(o);
		}
		
		update lstupdopp;
		
		List<Case> newcaselist = New List<Case>();
		newcaselist = [Select Id, Status, Opportunity__c from Case ];
		
		system.debug('newcaselist size is ' +newcaselist.size());
		
		List<Opportunity> updolist = [ Select Id, Create_Contract_Request__c from Opportunity ];
		List<Opportunity> unchecklist = New List<Opportunity>();
		for(Opportunity updo : updolist)
		{ updo.Create_Contract_Request__c = false;
		  unchecklist.add(updo);
		}
		update unchecklist;
		
		List<Opportunity> updateopp = [ Select Id, Create_Contract_Request__c from Opportunity ];
		List<Opportunity> rechecklist = New List<Opportunity>();
		for(Opportunity opp : updateopp)
		{ opp.Create_Contract_Request__c = true;
		  rechecklist.add(opp);
		}
		update rechecklist;
		
		test.stopTest();
		
		List<Case> caselist = New List<Case>();
		caselist = [ Select Id, Status, Accountid from Case ];
		
		system.debug('caselist size is ' +caselist.size());
		//now there should be 4 contract request cases, one closed and one open for each opportunity
		
		system.assert(caselist.size() > 0);
		
		Boolean closedcase = false;
		Boolean opencase = false;
		
		for(Case reccase : caselist)
		{
		   if(reccase.accountid == a2.id)
		    if(reccase.Status == 'Requested')
			{  opencase = true;   }
			else
			{  closedcase = true; }
		}
		
		system.debug('opencase = ' +opencase);
		system.debug('closedcase = ' +closedcase);
		
		system.assert(opencase);
		system.assert(closedcase);
	
    }//end contract request test
    
    //jjackson this code not needed because network engineering cases are no longer used  4/2018
   /* static testMethod void opportunityNetworkEngineeringCase()
    {

        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest opportunityNetworkEngineeringCase  **********    START');
 
        List<Account> accounts = DataGenerator.createAccounts(1, true);
        List<Contact> contacts = DataGenerator.createContacts(accounts[0], 1, true);
        List<Opportunity> opportunities = DataGenerator.createOpptys(accounts[0], 1, true);
        
        Opportunity o = opportunities[0];
        
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=contacts[0].Id,IsPrimary=true);
        insert ocr;
		
		//check the GIA Network Engineering Request box on the opportunity and run the trigger by doing an update -- this will create a case
			
		test.startTest();
		
		Opportunity Opp = [Select Id, GIA_Network_Engineering_Request__c, AccountId from Opportunity where Id = :o.Id LIMIT 1];
		Opp.GIA_Network_Engineering_Request__c = true;
		update Opp;
		
		List<Case> newcaselist = New List<Case>();
		newcaselist = [Select Id, Status, Opportunity__c from Case ];
		
		system.debug('newcaselist size is ' +newcaselist.size());

		
		test.stopTest();
		
		List<Case> caselist = New List<Case>();
		caselist = [ Select Id, Status from Case ];
		
		system.debug('caselist size is ' +caselist.size());
		//now there should be 1 network engineering request case
		
		system.assert(caselist.size() > 0);
		
		Boolean opencase = false;
		
		for(Case reccase : caselist)
		{
		    if(reccase.Status == 'Requested')
			{  opencase = true;   }
		}
		system.assert(opencase);
	
	
    }//end network engineering request test */
 
   /******************************************************************************************************
    ****************************Update Opportunity total number Rooms TEST METHODS*********************************************
    *******************************************************************************************************/

    static testMethod void UpdateTotalNoRoomsSiteSurveytest()
    {

        //create test data
        List<Opportunity_Site_Survey_Update_Status__c> statusSettings = new List<Opportunity_Site_Survey_Update_Status__c>();
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='Schedule Survey'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='Scheduled'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='In Progress'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='On Hold'));
        
        insert statusSettings;
        
        //Acquire test user of Profile Admin Manager
        Profile pfl = [select id from profile where name='System Administrator'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';

        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest Update Total rooms Test .  **********    START');  
       
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        
        User testUser =  DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 1, false).get(0);

        testUser.email=randomName;
        testUser.emailencodingkey='UTF-8'; 
        testUser.lastname='Testing';
        testUser.languagelocalekey='en_US';
        testUser.localesidkey='en_US'; 
        testUser.profileid = pfl.Id;  
        testUser.country='United States'; 
        testUser.CommunityNickname = 'u1';
        testUser.timezonesidkey='America/Los_Angeles'; 
        testUser.username=randomName;
        insert testUser;
        
        Opportunity opp = DataGenerator.createOpptys(acc, 1, false).get(0);
        Opportunity opp1 = DataGenerator.createOpptys(acc, 1, false).get(0);
        Opportunity opp2 = DataGenerator.createOpptys(acc, 1, false).get(0);

        // Asset ass1;
        //Asset ass2;

        Site_survey__c ssvy1; 
        Site_survey__c ssvy2;
        Site_survey__c ssvy3;


        system.runAs(testUser)
        {        
            //Create Account and Asset
          //  ass1 = new Asset();
           // ass1.AccountId = acc.Id;
           // ass1.Name = 'Part Inventory Test Asset Install';
           // ass1.Status = 'Pending Install';
           // insert ass1;
            
            
            //create on update
            opp.of_Rooms_Opportunity__c= 50;
            opp.CPO_Approved__c = true;
            opp.Type_of_Assessment__c = 'No Charge Desktop Review';
            opp.StageName = 'Desktop Review Required';

            opp1.of_Rooms_Opportunity__c= 12;
            opp1.CPO_Approved__c = true;
            opp1.Type_of_Assessment__c = 'No Charge Desktop Review';
            opp1.StageName = 'Desktop Review Required';

        
            //make sure they do not create two site surveys
//            opp2.of_Rooms_Opportunity__c = 50;
//            opp2.CPO_Approved__c = true;
//            opp2.Type_of_Assessment__c = 'No Charge Desktop Review';
//            opp2.StageName = 'Site Survey Order Approved';
            Test.startTest();

//            insert opp2;
            
            insert opp1;

            insert opp;
            // update opp1;

            ssvy1 = new Site_survey__c();
            ssvy1.Number_of_Rooms__c= 20;        
            // ssvy1.AccountId__c = acc.Id;
            ssvy1.Status__c = 'Schedule Survey';
            ssvy1.Opportunity__c = opp.id;        
            insert ssvy1;
        
            ssvy2 = new Site_survey__c();
            ssvy2.Number_of_Rooms__c= 20;        
            // ssvy2.AccountId__c = acc.Id;
            ssvy2.Status__c = 'Schedule Survey';
            ssvy2.Opportunity__c = opp1.id;        
            insert ssvy2;
        
//            ssvy3 = new Site_survey__c();
//            ssvy3.Number_of_Rooms__c = 20;        
//            ssvy3.Status__c = 'Schedule Survey';
//            ssvy3.Opportunity__c = opp2.id;        
//            insert ssvy3;

//            opp2.of_Rooms_Opportunity__c = 75;
//            update opp2;
        
            opp.of_Rooms_Opportunity__c= 75;
            update opp;

            opp1.of_Rooms_Opportunity__c= 150;
            update opp1;
                
            Test.stopTest();
        
            List<Site_Survey__c> sites = [SELECT id, Number_of_Rooms__c FROM Site_Survey__c];
            System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest Update Total number of rooms Test .  ********** '+sites.size());
            system.assertEquals(2, sites.size());
            Integer inx = 0;
            for (Site_Survey__c ssv : sites) {
                System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest Total number of rooms Test .  **********   test results '+ssv.Number_of_Rooms__c +' id '+ssv.id);
                if (ssv.id == ssvy1.id)
                {               
                  system.assertEquals(75 , ssv.Number_of_Rooms__c);
                } else {
                  system.assertEquals(150 , ssv.Number_of_Rooms__c);
                }   
            }
        }
 
   } //end UpdateTotalNoRoomsSiteSurvey
   
          
   static testmethod void testAssignorCreatePrimaryContact()
   {
   		
   		Account acc = CreateTestRecords.DefaultHospitalityAccount();
   		Opportunity Opp = CreateTestRecords.DefaultHospitalityOpportunity(acc.id);
   		List<Contact> lstcontact = CreateTestRecords.DefaultHospitalityContacts(acc.id, 2);
   		
   		test.startTest();
   		
   			Contact contact1 = [Select id, name from Contact where name like '%0' LIMIT 1];
   			Opp.proposal_recipient__c = contact1.id;
   			update Opp;
   			
   			OpportunityContactRole ocr = [Select Id, contactid, opportunityid, isprimary from
   			                              OpportunityContactRole where contactid = :contact1.id LIMIT 1];
   			                              
   			system.debug('isprimary is  ' +ocr.isprimary);
   			
   			Opportunity opprec = [Select Id, proposal_recipient__c from Opportunity where id = :Opp.id ];
   			Contact contact2 = [Select id, name from Contact where name like '%1' LIMIT 1];
   			
   			opprec.proposal_recipient__c = contact2.id;
   			update opprec;
   			
   			List<OpportunityContactRole> ocrlist = [Select contactid, opportunityid, isprimary from OpportunityContactRole
   			                                        where opportunityid = :opprec.id ];
   			                                        
   			system.assert(ocrlist.size() == 2);
   			
   			Boolean flag = false;
   			for(OpportunityContactRole role : ocrlist)
   			{
  
   				if(role.contactid == contact2.id)
   				{
   					if(role.isprimary == true)
   					{  flag = true;  }
   				}
  			}
  			
 			system.assert (flag==true);
 			
 			Opportunity oppty = [Select Id, proposal_recipient__c from Opportunity where id = :opprec.id ];
 			oppty.proposal_recipient__c = contact1.id;
 			update oppty;
 			
 			List<OpportunityContactRole> lstopconrole = [Select contactid, opportunityid, isprimary from OpportunityContactRole
 			                                             where opportunityid = :oppty.id ];
 			                                             
 			for(OpportunityContactRole opcon : lstopconrole)
 			{
 				if(opcon.contactid == contact1.id)
 				{  system.assert(opcon.isprimary == true);  }
 				
 				if(opcon.contactid == contact2.id)
 				{  system.assert(opcon.isprimary == false); }
 			}
 			test.stopTest();	
   }//end testAssignorCreatePrimaryContact

   static testMethod void testAlertContrAdmins()
   {
	  List<Account> acctlist = new List<Account>();
	  List<Contract> contlist = new List<Contract>();
	  List<Opportunity> insertOpplist = new List<Opportunity>();
	  List<Opportunity> opplist = new List<Opportunity>();
	  
	  //Create Contract Manager to notify with Chatter
	  List<User> u1 = DataGenerator.createUsers('Contract Manager', 1, true);
	  
	  //Create Custom Setting for Contract status values
	  OpportunityRelatedContractAlertStatuses__c setting = new OpportunityRelatedContractAlertStatuses__c(name= 'Draft');
	  insert setting;

	  //Create Accounts
	  Account acct1 = new Account(Name = 'Test Acc 1');
	  acctlist.add(acct1);
	  Account acct2 = new Account(Name = 'Test Acc 2');
	  acctlist.add(acct2);
	  Account acct3 = new Account(Name = 'Test Acc 3');
	  acctlist.add(acct3);
	  Account acct4 = new Account(Name = 'Test Acc 4');
	  acctlist.add(acct4);
	  insert acctlist;

      //Create Opportunities
	  Opportunity o1 = CreateTestRecords.DefaultHospitalityOpportunity(acct1.id);
      Opportunity o2 = CreateTestRecords.DefaultHeathcareOpportunity(acct2.id);
	  Opportunity o3 = new Opportunity(Name = 'Test Opportunity 3', recordtypeid = Utilities.RecordTypeNameToId('Opportunity', 'Hospitality Opportunities'),
	                                   AccountId = acct3.Id, Amount = 100.50, stagename = 'Proposal',
									   closedate = system.today().addmonths(1),
									   of_rooms_opportunity__c = 150);
	  insertOpplist.add(o3);
	  Opportunity o4 = new Opportunity(Name = 'Test Opportunity 4', recordtypeid = Utilities.RecordTypeNameToId('Opportunity', 'Hospitality Opportunities'),
	                                   AccountId = acct4.Id, Amount = 2000.00, stagename = 'Proposal',
									   closedate = system.today().addmonths(1),
									   of_rooms_opportunity__c = 200);
	  insertOpplist.add(o4);
	  insert insertOpplist;

	  //Create Contracts and related to Opportunities
	  Contract cont1 = new Contract(AccountId = acct1.Id, SBQQ__Opportunity__c = o1.Id, Contract_Status__c = 'Draft');
	  contlist.add(cont1);
	  Contract cont2 = new Contract(AccountId = acct2.Id, SBQQ__Opportunity__c = o2.Id, Contract_Status__c = 'Draft');
	  contlist.add(cont2);
	  Contract cont3 = new Contract(AccountId = acct3.Id, SBQQ__Opportunity__c = o3.Id, Contract_Status__c = 'Draft');
	  contlist.add(cont3);
	  insert contlist;

	  Datetime starttime = Datetime.now();

	  //Update opportunities to test
	  o1.amount = 1000.00;
	  opplist.add(o1);
	  o2.of_rooms_opportunity__c = 160;
	  opplist.add(o2);
	  o3.amount = 150.05;
	  opplist.add(o3);
	  o4.amount = 1500.99;
	  opplist.add(o4);

	  test.startTest();
	     update opplist;
	  test.stopTest();

      //Verify only two opportunities included in Chatter posts
      List<FeedItem> feedItems = [ SELECT Id,ParentId, Body FROM FeedItem WHERE CreatedDate >= :starttime ];
      System.debug('Test - Opportunities included in Chatter = ' + feedItems[0].Body.countMatches(';'));
	  system.assertEquals(2, feedItems[0].Body.countMatches(';'), 'Just two opportunities should have triggered Chatter posts');
   }  //End of testAlertContrAdmins
   
   static testmethod void testCustomQuoteFieldstoOpp()
   {
   		Account acct = CreateTestRecords.DefaultHospitalityAccount();
   		Id opprectype = Utilities.RecordTypeNameToId('Opportunity', 'Hospitality Opportunities');
   		Id qrectype = Utilities.RecordTypeNameToId('SBQQ__Quote__c', 'Approved Quote');
   		Date thisdate = system.today();
   		Date expdate = thisdate.addmonths(3);
   		
 		                    
 
   		
   		Opportunity opp = New Opportunity(Name = acct.name +'-' +thisdate, accountid=acct.id, stagename='Proposal',
   		                   quota_categories__c = 'GP New Rooms', closedate = expdate);
   		insert opp;
   		
   		SBQQ__Quote__c q = New SBQQ__Quote__c(recordtypeid=qrectype, sbqq__account__c = acct.id, sbqq__type__c='Quote',
   		                    sbqq__status__c = 'Approved', ftg_monthly_programming_fee__c = 35.00, sbqq__expirationdate__c = expdate,
   		                     of_televisions__c = 100, sbqq__opportunity2__c = opp.id);
 		insert q;


   		
   		test.startTest();
   		
  
   			q.sbqq__primary__c = true;
   			update q;
   			
   			system.debug('quote updated');
   			
   			  			
   			Opportunity updopp = [ Select id, sbqq__primaryquote__c, of_televisions__c, ftg_monthly_programming_fee__c from
   			            			Opportunity where Id = :opp.id LIMIT 1 ];
   			            
    			
   			system.assert(updopp.of_televisions__c == 100);
   			system.assert(updopp.ftg_monthly_programming_fee__c == 35.00);
   
   			
   			q.sbqq__primary__c = false;
   			update q;
   			
   			Opportunity emptyopp = [ Select id, of_televisions__c, ftg_monthly_Programming_fee__c from
   			            			Opportunity where Id = :updopp.id LIMIT 1 ];
   			            			
   			system.assert(emptyopp.of_televisions__c == null);
   		
   		
   		test.stopTest();
   		
   }

    /******************************************************************************************************
    ****************************CREATE SITE SURVEY TEST METHODS*********************************************
    *******************************************************************************************************/
/* NOT USED
    static testMethod void createSiteSurveySucess(){
        //create test data
        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest createSiteSurveySucess Test .  **********    START');
        
        //create test data
        List<Opportunity_Site_Survey_Update_Status__c> statusSettings = new List<Opportunity_Site_Survey_Update_Status__c>();
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='Schedule Survey'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='Scheduled'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='In Progress'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='On Hold'));
        
        
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, false).get(0);
        Opportunity opp1 = DataGenerator.createOpptys(acc, 2, true).get(0);
        Opportunity opp2 = DataGenerator.createOpptys(acc, 1, false).get(0);
       
        //set the fields ready for creation
        //create on insert
        opp.of_Rooms_Opportunity__c = 50;
        opp.CPO_Approved__c = true;
        opp.Type_of_Assessment__c = 'No Charge Desktop Review';
        opp.StageName = 'Site Survey Order Approved';
        
        //create on update
        opp1.of_Rooms_Opportunity__c= 50;
        opp1.CPO_Approved__c = true;
        opp1.Type_of_Assessment__c = 'No Charge Desktop Review';
        opp1.StageName = 'Desktop Review Required';
        
        //make sure they do not create two site surveys
        opp2.of_Rooms_Opportunity__c = 50;
        opp2.CPO_Approved__c = true;
        opp2.Type_of_Assessment__c = 'No Charge Desktop Review';
        opp2.StageName = 'Site Survey Order Approved';
        insert opp2;
        opp2.of_Rooms_Opportunity__c = 20;
        
        Test.startTest();
        insert opp;
        update opp1;
        update opp2;
        Test.stopTest();
        
        List<Site_Survey__c> sites = [SELECT id FROM Site_Survey__c];
        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest createSiteSurveySucess Test .  ********** sites size  '+sites.size());
        system.assertEquals(3, sites.size());
        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest createSiteSurveySucess Test .  **********    START');
   }
 */  
}