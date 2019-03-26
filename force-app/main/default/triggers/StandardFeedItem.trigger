trigger StandardFeedItem on FeedItem (before insert, after insert, before update, after update) {

	// Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(ChatterFeedItemTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
	
    if(Trigger.IsUpdate)
    {
    
    }
    if(Trigger.IsInsert)
    {
        if(Trigger.isBefore)
        {
           // FeedItemTriggerLogic.setVisibility(Trigger.new);
        }
    }

}