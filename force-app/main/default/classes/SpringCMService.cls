public class SpringCMService {

	private final String seperator = '/';
	private final String version = seperator + 'v201411';
	private final String documentsServiceURL = version + seperator + 'documents';
	private final String foldersServiceURL = version + seperator + 'folders';
	private final String workflowsServiceURL = version + seperator + 'workflows';
	public String apiBaseUrl;

	private SpringCMApiManager springcmApi;

	/** Default constructor, initializes SpringCM Authentication manager with api user
	 *      authentication enabled
	 *
	 *  @param N/A
	 *  @returns N/A
	 *  @throws QueryException - SpringCMApiEnvironment metadata was not properly configured
	 */
	public SpringCMService() {
		springcmApi = new SpringCMApiManager(false, null);
		apiBaseUrl = springcmApi.ApiBaseUrl;
		}

	/** Constructor, initializes SpringCM Authentication manager with user submission for
	 *      authentication mode
	 *
	 *  @param {Boolean} usersessionauth - Toggle authentication between User Session and API User
	 *  @returns N/A
	 *  @throws QueryException - SpringCMApiEnvironment metadata was not properly configured
	 */
	public SpringCMService(String session) {
		springcmApi = new SpringCMApiManager(session != null, session);
		apiBaseUrl = springcmApi.ApiBaseUrl;
		} 

	/* DOCUMENT */
	/** Place 1 or many documents within the External Object Storage (EOS) folder connected to a
	 *      Salesforce Object
	 *
	 *  @param {SObject} storageObject - Salesforce Object that is connected to a SpringCM Folder
	 *      (EOS)
	 *  @param {Map<String, Blob>} documentsToStore - Map of document names and blob
	 *      representation of document to be stored in SpringCM
	 *  @returns {List<SpringCMDocument>} - List of SpringCMDocument objects representing those
	 *      documents requested to be uploaded
	 *  @throws SpringCMException - An error validating file name is missing
	 *  @throws SpringCMException - An error validating no file content was provided
	 *  @throws SpringCMException - An error validating the file is too large for Salesforce to process
	 *  @throws SpringCMException - An error during the request (i.e. network related, SpringCM
	 *      validation such as folder name is duplicate with duplicates turned off, etc.)
	 */
	public List<SpringCMDocument> storeDocuments(SObject storageObject, Map<String, Blob> documentsToStore) {
		String storageObjectId = (String)storageObject.get('Id');
		String storageObjectType = String.valueOf(storageObject.getSObjectType());
		System.debug('storeDocument called for object type: '+storageObjectId+', object type'+storageObjectType);

		SpringCMFolder folder = findOrCreateEosFolder(storageObjectId, storageObjectType);
		if (folder == null) return null;
		List<SpringCMDocument> documents = uploadDocuments(folder, documentsToStore);
		return documents;
		}

	/** Upload 1 or many documents within a SpringCM Folder
	 *
	 *  @param {SpringCMFolder} folder - SpringCM Folder to store document
	 *  @param {Map<String, Blob>} documentsToStore - Map of document names and blob
	 *      representation of document to be stored in SpringCM
	 *  @returns {List<SpringCMDocument>} - List of SpringCMDocument objects representing those
	 *      documents requested to be uploaded
	 *  @throws SpringCMException - An error validating file name is missing
	 *  @throws SpringCMException - An error validating no file content was provided
	 *  @throws SpringCMException - An error validating the file is too large for Salesforce to process
	 *  @throws SpringCMException - An error during the request (i.e. network related, SpringCM
	 *      validation such as folder name is duplicate with duplicates turned off, etc.)
	 */
	public List<SpringCMDocument> uploadDocuments(SpringCMFolder folder, Map<String, Blob> documentsToStore) {
		if (documentsToStore.isEmpty()) return null;

		System.debug('uploadDocuments called for folder:' + folder.CreateDocumentHref);
		String endpoint = folder.CreateDocumentHref.replace('{?name}', '');

		String boundary = '----------------------------741e90d31eff';
		String footer = '--' + boundary + '--';

		String attachmentsStr = '';
		String lastPrepend = '';
		for (String documentName : documentsToStore.keySet()) {
			Blob fileBlob = documentsToStore.get(documentName);
			if (String.IsBlank(documentName))
				throw new SpringCMException('No document name provided');
			if (fileBlob.size() <= 0)
				throw new SpringCMException('No document or zero byte document provided');
			if (fileBlob.size() > 5242880)
				throw new SpringCMException('Document provided too large for Salesforce upload');
			String fHeader = lastPrepend + '--' + boundary + '\r\n';
			fHeader += String.format('Content-Disposition: form-data; name="files[{0}]"; filename="{0}"\r\nContent-Type: application/octet-stream',
					new String[] { documentName });
			String fHeaderEncoded = EncodingUtil.base64Encode(Blob.valueOf(fHeader + '\r\n\r\n'));
			while (fHeaderEncoded.endsWith('=')) {
				fHeader += ' ';
				fHeaderEncoded = EncodingUtil.base64Encode(Blob.valueOf(fHeader + '\r\n\r\n'));
				}
			String fBodyEncoded = EncodingUtil.base64Encode(fileBlob);
			String last4Bytes = fBodyEncoded.substring(fBodyEncoded.length() - 4, fBodyEncoded.length());
			if (last4Bytes.endsWith('==')) {
				last4Bytes = last4Bytes.substring(0, 2) + '0K';
				fBodyEncoded = fBodyEncoded.substring(0, fBodyEncoded.length() - 4) + last4Bytes;
				lastPrepend = '';
				}
			else if (last4Bytes.endsWith('=')) {
				last4Bytes = last4Bytes.substring(0, 3) + 'N';
				fBodyEncoded = fBodyEncoded.substring(0, fBodyEncoded.length() - 4) + last4Bytes;
				lastPrepend = '\n';
				}
			else {
				lastPrepend = '\r\n';
				}
			attachmentsStr += fHeaderEncoded + fBodyEncoded;
			}
		footer = lastPrepend + footer;

		String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));

		Blob bodyBlob = EncodingUtil.base64Decode(attachmentsStr + footerEncoded);
		String responseBody = springcmApi.postBlob(bodyBlob, endpoint, String.format('multipart/form-data; boundary={0}', new String[] { boundary }));
		if (responseBody == null) return null;
		responseBody = !responseBody.startsWith('[') ? String.format('[{0}]', new String[] { responseBody }) : responseBody;
		List<SpringCMDocument> documents = (List<SpringCMDocument>)JSON.deserialize(fixPrefixResponseKeywords(responseBody), Type.forName('List<SpringCMDocument>'));
		return documents;
		}

	/** Locate a document within SpringCM using its relative path
	 *
	 *  @param {String} documentPath - relative (to root folder) path to document
	 *  @param {String} expansion - 
	 */
	public SpringCMDocument findDocumentByPath(String documentPath, String expansion) {
		if (String.IsBlank(documentPath)) throw new SpringCMException('No document path provided');

		expansion = String.isNotBlank(expansion)
				? (expansion.startsWithIgnoreCase('&expand=')
					? ''
					: '&expand=') + expansion
				: '';
		String responseBody = springcmApi.get(apiBaseUrl + documentsServiceURL + '?Path=' + EncodingUtil.urlEncode(documentPath, 'UTF-8') + expansion);
		if (responseBody == null) return null;
		SpringCMDocument document = (SpringCMDocument)JSON.deserialize(fixPrefixResponseKeywords(responseBody), Type.forName('SpringCMDocument'));
		return document;
		}

	public Blob downloadDocument(SpringCMDocument document, String documentType, String zoom, Integer page) {
		if (String.isBlank(document.DownloadDocumentHref))
			throw new SpringCMException('Document is not valid, missing DownloadDocumentHref, please perform find on folder or document to proceed');
		if (String.isNotBlank(documentType) && 'application/pdf|text/plain|image/png'.indexOf(documentType) < 0)
			throw new SpringCMException('Valid Document Types are: application/pdf|text/plain|image/png');
		if (String.isNotBlank(documentType) && documentType.equals('image/png') && page != null && (document.PageCount < page || page == 0))
			throw new SpringCMException('Page requested outside of document page range');
		if (String.isNotBlank(documentType) && documentType.equals('image/png') && String.isNotBlank(zoom) && 'thumbnail|50|75|100|125|150|200'.indexOf(zoom) < 0)
			throw new SpringCMException('Valid zoom options are: thumbnail|50|75|100|125|150|200');

		System.debug('downloadDocument called for document:' + document.DownloadDocumentHref);
		String endpoint = document.DownloadDocumentHref +
				(String.isBlank(zoom) ? '' : '?zoom=' + zoom) +
				(page == null ? '' :
					(String.isBlank(zoom) ? '?' : '&') +
				'page=' + page);
		Blob responseBody = springcmApi.getBlob(endpoint, documentType);
		if (responseBody == null) return null;
		return responseBody;
		}

	public Blob getNativeRevision(SpringCMDocument document) {
		return downloadDocument(document, null, null, null);
		}

	public Blob getPDFRevision(SpringCMDocument document) {
		return downloadDocument(document, 'application/pdf', null, null);
		}

	public Blob getOCRText(SpringCMDocument document) {
		return downloadDocument(document, 'text/plain', null, null);
		}

	public Blob getPNGImage(SpringCMDocument document, String zoom, Integer page) {
		return downloadDocument(document, 'image/png', zoom, page);
		}

	public Blob getThumbnail(SpringCMDocument document) {
		return getPNGImage(document, 'thumbnail', 1);
		}

	/* FOLDER */
	public SpringCMFolder createSubFolderInEos(SObject storageObject, String subFolderName) {
		String storageObjectId = (String)storageObject.get('Id');
		String storageObjectType = String.valueOf(storageObject.getSObjectType());
		System.debug('createSubFolderInEos called for object type: ' + storageObjectId + ', object type'+storageObjectType);

		SpringCMFolder parent = findOrCreateEosFolder(storageObjectId, storageObjectType);
		//TODO: Check for dupe, allow create if exist on flag only
		if (parent == null) return null;
		SpringCMFolder subfolder = createFolder(subFolderName, parent);
		return subfolder;
		}

	public SpringCMFolder findOrCreateEosFolder(String storageObjectId, String storageObjectType) {
		//TODO: Check parameters
		SpringCMEos.SpringCMUtilities.EosObject eosObject = SpringCMEos.SpringCMUtilities.createEOSObject(storageObjectId,storageObjectType);

		SpringCMEosInfo eosInfo = new SpringCMEosInfo();
		eosInfo.ObjectId = eosObject.getSfId();
		eosInfo.ObjectType = 'Salesforce.' + eosObject.getSfType();
		eosInfo.Name = eosObject.getFoldername();
		eosInfo.Path = eosObject.getPath();

		SpringCMFolder folder = new SpringCMFolder();
		folder.EosInfo = eosInfo;
		System.debug('findOrCreateEosFolder called for id: '+eosInfo.ObjectId+', object type: '+eosInfo.ObjectType+', name: '+eosInfo.Name+', path: '+eosInfo.Path);

		String responseBody = springcmApi.post(folder,apiBaseUrl + foldersServiceURL);
		if (responseBody == null) return null;
		folder = (SpringCMFolder)JSON.deserialize(fixPrefixResponseKeywords(responseBody), Type.forName('SpringCMFolder'));
		return folder;
		}

	public SpringCMFolder findFolderByPath(String folderPath, String expansion) {
		if (String.IsBlank(folderPath)) throw new SpringCMException('No folder path provided');

		expansion = String.isBlank(expansion) ? '' : expansion;

		if (String.isNotBlank(expansion)) expansion = (expansion.startsWithIgnoreCase('&expand=') ? '' : '&expand=') + expansion;
		String responseBody = springcmApi.get(apiBaseUrl + foldersServiceURL + '?Path=' + EncodingUtil.urlEncode(folderPath, 'UTF-8') + expansion);
		if (responseBody == null) return null;
		SpringCMFolder folder = (SpringCMFolder)JSON.deserialize(fixPrefixResponseKeywords(responseBody), Type.forName('SpringCMFolder'));
		return folder;
		}

	public SpringCMFolder createFolder(String name, SpringCMFolder parent) {
		if (String.IsBlank(name)) throw new SpringCMException('No folder name provided');
		if (String.IsBlank(parent.Href)) throw new SpringCMException('Not a valid parent folder provided');

		SpringCMFolder folder = new SpringCMFolder();
		folder.Name = EncodingUtil.urlEncode(name, 'UTF-8');
		folder.ParentFolder = parent;
		System.debug('createFolder called for name: '+folder.Name+', parent folder name: '+folder.ParentFolder.Name+', parent folder href: '+folder.ParentFolder.Href);

		String responseBody = springcmApi.post(folder,apiBaseUrl + foldersServiceURL);
		if (responseBody == null) return null;
		folder = (SpringCMFolder)JSON.deserialize(fixPrefixResponseKeywords(responseBody), Type.forName('SpringCMFolder'));
		return folder;
		}

	/* WORKFLOW */
	public SpringCMWorkflow startWorkflow(SpringCMWorkflow workflow) {
		if (String.IsBlank(workflow.Name)) throw new SpringCMException('No workflow name provided');

		System.debug('startWorkflow called for workflow: '+workflow.Name);

		String responseBody = springcmApi.post(workflow, apiBaseUrl + workflowsServiceURL);
		if (responseBody == null) return null;
		workflow = (SpringCMWorkflow)JSON.deserialize(fixPrefixResponseKeywords(responseBody), Type.forName('SpringCMWorkflow'));
		return workflow;
		}

	/* UTILITIES */
	private String fixPrefixResponseKeywords(String responseBody) {
		return fixPrefixResponseKeywords(responseBody, 'scm');
		}

	private String fixPrefixResponseKeywords(String responseBody, String prefix) {
		return responseBody.replaceAll('Limit', prefix + 'Limit');
		}
	}