@isTest
private class CaseControllerTest {

    static testMethod void testCaseController() {
    	
    	//create these accounts calling methods in a different test class to avoid
    	//having to duplicate code
   		Account a = ThirdPartyFieldServiceTest.existingaccount();
   		Account tpa = ThirdPartyFieldServiceTest.partneraccount();

   		Account_Third_Party_Partner__c atpp = New Account_Third_Party_Partner__c(Related_Account__c = a.id,
   		                                 Third_Party_Partner_Account__c = tpa.id);
   		insert atpp;
   		
   		Id caserecid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
   		Case testcase = New Case(Subject='Test Case', Accountid=a.id, Status='Open', Priority='Low', Recordtypeid=caserecid,
   		                   Case_Product_Type__c = 'Interactive', Issue_Type__c = 'Hardware', Issue_Sub_Type__c='DCR/Catcher',
   		                   Issue_Details__c='Bad LNB DCR/Catcher', third_party_partner__c=atpp.id);
   		insert testcase;
   		
 
 		//SAMPLE CODE: unit test code for a standard controller with extension class
 
   		ApexPages.StandardController con = new ApexPages.StandardController(testcase);
   		CaseController testcon = New CaseController(con);
   		PageReference pageRef = Page.CustomButtonCreateFWO;
   		pageRef.getParameters().put('Id', String.valueOf(testcase.id));
   		Test.setCurrentPage(pageRef);
   		testcon.CreateThirdPartyFWO();
   		
   		List<WorkOrder> lstfwo = New List<WorkOrder>();
   		lstfwo = [ Select Id, recordtypeid from WorkOrder where caseid = :testcase.id ];
   		//system.debug('lstfwo size is ' +lstfwo.size());
   		system.assert(lstfwo.size() == 1);
    	
    	
        
        
    }
}