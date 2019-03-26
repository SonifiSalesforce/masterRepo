trigger FieldWorkOrderTrigger on WorkOrder (after insert, after update, before insert, before update) {
    
	
	Id rectype = Utilities.RecordTypeNameToId('WorkOrder', 'Third Party FWO');
	
	if(trigger.IsInsert)
	{
		if(trigger.IsBefore)
		{
			FieldWorkOrderTriggerLogic.PopulateWorkOrderUponCreation(trigger.new);
			FieldWorkOrderTriggerLogic.PopulateExceptions(trigger.new);
		}//end trigger is before
		
		if(trigger.IsAfter)
		{  FieldWorkOrderTriggerLogic.CreateFieldWorkOrderEvents(trigger.new);  }
		
	}//end trigger is insert
	
	if(trigger.IsUpdate)
	{
		//there are three methods that look for status changed to Submitted for Billing.  Find those first, then pass them into the
		//methods instead of writing redundant code inside the methods
		//Get the values in custom setting Field_WorkOrder_DoNotProcess to determine whether work order should go through the
		//billing approval process.  If the work order status is at one of the values in the custom setting, it is being
		//send through for a second time so don't created all the related elements
		List<Field_WorkOrder_DoNotProcess__c> lststatus = New List<Field_WorkOrder_DoNotProcess__c>();
		Set<String> statusset = New Set<String>();
		lststatus = Field_WorkOrder_DoNotProcess__c.getall().values();
		for(Field_WorkOrder_DoNotProcess__c cs : lststatus)
		{  statusset.add(cs.Name);  }
		List<WorkOrder> lstupdwo = New List<WorkOrder>();
		List<WorkOrder> lstresubmit = New List<WorkOrder>();
		Map<Id,WorkOrder> mpbillingapproved = New Map<Id,WorkOrder>();
		Set<Id> updid = New Set<Id>();
		for(WorkOrder wo : trigger.new)
		{
			if(!statusset.Contains(trigger.newmap.get(wo.id).status))
			{
				if(wo.submit_for_billing__c == true && trigger.oldmap.get(wo.id).submit_for_billing__c == false)
				   
		        {  lstupdwo.add(wo);  }
			}
			else
			{
				if(wo.submit_for_billing__c == true && trigger.oldmap.get(wo.id).submit_for_billing__c == false)
				{  lstresubmit.add(wo);  }
			}
			
			//set aside the third party field work orders where billing is approved for sending an email notice
			//jjackson 10/2017
			if(wo.billing_approved__c == true && trigger.oldmap.get(wo.id).billing_approved__c == false &&
			   wo.recordtypeid == rectype)
			{  mpbillingapproved.put(wo.id,wo);  }

		}
		
		if(trigger.isBefore)
		{
			if(lstupdwo.size() > 0)
			{  FieldWorkOrderTriggerLogic.PopulateTechField(lstupdwo);  
			   
			}
			
		}
		
		if(trigger.isAfter)
		{  
			if(lstupdwo.size() > 0)
			{   
				FieldWorkOrderTriggerLogic.CreateTripLaborChildLines(lstupdwo); 
				FieldWorkOrderTriggerLogic.StartWorkOrderApprovalProcess(lstupdwo);
				FieldWorkOrderTriggerLogic.EmailUponApproval(lstupdwo);
				
			}

			
			if(lstresubmit.size() > 0)
			{  FieldWorkOrderTriggerLogic.StartWorkOrderApprovalProcess(lstresubmit);  }
			
			if(mpbillingapproved.size() > 0)
			{  EmailUtilities.FieldWorkOrderThirdPartyNotification(mpbillingapproved);  }
			
		}
	}
}//end trigger