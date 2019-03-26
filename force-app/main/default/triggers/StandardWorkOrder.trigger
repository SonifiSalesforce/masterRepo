trigger StandardWorkOrder on Work_Order__c (before update, after update, before insert, after insert) {
    System.debug(LoggingLevel.DEBUG,'StandardWorkOrder .  **********    START');
    
    // Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(WorkOrderTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}

	if(Trigger.isInsert)
    {
        if(Trigger.isBefore)
        {
        //	WorkOrderTriggerLogic.checkCrewIsPartnerEnabled(null, Trigger.new);
            WorkOrderTriggerLogic.WorkOrderNameCompareUpdate(trigger.new, Trigger.oldMap, 'insert');
 
        }
    }
    
    if(Trigger.isUpdate)
    {
        if(Trigger.isBefore)
        {
        	//WorkOrderTriggerLogic.checkCrewIsPartnerEnabled(Trigger.oldMap, Trigger.new);
	        //shawks Bug-00717 - Check if HealthCare Email Notification may be needed
        	List<Work_Order__c> lstnewwo = New List<Work_Order__c>();
        	for(Work_Order__c recnewwo : trigger.new)
            {
            //Check if site is a 'Healthcare Site' and (Work Order Type is 'Install' or 'Schedules')
               if(recnewwo.Account_Type__c == 'Healthcare Site' && (recnewwo.RecordTypeId == Utilities.RecordTypeNameToId('Work_Order__c', 'Install')
                                                                 || recnewwo.RecordTypeId == Utilities.RecordTypeNameToId('Work_Order__c', 'Schedules')))
        	      {  lstnewwo.add(recnewwo);  }
        	}
        	if(!lstnewwo.isEmpty())
        	{
        	   WorkOrderTriggerLogic.CreateHCNotification(lstnewwo, Trigger.oldMap);
            }

            WorkOrderTriggerLogic.updateTVTypeRelated2Acc(Trigger.newMap, Trigger.oldMap);
 			WorkOrderTriggerLogic.TurnonNoticeAfterApproval(Trigger.new, Trigger.oldMap);
            WorkOrderTriggerLogic.ActivateServiceContracts(Trigger.new, Trigger.oldMap);
            WorkOrderTriggerLogic.UpdateOrderStatus(Trigger.new, Trigger.oldMap);
            
            if(triggerRecursionBlock.flag == true) 
            {
            	 WorkOrderTriggerLogic.updateOwner(Trigger.oldMap, Trigger.new);
            	 WorkOrderTriggerLogic.WorkOrderNameCompareUpdate(trigger.new, Trigger.oldMap, 'update');
          	     WorkOrderTriggerLogic.UpdateChildWorkOrderName(trigger.newMap, trigger.oldMap);
          	     triggerRecursionBlock.flag = false;
            }

        }
        if(Trigger.isAfter)
        {
        	//jjackson added 5/2018 BUG-00783
  			WorkOrderTriggerLogic.ProCentricNotification(trigger.new, trigger.oldmap);
            WorkOrderTriggerLogic.CreateProductActivations(trigger.new);
            WorkOrderTriggerLogic.deleteSitePhoto(trigger.new);
 
  
           // WorkOrderTriggerLogic.workOrderProductActivation(Trigger.new);
            

        }        
    }
    System.debug(LoggingLevel.DEBUG,'StandardWorkOrder .  **********    END');
}