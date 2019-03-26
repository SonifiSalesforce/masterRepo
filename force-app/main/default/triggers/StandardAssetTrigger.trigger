// *********************************************************************************************
// Filename:     StandardAssetTrigger
// Version:      0.0.1
// Author:       Etherios
// Date Created: 8/6/2013
// Description:  Trigger on the Asset object.
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

trigger StandardAssetTrigger on Asset (before insert, before update, after insert, after update, before delete, after delete) {
    
    // Check for trigger processing blocked by custom setting
    try{ 
        if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
            return;
        } else if(AssetTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
            return; 
        }
    }
    catch (Exception e) {}
 
    if(Trigger.isAfter){
        if(Trigger.isInsert)
        {
            StandardAssetTriggerLogic.subtotalSummary(Trigger.new);
            StandardAssetTriggerLogic.updateContractLineItemStatus(Trigger.oldMap, Trigger.new); 
        }
        if(Trigger.isDelete)
        {
            StandardAssetTriggerLogic.subtotalSummary(Trigger.old);
        }
        if (Trigger.isUpdate)
        {
			if(triggerRecursionBlock.flag == true)
			{
				triggerRecursionBlock.flag = false;
            	StandardAssetTriggerLogic.subtotalSummary(Trigger.new);
			}
			//jjackson 8/2016 Don't need code to update contract line item dates from product inventory
			//StandardAssetTriggerLogic.updateEndDates(Trigger.newMap);
            StandardAssetTriggerLogic.updateContractLineItemStatus(Trigger.oldMap, Trigger.new); 
        }
    }	
}