trigger FieldWOLineItemTrigger on WorkOrderLineItem (after insert, after update, before insert, before update) {

	if(trigger.isInsert)
	{
		if(trigger.IsBefore)
		{
			FieldWOLineItemTriggerLogic.PopulateNetSuiteLocation(trigger.new);
		}
	}

    
} //end of trigger