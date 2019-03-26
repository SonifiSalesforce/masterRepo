@isTest
public with sharing class FlashNotificationExtensionTest {
	
	/* */
	@isTest 
	static void testClassInstantiation() {
		
		// Test instantiation with invalid Id
		FlashNotificationExtension ext ;
			
			// Create accounts
			Integer accountsToCreate = 1;
			List<Account> accountList = DataGenerator.createAccounts(accountsToCreate, true);
			System.assertNotEquals(null, accountList);
			System.assertEquals(accountsToCreate, accountList.size());
			
			//Invalid Case
			Case caseFl;
			try{
				caseFl = (Case)DataGenerator.createSObjectWithDefaultValues('INVALID');
				System.assert(false, 'UNEXPECTED RESULT. EXPECTED ERROR.');
			} catch (Exception e) {
			}
			System.assertEquals(null,caseFl);

			
			//Test with valid Case
			Integer flashToCreate = 10;
			
			List<Case> caseFlash = new List<Case>();
			for(Integer i=0;i<flashToCreate;i++){
				Case flash = new Case();
				flash.AccountId = accountList[0].Id;
				caseFlash.add(flash); 
			}
			upsert caseFlash;
						
			
				ext = new FlashNotificationExtension(new ApexPages.StandardController(caseFlash[0]));
				System.assertNotEquals(null, ext);
				
				//ext.flashNotifications = null;
				
				List<CustomFlashNotificationLogic.FlashNotification> flashList = ext.flashNotifications;
				//List<CustomFlashNotificationLogic.FlashNotification> flashList = CustomFlashNotificationLogic.GetFlashNotifications(accountList[0].Id);
				System.assertNotEquals(null,flashList);
			
		
	}
	
}