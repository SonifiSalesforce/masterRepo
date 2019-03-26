@isTest
public with sharing class CustomQuoteLogicTest {

	@isTest (SeeAllData=true) // MUST set SeeAllData to create oppty products from Pricebook2 
	static void testCreateQuote() {
		
		// Create products
		Integer productsToCreate = 3;
		List<Product2> productList = DataGenerator.createProducts(productsToCreate, true);
		System.assertNotEquals(null, productList);
		System.assertNotEquals(true, productList.isEmpty());
		System.assertEquals(productsToCreate, productList.size());
		
		// Create pricebook entries for products
		List<PricebookEntry> pricebookEntryList = DataGenerator.createPricebookEntries(productList, true);
		System.assertNotEquals(null, pricebookEntryList);
		System.assertNotEquals(true, pricebookEntryList.isEmpty());
		System.assertEquals(productsToCreate, pricebookEntryList.size());
		
		// Create account
		Account acct = DataGenerator.createAccounts(1, true)[0];
		System.assertNotEquals(null, acct);
		
		// Create oppty
		Opportunity oppty = DataGenerator.createOpptys(acct, 1, false)[0];
		System.assertNotEquals(null, oppty);
		oppty.Pricebook2Id = pricebookEntryList[0].Pricebook2Id;
		insert oppty;
		
		// Create quote
		String quoteJson = '{' 
				+ '"' + CustomQuoteLogic.FIELDNAME_QUOTE + '" : {'
				+ '"OpportunityId" : "' + oppty.Id + '", '
				+ '"' + CustomQuoteLogic.FIELDNAME_PROGRAMMING + '" : [{'
				+ '"' + CustomQuoteLogic.FIELDNAME_ID + '" : "' + productList[0].ProductCode + '", '
				+ '"' + CustomQuoteLogic.FIELDNAME_QTY + '" : ' + 100 + ', '
				+ '"' + CustomQuoteLogic.FIELDNAME_VALUE + '" : ' + 5 + ', '
				+ '"' + CustomQuoteLogic.FIELDNAME_PROGRAMMING_ITEMS + '" : ';
		
		List<String> quoteItems = new List<String>();
		for (Integer i = 1; i < productsToCreate; i++) {
			quoteItems.add('{'
					+ '"' + CustomQuoteLogic.FIELDNAME_ID + '" : "' + productList[i].ProductCode + '", '
					+ '"' + CustomQuoteLogic.FIELDNAME_QTY + '" : ' + i + ', '
					+ '"' + CustomQuoteLogic.FIELDNAME_VALUE + '" : ' + (i * 1.25)
			+ '}');
		}
		quoteJson += '[' + String.join(quoteItems, ',') + ']}]}}';
		System.debug(quoteJson);
		
		CustomQuoteLogic quoteLogic = new CustomQuoteLogic();
		List<Quote> quoteList = quoteLogic.createQuotes(quoteJson);
		System.assertNotEquals(null, quoteList);
		System.assertNotEquals(true, quoteList.isEmpty());
		System.assertEquals(1, quoteList.size());
		
		String result = CustomQuoteLogic.applyQuoteToOpportunity(quoteList[0].Id, oppty.Id);
		System.assertEquals('Quote successfully applied to opportunity.', result);
	}
}