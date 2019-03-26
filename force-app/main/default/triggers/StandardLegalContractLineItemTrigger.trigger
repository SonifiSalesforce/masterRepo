trigger StandardLegalContractLineItemTrigger on Contract_Line_Item__c (before insert, before update, after insert, after update, after delete) {
    /*shawks 02/2019 - CPQ: Comment out all since not needed after using out-of-box Subscription object
    // Check for trigger processing blocked by custom setting
    try{ 
        if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
            return;
        } else if(LegalContractLineItemTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
            return; 
        }
    }
    catch (Exception e) {}
    
    if(Trigger.isBefore){
        
 
       if(Trigger.isInsert)
       {
           StandardLegalCLILogic.updateConversionDate(Trigger.new);
           MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'Price__c'=> 'Price_USD__c', 'Prior_Price__c' => 'Prior_Price_USD__c', 'Total_Financing__c' => 'Total_Financing_USD__c'});
       }
       if(Trigger.isUpdate)
       {
           
           MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'Price__c'=> 'Price_USD__c', 'Prior_Price__c' => 'Prior_Price_USD__c', 'Total_Financing__c' => 'Total_Financing_USD__c'});
           
       }
    }
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert)
        {
            StandardLegalCLILogic.updateRelatedObjects(Trigger.newMap, 'insert');
            StandardLegalCLILogic.rollUpChannelSummary(Trigger.new);
        }
        if(Trigger.isUpdate)
        {
            //these two calls must be made first to create global lists that are used in following methods
            StandardLegalCLILogic.GetAllOrderItems(trigger.new);
            StandardLegalCLILogic.GetAllProductParents(trigger.new, trigger.oldMap);
            StandardLegalCLILogic.UpdateRelatedOrderItems(trigger.new, trigger.oldMap);
            StandardLegalCLILogic.updateRelatedObjects(Trigger.newMap, 'update');
            
            if(triggerRecursionBlock.flag == true)
            {
                triggerRecursionBlock.flag = false;
  
                StandardLegalCLILogic.rollUpChannelSummary(Trigger.new);
            }
        }
        if(Trigger.isDelete)
        {
            StandardLegalCLILogic.rollUpChannelSummary(Trigger.old);        
        }
    }
    */
}