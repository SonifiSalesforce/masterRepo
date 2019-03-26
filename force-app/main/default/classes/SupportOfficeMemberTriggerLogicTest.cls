@isTest
public with sharing class SupportOfficeMemberTriggerLogicTest {
    @isTest 
    static void testSupportOfficeMemberTriggerLogic() { 
        
        AppConfig__c appConfig = new AppConfig__c();
        appConfig.Name = 'Global';
        appConfig.Dispatch_Error__c = 'Dispatch Error';
        appConfig.Case_Comments_To_Include_On_Dispatch__c = 999;
        appConfig.Case_Activities_To_Include_On_Dispatch__c = 999; 
        appConfig.BlockTriggerProcessing__c = false;
        appConfig.CompanyUTCOffset__c = 1;
        upsert appConfig; 
        
        Account a = DataGenerator.createAccounts(1, true)[0];
        Account suppAcc = DataGenerator.createAccounts(1, true)[0];
        Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
        System.debug('**** /////// *****  SupportOffice Id = ' + supportOfficeId);
        suppAcc.RecordTypeId = supportOfficeId;
        upsert suppAcc;
        
        User u = DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 1, true)[0];
        SupportOfficeMember__c suppMem = new SupportOfficeMember__c();
        suppMem.User__c = u.Id;
        suppMem.SupportOffice__c = suppAcc.Id;
        suppMem.Role__c = 'Primary Engineer';
        upsert suppMem;
        
        Map<Id, SupportOfficeMember__c> memberMap = new Map<Id, SupportOfficeMember__c>();
        memberMap.put(suppAcc.Id,suppMem);
        
        a.Support_Office__c = suppAcc.Id; 
        upsert a;
        
        
        List<Id> supportOfficeIds = new List<id>();
        List<Case> caseList = DataGenerator.createCases(a.Id, 2, true);
        
        for(Case cases : caseList){
        cases.Status = 'Open';
        cases.Dispatched__c = true;
        cases.Support_Office__c = suppAcc.Id;
        supportOfficeIds.add(suppAcc.Id);
        }
        System.debug('caseList is : '+caseList);
        upsert caseList;
        
        Map<id,Account> supTeamMap =new  Map<id,Account>();
        supTeamMap.put(a.id,a);
        
        Map<Id, List<Case>> caseTeamMap = new Map<Id, List<Case>>();
        caseTeamMap.put(suppAcc.Id,caseList); 
        
        System.runAs(u){
            SupportOfficeMemberTriggerLogic.validateMemberRemoval(memberMap);
            SupportOfficeMemberTriggerLogic.updateMemberCases(memberMap);
        }
        
        //User user2 = DataGenerator.createUsers(Definitions.PROFILE_HealthcareSales, 1, true)[0];
        //User user2 = new User();
        
        
        SupportOfficeMember__c suppMemNew = new SupportOfficeMember__c();
        //suppMemNew.User__c = Userinfo.getUserId();]
        suppMemNew.User__c = u.Id;
        suppMemNew.SupportOffice__c = suppAcc.Id;
        suppMemNew.Role__c = 'On Call Tech'; 
        insert suppMemNew; 
        delete suppMemNew;
        
    }
    @isTest static void testinsertSupportOfficeMember(){
        
        AppConfig__c appConfig = new AppConfig__c();
        appConfig.Name = 'Global';
        appConfig.Dispatch_Error__c = 'Dispatch Error';
        appConfig.Case_Comments_To_Include_On_Dispatch__c = 999;
        appConfig.Case_Activities_To_Include_On_Dispatch__c = 999; 
        appConfig.BlockTriggerProcessing__c = false;
        appConfig.CompanyUTCOffset__c = 1;
        upsert appConfig; 
        
        Account suppAcc = DataGenerator.createAccounts(1, true)[0];
        Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
        System.debug('**** /////// *****  SupportOffice Id = ' + supportOfficeId);
        suppAcc.RecordTypeId = supportOfficeId;
        upsert suppAcc;
        
        SupportOfficeMember__c suppMemNew = new SupportOfficeMember__c();
        //suppMemNew.User__c = Userinfo.getUserId();]
        suppMemNew.User__c = Userinfo.getUserId();
        suppMemNew.SupportOffice__c = suppAcc.Id;
        suppMemNew.Role__c = 'On Call Tech'; 
        upsert suppMemNew;
        suppMemNew.Role__c ='Primary Engineer';
        upsert suppMemNew;
        
        SupportOfficeMember__c suppOffMem = [select Id,Role__c from SupportOfficeMember__c where User__c =: Userinfo.getUserId() ];
        System.assertNotEquals(null,suppOffMem);
        
    }
}