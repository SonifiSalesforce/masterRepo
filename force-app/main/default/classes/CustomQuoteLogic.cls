public with sharing class CustomQuoteLogic {
	
	public static final String					FIELDNAME_QUOTE							= 'quote';
	public static final String 					FIELDNAME_PROGRAMMING 					= 'programming';
	public static final String 					FIELDNAME_PROGRAMMING_ITEMS				= 'items';
	public static final String					FIELDNAME_ID							= 'id';
	public static final String					FIELDNAME_QTY							= 'qty';
	public static final String					FIELDNAME_VALUE							= 'value';
	public static final String					FIELDNAME_STATUS						= 'status';
	
	private class InProcessProgrammingItem {
		String productCode;
		InProcessProgrammingItem parent;
		Programming__c detail;
		InProcessProgrammingItem() { 
			detail = new Programming__c(); 
		}
	}
	
	private class InProcessQuoteLineItem {
		String productCode;
		QuoteLineItem detail;
		List<InProcessProgrammingItem> programming;
		InProcessQuoteLineItem() {
			detail = new QuoteLineItem();
			programming = new List<InProcessProgrammingItem>();
		}
	}
	
	private class InProcessQuote {
		Quote detail;
		List<InProcessQuoteLineItem> lineItems;
		InProcessQuote() { 
			detail = new Quote();
			lineItems = new List<InProcessQuoteLineItem>();
		}
	}
	
	// These exist to prevent us from having to loop over every object to pull them out
	// during finalize. By writing them here as well as adding them to the structure, 
	// when one object is updated, all references are as well.
	private List<Quote> masterQuoteList = new List<Quote>();
	private List<QuoteLineItem> masterQuoteItemList = new List<QuoteLineItem>();

	// Because there are multiple quotes and each quote can have the exact same configuration,
	// there is a high probability that two Programming__c records would be identical, which is
	// a no-no in insert/upsert operations. To avoid this, we need to do 2 things. First, ensure 
	// that the programming for each quote is submitted independently. Second, within the programming,
	// ensure that each programming item only exists once.
	private List<Programming__c> masterProgrammingList = new List<Programming__c>();
	private Set<String> productCodeSet = new Set<String>();
	private Set<Id> opptyIdSet = new Set<Id>();
	
	/**
	 *
	 */
	public List<Quote> createQuotes(String quoteJson) {
		
		if (quoteJson == null || quoteJson == '') {
			Utilities.writeLog(
					'Failed to create quotes. Details: No quote data provided.', 
					CustomQuoteLogic.class, 'submitQuote', LoggingLevel.ERROR);
			return null;
		}
		
		Utilities.writeLog('Raw Quote Data: ' + quoteJson, 
			CustomQuoteLogic.class, 'createQuotes', LoggingLevel.INFO);
		
		List<Quote> quoteList;
		
		
		try {
			
			// Parse JSON-formatted quote data into object for creation
			// TODO Include check for multiple quotes
			// NOTE This will mean checking for an array in the JSON string
			Map<String, Object> quoteObjectList = (Map<String, Object>) JSON.deserializeUntyped(quoteJson);
			if (quoteObjectList == null || quoteObjectList.isEmpty()) {
				Utilities.writeLog(
						'Failed to create quotes. Details: Unable to convert JSON data.', 
						CustomQuoteLogic.class, 'submitQuote', LoggingLevel.ERROR);
				return null;
			}
			
			Map<String, Object> quoteItemMap = (Map<String, Object>)quoteObjectList.get(FIELDNAME_QUOTE);
			if (quoteItemMap == null || quoteItemMap.isEmpty()) {
				Utilities.writeLog(
						'Failed to create quotes. Details: Unable to read quote data.', 
						CustomQuoteLogic.class, 'submitQuote', LoggingLevel.ERROR);
				return null;
			}
			
			// Process quote object with appropriate method (single or array)
			quoteList = createQuote(quoteItemMap);
			
		} catch (Exception e) {
			Utilities.writeLog(
					'Failed to create quotes. Details: ' + e.getMessage(), 
					CustomQuoteLogic.class, 'createQuotes', LoggingLevel.ERROR);
			return null;	
		}
		
		return quoteList;
	}
	
	/**
	 * Creates a LIST of quotes from an array of JSON-formatted quote objects
	 */
	private List<InProcessQuote> createQuote(List<Map<String, Object>> quoteMap) {

		// TODO Implement this
		throw new Exceptions.UnsupportedOperationException('Only a single quote can be processed at a time.');

		Utilities.writeLog(
				'Creating ARRAY of quotes from JSON object array', 
				CustomQuoteLogic.class, 'createQuote', LoggingLevel.DEBUG);
		
		return null;
	}
	
	/**
	 * Generates a SINGLE quote item from a JSON-formatted quote object
	 */
	private List<Quote> createQuote(Map<String, Object> quoteMap) {
		
		Utilities.writeLog(
				'Creating SINGLE quote from JSON object map', 
				CustomQuoteLogic.class, 'createQuote', LoggingLevel.DEBUG);
		
		InProcessQuote thisQuote = new InProcessQuote();
		
		// Iterate through quote fields and build quote
		for (String fieldName : quoteMap.keyset()) {
			
			Utilities.writeLog(
					'Processing quote field \'' + fieldName + '\'', 
					CustomQuoteLogic.class, 'createQuotes', LoggingLevel.DEBUG);
			
			// Check for programming data
			if (fieldName.toLowerCase() == FIELDNAME_PROGRAMMING) {
				
				// Quote programming
				
				// System.debug('Programming: ' + quoteMap.get(fieldName));
				List<InProcessQuoteLineItem> quoteLineItems = createQuoteLineItems(
						(List<Object>)quoteMap.get(fieldName));
				if (quoteLineItems == null) { throw new Exceptions.AppException('Failed to parse quote programming.'); }
				if (!quoteLineItems.isEmpty()) { thisQuote.lineItems.addAll(quoteLineItems); }
				
			} else {
				
				// Quote field
				
				Object fieldValue = quoteMap.get(fieldName);
				
				try {
					thisQuote.detail.put(fieldName, fieldValue);
					Utilities.writeLog(
							'Quote field \'' + fieldName + '\' set to \'' + fieldValue + '\'', 
							CustomQuoteLogic.class, 'createQuotes', LoggingLevel.DEBUG);
				} catch (Exception e) {
					Utilities.writeLog(
							'Unknown quote field \'' + fieldName + '\'. Ignoring.', 
							CustomQuoteLogic.class, 'createQuotes', LoggingLevel.WARN);
				}
			}
		}
		
		opptyIdSet.add(thisQuote.detail.OpportunityId);
		masterQuoteList.add(thisQuote.detail);
		
		// Finalize quote creation and return
		return finalizeQuotes(new List<InProcessQuote> { thisQuote });
	}
	
	/**
	 * Processes programming items and converts to quote line items and programming sub-items
	 */
	private List<InProcessQuoteLineItem> createQuoteLineItems(List<Object> quoteItemObjectList) {
		
		Utilities.writeLog(
				'Creating quote line items...', 
				CustomQuoteLogic.class, 'createQuoteLineItems', LoggingLevel.DEBUG);
		
		// System.debug('Quote item object list: ' + quoteItemObjectList);
		
		List<InProcessQuoteLineItem> quoteLineItems = new List<InProcessQuoteLineItem>();
		
		// Iterate over quote item objects
		for (Object quoteItemObject : quoteItemObjectList) {
			
			// System.debug('Quote item object: ' + quoteItemObject);
			
			// Iterate over quote item definitions and programming
			Map<String, Object> quoteItemMap = (Map<String, Object>)quoteItemObject;
			
			InProcessQuoteLineItem quoteItem = new InProcessQuoteLineItem();
			InProcessProgrammingItem programmingHeader = new InProcessProgrammingItem();
			
			for (String fieldName : quoteItemMap.keyset()) {
				
				if (fieldName.toLowerCase() == FIELDNAME_PROGRAMMING_ITEMS) {
					
					// Build programming

					Utilities.writeLog(
							'Processing quote item field \'' + fieldName + '\'.', 
							CustomQuoteLogic.class, 'createQuoteLineItems', LoggingLevel.DEBUG);
					
					List<InProcessProgrammingItem> programmingItems = new List<InProcessProgrammingItem> { programmingHeader };
					programmingItems.addAll(createProgrammingItems(
							(List<Object>)quoteItemMap.get(fieldName), programmingHeader));
					if (programmingItems == null) { throw new Exceptions.AppException('Unable to create programming.'); }
					if (!programmingItems.isEmpty()) { quoteItem.programming.addAll(programmingItems); }
					
				} else {
					
					// Quote line item data
					
					Object fieldValue = quoteItemMap.get(fieldName);
					
					Utilities.writeLog(
							'Setting quote item field \'' + fieldName + '\' to \'' + fieldValue + '\'', 
							CustomQuoteLogic.class, 'createQuoteLineItems', LoggingLevel.DEBUG);
							
					if (fieldName == FIELDNAME_ID) {
						programmingHeader.productCode = String.valueOf(fieldValue); 
						programmingHeader.detail.Name = 'Programming Package - ' + programmingHeader.productCode;
						quoteItem.productCode = programmingHeader.productCode;
						productCodeSet.add(quoteItem.productCode);
					} else if (fieldName == FIELDNAME_QTY) {
						quoteItem.detail.Quantity = Double.valueOf(fieldValue);

						// Only bring in items that have a quantity
						if (quoteItem.detail.Quantity == 0) { break; }

						programmingHeader.detail.Qty__c = quoteItem.detail.Quantity;
						
					} else if (fieldName == FIELDNAME_VALUE) {
						programmingHeader.detail.Price__c = Double.valueOf(fieldValue); 
						quoteItem.detail.UnitPrice = programmingHeader.detail.Price__c;
					} else if (fieldName == FIELDNAME_STATUS) {
						programmingHeader.detail.Status__c = String.valueOf(fieldValue); 
						quoteItem.detail.Status__c = programmingHeader.detail.Status__c;
					} else {
						try { 
							quoteItem.detail.put(fieldName, fieldValue); 
							Utilities.writeLog(
									'Quote item field \'' + fieldName + '\' set to \'' + fieldValue + '\'', 
									CustomQuoteLogic.class, 'createQuoteLineItems', LoggingLevel.DEBUG);
						}
						catch (Exception e) {
							Utilities.writeLog(
									'Unknown quote item field \'' + fieldName + '\'. Ignoring.', 
									CustomQuoteLogic.class, 'createQuoteLineItems', LoggingLevel.WARN);
						}
					}
				}
			}
			
			// Check for product Id
			if (quoteItem.productCode == null || quoteItem.productCode == '') {
				throw new Exceptions.AppException('No product code provided for quote line item.');
			}
			
			Utilities.writeLog(
					'Adding quote line item for product code ' + quoteItem.productCode 
						+ '(Qty: ' + quoteItem.detail.Quantity + '; Price: ' + quoteItem.detail.TotalPrice + ')',
					CustomQuoteLogic.class, 'createQuoteLineItems', LoggingLevel.INFO);
			
			// Add quote to map
			masterProgrammingList.add(programmingHeader.detail);
			masterQuoteItemList.add(quoteItem.detail);
			quoteLineItems.add(quoteItem);
		}
		
		return quoteLineItems;
	}

	/**
	 * Creates programming items (sub-items to quote line items)
	 */
	private List<InProcessProgrammingItem> createProgrammingItems(
			List<Object> programmingItemObjectList, 
			InProcessProgrammingItem parentProgramming) {
		
		Utilities.writeLog(
				'Creating programming items for ' + 
				(parentProgramming == null ? 'quote line item...' : 'for programming package \'' + parentProgramming.productCode + '\'...'), 
				CustomQuoteLogic.class, 'createProgrammingItems', LoggingLevel.DEBUG);
				
		Integer parentIndex = 0;
		Map<String, Programming__c> programmingMap = new Map<String, Programming__c>();
		List<InProcessProgrammingItem> programmingItems = new List<InProcessProgrammingItem>();
		
		try {
			
			for (Object programmingItemObject : programmingItemObjectList) {
				
				InProcessProgrammingItem programmingItem = new InProcessProgrammingItem();
				programmingItem.parent = parentProgramming;
				
				Map<String, Object> programmingItemMap = (Map<String, Object>)programmingItemObject;
				
				for (String fieldName : programmingItemMap.keyset()) {
					
					if (fieldName.toLowerCase() == FIELDNAME_PROGRAMMING_ITEMS) {
						
						// Build child programming
						List<InProcessProgrammingItem> childItems = createProgrammingItems(
								(List<Object>)programmingItemMap.get(fieldName),
								programmingItem);
						if (childItems == null) { throw new Exceptions.AppException('Unable to create programming.'); }
						if (!childItems.isEmpty()) { programmingItems.addAll(childItems); }
						
					} else {
						
						// Programming item data
						
						Object fieldValue = programmingItemMap.get(fieldName);
						/*
						Utilities.writeLog(
								'Setting programming item field \'' + fieldName + '\' to \'' + fieldValue + '\'', 
								CustomQuoteLogic.class, 'createProgrammingItems', LoggingLevel.DEBUG);
						*/	
						if (fieldName == FIELDNAME_ID) {
							programmingItem.productCode = String.valueOf(fieldValue);
							programmingItem.detail.Name = parentProgramming.productCode + ' Product - ' + programmingItem.productCode;
							productCodeSet.add(programmingItem.productCode);
						} else if (fieldName == FIELDNAME_QTY) {
							programmingItem.detail.Qty__c = Double.valueOf(fieldValue);
							
							// Only bring in items that have a quantity
							if (programmingItem.detail.Qty__c == 0) { break; }
							
						} else if (fieldName == FIELDNAME_VALUE) {
							programmingItem.detail.Price__c = Double.valueOf(fieldValue);
						} else if (fieldName == FIELDNAME_STATUS) {
							programmingItem.detail.Status__c = String.valueOf(fieldValue);
						} else {
							try { 
								programmingItem.detail.put(fieldName, fieldValue);
								/* 
								Utilities.writeLog(
										'Programming item field \'' + fieldName + '\' set to \'' + fieldValue + '\'', 
										CustomQuoteLogic.class, 'createProgrammingItems', LoggingLevel.DEBUG);
								*/
							}
							catch (Exception e) {
								Utilities.writeLog(
										'Unknown programming item field \'' + fieldName + '\'. Ignoring.', 
										CustomQuoteLogic.class, 'createProgrammingItems', LoggingLevel.WARN);
							}
						}
					}
				}
				
				// Check for product number
				if (programmingItem.productCode == null || programmingItem.productCode == '') {
					throw new Exceptions.AppException('No product number provided for programming item.');
				}
				
				Utilities.writeLog(
						'Adding programming line item for product code ' + programmingItem.productCode 
							+ ' (Qty: ' + programmingItem.detail.Qty__c + '; Price: ' + programmingItem.detail.Price__c + ')',
						CustomQuoteLogic.class, 'createProgrammingItems', LoggingLevel.INFO);
				
				// Check for programming item already exists
				// NOTE This asserts that the first qty + value for an item is the right answer.
				// Based on the way the feasibility works, this is a valid assumption at this time.  
				if (!programmingMap.containsKey(programmingItem.productCode)) {
					masterProgrammingList.add(programmingItem.detail);
					programmingMap.put(programmingItem.productCode, programmingItem.detail);
					programmingItems.add(programmingItem);
				}
				
			}
		} catch (Exception e) {
			throw new Exceptions.AppException('Failed to create programming. Details: ' + e.getMessage()); 
		}
		
		return programmingItems;
	}

	private List<Quote> finalizeQuotes(List<InProcessQuote> inProcessQuoteList) {
		
		Utilities.writeLog(
				'Finalizing quotes...',
				CustomQuoteLogic.class, 'finalizeQuotes', LoggingLevel.DEBUG);
		
		// Get opptys to work with
		Boolean hasPriceBookId = false;
		Map<Id, Opportunity> opptyMap;
		try {
			opptyMap = new Map<Id, Opportunity> ([
				SELECT Id, PriceBook2Id, Account_Name__c, Number_of_Quotes__c
				FROM Opportunity
				WHERE Id IN :opptyIdSet
			]);
		} catch (Exception e) {
			throw new Exceptions.AppException('Failed to create quotes. Details: ' + e.getMessage());
		}
		// System.debug('Oppty Map: ' + opptyMap);
		
		Id priceBookId;
		for (Quote q : masterQuoteList) {
			Opportunity oppty = opptyMap.get(q.OpportunityId);
			
			// Increment number of quotes
			if (oppty.Number_Of_Quotes__c == null) { oppty.Number_Of_Quotes__c = 0; }
			oppty.Number_Of_Quotes__c++;
			
			// Assign name to new quote
			q.Name = oppty.Account_Name__c + ' - ' + DateTime.now().format('yyyy-MM-dd') + ' - Quote ' + oppty.Number_Of_Quotes__c;
			
			// Check for pricebook Id
			if (!hasPriceBookId && oppty.Pricebook2Id != null) {
				hasPriceBookId = true;
				priceBookId = oppty.Pricebook2Id;
			}
			
			Utilities.writeLog(
					'Creating new quote \'' + q.Name + '\'', 
					CustomQuoteLogic.class, 'finalizeQuotes', LoggingLevel.DEBUG);
		}
		
		// Check for no pricebook found
		if (priceBookId == null) {
			Utilities.writeLog(
					'No pricebook configured for quote opportunities. Using \'' + Definitions.PRICEBOOK_Hospitality + '\'', 
					CustomQuoteLogic.class, 'finalizeQuotes', LoggingLevel.WARN);
			try {
				priceBookId = [
					SELECT Id
					FROM Pricebook2
					WHERE Name = :Definitions.PRICEBOOK_Hospitality
					LIMIT 1
				].Id;
			} catch (Exception e) {
				throw new Exceptions.AppException(
						'Failed to create quotes. Details: Could not locate pricebook \'' + Definitions.PRICEBOOK_Hospitality + '\'');
			}
		}
		System.debug('Pricebook Id: ' + priceBookId);
		
		// Iterate over quotes and update pricebook
		for (Quote q : masterQuoteList) {
			q.Pricebook2Id = priceBookId;
			
			// NOTE This forces all opportunities to use the same pricebook
			opptyMap.get(q.OpportunityId).Pricebook2Id = priceBookId;
		}
		
		// Get all products referenced in the quotes
		// System.debug('Product Codes: ' + productCodeSet);
		List<PricebookEntry> productList = [
			SELECT Id, Name, Product2Id, ProductCode, UnitPrice
			FROM PriceBookEntry
			WHERE Pricebook2Id = :priceBookId
			  AND ProductCode IN :productCodeSet
		];
		// System.debug('Product List Size: ' + productList.size());
		
		// Reorganize products into a workable map
		Map<String, PricebookEntry> pricebookMap = new Map<String, PricebookEntry>();
		for (PricebookEntry entry : productList) {
			// System.debug('Pricebook Entry: ' + entry.ProductCode + ' (Id=' + entry.Id + ')');
			pricebookMap.put(entry.ProductCode, entry);
		}
		// System.debug('PriceBook Map: ' + pricebookMap);
		
		// Set savepoint for rollback if errors encountered
		System.Savepoint sp = Database.setSavepoint();
		
		try {
			
			// Insert quotes
			insert masterQuoteList;
			
			// Iterate through quotes
			for (InProcessQuote q : inProcessQuoteList) {
				
				// Iterate over quote line items
				for (InProcessQuoteLineItem l : q.lineItems) {
					
					try {
						// Update item detail and add to list
						l.detail.QuoteId = q.detail.Id;
						l.detail.PricebookEntryId = pricebookMap.get(l.productCode).Id;
					} catch (Exception e) {
						throw new Exceptions.IllegalArgumentException('No product found for \'' + l.productCode + '\'');
					}
					
				}
			}
			
			// Insert quote line items
			insert masterQuoteItemList;
			
			System.debug('Inserting programming...');
			for (Programming__c p : masterProgrammingList) {
				System.debug('\t\t' + p.Name); //p.ProductCode__c + ' ' + p.ProductName__c + '. Qty: ' + p.Qty__c + '; Price: ' + p.Price__c);
			}
			insert masterProgrammingList;
			
			// Iterate through quotes
			for (InProcessQuote q : inProcessQuoteList) {
				
				// Iterate over quote line items
				for (InProcessQuoteLineItem l : q.lineItems) {
					
					// Iterate over programming items
					if (l.programming != null) {
						for (InProcessProgrammingItem p : l.programming) {
							
							try {
								
								// Check for parent
								if (p.parent == null) {
									// No parent. Assign to quote line item
									p.detail.QuoteLineItem__c = l.detail.Id;
									
								} else {
									// Parent exists. Set parent Id
									// System.debug('Parent: ' + p.parent.detail.Id);
									p.detail.Parent__c = p.parent.detail.Id;
								}
								
								p.detail.Product__c = pricebookMap.get(p.productCode).Product2Id;
							} catch (Exception e) {
								System.debug('Exception: ' + e.getMessage());
								throw new Exceptions.IllegalArgumentException('No product found for \'' + p.productCode + '\'');
							}
						}
					}
				}
			}
			
			// Update programming items
			update masterProgrammingList;
			
			// Update opportunities
			upsert opptyMap.values();
			
		} catch (Exception e) {
			// Rollback any changes
			Database.rollback(sp);
			throw new Exceptions.AppException('Failed to save quotes. Details: ' + e.getMessage());
		}
		
		return masterQuoteList;
	}

	/**
	 *
	 */
	public static String applyQuoteToOpportunity(Id quoteId, Id opptyId) {
		CustomQuoteLogic quoteLogic = new CustomQuoteLogic();
		try { quoteLogic.applyQuote(quoteId, opptyId); } 
		catch (Exception e) { return e.getMessage(); }
		return 'Quote successfully applied to opportunity.';
	}
	
	/**
	 *
	 */
	public void applyQuote(Id quoteId, Id opptyId) {
		
		// TODO Add rules to check for oppty status before allowing quote to be applied
		
		final List<String> quoteStandardFieldList = new List<String> { 'Id', 'OpportunityId' };
		final List<String> quoteLineItemStandardFieldList = new List<String> { 
			'Id',
			'ProductCode__c', 
			'PricebookEntryId' 
		};
		
		// Validate inputs
		Quote thisQuote = new Quote(Id=quoteId);
		List<Id> quoteLineItemIds = new List<Id>();
		Map<Id, QuoteLineItem> quoteLineItemMap = new Map<Id, QuoteLineItem>();
		
		Opportunity thisOppty;
		if (opptyId == null) {
			thisOppty = [
				SELECT Id, StageName 
				FROM Opportunity 
				WHERE Id IN (
					SELECT OpportunityId 
					FROM Quote 
					WHERE Id = :quoteId
				) 
				LIMIT 1];
			opptyId = thisOppty.Id;
		} else {
			thisOppty = [
				SELECT Id, StageName 
				FROM Opportunity 
				WHERE Id = :opptyId
			];
		}
		
		// Check for closed opportunity
		if (thisOppty.StageName == Definitions.OPPTY_STAGE_ClosedWon || thisOppty.StageName == Definitions.OPPTY_STAGE_ClosedLost) {
			throw new Exceptions.AppException('Cannot apply quotes to a closed opportunity.');
		}
		
		List<OpportunityLineItem> newOpptyLineItems;
		List<Programming__c> programmingItemList;
		List<Programming__c> programmingToUnlink = new List<Programming__c>(); // Programing previously linked to the quote 
		Map<Id, List<Programming__c>> programmingMap = new Map<Id, List<Programming__c>>();
		
		Utilities.writeLog('Applying quote ' + quoteId + ' to opportunity ' + opptyId + ' in stage ' + thisOppty.StageName + '.', 
			CustomQuoteLogic.class, 'applyQuote', LoggingLevel.INFO);
		
		// Get CUSTOM Quote fields
		List<String> quoteFieldList = Utilities.getSObjectFields('Quote', true);
		quoteFieldList.addAll(quoteStandardFieldList);
		
		// Get ALL Quote Line Item fields for query
		List<String> quoteLineItemFieldList = Utilities.getSObjectFields('QuoteLineItem', false);
		quoteLineItemFieldList.addAll(quoteLineItemStandardFieldList);
		
		// Build query 
		String subQuery = ', (SELECT ' + String.join(quoteLineItemFieldList, ',') + ' FROM QuoteLineItems) ';
		String query = 'SELECT ' + String.join(quoteFieldList, ',') + subQuery
					 + 'FROM Quote '
					 + 'WHERE Id = \'' + quoteId + '\' '
					 + 'LIMIT 1';
		System.debug('applyQuote Query: ' + query);
		
		// Build new opportunity line items from quote line items
		try {
			Utilities.writeLog('Mapping quote to opportunity...', 
				CustomQuoteLogic.class, 'applyQuote', LoggingLevel.DEBUG);
				
			// Execute query to get all records for applying to the opportunity
			thisQuote = Database.query(query);
			
			// Map Quote fields to Opportunity fields
			for (String field : quoteFieldList) {
				if (field.toLowerCase() != 'id') {
					try { 
						thisOppty.put(field, thisQuote.get(field)); 
					}
					catch (Exception e) {
						Utilities.writeLog('Failed to write quote field \'' + field + '\' to opportunity. Details: ' + e.getMessage(), 
							CustomQuoteLogic.class, 'applyQuote', LoggingLevel.WARN);
					}
				}
			}
			
			// Iterate over quote line items
			newOpptyLineItems = new List<OpportunityLineItem>();
			for (QuoteLineItem thisQuoteLineItem : thisQuote.QuoteLineItems) {
				
				OpportunityLineItem newOpptyItem = new OpportunityLineItem(OpportunityId=thisQuote.OpportunityId);
				
				// Add Id to line item list for querying programming later
				quoteLineItemIds.add(thisQuoteLineItem.Id);

				// Create quote line item map for associating programming with new oppty line items later
				quoteLineItemMap.put(thisQuoteLineItem.PricebookEntryId, thisQuoteLineItem);
				
				// Map Quote Line Items to Opportunity Line Items
				for (String field : quoteLineItemFieldList) {
					if (field.toLowerCase() != 'id') {
						try {
							newOpptyItem.put(field, thisQuoteLineItem.get(field)); 
						}
						catch (Exception e) {
							Utilities.writeLog('Failed to write quote line item field \'' + field + '\' to new opportunity line item. Details: ' + e.getMessage(), 
								CustomQuoteLogic.class, 'applyQuote', LoggingLevel.WARN);
						}
					}
				}
				
				newOpptyLineItems.add(newOpptyItem);
			}
			
			// Get programming items
			/*	SGP - 03/02/2014
			    Query changed (Hierarchy Tree view on Oppty) to get all programming records for new quote line items 5 levels deep
			    if more are required another query would be required
			    
			    //Original query
				SELECT Id, QuoteLineItem__c, Opportunity__c, ProductCode__c
				FROM Programming__c
				WHERE QuoteLineItem__c IN :quoteLineItemIds
				   OR Opportunity__c = :opptyId 
			*/
			programmingItemList = [SELECT 
										Id, 
										Opportunity__c, 
										ProductCode__c, 
										QuoteLineItem__c, 
										Parent__c, 
										Parent__r.QuoteLineItem__c, 
										Parent__r.Parent__c, 
										Parent__r.Parent__r.QuoteLineItem__c,
										Parent__r.Parent__r.Parent__c,
										Parent__r.Parent__r.Parent__r.QuoteLineItem__c,
										Parent__r.Parent__r.Parent__r.Parent__c,
										Parent__r.Parent__r.Parent__r.Parent__r.QuoteLineItem__c,
										Parent__r.Parent__r.Parent__r.Parent__r.Parent__c,
										Parent__r.Parent__r.Parent__r.Parent__r.Parent__r.QuoteLineItem__c
								   FROM 
								   		Programming__c 
								   WHERE 
								   		(QuoteLineItem__c IN :quoteLineItemIds
									     OR Parent__r.QuoteLineItem__c IN :quoteLineItemIds
									     OR Parent__r.Parent__r.QuoteLineItem__c IN :quoteLineItemIds
										 OR Parent__r.Parent__r.Parent__r.QuoteLineItem__c IN :quoteLineItemIds
										 OR Parent__r.Parent__r.Parent__r.Parent__r.QuoteLineItem__c IN :quoteLineItemIds
									     OR Parent__r.Parent__r.Parent__r.Parent__r.Parent__r.QuoteLineItem__c IN :quoteLineItemIds)      
									    OR Opportunity__c = :opptyId];
			
			
			// Build programming map associated by quote line items
			for (Programming__c p : programmingItemList) {
				// Check for existing opportunity link
				// If found, this is a previously linked quote. Flag for removal.
				if (p.Opportunity__c != null) {
					p.Opportunity__c = null;
					p.OpptyLineItemId__c = null;
					programmingToUnlink.add(p);
				} else {
					/*
						  SGP - 03/02/2014
						  Changed from single programming record to list of programming records in map
						  (Hierarchy Tree view on Oppty)
					*/
					List<Programming__c> programmingItems;
					Id quoteLineItemId = null;
					
					if(null != p.QuoteLineItem__c) {
						quoteLineItemId = p.QuoteLineItem__c;						
					} else if(null != p.Parent__r.QuoteLineItem__c) {
						quoteLineItemId = p.Parent__r.QuoteLineItem__c;						
					} else if(null != p.Parent__r.Parent__r.QuoteLineItem__c) {
						quoteLineItemId = p.Parent__r.Parent__r.QuoteLineItem__c;						
					} else if(null != p.Parent__r.Parent__r.Parent__r.QuoteLineItem__c) {
						quoteLineItemId = p.Parent__r.Parent__r.Parent__r.QuoteLineItem__c;						
					} else if(null != p.Parent__r.Parent__r.Parent__r.Parent__r.QuoteLineItem__c) {
						quoteLineItemId = p.Parent__r.Parent__r.Parent__r.Parent__r.QuoteLineItem__c;						
					} else if(null != p.Parent__r.Parent__r.Parent__r.Parent__r.Parent__r.QuoteLineItem__c) {
						quoteLineItemId = p.Parent__r.Parent__r.Parent__r.Parent__r.Parent__r.QuoteLineItem__c;						
					} 
					
					if(null != quoteLineItemId) {						
						if(programmingMap.containsKey(quoteLineItemId)) {
							programmingItems = programmingMap.get(quoteLineItemId);
						} else {
							programmingItems = new List<Programming__c>();
						}
						programmingItems.add(p);
						programmingMap.put(quoteLineItemId, programmingItems); 
					}
				}
			}
			
		} catch (Exception e) {
			throw new Exceptions.AppException('Failed to build opportunity items from quote. Details: ' + e.getMessage());
		}
		
		// Affect DB
		System.Savepoint sp = Database.setSavepoint();
		
		try {
			Utilities.writeLog('Updating database with mapped values...', 
				CustomQuoteLogic.class, 'applyQuote', LoggingLevel.DEBUG);
			
			// Get and delete current oppty line items
			List<OpportunityLineItem> oldOpptyLineItems = [
				SELECT Id 
				FROM OpportunityLineItem 
				WHERE Opportunity.Id =:opptyId
			];
			delete oldOpptyLineItems;
			
			// Add new oppty line items
			insert newOpptyLineItems;
			
			//To get the Quote id that was synced
			thisOppty.Applied_Quote__c = thisQuote.Id;
			
			// Update oppty
			update thisOppty;
			
			// Get recently inserted oppty line items for updating programming items
			newOpptyLineItems = [
				SELECT Id, PricebookEntryId, ProductCode__c 
				FROM OpportunityLineItem 
				WHERE Opportunity.Id =:opptyId
			];
			
			List<Programming__c> programmingToUpdate = new List<Programming__c>();
			// Iterate over newly create oppty line items
			for (OpportunityLineItem oli : newOpptyLineItems) {
				try {
					
					// Get quote line item associated with the oppty line item
					QuoteLineItem qli = quoteLineItemMap.get(oli.PricebookEntryId);
					if (programmingMap.containsKey(qli.Id)) {
						// Get programming item associated with the quote line item
						// and associate it with the oppty and oppty line item
						
						/*
						  SGP - 03/02/2014
						  Changed from single programming record to list of programming records in map
						  (Hierarchy Tree view on Oppty)
						  //programmingMap.get(qli.Id).Opportunity__c = opptyId;
						  //programmingMap.get(qli.Id).OpptyLineItemId__c = oli.Id;
						*/
						for(Programming__c programming : programmingMap.get(qli.Id)) {
							programming.Opportunity__c = opptyId;
							if(programming.QuoteLineItem__c == qli.Id) {
								programming.OpptyLineItemId__c = oli.Id;
							}
						}
						programmingToUpdate.addAll(programmingMap.get(qli.Id));
						Utilities.writeLog('Updated programming item with opportunity line item Id for product \'' + oli.ProductCode__c + '\'.', 
							CustomQuoteLogic.class, 'applyQuote', LoggingLevel.DEBUG);
					}
					
				} catch (Exception e) {
					Utilities.writeLog('Failed to update programming item with opportunity line item Id for product \'' + oli.ProductCode__c + '\'. Details: ' + e.getMessage(), 
						CustomQuoteLogic.class, 'applyQuote', LoggingLevel.WARN);
				}
			}
			
			// Unlink previous programming
			update programmingToUnlink;
			
			// Update programming items
			//update programmingMap.values();
			update programmingToUpdate;
			
		} catch (Exception e) {
			Database.rollback(sp);
			throw new Exceptions.AppException('Failed to apply quote to opportunity. Details: ' + e.getMessage());
		}
	}
}