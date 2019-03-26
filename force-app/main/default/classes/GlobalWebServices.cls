global class GlobalWebServices {
    
    webservice static String applyQuote(Id quoteId) {
        String result = CustomQuoteLogic.applyQuoteToOpportunity(quoteId, null);
        return result;
    }
    
    webservice static String applyQuoteToOpportunity(Id opptyId, Id quoteId) {
        String result = CustomQuoteLogic.applyQuoteToOpportunity(quoteId, opptyId);
        return result;
    }

	//jjackson changed this to pass in an integer (owntype variable); if owntype = 1, leave
	//the site survey owner as person who clicks the button.  if owntype is null or < 1,
	//change the site survey owner to the Installs Site Surveys queue.
    webservice static String createSiteSurveyFromOpportunity(Id opptyId, Integer owntype) {
        String result = CustomOpportunityLogic.createSiteSurvey(opptyId, owntype);
        if(result == '')
        {
            return 'Site Survey Created Successfully';
        }
        else
        {
            return result;
        }
    }
/*  
    webservice static String createCase(Case caseDetails, String caseRecordType) {
        String result = CustomCaseLogic.createCase(caseDetails, caseRecordType);
        return result;
    }
*/  
    webservice static Id getRecordTypeId(String sObjectName, String recordTypeName) {
        return Utilities.RecordTypeNameToId(sObjectName, recordTypeName);
    }
    
    webservice static String workOrderCompletion(Id WorkOrderId, Id currentUserId, Id approverId)
    {
        try
        {
        	//system.debug('begin webservice workordercompletion, workorder id ' +WorkOrderId);
        	Work_Order__c thisworkorder = [ Select Id, Install_Complete_Date__c, De_Installation_Date__c, RecordTypeId from
        	                                Work_Order__c where Id = :WorkOrderId LIMIT 1 ];
           if(thisworkorder != null)
           { Id deinstrecordtype = Utilities.RecordTypeNameToId('Work_Order__c', 'De-Install');
           	 Id instrecordtype = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
           	 
           	/*( system.debug('deinstrecordtype id is ' +deinstrecordtype);
           	 system.debug('instrecordtype id is ' + instrecordtype);
           	 system.debug('thisworkorder record type id is ' +thisworkorder.RecordTypeId);
           	 system.debug('thisworkorder install complete date is ' +thisworkorder.Install_Complete_Date__c);
           	 system.debug('thisworkoder deinstall date is ' +thisworkorder.De_Installation_Date__c); */
           	 
           	 if(thisworkorder.RecordTypeId == deinstrecordtype && thisworkorder.De_Installation_Date__c == null)
           	 { return '  De-Installation Date is required.';  }
           	 else if(thisworkorder.RecordTypeId == instrecordtype && thisworkorder.Install_Complete_Date__c == null)
           	 { return '  Install Complete Date is required.';  }
           	 else
        	 {        	
            	Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            	req1.setComments('Submitting WorkOrder for Completion.');
            	req1.setObjectId(WorkOrderId);
            	Approval.ProcessResult result = Approval.process(req1);
            	system.debug('Submitting Approval Success' +result.isSuccess());
            	if(currentUserId == approverId)
            	{
                List<Id> newWorkItemIds = result.getNewWorkitemIds();
                // Instantiate the new ProcessWorkitemRequest object and populate it
                Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
                req2.setComments('Submitter is Approver, Auto approving');
                req2.setAction('Approve');
                req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
                
                // Use the ID from the newly created item to specify the item to be worked
                req2.setWorkitemId(newWorkItemIds.get(0));
                
                // Submit the request for approval
                Approval.ProcessResult result2 =  Approval.process(req2);
                system.debug('Autoapproving result:'+result2.isSuccess());
            	}
            	return 'true';
        		}//end else
               }//end if workorderid != null
               else
               { return 'Problem processing work order. ';  }
        	} //end try
        	catch(Exception e)
        	{
            system.debug('Approval Process for Completion failed : '+e.getMessage());
            return e.getMessage();
            }        
        } //end workordercomplete web service

        webservice static String CreateThirdPartyCase(Id atppid)
        {
          String returnmessage = null;

          Case newcase = New Case();


             Account_Third_Party_Partner__c atpprec = New Account_Third_Party_Partner__c();
             List<Account_Third_Party_Partner__c> lstpp = New List<Account_Third_Party_Partner__c>();
             lstpp = [Select Id, third_party_partner_account__c, third_party_partner_account__r.name, related_account__c from Account_Third_Party_Partner__c 
                      where id = :atppid LIMIT 1 ];

             for(Account_Third_Party_Partner__c tpp : lstpp)
             { atpprec = tpp; }
                      
             Id rectypeid = getRecordTypeId('Case', 'Contracted Field Service');

             newcase.recordtypeid = rectypeid;
             newcase.third_party_partner__c = atppid;
             newcase.related_third_party_partner_name__c = atpprec.third_party_partner_account__r.name;
             newcase.accountid = atpprec.related_account__c;

             try{insert newcase;
                  returnmessage = newcase.id; }
             catch(DMLException e)
             {
                  system.debug('Error creating third party account: ' +e.getMessage());
                  returnmessage = e.getMessage();
             } 

             return returnmessage;

          }

          webservice static boolean getResult(String res)
          {
              Boolean isresult = false;

              if(res.contains('500'))
              {
                isresult = true;
              }

              return isresult;
          }

          webservice static string CreateCTILog(String caseid, String callid)
          {
          	   string returnmessage = null;
   
          	   try{
          	   		CTI_Call_To_Case__c ctirec = new CTI_Call_To_Case__c();
           	   		ctirec.CTI_Call_Id__c = callid;
          	   		ctirec.Related_Case__c = caseid;
           	   		insert ctirec;
  
          	   }
          	   catch(Exception e)
          	   {  system.debug('Web Service Error in CreateCTILog: ' +e.getMessage());  
          	      returnmessage = 'Error in CreateCTILog: ' +e.getMessage();
          	   }
          	  
          	 return returnmessage;
          }
        
}