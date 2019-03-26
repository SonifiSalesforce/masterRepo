public with sharing class StandardBidTriggerLogic {
	
	public static void updateBidLineItems(Map<Id, Bid__c> oldMap, List<Bid__c> newList){
		//initialize var
		List<Bid_Line_Item__c> bidsList = new List<Bid_Line_Item__c>();
		Set<Id> bidIds = new Set<Id>(); // set of the bid ids that need to be queried
		
		//got through list and see where the approval status field has changed to pending
		for(Bid__c bid : newList){
			if(bid.Approval_Status__c == 'Approved' && oldMap.get(bid.id).Approval_Status__c != 'Approved'){
				bidIds.add(bid.id);
			}
		}
		System.debug('Bids that have changed status to Pending::' + bidIds);
		
		//query for the bid line items that need to be updated
		bidsList = [SELECT id, Conversion_Date__c FROM Bid_Line_Item__c WHERE Bid__c IN :bidIds];
		
		//got through list and make te conversion date be today
		for(Bid_Line_Item__c bid : bidsList){
			bid.Conversion_Date__c = Date.Today();
		}
		
		//update Bid_Line_Item__c
		update bidsList;
	}
	
	public static void updatePartListSelected(Map<Id, Bid__c> oldMap, List<Bid__c> newList){
		System.debug('Entering updatePartListSelected...');
		//initialize variables
		List<Part_List__c> partList = new List<Part_List__c>();
		Set<Id> partIds = new Set<ID>();
		
		//go through list and see where the bid selected changes to be true
		for(Bid__c bid : newList){
			if(oldMap != null){
				if(bid.Selected_Bid__c && !oldMap.get(bid.id).Selected_Bid__c){
					if(bid.Part_List__c != null){
						partIds.add(bid.Part_List__c);
					}
				}
			} else {
				if(bid.Selected_Bid__c){
					if(bid.Part_List__c != null){
						partIds.add(bid.Part_List__c);
					}
				}
			}
		}
		System.debug('Part ids::' + partIds);
		
		//if part ids is not empty then query the part ids
		if(partIds.size() > 0){
			partList = [SELECT id, Part_List_Selected__c FROM Part_List__c WHERE id IN :partIds];
			System.debug('parts found::'+partList);
			
			//update the part list selected to be true
			for(Part_List__c part : partList){
				part.Part_List_Selected__c = true;
			}
			
			//update the part list
			try{
				update partList;
			} catch(Exception ex){
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,ex.getMessage()));
			}
			
			System.debug('Exiting updatePartListSelected...');
		}
	}
}