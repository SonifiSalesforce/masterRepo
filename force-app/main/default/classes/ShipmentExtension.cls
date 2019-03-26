public with sharing class ShipmentExtension {
	
	public Shipment__c ship {get;set;}
	public String orderItemId {get;set;}
	public String orderName {get;set;}
	public String orderNameAndId {get;set;}
	public List<SelectOption> ordersAndIds{get;set;}
	public List<CustomOrder> getOrders(){
		List<CustomOrder> tempList = this.id2OrderMap.Values();
		tempList.sort();
		return tempList;
	}
		
	public List<CustomOrder> getSelectedOrders(){
		List<CustomOrder> lists = id2OrderSelectedMap.Values();
		lists.sort();
		return lists;
	}
	public Set<Id> getOrderIds() {
		Set<Id>ids = new Set<Id>();
		for(CustomOrder c : this.id2OrderSelectedMap.Values()){
			ids.add(c.orderItemId);
		}
		return ids;
	}
	public Map<Id, CustomOrder> id2OrderSelectedMap {get;set;}
	public Map<Id, CustomOrder> id2OrderMap {get;set;}
	
	public class CustomOrder implements Comparable {
		public id shipId {get;set;}
		public Order_Item__c orderItem {get;set;}
		public Id orderItemId {get;set;}
		public String name {get;set;}
		public Shipment_Item__c shipItem {get;set;}
		
		public integer compareTo(Object compareTo){
			CustomOrder custom = (CustomOrder)compareTo;
			if(Name == custom.Name) return 0;
			if(Name > custom.Name) return 1;
			return -1;
		}
	}
	
	public ShipmentExtension(ApexPages.StandardController stdController){
		this.ship = (Shipment__c) stdController.getRecord();
		this.orderName = '';
		this.id2OrderMap = new Map<Id, CustomOrder>();
		this.id2OrderSelectedMap = new Map<Id, CustomOrder>();
		this.orderItemId = '';
		this.orderNameAndId = 'Any';
		this.ordersAndIds = new List<SelectOption>{new SelectOption('Any', 'Any')};
		
		String fieldQuery = String.join(getSobjectFields(Shipment__c.getSobjectType()), ',');
		//get the shipment record
		List<Shipment__c> tempList = Database.query('SELECT ' + fieldQuery + ', Work_Order__r.Site__c FROM Shipment__c WHERE id=\'' + this.ship.id + '\'');
		
		this.ship = tempList[0];
		
		//load the data
		this.loadShipmentItems();
		//this.loadOrderItems();
		this.loadOrders();
	}
	
	public void loadOrders(){
		//create the list
		List<Order__c> tempOrderList = new List<Order__c>();
		
		//query for the order and its name
		String recordTypeId = (String)Utilities.RecordTypeNameToId('Order__c', 'Part Order');
		tempOrderList = [SELECT id, Name FROM Order__c WHERE Site__c =:this.ship.Work_Order__r.Site__c AND (Status__c = 'Approved to Build' OR Status__c = 'Approved to Ship and Install' OR Status__c = 'Order Approved' ) AND RecordTypeId = :recordTypeId];
		System.debug('Orders found are ' + tempOrderList);
		for(Order__c o : tempOrderList){
			this.ordersAndIds.add(new SelectOption(o.id, o.Name));
		}
	}

	//load the order items
	public void loadOrderItems(){
		//initalize variables
		this.id2OrderMap = new Map<Id, CustomOrder>();
		List<Order_Item__c> tempList = new List<Order_Item__c>();
		
		if(this.orderNameAndId != 'Any' && this.orderName != ''){
			tempList = [SELECT id, Name, Remaining_Quantity__c, Quantity__c, Order__c, Product__c, Product__r.Name FROM Order_Item__c WHERE Order__r.Site__c =: this.ship.Work_Order__r.Site__c  AND (Order__r.Status__c = 'Approved to Build' OR Order__r.Status__c = 'Approved to Ship and Install' OR Order__r.Status__c = 'Order Approved' ) AND id NOT IN :getOrderIds() AND Name LIKE :('%'+this.orderName+'%') AND Order__c =:this.orderNameAndId ] ;
		} else if(this.orderName != ''){
			tempList = [SELECT id, Name, Remaining_Quantity__c, Quantity__c, Order__c, Product__c, Product__r.Name FROM Order_Item__c WHERE Order__r.Site__c =: this.ship.Work_Order__r.Site__c  AND (Order__r.Status__c = 'Approved to Build' OR Order__r.Status__c = 'Approved to Ship and Install' OR Order__r.Status__c = 'Order Approved') AND id NOT IN :getOrderIds() AND Name LIKE :('%'+this.orderName+'%') ];
		} else if(this.orderNameAndId != 'Any'){
			tempList = [SELECT id, Name, Remaining_Quantity__c, Quantity__c, Order__c, Product__c, Product__r.Name FROM Order_Item__c WHERE Order__r.Site__c =: this.ship.Work_Order__r.Site__c  AND (Order__r.Status__c = 'Approved to Build' OR Order__r.Status__c = 'Approved to Ship and Install' OR Order__r.Status__c = 'Order Approved') AND id NOT IN :getOrderIds() AND Order__c =:this.orderNameAndId ] ;
		} else {
			tempList = [SELECT id, Name, Remaining_Quantity__c, Quantity__c, Order__c, Product__c, Product__r.Name FROM Order_Item__c WHERE Order__r.Site__c =: this.ship.Work_Order__r.Site__c  AND (Order__r.Status__c = 'Approved to Build' OR Order__r.Status__c = 'Approved to Ship and Install' OR Order__r.Status__c = 'Order Approved') AND id NOT IN :getOrderIds()  ] ;
		}
		
		//map the shipment items
		for(Order_Item__c item : tempList){
			CustomOrder custom = new CustomOrder();
			
			Shipment_Item__c shipItem = new Shipment_Item__c();
			shipItem.Order_Item__c = item.id;
			
			//set the values
			custom.shipId = null;
			custom.orderItem = item;
			custom.orderItemId = item.id;
			custom.name = item.Product__r.Name;
			custom.shipItem = shipItem;
			
			//map the custom order
			if(this.id2OrderMap.Values().size()<1000){
				this.id2OrderMap.put(custom.orderItemId, custom);
			}
		}
		
		//this.orders = this.id2OrderMap.Values();
		//this.orders.sort();
	}
	
	//save the shipment items
	public PageReference saveShipmentItem(){
		System.debug('Entering save shipment items....');
		
		//upsert the shipment
		upsert this.ship;
		
		//initialize variables
		List<Shipment_Item__c> itemList = new List<Shipment_Item__c>();
		
		//go through the list and if quantity is greater than 0 then save it
		for(CustomOrder custom : this.id2OrderSelectedMap.Values()){
			if(custom != null){
				Shipment_Item__c item = custom.shipItem;
				if((item.Quantity__c > 0 && item.Quantity__c != null) || item.id != null){
					if(item.Shipment__c == null){
						item.Shipment__c = this.ship.id;
					}
					itemList.add(item);
				}
			}
		}
		
		//upsert the shipment list if size is greater than 0
		if(itemList.size() > 0){
			upsert itemList;
		}
		
		//redirect to the shipment page
		PageReference ref = new PageReference('/' + this.ship.id);
		ref.setRedirect(true);
		System.debug('Page Reference url is ' + ref);
		return ref;
	}
	
	public void loadShipmentItems(){
		//initialize variables
		List<Shipment_Item__c> tempShipItems = new List<Shipment_Item__c>();
		
		//query for the shipment items
		tempShipItems = [SELECT id, Shipment__c, Order_Item__c, Order_Item__r.Quantity__c, Order_Item__r.Remaining_Quantity__c, Order_Item__r.Product__c, Order_Item__r.Product__r.Name, Order_Item__r.Order__c, Order_Item__r.Name, Quantity__c FROM Shipment_Item__c WHERE Shipment__c = :this.ship.id];
		
		//map the shipment items
		for(Shipment_Item__c item : tempShipItems){
			CustomOrder custom = new CustomOrder();
			
			Order_Item__c o = new Order_Item__c();
			o.id = item.Order_Item__c;
			o.Quantity__c = item.Order_Item__r.Quantity__c;
			o.Product__c = item.Order_Item__r.Product__c;
			o.Remaining_Quantity__c = item.Order_Item__r.Remaining_Quantity__c;
			o.Order__c = item.Order_Item__r.Order__c;
			//o.Order__r.Name = item.Order_Item__r.Order__r.Name;
			
			//set the values
			custom.shipId = item.id;
			custom.orderItemId = item.Order_Item__c;
			custom.orderItem = o;
			custom.name = item.Order_Item__r.Product__r.Name;
			custom.shipItem = item;
			
			//map the custom order
			this.id2OrderSelectedMap.put(custom.orderItemId, custom);
		}
	}
	
	public void deleteOrderItem(){
		//remove custo order from the list
		CustomOrder custom = this.id2OrderSelectedMap.remove(this.orderItemId);
		
		if(custom.shipItem.id != null){
			try{
				delete custom.shipItem;
				custom.shipItem.Id =  null;
				custom.shipId = null;
			} catch(Exception ex){
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,ex.getMessage()));
			}
		}
		
		this.id2OrderMap.put(this.orderItemId, custom);
		System.debug('selected map::' + this.id2OrderSelectedMap);
	}
	
	public void addOrderItem(){
		//intialize the custom part
		CustomOrder custom = new CustomOrder();
		
		//remove the custom part from product map 
		custom = this.id2OrderMap.remove(this.orderItemId);
		
		//put the part line item into the map
		this.id2OrderSelectedMap.put(this.orderItemId, custom);
		
		System.debug('selected map::' + this.id2OrderSelectedMap);
	}
	
	//add all item in the order map to the cart
	public void addAllItems(){
		
		//go through loop and remove the items from the order map and move them to selected list
		for(String cKey : this.id2OrderMap.KeySet()){
			//remove the custom order
			CustomOrder custom = id2OrderMap.remove(cKey);
			
			//put the custom order in the selected map
			this.id2OrderSelectedMap.put(cKey, custom);
		}
	}
	
	 /***********************************************************************************************************
	***************************************** HELPER FUNCTIONS ****************************************************
	***********************************************************************************************************/
    
      /* Returns all fields in an SObject */ 
	  public static List<String> getSObjectFields(Schema.SObjectType objectType) {
	    
	    // Check for object type 
	    if (objectType == null) { return null; }
	    
	    // Get field map
	    Map<String, SObjectField> fieldMap = objectType.getDescribe().fields.getMap();	      
	   
	    List<String> fieldList = new List<String>();
	    for (String f : fieldMap.keySet()) {
	       // DescribeFieldResult field = fieldMap.get(f).getDescribe();
	     	fieldList.add(f);
	    }
	    
	    //return the list of fields
	    return fieldList;
	  }
}