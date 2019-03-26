@isTest
public with sharing class AccountActivityListExtensionTest {
	/* */
	@isTest 
	static void testClassInstantiation() {
		AccountActivityListExtension ext;
		
		//AppConfig__c.getValues('Global').BlockTriggerProcessing__c
		AppConfig__c appConfig = new AppConfig__c();
		appConfig.Name='Global';
		appConfig.BlockTriggerProcessing__c = false;
		upsert appConfig;
		
		// Create running user
		User u = DataGenerator.createUsers(Definitions.PROFILE_HealthcareSales, 1, true)[0];
		
		System.runAs(u) {
			
			//Invalid Account
			Account acc;
			try{
				acc = (Account)DataGenerator.createSObjectWithDefaultValues('INVALID');
				System.assert(false, 'UNEXPECTED RESULT. EXPECTED ERROR.');
			} catch (Exception e) {
			}
			System.assertEquals(null,acc);
			
			
			// Create accounts
			Integer accountsToCreate = 2;
			List<Account> accountList = DataGenerator.createAccounts(accountsToCreate, true);
			System.assertNotEquals(null, accountList);
			System.assertEquals(accountsToCreate, accountList.size());
			
			accountList[0].Management_Group__c = accountList[0].Id;
			accountList[1].Management_Group__c = accountList[1].Id;
			
	
			// Test with valid account
			ext = new AccountActivityListExtension(new ApexPages.StandardController(accountList[0]));
			System.assertNotEquals(null, ext);
			//System.assertEquals(u.Id, accountList[0].OwnerId);
			
			CloneableInterface clone = ext.getCloneableInterface();
			System.assertNotEquals(null,clone);
			
			List<Sobject> sobj = ext.getCloneToItems();
			System.assertNotEquals(null,sobj);
			
			Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> mapItem =ext.getItemObjectFieldMap();
			System.assertNotEquals(null,mapItem);
			
			Sobject parent = ext.getParentObject();
			System.assertNotEquals(null,parent);
			
			Id who= ext.getWhoId();
			System.assertNotEquals(null,who);
		}
		
		
		
	}
	
}