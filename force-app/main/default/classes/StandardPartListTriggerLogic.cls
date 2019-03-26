public with sharing class StandardPartListTriggerLogic {

	public static void createPartOrderAndItems(Map<Id, Part_List__c> oldMap, Map<Id, Part_List__c> newMap){
		System.debug('Entering createPartOrderAndItems with ' + newMap.KeySet().size() + ' records');
		
		//initialize variables
		String partOrderRecordType = Utilities.RecordTypeNameToIdWithObject('Part Order', 'Order__c');
		List<Part_List__c> createOrderList = new List<Part_List__c>();
		Set<Id> partListIds = new Set<Id>(); 
		Map<Id, Order__c> insertOrderMap = new Map<Id, Order__c>();
		Map<Id, Order_Item__c> insertOrderItemMap = new Map<Id, Order_Item__c>();
		
		//go through part list and check if part list is selected
		for(Id i : newMap.KeySet()){
			if(oldMap != null){
				if(newMap.get(i).Part_List_Selected__c && !oldMap.get(i).Part_List_Selected__c){
					partListIds.add(newMap.get(i).id);
					createOrderList.add(newMap.get(i));
				}
			} else {
				if(newMap.get(i).Part_List_Selected__c ){
					partListIds.add(newMap.get(i).id);
					createOrderList.add(newMap.get(i));
				}
			}
		}
		
		//query for the part list and part list items
		createOrderList = [SELECT id, Part_List_Selected__c, Site_Survey__c, Site_Survey__r.Opportunity__c, Site_Survey__r.Site__r.Site_ID__c, Site_Survey__r.Site__c, CurrencyIsoCode, Site_Survey__r.Name,
							(SELECT id,Part_List__c, Org__c, Org_ID__c, Margin__c, Task_Number__c, Category__c, Sub_Category__c, Description__c, Part_Number__c, Price__c, Product__c, Product__r.Name, Quantity__c, Unit__c FROM Part_List_Items__r) 
							FROM Part_List__c WHERE id IN :partListIds];
							
		//create the order and order items
		for(Part_List__c part : createOrderList){
			if(part.Site_Survey__r.Opportunity__c != null){
				//create the order
				Order__c o = new Order__c();
				
				//set the values
				o.Opportunity__c = part.Site_Survey__r.Opportunity__c;
				o.Name = part.Site_Survey__r.Site__r.Site_ID__c + '-Part Order-'+Date.today().year()+'/'+Date.today().month()+'/'+Date.today().day();
				o.Site_Survey__c = part.Site_Survey__c;
				o.CurrencyIsoCode = part.CurrencyIsoCode;
				o.RecordTypeId = partOrderRecordType;
				o.Site__c = part.Site_Survey__r.Site__c;
				o.Status__c = 'Order Approved';
				
				//map the order
				insertOrderMap.put(part.id, o);
			}
		}
		System.debug('Insert order map before is ' + insertOrderMap);
		
		//insert the orders
		insert insertOrderMap.Values();
		System.debug('Insert order map after is ' + insertOrderMap);
		
		//go through the list and make the order items
		for(Part_List__c part : createOrderList){
			if(part.Site_Survey__r.Opportunity__c != null){
				//go through part list items
				for(Part_List_Item__c item : part.Part_List_Items__r){
					//create the order item
					Order_Item__c oItem = new Order_Item__c();
					
					//set the values
					if(item.Product__r.Name.length() > 80){
						oItem.Name = item.Product__r.Name.substring(0,79);
					} else {
						oItem.Name = item.Product__r.Name;
					}
					oItem.Order__c = insertOrderMap.get(part.id).id;
					oItem.Product__c = item.Product__c;
					oItem.Price__c = item.Price__c;
					oItem.Margin__c = item.Margin__c;
					oItem.UOM__c = item.Unit__c;
					oItem.Item_Description__c = item.Description__c;
					oItem.Remaining_Quantity__c = item.Quantity__c; 
					oItem.Quantity__c = item.Quantity__c;
					oItem.Task_Number__c = item.Task_Number__c;
					oItem.Part_Number__c = item.Part_Number__c;
					oItem.Description__c = item.Description__c;
					oItem.Category__c = item.Category__c;
					//oItem.Sub_Category__c = item.Sub_Category__c;
					oItem.Org__c = item.Org__c;
					oItem.Org_ID__c = item.Org_ID__c;
					
					//map the order item
					insertOrderItemMap.put(item.id, oItem);
				}
			}
		}
		
		//insert the order items
		try{
			insert insertOrderItemMap.Values();
		} catch(Exception ex){
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,ex.getMessage()));
		}
		System.debug('Order Items:: ' + insertOrderItemMap);
	}
	
	public static void updatePartLineItems(Map<Id, Part_List__c> oldMap, List<Part_List__c> newList){
		//initialize var
		List<Part_List_Item__c> partsList = new List<Part_List_Item__c>();
		Set<Id> partIds = new Set<Id>(); // set of the bid ids that need to be queried
		
		//got through list and see where the approval status field has changed to pending
		for(Part_List__c part : newList){
			if(part.Approval_Status__c == 'Approved' && oldMap.get(part.id).Approval_Status__c != 'Approved'){
				partIds.add(part.id);
			}
		}
		System.debug('Part Lists that have changed status to Pending::' + partIds);
		
		//query for the bid line items that need to be updated
		partsList = [SELECT id, Conversion_Date__c FROM Part_List_Item__c WHERE Part_List__c IN :partIds];
		
		//got through list and make te conversion date be today
		for(Part_List_Item__c part : partsList){
			part.Conversion_Date__c = Date.Today();
		}
		
		//update Bid_Line_Item__c
		update partsList;
	}
}