/*  LOG
shawks 01/2019 - CPQ: Comment out all since not needed after using out-of-box Contract object
shawks 10/2016 - BUG-00574:  Add code when auto-renew is set on contract also getting set on contract lines.

jjackson 8/2014  BUG-00329, BUG-00212, BUG-00370:  When term Start/End dates are added to a contract, update
the term start/end dates of the related entitlement.  When contract is made inactive, change end date of entitlement
to today.

*/

public with sharing class StandardLegalContractTriggerLogic {
/*shawks CPQ - comment group 01 start
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
	}
	
public static void UpdateContractLineItems(List<Contract__c> contracttriggernewlist, Map<Id,Contract__c> contracttriggeroldmap)
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
	Map<Id,Contract__c> contractchgmap = New Map<Id,Contract__c>();
	Map<Id,Contract__c> inactiveconmap = New Map<Id,Contract__c>();
	Map<Id,Contract__c> mpnewconstartdt = New Map<Id,Contract__c>();
	List<Entitlement> entllst = New List<Entitlement>();
	
	//get values from the custom settings that store status values needed for the rest of the code
	List<Contract_Line_Item_Renew_Status__c> lststatusvalues = Contract_Line_Item_Renew_Status__c.getall().values();
	List<Contract_Line_Item_Change_Start_Date__c> lstchgstart = Contract_Line_Item_Change_Start_Date__c.getall().values();
	
	List<Legacy_Service_Contract_Names__c> legacyscnames = Legacy_Service_Contract_Names__c.getall().values();
	List<Entitlement> lstupdentl = New List<Entitlement>();
	List<Contract_Line_Item__c> updlstlcli = New List<Contract_Line_Item__c>();
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

	for(Contract__c con : contracttriggernewlist)
	{
	  allcontractids.add(con.Id);
	  system.debug('contract that came into trigger is ' +con.Id +', ' +con.name +', ' +con.status__c +', ' +con.contract_start_date__c +', ' +con.contract_end_date__c);	
		
	  if(con.status__c != 'Inactive')
	  {
	
		if(con.contract_end_date__c != null && (con.contract_end_date__c != contracttriggeroldmap.get(con.id).contract_end_date__c))
		{  setcontractchgenddate.add(con.id);  
		   system.debug('contract added to setcontractchgenddate is ' +con.id +', ' +con.name);
		}  //these are the ids of contracts whose end dates have changed
		
		if(con.contract_start_date__c != null && (con.contract_start_date__c != contracttriggeroldmap.get(con.id).contract_start_date__c))
		{  setcontractchgstartdt.add(con.id);  
		   system.debug('contract added to setcontractchgstartdt is ' +con.name +', ' +con.id);
		}
		
		//if the contract is getting a start date for the first time, use these contract id's to double check the
		//service contracts/entitlements and make sure they get a start date
		if(con.contract_start_date__c != null && contracttriggeroldmap.get(con.id).contract_start_date__c == null)
		{   mpnewconstartdt.put(con.Id,con);  }

		//shawks BUG-00574 - Add IF statement for auto-renew
		if(con.auto_renew__c == true && con.auto_renew__c != contracttriggeroldmap.get(con.id).auto_renew__c)
		{   setcontractchgautornw.add(con.id);
			//system.debug('contract added to setcontractchgautornw is ' + con.id + ', ' + con.name);
		}
		
		if(setcontractchgenddate.contains(con.id) || setcontractchgstartdt.contains(con.id)||mpnewconstartdt.containskey(con.id) || setcontractchgautornw.contains(con.id))
		{   contractchgmap.put(con.Id, con);  }

	  system.debug('contract' + con.name +' new end date is ' +con.contract_end_date__c +' and old end date = ' +contracttriggeroldmap.get(con.id).contract_end_date__c);
	  system.debug('contract' +con.name +'new start date = ' +con.contract_start_date__c +'and old start date = ' +contracttriggeroldmap.get(con.id).contract_start_date__c);
	  
	  }
	  
	  if(con.status__c == 'Inactive' && (con.status__c != contracttriggeroldmap.get(con.id).status__c))
	  {  inactiveconmap.put(con.Id,con);  
		 system.debug('contract ' +con.name +' was changed from ' +contracttriggeroldmap.get(con.id).status__c +' to ' +con.status__c);
		 system.debug('inactiveconmap size is ' +inactiveconmap.size());
	  }
		
	}//end contract for loop
	
	//get all the line items related to the contracts in the trigger in one query
	List<Contract_Line_Item__c> lstlcli = New List<Contract_Line_Item__c>();
	lstlcli = [ Select Id, name, term_end_date__c, status__c, legal_contract__c, product__r.family, quantity__c, term_start_date__c,
		            project_type__c, equipment_ownership__c, legal_contract__r.status__c, auto_renew__c
		            from Contract_Line_Item__c where legal_contract__c in :allcontractids and (not name like '%Extended Warranty%')
                    and (status__c in :lclistatusvalues OR product__r.family = 'Entitlement') ]; 
                    
    system.debug('lstlcli size is ' +lstlcli.size());


	for(Contract_Line_Item__c conlcli : lstlcli)	
	{ 
		
		setlcliids.add(conlcli.id);    //hold the line item id's aside for querying related entitlements/service contracts
		if(inactiveconmap.keyset().Contains(conlcli.legal_contract__c))
		{ setinlcli.add(conlcli.id); }
		if(test.IsRunningTest())
		{ system.debug('line item to be updated in standardlegalcontracttest is ' +conlcli.name +', ' +conlcli.status__c +', ' +conlcli.term_start_date__c +', ' +conlcli.term_end_date__c); }
	}
	//using the contract line id's related to the contracts in the trigger, find all entitlements/service contracts
	//that are related to check for start/end dates that are needed
	entllst = [ Select Name, legal_contract_line_item__c, StartDate, EndDate, ServiceContract.Id, ServiceContract.Name, ServiceContract.EndDate,
	  	            ServiceContract.StartDate, ServiceContract.term, ServiceContract.NotificationNeeded__c, 
	  	            Status, ServiceContract.Status, legal_contract_line_item__r.legal_contract__c from
		            Entitlement where legal_contract_line_item__c in :setlcliids  ];
		            
    if(test.isRunningTest())
    {
    	for(Entitlement entrec :entllst)
    	{
    		system.debug('Entitlement to be updated in UpdateContractLineItems method is ' +entrec.Name +', ' +entrec.startdate +', ' +entrec.enddate +', ' +entrec.legal_contract_line_item__c);
    	}
    }

	
	if(contractchgmap.size() > 0)  //if the contract change map has at least one record in it, dates have changed on a contract
	{
	
		Map<Id,Date> mplineitemidtoconenddate = New Map<Id,Date>();
		Map<Id,Date> mplineitemidtoconstartdt = New Map<Id,Date>();

		system.debug('inside if statement contractchgmap.size > 0 and lstlcli size is ' +lstlcli.size());
		
	    if(lstlcli.size() > 0) //if there are line items related to the contracts that had dates changed,
		{
		
			for(Contract_Line_Item__c lcli : lstlcli)  //loop through them
			{
				
			
				if(contractchgmap.containskey(lcli.legal_contract__c) && !setinlcli.Contains(lcli.id))  //if the contract end date has changed,
				{
					if(setcontractchgenddate.contains(lcli.legal_contract__c) && lcli.product__r.family != 'Warranty' && lcli.product__r.family != 'Entitlement') //and the contract's id is in the set of id's where end date has changed,
					{	lcli.term_end_date__c = contractchgmap.get(lcli.legal_contract__c).contract_end_date__c;  //update the term end date on the line item
						mplineitemidtoconenddate.put(lcli.id,contractchgmap.get(lcli.legal_contract__c).contract_end_date__c);  //add line item id/new end date to a map for later
						system.debug('term end date was changed on line item ' +lcli.name);
					}
					
					if(setcontractchgstartdt.contains(lcli.legal_contract__c) && lclichgstartdatevalues.contains(lcli.status__c) &&
					    lcli.product__r.family != 'Warranty' && lcli.product__r.family != 'Entitlement')  //if the set of contracts with changed start dates contains the contract id,
					{   lcli.term_start_date__c = contractchgmap.get(lcli.legal_contract__c).contract_start_date__c;  
						system.debug('term start date was changed on line item ' +lcli.name);
						mplineitemidtoconstartdt.put(lcli.id, contractchgmap.get(lcli.legal_contract__c).contract_start_date__c);
					} //update the start dates on related line items

					//shawks BUG-00574 - Add IF statement to update Auto-Renew
					if(setcontractchgautornw.contains(lcli.legal_contract__c) && lcli.product__r.family != 'Warranty' && lcli.product__r.family != 'Entitlement')
					{	lcli.auto_renew__c = contractchgmap.get(lcli.legal_contract__c).auto_renew__c;
						system.debug('auto renew was changed on line item ' +lcli.name);
					}
											
					updlstlcli.add(lcli);  //we know some date change has been made here, so add line item to the update list
				}
			
			}  //end line item for loop
		
		}//end if lstlcli.size > 0
		
				
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
			  if(contractchgmap.containskey(entl.legal_contract_line_item__r.legal_contract__c))
			  {	
                //before changing dates on anything, make sure the related contract is not changing to Inactive
				if(!inactiveconmap.containskey(entl.legal_contract_line_item__r.legal_contract__c))
				{
					system.debug('entitlement name is ' +entl.name +'for contract line item ' +entl.legal_contract_line_item__c);
				
					ServiceContract updateservcon = New ServiceContract();
				
					updateservcon.Id = entl.servicecontract.Id;
								
					//if the legal contract is getting a start date for the first time and the entitlement has no start date,
					//put a start date on the entitlement
					if(mpnewconstartdt.containskey(entl.legal_contract_line_item__r.legal_contract__c))
					{ entl.startdate = mpnewconstartdt.get(entl.legal_contract_line_item__r.legal_contract__c).contract_start_date__c; }
			    
			    	if(mplineitemidtoconstartdt.keyset().contains(entl.legal_contract_line_item__c))
					{ entl.startdate = mplineitemidtoconstartdt.get(entl.legal_contract_line_Item__c); }
			    
					//add or update end dates of entitlements on any contract end date change
					if(mplineitemidtoconenddate.containskey(entl.legal_contract_line_Item__c))
					{  entl.EndDate = mplineitemidtoconenddate.get(entl.legal_contract_line_item__c);  }
				
					//add updated entitlements to an update list
					lstupdentl.add(entl);
				
				//check whether related service contracts have start dates.  Service contracts related to warranty
				//line items should have start dates from the work order trigger logic, but that doesn't always work.
				//if there is a related service contract, add the start date from the legal contract; then calculate the enddate and
				//add that also
	
				  	Date constartdate;
				  	
				  	if(mpnewconstartdt.size() > 0 && mpnewconstartdt.containskey(entl.legal_contract_line_item__r.legal_contract__c))
				  		{ constartdate = mpnewconstartdt.get(entl.legal_contract_line_item__r.legal_contract__c).contract_start_date__c;  }
				  
				  		if(contractchgmap.size() > 0 && contractchgmap.containskey(entl.legal_contract_line_Item__r.legal_contract__c))
				  		{ constartdate = contractchgmap.get(entl.legal_contract_line_item__r.legal_contract__c).contract_start_date__c;  }

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
					if(legacynames.contains(entl.servicecontract.name) && mplineitemidtoconenddate.containskey(entl.legal_contract_line_item__c))
					{   updateservcon.enddate = mplineitemidtoconenddate.get(entl.legal_contract_line_item__c);  
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
	  inentllst = [ Select Name, legal_contract_line_item__c, StartDate, EndDate, ServiceContract.Id, ServiceContract.Name, ServiceContract.EndDate,
	  	            ServiceContract.StartDate, ServiceContract.term, ServiceContract.NotificationNeeded__c, 
	  	            Status, ServiceContract.Status, legal_contract_line_item__r.legal_contract__c from
		            Entitlement where legal_contract_line_item__r.legal_contract__c in :inactiveconmap.keyset() ];
      
      //for(Id conid :inactiveconmap.keyset())
      //{ system.debug('contract in inactiveconmap is ' +conid); }
      	
      //system.debug('inentllst size is ' +inentllst.size());
	  
	  for(Entitlement inentl :inentllst)
	  {
	  
	  	system.debug('inside entitlement list for inactive contracts');
	  	system.debug('entitlement is ' +inentl.name +', ' +inentl.servicecontract.name);
	  	
	   if(inactiveconmap.containskey(inentl.legal_contract_line_item__r.legal_contract__c))
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
	
	
		try{ update updlstlcli;  }
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

END OF CPQ - comment group 01*/	
	//jjackson 7/23/2014 The updates to lcli term end dates was moved here from the ContractRenewalBatchProcess,
	// but the updates to entitlement end dates were not moved here.  Adding the code in here
	//to do that.
	//jjackson 11/2014 now adding code to update service contract start/end dates for legacy service contracts only
/*
	public static void updateLCLITermDates(List<Contract__c> triggerNew, Map<Id,Contract__c> triggerOldMap)
	{
		system.debug('updateLCLITermDates *************START*********************************');
		
		Set<Id> contractIds = new Set<Id>();
		Set<Id> allcontractids = new Set<ID>();
		Set<Id> inactiveids = new Set<Id>();
 		List<ID> lstInactiveContracts = new list<ID>();
		for(Contract__c c : triggerNew)
		{
		    if(triggerOldMap == null)//Is Insert
			{	contractIds.add(c.Id);  }
		  
			else   //Is update
			{
				if(triggerOldMap.get(c.Id).Contract_Start_Date__c != c.Contract_Start_Date__c || triggerOldMap.get(c.Id).Contract_End_Date__c != c.Contract_End_Date__c)
				{  if(c.Status__c.Contains('Inactive') == false)
					{	contractIds.add(c.Id); 
						system.debug('contract added to contractIds set is ' +c.Id);
					}
				}
					
			    if(triggerOldMap.get(c.Id).Status__c != c.Status__c && c.Status__c == 'Inactive')
			    {    inactiveids.add(c.Id);  //jjackson 8/2014 determine which contracts are inactive to deactivate entitlement and legacy service contract
			    	 system.debug('contract ids added to inactive set are ' + c.id); 
			    }
			    
			   //jjackson 9/2014  need a set of all contract ids together to pull all line items in order to find entitlements
			   //and service contracts
			   allcontractids.add(c.id);
			   system.debug('contract id added to allcontractids is ' +c.id);
			}
			
		}
		List<Contract_Line_Item__c> cliList = [SELECT 
		                                           Id,
											       Term_End_Date__c, 
											       Term_Start_Date__c, 
											       Auto_Renew__c, 
											       Legal_Contract__c,
											       Name,
											       Product__r.Family,
											       Status__c
											   FROM 
											   	   Contract_Line_Item__c
											   WHERE Legal_Contract__c IN :allcontractids]; //contractids

											     
		//jjackson 9/2014 separate line items with updated dates from other line items	
		List<Contract_Line_Item__c> lstupdatedlcli = new list<Contract_Line_Item__c>();	
		for(Contract_Line_Item__c conli : cliList)
		{
			if(contractids.contains(conli.legal_contract__c))
			{  lstupdatedlcli.add(conli);
			  // system.debug('line item that was updated is ' +conli.id + ', ' + conli.name);
			}
		}								     
								     
		Map<Id,List<Contract_Line_Item__c>> contractCLIMap = new Map<Id,List<Contract_Line_Item__c>>();
		for(Contract_Line_Item__c cli : lstupdatedlcli)
		{
		  if(cli.Status__c.Contains('De-Installed') == false && cli.Status__c.Contains('De-Installed') == false)	//jjackson don't add de-installed or cancelled line items to the list of lines that need updating
		  {	if(contractCLIMap.containsKey(cli.Legal_Contract__c))  //this map contains line items where dates need to be updated
			{
				contractCLIMap.get(cli.Legal_Contract__c).add(cli);
				//system.debug('added line item to contractCLIMap ' +cli.id + ', ' + cli.Name);
			}
			else
			{   
				
				List<Contract_Line_Item__c> temp = new List<Contract_Line_Item__c>();
				temp.add(cli);
				contractCLIMap.put(cli.Legal_Contract__c, temp);
				//system.debug('added line item to contractCLIMap' +cli.id + ',' + cli.Name);
			}
		  }
			//system.debug('line item in clilist is ' +cli.id + ', ' + cli.Name);
		}
	
	    //jjackson 8/2014 Find the product parent lines from the inactive contracts to get entitlements that must expire
	    Set<Id> inactiveitemids = new Set<Id>();
	    for(Contract_Line_Item__c cline : cliList)
	    {
	    	if(inactiveids.Contains(cline.legal_contract__c) && (cline.Name.Contains('Product Parent')||cline.Product__r.Family == 'Entitlement'))
	    	{   inactiveitemids.add(cline.id);
	    	   system.debug('added to inactiveitemids: ' +cline.Name); }
	    	
	    }                                                                           
	    //jjackson create a set of lcli id's so contains method can be used below
	    //system.debug('LegalContractTriggerLogic.UpdateLCLITermDates--line item ids in inactiveitemids set are ' +inactiveitemids);                                                                        
	    List<Contract_Line_Item__c> cliUpdate = new List<Contract_Line_Item__c>();
		Map<ID,Date> mpclitoconenddate = new Map<ID,Date>();  //jjackson
		Map<ID,Date> mpclitoconstartdate = new Map<ID,Date>(); //jjackson
		
		for(Contract__c con : triggerNew)
		{
			if(contractCLIMap.containsKey(con.Id)) //if line item dates need to change, put new start/end dates in the map
			{
				for(Contract_Line_Item__c cli : contractCLIMap.get(con.Id))
				{
				  	cli.Term_End_Date__c = con.Contract_End_Date__c;
					cli.Term_Start_Date__c = con.Contract_Start_Date__c;
					cli.Auto_Renew__c = con.Auto_Renew__c;
					cliUpdate.add(cli);
					mpclitoconenddate.put(cli.id,con.Contract_End_Date__c);   //jjackson
					mpclitoconstartdate.put(cli.id,con.Contract_Start_Date__c); //jjackson

				}
			}
		}
		

		//jjackson 7/23/2014 Adding the code from ContractRenewalBatchProcess that is supposed to update end dates on
		//entitlements when lcli term end dates are changed.
		//Query Entitlements
	   List<Entitlement> entitlementList = [SELECT 
	     										  Id,
			     								  EndDate, 
			     								  StartDate, 
			     								  Legal_Contract_Line_Item__c, 
			     								  Do_Not_Renew__c,
			     								  Status,
			     								  Name,
			     								  Asset.Id
			     							  FROM 
			     							  	  Entitlement
			     							  WHERE 
			     							  	  Legal_Contract_Line_Item__c IN : clilist ];
			     							  	  
			     							  	  //AND Do_Not_Renew__c = false];
	     Utilities.writeLog('Entitlements queried '+entitlementList, StandardLegalContractTriggerLogic.class, 'execute', LoggingLevel.DEBUG); 
	     
	     Map<Id, List<Entitlement>> contractLineItemEntitlementMap = new Map<Id, List<Entitlement>>();
	     List<Entitlement> entitlements;
	     for(Entitlement e : entitlementList) {
			if(!contractLineItemEntitlementMap.containsKey(e.Legal_Contract_Line_Item__c)){
				entitlements = new List<Entitlement>();
			} else {
				entitlements = contractLineItemEntitlementMap.get(e.Legal_Contract_Line_Item__c);
			}
			entitlements.add(e);
			contractLineItemEntitlementMap.put(e.Legal_Contract_Line_Item__c,entitlements);		
			system.debug('LegalContractTriggerLogic--entitlement list is ' +e.Name +', ' + e.Legal_Contract_Line_Item__c);
	     }
	     

	     List<Entitlement> eUpdate = new List<Entitlement>();
	     
	     //jjackson loop thru line items. Update entitlement fields where lcli id is not in the inactive set and
	     //change entitlement end date to today if lcli id is in the inactive set.
	     for(Contract_Line_Item__c cli : cliList)
	     {
	         if(contractLineItemEntitlementMap.containsKey(cli.Id))
	         {
	         	   for(Entitlement e : contractLineItemEntitlementMap.get(cli.Id))
	               {
	               	//jjackson 8/2014 setting entitlement start/end date to contract term start/term end
	               	//this will reset the entitlement end date every time the contract auto renews if the
	               	//do not renew check box is false
	               	   system.debug('Processing entitlement: ' +e.Name + ', ' + e.Id);
	               	   if(!inactiveitemids.contains(cli.id) && contractCLIMap.containsKey(cli.legal_contract__c) )
	               		   {e.StartDate = mpclitoconstartdate.get(cli.id);
	                		e.EndDate = mpclitoconenddate.get(cli.id);
  		            		eUpdate.add(e);
	                				
	                		//system.debug('start date and end date are ' +mpclitoconstartdate.get(cli.id) + ',' +mpclitoconenddate.get(cli.id));
	                	   }
	                	   else
	                	   {
	                	   	if(inactiveitemids.contains(cli.id))
	                		   	{   e.EndDate = system.Today();
	                                eUpdate.add(e);
	                                //system.debug('LegalContractTriggerLogic--entitlement end date changed to today is ' +e.id);
	                		   	}
	                	   }
	                }
	          }
	            		 	
	            		 	
	        }//end for loop
	  //jjackson 11/2014  We have updated line items and entitlements, also update legacy service contracts if this contract is related to one
	  List<ServiceContract> scUpdate = new List<ServiceContract>();
	  
	  if(!eUpdate.IsEmpty())  //if entitlement update list is not empty, get an updated list of related service contracts
	  {  scUpdate = StandardLegalContractTriggerLogic.UpdateLegacyServiceContracts(inactiveitemids,eUpdate,mpclitoconstartdate,mpclitoconenddate);  }

	  Savepoint sp = Database.setSavepoint();
	  try
	  {
		update cliUpdate;
		update eUpdate; }
	  catch(Exception ex1)
	  {system.debug('Error in Update LCLI Term Dates--updating Contract Line Items and Entitlements:  ' +ex1.getMessage());
	   Database.rollback(sp);  }

	if(!scUpdate.IsEmpty())
      try
      { update scUpdate;  }  //not all service contracts are legacy contracts, so make sure this contract has a legacy one related before attempting to update
	  
	  catch(Exception ex)
	  { Utilities.writeLog('Error in Legal Contract Trigger-Update LCLI Term Dates--updating service contracts: '+ex.getMessage(), StandardLegalContractTriggerLogic.class, 'execute', LoggingLevel.DEBUG);
	  	Database.rollback(sp); }
	  	
	  system.debug('updateLCLITermDates ***************END');
    }  //end of method
 
	public static List<ServiceContract> UpdateLegacyServiceContracts(Set<ID>inactiveitemids,List<Entitlement> eUpdate,Map<Id,Date>mpclitoconstartdate,Map<Id,Date>mpclitoconenddate){
	     system.debug('******************************START UpdateLegacyServiceContracts ********************************');
	     //jjackson create a list of related legacy service contracts that need dates updated OR need to be deactivated
	     
	     List<ServiceContract> lstrelatedsc = new List<ServiceContract>();
	     List<ServiceContract> lstupdsc = new List<ServiceContract>();
	     List<ServiceContract> lstreturnsc = new List<ServiceContract>();
         Set<String> legacynames = new Set<String>();
         Set<Id> setassetids = new Set<Id>();
         
         for(Entitlement recentl : eUpdate)
         {  setassetids.add(recentl.Asset.Id);  } //create a set of entitlement asset ids to find service contracts related to the same asset
         //system.debug('setassetids are ' +setassetids);
         //jjackson get legacy service contract name values from custom setting
        if(test.isRunningTest())
        { legacynames.add('Legacy') ;}
        else
        {
        	List<Legacy_Service_Contract_Names__c> legacysc = Legacy_Service_Contract_Names__c.getall().values();
  
         	for(Legacy_Service_Contract_Names__c name : legacysc)
         	{   legacynames.add(name.Name);  }
         	// system.debug('legacy name from custom setting is ' +name.Name);   }  //make a set of all the legacy service contract names for comparison
        }
         //jjackson find the related service contracts by using the asset id from the entitlement--it is the same asset as the one related to the sc
	     lstrelatedsc = [ Select Id, StartDate, EndDate,
	                      Name, Status, Legal_Contract_Line_Item__c, Product_Inventory__c,
	                      Do_Not_Renew__c from ServiceContract
	                      where Product_Inventory__c in :setassetids AND Status in ('Active', 'Inactive') ];
         
	     if(!lstrelatedsc.isEmpty())
	     { 
	       //system.debug('inside if lstrelatedsc is not empty ');
	       for(ServiceContract recsc : lstrelatedsc)
	       {
	       	 system.debug('inside service contract list for loop ');
	       	 if(legacynames.contains(recsc.Name) == true)
	       	 
	       	  //system.debug('in updatelegacyservicecontract line item in loop is ' +recsc.name);
	       	  	if(inactiveitemids.contains(recsc.Legal_Contract_Line_Item__c))
	       	  	{ recsc.EndDate = system.Today();
	       	  	  lstreturnsc.add(recsc);
	       	  	  //system.debug('inactivating servicecontract: ' +recsc.Name);
	       	  	}
	       	  	else
	       	  	{
	       	  	      recsc.StartDate = mpclitoconstartdate.get(recsc.Legal_Contract_Line_Item__c);
	       	  	      recsc.EndDate = mpclitoconenddate.get(recsc.Legal_Contract_Line_Item__c);
	       	  	      lstreturnsc.add(recsc); 
	       	  	  // system.debug('updating dates on service contract ' +scon.Name);
	       	  	}
	   
	       	 } //end for loop
	      } //end if lstrelatedsc is empty
      
  	   
	   	   system.debug('*******************************END UpdateLegacyServiceContracts ********************************');
	   	   
      return lstreturnsc;
	}//end UpdateLegacyServiceContracts	
	
	*/
/*shawks CPQ - comment group 02 start
	//jjackson 6/25/2014 BUG-00361 for Hilton, get install clock start dates from contract and add to work order
    public static void GetClockStartDate(Map<Id,Contract__c> mptriggerold, List<Contract__c> lsttriggernew){
    	   system.debug('***********************START GetClockStartDate *******************************');
    	   
       Set<Id> setlcid = new Set<Id>();
       Map<Id,Id> mplclitolc = new Map<ID,ID>();
       Map<Id,Id> mpoitolcli = new Map<ID,ID>();
       Map<Id,Id> mpaitooi = new Map<ID,ID>();
       Map<Id,Id> mpwotoai = new Map<ID,ID>();
       Map<Id,Date> mpftgstart = new Map<Id,Date>();
       Map<Id,Date> mpintstart = new Map<Id,Date>();
       Map<ID,ID> mpwotocon = new Map<ID,ID>();
       Boolean boostartclock;
       
       for(Contract__c reclc : lsttriggernew)
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
       	  List<Contract_Line_Item__c> lstlcli = new list <Contract_Line_Item__c>();
       	  lstlcli = [ Select ID, legal_contract__c from Contract_Line_Item__c where Legal_Contract__c in :setlcid ];
      	  if(!lstlcli.IsEmpty())
       	  {
       	  	for(Contract_Line_Item__c reclcli : lstlcli)
       	    {
       	  	  mplclitolc.put(reclcli.id,reclcli.legal_contract__c);
       	    }
       	    //system.debug('mplclitolc map is ' +mplclitolc);
       	  }
       	         	  
       	  List<Order_Item__c> lstorderitemid = new list<Order_Item__c>();
       	  lstorderitemid = [ Select ID, Legal_Contract_Line_Item__c from Order_Item__c where Legal_Contract_Line_Item__c in :mplclitolc.keyset()];
       	  //system.debug('lstorderitemid is ' +lstorderitemid);
       	  If(!lstorderitemid.IsEmpty())
          {
          	for(Order_Item__c recorderitem : lstorderitemid)
       	    {
       	  	  mpoitolcli.put(recorderitem.Id,recorderitem.Legal_Contract_Line_Item__c);
       	    }
       	    //system.debug('mpoitolcli map is ' +mpoitolcli);
          }
 
          List<Associated_Item__c> lstai = new list<Associated_Item__c>();
          lstai = [ Select Work_Order__c, Order_Item__c from Associated_Item__c where Order_Item__c in :mpoitolcli.keyset()];
          if(!lstai.IsEmpty())
          {
          	for(Associated_Item__c recai : lstai)
            {
          	  mpaitooi.put(recai.Work_Order__c,recai.Order_Item__c);
            }
          //  system.debug('mpaitooi map is ' +mpaitooi);
          }
   	  
      	  //go back and get the legal contract id and map to work order id
       	  List<Work_Order__c> lstupdwo = new list<Work_Order__c>();
       	  for(Id woid : mpaitooi.keyset())
       	    {
       	  	   mpwotocon.put(woid,mplclitolc.get(mpoitolcli.get(mpaitooi.get(woid))));
       	    }
       	    //system.debug('mpwotocon map is ' +mpwotocon);
       	    //now pull the work orders related to the contracts and set the ftg/interactive clock start dates
       	    
       	    
       	    List<Work_Order__c> lstworkorders = [Select Id, FTG_Contracted_Completion_Date__c, GP_Contracted_Completion_Date__c from Work_Order__c where Id in :mpwotocon.keyset()];
       	    for(Work_Order__c recwo : lstworkorders)
       	    {
       	    	Date ftgclockstart = mpftgstart.get(mpwotocon.get(recwo.id));
       	    	Date gpclockstart = mpintstart.get(mpwotocon.get(recwo.id));
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
       	    	   
       	    	
       	   		recwo.FTG_Contracted_Completion_Date__c = dtftgcontcompletion ;
       	    	recwo.GP_Contracted_Completion_Date__c = dtgpcontcompletion ;
       	    	lstupdwo.add(recwo);
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
      
      public static void SendGroupServicesEmail(List<Contract__c> triggernewlist, Map<Id,Contract__c> triggeroldmap)
      {
      	   system.debug('************** BEGIN SendGroupServicesEmail *********************');
			
		   Map<Id, Contract__c> mpcontracts = New Map<Id,Contract__c>();
		   
		   for(Contract__c con : triggernewlist)
		   {
		   	 if(con.status__c == 'Order Approved' && triggeroldmap.get(con.id).status__c != 'Order Approved')
		   	 {
		   	 	mpcontracts.put(con.Id,con); //create a map of contracts where status was changed to order approved
		   	 }
		   }      	   
      	   
		   if(mpcontracts.size() > 0) //if there are contract ids in the set, query for group services line items
		   {
		   	 
		   	 	List<Contract_Line_Item__c> listlcli = New List<Contract_Line_Item__c>();
		   	 	listlcli = [ Select Id, Name, legal_contract__r.name, legal_contract__r.account_name__r.name, legal_contract__r.id, product__r.productcode, status__c from Contract_Line_Item__c where
		   	 	             legal_contract__c in :mpcontracts.keyset() AND product__r.productcode like 'CC-330040%' AND
		   	 	             status__c = 'Pending Installation Activate' ];
		   	 	             
		   	 	if(listlcli.size() > 0)
		   	 	{
		   	 		//shawks: CPQ - comment out method call 
		   	 		//EmailUtilities.GroupServicesNotification(listlcli);
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
END OF CPQ - comment group 02*/
}