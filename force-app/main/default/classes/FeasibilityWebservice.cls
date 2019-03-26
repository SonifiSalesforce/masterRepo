@RestResource(urlMapping='/Feasibility/*')
global with sharing class FeasibilityWebservice {
	
	@HttpPost
	global static String submitQuote() {
		
		String result;
		RestResponse response = RestContext.response;
		
		// Parse JSON-formatted quote data from request body 
		String quoteJson = RestContext.request.requestBody.toString();
		if (quoteJson == null || quoteJson == '') {
			result = 'Failed to submit quote. Details: No quote data provided.'; 
			Utilities.writeLog(
					result, 
					FeasibilityWebservice.class, 'submitQuote', LoggingLevel.ERROR);
			return result;
		}
		
		// Log quote data
		Utilities.writeLog(
				'Raw Quote Data: ' + quoteJson, 
				FeasibilityWebservice.class, 'submitQuote', LoggingLevel.INFO);
		
		// Process quote data
		try {
			CustomQuoteLogic quoteLogic = new CustomQuoteLogic();
			List<Quote> addedQuotes =  quoteLogic.createQuotes(quoteJson);
			if (addedQuotes != null && !addedQuotes.isEmpty()) {
				response.statusCode = 201;
				result = addedQuotes.size() + ' quote(s) added to opportunity.';
			} else {
				response.statusCode = 500;
				result = 'Failed to create quotes.';
			}
		} catch (Exception e) {
			response.statusCode = 500;
			result = 'Failed to create quotes. Details: ' + e.getMessage();
		}
		return result;
	}
	
	@HttpGet
	global static string getQuote() {
		return 'success';
	}
}