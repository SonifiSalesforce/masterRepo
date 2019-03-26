public virtual class SpringCMBaseObject {
	public String Name {get;set;}
	//public String CreatedDate {get;set;}
	//public String CreatedBy {get;set;}
	//public String UpdatedDate {get;set;}
	//public String UpdatedBy {get;set;}
	//public String Description {get;set;}
	public SpringCMFolder ParentFolder {get;set;}
	//public SpringCMEosInfo EosParentInfo {get;set;}
	//public AccessLevel": {
	//public String Path {get;set;}
	// public AttributeGroups": {
	//public SpringCMShareLinks ShareLinks {get;set;}
	//public Security": {
	public String Href {get;set;}

	public class SpringCMDocuments extends SpringCMApiCollection {
		public List<SpringCMDocument> Items {get;set;}
	}

	//public class SpringCMShareLinks extends SpringCMApiCollection {
	//	public List<SpringCMShareLink> Items {get;set;}
	//}
}