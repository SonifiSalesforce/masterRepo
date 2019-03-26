@isTest
public with sharing class NotesAndAttachmentsListControllerTest {
	
	@isTest static void testNotesAndAttachmentsList() {
		
		// Create Account
		Account acct = DataGenerator.createAccounts(1, true)[0];
		System.assertNotEquals(null, acct);
		
		// Create Notes
		Integer notesToCreate = 2;
		List<Note> noteList = DataGenerator.createNotes(acct, notesToCreate, true);
		System.assertNotEquals(null, noteList);
		System.assertEquals(notesToCreate, noteList.size());
		
		// Create Page, Extension and Component Controller
		PageReference pageRef = Page.NotesAndAttachments;
		Test.setCurrentPage(pageRef);
		AccountNotesAndAttachmentsExtension pageExt = new AccountNotesAndAttachmentsExtension(new ApexPages.StandardController(acct));
		NotesAndAttachmentsListController controller = new NotesAndAttachmentsListController();
		controller.cloneableInterfaceObject = pageExt;
		controller.showAllRecords = true;
		
		// Get records
		// NOTE We cannot actually get NoteAndAttachment records in a test series.
		// Rather than adding special code to only get Note records, we are asserting NULL here.
		List<NoteAndAttachment> notes = controller.getRecordList();
		System.assertEquals(null, notes);
	}
}