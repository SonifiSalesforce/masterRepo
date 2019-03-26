@isTest


public with sharing class CaseSupportOfficeMemberTest {
	
	static testMethod void getTeamMembers()
    {
    	
		AppConfig__c appConfig = new AppConfig__c();
        appConfig.Name = 'Global';
        appConfig.Dispatch_Error__c = 'Dispatch Error';
        appConfig.Case_Comments_To_Include_On_Dispatch__c = 999;
        appConfig.Case_Activities_To_Include_On_Dispatch__c = 999; 
        appConfig.BlockTriggerProcessing__c = true;  //must turn off triggers to test exception handlers
        appConfig.CompanyUTCOffset__c = 1;
        upsert appConfig; 
        
         
        Account a = DataGenerator.createAccounts(1, true)[0];  //create a hotel account and insert it (true)
        Account suppAcc = DataGenerator.createAccounts(1, true)[0];  //create a support office account and insert it (true)
        Account acct = DataGenerator.createAccounts(1, true)[0];  //create an account with an MOL record type
        Account acct2 = DataGenerator.createAccounts(1, true)[0]; //create a second MOL account
        Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
        System.debug('**** /////// *****  SupportOffice Id = ' + supportOfficeId);
        suppAcc.RecordTypeId = supportOfficeId;  //update the record type of the support office account
        upsert suppAcc;
        Id molid = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('MOL').getRecordTypeId();
        System.debug('**** /////// *****  MOL Record Type Id = ' + molid);
        acct.RecordTypeId = molid;  //update the record type of the support office account
        upsert acct;
        acct2.RecordTypeId = molid;
        upsert acct2;
        
        
        LIST<User> userlist = new list<User>();
        userlist = DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 2, true); //create and insert new users
        Integer x = 0;
        for(User usr : userlist)
        {
           x = x + 1;
           SupportOfficeMember__c suppMem = new SupportOfficeMember__c();
           suppMem.User__c = usr.Id;
           suppMem.SupportOffice__c = suppAcc.Id;
           if(x <= 1)
              { suppMem.Role__c = 'Primary Engineer'; }
           else { suppMem.Role__c = 'On Call Tech'; }
           upsert suppMem;
         }
        
        a.Support_Office__c = suppAcc.Id;  //relate the support office to the hotel account now that there is a support team 
        upsert a;
        
        //create a case and insert it, then update some of the field values
        Case c = (Case)DataGenerator.createSObjectWithDefaultValues('Case');
        c.AccountId = a.Id;
        insert c;
        
        c.Status = 'Open';
        c.Dispatched__c = true;
        c.Support_Office__c = suppAcc.id;
        upsert c; 
        
        //create another case and relate it to the MOL account that has no support office
        Case c2 = (Case)DataGenerator.createSObjectWithDefaultValues('Case');
        c2.AccountId = acct.Id;
        insert c2;
        
        c2.Status = 'Open';
        //c2.Dispatched__c = true;
        upsert c2; 
        
        //create another hospitality account but do not link a support office to it
        //then create another case and link the new account to it.
        Account a2 = DataGenerator.createAccounts(1, true)[0];
        Case c3 = (Case)DataGenerator.createSObjectWithDefaultValues('Case');
        c3.AccountId = a2.Id;
        insert c3;
        c3.Status = 'Open';
        //c2.Dispatched__c = true;
        upsert c3; 
        
    	PageReference pr = Page.CaseSupportTeamMembers;
        pr.getParameters().put('id',c.id);
        Test.setCurrentPageReference(pr);
        Test.startTest();
        //positive test passing in valid case linked to account that has a support office
        CaseSupportTeamMembersExtension controller = new CaseSupportTeamMembersExtension (new ApexPages.StandardController(c));
        Boolean errorflag = controller.flagvalue();
        system.assert(errorflag == false);
        
        List<SupportOfficeMember__c> teamlist = new list<SupportOfficeMember__c>();
        teamlist = controller.supportTeamMembers;
        
        //negative test passing in case that is linked to an MOL account with no support office
        PageReference pr2 = Page.CaseSupportTeamMembers;
        pr2.getParameters().put('id', c2.id);
        Test.setCurrentPageReference(pr2);
        CaseSupportTeamMembersExtension controller2 = new CaseSupportTeamMembersExtension (new ApexPages.StandardController(c2));
        Boolean errorflag2 = controller2.flagvalue();
        system.assert(errorflag2 == true);
        
        //negative test passing in case that is linked to a hospitality account that has no support office
        PageReference pr3 = Page.CaseSupportTeamMembers;
        pr3.getParameters().put('id', c3.id);
        CaseSupportTeamMembersExtension controller3 = new CaseSupportTeamMembersExtension (new ApexPages.StandardController(c3));
        Boolean errorflag3 = controller3.flagvalue();
        system.assert(errorflag3 = true);
        
        
        Test.stopTest();
        
    }
    
            
}