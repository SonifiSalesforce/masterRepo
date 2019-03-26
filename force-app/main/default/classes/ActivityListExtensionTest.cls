@isTest
public class ActivityListExtensionTest {
	
	@isTest static void testActivityListRedirect() {
		
		// Create Account
		Account acct = DataGenerator.createAccounts(1, true)[0];
		System.assertNotEquals(null, acct);
		
		// Create page and set account id
		PageReference pageRef = Page.ActivityList;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('id', acct.Id);
		
		// Create page extension 
		ActivityListExtension pageExt = new ActivityListExtension();
		
		// Check for redirected page
		PageReference newPage = pageExt.checkRedirect();
	}
}