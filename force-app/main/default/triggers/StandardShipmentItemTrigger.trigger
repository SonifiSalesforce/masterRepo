trigger StandardShipmentItemTrigger on Shipment_Item__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	// Check for trigger processing blocked by custom setting
	try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(ShipmentItemTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
	
	if(Trigger.isAfter){
		if(Trigger.isUpdate || Trigger.isInsert){
			StandardShipmentItemTriggerLogic.updateOrderItems(Trigger.oldMap, Trigger.newMap, false);
		}
		
		if(Trigger.isDelete){
			StandardShipmentItemTriggerLogic.updateOrderItems(Trigger.oldMap, Trigger.newMap, true);
		}
	}
	
	
}