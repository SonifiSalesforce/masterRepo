public with sharing class CustomButtonApplyQuoteVF {

    public Quote qrec {get;set;}
    public Id oppid;
    
    public CustomButtonApplyQuoteVF(ApexPages.StandardController stdController)
    {
      qrec = (Quote)stdController.getRecord();
        Quote getquote = [Select Id, opportunityid from Quote where id = :qrec.id ];
       oppid = getquote.OpportunityId;
    }
    
    public pagereference applythequote()
    {
        Pagereference pageref = New Pagereference(url.getSalesforceBaseUrl().toexternalform()+'/'+qrec.id);
        String retresult;
        
        if(oppid == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An opportunity must be related to this quote </b>',
                                                                               'before clicking the Apply Quote button.'));
            
        }
        else
        {    
          retresult = GlobalWebServices.applyQuote(qrec.id);
          pageref =  New pagereference(url.getSalesforceBaseUrl().toexternalform()+'/'+oppid);
        }
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, retresult));
        return pageref;
    }
    

}