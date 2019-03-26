trigger StandardPriceListItemTrigger on Part_List_Item__c (after insert, after update, before insert, 
before update) {
	// Check for trigger processing blocked by custom setting
	try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(PartListItemTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
	
	if(Trigger.isBefore){
		MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'Total_Price__c' => 'Total_Price_USD__c', 'Price__c' => 'Price_USD__c', 'Total_With_Markup__c' => 'Total_With_Markup_USD__c'});
	}

}