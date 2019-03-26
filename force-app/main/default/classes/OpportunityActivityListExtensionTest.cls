@isTest
public class OpportunityActivityListExtensionTest {
	
	@isTest static void testOpptyActivityList() {
		
		// Create running user
		User u = DataGenerator.createUsers(Definitions.PROFILE_HealthcareSales, 1, true)[0];
		System.assertNotEquals(null, u);
		
		// Create Account
		Account acct = DataGenerator.createAccounts(1, true)[0];
		System.assertNotEquals(null, acct);
		
		// Create Opportunity
		Opportunity oppty = DataGenerator.createOpptys(acct, 1, true)[0];
		oppty.OwnerId = u.Id;
		oppty.Name = 'Test oppty';
		upsert oppty;
		System.assertNotEquals(null, oppty);
				
		// Create Tasks
		Integer tasksToCreate = 2;
		List<Task> taskList = DataGenerator.createTasks(oppty, tasksToCreate, true);
		System.assertNotEquals(null, taskList);
		System.assertEquals(tasksToCreate, taskList.size());
		
		// Create Events
		Integer eventsToCreate = 2;
		List<Event> eventList = DataGenerator.createEvents(oppty, eventsToCreate, true);
		System.assertNotEquals(null, eventList);
		System.assertEquals(eventsToCreate, eventList.size());
		
		System.runAs(u) {
			
			// Create page
			ApexPages.PageReference pageRef = Page.OpportunityActivityList;
			Test.setCurrentPage(pageRef); 
			
			// Create invalid page extension
			OpportunityActivityListExtension ext = new OpportunityActivityListExtension(null);
			System.assertNotEquals(null, ext);
			
			// Create page extension
			ext = new OpportunityActivityListExtension(new ApexPages.StandardController(oppty));
			System.assertNotEquals(null, ext);
			
			// Set page parameters and recreate class
			ApexPages.currentPage().getParameters().put('showAll', 'true');
			
			// Create page extension
			ext = new OpportunityActivityListExtension(new ApexPages.StandardController(oppty));
			System.assertNotEquals(null, ext);
			
			List<Opportunity> oppList = [
				SELECT Id, Name, OwnerId, AccountId,
					   Account.Management_Group__c
				FROM Opportunity WHERE Id = :oppty.Id
			];
			System.debug('oppList is : '+oppList);
			// Assertions
			System.assertNotEquals(null, ext.getCloneableInterface());
			System.assertNotEquals(null, ext.getParentObject());
			System.assertEquals(oppty.Id, ext.getParentObject().Id);
			System.assertNotEquals(null, ext.getWhoId());
			System.assertNotEquals(null, ext.getCloneToItems());
			System.assertNotEquals(null, ext.getItemObjectFieldMap());
		}			
	}
}