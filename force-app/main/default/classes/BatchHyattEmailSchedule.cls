/*
	jjackson Sonifi Solutions, October 2016
	Created this schedulable class to send out email notifications on cases created under the Hyatt master agreement,
	which requires that email notification go out at regular intervals until the case reaches a certain status value.
	There are two scheduled jobs in the salesforce cron that run this class every half hour:  Batch Hyatt Emails Hour
	and Batch Hyatt Emails Halfpast.  In order to make changes to this code or any of the methods it calls, these two
	scheduled jobs must be deleted under Monitoring/Scheduled Jobs in the UI, otherwise code changes can't be made.  Once
	code changes are saved, the scheduling code shown commented out down below can be run in the Execute Anonymous window
	of the Developer Console in order to reschedule this class to run every half hour.
*/

global class BatchHyattEmailSchedule implements Schedulable {

	  global void execute(SchedulableContext sc)
	  {
		
		//pull the list of hyatt entitlement cases that have an email notification due
		Datetime now = system.now();
		List<Case> lsthyattcases = New List<Case>();
		Id suppcaseid = Utilities.RecordTypeNameToId('Case', 'Support Case'); //we only want to query for support cases
		
		lsthyattcases = [ Select Id, casenumber, hyatt_email_frequency__c, email_notification_due__c, stop_hyatt_emails__c,
		                  customer_email__c, status, assetid, hyatt_broadband_support_phone__c, hyatt_interactive_support_phone__c,
		                  subject, origin, issue_type__c, case_product_type__c, issue_sub_type__c, issue_details__c, 
		                  issue_details_description__c, recordtypeid
		                  from Case where stop_hyatt_emails__c = false AND
		                  email_notification_due__c <= :now AND hyatt_email_frequency__c != null AND hyatt_email_frequency__c > 0
		                  AND customer_email__c != null AND origin != 'NOC Support' AND customer_role__c != 'Hotel Guest'
		                  AND (NOT issue_type__c like 'Project%') AND recordtypeid = :suppcaseid ]; //exclude PM cases, NOC cases,
		                  //hotel guest cases and Project cases from the notifications
		                  
		if(!lsthyattcases.IsEmpty())
		      { BatchHyattEmailCreationProcess.CreateEmailNotifications(lsthyattcases);  }
		      

	  }
}//end global class\\

/*  run the code below using the Developer Console Execute Anonymous window to create the scheduled batch job in the cron

        BatchHyattEmailSchedule b = New BatchHyattEmailSchedule();
     	String cronstrhour = '0 0 * * * ?';
    	String cronstrhalfpast = '0 30 * * * ?';
    	system.schedule('Batch Hyatt Emails Hour', cronstrhour, b);
    	system.schedule('Batch Hyatt Emails Halfpast', cronstrhalfpast, b);
    	
*/