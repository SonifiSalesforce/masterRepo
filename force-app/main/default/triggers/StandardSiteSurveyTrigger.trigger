// *********************************************************************************************
// Filename:     StandardSiteSurveyTrigger
// Version:      0.0.1
// Author:       Etherios
// Date Created: 9/16/2013
// Description:  Trigger on the Site Survey object.
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

trigger StandardSiteSurveyTrigger on Site_Survey__c (after delete, after insert, after undelete, 
		after update, before delete, before insert, before update) {

	// Check for trigger processing blocked by custom setting
	try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(SiteSurveyTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
	
	if(Trigger.isBefore){
		//if(Trigger.isInsert ){
		//	SiteSurveyTriggerLogic.noDuplicateSiteSurvey(Trigger.new);
		//}
		if(Trigger.isUpdate){
			SiteSurveyTriggerLogic.updateOwner(Trigger.oldMap, Trigger.new);
		}
	}
	
	if(Trigger.isAfter){
		if(Trigger.isUpdate ){
			SiteSurveyTriggerLogic.updateRelatedBids(Trigger.oldMap, Trigger.newMap);
			SiteSurveyTriggerLogic.updateRelatedPartList(Trigger.oldMap, Trigger.newMap);
		}
	}
}