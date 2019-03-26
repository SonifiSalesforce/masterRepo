public class SpringCMApiError {
	public SpringCMApiErrorInfo Error {get;set;}
	public List<SpringCMValidationError> ValidationErrors {get;set;}
	
	public class SpringCMApiErrorInfo {
		public Integer HttpStatusCode {get;set;}
		public String UserMessage {get;set;}
		public String DeveloperMessage {get;set;}
		public Integer ErrorCode {get;set;}
		public String ReferenceId {get;set;}
	}

	public class SpringCMValidationError {
		public String PropertyName {get;set;}
		public String UserMessage {get;set;}
		public String DeveloperMessage {get;set;}
		public Integer ErrorCode {get;set;}
	}
}