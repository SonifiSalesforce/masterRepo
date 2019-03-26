public with sharing class CustomButtonAssetsExtension {
	
	public Contract con {get;set;}
    Private ApexPages.StandardController controller;
    public List<SBQQ__Subscription__c> lstsubs {get;set;}
    public string returnmessage;
    public static boolean islightning = false;
        
    public static List<SBQQ__Subscription__c> getsublist(Id conid)
    {
    	List<SBQQ__Subscription__c> lstgetsubs = New List<SBQQ__Subscription__c>();
    	lstgetsubs = [Select Id, name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, sbqq__contract__r.recordtype.name,
                    product_inventory__c, sbqq__product__r.family, sbqq__product__c, sbqq__product__r.name, marina_resource_ratio__c,
					sbqq__quantity__c, sbqq__regularprice__c, status__c, contract_type__c, product_parent_id__c, fee_schedule__c, platform__c,
					sbqq__account__c, sbqq__account__r.name, sbqq__product__r.productcode, parent__c, parent__r.sbqq__product__r.productcode,
					sbqq__startdate__c, sbqq__enddate__c, parent__r.sbqq__product__r.name, parent__r.product_inventory__c
					from SBQQ__Subscription__c where SBQQ__Contract__c = :conid ];
					
		return lstgetsubs;
    }
    
    
    public CustomButtonAssetsExtension(ApexPages.StandardController controller)
    {
    	
    	
    	this.controller = controller;
		this.con = (Contract)controller.getRecord();
		
    	if(UserInfo.getUIThemeDisplayed() == 'Theme4d')
    	{  islightning = true;  }
    	
    	system.debug('theme displayed is ' +UserInfo.getUIThemeDisplayed());
		
		lstsubs = getsublist(this.con.id);
		returnmessage=checkparenting(lstsubs);
		
		if(returnmessage != null)
		{ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, returnmessage, '')); 

		}
		

	}//end standard controller
	
	public static string checkparenting(List<SBQQ__Subscription__c> sublist)
	{
		String message;
		Set<Id> setsubid = New Set<Id>();
		
		for(SBQQ__Subscription__c s :sublist)
		{
			if(!s.name__c.contains('Product Parent') && s.parent__c == null)
			{ setsubid.add(s.id);  
			  //system.debug(s.name__c +' was added to setsubid.');
			}
			
		}
		
		if(!setsubid.isEmpty())
		{  message = 'Before finalizing you must click Create Parenting Hierarchy. '; }
		
		return message;
	} 

	public PageReference CreateUpdateAssets()
    { 
      Contract thiscon = New Contract();	
      String returnstring = '';
      Map<Id, SBQQ__Subscription__c> mpnewpi = New Map<Id,SBQQ__Subscription__c>();
	  Map<Id,SBQQ__Subscription__c> mpupdatepi = New Map<Id,SBQQ__Subscription__c>();
	  Map<Id,SBQQ__Subscription__c> mpamendment = New Map<Id,SBQQ__Subscription__c>();
    	
	  if(returnmessage == null)
	  {
		thiscon = [ Select id, Contract_Status__c, accountid, contract_type__c, sbqq__renewalterm__c, recordtypeid, contractnumber,
		                     renewal_cycle__c, company_code__c, contractterm, auto_renew__c, extended_warranty_start_date__c from Contract
		                     where Id = :this.con.id LIMIT 1 ];
		                     
		system.debug('thiscon record type id is ' +thiscon.recordtypeid);
		                     
		/*List<SBQQ__Subscription__c>lstsubs = [Select Id, Name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, sbqq__contract__r.recordtype.name,
                    product_inventory__c, sbqq__product__r.family, sbqq__product__c, sbqq__product__r.name, marina_resource_ratio__c,
					sbqq__quantity__c, sbqq__regularprice__c, status__c, contract_type__c, product_parent_id__c, fee_schedule__c, platform__c,
					sbqq__account__c, sbqq__account__r.name, sbqq__product__r.productcode, parent__c, parent__r.sbqq__product__r.productcode,
					sbqq__startdate__c, sbqq__enddate__c, parent__r.sbqq__product__r.name, parent__r.product_inventory__c
					from SBQQ__Subscription__c where SBQQ__Contract__c = :this.con.id ];
					//And (sbqq__product__r.family != 'Entitlement' AND sbqq__product__r.family != 'Warranty') ]; */
					
	   String conrecname = Utilities.RecordTypeIdtoName('Contract', thiscon.recordtypeid);
	   Date extwarrdate = thiscon.extended_warranty_start_date__c;
		
		Boolean isExtended = false;		
	    if(conrecname == 'Contract Amendment')
	    {
	    	for(SBQQ__Subscription__c s :lstsubs)
	    	{
	    		if(s.sbqq__product__r.name.contains('Extended Warranty'))
	    		{  isExtended = true;  }
	    	}
	    }
	    
	    if(isExtended && extwarrdate == null)
	    {  throw new Exceptions.UnsupportedOperationException('Extended Warranty contract must have an Extended Warranty Start Date.'); }
	
	                  



		if(isExtended)
		{
			for(SBQQ__Subscription__c sub: lstsubs)
			{
				if(!sub.sbqq__product__r.name.contains('Product Parent') && sub.product_parent_id__c == null)
				{ throw new Exceptions.UnsupportedOperationException('Extended Warranty line items must fall under a Product Parent line.'); }
				else
				{ returnstring += FinalizeAssetsContractLogic.CreateExtendedWarrantyServiceContract(lstsubs, thiscon); }
			}
		}
		else
		{
			String checkstring;
			
			for(SBQQ__Subscription__c s :lstsubs)
			{
				if(s.name__c.contains('Product Parent') && s.equipment_ownership__c == null)
				{  checkstring += s.name__c +' requires an equipment ownership value.' +'\n'; }
				
				if(s.name__c.contains('Product Parent') && s.project_type__c == null)
				{  checkstring += s.name__c +' requires a project type values.' +'\n'; }
				
			}//end for lstsubs
			
			if(checkstring != null )
			{   
				throw new Exceptions.UnsupportedOperationException(checkstring);   }
			else
			{
				for(SBQQ__subscription__c subs : lstsubs)
				{
					if(subs.product_inventory__c == null && conrecname != 'Contract Amendment' && subs.sbqq__product__r.family != 'Entitlement'
				   	&& subs.sbqq__product__r.family != 'Warranty')
					{   
				   		mpnewpi.put(subs.id, subs); 
					}
			
					if(subs.product_inventory__c != null && conrecname != 'Contract Amendment' && subs.sbqq__product__r.family != 'Entitlement'
				   	&& subs.sbqq__product__r.family != 'Warranty')
					{  
				   		mpupdatepi.put(subs.id, subs); 
					}
				
					if(conrecname == 'Contract Amendment' && subs.sbqq__product__r.family != 'Entitlement' &&
				   	subs.sbqq__product__r.family != 'Warranty')
					{   
						mpamendment.put(subs.id, subs); 
					}
		
				}//end for sublist
			}//end else
			
			system.debug('mpnewpi size is ' +mpnewpi.size());
			system.debug('mpupdatepi size is ' +mpupdatepi.size());
			system.debug('mpamendment size is ' +mpamendment.size());
			
		}//end else	

      	
		
		if(mpnewpi.size() > 0)
		{  returnstring += FinalizeAssetsContractLogic.CreateNewAssets(mpnewpi,thiscon);  }
		
		if(mpupdatepi.size() > 0)
		{  returnstring += FinalizeAssetsContractLogic.UpdateExistingAssets(mpupdatepi,thiscon); }
		
		if(mpamendment.size() > 0)
		{ returnstring += FinalizeAssetsContractLogic.UpdateExistingAssets(mpamendment, thiscon); }
			
			
		if(returnstring.contains('Error'))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, returnstring, ''));
			return null;
		}
		

		
			
		
		
	  }//end if returnmessage == null
	  
	  	//reload the contract page to reload the subscription item hierarchy vf page
		//this will force the subscription item hierarchy extension code to see that the line items are linked to
		//product inventory records
		Id contractid = thiscon.id;
		String hostVal = ApexPages.currentPage().getHeaders().get('Host');

		//jjackson this code works whether in lightning or classic.
		String thisurl;
		if(islightning == false)
		{ thisurl = 'https://' +hostVal+'/'+contractid; }
		else
		{ thisurl = 'https://'+hostVal+'/lightning/r/Contract/' +contractid+'/view';  }
		system.debug('thisurl = ' +thisurl);
		PageReference pr = new PageReference(thisurl);
		pr.setRedirect(false); 
		return pr; 
		//return null;
   } //end method CreateUpdateAsset
	
}