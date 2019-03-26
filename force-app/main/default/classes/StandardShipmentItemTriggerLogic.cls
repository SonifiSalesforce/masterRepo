public with sharing class StandardShipmentItemTriggerLogic {
	
	public static void updateOrderItems(Map<Id, Shipment_Item__c> oldMap, Map<Id, Shipment_Item__c> newMap, Boolean isDelete){
		System.debug('Is delete::' + isDelete);
		//initialzie variables
		Set<Id> orderItemIds = new Set<Id>();
		List<Order_Item__c> orderItems = new List<Order_Item__c>();
		Map<Id, List<Shipment_Item__c>> id2ShipItems = new Map<Id, List<Shipment_Item__c>>();
		
		if(!isDelete){
			//go through list and find find where the quantity has changed
			for(Id shipId : newMap.KeySet()){
				if(oldMap != null){
					if(newMap.get(shipId).Order_Item__c != null){
						if(newMap.get(shipId).Quantity__c != oldMap.get(shipId).Quantity__c){
							orderItemIds.add(newMap.get(shipId).Order_Item__c);
							if(id2ShipItems.containsKey(newMap.get(shipId).Order_Item__c)){
								id2ShipItems.get(newMap.get(shipId).Order_Item__c).add(newMap.get(shipId));
							} else {
								id2ShipItems.put(newMap.get(shipId).Order_Item__c, new List<Shipment_Item__c>{newMap.get(shipId)});
							}
						}	
					}
				} else {
					if(newMap.get(shipId).Order_Item__c != null){
						orderItemIds.add(newMap.get(shipId).Order_Item__c);
						if(id2ShipItems.containsKey(newMap.get(shipId).Order_Item__c)){
							id2ShipItems.get(newMap.get(shipId).Order_Item__c).add(newMap.get(shipId));
						} else {
							id2ShipItems.put(newMap.get(shipId).Order_Item__c, new List<Shipment_Item__c>{newMap.get(shipId)});
						}
				}
				}
			}
			
			//query for the order items
			orderItems = [SELECT id, Quantity__c, Remaining_Quantity__c FROM Order_Item__c WHERE id IN :orderItemIds];
			
			//go through order items and update the unorder item field on quantity
			for(Order_Item__c o : orderItems){
				for(Shipment_Item__c ship : id2ShipItems.get(o.id)){
					if(oldMap != null){
						if(o.Remaining_Quantity__c != null ){
							o.Remaining_Quantity__c -= ship.Quantity__c - oldMap.get(ship.id).Quantity__c;
						}
					} else {
						if(o.Remaining_Quantity__c != null ){
							o.Remaining_Quantity__c -= ship.Quantity__c;
						} 
					}
				}
			}
			
			//update the order item if list is greater than 0
			if(orderItems.size() > 0){
				update orderItems;
			}
		} else {
			//make a map of the order item to shipment items
			for(Shipment_Item__c ship : oldMap.Values()){
				orderItemIds.add(ship.Order_Item__c);
				if(id2ShipItems.containsKey(ship.Order_Item__c)){
					id2ShipItems.get(ship.Order_Item__c).add(newMap.get(ship.Id));
				} else {
					id2ShipItems.put(ship.Order_Item__c, new List<Shipment_Item__c>{ship});
				}
			}
			
			//query for the order items
			orderItems = [SELECT id, Quantity__c, Remaining_Quantity__c FROM Order_Item__c WHERE id IN :orderItemIds];
			
			//go through the order items and update the unorder item fields on quantity
			for(Order_Item__c o : orderItems){
				for(Shipment_Item__c ship : id2ShipItems.get(o.id)){
					if(o.Remaining_Quantity__c != null ){
						o.Remaining_Quantity__c += ship.Quantity__c;
					} else{
						o.Remaining_Quantity__c = ship.Quantity__c;
					}
				}
			}
			
			//update the order item if list is greater than 0
			if(orderItems.size() > 0){
				update orderItems;
			}
		}
	}
}