public with sharing class ActivityListExtension {

	public PageReference checkRedirect() {
		try {
			String thisUrl = Url.getCurrentRequestUrl().toExternalForm();
			Id objectId =  Id.valueOf(ApexPages.currentPage().getParameters().get('Id'));
			Schema.SObjectType objectType = objectId.getSObjectType();
			thisUrl = thisUrl.replace('ActivityList', objectType + 'ActivityList');
			return new PageReference(thisUrl);
		}  catch (Exception e) { /* TODO Add error to current page */ }
		ApexPages.currentPage().setRedirect(false);
		return null;
	}
}