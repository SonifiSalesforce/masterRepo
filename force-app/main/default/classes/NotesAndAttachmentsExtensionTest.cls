@isTest
public class NotesAndAttachmentsExtensionTest {
	
	@isTest static void testNotesAndAttachmentsRedirect() {
		
		// Create Account
		Account acct = DataGenerator.createAccounts(1, true)[0];
		System.assertNotEquals(null, acct);
		
		// Create page and set account id
		PageReference pageRef = Page.NotesAndAttachments;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('id', acct.Id);
		
		// Create page extension 
		NotesAndAttachmentsExtension pageExt = new NotesAndAttachmentsExtension();
		
		// Check for redirected page
		PageReference newPage = pageExt.checkRedirect();
	}
}