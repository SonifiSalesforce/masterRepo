public with sharing class CustomButtonParentingExtension {
	
Contract con {get;set;}
public static List<SBQQ__Subscription__c> lstsubs = New List<SBQQ__Subscription__c>();
public String returnmessage;
Private ApexPages.StandardController controller;

	public static List<SBQQ__Subscription__c> getsublist(Id conid)
	{
    	List<SBQQ__Subscription__c> lstgetsubs = New List<SBQQ__Subscription__c>();
    	lstgetsubs = [Select Id, name__c, project_type__c, equipment_ownership__c, sbqq__contract__c, sbqq__contract__r.recordtype.name,
                    product_inventory__c, sbqq__product__r.family, sbqq__product__c, sbqq__product__r.name, marina_resource_ratio__c,
					sbqq__quantity__c, sbqq__regularprice__c, status__c, contract_type__c, product_parent_id__c, fee_schedule__c, platform__c,
					sbqq__account__c, sbqq__account__r.name, sbqq__product__r.productcode, parent__c, parent__r.sbqq__product__r.productcode,
					sbqq__startdate__c, sbqq__enddate__c, parent__r.sbqq__product__r.name, parent__r.product_inventory__c,
					sbqq__quoteline__c, sbqq__quoteline__r.sbqq__requiredby__c
					from SBQQ__Subscription__c where SBQQ__Contract__c = :conid ];
					
		return lstgetsubs;
	}
	
	public CustomButtonParentingExtension(ApexPages.StandardController controller)
    {
    	
    	this.controller = controller;
		this.con = (Contract)controller.getRecord();
		lstsubs = getsublist(this.con.id);
		system.debug('lstsubs size is ' +lstsubs.size());
		returnmessage = checkparenting(lstsubs);
		if(returnmessage != null)
		{ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, returnmessage, '')); 
		  return;
		}

	}//end standard controller
	
	public String checkparenting(List<SBQQ__Subscription__c> lstitems)
	{
		String message;
		Boolean hasparenting = true;
		
		for(SBQQ__Subscription__c s :lstitems)
		{
			if(!s.name__c.contains('Product Parent') && s.parent__c == null)
			{  hasparenting = false;  }
		}
		
		if(hasparenting == true)
		{  message = 'Subscription items already have a parenting hierarchy.';  }
		
		return message;
	}
	
	public pageReference CreateParentingHierarchy()
	{

		if(returnmessage == null)
		{
			returnmessage = ParentSubscriptions(lstsubs);
		}
		
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, returnmessage));
		
		return null;
		

	}
	
	public static string ParentSubscriptions(List<SBQQ__Subscription__c> lstitems)
	{
		//update the parent__c field on all the subscription items  with the appropriate parent subscription line
		//set the product_parent_id__c field with the id of the correct product parent line
		system.debug('*********BEGIN PARENTSUBSCRIPTIONS*************');
		
		String message;
		
		Set<Id> setqlid = New Set<Id>();
		Map<Id, Id> mpparents = New Map<Id, Id>();
		List<SBQQ__Subscription__c> lstupdsub = New List<SBQQ__Subscription__c>();
		
		for(SBQQ__Subscription__c s : lstitems)
		{ setqlid.add(s.sbqq__quoteline__r.sbqq__requiredby__c); }

		for(SBQQ__Subscription__c sub : lstitems)
		{  
			if(setqlid.contains(sub.sbqq__quoteline__c))
			{ mpparents.put(sub.sbqq__quoteline__c, sub.id); }
			
		}


		for(SBQQ__Subscription__c subs : lstitems)
		{

			if(mpparents.containskey(subs.sbqq__quoteline__r.sbqq__requiredby__c))
			{
				Id parentsubid = mpparents.get(subs.sbqq__quoteline__r.sbqq__requiredby__c);
				subs.parent__c = parentsubid;
				lstupdsub.add(subs);
	
			}
		}

		if(lstupdsub.size() > 0)
		try
		{  update lstupdsub;  }
		catch(Exception e)
		{ message = 'Error in ParentSubscriptions: ' +e.getmessage();  }
		
		if(message==null)
		{  message = 'Subscription line items were parented successfully.'; }
		
		system.debug('**********END PARENTSUBSCRIPTIONS*************');
		
		return message;
		
	}

   
}