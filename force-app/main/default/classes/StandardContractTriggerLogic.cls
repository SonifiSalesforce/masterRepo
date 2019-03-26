public with sharing class StandardContractTriggerLogic {
	
	/*  jjackson 9/2018 removed this for CPQ project because standard contract object does not
	    have a conversion date field
	public static void updateConversionDate(List< Contract__c> newList){
		System.debug('Entering updateConversionDate...');
		System.debug('Looking at ' + newList.size() + ' records');
		
		//initialize var
		List<Contract_Line_Item__c> clItems = new List<Contract_Line_Item__c>();
		Map<Id, Contract__c> id2ContractMap = new Map<Id, Contract__c>();
		
		//go through list and see where it needs to be update (conversion date is not the same as customer signed date unless it is null)
		for(Contract__c c : newList){
			if(c.Customer_Signed_Date__c != c.Conversion_Date__c && c.Customer_Signed_Date__c != null){
				c.Conversion_Date__c = c.Customer_Signed_Date__c;
				
				//if this is update then make a map of the contract
				if(c.Id != null){
					id2ContractMap.put(c.Id, c);
				}
			}
		}
		//System.debug('Contract map is::' + id2ContractMap);
		
		if(id2ContractMap.KeySet().size() > 0){
			//query for the related contract line items
			clItems = [SELECT id, Conversion_Date__c, Legal_Contract__c FROM Contract_Line_Item__c WHERE Legal_Contract__c IN :id2ContractMap.KeySet()];
			
			//go through contract line items and update conversion date
			for(Contract_Line_Item__c cli : clItems){
				cli.Conversion_Date__c = id2ContractMap.get(cli.Legal_Contract__c).Customer_Signed_Date__c;
				
			}
			
			
			//update the Contract line items 
			if(clItems.size() > 0){
				update clItems;
			}
		}
	} */

//jjackson this code updates the following on related subscription line items when the change is made on the contract
//start date, end date, auto-renewal checkbox, terminate warranty
public static void UpdateSubscriptionLineItems(List<Contract> contracttriggernewlist, Map<Id,Contract> contracttriggeroldmap)
{
	system.debug('***************************BEGIN UpdateContractLineItems********************');

	Set<Id> setcontractchgenddate = New Set<Id>();
	Set<Id> setcontractchgstartdt = New Set<Id>();
	Set<Id> setcontractchgautornw = New Set<Id>();
	Set<Id> setterminatewarranty = New Set<Id>();
	Set<Id> setlcliids = New Set<Id>();
	Set<Id> setinlcli = New Set<Id>();
	Set<String> lclistatusvalues = New Set<String>();
	Set<String> lclichgstartdatevalues = New Set<String>();
	Set<Id> allcontractids = New Set<Id>();
	Map<Id,contract> contractchgmap = New Map<Id,contract>();
	Map<Id,contract> inactiveconmap = New Map<Id,contract>();
	Map<Id,contract> mpnewconstartdt = New Map<Id,contract>();
	List<Entitlement> entllst = New List<Entitlement>();
	
	//get values from the custom settings that store status values needed for the rest of the code
	List<Contract_Line_Item_Renew_Status__c> lststatusvalues = Contract_Line_Item_Renew_Status__c.getall().values();
	List<Contract_Line_Item_Change_Start_Date__c> lstchgstart = Contract_Line_Item_Change_Start_Date__c.getall().values();
	
	List<Legacy_Service_Contract_Names__c> legacyscnames = Legacy_Service_Contract_Names__c.getall().values();
	List<Entitlement> lstupdentl = New List<Entitlement>();
	List<SBQQ__Subscription__c> updlstsub = New List<SBQQ__Subscription__c>();
	List<ServiceContract> lstupdsc = New List<ServiceContract>();
	
	
	//take the list of contract line item status values from the custom setting and put them in a set;
	//if any contract line items have one of these status values, we want to push out the end date during auto-renewal
	//we also want to change the term start date on the line item if the contract start date has changed;
	if(test.isrunningTest())
	{  lclistatusvalues.add('Installed Activated');
	   lclistatusvalues.add('Pending De-Installation');
	   lclichgstartdatevalues.add('Pending De-Installation');
	   lclichgstartdatevalues.add('Installed Activated');
	}
	else
	{
		for(Contract_Line_Item_Renew_Status__c cs : lststatusvalues)
		{  lclistatusvalues.add(cs.line_item_status__c);  }
		
		for(Contract_Line_Item_Change_Start_Date__c cds : lstchgstart)
		{  lclichgstartdatevalues.add(cds.ChangeDateStatus__c);  }
	}

	for(contract con : contracttriggernewlist)
	{
	  allcontractids.add(con.Id);
	  system.debug('contract that came into trigger is ' +con.Id +', ' +con.name +', ' +con.Contract_Status__c +', ' +con.StartDate +', ' +con.EndDate);	
	  if(con.Contract_Status__c != 'Inactive')
	  {
	
		if(con.EndDate != null && (con.EndDate != contracttriggeroldmap.get(con.id).EndDate))
		{  setcontractchgenddate.add(con.id);  
		   system.debug('contract added to setcontractchgenddate is ' +con.id +', ' +con.contractnumber);
		}  //these are the ids of contracts whose end dates have changed
		
		if(con.StartDate != null && (con.StartDate != contracttriggeroldmap.get(con.id).StartDate))
		{  setcontractchgstartdt.add(con.id);  
		   system.debug('contract added to setcontractchgstartdt is ' +con.contractnumber +', ' +con.id);
		}
		
		//if the contract is getting a start date for the first time, use these contract id's to double check the
		//service contracts/entitlements and make sure they get a start date
		if(con.StartDate != null && contracttriggeroldmap.get(con.id).StartDate == null)
		{   mpnewconstartdt.put(con.Id,con);  }

		//shawks BUG-00574 - Add IF statement for auto-renew
		if(con.auto_renew__c == true && con.auto_renew__c != contracttriggeroldmap.get(con.id).auto_renew__c)
		{   setcontractchgautornw.add(con.id);
			//system.debug('contract added to setcontractchgautornw is ' + con.id + ', ' + con.name);
		}
		
		//add all the contracts with changes to the contractchgmap
		if(setcontractchgenddate.contains(con.id) || setcontractchgstartdt.contains(con.id)||mpnewconstartdt.containskey(con.id) || setcontractchgautornw.contains(con.id))
		{   contractchgmap.put(con.Id, con);  }

	  		system.debug('contract' + con.contractnumber +' new end date is ' +con.EndDate +' and old end date = ' +contracttriggeroldmap.get(con.id).EndDate);
	  		//system.debug('contract' +con.name +'new start date = ' +con.StartDate +'and old start date = ' +contracttriggeroldmap.get(con.id).StartDate);
	  
	  }//end if contract status is not Inactive
	  
	  //identify contracts where the status is changed to Inactive
	  if(con.Contract_Status__c == 'Inactive' && (con.Contract_Status__c != contracttriggeroldmap.get(con.id).Contract_Status__c))
	  {  inactiveconmap.put(con.Id,con);  
		 //system.debug('contract ' +con.name +' was changed from ' +contracttriggeroldmap.get(con.id).status__c +' to ' +con.status__c);
		 //system.debug('inactiveconmap size is ' +inactiveconmap.size());
	  }
		
	}//end contract for loop
	
	//get all the line items related to the contracts in the trigger in one query
	List<SBQQ__Subscription__c> lstsub = New List<SBQQ__Subscription__c>();
	lstsub = [ Select Id, name__c, SBQQ__Subscriptionenddate__c, status__c, sbqq__contract__c, sbqq__product__r.family, sbqq__quantity__c, sbqq__subscriptionstartdate__c,
		            project_type__c, equipment_ownership__c, sbqq__contract__r.Contract_Status__c
		            from SBQQ__Subscription__c where sbqq__contract__c in :allcontractids and (not name__c like '%Extended Warranty%')
                    and (status__c in :lclistatusvalues OR sbqq__product__r.family = 'Entitlement') ]; 
                    
    system.debug('lstsub size is ' +lstsub.size());


	for(SBQQ__Subscription__c conlcli : lstsub)	
	{ 
		
		setlcliids.add(conlcli.id);    //hold the line item id's aside for querying related entitlements/service contracts
		if(inactiveconmap.keyset().Contains(conlcli.sbqq__contract__c))
		{ setinlcli.add(conlcli.id); }
		if(test.IsRunningTest())
		{ system.debug('line item to be updated in standardlegalcontracttest is ' +conlcli.name__c +', ' +conlcli.status__c +', ' +conlcli.sbqq__subscriptionstartdate__c +', ' +conlcli.sbqq__subscriptionenddate__c); }
	}
	//using the contract line id's related to the contracts in the trigger, find all entitlements/service contracts
	//that are related to check for start/end dates that are needed
	entllst = [ Select Name, subscription__c, StartDate, EndDate, ServiceContract.Id, ServiceContract.Name, ServiceContract.EndDate,
	  	            ServiceContract.StartDate, ServiceContract.term, ServiceContract.NotificationNeeded__c, 
	  	            Status, ServiceContract.Status, subscription__r.sbqq__contract__c from
		            Entitlement where subscription__c in :setlcliids  ];
		            
    if(test.isRunningTest())
    {
    	for(Entitlement entrec :entllst)
    	{
    		system.debug('Entitlement to be updated in UpdateContractLineItems method is ' +entrec.Name +', ' +entrec.startdate +', ' +entrec.enddate +', ' +entrec.subscription__c);
    	}
    }

	
	if(contractchgmap.size() > 0)  //if the contract change map has at least one record in it, dates have changed on a contract
	{
	
		Map<Id,Date> mplineitemidtoconenddate = New Map<Id,Date>();
		Map<Id,Date> mplineitemidtoconstartdt = New Map<Id,Date>();

		system.debug('inside if statement contractchgmap.size > 0 and lstsub size is ' +lstsub.size());
		
	    if(lstsub.size() > 0) //if there are line items related to the contracts that had dates changed,
		{
		
			for(SBQQ__Subscription__c lcli : lstsub)  //loop through them
			{
				
			
				if(contractchgmap.containskey(lcli.sbqq__contract__c) && !setinlcli.Contains(lcli.id))  //if the contract end date has changed,
				{
					if(setcontractchgenddate.contains(lcli.sbqq__contract__c) && lcli.sbqq__product__r.family != 'Warranty' && lcli.sbqq__product__r.family != 'Entitlement') //and the contract's id is in the set of id's where end date has changed,
					{	lcli.sbqq__subscriptionenddate__c = contractchgmap.get(lcli.sbqq__contract__c).EndDate;  //update the term end date on the line item
						mplineitemidtoconenddate.put(lcli.id,contractchgmap.get(lcli.sbqq__contract__c).EndDate);  //add line item id/new end date to a map for later
						system.debug('term end date was changed on line item ' +lcli.name);
					}
					
					if(setcontractchgstartdt.contains(lcli.sbqq__contract__c) && lclichgstartdatevalues.contains(lcli.status__c) &&
					    lcli.sbqq__product__r.family != 'Warranty' && lcli.sbqq__product__r.family != 'Entitlement')  //if the set of contracts with changed start dates contains the contract id,
					{   lcli.sbqq__subscriptionstartdate__c = contractchgmap.get(lcli.sbqq__contract__c).StartDate;  
						system.debug('term start date was changed on line item ' +lcli.name);
						mplineitemidtoconstartdt.put(lcli.id, contractchgmap.get(lcli.sbqq__contract__c).StartDate);
					} //update the start dates on related line items

					//shawks BUG-00574 - Add IF statement to update Auto-Renew
					
					if(setcontractchgautornw.contains(lcli.sbqq__contract__c) && lcli.sbqq__product__r.family != 'Warranty' && lcli.sbqq__product__r.family != 'Entitlement')
					{	lcli.auto_renew__c = contractchgmap.get(lcli.sbqq__contract__c).auto_renew__c;
					//	system.debug('auto renew was changed on line item ' +lcli.name);
					}
											
					updlstsub.add(lcli);  //we know some date change has been made here, so add line item to the update list
				}
			
			}  //end line item for loop
		
		}//end if lstsub.size > 0
		
				
		Set<String> legacynames = New Set<String>();
		
		system.debug('queried list entllst size is ' +entllst.size());
		
		//add all the legacy service contract names to a set for comparison later
		if(test.isrunningTest())
		{ legacynames.add('Legacy');  }
		else
		{
			for(Legacy_Service_Contract_Names__c leg : legacyscnames)
			{  legacynames.add(leg.service_contract_names__c);  
			   system.debug('legacy name added to set is ' +leg.service_contract_names__c);
			}
		}
		
		//loop through entitlements.  if the entitlement related line item id is found in the map of line items that had end date changes,
		//update the end date on the entitlement.  If the related service contract name is found in the legacy name set, update the end date
		//on the service contract that is related to the entitlement.
		if(entllst.size() > 0 )
		{
			for(Entitlement entl : entllst)
			{
			  if(contractchgmap.containskey(entl.subscription__r.sbqq__contract__c))
			  {	
                //before changing dates on anything, make sure the related contract is not changing to Inactive
				if(!inactiveconmap.containskey(entl.subscription__r.sbqq__contract__c))
				{
					system.debug('entitlement name is ' +entl.name +'for contract line item ' +entl.subscription__c);
				
					ServiceContract updateservcon = New ServiceContract();
				
					updateservcon.Id = entl.servicecontract.Id;
								
					//if the legal contract is getting a start date for the first time and the entitlement has no start date,
					//put a start date on the entitlement
					if(mpnewconstartdt.containskey(entl.subscription__r.sbqq__contract__c))
					{ entl.startdate = mpnewconstartdt.get(entl.subscription__r.sbqq__contract__c).StartDate; }
			    
			    	if(mplineitemidtoconstartdt.keyset().contains(entl.subscription__c))
					{ entl.startdate = mplineitemidtoconstartdt.get(entl.subscription__c); }
			    
					//add or update end dates of entitlements on any contract end date change
					if(mplineitemidtoconenddate.containskey(entl.subscription__c))
					{  entl.EndDate = mplineitemidtoconenddate.get(entl.subscription__c);  }
				
					//add updated entitlements to an update list
					lstupdentl.add(entl);
				
				//check whether related service contracts have start dates.  Service contracts related to warranty
				//line items should have start dates from the work order trigger logic, but that doesn't always work.
				//if there is a related service contract, add the start date from the legal contract; then calculate the enddate and
				//add that also
	
				  	Date constartdate;
				  	
				  	if(mpnewconstartdt.size() > 0 && mpnewconstartdt.containskey(entl.subscription__r.sbqq__contract__c))
				  		{ constartdate = mpnewconstartdt.get(entl.subscription__r.sbqq__contract__c).StartDate;  }
				  
				  		if(contractchgmap.size() > 0 && contractchgmap.containskey(entl.subscription__r.sbqq__contract__c))
				  		{ constartdate = contractchgmap.get(entl.subscription__r.sbqq__contract__c).StartDate;  }

				  		if(constartdate != null)
				  		{
							Integer terminmonths = 0;
					
							if(entl.ServiceContract.term != null)
							{  terminmonths = Integer.valueof(entl.ServiceContract.term);  }
							else
							{  terminmonths = 3;  //if we have to set term to 3 months because of no term on the service contract,
					   			updateservcon.term = 3;  //put 3 months in the term field on the service contract
					   			updateservcon.notificationneeded__c = true;  //set the notification needed field to true so email will go out
							}  //if the service contract has no term length set the contract to 3 months
								//contracts group will get an email telling them to fix the term on the service contract (workflow rule)
					
				  			Date conenddate = constartdate.addMonths(terminmonths);
				  			updateservcon.startdate = constartdate;
				  	
				  			//if the service contract is not a legacy, only add the end date if the end date is null
				  			//once an end date is on the service contract, we don't change it unless it is a legacy contract
				  			if(entl.ServiceContract.enddate == null && !legacynames.contains(entl.servicecontract.name))
				  			{  updateservcon.enddate = conenddate;  }
				  	
				  			//shawks - BUG-00574: Move below -> lstupdsc.add(updateservcon);
				  		}
				  		else
				  		{
				  			system.debug('line 228--service contract start date is null but contract start date was not found.');
				  		}
		
			
				//if the service contract is a legacy type and the contract end date is being pushed out,
				//push out the end date on the service contract also; but only if legacy
					if(legacynames.contains(entl.servicecontract.name) && mplineitemidtoconenddate.containskey(entl.subscription__c))
					{   updateservcon.enddate = mplineitemidtoconenddate.get(entl.subscription__c);  
						system.debug('servicecontract new enddate for ' +entl.servicecontract.name + ' is ' +updateservcon.enddate);
						//shawks - BUG-00574: Move below -> lstupdsc.add(updateservcon);
					}

					lstupdsc.add(updateservcon); //Move here so no duplicate records in list
					system.debug('entl name and service contract name are ' +entl.name +', ' +entl.servicecontract.name);
				  }//end if the related contract id is not in the inactive contract map
			  	 }//end if contractchgmap.keyset		
				}//end entitlement for loop
			}//end entl list
		
	} //if contractchgmap size > 0

	//now put end dates on service contracts where the legal contract has been deactivated
	if(inactiveconmap.size() > 0)
	{
	  Date newenddate = system.today().addDays(-1);
	  
	  List<Entitlement> inentllst = New List<Entitlement>();
	  inentllst = [ Select Name, subscription__c, StartDate, EndDate, ServiceContract.Id, ServiceContract.Name, ServiceContract.EndDate,
	  	            ServiceContract.StartDate, ServiceContract.term, ServiceContract.NotificationNeeded__c, 
	  	            Status, ServiceContract.Status, subscription__r.sbqq__contract__c from
		            Entitlement where subscription__r.sbqq__contract__c in :inactiveconmap.keyset() ];
      
      //for(Id conid :inactiveconmap.keyset())
      //{ system.debug('contract in inactiveconmap is ' +conid); }
      	
      //system.debug('inentllst size is ' +inentllst.size());
	  
	  for(Entitlement inentl :inentllst)
	  {
	  
	  	system.debug('inside entitlement list for inactive contracts');
	  	system.debug('entitlement is ' +inentl.name +', ' +inentl.servicecontract.name);
	  	
	   if(inactiveconmap.containskey(inentl.subscription__r.sbqq__contract__c))
	   {
		//system.debug('inactiveconmap contains legal contract id for the entitlement');
		ServiceContract upservicecon = New ServiceContract();
		upservicecon.id = inentl.ServiceContract.id;
		system.debug('servicecontract id is ' +inentl.servicecontract.id);
					
			//system.debug('inside inentl loop to update end dates on entitlements/service contracts');
				
			if(inentl.status == 'Active')
				{  inentl.enddate = newenddate;  
				   //system.debug('today end date on entitlement ' +inentl.name);
				}

			if(inentl.ServiceContract.status == 'Active')
				{ upservicecon.enddate = newenddate;
				  //system.debug('today enddate on service contract ' +inentl.servicecontract.name);
				  lstupdsc.add(upservicecon);
				}
					
			lstupdentl.add(inentl);

		  }//if inactive map contains the line item's contract id
		}//for entitlement list

	}//end if inactiveconmap size > 0
	
	
		try{ update updlstsub;  }
		catch(Exception e)
		{ system.debug('ERROR in UpdateContractLineItems while updating contract line items: ' +e.getmessage()); }
		
		try{ update lstupdentl; }
		catch(Exception ex)
		{ system.debug('ERROR in UpdateContractLineItems while updating entitlements: ' +ex.getmessage()); }
		
		try{ upsert lstupdsc;  }
		catch(Exception err)
		{ system.debug('ERROR in UpdateContractLineItems while upserting service contracts: ' +err.getmessage()); }
	
	system.debug('***************************END UpdateContractLineItems********************');

}//end method

			
	//jjackson 6/25/2014 BUG-00361 for Hilton, get install clock start dates from contract and add to work order
  	public static void GetClockStartDate(Map<Id,contract> mptriggerold, List<contract> lsttriggernew){
    	   system.debug('***********************START GetClockStartDate *******************************');
    	   
       Set<Id> setlcid = new Set<Id>();
       Map<Id,Id> mpoitolcli = new Map<ID,Id>();
       Map<Id,Date> mpftgstart = new Map<Id,Date>();
       Map<Id,Date> mpintstart = new Map<Id,Date>();
       Boolean boostartclock;
       
       for(contract reclc : lsttriggernew)
       {
       	   boostartclock = false;
           Boolean booClockisStarted = reclc.Installation_Clock_Started__c;
           Boolean booOldClockisStarted = mptriggerold.get(reclc.id).Installation_Clock_Started__c;
           Date newftgstartdt = reclc.FTG_Clock_Start_Date__c;
           Date oldftgstartdt = mptriggerold.get(reclc.id).FTG_Clock_Start_Date__c;
           Date newintstartdt = reclc.Interactive_Clock_Start_Date__c;
           Date oldintstartdt = mptriggerold.get(reclc.id).Interactive_Clock_Start_Date__c;
           
           if(!booOldClockisStarted && booClockisStarted)
               boostartclock = true;
              
           if(booOldClockisStarted)
           { 
           	 if(oldftgstartdt != newftgstartdt)
           	   boostartclock = true;
           	  
           	 if(oldintstartdt != newintstartdt)
           	   boostartclock = true;
           }
           
           //jjackson 11/2014 add another scenario:  if clock was started but now is not, run the update code
           //to remove dates from the work order that were put on by mistake
           if(booOldClockisStarted && !booClockisStarted)
           {
           	  if(newftgstartdt == null && newintstartdt == null)  //if both dates are null
           	     boostartclock = true;
           }
           
           if(boostartclock)
           {
           	 setlcid.add(reclc.id);
           	 mpftgstart.put(reclc.id,newftgstartdt);
           	 mpintstart.put(reclc.id,newintstartdt);
           	 system.debug('mpftgstart is ' +mpftgstart);
           	 system.debug('mpintstart is ' +mpintstart);
           }
         } //end of trigger.new for loop
         	
       if(setlcid != null && boostartclock)  //if there are records that meet the change criteria, continue on       
       {
       	  //system.debug('starting install clock where lcid and boostartclock are ' +setlcid +', ' +boostartclock);
       	  List<SBQQ__Subscription__c> lstsub = new list <SBQQ__Subscription__c>();
       	  lstsub = [ Select ID, sbqq__contract__c, (select Id, subscription__c, subscription__r.sbqq__contract__c from Order_Items__r) from SBQQ__Subscription__c where sbqq__contract__c in :setlcid ];
       	  system.debug('lstsub size is ' +lstsub.size());
      	  if(!lstsub.IsEmpty())
       	  {
       	  	for(SBQQ__Subscription__c reclcli : lstsub)
       	    {
   	  	  
       	  	  for(Order_Item__c oi : reclcli.order_items__r)
       	  	  {
       	  	  	mpoitolcli.put(oi.id, oi.subscription__r.sbqq__contract__c);
       	  	  	//system.debug('contract id is ' +oi.subscription__r.sbqq__contract__c);
       	  	  }
       	    }
       	      system.debug('mpoitolcli map size is ' +mpoitolcli.size());
       	  }
       
          List<Associated_Item__c> lstai = new list<Associated_Item__c>();
          lstai = [ Select Work_Order__c, Order_Item__c, order_item__r.subscription__r.sbqq__contract__c
                    from Associated_Item__c where Order_Item__c in :mpoitolcli.keyset()];
          
          system.debug('lstai size is ' +lstai.size());
          Map<Id, Associated_Item__c> mapai = New Map<Id, Associated_Item__c>();
         
          if(!lstai.IsEmpty())
          {
          	for(Associated_Item__c recai : lstai)
            {
          	   	  mapai.put(recai.work_order__c, recai);
            }
 
          }
   	  

       	  List<Work_Order__c> lstupdwo = new list<Work_Order__c>();
       	  List<Work_Order__c> lstworkorders = [Select Id, FTG_Contracted_Completion_Date__c, GP_Contracted_Completion_Date__c from Work_Order__c where Id in :mapai.keyset()];
       	  system.debug('lstworkorders size is ' +lstworkorders.size());
       	  
       	  for(Work_Order__c w : lstworkorders )
       	  {
       	  	
       	  	  Associated_Item__c a;
       
       	  	  
       	  	  if(mapai.containskey(w.id))
       	  	  {	a = mapai.get(w.id); }
       	  	  
       	  	  if(a != null && mpoitolcli.containskey(a.order_item__c))
        	  {	
       	    	Date ftgclockstart = mpftgstart.get(mpoitolcli.get(a.order_item__c));
       	    	Date gpclockstart = mpintstart.get(mpoitolcli.get(a.order_item__c));
       	    	Date dtftgcontcompletion; 
       	    	Date dtgpcontcompletion;
       	    	
       	    	if(ftgclockstart != null)
       	    	   { dtftgcontcompletion = ftgclockstart.addDays(60); }
       	    	else
       	    	   { dtftgcontcompletion = null; }
       	    	   
       	    	if(gpclockstart != null)
       	    	   { dtgpcontcompletion = gpclockstart.addDays(90); }
       	    	else
       	    	   { dtgpcontcompletion = null; }
       	    	   
  				
  				w.ftg_contracted_completion_date__c = dtftgcontcompletion;
  				w.gp_contracted_completion_date__c = dtgpcontcompletion;
       	    	lstupdwo.add(w);
       	    	
        	  }
       	    }
       	    
       	    Savepoint sp = Database.setSavepoint();
       	    try
       	    { update lstupdwo; }
       	    
       	    catch(Exception e)
		    {
			   Database.rollback(sp);
			   System.Debug('Update Error Occurred in GetClockStartDate: ' +e.getMessage());
			   throw new Exceptions.AppException(e.getMessage());

		    }
       	   
           system.debug('******************END GetClockStartDate *******************************');
       	  
        }
      } 
      
      public static void SendGroupServicesEmail(List<contract> triggernewlist, Map<Id,contract> triggeroldmap)
      {
      	   system.debug('************** BEGIN SendGroupServicesEmail *********************');
			
		   Map<Id, contract> mpcontracts = New Map<Id,contract>();
		   
		   for(contract con : triggernewlist)
		   {
		   	 if(con.Contract_Status__c == 'Order Approved' && triggeroldmap.get(con.id).Contract_Status__c != 'Order Approved')
		   	 {
		   	 	mpcontracts.put(con.Id,con); //create a map of contracts where status was changed to order approved
		   	 }
		   }      	   
      	   
		   if(mpcontracts.size() > 0) //if there are contract ids in the set, query for group services line items
		   {
		   	 
		   	 	List<SBQQ__Subscription__c> listlcli = New List<SBQQ__Subscription__c>();
		   	 	listlcli = [ Select Id, Name__c, sbqq__contract__r.contractnumber, account_name__c, sbqq__contract__r.id, sbqq__product__r.productcode, status__c from SBQQ__Subscription__c where
		   	 	             sbqq__contract__c in :mpcontracts.keyset() AND sbqq__product__r.productcode like 'CC-330040%' AND
		   	 	             status__c = 'Pending Installation Activate' ];
		   	 	             
		   	 	if(listlcli.size() > 0)
		   	 	{
		   	 		EmailUtilities.GroupServicesNotification(listlcli);
		   	 	}
		   	 	else
		   	 	{  system.debug('No group services line items found on contracts changing to Order Approved.');  }
		   	 
		   }
		   else
		   {
		   		system.debug('There were no contracts changing to status of order approved in the update trigger.');
		   }
		   
		   system.debug('*************************END SendGroupServicesNotification******************');
      } 
      
  
     
}