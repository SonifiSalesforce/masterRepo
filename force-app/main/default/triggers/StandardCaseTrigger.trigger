// *********************************************************************************************
// Filename:     StandardCaseTrigger
// Version:      0.0.1
// Author:       Etherios
// Date Created: 8/6/2013
// Description:  Trigger on the Case object.
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

trigger StandardCaseTrigger on Case (before insert, before update) {

    // Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(CaseTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
    
    Id rectypeid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
    List<Case> lstcaseinsert = new List<Case>();
    
    Map<Id, List<Case>> statusChangeCaseMap = new Map<Id, List<Case>>();
    
    // get and store the cases service contract name 
    Map<Id,String> casesServiceContractMap = CustomCaseLogic.casesServiceContracts(Trigger.new);
    
    // Check for NEW trigger
    if (Trigger.isInsert) 
    {
          	// NOTE Dispatched rules do not apply to new cases
          	
        //jjackson 10/2016 verify new support cases contain customer name and role
        CaseTriggerLogic.VerifyCustomerNameRole(trigger.new);
        
         
        //jjackson 10/2016 this method pertains to Hyatt email notifications under Hyatt MSA	
        CaseTriggerLogic.GetCaseEmailCriteria(trigger.new, trigger.oldmap);

        
     	for (Case c : Trigger.new) {
	        if (statusChangeCaseMap.containsKey(c.AccountId)) {
	        	statusChangeCaseMap.get(c.AccountId).add(c);
	        } else {
	        	statusChangeCaseMap.put(c.AccountId, new List<Case> { c });
	        }
    	}

    	// Process status change ONLY
    	CustomCaseLogic.processStatusChange(statusChangeCaseMap, casesServiceContractMap);
    	
    	return;
           
    }
    
            
    if(trigger.IsUpdate)
    {		
    		//jjackson 5/2017, if a case being updated is a single digits BAP case, check to make sure
    		//the case ownership hasn't changed.
    		List<Case> lstcases = New List<Case>();
    		for(Case c : trigger.new)
    		{
    			if(c.single_digits_case_id__c != null)
    			{  lstcases.add(c); }
    		}
  			if(lstcases.size() > 0)
    		{  CaseTriggerLogic.CheckCaseOwner(lstcases, trigger.oldmap);  }
    		
            CaseTriggerLogic.DispatchThirdPartyCases(trigger.new, 'update', trigger.oldMap);
    	
    		//jjackson 10/2016 these methods pertain to notification emails for Hyatt MSA cases
    		CaseTriggerLogic.GetCaseEmailCriteria(trigger.new, trigger.oldmap);
    		CaseTriggerLogic.UpdateEmailFrequencyAfterSeverityChange(trigger.new, trigger.oldmap);
    		CaseTriggerLogic.StopOrRestartEmailNotification(trigger.new, trigger.oldmap);
    	
    	    //jjackson all the code below is used to identify Hilton SLA cases that within 2 hours of milestone violation
    		List<Case> casenotificationslist = New List<Case>();
    		List<RecordType> rectypelist = [ Select Developername, Id from RecordType where Developername = 'Support_Case' LIMIT 1 ];
    		Id recid;
    		for(RecordType rectype : rectypelist)
    		{  recid = rectype.id;  }
    		for(Case caserec : trigger.new)
    		{
    			
    			if((caserec.nearing_expiration__c == true && trigger.oldmap.get(caserec.id).nearing_expiration__c == false) &&
    			   caserec.recordtypeid == recid && (caserec.issue_type__c != null && !caserec.issue_type__c.Contains('Project'))) //don't send notification for project cases
    			{  casenotificationslist.add(caserec);  }
    		}
    		
    		if(casenotificationslist.size() > 0)
    		{ EmailUtilities.PendingCaseViolationNotification(casenotificationslist);  }
    		
    		//jjackson End of case milestone violation code for Hilton SLA
    	
    }
    

    Boolean hasOld = (Trigger.oldMap != null && !Trigger.oldMap.isEmpty());
    
    // NOTE This logic assumes the support office field on the Case object WILL NEVER be set
    // explicitly by the user. The Case Support Office field is expected to be set by the 
    // Account trigger ONLY. 
    // 
    // If that changes, this logic will need to be modified to include considerations for
    // changing both Support Office and Dispatched fields simultaneously when each field is
    // dependent upon the other.
    // 
    // DO NOT DO THIS UNLESS ABSOLUTELY NECESSARY!!!  
    
    Map<Id, Case> dispatchedCaseMap = new Map<Id, Case>();
    Map<Id, Case> unDispatchedCaseMap = new Map<Id, Case>();
    for (Case c : Trigger.new) {
    	
    	// Get old case (or empty) for comparisons below
    	Case oldCase;
    	if (hasOld && Trigger.oldMap.containsKey(c.Id)) {
    		oldCase = Trigger.oldMap.get(c.Id);
    	} else {
    		oldCase = new Case();
    	}
    	
    	// Check to be sure we have set the initiated date/time
    	// NOTE This can be missed when using buttons to immediately create support cases
    	if(c.recordtypeid != rectypeid)
    	{  	if (Trigger.isInsert && c.Date_Time_Initiated__c == null)
    		 { c.Date_Time_Initiated__c = DateTime.now(); }
    	}
    	
    	// Check for change in dispatched flag
    	if (c.Dispatched__c && !oldCase.Dispatched__c) { 
    		dispatchedCaseMap.put(c.Id, c);
    	} else if (!c.Dispatched__c && oldCase.Dispatched__c) {
    		unDispatchedCaseMap.put(c.Id, c);
    	}
    	
        // Check for status change
        // NOTE Status change is indicated by a change in status from the OLD to NEW triggers
        // OR a change in the dispatched flag between the two.
        if (c.Status != oldCase.Status || (c.Dispatched__c && !oldCase.Dispatched__c)) {
	        if (statusChangeCaseMap.containsKey(c.AccountId)) {
	        	statusChangeCaseMap.get(c.AccountId).add(c);
	        } else {
	        	statusChangeCaseMap.put(c.AccountId, new List<Case> { c });
	        }
        }
    }
    
    // Check for undispatched cases
    if (!unDispatchedCaseMap.isEmpty()) {
        CaseTriggerLogic.unDispatchCases(unDispatchedCaseMap);
     }
    
    // Check for no cases dispatched
    if (!dispatchedCaseMap.isEmpty()) {
        CaseTriggerLogic.dispatchCases(dispatchedCaseMap);
    }
    
    // Check for status changes
    if(!statusChangeCaseMap.isEmpty()) {
        CustomCaseLogic.processStatusChange(statusChangeCaseMap, casesServiceContractMap);
    }
    
 }