@isTest
public class CustomButtonApplyQuoteTest {
	
	public static testmethod void testApplyTheQuote()
	{
		Account acc = CreateTestRecords.DefaultHospitalityAccount();
		Opportunity oppty = CreateTestRecords.DefaultHospitalityOpportunity(acc.id);
		Quote q = CreateTestRecords.DefaultHospitalityQuote(oppty.id);
		
		PageReference pageRef = Page.ApplyQuoteButton;
        Test.setCurrentPage(pageRef);
      
        //jjackson when testing a page with a standard controller, the controller must be instantiated this way
      	CustomButtonApplyQuoteVF controller = new CustomButtonApplyQuoteVF(new ApexPages.StandardController(q));
      	controller.qrec = q;
      	controller.oppid = oppty.id;
		controller.applythequote();
		
		
		
		
	}
    
}