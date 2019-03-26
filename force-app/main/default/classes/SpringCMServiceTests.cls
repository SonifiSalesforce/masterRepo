@isTest
private class SpringCMServiceTests {

	static testMethod void testAPIUser() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService();
		SpringCMWorkflow workflow = new SpringCMWorkflow('Test Workflow', '<test />');

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		workflow = springcm.startWorkflow(workflow);
		Test.stopTest();

		System.assertEquals(workflow.Name,'Test Workflow');
		}

	static testMethod void testStoreDocument() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		Opportunity storageObject = new Opportunity(Name='Test Opp',StageName='Prospecting',CloseDate=Date.newInstance(2012,12,1));
		Blob documentToStore = Blob.valueOf('I am a blob');
		String documentName = 'Testing.docx';
		Map<String, Blob> documentsToStore = new Map<String, Blob>();
		documentsToStore.put(documentName, documentToStore);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		List<SpringCMDocument> documents = springcm.storeDocuments(storageObject, documentsToStore);
		Test.stopTest();

		System.assertEquals(documents.get(0).Name, 'Testing.docx');
		System.assertEquals(documents.get(0).Href, 'https://apiuatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000');
		}

	static testMethod void testUploadDocuments() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMFolder folder = new SpringCMFolder();
		folder.Name = 'Test Folder';
		folder.CreateDocumentHref = 'https://apiuploaduatna11.springcm.com/v201411/folders/00000000-0000-0000-0000-000000000000/documents{?name}';
		Blob documentToStore = Blob.valueOf('I am a blob');
		String documentName = 'Testing.docx';
		Map<String, Blob> documentsToStore = new Map<String, Blob>();
		documentsToStore.put(documentName, documentToStore);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		List<SpringCMDocument> documents = springcm.uploadDocuments(folder, documentsToStore);
		Test.stopTest();

		System.assertEquals(documents.get(0).Name, 'Testing.docx');
		System.assertEquals(documents.get(0).Href, 'https://apiuatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000');
		}

	static testMethod void testUploadDocumentsNoName() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMFolder folder = new SpringCMFolder();
		folder.Name = 'Test Folder';
		folder.CreateDocumentHref = 'https://testdocumentuploadfolder{?name}';
		Blob documentToStore = Blob.valueOf('I am a blob');
		String documentName = '';
		Map<String, Blob> documentsToStore = new Map<String, Blob>();
		documentsToStore.put(documentName, documentToStore);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);

		try {
			List<SpringCMDocument> documents = springcm.uploadDocuments(folder, documentsToStore);
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage().contains('No document name provided');
		}
		Test.stopTest();
		System.Assert(correctExceptionReturned);
		}

	static testMethod void testUploadDocumentsNoDocument() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMFolder folder = new SpringCMFolder();
		folder.Name = 'Test Folder';
		folder.CreateDocumentHref = 'https://testdocumentuploadfolder{?name}';
		Blob documentToStore = Blob.valueOf('');
		String documentName = 'Testing.docx';
		Map<String, Blob> documentsToStore = new Map<String, Blob>();
		documentsToStore.put(documentName, documentToStore);

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);

		try {
			List<SpringCMDocument> documents = springcm.uploadDocuments(folder, documentsToStore);
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage().contains('No document or zero byte document provided');
		}
		Test.stopTest();
		System.Assert(correctExceptionReturned);
		}

	static testMethod void testUploadDocumentsBulk() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMFolder folder = new SpringCMFolder();
		folder.Name = 'Test Folder';
		folder.CreateDocumentHref = 'https://apiuploaduatna11.springcm.com/v201411/folders/00000000-0000-0000-0000-000000000000/documents{?name}';

		Blob documentToStore = Blob.valueOf('I am a blob');
		String documentName = 'Testing';
		String documentExt = '.docx';
		Map<String, Blob> documentsToStore = new Map<String, Blob>();
		Integer i = 1, max = 100;
		while (i < max) {
			documentsToStore.put(documentName + i + documentExt, documentToStore);
			i++;
		}

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		List<SpringCMDocument> documents = springcm.uploadDocuments(folder, documentsToStore);
		Test.stopTest();

		System.assertEquals(documents.get(0).Name,'Testing.docx');
		System.assertEquals(documents.get(0).Href,'https://apiuatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000');
		}

	static testMethod void testFindDocumentByPath() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		SpringCMDocument document = springcm.findDocumentByPath('documentPath', 'expansion');
		Test.stopTest();

		System.assertEquals(document.Name,'Testing.docx');
		System.assertEquals(document.Href,'https://apiuatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000');
		}

	static testMethod void testFindDocumentByPathNoPath() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		try {
			SpringCMDocument document = springcm.findDocumentByPath(null, null);
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage() == 'No document path provided';
		}
		Test.stopTest();

		System.assert(correctExceptionReturned);
		}

	static testMethod void testDownloadDocument() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMDocument document = new SpringCMDocument();
		document.DownloadDocumentHref = 'https://apidownloaduatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		Blob documentBlob = springcm.downloadDocument(document, null, null, null);
		Test.stopTest();

		System.assertEquals(documentBlob.toString(), 'This is a blob'); 
		}

	static testMethod void testDownloadDocumentInvalidHref() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMDocument document = new SpringCMDocument();
		document.DownloadDocumentHref = '';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);

		try {
			Blob documentBlob = springcm.downloadDocument(document, null, null, null);
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage().contains('Document is not valid, missing DownloadDocumentHref, please perform find on folder or document to proceed');
		}
		Test.stopTest();

		System.Assert(correctExceptionReturned);
		}

	static testMethod void testDownloadDocumentInvalidDocumentType() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMDocument document = new SpringCMDocument();
		document.DownloadDocumentHref = 'https://apidownloaduatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);

		try {
			Blob documentBlob = springcm.downloadDocument(document, 'null', null, null);
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage().contains('Valid Document Types are: application/pdf|text/plain|image/png');
		}
		Test.stopTest();

		System.Assert(correctExceptionReturned);
		}

	static testMethod void testDownloadDocumentInvalidZoom() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMDocument document = new SpringCMDocument();
		document.DownloadDocumentHref = 'https://apidownloaduatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);

		try {
			Blob documentBlob = springcm.downloadDocument(document, 'image/png', 'null', null);
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage().contains('Valid zoom options are: thumbnail|50|75|100|125|150|200');
		}
		Test.stopTest();

		System.Assert(correctExceptionReturned);
		}

	static testMethod void testDownloadDocumentInvalidPage() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMDocument document = new SpringCMDocument();
		document.DownloadDocumentHref = 'https://apidownloaduatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);

		try {
			Blob documentBlob = springcm.downloadDocument(document, 'image/png', null, 0);
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage().contains('Page requested outside of document page range');
		}
		Test.stopTest();

		System.Assert(correctExceptionReturned);
		}

	static testMethod void testGetNativeRevision() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMDocument document = new SpringCMDocument();
		document.DownloadDocumentHref = 'https://apidownloaduatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		Blob documentBlob = springcm.getNativeRevision(document);
		Test.stopTest();

		System.assertEquals(documentBlob.toString(), 'This is a blob'); 
		}

	static testMethod void testGetPDFRevision() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMDocument document = new SpringCMDocument();
		document.DownloadDocumentHref = 'https://apidownloaduatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		Blob documentBlob = springcm.getPDFRevision(document);
		Test.stopTest();

		System.assertEquals(documentBlob.toString(), 'This is a blob'); 
		}

	static testMethod void testGetOCRText() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMDocument document = new SpringCMDocument();
		document.DownloadDocumentHref = 'https://apidownloaduatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		Blob documentBlob = springcm.getOCRText(document);
		Test.stopTest();

		System.assertEquals(documentBlob.toString(), 'This is a blob'); 
		}

	static testMethod void testGetPNGImage() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMDocument document = new SpringCMDocument();
		document.DownloadDocumentHref = 'https://apidownloaduatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		Blob documentBlob = springcm.getPNGImage(document, null, null);
		Test.stopTest();

		System.assertEquals(documentBlob.toString(), 'This is a blob'); 
		}

	static testMethod void testGetThumbnail() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMDocument document = new SpringCMDocument();
		document.DownloadDocumentHref = 'https://apidownloaduatna11.springcm.com/v201411/documents/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		Blob documentBlob = springcm.getThumbnail(document);
		Test.stopTest();

		System.assertEquals(documentBlob.toString(), 'This is a blob'); 
		}

	static testMethod void testCreateSubFolderInEos() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		Opportunity storageObject = new Opportunity(Name='Test Opp',StageName='Prospecting',CloseDate=Date.newInstance(2012,12,1));

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		SpringCMFolder folder = springcm.createSubFolderInEos(storageObject, 'subFolderName');
		Test.stopTest();

		System.assertEquals(folder.Name,'Testing');
		System.assertEquals(folder.Href,'https://apiuatna11.springcm.com/v201411/folders/00000000-0000-0000-0000-000000000000');
		}

	static testMethod void testFindOrCreateEosFolder() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		SpringCMFolder folder = springcm.findOrCreateEosFolder('Id', 'Opportunity');
		Test.stopTest();

		System.assertEquals(folder.Name,'Testing');
		System.assertEquals(folder.Href,'https://apiuatna11.springcm.com/v201411/folders/00000000-0000-0000-0000-000000000000');
		}

	static testMethod void testFindFolderByPath() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		SpringCMFolder folder = springcm.findFolderByPath('folderPath', null);
		Test.stopTest();

		System.assertEquals(folder.Name,'Testing');
		System.assertEquals(folder.Href,'https://apiuatna11.springcm.com/v201411/folders/00000000-0000-0000-0000-000000000000');
		}

	static testMethod void testFindFolderByPathNoPath() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		try {
			SpringCMFolder folder = springcm.findFolderByPath('', 'expansion');
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage() == 'No folder path provided';
		}
		Test.stopTest();

		System.assert(correctExceptionReturned);
		}

	static testMethod void testCreateFolder() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMFolder folder = new SpringCMFolder();
		folder.Href = 'https://apiuatna11.springcm.com/v201411/folders/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		folder = springcm.createFolder('name', folder);
		Test.stopTest();

		System.assertEquals(folder.Name,'Testing');
		System.assertEquals(folder.Href,'https://apiuatna11.springcm.com/v201411/folders/00000000-0000-0000-0000-000000000000');
		}

	static testMethod void testCreateFolderNoName() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMFolder folder = new SpringCMFolder();
		folder.Href = 'https://apiuatna11.springcm.com/v201411/folders/00000000-0000-0000-0000-000000000000';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		try {
			folder = springcm.createFolder(null, folder);
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage() == 'No folder name provided';
		}
		Test.stopTest();

		System.assert(correctExceptionReturned);
		}

	static testMethod void testCreateFolderInvalidParent() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMFolder folder = new SpringCMFolder();
		folder.Href = '';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		try {
			folder = springcm.createFolder('name', folder);
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage() == 'Not a valid parent folder provided';
		}
		Test.stopTest();

		System.assert(correctExceptionReturned);
		}

	static testMethod void testStartWorkflow() {
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());
		SpringCMWorkflow workflow = new SpringCMWorkflow('Test Workflow', '<test />');

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		workflow = springcm.startWorkflow(workflow);
		Test.stopTest();

		System.assertEquals(workflow.Name,'Test Workflow');
		}

	static testMethod void testStartWorkflowNoName() {
		Boolean correctExceptionReturned = false;
		SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
		SpringCMService springcm = new SpringCMService(UserInfo.getSessionId());

		SpringCMWorkflow workflow = new SpringCMWorkflow(null, '<test />');

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, mock);
		try {
			workflow = springcm.startWorkflow(workflow);
		}
		catch(Exception e) {
			correctExceptionReturned = e.getMessage() == 'No workflow name provided';
		}
		Test.stopTest();

		System.assert(correctExceptionReturned);
		}
	}