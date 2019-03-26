public with sharing class FinalizeWarrantyEntitlementContractLogic {
	
	public static Map<Id,Id> mpsubtoasset = New Map<Id,Id>();
	public static Map<String, Id> mpentprocess = New Map<String,Id>();
	
	public static string WarrantyandEntitlementProcess(List<SBQQ__Subscription__c> lstsubs)
	{	
		//jjackson--most of this method spins through the line items that are related to the contract in the
		//standard controller.  The method collects the product parent lines and the entitlement and warranty
		//lines.  It then creates some maps for matching purposes, then spins through the subscription list
		//lstsubs to determine whether there are any existing entitlement or warranty records already related to
		//these subscription lines.  We do not want to create duplicate entitlements and service contracts, so this
		//check is done first.  If existing entitlements/service contracts aren't found for one or more of the
		//subscription records in lstsubs, the CreateEntandSC method is called to create new ones.
		//The methods here are public strings that return strings. This allows us to pass a success or fail message
		//back to the controller extension (CustomButtonWarrantyExtension), which can then be passed back to the visualforce
		//button page to show as an alert message via javascript.
		
		String resultstring = '';
		List<Entitlement> lstent = New List<Entitlement>();
		List<ServiceContract> lstsc = New List<ServiceContract>();
		List<SBQQ__Subscription__c> lstnewentsc = New List<SBQQ__Subscription__c>();
		List<SBQQ__Subscription__c> lstsubentwarr = New List<SBQQ__Subscription__c>(); //list of only warranty & entitlement line items
		List<Id> lstassetid = New List<Id>();
		Set<Id> assetids = New Set<Id>();
		
		//create a map of subscription id and linked asset id if line item is a product parent
		//and id , product parent id if line is a warranty or entitlement line
		for(SBQQ__Subscription__c s : lstsubs)
		{
			if(s.name__c.contains('Product Parent') && s.product_inventory__c != null)
			{ mpsubtoasset.put(s.id,s.product_inventory__c);  }
			
			if(s.sbqq__product__r.family == 'Entitlement' || s.sbqq__product__r.family == 'Warranty')
			{ 
				mpsubtoasset.put(s.id,s.product_parent_id__c.left(18)); 
				lstsubentwarr.add(s);
			}
			
			
		}
		
		//get a map of the entitlement name to entitlement process id for creating the entitlement record
		mpentprocess = getEntlProc();
		
		lstassetid = mpsubtoasset.values();
		for(Id i : lstassetid)
		{ assetids.add(i);  }
		
	
		//query for existing entitlements that have a matching subscription id and asset id
		lstent = [ Select id, Name, accountid, assetid, status, subscription__c, servicecontractid from Entitlement 
		           where assetid in :assetids AND subscription__c in :mpsubtoasset.keyset() AND 
		           status in ('Active', 'Inactive')];
		           
 		
		if(lstent.size() > 0) //if there are existing entitlements
		{
			Set<Id> scid = New Set<Id>(); // get the related service contract ids for querying          
			Map<Id, Entitlement> mpent = New Map<Id, Entitlement>();
			Map<Id,ServiceContract> mpsc = New Map<Id,ServiceContract>();

			
			for(Entitlement e :lstent)
			{ 
				mpent.put(e.subscription__c, e); 
				scid.add(e.servicecontractid);
			}
     
		//query for existing service contracts
			if(scid != null)
			{   
				
				lstsc = [Select id, name, subscription__c, status, product_inventory__c from
				         ServiceContract where id in :scid ];
				         
				for(ServiceContract s : lstsc)
				{  mpsc.put(s.subscription__c, s);  }
			}
			
			//now spin through the subscription items to see if any of the existing entitlements
			//and servicecontracts match them.  If no matches found, add the subscription item
			//to a list and then create the appropriate entitlement and service contract records
			
			for(SBQQ__Subscription__c sub : lstsubentwarr)
			{
					Boolean isduplicateent = false;
					Boolean isduplicatesc = false;
				
				if(sub.sbqq__product__r.family == 'Entitlement')
				{  
					system.debug('sub name is ' +sub.sbqq__product__r.name);
					
					if(mpent.containskey(sub.product_parent_id__c.left(18)))
					{  Entitlement ent = mpent.get(sub.product_parent_id__c.left(18));
	   
					   if(ent.subscription__c == sub.product_parent_id__c.left(18))
					   { isduplicateent = true; 
					   	 resultstring += 'There is already an entitlement for ' +sub.name__c +'\n';
					   }
					   
					   if(isduplicateent == false)
					   {  lstnewentsc.add(sub);  }
					   
					}
					else
					{  lstnewentsc.add(sub); }
					
				}//end if productfamily is entitlement
				
				if(sub.sbqq__product__r.family == 'Warranty')
				{	
					system.debug('sub name is ' +sub.sbqq__product__r.name);
					
					if(mpsc.containskey(sub.id))
					{
						ServiceContract scon = mpsc.get(sub.id);
	
						if(scon.subscription__c == sub.id)
						{  isduplicatesc = true; 
						   resultstring += 'There is already a service contract for ' +sub.sbqq__product__r.name +'\n';
						}
						   
						if(isduplicatesc == false)
						{  lstnewentsc.add(sub); }
					}
					else
					{  lstnewentsc.add(sub);  }
									
				}
			}//end for loop
			
		} //end if there are existing entitlements
		else
		{
			for(SBQQ__Subscription__c srec : lstsubentwarr )
			{
				lstnewentsc.add(srec);  
			}
		}
		
	
		//subscriptions that don't have matching service contract or entitlement get passed to an insert method
		if(lstnewentsc.size() > 0)
		{
			resultstring += CreateEntandSC(lstnewentsc);
		}

		
		return resultstring;
		
	}//end WarrantyandEntitlementProcess
	
	public static string CreateEntandSC(List<SBQQ__Subscription__c> lstcreate)
	{
		String returnstring;
		
		List<Entitlement> lstnewent = New List<Entitlement>();
		List<ServiceContract> lstnewsc = New List<ServiceContract>();
		Map<Id,Id> mpprodparenttowarr = New Map<Id,Id>();
		Set<Id> setscid = New Set<Id>();
		
		for(SBQQ__Subscription__c s : lstcreate)
		{
			ServiceContract newsc = New ServiceContract();
			Entitlement newent = New Entitlement();
			
			system.debug('line item name is ' +s.name__c);
			
			if(s.sbqq__product__r.family == 'Warranty')
			{
				newsc.name = s.sbqq__product__r.name;
				newsc.accountid = s.sbqq__account__c;
				newsc.subscription__c = s.id;
				if(mpsubtoasset.containskey(s.product_parent_id__c))
				{  newsc.product_inventory__c = mpsubtoasset.get(s.product_parent_id__c); }
				
				lstnewsc.add(newsc);
			}
			
			if(s.sbqq__product__r.family == 'Entitlement')
			{
                String entname = s.sbqq__product__r.name;
                Id aid = s.SBQQ__Account__c;
                String pid = s.Product_Parent_Id__c.left(18);
  				newent.name = entname;
				newent.Accountid = aid;
				newent.subscription__c = pid;
				if(mpsubtoasset.containskey(s.product_parent_id__c))
				{  newent.assetid = mpsubtoasset.get(s.product_parent_id__c);  }
				if(mpentprocess.containskey(s.sbqq__product__r.name))
				{  newent.slaprocessid = mpentprocess.get(s.sbqq__product__r.name);  }
				lstnewent.add(newent);
				
			}
		}//end lstcreate for loop
			
			if(lstnewsc.size() > 0 )
			{ insert lstnewsc; }
			
			for(ServiceContract sc : lstnewsc)
			{  setscid.add(sc.id);  }
			
			//query for the service contracts just created to make a map
			List<ServiceContract> lstgetsc = [ Select Id, subscription__r.product_parent_id__c, product_inventory__c 
			                                   from ServiceContract where id in :setscid ];
			
			//make a map of the new service contracts so they can be matched to the correct entitlements
			for(ServiceContract scon : lstgetsc )
			{  mpprodparenttowarr.put(scon.subscription__r.product_parent_id__c,scon.id);  }
			
			//loop the new entitlements and add the service contract id to field servicecontractid before insert
			for(Entitlement e : lstnewent)
			{
				if(mpprodparenttowarr.containskey(e.subscription__c))
				{  e.servicecontractid = mpprodparenttowarr.get(e.subscription__c);  }
			}
			
			if(lstnewent.size() > 0)
			try{  insert lstnewent;  }
			catch(Exception e)
			{
				returnstring = e.getmessage();
			} 
	
		if(returnstring == null)
		{ returnstring = 'Warranties and Entitlements were successfully created.'; }
		
		return returnstring;
	}
	
	//method that creates a map of all the active entitlement processes for creating an entitlement record
	public static MAP<string,Id> getEntlProc (){
        
        MAP<string,Id> mpEntProcess=new MAP<string,Id>();
        
        for (SlaProcess slproc:[Select ID,Name from SlaProcess where isActive=true]){
            mpEntProcess.put(slproc.name,slproc.id);
        }
        return mpEntProcess;
        
    } 
    
}