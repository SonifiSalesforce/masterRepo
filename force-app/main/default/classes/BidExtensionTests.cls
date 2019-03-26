@isTest(seeAllData = true)
private class BidExtensionTests {
 
 	static testMethod void updateTotalPrice() {
        User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
		BidExtension stdController;
		Product2 prod;
		Bid__c card;
 		System.runAs(u1){
			//create test data
	        card = new Bid__c();
	        insert card;
	        String productRecordId = Utilities.RecordTypeNameToId('Product2', 'Labor Task');
			prod = [SELECT id, Name, Family FROM Product2 WHERE RecordTypeId = :productRecordId limit 1][0];
			Bid_Line_Item__c item = new Bid_Line_Item__c(Conversion_Date__c = Date.Today(), Bid__c = card.id, Product__c = prod.id, Default_Price__c = 200, Price__c = 50, Quantity__c = 50);
			insert item;
			
			//put in the test page
	        PageReference pageRef = Page.Bid;
			pageRef.getParameters().put('Id', card.id);
			Test.setCurrentPageReference(pageRef);
	        
	        //make the standard controller
	        ApexPages.StandardController controller = new ApexPages.StandardController(card);
	
		    // now pass it to the extension
		    stdController = new BidExtension(controller);
		    System.assert(stdController != null); // controller has successfully been created
		    
		    stdController.addRow();
		}
		
		System.assertNotEquals(null, stdController.productId2LineItem.get(prod.id));
		System.assertEquals(2, stdController.otherbidCards.KeySet().Size());
    }
    
    static testMethod void loadData() {
        User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
		BidExtension stdController;
		
		String recordTypeId = Utilities.RecordTypeNameToId('Product2', 'Labor Task');
		List<Product2> prods =[SELECT id FROM Product2 WHERE recordTypeId =:recordTypeId limit 2];
		 
		Bid__c card;
		Decimal price;
		System.runAs(u1){
			//create test data
	        card = new Bid__c();
	        insert card;
	        
	        insert new List<Bid_Line_Item__c>{new Bid_Line_Item__c (Bid__c = card.id, Product__c = prods[0].id, Quantity__c = 20, Default_Price__c = 200, Price__c = 210)};
	        
			System.debug('Products found are ' + prods);
			
			//put in the test page
	        PageReference pageRef = Page.Bid;
			pageRef.getParameters().put('Id', card.id);
			Test.setCurrentPageReference(pageRef);
	        
	        //make the standard controller
	        ApexPages.StandardController controller = new ApexPages.StandardController(card);
	
		    // now pass it to the extension
		    stdController = new BidExtension(controller);
		    System.assert(stdController != null); // controller has successfully been created
		    
		    //set values
		    System.debug('map is '+stdController.productId2LineItem);
		    System.debug('id is ' + prods[1]);
		    stdController.itemId = prods[0].id;
		    stdController.productId2LineItem.get(prods[0].id).bid.Quantity__c = 50;
		    price = stdController.productId2LineItem.get(prods[0].id).bid.Price__c;
		    stdController.updateTotalPrice();
		}
		
		//assertions
		System.assertEquals(price*50, stdController.totalPriceMap.get(prods[0].id));
    }
    
    
    
    static testMethod void saveAll() {
    	BidExtension stdController;
        User u1 = DataGenerator.createUsers('System Administrator', 1, true)[0];
        u1.DefaultCurrencyIsoCode  = 'USD';
        update u1;
        
		String recordTypeId = Utilities.RecordTypeNameToId('Product2', 'Labor Task');
		List<Product2> prods =[SELECT id FROM Product2 WHERE recordTypeId =:recordTypeId limit 2];
		 
		Bid__c card;
		System.runAs(u1){
			//create test data
	        card = new Bid__c(CurrencyIsoCode = 'USD');
	        insert card;
			
	        insert new List<Bid_Line_Item__c>{new Bid_Line_Item__c(Bid__c = card.id, Product__c = prods[0].id, Quantity__c = 20, Default_Price__c = 200, Price__c = 210)};
	        
			//put in the test page
	        PageReference pageRef = Page.Bid;
			Test.setCurrentPageReference(pageRef);
	        
	        //make the standard controller
	        ApexPages.StandardController controller = new ApexPages.StandardController(card);
	
		    // now pass it to the extension
		    stdController = new BidExtension(controller);
		    System.assert(stdController != null); // controller has successfully been created
		    
		    stdController.productId2LineItem.get(prods[0].id).bid.Quantity__c = 100;
		    stdController.saveAll();
		}
		
		//query for the rate card line items
		List<Bid_Line_Item__c> items = [SELECT id, Quantity__c FROM Bid_Line_Item__c WHERE Bid__c =:card.id];
		
		//assertions
		System.assertEquals(100, items[0].Quantity__c);
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
	    	if(f != 'geolocation__c'){
		       // DescribeFieldResult field = fieldMap.get(f).getDescribe();
		     	fieldList.add(f);
	    	}
	    }
	    
	    //return the list of fields
	    return fieldList;
	  }
}