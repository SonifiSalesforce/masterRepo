public with sharing class CaseRedirectExtension {
	
	public final ApexPages.StandardController theController;
	public final Case theCase;
	public final Boolean isNew;
	public final String recordTypeId;
	
	/**
	 * Constructor
	 */
	public CaseRedirectExtension(ApexPages.StandardController controller) {
		try {
			theController = controller;
			theCase = (Case)controller.getRecord();
		} catch (Exception e) {}
		isNew = (theCase == null || theCase.Id == null) ? true : false;
		recordTypeId = (isNew || theCase.RecordTypeId == null) ? ApexPages.currentPage().getParameters().get('RecordType') : theCase.RecordTypeId;
		System.debug('isNew is : '+isNew);
	}
	
	/**
	 * Determine which Case UI the user should be directed to
	 */
	public PageReference redirectCase() {
		
		// Check for redirected from an edit page
		try {
			String referer = ApexPages.currentPage().getHeaders().get('Referer');
			System.debug('CaseRedirectExtension.redirectCase. Referer URL: ' + referer);
			String lastParam = referer.substring(referer.lastIndexOf('/') + 1, referer.length());
			System.debug('CaseRedirectExtension.redirectCase. Last URL param: ' + lastParam);
			if (lastParam == 'e') {
				System.debug('CaseRedirectExtension.redirectCase. Page was redirected from an edit page. Returning to base view page.'); 
				return redirectToBaseViewPage(); 
			}
		} catch (Exception e) {}
		
		// Check for no record type
		if (recordTypeId == null) {
			System.debug('CaseRedirectExtension.redirectCase. Record is null. Redirecting to the base view page.');
			return redirectToBaseViewPage();
		}
		
		// Check for non support case record type
		if (recordTypeId != Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Case_SupportCase)
			&& recordTypeId != Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Case_SupportCaseClosed)) {
			System.debug('CaseRedirectExtension.redirectCase. Record IS NOT a support case. Redirecting to the base edit page.');
			return redirectToBaseEditPage();
		}
		
		// Case is a support case
		System.debug('CaseRedirectExtension.redirectCase. Record IS a support case. Checking if user is allowed to edit...');
		
		// Check for case closed
		try {
			if (theCase.IsClosed) {
				System.debug('CaseRedirectExtension.redirectCase. Case is closed. Redirecting user to view page.');
				return redirectToBaseViewPage();
			}
		} catch (Exception e) {}
		
		// Check if current user is allowed to edit support cases
		String userProfileName = Utilities.ProfileIdToName(UserInfo.getProfileId()).toUpperCase();
		for (SupportCaseEditRestrictions__c record : SupportCaseEditRestrictions__c.getAll().values()) {
			if (record.Profile__c.toUpperCase() == userProfileName) {
				System.debug('CaseRedirectExtension.redirectCase. User with profile ' + userProfileName + 
					' are not allowed to edit support cases. Redirecting to view page.');
				return redirectToBaseViewPage();
			}
		}
		
		// Redirect to custom CaseEdit page
		PageReference redirectTo = Page.CaseEdit;
		
		String retUrl = isNew ? '%2F500%2Fo' : '%2F' + theCase.Id;
		redirectTo.getParameters().put('retUrl',  retUrl);
		redirectTo.getParameters().put('saveURL',  retUrl);
		redirectTo.getParameters().put('cancelURL',  retUrl);
		populatePageParameters(redirectTo);
		
		redirectTo.setRedirect(true);
		return redirectTo;
	}
	
	/**
	 * Redirect the user to the view page
	 */
	private PageReference redirectToBaseViewPage() {
		PageReference redirectTo = new PageReference(Utilities.getRedirectUrl((isNew ? '500/o' : theCase.Id)));
		redirectTo.setRedirect(true);
		return redirectTo;
	}
	
	/**
	 * Redirect the user to the base (non-overridden) edit page
	 */
	private PageReference redirectToBaseEditPage() {
		
		PageReference redirectTo = new PageReference(Utilities.getRedirectUrl((isNew ? '500/e' : theCase.Id + '/e')));
		String returnUrl = Utilities.getReturnUrl((isNew ? '500/o' : theCase.Id));
		
		if (isNew) { 
			populatePageParameters(redirectTo); 
		} else {
			redirectTo.getParameters().put('id', theCase.Id);			
			redirectTo.getParameters().put('saveURL',  returnUrl);
		}
		redirectTo.getParameters().put('retURL',  returnUrl);
		redirectTo.getParameters().put('cancelURL',  returnUrl);
		redirectTo.getParameters().put('nooverride', '1');
		
		redirectTo.setRedirect(true);
		System.debug(redirectTo);
		return redirectTo;
	}
	
	/**
	 * Populate the page parameters using the parameters from the incoming page 
	 */
	private void populatePageParameters(PageReference pageRef) {
		
		Map<String, String> pageParams = ApexPages.currentPage().getParameters();
		System.debug('pageParams is : '+pageParams);
		
		for (String param : pageParams.keyset()) {
			if (param != 'save_new' && param != 'sfdc.override') {
				pageRef.getParameters().put(param, pageParams.get(param));
			}
		}
		System.debug('pageRef.getParameters() is : '+pageRef.getParameters());
	}
}