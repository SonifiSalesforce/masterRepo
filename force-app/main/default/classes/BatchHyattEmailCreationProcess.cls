public with sharing class BatchHyattEmailCreationProcess
{
	public static void CreateEmailNotifications(List<Case> lstnotifycases)
	{
		if(lstnotifycases.IsEmpty()) { return; }
		
		List<Case> lstupdatecases = new List<Case>();
		
		//We must reset the email_notification_due__c field on each case to the next datetime an email has to go out.
		//We must then pass the list of cases in to the EmailUtilities class to create and send the emails.
		for(Case notifycase : lstnotifycases)
		{	
			Integer frequency = Integer.valueof(notifycase.hyatt_email_frequency__c);
			Datetime newnotificationdue = notifycase.email_notification_due__c.addHours(frequency);
			notifycase.email_notification_due__c = newnotificationdue;
			lstupdatecases.add(notifycase);
			
		}//end for loop lstnotifycases
		
		     CreateCaseEmailNotifications(lstnotifycases);
	
		if(lstupdatecases.size() > 0)
		{
			try{ update lstupdatecases;  }
			catch(Exception e)
			{ String errormessage = e.getmessage();
			  BatchProcessFailureNotification(errormessage, 'BatchHyattEmailCreationProcess');	
			}
		}
		
	}//end CreateEmailNotifications
	
	//jjackson 10/2016  for Hyatt cases, send the status update email notifications
     //This notification fires based on the BatchHyattEmail process. 
	public static void CreateCaseEmailNotifications(List<Case> lstcases)
	{

      	 system.debug('*********************BEGIN CreateCaseEmailNotifications*****************');
      	
      	 List<String> lstemailaddress = New List<String>();
      	 String emailsubject = 'SONIFI CASE STATUS NOTIFICATION FOR CASE ';
      	 Set<Id> setassetids = New Set<Id>();
 	   	 String genericsupportphone;
 	   	 if(test.isRunningTest())
 	   	 {
 	   	 	genericsupportphone = '1-800-999-9999';
 	   	 }
 	   	 else
 	   	 {
      	 	EmailAddress_TON__c csphone = EmailAddress_TON__c.getInstance('InteractiveCaseSupportNumber');
      	 	genericsupportphone = csphone.EmailAddress__c; 
 	   	 }
 	   	 
      	 List<Asset> lstcaseasset = New List<Asset>();
      	 Map<Id,string> mpasset = New Map<Id,string>();
      	 Map<Id,String> mpsupportphone = New Map<Id,String>();
   		 OrgWideEmailAddress orgaddress = [ Select Id, DisplayName from OrgWideEmailAddress where DisplayName = 'Sonifi Support Do-Not-Reply' LIMIT 1 ];
  		 Id orgaddressid = orgaddress.id;
 
  		       	 
      	 //get the product parent for each case and create a map.  If the case is for Broadband Product Parent,
      	 //the support phone number on the email comes from GIA_Support_Phone_Number__c on the related Account
      	 for(Case caseasset : lstcases)
      	 {  setassetids.add(caseasset.assetid);  
      	 	system.debug('case assetid added to set is ' +caseasset.assetid);
      	 }
      	 
      	 lstcaseasset = [ Select Id, Name from Asset where Id in :setassetids ];
      	 for(Asset pi : lstcaseasset)
      	 { mpasset.put(pi.Id, pi.Name); 
      	   system.debug('asset added to mp asset is ' +pi.id +', '+pi.Name);
      	 }
      	 
      	 mpsupportphone = GetSupportPhone(lstcases, mpasset);
   	 
      	 for(Case emailcase : lstcases)
      	 {
      	 		String body = '';
      	 		String CaseProductInventory = '';
      	 		String SupportPhone = '';
      	 		lstemailaddress.add(emailcase.customer_email__c);
       	 		
 				if(mpsupportphone.containskey(emailcase.id))
 				{  SupportPhone = mpsupportphone.get(emailcase.id);  
 					system.debug('support phone for ' +emailcase.casenumber +' is ' +SupportPhone);
 				}
 				else
 				{  SupportPhone = genericsupportphone;  }
      	 		
      	 		body = 'For your Sonifi Case Number ' +emailcase.casenumber +', the current status is ' +emailcase.status +'.' +'<br/>';
      	 		body +='If you have any questions, please call Sonifi Support at ' +SupportPhone +'.';
      	 
      	    try{
  				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				mail.setToAddresses(lstemailaddress);
	    		mail.setSubject(emailsubject+emailcase.casenumber);
	    		mail.setOrgWideEmailAddressId(orgaddressid);
	    		mail.saveAsActivity = false;
	    		mail.setHtmlBody(body);
    			Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
      	    }
      	    catch(Exception e)
      	    {
      	    	String Errmsg = 'Failure processing casenumber ' +emailcase.casenumber +', ' +e.getmessage() +', ' +e.getLineNumber();
      	    	system.debug('Error in BatchHyattEmailCreationProcess: ' +Errmsg);
      	    	BatchProcessFailureNotification(Errmsg, 'CreateCaseEmailNotifications');
      	    }
        
      	 }
      	 
      	 if(lstcases.size() > 0)
      	 {  
      	 	try{
      	 			CreateCaseTaskonCases(lstcases);
      	 	   }
      	 	catch(Exception ex)
      	 	{  String Errmsg = 'Error in CreateCaseTaskonCases ' + ex.getmessage() +', ' +ex.getlinenumber() +', ' +system.now(); 
      	 	   system.debug(Errmsg);
      	 	   BatchProcessFailureNotification(Errmsg, 'CreateCaseTaskonCases');
      	 	}
      	 }
      	 
     	 system.debug('**********************END CreateCaseEmailNotifications***************');
      	
 	}//end CreateCaseEmailNotifications
 
 	
 	//create a map that matches the case product parent to the correct support phone number
 	public static Map<Id,String> GetSupportPhone(List<Case> lstofcases, Map<Id,String> mpofassets)
 	{
 		system.debug('************************BEGIN GetSupportPhone********************');
 		
 		String genericgiasupport;
 		String genericinteractivesupport;
 		
 		Map<Id,String> mpphonenumbers = New Map<Id,String>();
 		
 		if(test.isRunningTest())
 		{
 			genericgiasupport = '1-800-999-0000';
 			genericinteractivesupport = '1-800-999-0000';
 		}
 		else
 		{
 			EmailAddress_TON__c csgia = EmailAddress_TON__c.getInstance('GIACaseSupportNumber');
      		genericgiasupport = csgia.EmailAddress__c;
      		EmailAddress_TON__c csint = EmailAddress_TON__c.getInstance('InteractiveCaseSupportNumber');
      		genericinteractivesupport = csint.EmailAddress__c;
 		}
 		for(Case c : lstofcases)
 		{
 		  if(mpofassets.containskey(c.assetid))
 		  {
 			String productparent = mpofassets.get(c.assetid);
 			system.debug('inside GetSupportPhone, productparent on this case is ' +productparent);
 			
 			if(productparent == 'Broadband Product Parent')
 			{
 				if(c.Hyatt_Broadband_Support_Phone__c != null)
 				{  mpphonenumbers.put(c.id,c.hyatt_broadband_support_phone__c); }
 				else
 				{  mpphonenumbers.put(c.id,genericgiasupport);  }
 				
 				system.debug(' support phone added to map is ' +mpphonenumbers.get(c.id));
 			}
 			
 			if(productparent != 'Broadband Product Parent')
 			{
  				if(c.Hyatt_Interactive_Support_Phone__c != null)
 				{  mpphonenumbers.put(c.id,c.hyatt_interactive_support_phone__c);  }
 				else
 				{  mpphonenumbers.put(c.id,genericinteractivesupport);  }
 				
 				system.debug('support phone added to map is ' +mpphonenumbers.get(c.id));	
 			}
 		  }//end if mpofassets contains case assetid
 		  else
 		  {  mpphonenumbers.put(c.id,genericinteractivesupport);  }
 
 		} //end for loop lstofcases
 		
 		system.debug('******************END GetSupportPhone*********************** ');
 		
 		return mpphonenumbers;
 		
 	}//end GetSupportPhone
 	
 	public static void CreateCaseTaskonCases(List<Case> lstcases)
 	{
 		system.debug('***************BEGIN  CreateCaseTaskonCases*****************');
 		
 		List<Task> lsttasks = New List<Task>();
 		Id Userid = UserInfo.getUserId();
 		Id rectypeid = Utilities.RecordTypeNameToId('Task', 'Support Case Task');
 		DateTime now = system.now();
 		
 		for(Case c : lstcases)
 		{
 			Task newtask = New Task(Subject='Hyatt Case Status Notification Email');
 			newtask.Priority = 'Low';
 			newtask.Status = 'Completed';
 			newtask.case_product_type__c = c.case_product_type__c;
 			newtask.Issue_type__c = c.Issue_type__c;
 			newtask.issue_sub_type__c = c.issue_sub_type__c;
 			newtask.issue_details__c = c.issue_details__c;
 			newtask.issue_details_description__c = c.issue_details_description__c;
 			newtask.case_status__c = c.status;
 			newtask.Task_Origin__c = 'Email';
 			newtask.Task_Customer_Role__c = c.customer_role__c;
 			newtask.Description = 'A case status notification email for case ' +c.casenumber +' has been sent to ' +c.customer_email__c +' at ' +now;
 			newtask.WhatId = c.Id;
 			newtask.RecordTypeId = rectypeid;
 			
 			lsttasks.add(newtask);
 			
 		}
 		try{ insert lsttasks;  }
 		catch(Exception e)
 		{
 			system.debug('Error creating tasks for support case notification emails ' +e.getmessage());
 			BatchProcessFailureNotification(e.getmessage(), 'CreateCaseTaskonCases');
 		}
 		
 		system.debug('***************END CreateCaseTaskonCases*************************');
 	}
 	
	
 	   //jjackson 10/2016 added this as a way to be notified if a batch process fails.
      //It can be used for any batch process just by passing in the error message from the catch Exception
      //and the name of the batch process.
      public static void BatchProcessFailureNotification(String errorstring, String processname)
      {
      		system.debug('****************BEGIN BatchProcessFailureNotification******************');
      	  
      	  String emailaddress;
      	  if(test.isRunningTest())
      	  {
      	  	emailaddress = 'jjackson@sonifi.com';
      	  }
      	  else
      	  {
      	  	EmailAddress_TON__c address = EmailAddress_TON__c.getInstance('BatchProcessFailureNotification');
      	  	emailaddress = address.EmailAddress__c;
      	  }
      	  
      	  List<String> lstemailaddress = New List<String>();
      	  lstemailaddress.add(emailaddress);
      	  DateTime currenttime = system.Now();
      	  String Subjectline = 'FAILURE IN BATCH PROCESS: ' +processname;
      	  String body = '';
      	  
      	  body = 'Batch process ' +processname +' failed at ' +currenttime +' with the following error message:  ';
      	  body += errorstring;
      	  
      	  Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(lstemailaddress);
	    	mail.setSubject(Subjectline);
	    	mail.saveAsActivity = false;
	    	mail.setHtmlBody(body);
    		Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    		
    	    system.debug('********************END BatchProcessFailureNotification****************');
     	
      }
	
}//end BatchHyattEmailCreationProcess