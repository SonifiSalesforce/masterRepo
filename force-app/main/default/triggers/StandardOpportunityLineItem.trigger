trigger StandardOpportunityLineItem on OpportunityLineItem (before update, after insert, after update) {

    // Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(OpportunityLineItemTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
    
    if(Trigger.isAfter) {
        
        //After Update
        if(Trigger.isUpdate) {
            OpportunityLineItemTriggerLogic.createContractRequest(Trigger.new, Trigger.oldMap);  
       }
        if(Trigger.isInsert) {
            OpportunityLineItemTriggerLogic.createContractRequest(Trigger.new, Trigger.oldMap);  
        }
	}
    
}