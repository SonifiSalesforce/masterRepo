@isTest
public class CustomListButtonAppQuoteTest {

    static testMethod void testApplyQuoteToOpp() 
    {
        Account acct = CreateTestRecords.DefaultHospitalityAccount();
        Opportunity oppty = CreateTestRecords.DefaultHospitalityOpportunity(acct.id);
        Quote q1 = CreateTestRecords.DefaultHospitalityQuote(oppty.id);
        Quote q2 = CreateTestRecords.DefaultHospitalityQuote(oppty.id);
        List<Quote> qlist = New List<Quote>();
        qlist.add(q1);
        qlist.add(q2);
        
        PageReference pageRef = Page.CustomListButtonApplyQuote;
        Test.setCurrentPage(pageRef);
      
        //jjackson when testing a page with a standard controller, the controller must be instantiated this way
      	CustomListButtonAppQuoteExt controller = new CustomListButtonAppQuoteExt(new ApexPages.StandardController(oppty));
      	controller.opptyid = oppty.id;
	    controller.opp = oppty;
	    controller.lstquotes=qlist;
	    controller.lstcheckedquotes=controller.getCheckedQuote();
	    controller.lstselected.add(controller.lstcheckedquotes[0]);
	    controller.ApplyQuoteToOpp();
	    controller.NewQuote();
        
        
    }
    
    
}