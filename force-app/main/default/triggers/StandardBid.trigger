trigger StandardBid on Bid__c ( before update, before insert, after update, after insert) {
    
    // Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(BidTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
    
    if(Trigger.isAfter){
        StandardBidTriggerLogic.updatePartListSelected(Trigger.oldMap, Trigger.new);
        if(Trigger.isUpdate){
            StandardBidTriggerLogic.updateBidLineItems(Trigger.oldMap, Trigger.new);
        }
    }
}