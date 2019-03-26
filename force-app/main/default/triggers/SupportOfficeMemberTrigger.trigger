// *********************************************************************************************
// Filename:     SupportOfficeMemberTrigger
// Version:      0.0.1
// Author:       Etherios
// Date Created: 8/5/2013
// Description:  Trigger on the custom SupportOfficeMember__c object to manage Primary Engineer
//				 linkages as well as affect Account and dispatched Case records accordingly.
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
//Modified February 2014 by Joan Jackson, Sonifi
// *********************************************************************************************
// *********************************************************************************************

trigger SupportOfficeMemberTrigger on SupportOfficeMember__c (
		before update, before delete,  
		after insert, after update, after delete, after undelete) 
{  //begin trigger
	
	// Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(SupportOfficeMemberTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}

	if (Trigger.isBefore) {
		
		// BEFORE TRIGGERS
		
		Map<Id, SupportOfficeMember__c> membersToAffect = Trigger.newMap;
		Map<Id, SupportOfficeMember__c> primaryEngineerMap = new Map<Id, SupportOfficeMember__c>();
		
		if (Trigger.isDelete) 
		{
			System.debug('within trigger.isdelete before trigger');
			// BEFORE DELETE
			
			// Before a delete is allowed, be sure this is not the Primary Engineer
			// OR there are NO dispatched cases to contend with.
			
			// NOTE The Insert/Update/Undelete will handle reassignment of Account
			// and dispatched Case records to the new owner prior to deleting. So,
			// if this record is a Primary Engineer AND associated with dispatched
			// Cases, then someone is trying to manually delete the Primary Engineer.
			
			
			// Get Primary Engineer records
			for (SupportOfficeMember__c member : Trigger.old) 
			{  //begin loop
				if (member.Role__c == Definitions.SUPPORTMEMBER_PRIMARY_ENGINEER) 
				{
					primaryEngineerMap.put(member.Id, member);
					
				}
			} //end loop
			
		} //end if trigger.isdelete
		else 
		{  //begin if trigger is not delete
			
			//System.debug('within trigger is not delete before trigger');
			
			// BEFORE UPDATE
			
			// Before an update is allowed, check to see if this was (or is now) the Primary Engineer. 
			// If changed FROM a Primary Engineer or record is being deleted, BEFORE DELETE rules apply.
			// If changed TO a Primary Engineer, leave alone--AFTER UPDATE rules will handle. 
			
			// Get Primary Engineer records
			for (SupportOfficeMember__c member : Trigger.new) 
			{  //begin loop
				//System.debug('within before trigger for loop');
				SupportOfficeMember__c oldMember = Trigger.oldMap.get(member.Id);
				if ((member.User__c == null
					&& member.Role__c == Definitions.SUPPORTMEMBER_PRIMARY_ENGINEER) 
					|| (oldMember.Role__c == Definitions.SUPPORTMEMBER_PRIMARY_ENGINEER
						&& member.Role__c != Definitions.SUPPORTMEMBER_PRIMARY_ENGINEER)) 
				{
					primaryEngineerMap.put(member.Id, member);
				}
			} //end loop
		 }  // end if trigger is not delete
		
		// Check if members can be deleted/updated
		if (primaryEngineerMap.isEmpty()) { return; }
		
		SupportOfficeMemberTriggerLogic.validateMemberRemoval(primaryEngineerMap);
		
	}  // end before trigger   
	
	else 
	
	{  //begin after trigger
		
		//System.debug('within after trigger');
		
		// AFTER TRIGGERS - INSERT, UPDATE, DELETE, UNDELETE
		
		// Affect Account and active, dispatched Case records.
		// If the newly upserted/undeleted record is for the Primary Engineer role,
		// check for duplicated role and delete the previous record.
		
		Map<Id, SupportOfficeMember__c> membersToAffect;
		
		if (Trigger.isDelete) 
		{
			//System.debug('within after trigger isdelete');
			membersToAffect = new Map<Id, SupportOfficeMember__c>();
			for (SupportOfficeMember__c member : Trigger.old) 
			{  //begin loop
				System.debug('SupportOfficeMemberTrigger.AFTER_DELETE. Adding member: ' + member);
				membersToAffect.put(member.Id, new SupportOfficeMember__c(
					SupportOffice__c=member.SupportOffice__c, 
					Role__c = member.Role__c)
				);
			}  // end loop
		} //end trigger.isdelete 
		
		else 
		{ //trigger is not delete
			//System.debug('within after trigger is not delete');
			membersToAffect = Trigger.newMap.deepClone();
			System.debug('SupportOfficeMemberTrigger.AFTER_UPDATE. membersToAffect: ' + membersToAffect);
			if (Trigger.oldMap != null && !Trigger.oldMap.isEmpty()) 
			{
				for (SupportOfficeMember__c member : Trigger.new)
				{  //begin loop
					//System.debug('within after trigger for loop not delete and member = ' + member); 
	     			if (Trigger.oldMap.containsKey(member.Id)) 
	     			{
						SupportOfficeMember__c oldMember = Trigger.oldMap.get(member.Id);
						//System.Debug('oldmember = ' + oldMember.MemberName__c);
						//System.Debug('member = ' + member.MemberName__c);
				 		if (oldMember == member) 
				 		{
				 			System.debug('SupportOfficeMemberTrigger.AFTER. Removing member: ' + member);
							membersToAffect.remove(member.Id);
						} 
						
					
				     //JJACKSON CHANGE:  Before calling processMemberUpdate in trigger logic, check to see if it is the primary engineer
					 //that has changed.  We don't want to call this if a different role has changed, because then all case ownership
					 //will be updated and doesn't need to be.
					 //System.debug('member role = ' + member.Role__c);
				     if (member.Role__c == Definitions.SUPPORTMEMBER_PRIMARY_ENGINEER && oldMember.User__c != member.User__c) 
				     {
	        	           SupportOfficeMemberTriggerLogic.processMemberUpdate(membersToAffect, !Trigger.isDelete);
	        	     }
	        	     
	     			}
			      }  //end loop
		      }
		
	        }  // end else
	        	        	
	 }  //end after trigger
}  // end trigger