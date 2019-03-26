/****LOG***********************************************************************************
   
   jjackson 5/2018 BUG-00783 Email Notification for Pro:Centric when To Warehouse date is added to rack build wo
   jjackson 5/2018 testing change then pushing to gitlab repo
   jjackson 5/2018 testing making a change to a local repository of this then merging to main
   jjackson 4/2018 testing git
   jjackson 12/2017 - Add a backup email address to method FieldWorkOrderThirdPartyNotification.  This will
   send a copy of the customer's email to a sonifi mailbox in case the third party partner does not
   receive their emailed invoice summary.  We will keep a backup in the sonifi mailbox so we can forward
   another email if necessary.
   jjackson 10/2017 - Third Party Contracted Phase II: FieldWorkOrderThirdPartyNotification to email third
   party partners when field service work is performed at one of their properties.
   shawks 09/13/2017 - BUG-00744: 3rd Party Turn On Notices sent to incorrect Public Folder for Healthcare Sites 
   jjackson 8/21/17 BUG-00728 Field Service Third Party Cases -- email notification to third party case queue members
   when a Contracted Field Service case is dispatched to a Third Party queue
   shawks 06/20/2017 - BUG-00717:  Healthcare Email Notifications - Add EmailNotification
/*****************************************************************************************/
public with sharing class EmailUtilities {

   public static void doEmailPosts (Map<Id, List<String>> emailData) {

     system.debug('*************************************START doEmailPosts********************************');

        Messaging.reserveSingleEmailCapacity(9);
         
        List <String> toAddresses = new List<String>{};
        
        Map <String,List<String>> emailinfo = new Map <String,List<String>>();
        
        Set<ID> contactIds = new Set<ID>();

        Utilities.writeLog('Entered doEmailPosts....'+emailData.size() , EmailUtilities.class, 'doEmailPosts', LoggingLevel.DEBUG);        
        
        // First get a list of user Id 
        for (Id parentId : emailData.keyset()){
            contactIds.add(parentId);
        }
        // Obtain a list of the user Emails from the list of ID passed in
        List<User> ownerUsers = [SELECT u.Id, u.Email FROM User u WHERE u.Id IN :contactIds];
        // Now again loop through the Map that was passed in to build the Email information, 
        // ie email address and list of messages.
        for (Id parentId : emailData.keyset()){
            for (User emailuser : ownerUsers){
                // Make sure that the users from the soql matches the id's that where passed in.
                // If so assign them to the email info.
                if (emailuser.Id == ParentId)
                {
                   emailinfo.put(emailuser.Email,emailData.get(parentId));
                   break;
                }   
            }
        }
        // Loop through all the email addresses which belong to the user ids that were passed in.
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        for (Id userId: emailData.keyset())
        {       
            //toAddresses.add(emailaddr);

            Utilities.writeLog('doEmailPosts to address ....'+toAddresses, EmailUtilities.class, 'doEmailPosts', LoggingLevel.DEBUG);
            // Now send each Message that was passed in to the email that was given.
            for (String textbody :  emailData.get(userId) )
            {
                //Extract subject from the message.
                String messageSubject = '';
                if(textbody.indexOf('Site: ') != -1)//Finding site information for Order Item Email Notificaiton
                {
                    Integer subjectStartIndex;
                    Integer subjectEndIndex;
                    if(textbody.indexOf('Associated Items') != -1)
                    {
                        messageSubject += 'Work Order Items Updated : ';
                        subjectStartIndex = textbody.indexOf('Site: ');
                        subjectEndIndex = textbody.indexOf('<br/>',subjectStartIndex);
                        messageSubject += textbody.subString(subjectStartIndex, subjectEndIndex);
                        
                        
                        Integer workOrderNumberStart = textbody.indexOf(' Work Order:');
                        Integer workOrderNumberEnd = textbody.indexOf('<br/>', workOrderNumberStart);
                        messageSubject += textbody.subString(workOrderNumberStart,workOrderNumberEnd);
                    }
                    else
                    {
                        messageSubject += 'Order Items Updated : ';
                        subjectStartIndex = textbody.indexOf('Site: ');
                        subjectEndIndex = textbody.indexOf('<br/>',subjectStartIndex);
                        messageSubject += textbody.subString(subjectStartIndex, subjectEndIndex);
                        
                        //TODO need to change order item trigger logic and this method to pass in order number and add to line 70 below
                        Integer orderNumberStart = textbody.indexOf('Order Number: ');
                        Integer orderNumberEnd = textbody.indexOf('<br/>',orderNumberStart);
                        messageSubject += +' - '+textbody.subString(orderNumberStart,orderNumberEnd);
    
                    }
                }

                Utilities.writeLog('doEmailPosts message subject is  ....'+messageSubject, EmailUtilities.class, 'doEmailPosts', LoggingLevel.DEBUG);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(userId);
                mail.setSubject(messageSubject);
                mail.saveAsActivity = false;
                mail.setUseSignature(false);
                // mail.setSubject('Record Clean Up Status: ' + a.Status);
                mail.setHTMLBody(textbody);
                mailList.add(mail);
              //  Utilities.writeLog('doEmailPosts message ....'+textbody , EmailUtilities.class, 'doEmailPosts', LoggingLevel.DEBUG);

        
               //Utilities.writeLog('Exit doEmailPosts....Result '+emailresult , EmailUtilities.class, 'doEmailPosts', LoggingLevel.DEBUG);
            }
            toAddresses.clear();
        }
        Messaging.SendEmailResult[] emailresult = Messaging.sendEmail(mailList);
        
        system.debug('*************************END doEmailPosts*********************************');
  }
    
    //shawks:BUG-00744 - Change parameter from Account Type to Project Type
    //shawks:BUG-00717 - Add parameter for Account Type 
    //jjackson 10/2014 Create an email for a turn-on notice  BUG-00263  
    //public static void EmailTurnonNotice(String messagetext, String sitename, String noticetype, String accountType){
    public static void EmailTurnonNotice(String messagetext, String sitename, String noticetype, String projectType){
        system.debug('***********************START EmailTurnonNotice*****************************');
        
        String messageSubject = '';
        Id thisuser = UserInfo.getUserId();
        List<Messaging.SingleEmailMessage> emails = new list<Messaging.SingleEmailMessage>();
        String email;
        List<String> emailaddress = new list<String>();
        
        //get turn on notice email address from custom setting unless we are running a test
        if(test.isRunningTest())
        {
           email = 'jjackson@sonifi.com'; 
           emailaddress.add(email);
        }
        else
        {
           //shawks:BUG-00744 - Now use Project Type instead of account type
           //if(accounttype == 'Healthcare Site') //shawks:BUG-00717 - Account Type determines which email address to retrieve
           if(projectType == 'Healthcare')
           {
              EmailAddress_TON__c cs = EmailAddress_TON__c.getInstance('HealthcareEmailNotification');
              email = cs.EmailAddress__c;
           }
           else
           {
                EmailAddress_TON__c cs = EmailAddress_TON__c.getInstance('TurnOnNotice');
                email = cs.EmailAddress__c;
           }
             //email = 'jjackson@sonifi.com'; 
             emailaddress.add(email);
        }

        //shawks:BUG-00744 - Now use Project Type instead of account type
        //if(accounttype == 'Healthcare Site')  //shawks:BUG-00717 - Account Type determines the format of the email subject
        if(projectType == 'Healthcare')
        {
           if(noticetype == 'Install')  
           {   messageSubject = sitename +':  TURN ON NOTICE';   }
           else if(noticetype == 'Deinstall')
           {   messageSubject = sitename +':  SHUT OFF NOTICE';   }
           else
           { messageSubject = sitename +':  SERVICES TURNED ON AND SHUT OFF';  }
        }
        else
        {
           if(noticetype == 'Install')  
           {   messageSubject = 'TURN ON NOTICE:   ' +sitename;   }
           else if(noticetype == 'Deinstall')
           {   messageSubject = 'SHUT OFF NOTICE:  ' +sitename;   }
           else
           { messageSubject = 'SERVICES TURNED ON AND SHUT OFF:  ' +sitename;  }
        }

      //  Utilities.writeLog('EmailTurnonNotice message subject is  ....'+messageSubject, EmailUtilities.class, 'EmailTurnonNotice', LoggingLevel.DEBUG);
        

        //emailaddress.add('thofer@sonifi.com');
        //emailaddress.add('jjackson@sonifi.com');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailaddress);
        mail.setTargetObjectId(thisuser);
        mail.setSubject(messageSubject);
        mail.saveAsActivity = false;
        mail.setUseSignature(false);
        mail.setPlainTextBody(messagetext);
       // Utilities.writeLog('EmailTurnonNotice message ....'+messagetext , EmailUtilities.class, 'EmailTurnonNotice', LoggingLevel.DEBUG);
        
        emails.add(mail);
        
        Messaging.SendEmailResult[] turnonnoticeresult = Messaging.sendEmail(emails);
        
      system.debug('*************************END EmailTurnOnNotice***************************');
    }
    
    public static void PendingCaseViolationNotification(List<Case> casetriggerlist)
    {

        system.debug('***************BEGIN PendingCaseViolationNotification*************************');
 
        Map<Id,Set<Id>> casetorecipients = New Map<Id,Set<Id>>();
        List<Case> dispatchedcaselist = New List<Case>();
        List<Case> nondispatchedcaselist = New List<Case>();
        List<User> allusers = New List<User>();
        Map<Id,String> useridtoemail = New Map<Id,String>();
        
        allusers = [ Select Id, email, isactive from User where isactive = true ];
        for(User userrec : allusers )
        { useridtoemail.put(userrec.id, userrec.email);  }
        
        
        for(Case caserec : casetriggerlist) //separate cases into dispatched and non-dispatched because recipients are different
        {
            Set<Id> dispatchedcaserecipients = New Set<Id>();
            Set<Id> nondispatchedcaserecipients = New Set<Id>();
            
            if(caserec.dispatched__c == true)
            {  dispatchedcaselist.add(caserec);   
               dispatchedcaserecipients.add(caserec.ownerid);
               dispatchedcaserecipients.add(caserec.manager__c);
               dispatchedcaserecipients.add(caserec.sr_director__c);
               dispatchedcaserecipients.add(caserec.sr_manager__c);
               dispatchedcaserecipients.add(caserec.technician__c);
               dispatchedcaserecipients.add(caserec.on_call_tech__c);
               dispatchedcaserecipients.add(caserec.lead_tech_1__c);
               
            }
            else
            {  nondispatchedcaselist.add(caserec);  
               nondispatchedcaserecipients.add(caserec.ownerid);
            }
            
            if(!dispatchedcaserecipients.IsEmpty())
            { casetorecipients.put(caserec.id,dispatchedcaserecipients); }
            
            if(!nondispatchedcaserecipients.IsEmpty())
            { casetorecipients.put(caserec.id,nondispatchedcaserecipients);  }
        }
        system.debug('dispatchedcaselist size is ' +dispatchedcaselist.size());
        system.debug('nondispatchedcaselist size is ' +nondispatchedcaselist.size());
                
        if(dispatchedcaselist.size() > 0)
        {  CreateandSendEmail(dispatchedcaselist,casetorecipients,useridtoemail); }
        
        if(nondispatchedcaselist.size() > 0)
        {  CreateandSendEmail(nondispatchedcaselist,casetorecipients,useridtoemail);  }
        
    }   //end of PendingCaseViolationNotification
        
    public static void CreateandSendEmail(List<Case> caselist, Map<Id,Set<Id>> mpcasetorecipients, Map<Id,String>mpusertoemail)         
    {
        system.debug('*********************BEGIN CreateandSendEmail***********************');
        
            List<Account> relatedaccounts = New List<Account>();
            List<Entitlement> relatedentitlement = New List<Entitlement>();
            List<Case> lstupdatecase = New List<Case>();
            Map<Id,String> acctidtoname = New Map<Id,String>();
            Map<Id,String> entidtoname = New Map<Id,String>();
            Set<Id> setaccountid = new Set<Id>();
            Set<Id> entitlementid = New Set<Id>();
            
            for(Case cases : caselist)
            {
                setaccountid.add(cases.accountid);
                entitlementid.add(cases.entitlementid);
            }
            
            relatedaccounts = [ Select id, name from Account where id in :setaccountid ];
            relatedentitlement = [ Select id, name from Entitlement where id in :entitlementid ];
            
            if(relatedaccounts.size() > 0 )
            {
                for(Account acct : relatedaccounts)
                { acctidtoname.put(acct.id, acct.name); }
            }
            
            if(relatedentitlement.size() > 0)
            {
                for(Entitlement ent : relatedentitlement)
                { entidtoname.put(ent.id, ent.name);  }
            }
                
            for(Case dcrec : caselist)
            {   
                    List<String> emailaddresses = New List<String>();
                    Set<Id> emailrecipientids = New Set<Id>();
                    if(mpcasetorecipients.containskey(dcrec.id))
                    { emailrecipientids = mpcasetorecipients.get(dcrec.id);
                      for( Id userid : emailrecipientids )
                      { if(mpusertoemail.containskey(userid))
                        { emailaddresses.add(mpusertoemail.get(userid)); }  
                      }
                    }
             
                //jjackson 8/2016 added TOD TCC mgrs to the distribution for dispatched cases BUG-00644
                //if the case is not dispatched, add the TAC email to the
                //list of email addresses in addition to the case owner (added above);
                //get the email address from custom setting so it can be changed without coding
                if(dcrec.dispatched__c == false)
                {
                    if(test.IsRunningTest())
                    { emailaddresses.add('jjackson@sonifi.com'); }
                    else
                    { EmailAddress_TON__c address = EmailAddress_TON__c.getInstance('CaseViolationNotification');
                      emailaddresses.add(address.EmailAddress__c);
                    }
                }
                else
                {
                    if(test.IsRunningTest())
                    { emailaddresses.add('jjackson@sonifi.com');  }
                    else
                    { EmailAddress_TON__c mgraddress = EmailAddress_TON__c.getInstance('FieldCaseViolationNotif');
                      emailaddresses.add(mgraddress.EmailAddress__c);
                    }
                } 
                
                //for test purposes only
                //emailaddresses.add('jjackson@sonifi.com');
                //emailaddresses.add('tfieber@sonifi.com');
                //*****************************************
                String accountname;
                String entitlementname;
                String messagebody;
                if(acctidtoname.containskey(dcrec.accountid))
                { accountname = acctidtoname.get(dcrec.accountid);  }
                if(entidtoname.containskey(dcrec.entitlementid))
                { entitlementname = entidtoname.get(dcrec.entitlementid);  }
                String fullrecordurl = URL.getSalesforceBaseUrl().toExternalform() +'/' +dcrec.id;
                String messagesubject = 'WARNING:  Case ' +dcrec.CaseNumber +' for Account ' +accountname +' is nearing expiration';
                messagebody = 'A case milestone for this property will expire in two hours: ' +'<br/>';
                messagebody += 'Case Number:  ' +dcrec.casenumber +'<br/>';
                messagebody += 'Subject:  ' +dcrec.subject +'<br/>';
                messagebody += 'Case Priority:  ' +dcrec.priority +'<br/>';
                messagebody += 'Entitlement Type:  ' +entitlementname +'<br/>';
                messagebody += fullrecordurl;
                
                system.debug('email messagebody is ' +messagebody);
                //for(String email : emailaddresses)
                //{  system.debug('email recipients are ' +email);  }
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(emailaddresses);
                //mail.setTargetObjectId(thisuser);
                mail.setSubject(messagesubject);
                mail.saveAsActivity = false;
                mail.setUseSignature(false);
                mail.setHTMLBody(messagebody);
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                
                dcrec.nearing_expiration__c = false;
                
                lstupdatecase.add(dcrec);
                
            }//end for loop for cases
            
            if(lstupdatecase.size() > 0)
            try{  update lstupdatecase;  }
            catch(Exception ex)
            { system.debug('CreateAndSendEmailError while updating cases:  ' +ex.getMessage());  }
            
            system.debug('*************************END CreateAndSendEmail*****************');
             
      }//end CreateandSendEmail
      
      //jjackson 9/2016 BUG-00621
      public static void GroupServicesNotification(List<SBQQ__Subscription__c> lstgrouplcli)
      {
          system.debug('************************BEGIN GroupServicesNotification******************');
          
          Map<Id,List<SBQQ__Subscription__c>> mpgrouplineitems = New Map<Id,List<SBQQ__Subscription__c>>();
          List<String> lstemailaddresses = New List<String>(); //list of email addresses needed for mail functions
          
          //get email addresses from custom setting
          if(test.IsRunningTest())
          {
            lstemailaddresses.add('jjackson@sonifi.com');
          }
          else
          { List<Group_Services_Email_Notification__c> grouplist = New List<Group_Services_Email_Notification__c>();
            grouplist = Group_Services_Email_Notification__c.getall().values();
            for(Group_Services_Email_Notification__c gs : grouplist)
            {       lstemailaddresses.add(gs.EmailAddress__c);  }
            //lstemailaddresses.add('jjackson@sonifi.com');
          }
          
          for(SBQQ__Subscription__c lcli :lstgrouplcli)
          
          {
            if(mpgrouplineitems.containskey(lcli.sbqq__contract__c))
            {
                mpgrouplineitems.get(lcli.sbqq__contract__c).add(lcli);
            }
            else
            {
                List<sbqq__subscription__c> templist = New List<sbqq__subscription__c>();
                templist.add(lcli);
                mpgrouplineitems.put(lcli.sbqq__contract__c,templist);
            }
          }
          
          if(mpgrouplineitems.size() > 0)
          {
            for(Id conid :mpgrouplineitems.keyset())    
            {
                List<sbqq__subscription__c> lstgetlineitems = New List<sbqq__subscription__c>();
                lstgetlineitems = mpgrouplineitems.get(conid);
                
                sbqq__subscription__c lcli = lstgetlineitems.get(0);
                String subject = 'Group Services Notification for ' + lcli.account_name__c;
                String contracturl = URL.getSalesforceBaseURL().toExternalForm() +'/' +conid;
                String body = '';
                body = 'Contract ' +lcli.sbqq__contract__r.contractnumber +' for ' +lcli.account_name__c +' has been changed to Order Approved.' +'<br/>';
                body += 'The following group services line items are on the contract: ' +'<br/><br/>';
                for(sbqq__subscription__c lines : lstgetlineitems)
                {
                    body += lines.name__c +'<br/>';
                }
                body += '<br/>' +'<br/>';
                body+= contracturl;
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(lstemailaddresses);
                mail.setSubject(subject);
                mail.saveAsActivity = false;
                mail.setHtmlBody(body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                
            }//end for loop mpgrouplineitems
          
          }
      }//end GroupServicesNotification
      
      //jjackson 10/2016 for Hyatt Cases, send the final notification when the case goes to a closed status
      //this notification fires based on the case trigger
      public static void ClosedCaseEmailNotification(List<Case> lstclosedcases)
      {
         system.debug('******************BEGIN ClosedCaseEmailNotification*****************');
        
         List<String> lstemailaddress = New List<String>();
         String emailsubject = 'SONIFI CASE STATUS NOTIFICATION FOR CASE ';
         String genericgiasupport;
         String genericinteractivesupport;
         
         if(!test.isRunningTest())
         {
            EmailAddress_TON__c csgia = EmailAddress_TON__c.getInstance('GIACaseSupportNumber');
            genericgiasupport = csgia.EmailAddress__c;
            EmailAddress_TON__c csint = EmailAddress_TON__c.getInstance('InteractiveCaseSupportNumber');
            genericinteractivesupport = csint.EmailAddress__c;
         }
         else  //if the unit test code is running, we have to populate the phone number strings ourselves
         {
            genericgiasupport = '1-800-999-0000';
            genericinteractivesupport = '1-800-999-1111';
         }
         
         Set<Id> setassetid = New Set<Id>();
         List<Asset> lstassets = New List<Asset>();
         Map<Id,String> mpassetidtoname = new Map<Id,String>();
         OrgWideEmailAddress orgaddress = [ Select Id, DisplayName from OrgWideEmailAddress where DisplayName = 'Sonifi Support Do-Not-Reply' LIMIT 1 ];
         Id orgaddressid = orgaddress.id;
         
         for(Case caseasset : lstclosedcases)
         {  setassetid.add(caseasset.assetid);  }
         
         lstassets = [ Select Id, Name from Asset where Id in :setassetid ];
         for(Asset assrec : lstassets)
         {
            mpassetidtoname.put(assrec.Id, assrec.Name);
         }
         
         
         for(Case emailcase : lstclosedcases)
         {
                String body = '';
                String ProdParent = '';
                String SupportPhone = '';
                lstemailaddress.add(emailcase.customer_email__c);
                
                if(mpassetidtoname.containskey(emailcase.assetid))
                {  ProdParent = mpassetidtoname.get(emailcase.assetid);  }
                
                if(ProdParent == 'Broadband Product Parent')
                {  if(emailcase.hyatt_broadband_support_phone__c != null)
                   {  SupportPhone = emailcase.hyatt_broadband_support_phone__c;  }
                   else
                   {  SupportPhone = genericgiasupport;  }
                }
                else
                {  
                   if(emailcase.hyatt_interactive_support_phone__c != null)
                   {  SupportPhone = emailcase.hyatt_interactive_support_phone__c;  }
                   else
                   {  SupportPhone = genericinteractivesupport;  }
                }

                
                body = 'Your Sonifi Case Number ' +emailcase.casenumber +' has reached a closed status. There will be no more status notifications. ' +'<br/>';
                body += 'If you have any questions, please call Sonifi Support at ' +SupportPhone +'.' +'<br/>';
             try
             {  
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
                String errmsg = e.getmessage() +', ' +e.getlinenumber();
                system.debug('Failure in EmailUtilities.ClosedCaseEmailNotification: ' +errmsg);
                BatchHyattEmailCreationProcess.BatchProcessFailureNotification(errmsg, 'EmailUtilities.ClosedCaseEmailNotification');
             }

         }
         
         BatchHyattEmailCreationProcess.CreateCaseTaskonCases(lstclosedcases); //create a case task on each case when the final email goes out

        system.debug('***************END ClosedCaseEmailNotification********************');         
        
      }//end ClosedCaseEmailNotification
      
      //jjackson added this Dec 2016 for field work order automation:  send customers a work order summary when work order goes to
      //billing approved
      public static void FieldWorkOrderCustomerNotification(Map<Id,WorkOrder> mpworkorder, Map<Id,List<FieldWorkOrder_Events__c>> mpevents)
      {
         system.debug('********************BEGIN FieldWorkOrderCustomerNotification*************');
         
         List<WorkOrderLineItem> lineitemlist = New List<WorkOrderLineItem>();
         Map<Id,List<WorkOrderLineItem>> mpwotolineitem = New Map<Id,List<WorkOrderLineItem>>();
         String emailsubject = 'SONIFI WORK SUMMARY FOR:  ';
         OrgWideEmailAddress orgaddress = [ Select Id, DisplayName from OrgWideEmailAddress where DisplayName = 'Sonifi Support Do-Not-Reply' LIMIT 1 ];
         Id orgaddressid = orgaddress.Id;
         
         //pull a list of all the related work order line items that are for parts only so they can be listed on the email:
         lineitemlist = [Select id, workorderid, product_code__c, part_number__r.name, qty__c, part_price__c,
                         netsuite_location__c from
                         WorkOrderLineItem where workorderid in :mpworkorder.keyset() AND NetSuite_Location__c = 'FBL' AND
                         (NOT part_number__r.name like '%LABOR%') AND (NOT part_number__r.name like '%TRIP%') ];
                         
         if(lineitemlist.size() > 0)
         {
            for(WorkOrderLineItem line : lineitemlist)
            {
                if(mpwotolineitem.containskey(line.workorderid))
                {
                    mpwotolineitem.get(line.workorderid).add(line);
                }
                else
                {
                   List<WorkOrderLineItem> templist = New List<WorkOrderLineItem>();
                   templist.add(line);
                   mpwotolineitem.put(line.workorderid, templist);
                }
            }
         }
         
         for(Id woid : mpworkorder.keyset())
         {
            
            String body = '';
            String emailaddress = '';
            WorkOrder wo = New WorkOrder();
            wo=mpworkorder.get(woid);
            List<String> lstemailaddress = New List<String>();
            
            if(wo.contact_email__c != null)
            { lstemailaddress.add(wo.contact_email__c); }
            
            if(wo.customer_email__c != null)
            {  lstemailaddress.add(wo.customer_email__c); }
            
            system.debug('fieldworkordercustomernotification email address = ' +emailaddress);
            
            
            List<FieldWorkOrder_Events__c> fwoelist = New List<FieldWorkOrder_Events__c>();
            
         if(lstemailaddress.size() > 0)
         {
            
            if(mpevents.containskey(woid))
            { fwoelist = mpevents.get(woid); }
            
            String subject = emailsubject +wo.account_site_id__c +', ' +wo.account_name__c;
            
            if(wo.case_number__c != null)
            { body = 'Case Number: ' +wo.case_number__c +'\n'; }
            else
            { body = 'Case Number: No Related Case' +'\n';  }
            body += 'Work Order Number:  ' +wo.workordernumber +'\n';
            body += 'Work Order Signed By:  ' +wo.signature_name__c +'\n';
            body += 'Signer Title:    ' +wo.customer_title__c +'\n'+'\n';
            body += 'We recently performed work at your property as summarized below:' +'\n'+'\n';

            body += wo.invoice_summary__c +'\n'+'\n';
            if(fwoelist.size() > 0)
            {
                for(FieldWorkOrder_Events__c event : fwoelist)
                {
                    body += event.event_type__c +':    ' +event.event_name__c +':    ' +event.event_description__c +'       ' +'Hours:  ' +event.hours__c +'\n';
                }
            }
            body += '\n' +'\n';
            
            if(mpwotolineitem.containskey(woid))
            {
                body += 'Part(s) installed: ' +'\n';
                
                List<WorkOrderLineItem> lstusedparts = New List<WorkOrderLineItem>();
                lstusedparts = mpwotolineitem.get(woid);
                
                for(WorkOrderLineItem woli : lstusedparts)
                {
                    body += woli.part_number__r.name +'      ' +woli.product_code__c +'      ' +woli.qty__c +'       '+woli.part_price__c +'\n';    
                }
                
            }
            
            try
             {  
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(lstemailaddress);
                mail.setSubject(subject);
                mail.setOrgWideEmailAddressId(orgaddressid);
                mail.saveAsActivity = false;
                mail.setPlainTextBody(body); //had to make this a text email format to accommodate blank space in the strings for the body
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
             }
             catch(Exception e)
             {
                String errmsg = e.getmessage() +', ' +e.getlinenumber();
                system.debug('Failure in EmailUtilities.FieldWorkOrderCustomerNotification: ' +errmsg);
             }
          }//end if emailaddress != null
         }//end for loop mpworkorder.keyset
            system.debug('***************END FieldWorkOrderCustomerNotifiction*******************');
      
      }//end method FieldWorkOrderCustomerNotification

   //shawks: BUG-00717 - Add new method for emailing Healthcare Notifications
   public static void EmailNotification(List<String> lstEmailAddress, String strEmailSubject, String strEmailBody)
   {
      System.Debug('***********************START EmailNotification*****************************');

      Id thisuser = UserInfo.getUserId();
      List<Messaging.SingleEmailMessage> emails = New List<Messaging.SingleEmailMessage>();

      //  Utilities.writeLog('EmailNotification message subject is  ....'+strEmailSubject, EmailUtilities.class, 'EmailNotification', LoggingLevel.DEBUG);

      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setToAddresses(lstEmailAddress);
      mail.setTargetObjectId(thisuser);
      mail.setSubject(strEmailSubject);
      mail.saveAsActivity = false;
      mail.setUseSignature(false);
      mail.setPlainTextBody(strEmailBody);
      // Utilities.writeLog('EmailNotification message ....'+stremailBody , EmailUtilities.class, 'EmailNotification', LoggingLevel.DEBUG);

      emails.add(mail);

      Messaging.SendEmailResult[] notificationeresult = Messaging.sendEmail(emails);

      System.Debug('*************************END EmailNotification***************************');
   }//end EmailNotification method
   
   //jjackson when a ContractedFieldService case is dispatched, email the members of the third party queue who should get notified
   //this is being done with custom email because the default SF queue email doesn't show enough info and doesn't show who all the
   //people are who received the email
    public static void NotifyThirdPartyCaseQueueMembers(List<Case> lstdcases, Map<Id,Case> triggeroldmap)
   {
         system.debug('*******************BEGIN NotifyThirdPartyCaseQueueMembers****************');
         
         Id recid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
         List<Case> lstprocesscases = new List<Case>();
         List<Group> lstgroup = New List<Group>();
         List<GroupMember> lstgm = New List<GroupMember>();
         List<User> lstuser = New List<User>();
         Set<Id> setqueueids = New Set<Id>();
         Map<String,Id> mpstatetoqueueid = New Map<String,Id>();
         Map<Id,String> mpqueuetoname = New Map<Id,String>();
         Map<Id,List<Id>> mpqueuetomember = New Map<Id,List<Id>>();
         Map<Id,String> mpusertoemail = New Map<Id,String>();
         Set<Id> setgmid = New Set<Id>();
         
         for(Case c : lstdcases)
         {
            if(c.recordtypeid == recid)
            {
                if(test.IsRunningTest())
                {
                    if(c.dispatch_case__c == true)
                    {  lstprocesscases.add(c);  
                       setqueueids.add(c.ownerid);
                       system.debug('ownerid in emailtest is ' +c.ownerid);
                    }
                }
                else
                {
                    if(c.dispatch_case__c == true && triggeroldmap.get(c.id).dispatch_case__c == false)
                    {
                        lstprocesscases.add(c);
                    
                        if(String.valueOf(c.ownerid).left(3) == '00G')
                        { setqueueids.add(c.ownerid); }
                    }
                }
            }
         }
     
         List<String> lstemailaddresses = New List<String>(); //list of email addresses needed for mail functions
         List<Messaging.SingleEmailMessage> emails = New List<Messaging.SingleEmailMessage>();
      
      if(lstprocesscases.size() > 0 && setqueueids.size() > 0) 
      {
         lstgroup = [ Select Id, Type, Name,(Select UserOrGroupId, GroupId from GroupMembers) from Group where Type = 'Queue' AND
                      Id in :setqueueids ];
                      
         for(Group gr : lstgroup)
         {
            mpstatetoqueueid.put(gr.Name.right(2), gr.id);
            mpqueuetoname.put(gr.id, gr.Name);
        
            for(GroupMember gm :gr.GroupMembers)
            {
                if(mpqueuetomember.containskey(gr.Id))
                {
                    mpqueuetomember.get(gr.Id).add(gm.UserOrGroupId);
                }
                else
                {
                    List<Id> templist = New List<Id>();
                    templist.add(gm.UserOrGroupId);
                    mpqueuetomember.put(gr.Id, templist);
                }
            
            setgmid.add(gm.UserOrGroupId);
          }
        }
        
        lstuser = [Select Id, email from User where id in :setgmid ];
        for(User u :lstuser)
        { mpusertoemail.put(u.Id,u.email) ;  }
      }  
         
 
      for(Case dcase : lstprocesscases)
      {
          system.debug('case ownerid is ' +dcase.ownerid);
        
          if(mpqueuetomember.containskey(dcase.ownerid))
          {
            List<Id> lstmemberid = mpqueuetomember.get(dcase.ownerid);
            for(Id memid : lstmemberid)
            { 
                system.debug('queue member id is ' +memid);
                  
                if(mpusertoemail.containskey(memid))
                { lstemailaddresses.add(mpusertoemail.get(memid)); 
                  system.debug('email address added to email address list is ' +mpusertoemail.get(memid));
                }
            }
          }

         if(lstemailaddresses.size() > 0 && mpqueuetoname.containskey(dcase.ownerid))
         {  String emailsubj = 'CONTRACTED FIELD SERVICE CASE #'+dcase.casenumber +' DISPATCHED TO ' +mpqueuetoname.get(dcase.ownerid);
            
            String emailbody = 'Case Number: ' +dcase.casenumber +'<br/>';
            emailbody += 'Case Subject: ' +dcase.subject +'<br/>';
            emailbody += 'Case Priority: ' +dcase.priority +'<br/>';
            emailbody += 'Case Third Party Partner: ' +dcase.related_third_party_partner_name__c +'<br/>';
            emailbody += 'Case Third Party Partner Ticket #: ' +dcase.partner_ticket_number__c +'<br/>';
            emailbody += 'Case Opened: ' +dcase.CreatedDate +'<br/>';
            emailbody += 'Case Comments: ' +dcase.comments__c +'<br/>';
            emailbody += 'Site ID:  ' +dcase.site_id_formula__c +'<br/>';
            emailbody += 'Location City:  ' +dcase.physical_city__c +'<br/>';
            emailbody += 'Location State:  ' +dcase.physical_state__c +'<br/>'+'<br/>'+'<br/>';
            emailbody += URL.getSalesforceBaseUrl().toExternalForm()+'/'+dcase.id; //jjackson added link to the case Jan 2018
 
            //system.debug('emailbody is ' +emailbody);
                    
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(lstemailaddresses);
            mail.setSubject(emailsubj);
            mail.saveAsActivity = false;
            mail.setUseSignature(false);
            mail.setHTMLBody(emailbody);
 
            emails.add(mail);

            Messaging.SendEmailResult[] notificationeresult = Messaging.sendEmail(emails);
         }
         else
         { system.debug('No email addresses were found for third party queue id');  }
     } //end case for loop
         
         system.debug('**********************END NotifyThirdPartyCaseQueueMembers************************');
 
   }//end NotifyThirdPartyCaseQueueMembers
   
   //jjackson ThirdPartyCase and WorkOrder Phase II 10/2017 Notify third party partner
   //of work done at one of their locations
   public static void FieldWorkOrderThirdPartyNotification(Map<Id,WorkOrder> tpfwomap)
   {
        system.debug('**************BEGIN FieldWorkOrderThirdPartyNotification*****');
          
        //jjackson 12/2017 get an email address from a custom setting to be used as a backup address
        //that sends a copy of the customer's email to a sonifi mailbox
        String inhouseemail;
        if(!test.isRunningTest())
        {
            EmailAddress_TON__c emails = EmailAddress_TON__c.getValues('ThirdPartyFWOBackup');
            inhouseemail = emails.EmailAddress__c;
            //system.debug('value of ' +emails.EmailAddress__c);
        }
        else
        {   //tests can't see custom settings, so when the unit test is running,
            //we must provide the email address when the test runs this method
            inhouseemail = 'thirdpartyfwo@sonifi.com';
        }
        
        List<WorkOrderLineItem> lstwoli = New List<WorkOrderLineItem>();
        List<Case> lstrelatedcase = New List<Case>();
        List<Field_Service_Digest__c> lstfsd = New List<Field_Service_Digest__c>();
        List<Attachment> lstattach = New List<Attachment>();
        Set<Id> setcaseid = New Set<Id>();
        OrgWideEmailAddress orgaddress = [ Select Id, DisplayName from OrgWideEmailAddress where DisplayName = 'Sonifi Support Do-Not-Reply' LIMIT 1 ];
        
        //get the case id's from the work order records and put them in a set so the
        //related cases can be queried for information
        for(Id woid : tpfwomap.keyset())
        {
            WorkOrder wo = tpfwomap.get(woid);
            setcaseid.add(wo.caseid);
        }
        
        Map<Id,List<WorkOrderLineItem>> mpwotowoli = New Map<Id,List<WorkOrderLineItem>>();
        Map<Id,Case> mpwotocase = New Map<Id,Case>();
        Map<Id,List<Field_Service_Digest__c>> mpcasetofsd = New Map <Id,List<Field_Service_Digest__c>>();
        Map<Id,Attachment> mpwotoattach = new Map<Id,Attachment>();
        
        //get all the work order line items that are related to the work orders in the trigger and
        //put them in a map
        lstwoli = [ select workorderid, product_code__c, qty__c, part_number__r.name from WorkOrderLineItem
                    where workorderid in :tpfwomap.keyset() AND (not(part_number__r.name like '%LABOR%')) AND
                    (not(part_number__r.name like '%TRIP%')) ];
        
        //get all the cases that are related to the work orders in the trigger and put them in a map. The
        //subquery gets all the field service digest records that are related to the cases.  We need these
        //to put the checkin and checkout times on the email         
        lstrelatedcase = [ select partner_ticket_number__c, physical_city__c, physical_state__c, account.name,
                           account.physical_street_address_line_1__c, account.physical_postal_code__c, id,
                           (Select case__c, id, checkin_time__c, checkout_time__c, time_spent_on_site_mins__c,
                            time_spent_on_site_hrs__c from Field_Service_Digest__r)
                            from Case where id in :setcaseid ];
                            
        //get the signed attachment from the work orders that contains the signature image & add to map
        lstattach = [ Select Id, Name, Parentid, Body from Attachment where parentid in :tpfwomap.keyset() AND
                          name like 'Signed Document%' ];
        system.debug('lstattach size is ' +lstattach.size());
                            
                    
        for(WorkOrderLineItem li : lstwoli)
        {
            if(mpwotowoli.containskey(li.workorderid))
            {
                mpwotowoli.get(li.workorderid).add(li); 
                
            }
            else
            {
                List<WorkOrderLineItem> maplist = New List<WorkOrderLineItem>();
                maplist.add(li);
                mpwotowoli.put(li.workorderid, maplist);
            }
        }
        
        for(Case c : lstrelatedcase)
        {
            mpwotocase.put(c.id, c);
            
            for(Field_Service_Digest__c f : c.Field_Service_Digest__r)
            {
                if(mpcasetofsd.containskey(c.Id))
                {
                    mpcasetofsd.get(c.id).add(f);
                }
                else
                {
                    List<Field_Service_Digest__c> templist = New List<Field_Service_Digest__c>();
                    templist.add(f);
                    mpcasetofsd.put(f.case__c, templist);
                }
            }
        }
        
        for(Attachment a :lstattach)
        { mpwotoattach.put(a.parentid, a); 
        
        system.debug('wo in attachment map is ' +a.parentid);
        
        }
        //now process the work orders in the trigger and create emails
        for(WorkOrder wo : tpfwomap.values())
        {
            List<String> emailaddresses = New List<String>();
            List<Field_Service_Digest__c> lstdigest = New List<Field_Service_Digest__c>();
            
            if(wo.third_party_email__c != null)
            {
                List<WorkOrderLineItem> thiswolist = New List<WorkOrderLineItem>();
                if(mpwotowoli.containskey(wo.id))
                {  thiswolist = mpwotowoli.get(wo.id);  }
                
                emailaddresses.add(wo.third_party_email__c);
                emailaddresses.add(inhouseemail);
                String emailsubj = 'SONIFI WORK SUMMARY FOR ' +wo.account_name__c +', TICKET ' +wo.third_party_ticket__c;
                String body;
                body = 'Location Name: ' +wo.account_name__c +'<br/>';
                body += mpwotocase.get(wo.caseid).account.physical_street_address_line_1__c +'<br/>';
                body += mpwotocase.get(wo.caseid).physical_city__c +', ' +mpwotocase.get(wo.caseid).physical_state__c;
                body += '&nbsp;&nbsp;&nbsp;' +mpwotocase.get(wo.caseid).account.physical_postal_code__c +'<br/>' +'<br/>';
                body += 'Contact Name/Title: ' +wo.signature_name__c +', '+wo.customer_title__c +'<br/>'+'<br/>';
                if(mpcasetofsd.containskey(wo.caseid))
                {
                    lstdigest = mpcasetofsd.get(wo.caseid);
                    
                    //SAMPLE code: format Salesforce default datetime into month/date/year with 12 hour time
                    for(Field_Service_digest__c fsd : lstdigest)
                    {   String checkin = fsd.checkin_time__c.format('MM-dd-yyyy hh:mm a');
                        String checkout = fsd.checkout_time__c.format('MM-dd-yyyy hh:mm a');
                        body += 'Work Start Time: '+checkin +'&nbsp;&nbsp' +'  Work End Time: '+checkout +'<br/>';
                    }
                }
                body += '<br/>' +'<br/>';
                body += 'Work Performed:  ' +wo.invoice_summary__c +'<br/>'+'<br/>';
                if(thiswolist.size() > 0)
                {
                    for(WorkOrderLineItem li :thiswolist)
                    { body += 'Part Installed: ' +li.product_code__c +', ' +li.part_number__r.name +', ' +li.qty__c +'<br/>'; }
                }
                body += '<br/>';
                body += 'Date Work Completed: ' +wo.signature_date__c +' by ' +wo.technician_name__c;
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(emailaddresses);
                mail.setSubject(emailsubj);
                mail.setOrgWideEmailAddressId(orgaddress.id);
                mail.saveAsActivity = false;
                mail.setHTMLBody(body); 
                
                List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
                if(mpwotoattach.containskey(wo.id))
                {               
                    Attachment a = mpwotoattach.get(wo.id);
                    system.debug('attachment is ' +a.name +', ' +a.body);
                    
                    // Add to attachment file list
                    Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                    efa.setFileName(a.Name);
                    efa.setBody(a.Body);
                    fileAttachments.add(efa);
                    
                    system.debug('fileAttachments list size is ' +fileAttachments.size());
                    
                    mail.setFileAttachments(fileAttachments);
                }
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                
              }//end if third party email != null
                
            }//end work order for loop
            
            system.debug('***********END FieldWorkOrderThirdPartyNotification**********');
      }//end FieldWorkOrderThirdPartyNotification
      
      //jjackson 5/2018 for BUG-00783 notify customization of pro centric work orders
      public static void SendProCentricNotification(List<Associated_Item__c> lstai, Map<Id,Work_Order__c> mprackbuild)
      {
                //spin through the list of associated items and pull the rack build work order out of the
                //map where the map key = associated item's work_order__c value
                
                List<String> emailaddresslist = New List<String>();
                String toaddress;
                Set<Id> setacctid = New Set<Id>();
                
                //get all the site__c ids on the work orders to query for account names
                for(Work_Order__c wo : mprackbuild.values())
                {
                	setacctid.add(wo.site__c);
                }
                
                List<Account> lstacct = New List<Account>();
                Map<Id,String> mpacctidtoname = New Map<Id, String>();
                lstacct = [ Select Id, Name from Account where id in :setacctid ];
                if(lstacct.size() > 0)
                {
                	for(Account act : lstacct)
                	{
                		mpacctidtoname.put(act.id, act.name);
                	}
                }
                
                //get the email to address from the custom setting where record name is ProCentric
                EmailAddress_TON__c procentric = EmailAddress_TON__c.getInstance('ProCentric');
                
                if(!test.isRunningTest())
                {   toaddress = procentric.EmailAddress__c;  }
                else
                {   toaddress = 'jjackson@sonifi.com';  }
                    
                emailaddresslist.add(toaddress);
                
                          
                for(Associated_Item__c ai : lstai)
                {
                     String messageSubject;
                     String messageBody;
                     String acctname;
                     
                     if(mprackbuild.containskey(ai.work_order__c))
                     {
                        Work_Order__c rackbuildwo = mprackbuild.get(ai.work_order__c);
                        if(mpacctidtoname.size() > 0 && mpacctidtoname.containskey(rackbuildwo.site__c))
                        {   acctname = mpacctidtoname.get(rackbuildwo.site__c);  }
                        	
                        messageSubject = 'Pro:Centric Direct Rack To Warehouse Date - ' +rackbuildwo.work_order_number__c;
                        
                        messageBody = 'Site:   ' +acctname +'<br/>';
                        messageBody += 'To Warehouse Date:   ' +rackbuildwo.to_warehouse_date__c +'<br/>';
                        messageBody += 'Rack Build Work Order Name:   ' +rackbuildwo.name;
                        
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(emailaddresslist);
                        mail.setSubject(messageSubject);
                        mail.saveAsActivity = false;
                        mail.setUseSignature(false);
                        mail.setHTMLBody(messageBody);
                
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                                                
                     }//end if mprackbuild containskey
                }//end for loop lstsai
                
      }//end ProCentric Notification

//      jjackson--9/2016 it was decided by the business that this is not needed, but saving the code anyway
   /*   public static void HappeningsChannelNotification(List<Associated_Item__c> lsthappenings)
      {
                Map<Id,List<Associated_Item__c>> mphappenings = New Map<Id,List<Associated_Item__c>>();
                Map<Id,Work_Order__c> mpworkorder = New Map<Id,Work_Order__c>();
                List<Work_Order__c>lstworkorders = New List<Work_Order__c>();
                
                for(Associated_Item__c ai : lsthappenings)
                {
                    if(mphappenings.containskey(ai.work_order__c))
                    {
                        List<Associated_Item__c> ailist = mphappenings.get(ai.work_order__c);
                        ailist.add(ai);
                    }
                    else
                    {
                        List<Associated_Item__c> templist = new List<Associated_Item__c>();
                        templist.add(ai);
                        mphappenings.put(ai.work_order__c, templist);
                    }
                    
                }
                
                lstworkorders = [ Select Id, Name, work_order_number__c, site__r.Name from Work_Order__c where
                                  Id in :mphappenings.keyset() ];
                                  
                for(Work_Order__c wo : lstworkorders)
                {
                    mpworkorder.put(wo.Id, wo);  
                }
                
                String email;
                
                if(test.IsRunningTest())
                {  email = 'jjackson@sonifi.com'; }
                else
                {
                    EmailAddress_TON__c csemail = EmailAddress_TON__c.getInstance('SCMSHappeningsNotification');
                    email = csemail.emailaddress__c ;  //get the scms email address from custom setting
                }
                
                
                String subject = 'Happenings Channel(s) added to work order for ';
                
                
        //loop through the work orders in the map and pull their list of associated items.  Send an email
        //for each separate work order
        for(Id woid : mphappenings.keyset())
        {
            String messageSubject = '';
            List<String> emailaddress = new list<String>();
            List<Associated_Item__c> lstassocitem = New List<Associated_Item__c>();
            String woname = '';
            String wonumber = '';
            String woaccountname = '';
            String messagebody = '';
            String wourl = URL.getSalesforceBaseURL().toExternalForm() +'/' +woid;
            
            //for each work order id key in the map, get the list of associated items that go with it
            if(mpworkorder.containskey(woid))
            {
                lstassocitem = mphappenings.get(woid);
            
                //get some information from the work order to put on the email notification
                woname = mpworkorder.get(woid).Name;
                wonumber = mpworkorder.get(woid).work_order_number__c;
                woaccountname = mpworkorder.get(woid).site__r.Name;
                messagesubject = subject+woaccountname+' on work order ' +woname;
                messagebody = 'Happenings channel line items have been added to work order ' +wonumber +':' +'<br/>'+'<br/>';
                for(Associated_Item__c aitem : lstassocitem)
                {
                    messagebody += aitem.name +'<br/>';
                }
                    messagebody += '<br/>'+'<br/>';
                    messagebody += wourl;
            
                    if(test.IsRunningTest())
                    { emailaddress.add('jjackson@sonifi.com'); }
                    else
                    {   emailaddress.add(email);  }
            
            
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(emailaddress);
                    mail.setSubject(messagesubject);
                    mail.saveAsActivity = false;
                    mail.setHtmlBody(messagebody);
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            
             } //end if mphappenings contains work order key
          }//end work order keyset for loop
    
      }//end method HappeningsChannelNotification  */
      
}//end class