// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/29/2013
// Description:  Class for housing custom logic for the Opportunity object
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public without sharing class CustomOpportunityLogic {
	
	public enum ClosedStage { CLOSED_WON, CLOSED_LOST }
	
	public class OpptyProductStage {
		public Id										productId						{ get; set; }				
		public String									productName						{ get; set; }
		public String									stage							{ get; set; }
		public String									reason							{ get; set; }
		public String									description						{ get; set; }
	}
	
	/**
	 * Change stage for a list of opportunities (by Id)
	 */
    public static void changeStage(List<Id> opptyIdList, String stage) {
    	
    	if (opptyIdList == null || opptyIdList.isEmpty()) { 
    		throw new Exceptions.IllegalArgumentException('Opportunity list is missing or empty.'); 
    	}
    	if (stage == null || stage == '') { 
    		throw new Exceptions.IllegalArgumentException('No stage provided.'); 
    	}
    	
        Utilities.writeLog(
            'Changing stage for ' + opptyIdList.size()
            	+ ' opportunities  to \'' + stage + '\'.', 
            CustomOpportunityLogic.class, 'changeStage', LoggingLevel.DEBUG);
        
        List<Opportunity> opptyList = new List<Opportunity>();
        for (Id itemId : opptyIdList) {
        	opptyList.add(
        		new Opportunity(Id = itemId, StageName = stage));
        }
        
        try {
        	upsert opptyList;
        } catch (Exception e) {
	        Utilities.writeLog(
	            'Unable to change opportunity stage to \'' + stage + '\'. Details:  ' + e.getMessage(), 
	            CustomOpportunityLogic.class, 'changeStage', LoggingLevel.ERROR);
			throw e;
        }
    }
            
	/**
	 * Close passed opportunities with THE SAME closed stage  
	 */
    public static void closeOpportunities(List<Id> opptyIdList, ClosedStage stage) {
    	closeOpportunities(opptyIdList, stage, null, null);	
    }
    
	/**
	 * Close passed opportunities with THE SAME closed stage  
	 */
    public static void closeOpportunities(List<Id> opptyIdList, ClosedStage stage, String closeReason, String closeDescription) {
        
    	if (opptyIdList == null || opptyIdList.isEmpty()) { 
    		throw new Exceptions.IllegalArgumentException('Opportunity list is missing or empty.'); 
    	}
    	
    	if (stage == null) { 
    		throw new Exceptions.IllegalArgumentException('No stage provided.'); 
    	}
    	
    	// Set stage value based on parameter
    	String stageName;
        if (stage == ClosedStage.CLOSED_WON) {
        	stageName = Definitions.OPPTY_STAGE_ClosedWon;
        } else {
        	stageName = Definitions.OPPTY_STAGE_ClosedLost;
        }
        
        Utilities.writeLog(
            'Closing ' + opptyIdList.size()
            	+ ' opportunities  as \'' + stageName + '\'.', 
            CustomOpportunityLogic.class, 'closeOpportunities', LoggingLevel.DEBUG);
        
        // Close Opportunities
        System.Savepoint sp = Database.setSavepoint();
        try {
	        List<Opportunity> closedOpptys = new List<Opportunity>();
	        for (Id opptyId : opptyIdList) {
	        	closedOpptys.add(
	        		new Opportunity(
		        		Id = opptyId, 
		        		StageName = stageName,
		        		Reason_Closed__c = closeReason,
		        		Other_Reason__c = closeDescription
		        	)
		        );
	        }
	        upsert closedOpptys;
        } catch (Exception e) {
        	Database.rollback(sp);
        	throw e;
        }
    }
	
	/**
	 * Closes opportunities based on itemized product-level decisions. 
	 * This allows closing some products as Won and others as Lost 
	 * while leaving others unchanged. The opportunity is cloned
	 * for each independent action.
	 */
	public static void CloseOpportunitiesByProduct(List<Id> opptyIdList, Map<Id, OpptyProductStage> productStageMap) {
		
    	if (opptyIdList == null || opptyIdList.isEmpty()) { 
    		throw new Exceptions.IllegalArgumentException('Opportunity list is missing or empty.'); 
    	}
    	
    	if (productStageMap == null || productStageMap.isEmpty()) { 
    		throw new Exceptions.IllegalArgumentException('No stage information provided.'); 
    	}
    	
        // Get ALL INFO for opptys that contain the closed products
        String opptyQueryFields = String.join(Utilities.getSObjectFields(Opportunity.getSObjectType()), ',');
        String prodQueryFields = String.join(Utilities.getSObjectFields(OpportunityLineItem.getSObjectType()), ',');

        System.debug('opptyQueryFields: ' + opptyQueryFields);
        System.debug('prodQueryFields: ' + prodQueryFields);
                                
        String inlineSOQL = 'SELECT ' + opptyQueryFields + ', '
               +              '(SELECT ' + prodQueryFields + ', PricebookEntry.Name '
               +              'FROM OpportunityLineItems) '
               + 'FROM Opportunity '
               + 'WHERE Id IN (\'' + String.join(opptyIdList, '\',\'') + '\')';
        System.debug('inlineSOQL: ' + inlineSOQL);
        List<Opportunity> openOpptyList = Database.query(inlineSOQL);

    	//List<Opportunity> openOpptyList = Database.query(
        //	  'SELECT ' + opptyQueryFields + ', '
		//	+	'(SELECT ' + prodQueryFields + ', PricebookEntry.Name '
		//	+	'FROM OpportunityLineItems) '
        //	+ 'FROM Opportunity '
        //	+ 'WHERE Id IN (\'' + String.join(opptyIdList, '\',\'') + '\')'
    	//);
    	
    	// The following individual maps are required for inserting cloned records.
    	// SDFDC will throw an error if multiple unique items exist in the operation
    	Integer mapIndex = 0;
    	Map<Integer, Opportunity> wonOpptyMap = new Map<Integer, Opportunity>();
    	Map<Integer, Opportunity> lostOpptyMap = new Map<Integer, Opportunity>();
    	Map<Integer, Opportunity> unchangedOpptyMap = new Map<Integer, Opportunity>();
    	Map<Integer, List<OpportunityLineItem>> closedProductMap = new Map<Integer, List<OpportunityLineItem>>();
    	
    	// These will hold the globally-applicable WON and LOST reasons
    	// TODO Consider applying these by product type (will require cloning opptys by product type as well).
    	String closedWonReason;
    	String closedWonDesc;
    	String closedLostReason;
    	String closedLostDesc;
    	
    	// Iterate over each of the closed opptys
    	for (Opportunity openOppty : openOpptyList) {
    		
			Utilities.writeLog(
				'Checking close selections for opportunity \'' + openOppty.Name + '\' products', 
				CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
				
    		List<OpportunityLineItem> closedWon = new List<OpportunityLineItem>();
    		List<OpportunityLineItem> closedLost = new List<OpportunityLineItem>();
    		List<OpportunityLineItem> unchanged = new List<OpportunityLineItem>();
    		
    		// Iterate over the available oppty products for this opportunity
    		for (OpportunityLineItem openOpptyProduct : openOppty.OpportunityLineItems) {
    			
				Utilities.writeLog(
					'Checking opportunity product \'' + openOpptyProduct.PricebookEntry.Name + '\'', 
					CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
					
    			// Check to see if this available oppty product was one of the closed products
    			if (productStageMap.containsKey(openOpptyProduct.PricebookEntryId)) {
    				OpptyProductStage thisProductStage = productStageMap.get(openOpptyProduct.PricebookEntryId); 
    				if (thisProductStage.stage == Definitions.OPPTY_STAGE_ClosedWon) {
    					if (closedWonReason == null && thisProductStage.reason != null) {
    						closedWonReason = thisProductStage.reason;
    						closedWonDesc = thisProductStage.description;
							Utilities.writeLog(
								'Closed WON Reason set to \'' + closedWonReason + '\'.', 
								CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
    					}
						Utilities.writeLog(
							'Opportunity product \'' + openOpptyProduct.PricebookEntry.Name + '\' was set to WON', 
							CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
    					closedWon.add(openOpptyProduct);
    				} else {
    					if (closedLostReason == null && thisProductStage.reason != null) {
    						closedLostReason = thisProductStage.reason;
    						closedLostDesc = thisProductStage.description;
							Utilities.writeLog(
								'Closed LOST Reason set to \'' + closedLostReason + '\'.', 
								CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
    					}
						Utilities.writeLog(
							'Opportunity product \'' + openOpptyProduct.PricebookEntry.Name + '\' was set to LOST', 
							CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
    					closedLost.add(openOpptyProduct);
    				}
    			} else {
					Utilities.writeLog(
						'Opportunity product \'' + openOpptyProduct.PricebookEntry.Name + '\' was UNCHANGED', 
						CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
    				unchanged.add(openOpptyProduct);
    			}
        	}
        	
			Utilities.writeLog(
				'WON Count: ' + closedWon.size() + '; LOST Count: ' + closedLost.size() + '; UNCHANGED Count: ' + unchanged.size(), 
				CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
			
			Integer listCount = 0;
			if (!closedWon.isEmpty()) { listCount++; }
			if (!closedLost.isEmpty()) { listCount++; }
			if (!unchanged.isEmpty()) { listCount++; }
			
        	// Determine if we need to clone the oppty
        	if (listCount < 2) {
	        	
				Utilities.writeLog(
					'Only a single close-type found. Closing entire opportunity.', 
					CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
					
	        	// Only 1 list has data, then no reason to clone. Operate on the whole.
	        	
				if (!closedWon.isEmpty()) {
					openOppty.StageName = Definitions.OPPTY_STAGE_ClosedWon;
	    			openOppty.Reason_Closed__c = closedWonReason;
	    			openOppty.Other_Reason__c = closedWonDesc;
					mapIndex++;
	        		wonOpptyMap.put(mapIndex, openOppty);
	        		closedProductMap.put(mapIndex, new List<OpportunityLineItem>());
	        		
	        	} else if (!closedLost.isEmpty()) {
	        		openOppty.StageName = Definitions.OPPTY_STAGE_ClosedLost;
	    			openOppty.Reason_Closed__c = closedLostReason;
	    			openOppty.Other_Reason__c = closedLostDesc;
					mapIndex++;
	        		lostOpptyMap.put(mapIndex, openOppty);
	        		closedProductMap.put(mapIndex, new List<OpportunityLineItem>());
	        	} else {
	        		// Nothing to do. This is improbable at best.
	        	}
        		
        	} else {
	        	
	        	// Create a deep clone
	        	Opportunity clonedOppty = openOppty.clone(false, true);
	        	clonedOppty.ClonedFrom__c = openOppty.Id;
	        	
	        	Boolean opptyIsClosed = false;
	        	
	        	// Check for WON items first
	        	if (!closedWon.isEmpty()) {
					Utilities.writeLog(
						'Identified ' + closedWon.size() + ' WON opportunity products.', 
						CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
					mapIndex++;
	        		wonOpptyMap.put(mapIndex, openOppty);
	        		closedProductMap.put(mapIndex, closedWon);
	        		opptyIsClosed = true;
	        	}
	        	
	        	// Check for LOST items next
	        	if (!closedLost.isEmpty()) {
					Utilities.writeLog(
						'Identified ' + closedLost.size() + ' LOST opportunity products.', 
						CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
	        		Opportunity lostOppty = opptyIsClosed ? clonedOppty.clone(false, true) : openOppty;
					mapIndex++;
	        		lostOpptyMap.put(mapIndex, lostOppty);
	        		closedProductMap.put(mapIndex, closedLost);
	        		opptyIsClosed = true;
	        	}
	        	
	        	// Finally, check for unchanged items
	        	// If the opportunity is not yet closed, then no changes were made. Ignore.
	        	// NOTE The opptyIsClosed here is little more than a quick sanity check 
	        	// as it should never be expected to be false once we reach this point.
	        	if (!unchanged.isEmpty() && opptyIsClosed) {
					Utilities.writeLog(
						'Identified ' + unchanged.size() + ' UNCHANGED opportunity products.', 
						CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
					mapIndex++;
	        		unchangedOpptyMap.put(mapIndex, clonedOppty);
	        		closedProductMap.put(mapIndex, unchanged);
	        	}
        	}
    	}
    	
    	// Save
    	System.Savepoint sp = Database.setSavepoint();
    	try {
			List<OpportunityLineItem> savedOpptyProducts = new List<OpportunityLineItem>();
    		
    		// Save opportunities (to get Ids for assigning products)
    		if (!unchangedOpptyMap.isEmpty()) {
				Utilities.writeLog(
					'Cloning ' + unchangedOpptyMap.size() + ' opportunities for UNCHANGED products.', 
					CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
	    		upsert unchangedOpptyMap.values();
	    		
	    		/*
	    		// TODO DEBUG ONLY!!!
	    		for (Opportunity oppty : unchangedOpptyMap.values()) {
	    			System.debug('Opportunity: ' + oppty.Name + ' - ' + oppty.StageName + ' (' + oppty.Id + ')');
	    		}
	    		*/
    		}
    		
    		if (!wonOpptyMap.isEmpty()) {
				Utilities.writeLog(
					'Cloning ' + lostOpptyMap.size() + ' opportunities for LOST products.', 
					CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
	    		upsert lostOpptyMap.values();
	    		
	    		/*
	    		// TODO DEBUG ONLY!!!
	    		for (Opportunity oppty : lostOpptyMap.values()) {
	    			System.debug('Opportunity: ' + oppty.Name + ' - ' + oppty.StageName + ' (' + oppty.Id + ')');
	    		}
	    		*/
    		}
    		
    		// Update WON oppty statuses
    		for (Opportunity oppty : wonOpptyMap.values()) {
    			oppty.StageName = Definitions.OPPTY_STAGE_ClosedWon;
    			oppty.Reason_Closed__c = closedWonReason;
    			oppty.Other_Reason__c = closedWonDesc;
    			System.debug('Opportunity: ' + oppty.Name + ' - ' + oppty.StageName + ' (' + oppty.Id + ')');
    		}
    		
    		// Combine opptys into a single list for final upsert
    		List<Opportunity> updatedOpptys = new List<Opportunity>();
    		updatedOpptys.addAll(wonOpptyMap.values());
    		updatedOpptys.addAll(unchangedOpptyMap.values());
    		
    		// Clone unchanged oppty products
    		List<OpportunityLineItem> deletedOpptyProducts = new List<OpportunityLineItem>();
    		for (Integer opptyIndex : unchangedOpptyMap.keyset()) {
    			
    			Opportunity oppty = unchangedOpptyMap.get(opptyIndex);
    			
    			for (OpportunityLineItem prod : closedProductMap.get(opptyIndex)) {
    				OpportunityLineItem productToAdd = prod.clone(false, true, true, true);
    				productToAdd.OpportunityId = oppty.Id;
    				productToAdd.TotalPrice = null;
    				System.debug('Original Product: ' + prod);
    				System.debug('Cloned Product:   ' + productToAdd);
    				savedOpptyProducts.add(productToAdd);
    				deletedOpptyProducts.add(prod);
    			}
    		}
    		
    		// Update lost oportunities
    		for (Integer opptyIndex : lostOpptyMap.keyset()) {
    			
    			Opportunity oppty = lostOpptyMap.get(opptyIndex);
    			oppty.StageName = Definitions.OPPTY_STAGE_ClosedLost;
    			oppty.Reason_Closed__c = closedLostReason;
    			oppty.Other_Reason__c = closedLostDesc;
    			updatedOpptys.add(oppty);
	    		
	    		// Clone lost oppty products
	    		// NOTE LOST opptys only need reparenting if there are also WON opptys
	    		// Otherwise, the LOST oppty is the original oppty
	    		if (!wonOpptyMap.isEmpty()) {
	    			for (OpportunityLineItem prod : closedProductMap.get(opptyIndex)) {
	    				OpportunityLineItem productToAdd = prod.clone(false, true, true, true);
	    				productToAdd.OpportunityId = oppty.Id;
	    				productToAdd.TotalPrice = null;
	    				System.debug('Original Product: ' + prod);
	    				System.debug('Cloned Product:   ' + productToAdd);
	    				savedOpptyProducts.add(productToAdd);
	    				deletedOpptyProducts.add(prod);
	    			}
	    		}
    		}
    		
			Utilities.writeLog(
				'Deleting ' + savedOpptyProducts.size() + ' old opportunity products.', 
					CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);

    		delete deletedOpptyProducts;
    		
			Utilities.writeLog(
				'Adding ' + savedOpptyProducts.size() + ' new opportunity products.', 
					CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);

    		upsert savedOpptyProducts;
    		
			Utilities.writeLog(
				'Saving ALL ' + updatedOpptys.size() + ' opportunities with their final statuses.', 
					CustomOpportunityLogic.class, 'closeOpportunityByProduct', LoggingLevel.DEBUG);
			
    		// TODO DEBUG ONLY!!!
    		for (Opportunity oppty : updatedOpptys) {
    			System.debug('Opportunity: ' + oppty.Name + ' - ' + oppty.StageName + ' (' + oppty.Id + ')');
    		}
			upsert updatedOpptys;
			
    	} catch (Exception e) {
    		Database.rollback(sp);
    		throw e;
    	}
	}

    public static string createSiteSurvey(Id OppID, Integer owntype) {
        
        //check to make sure new list is not empty
        if(OppID == null ) {
            throw new Exceptions.IllegalArgumentException('Opportunity empty');
        }
        
        Opportunity Opp = [SELECT 
        					  Id,
        					  Name, 
        					  Account_ID__c, 
        					  of_Rooms_Opportunity__c 
        				   FROM 
        				      Opportunity 
        				   WHERE 
        				   	  id = :OppID
        				   LIMIT 1][0];
        
        Utilities.writeLog('Creating site survey for ' + Opp.name + ' opportunity.',
                            CustomOpportunityLogic.class, 'createSiteSurvey', LoggingLevel.DEBUG);        
        
        //query for the queue
        QueueSobject groupQueue = [SELECT 
        							  Id,
        						      QueueId 
        						   FROM 
        						   	  QueueSobject 
        						   WHERE 
        						   	  SobjectType = 'Site_Survey__c'  
        						   	  AND Queue.DeveloperName = 'Installs_Site_Surveys' 
        						   LIMIT 1][0]; 
        
        //initialize the fields
        Site_Survey__c site = new Site_Survey__c();
        site.Opportunity__c = OppID;
        site.Site__c = Opp.Account_ID__c;
        site.Number_of_Rooms__c = Opp.of_Rooms_Opportunity__c;
        site.RecordTypeId =  Utilities.RecordTypeNameToId('Site_Survey__c', 'Parent Site Survey');
        
        if(owntype == null || owntype < 1)
        {  site.OwnerId = groupQueue.QueueId; }
        
        String result = '';
        try {
          //upsert the Site Survey;
          upsert site;
        } catch( Exception e) {
             result = 'Unable to upsert site survey to opportunity: ' +e.getMessage();
             Utilities.writeLog('Unable to upsert site survey to opportunity with details: ' +e.getMessage(), 
             					 CustomOpportunityLogic.class, 'createSiteSurvety', LoggingLevel.DEBUG);
        }
        return result;
	}

}