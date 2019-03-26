public with sharing class BidExtension {
	public Bid__c bidCard {get;set;}
	public Map<String, CustomBid> productId2LineItem {get;set;}
	private String pricebookId {get;set;}
	private Site_Survey__c survey {get;set;}
	public String itemId {get;set;}
	public Map<String, Decimal> totalPriceMap {get;set;}
	public Map<String, Decimal> totalMarginPriceMap {get;set;}
	private Id ownerId {get;set;}
	public Map<String, List<String>> category2ProductMap {get;set;}
	public Map<String, Bid_Line_Item__c> otherbidCards{get;set;}
	public Decimal grandTotal {get;private set;}
	public String grandTotalString {get;private set;}
	public String grandTotalStringWMargin {get;private set;}
	private Map<String, Decimal> subCat2MarginalValue {get;set;}
	public Boolean viewMargin {get;private set;}
	
	public class CustomBid implements Comparable{
		public Bid_Line_Item__c bid {get;set;}
		public Decimal sortOrder {get;set;}
		
		public CustomBid(){
			sortOrder = 99999;
		}

		public integer compareTo(Object compareTo){
			CustomBid custom = (CustomBid)compareTo;
			if(sortOrder == custom.sortOrder) return 0;
			if(sortOrder > custom.sortOrder) return 1;
			return -1;
		}
	}
	
	public BidExtension(ApexPages.StandardController stdController){
		//initialize var
		this.productId2LineItem = new Map<String, CustomBid>();
		this.itemId = '' ;
		this.survey	= new Site_Survey__c();
		this.totalPriceMap = new Map<String, Decimal>();
		this.totalMarginPriceMap = new Map<String, Decimal>();
		this.category2ProductMap = new Map<String, List<String>>();//{'Other' => new List<String>()};
		this.otherbidCards = new Map<String, Bid_Line_Item__c>();
		this.bidCard = (Bid__c)stdController.getRecord();
		this.grandTotal = 0.0;
		this.grandTotal.setScale(2);
		this.subCat2MarginalValue = new Map<String, Decimal>();
		this.viewMargin = false;
		
		User u1 = [SELECT id, ProfileId, Profile.Name, Assigned_Pricebook__c, CurrencyIsoCode, Name, LastName, DefaultCurrencyIsoCode, CommunityNickname FROM User WHERE id =:UserInfo.getUserId() limit 1];
		
		//get the id of the site survey if passed through parameters
    	if(this.bidCard.Id != null) {
    		loadData();
    	} else {
    		if(ApexPages.currentPage().getParameters().containsKey('SiteId')){
    			this.bidCard.Site_Survey__c = ApexPages.currentPage().getParameters().get('SiteId');
    		}
    		
    		System.debug('User found is ' + u1);
    		this.pricebookId = u1.Assigned_Pricebook__c;
    		this.bidCard.CurrencyIsoCode = u1.DefaultCurrencyIsoCode;
    		
    		this.survey = [SELECT id, Approval_Status__c FROM Site_Survey__c WHERE id=:this.bidCard.Site_Survey__c limit 1];
    		this.bidCard.Approval_Status__c = this.survey.Approval_Status__c;
    		
    		//load rate card line items attached to the rate card
			loadPriceBookEntry();
    	}
    	
    	//make sure at least one other is in the list
    	if(this.otherbidCards.size() == 0){
    		Bid_Line_Item__c tempItem = (Bid_Line_Item__c)DataGenerator.createSObjectWithDefaultValues('Bid_Line_Item__c');
    		tempItem.Margin__c = 65;
    		//if rate card exists then copy over the currency iso code
			if(this.bidCard.id != null){
				tempItem.CurrencyIsoCode = this.bidCard.CurrencyIsoCode;
			}
    		
    		//set values
    		tempItem.Default_Price__c = 0;
    		tempItem.Price__c = 0;
    		
    		//map the item correctly
    		this.otherbidCards.put('0', tempItem);
    		this.totalPriceMap.put('0', 0);
    		this.totalMarginPriceMap.put('0', 0);
    	}
    	System.debug('Other rate cards are ' + this.otherbidCards);
    	System.debug('Other rate cards cateogry are ' + this.category2ProductMap);
    	System.debug('Total price map ' + this.totalPriceMap);
    	System.debug('Product id 2 line item map is ' + this.productId2LineItem.keyset());
    	
    	//loop through bids and sort the bids
    	for(String bidCategory : this.category2ProductMap.keySet()){
    		List<String> productids = this.category2ProductMap.get(bidCategory); // this has all the ids for the bids that are attached to that category
    		
    		//make a list of customBids using the product ids
    		List<CustomBid> customBids = new List<CustomBid>();
    		for(String prodId : productIds){
    			customBids.add(this.productId2LineItem.get(prodId));
    		}
    		
    		//sort the list
    		customBids.sort();
    		
    		//remake the list with the new ids in correct spot
    		productIds = new List<String>();
    		for(CustomBid custom : customBids){
    			productIds.add(custom.bid.Product__c);
    		}
    		
    		//put the list of product ids back into the map
    		this.category2ProductMap.put(bidCategory, productIds);
    	}
    	
    	//load the sub category and marginal default values
	    List<Product_Marginal_Value_Bid__c> marginalValues = Product_Marginal_Value_Bid__c.getAll().Values();
	    //map the product marginal values
	    for(Product_Marginal_Value_Bid__c pmv: marginalValues){
	    	this.subCat2MarginalValue.put(pmv.Name, pmv.Margin__c);
	    }     
	    
	    //load the profile with installation permissions (be able to view margin values)
	    for(Installation_Profiles__c p : Installation_Profiles__c.getAll().Values()){
	    	//see if the profile can view margin and margin total
	    	if(u1.Profile.Name == p.Name){
	    		this.viewMargin = true;
	    	}
	    }  
    	
    	//grand total sum
    	sumTotals();
	}
	
	//grand total for all the prices on rate card
	public void sumTotals() {
		System.debug('Entering sumTotals...');
		//set the grand total to 0
		grandTotal = 0;
		
		//for throug the map and add up all the prices
		for(Decimal d : this.totalPriceMap.Values()){
			grandTotal += d;
		}
		
		//set string grand total
		this.grandTotalString = this.grandTotal.format();
		
		//get the total w margin values
		sumTotalsWMargin();
	}
	
	//grand total for all the prices on rate card
	public void sumTotalsWMargin() {
		System.debug('Entering sumTotals...');
		//set the grand total to 0
		grandTotal = 0;
		
		//for throug the map and add up all the prices
		for(Decimal d : this.totalMarginPriceMap.Values()){
			grandTotal += d;
		}
		
		//set string grand total
		this.grandTotalStringWMargin = this.grandTotal.format();
	}
	
	//add row to other
	public void addRow(){
		//create the item about to go into the map
		Bid_Line_Item__c tempItem = (Bid_Line_Item__c)DataGenerator.createSObjectWithDefaultValues('Bid_Line_Item__c');
		tempItem.Margin__c = 0;
		
		//if rate card exists then copy over the currency iso code
		if(this.bidCard.id != null){
			tempItem.CurrencyIsoCode = this.bidCard.CurrencyIsoCode;
		}
		
		//get the size of the already other list in order to give this rate card an original id
    	String bidCardId = String.valueOf(this.otherbidCards.KeySet().size());
    	
    	//map the rate card line item correctly
		this.otherbidCards.put(bidCardId, tempItem);
		this.totalPriceMap.put(bidCardId, 0);
		this.totalMarginPriceMap.put(bidCardId, 0);
	}
	
	//update total price
	public void updateTotalPrice() {
		System.debug('Product id is ' + this.itemId);
		
		Bid_Line_Item__c item;
		if(this.productId2LineItem.containsKey(this.itemId)){
			CustomBid custom = this.productId2LineItem.get(this.itemId);
			item = custom.bid;
		} else {
			 item = this.otherbidCards.get(itemId);
		}
		
		//update the total price
		if(item.Quantity__c == null ){
			item.Quantity__c = 0;
		}
		this.totalPriceMap.put(this.itemId, item.Price__c * item.Quantity__c);
		
		if(item.Margin__c != null){
			this.totalMarginPriceMap.put(this.itemId, item.Price__c * item.Quantity__c + (item.Price__c * item.Quantity__c *(item.Margin__c/100)).setScale(2));
		}
		sumTotals();
	}
	
	/***********************************************************************************************************
	***************************************** LOAD FUNCTIONS ****************************************************
	***********************************************************************************************************/
	
	//load everything given that the rate card was already made
	public void loadData(){
		//load rate card and user data
		loadUserData();
		
		//load rate card line items attached to the rate card
		loadbidCardLineItems();
		
		//load the other pricebook entries
		loadPriceBookEntry();
	}
	
	public void loadbidCardLineItems(){
		String fieldQuery;
		
		//get fields on Product
		fieldQuery = String.join(getSObjectFields(Bid_Line_Item__c.getSObjectType()), ',');
		
		//gte rate card line items attached to the rate card
		List<Bid_Line_Item__c> lineItems = new List<Bid_Line_Item__c>();
		lineItems = Database.query('SELECT ' + fieldQuery + ', Bid__r.OwnerId, Product__r.Name, Product__r.Labor_Category__c, Product__r.Sort_Order__c FROM Bid_Line_Item__c WHERE Bid__c = \'' + this.bidCard.id + '\'');
		
		//create the map, productid to rate card lineitem
		for(Bid_Line_Item__c item : lineItems){
			if(item.Margin__c == null){
				if(this.subCat2MarginalValue.containsKey(item.Product__r.Labor_Category__c)){
					item.Margin__c = this.subCat2MarginalValue.get(item.Product__r.Labor_Category__c);
				} else {
					item.Margin__c = 0;
				}
			}
			if(item.Product__c != null){
				CustomBid custom = new CustomBid();
				custom.bid = item;
				if(item.Product__r.Sort_Order__c != null){
					custom.sortOrder = item.Product__r.Sort_Order__c;
				} else {
					custom.sortOrder = 99999;
				}
				
				//product is present so map it
				this.productId2LineItem.put(item.Product__c, custom);
				//map the total price to the product
				this.totalPriceMap.put(item.Product__c, item.Price__c * item.Quantity__c);
				this.totalMarginPriceMap.put(item.Product__c, (item.Price__c * item.Quantity__c * (1+item.Margin__c/100)).setScale(2));
				
				//map the rate card to the associated category
				if(this.category2ProductMap.containsKey(item.Product__r.Labor_Category__c)){
					this.category2ProductMap.get(item.Product__r.Labor_Category__c).add(item.Product__c);
				} else {
					this.category2ProductMap.put(item.Product__r.Labor_Category__c,new List<Id>{item.Product__c});
				}
			} else {
				//get the number for other to be the id for the rate card
				String bidCardId = String.valueOf(this.otherbidCards.KeySet().size());
				
				//map the products accordingly
				this.otherbidCards.put(bidCardId, item);
				this.totalPriceMap.put(bidCardId, item.Total_Price__c);
				this.totalMarginPriceMap.put(bidCardId, (item.Total_Price__c * (1+item.Margin__c/100)).setScale(2));
			}
		}
		System.debug('Map of found rate card line items ' + this.productId2LineItem);
	}
	
	//load pricebook2s
	public void loadPriceBookEntry(){
		System.debug('bid item is ' + this.bidCard);
		String fieldQuery;
		
		//get fields on Product
		fieldQuery = String.join(getSObjectFields(PricebookEntry.getSObjectType()), ',');
		String recordTypeId = (String)Utilities.RecordTypeNameToId('Product2', 'Labor Task');
		
		//set the where clause
		String whereClause = '';
		if(this.pricebookId != null){
			whereClause = 'Pricebook2Id = \'' + this.pricebookId + '\' AND Product2.RecordTypeId = \'' +  recordTypeId + '\''; //pricebook exists
		}else { // get the standard price books
			whereClause = 'Pricebook2.Name = \'Standard Price Book\' AND Product2.RecordTypeId = \'' +  recordTypeId + '\' '; //pricebook is null so use standard price *** AND CurrencyIsoCode = \'' + this.bidCard.CurrencyIsoCode + '\'
		}
		
		//query the priceook entries
		List<PricebookEntry> items = new List<PricebookEntry>();
		items = Database.query('SELECT ' + fieldQuery + ', Product2.Description, Product2.ProductCode, Product2.Sort_Order__c, Product2.id, Product2.Name, Product2.Labor_Category__c, Product2.Units__c FROM PricebookEntry WHERE IsActive = true AND ' + whereClause);
		System.debug('Pricebookentryies found ' + items);
		
		//create the map and put data into the appropriate place in rate card line item
		for(PricebookEntry item : items){
			if(!this.productId2LineItem.containsKey(item.Product2.Id)){
				//create the rate card line item
				Bid_Line_Item__c tempRate = new Bid_Line_Item__c(CurrencyIsoCode = item.CurrencyIsoCode, Product__c = item.Product2Id, Task_Number__c = item.Product2.ProductCode, Description__c = item.Product2.Description, Default_Price__c = item.UnitPrice, Price__c = item.UnitPrice, Unit__c = item.Product2.Units__c);
				
				if(this.subCat2MarginalValue.containsKey(item.Product2.Labor_Category__c)){
					tempRate.Margin__c = this.subCat2MarginalValue.get(item.Product2.Labor_Category__c);
				} else {
					tempRate.Margin__c = 0;
				}
			
				// if iso code is usd then put it into the map
				//if('USD' == tempRate.CurrencyIsoCode){
				if(this.bidCard.CurrencyIsoCode == tempRate.CurrencyIsoCode){
					CustomBid custom = new CustomBid();
					custom.bid = tempRate;
					if(tempRate.Product__r.Sort_Order__c != null){
						custom.sortOrder = tempRate.Product__r.Sort_Order__c;
					} else {
						custom.sortOrder = 99999;
					}
					//add product to map because it does not already exist in the map
					this.productId2LineItem.put(item.Product2.Id,  custom);
					//map 0 to the product because quantity equals 0
					this.totalPriceMap.put(item.Product2.Id, 0);
					this.totalMarginPriceMap.put(item.Product2.Id, 0);
					
					//map the product to the category
					if(this.category2ProductMap.containsKey(item.Product2.Labor_Category__c)){
						this.category2ProductMap.get(item.Product2.Labor_Category__c).add(item.Product2.id);
					} else {
						this.category2ProductMap.put(item.Product2.Labor_Category__c,new List<Id>{item.Product2.id});
					}
				}
			} 
		}
		System.debug('Pricebook map ' + this.productId2LineItem);
		System.debug('Category map is ' + this.category2ProductMap);
		
		//convert te prices to correct currencyisocode
		if(this.bidCard.CurrencyIsoCode != 'USD'){
			//convertIsoCodes();
		}
	}
	
	//convert prices to correct prices based on iso code
	/*public void convertIsoCodes(){
		//initialize var for rate
		Double rate = -1;
		
		//query for the date conversion date
		List<DatedConversionRate> convertList = [SELECT ISOCode, ConversionRate,StartDate, NextStartDate FROM DatedConversionRate WHERE ISOCode = :this.bidCard.CurrencyIsoCode];
		
		//loop through convertlist and find the correct conversion rate
		for(DatedConversionRate con : convertList){
			if(Date.Today() < con.NextStartDate && Date.Today() >= con.StartDate){
				rate = con.ConversionRate;
				break;
			}
		}
		System.assertNotEquals(rate, -1, 'A Rate was not found for the ' + Date.Today() + ' & ' + this.bidCard.CurrencyIsoCode);
		System.debug('The rate found is ' + rate);
		
		//loop through the bid cards
		for(String prodId : this.productId2LineItem.KeySet()){
			if(this.productId2LineItem.get(prodId).CurrencyIsoCode == 'USD'){
				//set the fields with the rate 
				this.productId2LineItem.get(prodId).Default_Price__c = this.productId2LineItem.get(prodId).Default_Price__c * rate;
				this.productId2LineItem.get(prodId).Price__c = this.productId2LineItem.get(prodId).Price__c * rate;
				//put the iso code
				this.productId2LineItem.get(prodId).CurrencyIsoCode = this.bidCard.CurrencyIsoCode;
			}
		}
		System.debug('Product Id 2 Line item is ' + this.productId2LineItem);
	}*/
	
	//set the pricebookId
	public void loadUserData(){
		String fieldQuery;
		
		//get fields on Product
		fieldQuery = String.join(getSObjectFields(Bid__c.getSObjectType()), ',');
		
		//query for the rate card
		List<Bid__c> cards = Database.query('SELECT ' + fieldQuery + ' FROM Bid__c WHERE Id = \'' + this.bidCard.id + '\' limit 1');
		this.bidCard = cards[0];
		//query for the owner of the rate card
		List<User> users = [SELECT id, Assigned_Pricebook__c FROM User WHERE id =:cards[0].OwnerId limit 1];
		
		//set the pricebook id
		this.pricebookId = users[0].Assigned_Pricebook__c;
	}
	
	/***********************************************************************************************************
	***************************************** SAVE FUNCTIONS ***************************************************
	***********************************************************************************************************/
	
	public PageReference saveAll(){
		System.debug('Entering save method...');
		List<Bid_Line_Item__c> bidsDelete = new List<Bid_Line_Item__c>();
		//update bid card
		upsert bidCard;
		
		if(bidCard.Approval_Status__c != 'Approved'){
			List<Bid_Line_Item__c> upsertList = new List<Bid_Line_Item__c>();
			
			//save all bid cards that have a related product
			for(CustomBid custom : productId2LineItem.Values()){
				Bid_Line_Item__c item = custom.bid;
				if((item.Quantity__c != null && item.Quantity__c > 0)){
					//if bid card exists then put rate card id
					if(item.Bid__c == null){
						item.Bid__c = bidCard.id;
					}
					
					//set or update the conversion date
					if(item.Conversion_Date__c == null){
						item.Conversion_Date__c = Date.Today();
					}
					
					//add the item to upsert list
					upsertList.add(item);
				} else if(item.Quantity__c == 0 && item.CreatedDate != null) {
					bidsDelete.add(item);
				}
			}
			
			//save the other bid cards
			for(Bid_Line_Item__c item : this.otherbidCards.Values()){
				if((item.Quantity__c != null && item.Quantity__c > 0) ){
					//if bid card exists then put rate card id
					if(item.Bid__c == null){
						item.Bid__c = bidCard.id;
					}
					// make sure date field is filled out
					if(item.Conversion_Date__c == null){
						item.Conversion_Date__c = Date.Today();
					}
					
					//add the item to the upsert list
					upsertList.add(item);
				} else if(item.Quantity__c == 0 && item.CreatedDate != null) {
					bidsDelete.add(item);
				}
			}
			
			//upsert the bid cards if not empty
			if(upsertList.size() > 0){
				try{
					upsert upsertList;
				} catch(Exception ex){
					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,ex.getMessage()));
					return null;
				}
			}
			
			if(bidsDelete.size() > 0){
				try{
					delete bidsDelete;
				} catch(Exception ex){
					ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,ex.getMessage()));
					return null;
				}
			}
		}
		
		//redirect to the bid card page
		PageReference ref = new PageReference('/' + this.bidCard.id);
    	ref.setRedirect(true);
    	System.debug('Page reference Url is ' + ref);
		return ref;
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