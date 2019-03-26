trigger StandardBidLineItem on Bid_Line_Item__c (before insert, before update) {
	// Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(BidLineItemTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
	
	MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'Total_Price__c' => 'Amount_USD__c', 'Total_With_Markup__c' => 'Total_With_Markup_USD__c'});

}