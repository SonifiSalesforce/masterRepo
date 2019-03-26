@isTest
public with sharing class OpptyNotesAndAttachmentsExtensionTest {
	
	@isTest
	static void testClassInstantiation() {
		OpportunityNotesAndAttachmentsExtension oppExt;
		List<Opportunity> oppr;

			//Invalid Account
			Account acc;
			try{
				acc = (Account)DataGenerator.createSObjectWithDefaultValues('INVALID');
				System.assert(false, 'UNEXPECTED RESULT. EXPECTED ERROR.');
			} catch (Exception e) {
			}
			System.assertEquals(null,acc);
			
			
			//Invalid Opportunity
			Opportunity op;
			try{
				op = (Opportunity)DataGenerator.createSObjectWithDefaultValues('INVALID');
				System.assert(false, 'UNEXPECTED RESULT. EXPECTED ERROR.');
			} catch (Exception e) {
			}
			System.assertEquals(null,op);		
				
		// Create accounts
			Integer accountsToCreate = 2;
			List<Account> accountList = DataGenerator.createAccounts(accountsToCreate, true);
			System.assertNotEquals(null, accountList);
			//System.assertEquals(accountsToCreate, accountList.size());
			for (Integer i = 1; i < accountsToCreate; i++) {
				oppr =DataGenerator.createOpptys(accountList[i], accountsToCreate, true);
				
				oppr[i].AccountId = accountList[i].Id;
				System.assertNotEquals(null,oppr[i].AccountId);
				
				accountList[i].Management_Group__c = accountList[0].Id;
			}
		
		
		
		// Test with valid account
		oppExt = new OpportunityNotesAndAttachmentsExtension(new ApexPages.StandardController(oppr[0]));
		System.assertNotEquals(null, oppExt);
		
		CloneableInterface clone = oppExt.getCloneableInterface();
		System.assertNotEquals(null,clone);
		
		List<Sobject> sobj= oppExt.getCloneToItems();
		System.assertNotEquals(null,sobj);
		
		Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> mapItem = oppExt.getItemObjectFieldMap();
		System.assertNotEquals(null,mapItem);
		
		Id who =oppExt.getWhoId();
		System.assertNotEquals(null,who);
			
		Sobject parent= oppExt.getParentObject();
		System.assertNotEquals(null,parent);
		
		
	}
	
}