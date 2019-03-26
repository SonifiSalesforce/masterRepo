// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 06/10/2013
// Description:  Class for implementing functionalities to support custom Opportunity
//				 list components.
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class OpportunityListController extends CustomListController {
	
	public static final String arrowASC = '&#9650;';
	public static final String arrowDESC = '&#9660;';
	private static final String defaultSortExpression = 'OwnerName';

	transient public List<CustomOpportunityLogic.OpptyProductStage> opptyProductList { get; set; }

	private Map<Id, List<Id>> opptyProductMap;
	private List<Opportunity> recordListLocal;
	
	/* */
	public List<SelectOption> opportunityStages {
		get {
			if (opportunityStages == null) {
				
				// Create stage list
				opportunityStages = new List<SelectOption> { new SelectOption('', 'Select a Stage') };
				
				// Get stages from custom setting 
				List<OpportunityStage__c> stageList = OpportunityStage__c.getAll().values();
				
				// Build map for ordering
				Map<Integer, OpportunityStage__c> stageMap = new Map<Integer, OpportunityStage__c>();
				for (OpportunityStage__c stage : stageList) {
					stageMap.put(Integer.valueOf(stage.SortOrder__c), stage);
				}
				
				// Iterate through index values and build resulting list
				for (Integer i = 0; i < stageList.size(); i++) {
					String stage = stageMap.get(i + 1).Name;
					opportunityStages.add(new SelectOption(stage, stage));
				}
			}
			return opportunityStages;
		}
		private set;
	}
	
	/* */
    public List<SelectOption> opportunityCloseStages {
    	get {
	    	if (opportunityCloseStages == null) {
	    		opportunityCloseStages = new List<SelectOption> { 
					new SelectOption('', 'Select a Stage'), 
					new SelectOption('Closed Won', 'Closed Won'),
					new SelectOption('Closed Lost', 'Closed Lost')
	    		};
	    	}
	    	return opportunityCloseStages;
    	}
    	private set;
    }
    
	/* */
    public List<Opportunity> getRecordList() {
    	if (recordListLocal == null) {
	    	if (parentObject == null) { return null; }
			Utilities.writeLog(
					'Reading records associated with ' + parentObjectName + '(' + parentObject.Id + ')...', 
					OpportunityListController.class, 'records', LoggingLevel.DEBUG);
	    	
	    	String query = 
		    		'SELECT Id, RecordTypeId, OwnerId, Owner.FirstName, Owner.LastName, Owner.Name, '
		    		+ 'AccountId, Account.Name, Name, CloseDate, '
		    		+ 'StageName, of_Rooms_in_Hotel__c '
		    		+ 'FROM Opportunity '
		    		+ 'WHERE IsClosed = False ';
		    		// + '  AND OwnerId = \'' + UserInfo.getUserId() + '\' ';
		    
	    	Schema.SObjectType parentObjectType = parentObject.getSObjectType();
	    	if (parentObjectType == Account.getSObjectType()) {
	    		
	    		Id accountId = (Id)parentObject.get('Management_Group__c');
	    		if (accountId == null) { accountId = parentObject.Id; }
	    		
		    	query += 'AND (AccountId = \'' + accountId + '\' OR Account.Management_Group__c = \'' + accountId + '\') '
		    		   + 'ORDER BY Account.Name '; 
	    	} else if (parentObjectType == Opportunity.getSObjectType()) {
	    		
	    		query += 'AND Id = \'' + parentObject.Id + '\' ';
	    		
	    	} else {
	            hasPageError = true;
	            pageError = new ApexPages.Message(
	                ApexPages.Severity.ERROR,
	                'Unable to read list data from parent object.',
	                'Unsupported parent object type: ' + parentObjectType + '.');
				return null;
	    	}
	    	
	    	// Check showAll flag
	    	// TODO Consider adding paging if record set is going to get big for this query
	    	if (!showAllRecords) { query += 'LIMIT 5'; }
	    	
			try { 
				recordListLocal = Database.query(query);
				if (recordListLocal == null || recordListLocal.isEmpty()) { return null; }
			}
			catch (Exception e) {
				Utilities.writeLog(
						'Unable to read records. Details: ' + e.getMessage(), 
						OpportunityListController.class, 'records', LoggingLevel.ERROR);
				ApexPages.addMessage(new ApexPages.Message(
						ApexPages.Severity.ERROR,
						'Unable to read records', e.getMessage()));
				return null; 
			}
			
			// Sort list
			sortList(sortExpression, sortDirection);
    	}
        return recordListLocal;
    }
    
	/* */
    public PageReference readOpportunityProducts() {
    	
    	List<Id> opptyIdList = getOpptyIdList();
        if (opptyIdList == null) { return null; }
        
        Utilities.writeLog(
            'Reading products for ' + opptyIdList.size() + ' opportunities.', 
            OpportunityListController.class, 'readOpportunityProducts', LoggingLevel.DEBUG);
    	
    	List<Opportunity> opptyList = [
			SELECT Id, Name, StageName,
				(SELECT PricebookEntryId, PricebookEntry.Name
				FROM OpportunityLineItems
				ORDER BY PricebookEntry.Name)
			FROM Opportunity
    		WHERE Id IN :opptyIdList
    		ORDER BY StageName
    	];
    	
    	opptyProductMap = new Map<Id, List<Id>>();
    	Map<String, CustomOpportunityLogic.OpptyProductStage> closeableOpptyMap = new Map<String, CustomOpportunityLogic.OpptyProductStage>();
    	for (Opportunity o : opptyList) {
			
			List<Id> productList = new List<Id>();
    		
    		for (OpportunityLineItem lineItem : o.OpportunityLineItems) {
    			
    			// Accumulate opportunity products
				productList.add(lineItem.PricebookEntryId);
    			
    			// Add product to closeable product map  
    			if (!closeableOpptyMap.containsKey(lineItem.PricebookEntry.Name)) {
			        Utilities.writeLog(
			            'Adding product ' + lineItem.PricebookEntry.Name + '.', 
			            OpportunityListController.class, 'readOpportunityProducts', LoggingLevel.DEBUG);
		    		CustomOpportunityLogic.OpptyProductStage opptyProduct = new CustomOpportunityLogic.OpptyProductStage();
    				opptyProduct.productId = lineItem.PricebookEntryId;
    				opptyProduct.productName = lineItem.PricebookEntry.Name;
    				closeableOpptyMap.put(lineItem.PricebookEntry.Name, opptyProduct);
    			}
    		}
    		
    		// Add opportunity product list to map
    		opptyProductMap.put(o.Id, productList);
    	}
    	
    	if (closeableOpptyMap == null || closeableOpptyMap.isEmpty()) {
    		opptyProductList = null;
    	} else {
    		opptyProductList = closeableOpptyMap.values();
    	}
    	return null;
    }
    
	/**
	 * Change stage for passed opptys
	 */
    public PageReference changeOpportunityStage() {
		
		// Get page parameters
    	List<Id> opptyIdList = getOpptyIdList();
        String stage = ApexPages.currentPage().getParameters().get('newStage');
        
        try {
        	// Change stage for passed opptys
	        CustomOpportunityLogic.changeStage(opptyIdList, stage);
	        recordListLocal = null;
        } catch (Exception e) {
	        Utilities.writeLog(
	            'Unable to change the stage for passed opportunities. Details: ' + e.getMessage(), 
	            OpportunityListController.class, 'changeOpportunityStage', LoggingLevel.ERROR);
            hasPageError = true;
            pageError = new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Unable to change the stage for passed opportunities.',
                + e.getMessage() + '.');
        }
    	return null;
    }
    
	/**
	 * Close ALL passed opportunities with THE SAME closed stage  
	 */
    public PageReference closeOpportunity() {
		
		// Get page parameters
    	List<Id> opptyIdList = getOpptyIdList();
        String stageParam = ApexPages.currentPage().getParameters().get('stage');
		String closeReason = ApexPages.currentPage().getParameters().get('closeReason');
		String closeDesc = ApexPages.currentPage().getParameters().get('closeDescription');
		
        try {
			// Determine stage passed
			CustomOpportunityLogic.ClosedStage stage = 
				stageParam.toLowerCase() == 'won' 
					? CustomOpportunityLogic.ClosedStage.CLOSED_WON 
					: CustomOpportunityLogic.ClosedStage.CLOSED_LOST; 
			// Close passed opptys
	        CustomOpportunityLogic.closeOpportunities(opptyIdList, stage, closeReason, closeDesc);
	        recordListLocal = null;
        } catch (Exception e) {
	        Utilities.writeLog(
	            'Unable to close opportunities. Details: ' + e.getMessage(), 
	            OpportunityListController.class, 'closeOpportunity', LoggingLevel.ERROR);
            hasPageError = true;
            pageError = new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Unable to close opportunities.',
                + e.getMessage() + '.');
        }
    	return null;
    }
    
	/**
	 * Close passed opportunities with a UNIQUE close stage for individual products  
	 */
    public PageReference closeOpportunityByProduct() {
    	
    	List<Id> opptyIdList = getOpptyIdList();
        if (opptyIdList == null) { return null; }
        
        String pageParam = ApexPages.currentPage().getParameters().get('stageChangeJson');
        if (pageParam == '') { return null; }
		
		List<CustomOpportunityLogic.OpptyProductStage> productStageList = 
				(List<CustomOpportunityLogic.OpptyProductStage>)JSON.deserialize(pageParam, List<CustomOpportunityLogic.OpptyProductStage>.class);
		if (productStageList == null || productStageList.isEmpty()) { return null; }
		
        Utilities.writeLog(
            'Line-Item JSON: ' + pageParam, 
            OpportunityListController.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
		System.debug(productStageList);
        
        // Iterate over product changes
        Map<Id, CustomOpportunityLogic.OpptyProductStage> productStageMap = 
        		new Map<Id, CustomOpportunityLogic.OpptyProductStage>();
        for (CustomOpportunityLogic.OpptyProductStage closedProduct : productStageList) {
        	if (closedProduct.stage != null && closedProduct.stage != '') {
				Utilities.writeLog(
					'Closing opportunity product \'' + closedProduct.productName + '\' '
						+ 'as \'' + closedProduct.stage + '\'.', 
					OpportunityListController.class, 'closeOpportunityByProduct', LoggingLevel.INFO);
				
				// Add closed product to map 
				productStageMap.put(closedProduct.productId, closedProduct);
        	}
        }
        
        // Determine which of the selected opptys have the selected products
        List<Id> closedOpptyIdList = new List<Id>();
        
        // Iterate over the selected opptys
        Boolean hasClosedItem = false;
    	for (Id opptyId : opptyIdList) {
    		
    		// Get the list of available oppty products for the selected oppty
    		List<Id> opptyProductIds = this.opptyProductMap.get(opptyId);
    		
    		// Iterate over the available oppty products
    		for (Id productId : opptyProductIds) {
    			
    			// Check to see if this available oppty product was one of the selected products
    			if (productStageMap.containsKey(productId)) {

		    		// Check for closed item
		    		if (!hasClosedItem) {
		    			 String stage = productStageMap.get(productId).stage;
		    			 if (stage != null && stage != '') { hasClosedItem = true; }
		    		}
		    		
    				// Add oppty Id to list of closed opptys
    				closedOpptyIdList.add(opptyId);
    				break;
    				
    			}
        	}
        }
        
        // Check for closed item
        if (!hasClosedItem) { return null; }
        
        try {
	        // Close opportunities
	        CustomOpportunityLogic.CloseOpportunitiesByProduct(closedOpptyIdList, productStageMap);
	        recordListLocal = null;
        } catch (Exception e) {
	        Utilities.writeLog(
	            'Unable to close opportunities. Details: ' + e.getMessage(), 
	            OpportunityListController.class, 'closeOpportunitiesByProduct', LoggingLevel.ERROR);
            hasPageError = true;
            pageError = new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Unable to close opportunities.',
                + e.getMessage() + '.');
        }

    	return null;
    }
    
	/**
	 * Pulls opportunity Ids from page parameters
	 */
    private List<Id> getOpptyIdList() {
    	
        String pageParam = ApexPages.currentPage().getParameters().get('opportunityIdList');
        if (pageParam == '') { return null; }
		
        List<Id> opptyIdList = pageParam.split(',');
		if (opptyIdList == null || opptyIdList.isEmpty()) { return null; }
		
        Utilities.writeLog(
            'Opportunity Id List: ' + pageParam, 
            OpportunityListController.class, 'getOpptyIdList', LoggingLevel.DEBUG);
        
    	return opptyIdList;
    }

	public String sortExpression {
		get {
			if (sortExpression == null) { sortExpression = defaultSortExpression; }
			return sortExpression;
		}
	 	set {
				//if the column is clicked on then switch between Ascending and Descending modes
				if (value == sortExpression) {
		 		this.sortDirection = (this.sortDirection == 'ASC') ? 'DESC' : 'ASC';
				} else {
		 		this.sortDirection = 'ASC';
				}
				sortExpression = value;
		}
		}
		
 	public String sortDirection	{
 		get {
 			if (sortDirection == null || sortDirection == '') { return 'ASC'; }
			if (this.sortExpression == null || this.sortExpression == '') { return 'ASC'; }
 			return sortDirection;
 		}
 		set {
 			sortDirection = value.toUpperCase();
 		}
 	}
 	
	public String arrowDisplay {
		get {
			if (this.sortDirection == 'ASC') { return arrowASC; }
			return arrowDESC;
		}
	}
 	
	public PageReference sortByHeader() {
		this.sortExpression = ApexPages.currentPage().getParameters().get('sortColumn');
		sortList(this.sortExpression, this.sortDirection);
		return null;
	}

	private void sortList(String sortField, String sortOrder) {
		
		if (this.recordListLocal == null || this.recordListLocal.isEmpty()) { return; }
		
		//Create a map that can be used for sorting
		Map<object, List<Opportunity>> objectMap = new Map<object, List<Opportunity>>();

		for(Opportunity item : this.recordListLocal) {
			object fieldValue;
			String defaultSort = ' ' + item.Owner.LastName.toUpperCase() + ' ' + item.Owner.FirstName.toUpperCase();
			
			if (sortField == 'OpptyName') {
				fieldValue = item.Name;
			} else if(sortField == 'SiteName') {
				fieldValue = item.Account.Name;
			} else if(sortField == 'StageName') {
				fieldValue = item.StageName;
			} else if(sortField == 'RoomCount') {
				fieldValue = ('0000000000' + item.of_Rooms_in_Hotel__c).right(10);
			} else if(sortField == 'CloseDate') {
				DateTime dt;
				if (item.CloseDate == null) {
					dt = sortOrder == 'ASC' ? Datetime.now().addYears(50) : Datetime.now().addYears(-50);
				} else {
					dt = item.CloseDate;
				}
				fieldValue = dt.format('yyyy/MM/dd HH:mm:ss');
			} else if(sortField == 'OwnerName') {
				fieldValue = '';
			}
			fieldValue += defaultSort;
			if(!objectMap.containsKey(fieldValue)) {
				objectMap.put(fieldValue, new List<Opportunity>());
			}
			objectMap.get(fieldValue).add(item);
		}

		//Sort the keys
		List<object> keys = new List<object>(objectMap.keySet());
		keys.sort();

		List<Opportunity> resultList = new List<Opportunity>();
		for(object key : keys) {
			resultList.addAll(objectMap.get(key));
		}

		//Apply the sorted values to the source list
		this.recordListLocal.clear();
		if(sortOrder == 'DESC') {
			for(integer i = resultList.size()-1; i >= 0; i--) {
				this.recordListLocal.add(resultList[i]);
			}
		} else {
			for(Opportunity ob : resultList) {
				this.recordListLocal.add(ob);
			}
		}
	}
}