trigger StandardAssociatedItem on Associated_Item__c (before update, after update, before insert, after insert, before delete, after delete) 
{
    System.debug(LoggingLevel.DEBUG,'StandardAssociatedItem .  **********    START');
    // Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(AssociatedItemTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
    
    
    	
    if(Trigger.isBefore)
    {

        if(Trigger.isInsert || Trigger.isUpdate){
           
           MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'Professional_Solutions_Cost__c'=> 'Professional_Solutions_Cost_USD__c', 'BIS_Cost__c' => 'BIS_Cost_USD__c', 'Install_Cost__c' => 'Install_Cost_USD__c'});
        }
        if(Trigger.isDelete)
        {
        	AssociatedItemTriggerLogic.WorkOrderEmailNotification(Trigger.old, null, 'Delete');
        	
        }
  
    }
    
    if(Trigger.isAfter)
    {
    	Set<ID> workorderids = new Set<ID>();
        Set<ID> orderitemids = new Set<ID>();
        List<Work_Order__c> lstworkorder = new List<Work_Order__c>();
        List<Order_Item__c> lstorderitem = new List<Order_Item__c>();
        
        if(Trigger.isInsert)
        {
        	for(Associated_Item__c recaitem : trigger.new)
    	    {
    			workorderids.add(recaitem.Work_Order__c);
    			orderitemids.add(recaitem.Order_Item__c);
    	    }
    	    lstworkorder = AssociatedItemTriggerLogic.GetWorkOrderList(workorderids);
            lstorderitem = AssociatedItemTriggerLogic.GetOrderItemList(orderitemids);
          	AssociatedItemTriggerLogic.WorkOrderEmailNotification(Trigger.new, null, 'Insert');
        	//jjackson 7/18/2014 BUG-00361
            AssociatedItemTriggerLogic.GetInstallClockStartDates(Trigger.new, lstworkorder, lstorderitem);
            AssociatedItemTriggerLogic.WorkOrderNameUpdate(Trigger.new, lstworkorder, lstorderitem);
             
        }
        if(Trigger.isUpdate)
        {
        	//jjackson 9/2014 need to get order item list for UpdateOrderItemStatus
            for(Associated_Item__c recaitem : trigger.new)
    	    {
     			orderitemids.add(recaitem.Order_Item__c);
    	    }
            	
            lstorderitem = AssociatedItemTriggerLogic.GetOrderItemList(orderitemids);
            
        	AssociatedItemTriggerLogic.WorkOrderEmailNotification(Trigger.new, Trigger.oldMap, 'Update');
        	AssociatedItemTriggerLogic.UpdateOrderItemStatus(trigger.new, trigger.oldMap, lstorderitem);
        }
        if(Trigger.isDelete)
        {	
        	set<Id> woids = New Set<Id>();
        	List<Associated_Item__c> lstremoveprodparents = New List<Associated_Item__c>();
        	List<Work_Order__c> lstrelatedwo = New List<Work_Order__c>();
        	for(Associated_Item__c recaitem : trigger.old)
    	    {
    	    	if(recaitem.name.contains('Product Parent') && recaitem.work_order__c != null)
    	    	{ woids.add(recaitem.work_order__c);  
    	    	  lstremoveprodparents.add(recaitem);
    	    	}
    		  
    	    }

        	//AssociatedItemTriggerLogic.WorkOrderNameUpdate(Trigger.old, lstworkorder, lstorderitem);
        	//jjackson 5/2016 need a different method that only runs when a product parent is being deleted
        	if(lstremoveprodparents.size() > 0 || !lstremoveprodparents.IsEmpty())
        	{ 
        		lstrelatedwo = AssociatedItemTriggerLogic.GetWorkOrderList(woids);
        		AssociatedItemTriggerLogic.RemoveProductParent(lstremoveprodparents, lstrelatedwo);
            }
        }//end if trigger isDelete
               
    }//end if trigger isAfter
    System.debug(LoggingLevel.DEBUG,'StandardAssociatedItem .  **********   End');
}