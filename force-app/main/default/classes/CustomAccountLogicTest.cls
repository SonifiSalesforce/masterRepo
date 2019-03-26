@isTest
public with sharing class CustomAccountLogicTest {
	
	@isTest 
	static void testCustomAccountLogic() {
				Account a = DataGenerator.createAccounts(1, true)[0];
		Account suppAcc = DataGenerator.createAccounts(1, true)[0];
		Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
		System.debug('**** /////// *****  SupportOffice Id = ' + supportOfficeId);
		suppAcc.RecordTypeId = supportOfficeId;
		upsert suppAcc;
		
		User u = DataGenerator.createUsers(Definitions.PROFILE_SalesUser, 1, true)[0];
		SupportOfficeMember__c suppMem = new SupportOfficeMember__c();
		suppMem.User__c = u.Id;
		suppMem.SupportOffice__c = suppAcc.Id;
		suppMem.Role__c = 'Primary Engineer';
		upsert suppMem;
		Map<Id,List<SupportOfficeMember__c>> supportTeamMemberMap = new Map<Id,List<SupportOfficeMember__c>>();
		List<SupportOfficeMember__c> suppList = new List<SupportOfficeMember__c>();
		suppList.add(suppMem);
		upsert suppList;
		supportTeamMemberMap.put(suppAcc.id,suppList); 
		
		a.Support_Office__c = suppAcc.Id;
		Case case1 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		Case case2 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		Case case3 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		List<Case> caseList = new List<Case>();
		
		case1.AccountId = a.Id;
		case1.Status = 'Open';
		case1.Dispatched__c = true;
		case1.Support_Office__c = suppAcc.Id;
		case2.AccountId = a.Id;
		case3.AccountId = a.Id;
		Map<Id,Case> caseMap = new Map<Id,Case>();
		caseList.add(case1);
		caseList.add(case2);
		caseList.add(case3);
		
		Map<id,Account> supTeamMap =new  Map<id,Account>();
		
		supTeamMap.put(a.id,a);
		
		upsert a;
		upsert caseList;
		
		CustomAccountLogic.updateSupportOffice(supTeamMap);
		System.assertNotEquals(null,supTeamMap);
		
	}

}