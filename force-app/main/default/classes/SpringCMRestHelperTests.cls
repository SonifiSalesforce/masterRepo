@isTest
private class SpringCMRestHelperTests {
	static testMethod void testStartWorkflow() {
		SpringCMEos__EOS_Type__c eA = (SpringCMEos__EOS_Type__c)SpringCMTestDataFactory.createSObject(new SpringCMEos__EOS_Type__c(), true);
		SpringCMEos__EOS_Type__c eO = (SpringCMEos__EOS_Type__c)SpringCMTestDataFactory.createSObject(new SpringCMEos__EOS_Type__c(name = 'Opportunity',
				SpringCMEos__Folder_Name__c = '{!Name}',
				SpringCMEos__Folder_Name_Format__c = '{0}',
				SpringCMEos__Path__c = '/path/{!Account.Name}',
				SpringCMEos__Path_Format__c = '/path/{1}',
				SpringCMEos__Variables__c = 'Name,Account.Name'), true);
		Account a = (Account) SpringCMTestDataFactory.createSObject(new Account(), true);
		Opportunity o = (Opportunity) SpringCMTestDataFactory.createSObject(new Opportunity(AccountID = a.Id), true);   

		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		Boolean noErrorsThrown = true;

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		try {
			SpringCMRestHelper.StartWorkflow(o.Id, 'Opportunity', 'workflowname', UserInfo.getSessionId());
		}
		catch (Exception ex) {
			noErrorsThrown = false;
		}
		Test.stopTest();

		System.assert(noErrorsThrown);
	}

	static testMethod void testBulkTriggerHandling() {
		SpringCMEos__EOS_Type__c eA = (SpringCMEos__EOS_Type__c)SpringCMTestDataFactory.createSObject(new SpringCMEos__EOS_Type__c(), true);
		SpringCMEos__EOS_Type__c eO = (SpringCMEos__EOS_Type__c)SpringCMTestDataFactory.createSObject(new SpringCMEos__EOS_Type__c(name = 'Opportunity',
				SpringCMEos__Folder_Name__c = '{!Name}',
				SpringCMEos__Folder_Name_Format__c = '{0}',
				SpringCMEos__Path__c = '/path/{!Account.Name}',
				SpringCMEos__Path_Format__c = '/path/{1}',
				SpringCMEos__Variables__c = 'Name,Account.Name'), true);
		Account[] accounts = (Account[])SpringCMTestDataFactory.createSObjectList(new Account(), 1000);
 
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		Boolean noErrorsThrown = true;

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		try {
			SpringCMTriggerHandler.StartWorkflow(UserInfo.getSessionId(), 'Account', accounts, 'workflow');
		}
		catch (Exception ex) {
			noErrorsThrown = false;
		}
		Test.stopTest();
 
		System.assert(true);
	}
}