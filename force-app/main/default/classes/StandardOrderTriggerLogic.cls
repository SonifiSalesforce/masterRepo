public with sharing class StandardOrderTriggerLogic {
	
	//jjackson 1/2015 Created a trigger on Order__c to find a way to update asset statuses beyond the Billing value when
	//a work order goes to Work Order Complete.  At Work Order Complete, the related order goes to Order Fulfilled.  When order
	//goes to Order Fulfilled, find the related order items and update the status of the related assets to match order item status.
		
	public static void UpdateAssetsonOrderFulfilled(List<Order__c> lstfulfilledorders, Map<ID,Order__c> mpoldordervalues)
	{
		system.debug('***************************BEGIN StandardOrderTriggerLogic.UpdateAssetsonOrderFulfilled******************');
		
		List<Order_Item__c> lstorderitems = New List<Order_Item__c>();
		Set<ID> orderid = new Set<ID>();
		List<Asset> updasset = New List<Asset>();
		
	
		
		for(Order__c updatedorder : lstfulfilledorders) //find the orders where the status has changed to Order Fulfilled
		{
			system.debug('order status value in triggernew is ' +updatedorder.status__c +' and old value is ' +mpoldordervalues.get(updatedorder.id).status__c);
			if(updatedorder.Status__c == 'Order Fulfilled' && mpoldordervalues.get(updatedorder.Id).Status__c != 'Order Fulfilled')
			{
				orderid.add(updatedorder.id);
			}	
		
		}
		
		system.debug('orderid set size is ' +orderid.size());
		
		//jjackson 4/2016 changed this code so that when order goes to order fulfilled, the related product inventory
		//items change to Installed Activated.  Also cut down on the amount of code written for this.
		//Items pending de-installation are not updated by this code; assets are changed to De-Installed when the
		//product deactivations are created.
		lstorderitems = [ Select Id, Name, asset__c, asset__r.status, order__c from Order_Item__c where order__c in :orderid ];
		
		for(Order_Item__c oi : lstorderitems)
		{
			if(oi.asset__c != null)
			{
				if(oi.asset__r.status == 'Billing')
				{
					Asset updassetrec = New Asset();
			
					updassetrec.Id = oi.asset__c;
				
					updassetrec.status = 'Installed Activated';
				
					updasset.add(updassetrec);
				}
		     }   
		}
		
		if(updasset.size() > 0)
		{
			try{ upsert updasset;  }
			catch(Exception e)
			{  system.debug('ERROR upserting status changes to asset record in order trigger logic : ' +e.getMessage());  }
		}
		
		system.debug('*************************END StandardOrderTriggerLogic.UpdateAssetsonOrderFulfilled*********************');
     } //end UpdateAssetsonOrderFulfilled
     
     
}//end class