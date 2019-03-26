public with sharing class FieldWorkOrderDisplayDigestExtension {
	
	Public WorkOrder fworec {get;set;}
	Case relatedcase;
	Id cid;
	Id woid;
	public List<Field_Service_Digest__c> lstfsd {get;set;}
	
	
	public FieldWorkOrderDisplayDigestExtension(ApexPages.StandardController controller) {
    
       		 this.fworec = (WorkOrder)controller.getRecord();
       		 WorkOrder fwo = [Select Id, CaseId from WorkOrder where Id = :fworec.id LIMIT 1 ];
       		 system.debug('fworec is ' +fworec);
       		 cid = fwo.CaseId;
       		 woid = fwo.Id;
       		 system.debug('cid is ' +cid);
       		 lstfsd = GetFSD();
       		 
	}
    
    public List<Field_Service_Digest__c> GetFSD()
    {
    	lstfsd = New List<Field_Service_Digest__c>();
    	
    	lstfsd = [ Select Id, case__c, checkin_time__c, checkout_time__c, time_spent_on_site_mins__c,
    	              time_spent_on_site_hrs__c from
    	              field_service_digest__c where case__c = :cid ];
    	           
    	return lstfsd;
    }
    
    public PageReference SaveChange()
    {
    	List<Field_Service_Digest__c> lstdigest = New List<Field_Service_Digest__c>();
    	
    	if(lstfsd != null)
    	{
    		lstdigest = lstfsd;
    		update lstdigest;
    	}
    	
    	PageReference pr = New PageReference('/' +woid);
    	pr.setRedirect(true);
    	return pr;
    }
}