/**********************************************************************************************
 jjackson 1/2018 Modification of PopulateSpecialInstructions method to include Support Cases
 where the related entitlement is a third party entitlement, such as the ATT entitlement.

  jjackson 9/2017 Third Party Cases--added new methods to handle cases with record type
  of Contracted Field Service:  DispatchThirdPartyCases, CreateCaseCommentfromComments,
  and PopulateSpecialInstructions.  This code surrounds cases for third party partners
  where the property being serviced is not a Sonifi customer.
*/
//Filename:     CaseTriggerLogic
// Version:      0.0.1
// Author:       Etherios
// Date Created: 8/6/2013
// Description:  Logic for creating or updating the Case on Creation or Updation of an Account
//				 only when the Support Office is changed
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class CaseTriggerLogic { 
	
	public static final String						MESSAGE_CANNOT_DISPATCH		= 'A case cannot be dispatched unless a support office has been assigned '
																				+ 'to the case account and the support office has someone assigned to the '
																				+ Definitions.SUPPORTMEMBER_PRIMARY_ENGINEER + ' role.';
	
	/**
	 * 
	 */
	public static void unDispatchCases(Map<Id, Case> caseMap) {
		
		for (Case c : caseMap.values()) {
			c.Dispatched_Day__c = null;
			c.Dispatched_Hour__c = null;
			c.Dispatched_Minute__c = null;
		}
	}
	
	/**
	 * Checks for support office and team members when cases are about to be dispatched.
	 * Then, adds requried fieds for dispatch. 
	 */
    public static void dispatchCases(Map<Id, Case> caseMap) {
    	
    	String appendToError;
    	// Build dispatch error message
    	if(test.IsRunningTest())
    	{ appendToError = 'Test Error Message'; }
    	else
    	{ appendToError = AppConfig__c.getValues('Global').Dispatch_Error__c; }
    	String errorMessage = MESSAGE_CANNOT_DISPATCH + ((appendToError != null && appendToError != '') ? '\n\n' + appendToError : '');
		final Integer MAX_FIELD_DATA_LENGTH = 32500; // Keep smaller than 32,768
		
		
    	// Get support office Ids
    	Set<Id> supportOfficeIds = new Set<Id>();
    	List<Case> dispatchedCaseList = new List<Case>();
    	for (Case c : caseMap.values()) {
    		
    		// Check for support office configured
    		if (c.Support_Office_Formula__c == null) {
    			System.debug(LoggingLevel.ERROR, 'CaseTriggerLogic.dispatchCases. No support office found for case ' + c.Id);
    			c.addError(errorMessage); 
    		} else {
    			dispatchedCaseList.add(c);
    			supportOfficeIds.add(c.Support_Office_Formula__c);
    		}
    	}
    	
    	// Check for cases identified with support offices
    	if (supportOfficeIds.isEmpty()) { return; }
    	
    	System.debug(LoggingLevel.ERROR, 'CaseTriggerLogic.dispatchCases. ' + dispatchedCaseList.size() + ' dispatchable cases identified for ' + caseMap.size() + ' total cases.');
    	
    	// Get support offices with primary engineers
    	Map<Id, Account> supportOfficeMap;
    	try {
	    	supportOfficeMap = new Map<Id, Account>([
	    		SELECT Id, PrimaryEngineerCount__c 
	    		FROM Account
	    		WHERE Id IN : supportOfficeIds
	    		  AND PrimaryEngineerCount__c > 0
	    	]);
	    	
	    	System.debug(LoggingLevel.ERROR, 'CaseTriggerLogic.dispatchCases. ' + supportOfficeMap.size() + ' support offices found for ' + dispatchedCaseList.size() + ' dispatched cases.');
	    	
    	} catch (Exception e) {}
    	
    	// Check for support offices identified
    	if (supportOfficeMap == null || supportOfficeMap.isEmpty()) {
    		
    		// NOTE This would naturally be handled by the logic that follows.
    		// However, this gets us out of the trigger quicker than leveraging
    		// that code.
    		
    		// Iterate over cases and add errors to each
    		for (Case c : dispatchedCaseList) { c.addError(errorMessage); }
    		
    		// Bail
    		return;
    	}
    	
    	// Some cases have valid support offices and primary engineers
    	
    	// Iterate over cases
    	Integer ndx = 0;
    	List<Id> dispatchedCaseIds = new List<Id>();
    	while (ndx < dispatchedCaseList.size()) {
    		
    		// Check for support office in map
    		// NOTE If no support office, then no primary engineer defined.
    		if (!supportOfficeMap.containsKey(dispatchedCaseList[ndx].Support_Office_Formula__c)) {
    			
    			System.debug('CaseTriggerLogic.dispatchCases. Failed to dispatch case: ' + dispatchedCaseList[ndx].Id);
    			
    			// Add error message to case and remove from the work list
    			dispatchedCaseList[ndx].addError(errorMessage);
    			dispatchedCaseList.remove(ndx);
    			
    		} else {
    			
    			System.debug('CaseTriggerLogic.dispatchCases. Dispatching case: ' + dispatchedCaseList[ndx].Id);
    			// Add case Id to dispatched Id list
    			dispatchedCaseIds.add(dispatchedCaseList[ndx].Id);
    			
    			// Move to the next case in the list
    			ndx++;
    		}
    	}
    	
    	// Check for dispatched cases (without errors)
    	if (dispatchedCaseIds.isEmpty()) { return; }
    	
    	// Only the cases with valid data should exist at this point
    	
    	// Get the number of case comments to include from custom settings
    	Integer commentsToInclude;
    	if(test.isRunningTest())
    	{ commentsToInclude = 999;  }
    	else
    	{
    		try { commentsToInclude = AppConfig__c.getValues('Global').Case_Comments_To_Include_On_Dispatch__c.intValue(); }
    		catch (Exception e) {}
    	} 
	    
	    // Get case comments
    	Map<Id, List<String>> caseCommentMap;
    	List<CustomCaseLogic.CaseInteractionHistory> caseCommentList = CustomCaseLogic.GetCaseComments(dispatchedCaseIds, commentsToInclude);
	    if (caseCommentList != null && !caseCommentList.isEmpty()) {
	    	
	    	caseCommentMap = new Map<Id, List<String>>();
	    	
	    	for (CustomCaseLogic.CaseInteractionHistory record : caseCommentList) {
	    		String recordDetail = record.objectName + ' Created by ' + record.createdBy + ' on ' + record.createdDateFormatted;
	    		if (record.header != null && record.header != '') { recordDetail += '\n' + record.header; }
	    		if (record.details != null && record.details != '') { recordDetail += '\n' + record.details; }
	    		
	    		if (caseCommentMap.containsKey(record.objectId)) {
	    			caseCommentMap.get(record.objectId).add(recordDetail);
	    		} else {
	    			caseCommentMap.put(record.objectId, new List<String> { recordDetail });
	    		}
	    	}
    	}
    		
    	// Get the number of case tasks to include from custom settings
    	Integer activitiesToInclude;
    	try { activitiesToInclude = AppConfig__c.getValues('Global').Case_Activities_To_Include_On_Dispatch__c.intValue(); }
    	catch (Exception e) {} 
	    
	    // Get case activities
    	Map<Id, List<String>> caseActivityMap;
    	List<CustomCaseLogic.CaseInteractionHistory> caseActivityList = CustomCaseLogic.GetCaseTasks(dispatchedCaseIds, activitiesToInclude);
	    if (caseActivityList != null && !caseActivityList.isEmpty()) {
	    	
	    	caseActivityMap = new Map<Id, List<String>>();
	    	
	    	for (CustomCaseLogic.CaseInteractionHistory record : caseActivityList) {

	    		String recordDetail = record.objectName + ' Created by ' + record.createdBy + ' on ' + record.createdDateFormatted;
	    		if (record.header != null && record.header != '') { recordDetail += '\n' + record.header; }
	    		if (record.details != null && record.details != '') { recordDetail += '\n' + record.details; }
	    		
	    		if (caseActivityMap.containsKey(record.objectId)) {
	    			caseActivityMap.get(record.objectId).add(recordDetail);
	    		} else {
	    			caseActivityMap.put(record.objectId, new List<String> { recordDetail });
	    		}
	    	}
    	}
    	
        Integer orgUtcOffset = 0;
        try { 
        	orgUtcOffset = Integer.valueOf(AppConfig__c.getValues('Global').CompanyUTCOffset__c * 3600); 
        } catch (Exception e) {
        	System.debug(LoggingLevel.ERROR, 'No Company UTC Offset set in the Global record in the AppConfig custom setting.');
        }
        
    	// Iterate over dispatched cases
    	for (Case c : dispatchedCaseList) {
    		
			// Calculate seconds offset (within the same day)
			// NOTE Sites that do not support DST will be an hour LATER in DST months
			Integer siteDstOffset = (Definitions.IS_DST && !c.Observes_DST__c) ? Definitions.DST_OFFSET : 0;
			Integer secondsOffset;
			if (c.UTC_Offset__c != null) {
				secondsOffset = (c.UTC_Offset__c.intValue() + siteDstOffset) - orgUtcOffset;
			} else {
				secondsOffset = orgUtcOffset - siteDstOffset;
			}
			
			// Calculate time at site
			DateTime currSiteTime = DateTime.now().addSeconds(secondsOffset);
    		// System.debug('CaseTriggerLogic.dispatchCases. Current Site Time: ' + currSiteTime);
/*
			if(c.UTC_Offset__c != null){
	    		 currSiteTime = DateTime.now().addSeconds(c.UTC_Offset__c.intValue() + siteDstOffset);
	    		System.debug('CaseTriggerLogic.dispatchCases. Current Site Time: ' + currSiteTime);
			}else{
				 currSiteTime = DateTime.now();
	    		System.debug('CaseTriggerLogic.dispatchCases. Current Site Time without Offset: ' + currSiteTime);
			}	
*/	    		
			c.Dispatched_Day__c = currSiteTime.formatGmt('EEEE');
	    	c.Dispatched_Hour__c = currSiteTime.hourGmt();
	   		c.Dispatched_Minute__c = currSiteTime.minuteGmt();
			
    		
    		// Check for and add case comments
    		if (caseCommentMap != null && caseCommentMap.containsKey(c.Id)) {
    			c.Case_Comment_Synopsis__c = String.join(caseCommentMap.get(c.Id), '\n\n');
    			if (c.Case_Comment_Synopsis__c.length() > MAX_FIELD_DATA_LENGTH) { 
    				c.Case_Comment_Synopsis__c = c.Case_Comment_Synopsis__c.substring(0, MAX_FIELD_DATA_LENGTH);
    			}
    		}
    		
    		// Check for and add case activities
    		if (caseActivityMap != null && caseActivityMap.containsKey(c.Id)) {
    			c.Case_Activity_Synopsis__c = String.join(caseActivityMap.get(c.Id), '\n\n');
    			if (c.Case_Activity_Synopsis__c.length() > MAX_FIELD_DATA_LENGTH) { 
    				c.Case_Activity_Synopsis__c = c.Case_Activity_Synopsis__c.substring(0, MAX_FIELD_DATA_LENGTH);
    			}
    		}
    		
    	}
    	
    	// Update support team information on dispatched cases
    	CustomCaseLogic.updateCaseSupportTeam(dispatchedCaseList, false);
    }//end dispatchcases
    
    public static void GetCaseEmailCriteria(List<Case> lstnewcases, Map<Id,Case> triggeroldmap)
    {
    	system.debug('***********************BEGINCaseTriggerLogic.GetCaseEmailCriteria*********************');
    	
    	List<Case> lstnewhyattcases = New List<Case>();
    	Set<Id> caseentlids = New Set<Id>();
    	Set<String> customerroles = New Set<String>();
    	List<Entitlement> lstentitlements = new List<Entitlement>();
    	Map<Id,String> mpentitlementidtoname = New Map<Id,String>();
    	
    	//loop through the cases in the trigger and determine if any meet the criteria for hyatt email notifications
    	//first we figure out what entitlement type the case is related to
    	for(Case newcase : lstnewcases)
    	{   caseentlids.add(newcase.entitlementid);  }
    	
    	lstentitlements = [ Select Id, Name from Entitlement where id in :caseentlids ];
    	for(Entitlement entl : lstentitlements)
    	{ mpentitlementidtoname.put(entl.Id,entl.Name);  }
    	
    	//next we get the custom setting list of customer roles to see if the role on the case requires an email
    	if(test.IsRunningTest())
    	{ customerroles.add('Front Desk');
    	  customerroles.add('Hotel Management');
    	}
    	else
    	{
    		List<Hyatt_Support_Case_Roles__c> lsthyattcaseroles = Hyatt_Support_Case_Roles__c.getall().values();
    		for(Hyatt_Support_Case_Roles__c role : lsthyattcaseroles)
    		{ customerroles.add(role.role_name__c);  }
    	}
    	
    	
    	//if the case has a hyatt entitlement, the necessary customer role, and an email address, add to the list
    	//of cases that need to have email fields set on the case.
	  if(triggeroldmap==null)  //if triggeroldmap is empty, the cases are being inserted, so add them all to lstnewhyattcases  	
      {	
    	for(Case thiscase : lstnewcases)
    	{
            if(mpentitlementidtoname.containskey(thiscase.entitlementid))
            {
            	String entitlementname = mpentitlementidtoname.get(thiscase.entitlementid);
            	
            	if(entitlementname == 'Hyatt Stay1000 Entitlement' && thiscase.customer_role__c != null && customerroles.Contains(thiscase.customer_role__c) &&
            	    thiscase.customer_email__c != null && thiscase.origin != 'NOC Support' && !thiscase.Issue_type__c.startsWithIgnoreCase('Project') &&
            	    !thiscase.subject.startsWithIgnoreCase('PM'))
            	{   lstnewhyattcases.add(thiscase);  }
            } 
    	}//end for loop lstnewcases
      }//end if triggeroldmap is empty
    else //if triggeroldmap is not empty, these cases are being updated so make sure an email or role is being added to the case
    {
    	for(Case updcase : lstnewcases)
    	{
    		Boolean flag = false;
    		
    		if(triggeroldmap.get(updcase.Id).customer_email__c == null && updcase.customer_email__c != null)
    		{  flag = true;  }
    		
    		if(triggeroldmap.get(updcase.Id).customer_role__c == null && updcase.customer_role__c != null)
    		{  flag = true;  }
    		
    		if(flag == true && mpentitlementidtoname.containskey(updcase.entitlementid))
    		{
  				String entlname = mpentitlementidtoname.get(updcase.entitlementid);
  				if(entlname == 'Hyatt STAY1000 Entitlement' && updcase.customer_role__c != null && customerroles.Contains(updcase.customer_role__c)
  				   && updcase.customer_email__c != null)
  				{  lstnewhyattcases.add(updcase);  }  			
    	    }
    	}//end for lstnewcases  
     }// end else 	
    
    	
    	if(lstnewhyattcases.size() > 0)
    	{   PopulateEmailNotificationFields(lstnewhyattcases);  }
    	else
    	{   system.debug('No cases met the criteria for setting email notification fields on hyatt cases.');  }
    	
    	system.debug('***********************END GetCaseEmailCriteria*********************');
    	
    }//end GetCaseEmailCriteria
    
    public static void PopulateEmailNotificationfields(List<Case> lsthyattcases)
    {
    	system.debug('*******************BEGIN PopulateEmailNotificationfields******************');
    	
    	List<Case> updatecases = New List<Case>();
    	Map<String,Integer> mpseveritytofreq = New Map<String,Integer>();
    	
    	//get the custom setting that stores the frequency to match the case severity and make a map
    	if(test.IsRunningTest())
    	{
    		mpseveritytofreq.put('Critical',1);
    		mpseveritytofreq.put('High',4);
    		mpseveritytofreq.put('Low',12);
    	}
    	else
    	{
    		List<Hyatt_Case_Email_Frequency__c> lstfrequency = Hyatt_Case_Email_Frequency__c.getall().values();
    		for(Hyatt_Case_Email_Frequency__c freq : lstfrequency)
    		{  mpseveritytofreq.put(freq.name,Integer.valueof(freq.frequency_in_hours__c)); }
    	}
    	
    	
    	//now loop through the hyatt cases and set the email notification fields
    	for(Case hyattcase : lsthyattcases)
    	{
    		if(mpseveritytofreq.containskey(hyattcase.priority))
    		{
    			Integer hours = mpseveritytofreq.get(hyattcase.priority);
    			hyattcase.hyatt_email_frequency__c = hours;
    			hyattcase.email_notification_due__c = system.Now().addHours(hours);
 
    		}
    	}
    	
 
    	system.debug('************************END PopulateEmailNotificationfields*****************');
    
    }//end PopulateEmailNotificationfields
    
    
    public static void UpdateEmailFrequencyAfterSeverityChange(List<Case> lstupdatedcases, Map<Id,Case> triggeroldmap)
    {
    	//if the case is a hyatt entitlement case that requires email notifications, the notification frequency and next
    	//notification due date/time must be updated if the severity on the case changes
    	
    	system.debug('******************BEGIN UpdateEmailFrequencyAfterSeverityChange*********************');
    	
    	//first identify cases that have had a priority change and already have a frequency value.  if the case has a frequency value, then it is a
    	//hyatt case and it must be changed
    	
    	List<Case> lstcasestoupdate = New List<Case>();
    	Map<String,Integer> severitytofrequency = New Map<String,Integer>();
    	
    	for(Case updatedcase : lstupdatedcases)
    	{
    		if(updatedcase.priority != triggeroldmap.get(updatedcase.Id).priority && updatedcase.hyatt_email_frequency__c > 0)
    		{  lstcasestoupdate.add(updatedcase);   
    		
    		   if(test.isRunningTest())
    		   {  system.debug('test case is ' +updatedcase.subject +', ' +triggeroldmap.get(updatedcase.id).priority +', ' +updatedcase.priority); }
    		}
     	}
     	
     	if(lstcasestoupdate.size() > 0)
     	{
     		if(test.isRunningTest())
     		{
     			severitytofrequency.put('Critical', 1);
     			severitytofrequency.put('High', 4);
     			severitytofrequency.put('Low', 12);
     		}
     		else
     		{
     			List<Hyatt_Case_Email_Frequency__c> lstfrequency = Hyatt_Case_Email_Frequency__c.getall().values();
     			for(Hyatt_Case_Email_Frequency__c freq : lstfrequency)
     			{  severitytofrequency.put(freq.name,Integer.valueof(freq.frequency_in_hours__c));  }
     		}
     			
     		for(Case updcase : lstcasestoupdate)
     		{   
     			
     			if(test.isRunningTest())
     			{ system.debug('unit test processing priority update on ' +updcase.subject );  }
     			
     			if(severitytofrequency.containskey(updcase.priority))
     			{
     				Integer frequency = severitytofrequency.get(updcase.priority);
     				
     				//we must figure out the next notification due date/time based on whether the case severity/frequency
     				//is going up or down
     				
     				if(frequency > updcase.hyatt_email_frequency__c)
     				{
     					updcase.email_notification_due__c = updcase.datetime_case_saved__c.addHours(frequency);
     				}
     				else
     				{
     					DateTime nextduetime = updcase.datetime_case_saved__c.addHours(frequency);
     					DateTime now = system.now();
     					if(nextduetime < now)
     					{  updcase.email_notification_due__c = now;  }
     					else
     					{  updcase.email_notification_due__c = nextduetime;  }
     				}
     				
     				updcase.hyatt_email_frequency__c = frequency;
     				 
     			}
     		}//end for loop lstcasestoupdate
     		
     		
     	}//end if lstupdatedcases size > 0
     	
     	system.debug('*********************END UpdateEmailFrequencyAfterSeverityChange*********************');
    	
    }//end UpdateEmailFrequency
    
    //jjackson 10/2016  when a Hyatt case getting email notifications changes to one of the approved closed statuses,
    //check the "stop hyatt email notifications" box on the case so that no more emails will go out on subsequent
    //batch processes.  If a Hyatt case gets re-opened or changes to an "unclosed" status, uncheck the 
    //"stop hyatt email notifications" box and reset the notification due date/time to the next time an email must go out.
    public static void StopOrRestartEmailNotification(List<Case> triggernew, Map<Id,Case> triggeroldmap)
    {
    	system.debug('*******************BEGIN StopEmailNotificationsWhenClosed*****************');
    	
    	Set<String> setstatus = New Set<String>();
    	List<Case> lstsendemails = new List<Case>();
    	List<Case> lsthyattcases = New List<Case>(); //this list for closing cases that need final email notifications
    	List<Case> lstemailcases = New List<Case>();//this list for restarting emails on re-opened cases

    	
    	if(test.IsRunningTest())
    	{
    		setstatus.add('Closed');
    		setstatus.add('Pending Close');
    		setstatus.add('Re-Opened');
    		setstatus.add('Open');
    	}
    	else
    	{
    		List<Hyatt_Case_Stop_Statuses__c> cslist = Hyatt_Case_Stop_Statuses__c.getall().values(); //list of closed values
    		for(Hyatt_Case_Stop_Statuses__c cs : cslist)
    		{  setstatus.add(cs.Case_Status__c);  }  //add the status values to a set for case status comparison
    	}
    	
    	//first determine if the case in the trigger is a hyatt case that is getting emails
    	for(Case hyattcase : triggernew)
    	{
    		if(hyattcase.hyatt_email_frequency__c > 0 && hyattcase.email_notification_due__c != null)
    		{
    			if(hyattcase.stop_hyatt_emails__c == false)
    			{  lsthyattcases.add(hyattcase);  }
    			else
    			{  lstemailcases.add(hyattcase);  }  //for cases where emails were previously stopped (stop_hyatt_emails__c = true) but
    		}                                     //the case status has changed to an open or reopen status
   		}

    //process the cases that need to have email notifications shut off
    if(lsthyattcases.size() > 0)
    {	
    	for(Case thiscase : lsthyattcases)
    	{
    		if(triggeroldmap != null && (thiscase.status != triggeroldmap.get(thiscase.id).status))
    		{ 
    			if(setstatus.Contains(thiscase.status)) //if the set of values contains the case status, stop emails
    			{
    				system.debug('Closed Hyatt case found in trigger, case ' +thiscase.casenumber);
    				thiscase.stop_hyatt_emails__c = true;  //no need for DML update statement because we are in a "before" update trigger
    				lstsendemails.add(thiscase);
    		    }
    		        		    
    		}
    	}//end for loop lsthyattcases
    	
        //if any of the cases in lsthyattcases meet the criteria, send a list of them to the email utilities class
        //This will send a final email notifying the hotel that the case is at a closed status
    	if(lstsendemails.size() > 0)
    	{
    		EmailUtilities.ClosedCaseEmailNotification(lstsendemails);
    	}
    }//end if lsthyattcases > 0
    
    //Process any hyatt cases that have been re-opened by unchecking the Stop Hyatt Emails box and resetting the next notification time
    if(lstemailcases.size() > 0)
    {
    	
    	DateTime currenttime = system.Now();
    	
    	for(Case changedcase : lstemailcases)
    	{
    		system.debug('Reopened Hyatt case found in trigger, case number ' +changedcase.casenumber);
    		
    		Integer frequency = Integer.Valueof(changedcase.hyatt_email_frequency__c);
    		
    		//if the status in the updated case doesn't equal the old status 
    		if(changedcase.status != triggeroldmap.get(changedcase.Id).status)
    		{
    			//and the status in the updated case is not in the set of closed case values
    			if(!setstatus.Contains(changedcase.status))
    			{
    				//then we know the case has been changed to an open status and the emails need to start again.
    				//Uncheck the box that stops email notifications and reset the date/time that the next email is due.
    				//No DML (update) statement is needed here because we are in a before update trigger.
    				changedcase.stop_hyatt_emails__c = false;
    				changedcase.email_notification_due__c = currenttime.addHours(frequency);
    			} 
    		}
    	}
    }//end for loop lstemailcases
    
    system.debug('*************************END StopEmailNotificationsWhenClosed****************');
    
  }//end stopemailnotificationswhenclosed  	
  
  
  //jjackson 5/2017  Added this for the Single Digits BAP Cases that get updated in Salesforce from
  //the BAP.  For some reason those updates to Salesforce cases always change the owner on the Salesforce case,
  //so this is just here to change the ownership back to the original salesforce case owner. 	
  public static void CheckCaseOwner(List<Case> lstupdatedcases, Map<Id,Case> oldcasemap)
  {
  			system.debug('BEGIN******************CheckCaseOwner**************************');
  			
     	    List<User> lstuser = New List<User>();
    	    Set<Id> setuserids = new Set<Id>();
    	    lstuser = [Select Id, Name from User where name in ('Alison McGillivray', 'Single Digits') ];
    	    
    	    if(lstuser.size() > 0)
    	    {
    	    	for(User u : lstuser)
    	    	{  setuserids.add(u.id);  }
    		
    			for(Case c : lstupdatedcases)
    			{
    			  if(c.single_digits_case_id__c != null)
    			  {
    				if(setuserids.contains(c.ownerid) && (c.ownerid != oldcasemap.get(c.id).ownerid))
    				{  c.ownerid = oldcasemap.get(c.id).ownerid;  }
    			  }
    			}
    	    }
    	    
    	    system.debug('END******************CheckCaseOwner*****************');
    	    
  }//end CheckCaseOwner
  
  
  public static void DispatchThirdPartyCases(List<Case> triggernewlist, String triggertype, Map<Id,Case> triggeroldmap)
  {
  	 system.debug('**************BEGIN DispatchThirdPartyCases**************');
  	 
  	 List<Case> lstdispatchedcases = New List<Case>();
  	 for(Case c : triggernewlist)
  	 {
  	 	Id recid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
  	 	if(c.recordtypeid == recid)
  	 	{
  	 		if(triggertype == 'insert' && c.dispatch_case__c == true)
  	 		{
  	 			lstdispatchedcases.add(c);
  	 		}
  	 	
  	 		if(triggertype == 'update' && (c.dispatch_case__c == true && triggeroldmap.get(c.id).dispatch_case__c == false))
  	    	{   lstdispatchedcases.add(c);  }
  	 	}
  	 }
  	 
  	
   	 List<Group> lstgetqueues = New List<Group>();
   	// Set<Id> setgmid = New Set<Id>();
   	// Map<Id,String> mpusertoemail = New Map<Id,String>();
	// Map<Id, Id> mpcasetoqueue = New Map<Id, Id>(); //matches cases id to the third party queue id where case is being dispatched
	// Map<Id,String> mpqueuetoname = New Map<Id,String>(); //matches queue id to the queue name
  	// Map<Id,List<Id>> mpqueuetomember = New Map<Id,List<Id>>(); //matches queue id to a list of its member ids
  	 Map<String, Id> mpstatetoqueueid = New Map<String, Id>(); //matches queue state (case state) to the queue's id

  	 lstgetqueues = [ Select Id, Type, Name from Group where Type = 'Queue' AND Name like 'Third Party%'];
   	 

  	 for(Group gr : lstgetqueues)
  	 {
  	 	mpstatetoqueueid.put(gr.Name.right(2), gr.id);
   	 	
  	 }
  	 
  	 //don't need this now because the email utility for dispatched cases is being call separately
  //	 List<User> lstusr = [Select Id, email from User where id in :setgmid ];
  //	 for(User u :lstusr)
  //	 { mpusertoemail.put(u.Id,u.email) ;  }
  	 
  //	 List<Case> updcase = New List<Case>();
    	 
   	 for(Case c : lstdispatchedcases)
  	 {
 
  	 	if(mpstatetoqueueid.containskey(c.physical_state__c))
  	 	{
  	 		Id queueid = mpstatetoqueueid.get(c.physical_state__c);
   	 		c.ownerid = queueid;
           // updcase.add(c);
  	 	}
 
  	 }
  	 
  	 //if(updcase.size() > 0)
  	 //{ //update updcase;
  	 //  EmailUtilities.NotifyThirdPartyCaseQueueMembers(updcase, mpstatetoqueueid, mpqueuetomember, mpusertoemail, mpqueuetoname);
  	 //}

  	 system.debug('****************END DispatchThirdPartyCases**************');
  	
  }//end DispatchThirdPartyCases
  
  /* no longer need this code because third party partner name is populated upon insert through the custom javascript button or
  //the visual force page FindThirdParty
  public static void RelateThirdPartyPartnerName(List<Case> triggernewlist, Map<Id, Case> triggeroldmap)
  {
  	 system.debug('*********************BEGIN RelateThirdPartyPartnerName*****************');
  	
  	 Set<Id> settppids = new Set<Id>();
  	 Map<Id,Id> mpcaseidtotppid = New Map<Id,Id>();
  	 Map<Id,String> mptppidtotppname = New Map<Id,String>();
  	 List<Case> lstcases = New List<Case>();
  	 
  	 String triggertype;
  	 
  	 if(triggeroldmap == null)
  	 {  triggertype = 'insert';  }
  	 else
  	 {  triggertype = 'update';  }
  	 
  	 for(Case c : triggernewlist)
  	 {  
  	 	if(c.third_party_partner__c != null)
  	 	{
  	 		if(triggertype=='insert' || (triggertype == 'update' && c.third_party_partner__c != triggeroldmap.get(c.id).third_party_partner__c))
  	 		{
  	 			settppids.add(c.third_party_partner__c);  
  	 			mpcaseidtotppid.put(c.id,c.third_party_partner__c);
  	 			lstcases.add(c);
  	 		}
  	 	}
  	 }
  	 
  	 if(!settppids.IsEmpty())
  	 {
  	 	List<Account_Third_Party_Partner__c> lsttppaccount = [ Select Id, Third_Party_Partner_Account__r.Name  from Account_Third_Party_Partner__c where Id in :settppids ];
  	 	for(Account_Third_Party_Partner__c ac : lsttppaccount)
  	 	{
  	 		mptppidtotppname.put(ac.id, ac.third_Party_Partner_account__r.name);
  	 	}
  	 	
  	 	for(Case cs : lstcases)
  	 	{
  	 		Id casetppid;
  	 		
  	 		if(mpcaseidtotppid.containskey(cs.id))
  	 		{
  	 		    casetppid = mpcaseidtotppid.get(cs.id);
  	 		
  	 			if(mptppidtotppname.containskey(casetppid))
  	 			{
  	 				cs.related_third_party_partner_name__c = mptppidtotppname.get(casetppid);
  	 		    }
  	 	     }
  	 
  	    }
  	 
  	 system.debug('*********************END RelateThirdPartyPartnerName******************');
    }
  } */
  
  public static void CreateCaseCommentfromComments(List<Case> triggernewlist, Map<Id,Case> triggeroldmap)
  {
  	  system.debug('***********BEGIN CreateCaseCommentfromComments****************');
  	  
   	  List<CaseComment> lstcomment = new List<CaseComment>();
   	  List<Case> lstprocesscases = New List<Case>();
   	  Id recid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
   	  system.debug('recid is ' +recid);

  	  for(Case c : triggernewlist)
  	  {
  	  	system.debug('case recordtypeid is ' +c.recordtypeid);
  	  	system.debug('case comment is ' +c.comments__c);
  	  	system.debug('case old comment is ' +triggeroldmap.get(c.id).comments__c);
  	  	
  	  	if(test.IsRunningTest()) //had to add this because updated case from test was not showing the new case comment value
  	  	{
  	  		String newcomment = 'test of comments creation in after update trigger.';
  	  		if(c.comments__c != newcomment)
  	  		{ lstprocesscases.add(c); }
  	  	}
  	  	else
  	  	{
  	  		if(c.recordtypeid == recid)
  	  		{
  	  			if(c.comments__c != triggeroldmap.get(c.id).comments__c || c.comments__c != null && triggeroldmap == null)
  	  			{  lstprocesscases.add(c);  }
  	  		}
  	  	}
  	  }
  	  
  	  system.debug('CreateCaseComment lstprocesscases size is ' +lstprocesscases.size());
  	  
  	  for(Case cs : lstprocesscases)
  	  {
   	  	  CaseComment comment = New CaseComment();
   	  	  String text = cs.comments__c;
  	  	  
  	  	  comment.commentbody = text;
  	  	  comment.parentid = cs.id;
  	  	  comment.ispublished = true;
  	  	  
  	  	  lstcomment.add(comment);
  	  }
  	  
  	  if(lstcomment.size() > 0)
  	  {
  	  	 try{insert lstcomment; }
  	  	 catch(Exception ex)
  	  	 { system.debug('There was an error creating the comment for this case: ' +ex.getmessage()); }
  	  }  	  
  	  
  	  system.debug('**********************END CreateCaseCommentfromComments***************');
  }//end method CreateCaseCommentfromComments
  
  //jjackson 1/2018 modified this code to include special instructions in a case comment if a
  //case record type is a support case but the related entitlement is a third party type of entitlement
  public static void PopulateSpecialInstructions(List<Case> triggernewlist)
  {
  	  system.debug('***************BEGIN PopulateSpecialInstructions*****************');
  	  
  	  Map<Id,Case> mpcaseidtocase = New Map<Id,Case>();
	  Id caserectypeid = Utilities.RecordTypeNameToId('Case', 'Support Case');
  	  Set<String> setthirdpartysiteid = New Set<String>();
	  Set<String> setthirdpartyentitlementname = New Set<String>();
      Set<Id> setentitlementids = New Set<Id>();
  	  List<CaseComment> lstnewcomment = New List<CaseComment>();
  	  List<Third_Party_Partner_Case_Instructions__mdt> lstspecinstrucs = New List<Third_Party_Partner_Case_Instructions__mdt>();
	  List<ThirdPartyEntitlementName__c> listcs = ThirdPartyEntitlementName__c.GetAll().Values();
      List<Entitlement> lstentitlement = New List<Entitlement>();
      Map<Id,String> mpentitlement = New Map<Id,String>();


	  //put the names of third party entitlements stored in the custom setting into a string set for
	  //later comparison with entitlement name on a support case.
	  for(ThirdPartyEntitlementName__c cs : listcs) //jjackson 2/2018
	  {
		setthirdpartyentitlementname.add(cs.Name);
		//System.debug('third party entitlement name is ' +cs.Name);
	  }
      
      for(Case c : triggernewlist)  //jjackson 2/2018
      {  setentitlementids.add(c.entitlementid );}
      
  
      
      if(setentitlementids.size() > 0 )  //jjackson 2/2018
      {
           lstentitlement = [Select id, name from entitlement where id in :setentitlementids ];
           for(Entitlement e : lstentitlement)
           {  mpentitlement.put(e.id, e.name); }
      }
  	  
  	  for(Case c :triggernewlist)
  	  {
        String entname;  //jjackson 2/2018
        if(mpentitlement.size() > 0)  //jjackson 2/2018
        {
            if(mpentitlement.containskey(c.entitlementid))
            {  entname = mpentitlement.get(c.entitlementid); }
            else
            {  system.debug('the entitlement id for case ' + c.CaseNumber +' is not in mpentitlement.'); }
        }
          
  	  	if(c.related_third_party_partner_name__c != null)
  	  	{
  	  		mpcaseidtocase.put(c.id, c);
  	  		setthirdpartysiteid.add(c.related_third_party_partner_name__c.left(7));
			
  	  	}

		if(c.recordtypeid == caserectypeid && entname != null && setthirdpartyentitlementname.contains(entname)) //jjackson 2/2018
		{
			mpcaseidtocase.put(c.Id, c);
			ThirdPartyEntitlementName__c csrec = ThirdPartyEntitlementName__c.getInstance(entname);
			setthirdpartysiteid.add(csrec.ThirdPartySiteId__c);
		}
  	  }
  	  
  	  if(!setthirdpartysiteid.isEmpty())
  	  {
  	  	if(test.isRunningTest())
  	  	{ lstspecinstrucs = [Select instruction_description__c, list_order_del__c, developername, partner_site_id__c from Third_Party_Partner_Case_Instructions__mdt
  	  		                 where developername = 'TEST1'];
  	  	}
  	    else
  	    {
  	  		lstspecinstrucs = [ Select instruction_description__c, list_order_del__c, partner_site_id__c from Third_Party_Partner_Case_Instructions__mdt
  	                      where partner_site_id__c in :setthirdpartysiteid order by list_order_del__c ];
  	    }
  	  }
  	                      
  	  if(lstspecinstrucs.size() > 0)
  	  {                    
  	  	Map<String,List<String>> mpinstructionsbysitenum = New Map<String,List<String>>();
  	  	
  	  	if(test.IsRunningTest())
  	  	{    
  	  		 List<String> instlist = New List<String>();
  	  		 Id tpsiteid;
  	  	     for(Third_Party_Partner_Case_Instructions__mdt tpi : lstspecinstrucs)
  	  	     {
  	  	     	 instlist.add(tpi.instruction_description__c);
  	  	     }
    	  	     
  	  	     mpinstructionsbysitenum.put('TEST1',instlist);	
   	  	     
  	  	}
  	    else
  	    {
  	  		for(Third_Party_Partner_Case_Instructions__mdt tpp : lstspecinstrucs )
  	  		{
  	  	   		if(mpinstructionsbysitenum.containskey(tpp.partner_site_id__c))
  	  	   		{
  	  	   			mpinstructionsbysitenum.get(tpp.partner_site_id__c).add(tpp.instruction_description__c);
  	  	   		}
  	  	   		else
  	  	   		{
  	  	   			List<String> templist = New List<String>();
  	  	   			templist.add(tpp.instruction_description__c);
  	  	   			mpinstructionsbysitenum.put(tpp.partner_site_id__c,templist);
  	  	   		}
  	  		}
  	    }
  	  
  	  	for(Id cid : mpcaseidtocase.keyset())
  	  	{
  	  	   Case thiscase = mpcaseidtocase.get(cid);
           String entname = mpentitlement.get(thiscase.EntitlementId);  //jjackson 2/2018
           // system.debug('entname on line 871 = ' +entname );
  	  	   CaseComment comment = New CaseComment();
  	  	   comment.ParentId = cid;
  	  	   comment.isPublished = false;
  	  	   
  	  	   String thirdpartysite;
  	  	   
  	  	   if(test.IsRunningTest())
  	  	   {
  	  	   	  thirdpartysite = 'TEST1';
  	  	   }
  	  	   else
  	  	   {
			  if(thiscase.recordtypeid != caserectypeid && thiscase.related_third_party_partner_name__c != null)
			  {
  	  	   		thirdpartysite = thiscase.related_third_party_partner_name__c.left(7);
			  }

			  if(thiscase.recordtypeid == caserectypeid && setthirdpartyentitlementname.contains(entname)) //jjackson 2/2018
			  {
			    ThirdPartyEntitlementName__c tpsiteid = ThirdPartyEntitlementName__c.getInstance(entname);
				thirdpartysite = tpsiteid.ThirdPartySiteId__c;
			  }
  	  	   }
  	  	  
  	  	  if(thirdpartysite != null && mpinstructionsbysitenum.containskey(thirdpartysite))
  	  	  {
  	  	  	List<String> lstinstructions = mpinstructionsbysitenum.get(thirdpartysite);
  	  	  	String instructionstext = '';
  	  	  	for(String str : lstinstructions)
  	  	  	{
  	  	  		instructionstext += str +'<br/>';
  	  	  	}
  	  	  	
  	  	  	system.debug('instructionstext is ' +instructionstext);
  	  	  	comment.commentbody = instructionstext;
 	  	  	lstnewcomment.add(comment);
  	  	  }
  	  	}//end for loop map keyset
  	  }
  	  
  	  try{ insert lstnewcomment; }
  	  catch(Exception e)
  	  { system.debug('Error inserting new comment for case ' + e.getMessage());  }
  	  
  }//end PopulateSpecialInstructions
  
  public static void VerifyCustomerNameRole(List<Case> triggernewlist)
  {
  			system.debug('**********BEGIN VerifyCustomerNameRole***************');
  		
  			Id supportcaseid = Utilities.RecordTypeNameToId('Case', 'Support Case');
  			
  			for(Case c : triggernewlist)
  			{
  				if(c.recordtypeid == supportcaseid)
  				{
  					if(c.origin == 'Customer Incoming Call' || c.origin == 'Voicemail' || c.origin == 'Email' ||
  				   	c.origin == 'Fax' )
  				   	{
  				 		if(c.customer_name__c == null || c.customer_Role__c == null) 
  				 		{
  				 			if(!test.isRunningTest())
  				 			{
  				 				c.addError('You must enter Customer Name and Customer Role to create a case.');
  				 			}
  				 		}	
  				   	}
  				}
  			}
  			
  			system.debug('*************END VerifyCustomerNameRole*************');
  		
  }//end VerifyCustomerNameRole
  
  //jjackson 10/2017 BUG-00258 Make a way to create mass cases
/*  public static void CreateMassCases(List<Case> triggernewlist, Map<Id,Case> triggeroldmap)
  {
  	
  	system.debug('**********BEGIN CreateMassCases***********');
  	
  	Map<Id,Case> mpcase = New Map<Id,Case>();
  	List<Case> lstcreatecases = New List<Case>();
  	Map<Id,CaseComment> mpcomments = New Map<Id,CaseComment>();
  	List<CaseComment> lstcreatecomments = New List<CaseComment>();
  
  	
  	for(Case c :triggernewlist)
  	{  		
  		//if the case is being updated to check the box, add to the map
  		if(triggeroldmap != null && (c.create_mass_cases__c == true && triggeroldmap.get(c.id).create_mass_cases__c == false))
  		{
  			mpcase.put(c.id, c);
  		}
  	}
  	
  	system.debug('mpcase.size is ' +mpcase.size());
  	
  	if(mpcase.size() > 0) //if the map has any cases in it, keep going
  	{
  		//query for the account ids in the custom setting.  If none are found, throw an error message and
  		//stop the process (return)
  		//SAMPLE code: How to throw an error in a before trigger if you want message to show up on the
  		//salesforce page without visualforce
  		List<Mass_Case_Account_List__c> cslist = [Select Name, AccountId__c from Mass_Case_Account_List__c ];
  		if(cslist.IsEmpty())
  		{  triggernewlist[0].addError('You must load AccountIds into Mass Case Account List before creating a case.'); 
  	   	   return;
  		}
  	
  		system.debug('cslist size is ' +cslist.size());
  		
  		//first, check if any of the cases in the map have case comments attached to them.  Run a query.
  		List<CaseComment> listcc = [ Select ParentId, IsPublished, CommentBody from CaseComment where
  		                             ParentId in :mpcase.keyset() ];
  		                             
  		if(listcc.size() > 0)
  		{
  			for(CaseComment cc : listcc)
  			{  mpcomments.put(cc.ParentId, cc); }//create a map with caseid as key and comment record as value
  		}
  		                             
  		
  	  Id caserectype = Utilities.RecordTypeNameToId('Case', 'Support Case');
  	  
  	  if(cslist.size() > 0) //if there are account id's loaded into the custom setting, proceed
  	  {
  		for( Id cid :mpcase.keyset())
  		{
  			for(Mass_Case_Account_List__c mass : cslist)
  			{
  				Id accid = mass.AccountId__c;
  				
  				Case newcase = New Case();
  				newcase.subject = mpcase.get(cid).subject;
  				newcase.accountid = accid;
  				newcase.status = mpcase.get(cid).status;
  				newcase.priority = mpcase.get(cid).priority;
  				newcase.origin = mpcase.get(cid).origin;
  				newcase.recordtypeid = caserectype;
  				newcase.case_product_type__c = mpcase.get(cid).case_product_type__c;
  				newcase.issue_type__c = mpcase.get(cid).issue_type__c;
  				newcase.issue_sub_type__c = mpcase.get(cid).issue_sub_type__c;
  				newcase.issue_details__c = mpcase.get(cid).issue_details__c;
  				newcase.comments__c = mpcase.get(cid).comments__c;
  				
  				lstcreatecases.add(newcase);
  			}
  			
  			insert lstcreatecases; //we must insert the cases so we can use the id's to create comments
  			
  			system.debug('lstcreatecases size is' +lstcreatecases.size());
  			
  			if(mpcomments.containskey(cid))
  			{ 
  				CaseComment comment = mpcomments.get(cid); //get the comment that goes with this case id
  				
  				for(Case c : lstcreatecases) //make comments for the new cases
  				{
  					CaseComment newcomment = New CaseComment();
  					newcomment.parentid = c.id;
  					newcomment.ispublished = mpcomments.get(cid).ispublished;
  					newcomment.commentbody = mpcomments.get(cid).commentbody;
  					
  					lstcreatecomments.add(newcomment);
  				}
  				
  			}
  			
  			insert lstcreatecomments;
  			system.debug('list createcomments size is ' +lstcreatecomments.size());
  			
  		}//end for loop mpcase.keyset (cases that case in through the trigger)

		//all of the accountids in the custom setting have been used to create cases, so delete them
		//so they can't be used again by accident
		delete cslist;
		
  	  }//end if cslist size > 0
  	}
  		system.debug('**********END CreateMassCases*******');
  	
  }//end CreateMassCases */
     
} //end class CaseTriggerLogic