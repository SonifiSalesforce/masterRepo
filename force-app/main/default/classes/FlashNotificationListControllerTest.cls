@isTest
public with sharing class FlashNotificationListControllerTest {
	
	/* */
	@isTest 
	static void testClassInstantiation() {
		
		// Test instantiation with invalid Id
		FlashNotificationListController ctrl ;
			
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
			Integer flashToCreate = 250;
			
			List<Case> caseFlash = new List<Case>();
			for(Integer i=0;i<flashToCreate;i++){
				Case flash = new Case();
				flash.AccountId = accountList[0].Id;
				caseFlash.add(flash); 
			}
			upsert caseFlash;
						
			
				ctrl = new FlashNotificationListController();
				ctrl.theAccountId = caseFlash[0].AccountId;
				System.assertNotEquals(null, ctrl);
				
				//ctrl.flashNotifications = null;
				
				List<CustomFlashNotificationLogic.FlashNotification> flashList = ctrl.flashNotifications;
				//List<CustomFlashNotificationLogic.FlashNotification> flashList = CustomFlashNotificationLogic.GetFlashNotifications(accountList[0].Id);
				System.assertNotEquals(null,flashList);
			
		
	}
	
}