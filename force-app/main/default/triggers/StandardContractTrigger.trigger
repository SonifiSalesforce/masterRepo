trigger StandardContractTrigger on Contract (after delete, after update, before insert, before update) 
{
    
    // Check for trigger processing blocked by custom setting
    try{ 
        if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
            return;
        } else if(Contract_Trigger_Config__c.getValues('Global').BlockTriggerProcessing__c) {
            return; 
        }
    }
    catch (Exception e) {}
    
    if(Trigger.isBefore)
    {
       //MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'TOD_Project_E__c'=> 'TOD_Project_USD__c', 'TOD_Sub_K__c' => 'TOD_Sub_K_USD__c'});
       if(trigger.isUpdate)
       {
         StandardContractTriggerLogic.UpdateSubscriptionLineItems(trigger.new, trigger.oldmap);  
       }

    } 
    if(Trigger.isafter)
    {
        if(Trigger.isUpdate)
        {
          //jjackson 6/30/2014 This populates install start ftg and interactive dates to the related work order.
          StandardContractTriggerLogic.GetClockStartDate(trigger.oldMap,trigger.new);   
          if(triggerRecursionBlock.flag == true) 
            {
                 StandardContractTriggerLogic.SendGroupServicesEmail(trigger.new, trigger.oldmap); 
                 triggerRecursionBlock.flag = false;
            }
          if(test.isRunningTest())
          { StandardContractTriggerLogic.SendGroupServicesEmail(trigger.new, trigger.oldmap); }  
        }
    }
}