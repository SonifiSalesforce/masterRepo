trigger StandardPartListTrigger on Part_List__c (after insert, after update, before insert, before update) {
	// Check for trigger processing blocked by custom setting
	try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(PartListTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
	
	if(Trigger.isAfter){
		StandardPartListTriggerLogic.createPartOrderAndItems(Trigger.oldMap, Trigger.newMap);
		if(Trigger.isUpdate){
			StandardPartListTriggerLogic.updatePartLineItems(Trigger.oldMap, Trigger.new);
		}
		
	}  
	
	
}