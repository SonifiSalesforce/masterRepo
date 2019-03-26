public class CaseController {
	
	Public Case c {get;set;}
	Public Case thiscase;
	Public Id caseid; 
	Public Id caserecid; 
	Public Id accid; 
	Public String subj;
	Public String pri;
	Public String redirectUrl {public get; private set;}
	Public Boolean shouldRedirect {public get; private set;}
	Private ApexPages.StandardController controller;
	
	
	public CaseController(ApexPages.StandardController controller){
		this.controller = controller;
		shouldRedirect=false;
		this.c = (Case)controller.getRecord();
		thiscase = [ Select recordtypeid, id, priority, accountid, subject from Case
		             where Id = :this.c.id LIMIT 1 ];
		caseid = thiscase.id;
		caserecid = thiscase.recordtypeid;
		accid = thiscase.accountid;
		pri = thiscase.priority;
		subj = thiscase.subject;
	}
	
	public pageReference CreateThirdPartyFWO()
	{	
		Id caserectypeid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
		Id fworectypeid = Utilities.RecordTypeNameToId('WorkOrder', 'Third Party FWO');
		DateTime thistime = system.now();
		WorkOrder fwo = new WorkOrder();
		
		if(caserecid == caserectypeid && caseid != null)
		{
			fwo.recordtypeid = fworectypeid;
			fwo.date__c = thistime;
			fwo.AccountId = accid;
			fwo.priority = pri;
			fwo.Subject = subj;
			fwo.status = 'New';
			fwo.caseid = caseid;
			
			insert fwo;
			
		  }
		  else
		  {
		  	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'ERROR: Incorrect case record type or no case id found.'));
		  }
		  

         shouldRedirect = true;
         //this statement gets you back to the case page
         redirectUrl = controller.view().getUrl();
         //this statement flips the view to the new field work order page;
         redirectUrl = '/'+fwo.id;
         return null;
          
   
	  }
				
}