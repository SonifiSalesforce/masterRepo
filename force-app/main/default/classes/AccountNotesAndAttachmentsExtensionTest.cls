@isTest
public with sharing class AccountNotesAndAttachmentsExtensionTest {

	@isTest 
	static void testClassInstantiation() {
		AccountNotesAndAttachmentsExtension acc;
		
		// Create accounts
			Integer accountsToCreate = 2;
			List<Account> accountList = DataGenerator.createAccounts(1, true);
			System.assertNotEquals(null, accountList);
			//System.assertEquals(accountsToCreate, accountList.size());
			
		// Built acct hierarchy
		accountList[0].Management_Group__c = accountList[0].Id;
		
		// Test with valid account
		acc = new AccountNotesAndAttachmentsExtension(new ApexPages.StandardController(accountList[0]));
		System.assertNotEquals(null, acc);
		
		CloneableInterface clone = acc.getCloneableInterface();
		System.assertNotEquals(null,clone);
		
		List<Sobject> sobj= acc.getCloneToItems();
		System.assertNotEquals(null,sobj);
		
		Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> mapItem = acc.getItemObjectFieldMap();
		System.assertNotEquals(null,mapItem);
		
		Id who =acc.getWhoId();
		System.assertNotEquals(null,who);
			
		Sobject parent= acc.getParentObject();
		System.assertNotEquals(null,parent);
		
		
	}
}