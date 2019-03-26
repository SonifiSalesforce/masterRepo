trigger StandardOrderItemTrigger on Order_Item__c (before insert, before update, after update, after insert, after delete) {
  // Check for trigger processing blocked by custom setting
	// Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(OrderItemTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
    
    if(Trigger.isBefore) {
       MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'Price__c' => 'Price_USD__c', 'Prior_Price__c' => 'Prior_Price_USD__c', 'Unit_Selling_Price__c' => 'Unit_Selling_Price_USD__c'});    	
    }
    if (Trigger.isAfter) {
    	if (Trigger.isUpdate) {
    		OrderItemTriggerLogic.OrderItemEmailNotification(Trigger.new, Trigger.oldMap);
        	if(triggerRecursionBlock.flag == true)
        	{
        		triggerRecursionBlock.flag = false;
	            OrderItemTriggerLogic.rollUpChannelSummary(Trigger.new);
        	}
    	}
    	if (Trigger.isInsert)
    	{
    		OrderItemTriggerLogic.rollUpChannelSummary(Trigger.new);
    		OrderItemTriggerLogic.OrderItemEmailNotification(Trigger.new, Trigger.oldMap);
    	}
    	if (Trigger.isDelete)
    	{
    		OrderItemTriggerLogic.rollUpChannelSummary(Trigger.old);
    	}
    	
    }
    
    
}