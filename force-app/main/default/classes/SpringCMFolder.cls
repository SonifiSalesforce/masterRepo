public class SpringCMFolder extends SpringCMBaseObject {
	//public String BrowseDocumentsUrl {get;set;}
	public SpringCMDocuments Documents {get;set;}
	public SpringCMFolders Folders {get;set;}
	public SpringCMEosInfo EosInfo {get;set;}
	public String CreateDocumentHref {get;set;}

	public class SpringCMFolders extends SpringCMApiCollection {
		public List<SpringCMFolder> Items {get;set;}
	}
}