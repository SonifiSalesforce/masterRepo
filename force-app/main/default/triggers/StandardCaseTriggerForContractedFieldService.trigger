trigger StandardCaseTriggerForContractedFieldService on Case (after insert, after update) {
	
	
	Id recid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
	List<Case> lstcfscasebeforeinsert = New List<Case>();
	
	if(trigger.isInsert)
	{
		CaseTriggerLogic.PopulateSpecialInstructions(trigger.new);
	}

	
	if(trigger.isUpdate)
	{
		 if(triggerRecursionBlock.flag == true)
		 { 
		 	system.debug('inside after update recursion block');
		 	CaseTriggerLogic.CreateCaseCommentfromComments(trigger.new, trigger.oldMap);
			EmailUtilities.NotifyThirdPartyCaseQueueMembers(trigger.new, trigger.oldMap);
	        triggerRecursionBlock.flag = false;
		 }
		 
		 Id recid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
		 List<Id> lstclosedcases = new List<Id>();
		 
		 for(Case trig :trigger.new)
		 {
		 	if(trig.recordtypeid == recid )
		 	{
		 		if(trig.status.contains('Closed') && !trigger.oldmap.get(trig.id).status.Contains('Closed'))
		 		{  lstclosedcases.add(trig.id);  }
		 	}
		 }
		 
		 if(lstclosedcases.size() > 0)
		 {  CustomCaseLogic.GetCaseInteractionHistory(lstclosedcases, null);  }
				
		
	}
	

    
}