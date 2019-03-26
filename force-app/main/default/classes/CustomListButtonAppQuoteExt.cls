public with sharing class CustomListButtonAppQuoteExt {
	
	public Id opptyid;
	public Opportunity opp {get; set;}
	public List<Quote> lstquotes {get;set;}
	public List<cQuote> lstcheckedquotes {get;set;}
	public List<cQuote> lstselected = New List<cQuote>();
	public Id quoteid;
	
	public CustomListButtonAppQuoteExt(ApexPages.StandardController stdController)
    {
    	opp = (Opportunity)stdController.getRecord();
    	opptyid = opp.id;
    	lstcheckedquotes=getCheckedQuote();
    	system.debug('lstquotes size is ' +lstquotes.size());
    	
    }
    
    
    public class cQuote //jjackson--wrapper class for creating list of selected quotes from the visual force page 
	{

		public Quote qte {get;set;}
		public Boolean selected {get;set;}

        
		public cQuote(Quote q)
		{
			qte = q;
   			selected = false;
            qte.id = q.id;
            qte.name = q.name;
            qte.discount__c=q.discount__c;
            qte.expirationdate = q.expirationdate;
  
	
		}
   } //end class cAccount
   
   public List<cQuote> getCheckedQuote()
	{
		lstquotes= [Select Id, name, accountid, quotenumber, expirationdate, discount__c, totalprice, createddate,
		           createdbyid, opportunityid from Quote where opportunityid = :opptyid Order By createddate DESC ];
		           
			lstcheckedquotes = New List<cQuote>();
			for(Quote quo: lstquotes)
			{
				lstcheckedquotes.add(new cQuote(quo));
			}
		
		
		return lstcheckedquotes;
	}
	
	public PageReference ApplyQuoteToOpp()
	{
		String msg1 = 'You must select one quote before clicking the button.';
		String msg2 = 'You can choose only one quote when you click the button.';
		//List<cQuote> lstselected = New List<cQuote>();
		
		for(cQuote cq : lstcheckedquotes)
		{
			if(cq.selected == true)
			{
				lstselected.add(cq);
			}
		}
		
		if(lstselected.IsEmpty())
		{
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, msg1);
            ApexPages.addMessage(myMsg);
            return null;
		}
		
		if(lstselected.size() > 1)
		{
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, msg2);
            ApexPages.addMessage(myMsg);
            return null;
		}
		
		
		if(lstselected.size() == 1)
    	{
    		for(cQuote cquo : lstselected)
    		{
    			quoteid = cquo.qte.Id;
    		}
    	}
    	
    	if(quoteid != null)
    	{
    	   try
    	   {	CustomQuoteLogic.applyQuoteToOpportunity(quoteId, opptyId);  }
    	   catch(Exception ex)
    	   {
    	   		String errmsg = ex.getMessage();
    	   		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errmsg);
                ApexPages.addMessage(myMsg);
    	   }
    	   
    	   String success = 'Quote successfully applied to opportunity.';
    	   ApexPages.Message successmsg = new ApexPages.Message(ApexPages.Severity.INFO, success);
    	   ApexPages.addMessage(successmsg);
    	}
		
		PageReference pageref = new PageReference('/'+opptyId);
		return pageref;
	}
	
	public PageReference NewQuote()
	{
        //system.debug('inside pagereference newquote');
        //system.debug('opportunityid is ' +opp.id);
		Quote newquote = New Quote();
		Id qid;
		
		newquote.opportunityid=opp.id;
		newquote.name= 'newquote';
	    insert newquote;
	    
	    qid=newquote.id;
	    //system.debug('newquote id is ' +qid +' and name is ' +newquote.name);
	   
	   String baseurl = system.url.getSalesforceBaseUrl().toExternalForm();
	   String redirect = baseurl+'/'+qid;
	   //system.debug('baseurl is ' +baseurl );
	   //system.debug('redirect is ' +redirect);

		PageReference pr = new PageReference(redirect);
		pr.setRedirect(true);
		return pr;
		
	}

}