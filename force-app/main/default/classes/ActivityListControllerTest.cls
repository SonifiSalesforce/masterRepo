@isTest
public with sharing class ActivityListControllerTest {

	@isTest static void testActivityList() {
		
		// NOTE We cannot get ActivityHistory records in the test environment.  So, the test coverage
		// will fall short by that amount.  However, even without that coverage, we are currently able to get 80%+. 
		
		// Create Account
		Account acct = DataGenerator.createAccounts(1, true)[0];
		System.assertNotEquals(null, acct);
		
		// Create Tasks
		Integer tasksToCreate = 2;
		List<Task> taskList = DataGenerator.createTasks(acct, tasksToCreate, true);
		System.assertNotEquals(null, taskList);
		System.assertEquals(tasksToCreate, taskList.size());
		
		// Create Events
		Integer eventsToCreate = 2;
		List<Event> eventList = DataGenerator.createEvents(acct, eventsToCreate, true);
		System.assertNotEquals(null, eventList);
		System.assertEquals(eventsToCreate, eventList.size());
		
		// Create Page, Extension and Component Controller
		PageReference pageRef = Page.ActivityList;
		Test.setCurrentPage(pageRef);
		AccountActivityListExtension pageExt = new AccountActivityListExtension(new ApexPages.StandardController(acct));
		ActivityListController controller = new ActivityListController();
		controller.cloneableInterfaceObject = pageExt;
		controller.showAllRecords = true;
		
		// Get records
		List<ActivityListController.CustomActivity> activities = controller.getRecordList();
		System.assertNotEquals(null, activities);
		System.assertEquals(tasksToCreate + eventsToCreate, activities.size());
	}
}