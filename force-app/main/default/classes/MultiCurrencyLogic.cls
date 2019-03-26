public with sharing class MultiCurrencyLogic {
	private static final String FIELD_CURRENCYCODE = 'CurrencyIsoCode';
	private static final String FIELD_DATE = 'Conversion_Date__c'; //date at which the convertion should be based on
	//private static final String FIELD_CONVERTED_AMOUNT = 'Amount_USD__c';
	//private static final String FIELD_AMOUNT = 'Amount__c'; // might make this a field that passes through the paramters
	

	//convert the amount field (passed through the paramters) to USD and upsert it
	public static void convertMultiCurrency(Map<Id, Sobject> oldMap, List<SObject> newList, Map<String, String> currencyFields ){
		//debug
		System.debug('Entering method convertMultiCurrency...');
		System.debug('Old Map is ' + oldMap);
		System.debug('New List is ' + newList);
		System.debug('Fields totaling up is ' + currencyFields);
		
		// get the full map of fields
	    Map<String, SObjectField> fieldMap = newList[0].getSobjectType().getDescribe().fields.getMap();	
		
		//intialize the decimal places for fields
		final Integer USDDecimalPlaces = 2;
		
		// A list of the Currency codes to retrieve from the DatedConversionRates table
        Set<String> currCodes = new Set<String>();
        Map<Sobject, Set<String>> object2UpdateFields = new Map<Sobject, Set<String>>();
        // A list of item numbers to process from the Trigger.New[] collection
        List<Sobject> triggerItem = new List<Sobject>();
        try{
	        for(Sobject obj : newList){
	        	if(obj.get(FIELD_DATE) == null){
	        		obj.put(FIELD_DATE, Date.Today());
	        	}
	        	if(oldMap != null){
	        		//check to see if amount, date, or currency code has changed
	        		if ( ( oldMap.get((Id)obj.get('id')).Get(FIELD_DATE) != obj.Get(FIELD_DATE))
			           || ( oldMap.get((Id)obj.get('id')).Get(FIELD_CURRENCYCODE) != obj.Get(FIELD_CURRENCYCODE)) )
			        {
			        	
			        	triggerItem.add(obj);
			        	currCodes.add((string) obj.get(FIELD_CURRENCYCODE));
			        	object2UpdateFields.put(obj, currencyFields.keyset());
			        } else {
			        	for(String f : currencyFields.KeySet()){
			        		if(oldMap.get((Id)obj.get('id')).get(f) != obj.get(f)){
			        			if(object2UpdateFields.containsKey(obj)){
			        				object2UpdateFields.get(obj).add(f);
			        			} else {
			        				object2UpdateFields.put(obj, new Set<String>{f});
			        			}
			        		}
			        	}
			        }
	        	} else { // this item is about to be be inserted so need to update the converted fields
	        		
	        		triggerItem.add(obj);
	        		currCodes.add((String)obj.get(FIELD_CURRENCYCODE));
	        		object2UpdateFields.put(obj, currencyFields.keyset());
	        	}
	        }
	        System.debug('Currency codes going to be queried: ' + currCodes);
	        
	        
	        //query for the conservation rates
	        List<DatedConversionRate> exchangeRateList= [SELECT ISOCode, ConversionRate,StartDate, NextStartDate FROM DatedConversionRate WHERE ISOCode in :currCodes];
	        
	        //look through the items that need to be inserted or fields to be updated
	        for(Sobject obj : triggerItem){
	        	//get the date field and initialize the rate
	        	Date dDateFieldValue = (date)obj.get(FIELD_DATE);
	        	Double nRate = -1;
	        	//get the right datedConversionRate by name and date is within the startdate and nextStartDate
	        	for(DatedConversionRate exRate : exchangeRateList){
	        		if(exRate.IsoCode == obj.get(FIELD_CURRENCYCODE) && exRate.startDate <= dDateFieldValue && exRate.NextStartDate > dDateFieldValue){
	        			//set the conversion rate and exit loop
	        			nRate = exRate.ConversionRate;
	        			break;
	        		}
	        	}
	        	system.debug('Object is '+obj);
	        	system.debug('Fields to update are '+object2UpdateFields.get(obj));
	        	System.assertNotEquals(nRate, -1, 'A Rate was not found for the ' +dDateFieldValue + ' & ' + obj.Get(FIELD_CURRENCYCODE));
	        	for(String field : object2UpdateFields.get(obj)){
		        	//convert amount to USD using nRate
		        	if((Decimal)obj.get(field) != null)
		        	{
			        	Decimal nOriginalAmt = ((Decimal)obj.Get(field)).setScale(USDDecimalPlaces);
		        		Decimal nAmount = (nOriginalAmt / nRate).setScale(USDDecimalPlaces);
		 				
				         // Update the field (BEFORE INSERT/UPDATE ONLY)
			         	obj.put(currencyFields.get(field), nAmount);
		        	}
	        	}
	        }
			
		}catch(Exception ex){
			System.debug('Error Detected in MultiCurrencyLogic: ' + ex.getMessage() + '/' + ex.getCause());
		}
	}
}