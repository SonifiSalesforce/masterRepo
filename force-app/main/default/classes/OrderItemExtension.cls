public with sharing class OrderItemExtension {
	private final List<Order_Item__c> orderItemsSelected = new List<Order_Item__c>();
	
	public OrderItemExtension(ApexPages.StandardSetController controller) {
     controller.setPageSize(10);   
    }
	

}