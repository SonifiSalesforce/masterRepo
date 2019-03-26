trigger StandardOrderTrigger on Order__c (before insert, before update, after insert, after update) {
    
   // Check for trigger processing blocked by custom setting
	try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(OrderTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
    
    if(Trigger.isBefore)
    {  if(Trigger.isInsert || Trigger.isUpdate)
	
    	    MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'Charges__c' => 'Charges_USD__c', 'Subtotal__c' => 'Subtotal_USD__c', 'Tax__c' => 'Tax_USD__c', 'Total__c' => 'Total_USD__c'});
    	    
    }
    //jjackson added January 2015 BUG-00378
	if(Trigger.isAfter)
    {
        if(Trigger.isUpdate)
        {
        	StandardOrderTriggerLogic.UpdateAssetsonOrderFulfilled(trigger.new, trigger.oldMap);
        }
    }

}