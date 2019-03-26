trigger StandardSubscriptionTrigger on SBQQ__Subscription__c (after delete, after insert, after update, before insert, before update) {
    
    try{ 
        if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
            return;
        } else if(SubscriptionTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
            return; 
        }
    }
    catch (Exception e) {}
    
    if(Trigger.isBefore){
        
 
       if(Trigger.isInsert)
       {
          
           //MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'Price__c'=> 'Price_USD__c', 'Prior_Price__c' => 'Prior_Price_USD__c', 'Total_Financing__c' => 'Total_Financing_USD__c'});
       }
       if(Trigger.isUpdate)
       {
           
          // MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'Price__c'=> 'Price_USD__c', 'Prior_Price__c' => 'Prior_Price_USD__c', 'Total_Financing__c' => 'Total_Financing_USD__c'});
           
       }
    }
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert)
        {
            
            StandardSubscriptionTriggerLogic.updateRelatedObjects(Trigger.newMap, 'insert');
            //StandardSubscriptionTriggerLogic.rollUpChannelSummary(Trigger.new);  //shawks Post-CPQ Imp - remove; will be executed in update section
            
        }
        if(Trigger.isUpdate)
        {
            //these two calls must be made first to create global lists that are used in following methods
            //jjackson 12/11/2018 for CPQ, don't call GetAllProductParents if the subscriptions are being created by
            //CPQ functionality and have no parenting.  Check the subscriptions in trigger.new first to determine whether the
            //subscription lines have parenting.
            Boolean hasparenting = false;
            for(SBQQ__Subscription__c s : trigger.new)
            {
                if(s.parent__c != null)
                {  hasparenting = true;  }
            }
            
            system.debug('hasparenting = ' +hasparenting);
            
            StandardSubscriptionTriggerLogic.GetAllOrderItems(trigger.new);
            
            if(hasparenting == true)
            {
                StandardSubscriptionTriggerLogic.GetAllProductParents(trigger.new, trigger.oldMap);
                StandardSubscriptionTriggerLogic.UpdateRelatedOrderItems(trigger.new, trigger.oldMap);
                StandardSubscriptionTriggerLogic.updateRelatedObjects(Trigger.newMap, 'update');
            }
            
            StandardSubscriptionTriggerLogic.PopulateProductParentIdField(trigger.new);
            
            if(triggerRecursionBlock.flag == true)
            {
                triggerRecursionBlock.flag = false;
  
                StandardSubscriptionTriggerLogic.rollUpChannelSummary(Trigger.new);
                
            }
        }
        if(Trigger.isDelete)
        {
            StandardSubscriptionTriggerLogic.rollUpChannelSummary(Trigger.old);        
        }
    }
}