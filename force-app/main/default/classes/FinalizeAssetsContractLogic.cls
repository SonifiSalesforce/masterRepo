public with sharing class FinalizeAssetsContractLogic {
	
	public static map<String,List<Marina_Service_Mod_Mapping__c>> mpmods = New Map<String,List<Marina_Service_Mod_Mapping__c>>();
	
	//for the map passed in that contains subscriptions with no linked product inventory,
	//create product inventory lines, create marina modules, and parent the product inventory lines
	public static string CreateNewAssets(Map<Id,SBQQ__Subscription__c> mpcreatenewassets, Contract con)
	{
		system.debug('**************BEGIN CreateNewAssets*****************');
		
		system.debug('mpcreatenewassets size is ' +mpcreatenewassets.size());
		for(Id key :mpcreatenewassets.keyset())
		{
			SBQQ__Subscription__c sub = mpcreatenewassets.get(key);
			//system.debug('subscription is ' +sub.name__c +',' +con.id);
		}
		
		String resultstring = '';
		List<Asset> lstnewasset = New List<Asset>();
		List<Asset> lstaddparent = new List<Asset>();
		Map<Id, id> mpparenting = New Map<Id, id>();
		List<SBQQ__Subscription__c> lstupdatesub = New List<SBQQ__Subscription__c>();
		mpmods = CreateMarinaModMap();  //create a map of the custom setting Marina Service Mod Mapping

		//create a new asset record for each subscription
		for(Id subid : mpcreatenewassets.keyset())
		{
			//system.debug('inside loop mpcreatenewassets keyset');
			
			SBQQ__Subscription__c sub = New SBQQ__Subscription__c();
			sub = mpcreatenewassets.get(subid);
			Asset astRec = New Asset();
			astRec.subscription_item__c=sub.id;
            astRec.AccountId=sub.sbqq__account__c;
            astRec.Product2Id=sub.sbqq__product__c;
            system.debug('subscription accountid is ' +sub.sbqq__product__c);
            astRec.Name=sub.sbqq__product__r.name;
            astRec.Status=sub.status__c;
            astRec.Marina_Resource_Ratio__c=sub.Marina_Resource_Ratio__c;
            astRec.Fee_Schedule__c=sub.Fee_Schedule__c;
            astRec.Platform__c=sub.Platform__c;
            astRec.Term_Start_Date__c=sub.sbqq__startdate__c;
            astRec.Term_End_Date__c=sub.sbqq__enddate__c;
            astRec.Auto_Renew__c=con.Auto_Renew__c;
            astRec.Contract_Type__c=con.Contract_Type__c;
            astRec.Renewal_Term__c=con.sbqq__renewalterm__c;
            astRec.Renewal_Cycle__c=con.Renewal_Cycle__c;
            astRec.Company_Code__c=con.Company_Code__c;
            astRec.Term__c=con.ContractTerm;
            astrec.Contract__c=con.Id;
            astrec.Quantity = sub.sbqq__quantity__c;
            astrec.Price__c = sub.sbqq__regularprice__c;
            lstnewasset.add(astRec);
     
		}
		
		if(lstnewasset.size() > 0 )
		{
			Savepoint sp = Database.setSavepoint();
			try{  insert lstnewasset;  }
			catch(Exception e)
			{
				Database.rollback(sp);
				resultstring = 'Error in Create New Assets: ' +e.getmessage();

			}
		}
		
		//query for all the assets just created and make marina modules where necessary
		List<Asset> lstassets = New List<Asset>();
		lstassets = [ Select Id, name, product2.productcode, contract__c, parent_asset__c,
		              subscription_item__c from Asset  //changed from subscription__c
		              where contract__c = :con.id  ];
		
		Set<Id> setaid = new Set<Id>();              
		for(Asset a : lstassets)
		{
			setaid.add(a.id);
			
			if(mpcreatenewassets.containskey(a.subscription_item__c))  //changed from subscription__c
			{
				SBQQ__Subscription__c subscrip = mpcreatenewassets.get(a.subscription_item__c);  //changed from subscription__c
				subscrip.product_inventory__c = a.id;
				lstupdatesub.add(subscrip);
			}
		}
		
		//from the product inventory id's, query for existing marina modules related to product inventory records
		List<Marina_Module__c> lstmm = New List<Marina_Module__c>();
		lstmm= [Select Id, product_inventory__c from Marina_Module__c where product_inventory__c in :setaid];
		
		//collect the ids of product inventory recs that are already have modules for them
		Set<Id> assetswithmodules = New Set<Id>();
		for(Marina_Module__c m :lstmm)
		{  assetswithmodules.add(m.product_inventory__c); }
		
		
		//if the asset record productcode is a mpmod key but the asset's id is not in the set of asset ids
		//that already have existing marina modules, add the asset record to lstneedmods to have marina modules created.
		List<Asset> lstneedmods = new List<Asset>();
		for(Asset a :lstassets)
		{
			if(mpmods.containskey(a.product2.productcode) && !assetswithmodules.contains(a.id))
			{
				lstneedmods.add(a);
			}
		}
		
		system.debug('lstneedmods size is ' +lstneedmods.size());
		
		if(lstneedmods.size() > 0)  
		{  resultstring += CreateMarinaModuleRecords(lstneedmods);  }
	
		system.debug('resultstring after CreateMarinaModules = ' +resultstring);
	
		//make a map that matches subscription id to asset id
		for(Asset a : lstassets)
		{  mpparenting.put(a.subscription_item__c, a.id); }  //changed from subscription__c
	
		//now add parenting to the asset records
		for(Asset asst :lstassets)
		{
			//system.debug('inside the loop to create asset parenting');
			
			if(!asst.name.contains('Product Parent') && mpcreatenewassets.containskey(asst.subscription_item__c)) //changed from subscription__c
			{
				Id subparentid = mpcreatenewassets.get(asst.Subscription_item__c).parent__c;  //chaned from subscription__c
				
				if(mpparenting.containskey(subparentid))
				{
					Id parentid = mpparenting.get(subparentid);
					asst.parent_asset__c = parentid;
					lstaddparent.add(asst);
				}
				
			}
		}//end for loop lstassets

		Savepoint svp = Database.setSavepoint();

		if(lstaddparent.size() > 0)
		{

			try{  update lstaddparent;  }
			catch(Exception ex)
			{   Database.rollback(svp);
				resultstring += 'Error adding parent id to asset:  ' +ex.getMessage(); }
		}
		
		if(lstupdatesub.size() > 0)
		{
			try{ update lstupdatesub;  }
			catch(Exception e)
			{	Database.rollback(svp);
				resultstring += 'Error updating asset id on subscription: ' +e.getMessage(); 
			}
		}
		
		if(!resultstring.contains('Error'))
		{ resultstring += 'New product inventory lines were created successfully.' +'\n'; }
		
		system.debug('*****************END CreateNewAssets****************');
		
		return resultstring;
	}//end Createnewassets
	
	
	//for the map passed in that contains subscriptions already linked to product inventory lines,
	//verify marina modules are created, and make sure certain values in the product inventory match
	//what's in the subscription items
	public static string UpdateExistingAssets(Map<Id,SBQQ__Subscription__c> mpupdateassets, Contract con)
	{
		system.debug('********************BEGIN UpdateExistingAssets****************');
		
		system.debug('mpupdateassets size in UpdateExistingAssets is ' +mpupdateassets.size());
	

		String resultstring = '';
		List<Asset> lstexistingasset = new List<Asset>();
		List<Marina_Module__c> lstmod = new List<Marina_Module__c>();
		Map<Id,List<Marina_Module__c>> mpmodules = New Map<Id,List<Marina_Module__c>>();
		List<Asset> lstneedsmods = New List<Asset>();
		List<SBQQ__Subscription__c> lstsubs = New List<SBQQ__Subscription__c>();
		List<SBQQ__Subscription__c> lstnewasset = New List<SBQQ__Subscription__c>();
		List<Asset> lstupdateasset = New List<Asset>();
		Set<Id> assetids = New Set<Id>();
		String conrectype = Utilities.RecordTypeIdToName('Contract', con.recordtypeid);
		Set<Id> setassetid = New Set<Id>(); //collect the product codes on all the asset records
		Set<Id> setassetswithmods = new Set<Id>(); //collect the asset ids that already have marina modules related to them
		Set<Id> setexistingpiids = New Set<Id>();
		
		//get all the subscription records out of the map and look for any that don't have assets linked to them
		lstsubs = mpupdateassets.values();
		for(SBQQ__Subscription__c s :lstsubs)
		{
			if(s.product_inventory__c == null)
			{  lstnewasset.add(s); }
			else
			{ setexistingpiids.add(s.product_inventory__c); }
		}
		
		if(mpmods.size() < 1)
		{ mpmods = CreateMarinaModMap(); }
		
		
		system.debug('mpmods size is ' +mpmods.size());
		
		//query for a list of all the product inventory lines related to the subscriptions along with related marina modules
		//check whether contract record type is contract amendment.  If so we have to query for existing assets related to the subscription
		//items in the contract amendment.  We can't query based on pi existing subscription id because that is for the original subscription item, not the amendment items
		if(conrectype != 'Contract Amendment')
		{
			lstexistingasset = [ Select name, status, marina_resource_ratio__c, fee_schedule__c, platform__c, term_start_date__c, product2.productcode,
		                     term_end_date__c, auto_renew__c, renewal_term__c, renewal_cycle__c, company_code__c, subscription_item__c, product2.name,  //changed from subscription__c
		                     term__c, quantity, price__c, id from Asset where subscription_item__c in :mpupdateassets.keyset() ];  //changed from subscription__c
		}
		else
		{
			lstexistingasset = [ Select name, status, marina_resource_ratio__c, fee_schedule__c, platform__c, term_start_date__c, product2.productcode,
		                     term_end_date__c, auto_renew__c, renewal_term__c, renewal_cycle__c, company_code__c, subscription_item__c, product2.name,  //changed from subscription__c
		                     term__c, quantity, price__c, id from Asset where id in :setexistingpiids ];
		}
              
		system.debug('lstexistingasset size is ' +lstexistingasset.size());
	
		for(Asset a : lstexistingasset)
		{
			setassetid.add(a.id);
		}
		
		lstmod = [Select id, product_inventory__c, product_inventory__r.name from Marina_Module__c where product_inventory__c in :setassetid ];
		
		system.debug('lstmod size related to the assets in lstexisting asset is ' +lstmod.size());
		for(Marina_Module__c mm : lstmod)
		{  //system.debug('existing mods are for ' +mm.product_inventory__r.name); 
		   setassetswithmods.add(mm.product_inventory__c);
		}
		

		
			
		//loop through the asset list and check whether the related part number matches a key in mpmods.  If there is a match,
		//the assetid should be a key in mpmodules.  If it's in mpmods but not mpmodules, make a new marina module
	  if(conrectype != 'Contract Amendment')
	  {
		for(Asset astRec : lstexistingasset)
		{	
			
			
			if(mpmods.containskey(astRec.product2.productcode) && !setassetswithmods.contains(astRec.id))
			{
				lstneedsmods.add(astRec);
				//system.debug('asset added to lstneedsmods is ' +astRec.name);
			}
			
			

			//declare a blank subscription
			SBQQ__Subscription__c sub = New SBQQ__Subscription__c();
			
			//if the subscription map contains the subscription id from the asset record,
			//update the asset
			if(mpupdateassets.containskey(astRec.subscription_item__c))   //changed from subscription__c
			{
				sub = mpupdateassets.get(astRec.subscription_item__c);  //changed from subscription__c
				
			}
			
			//if the value of sub is empty, that means no asset has that subscription id on it and we need a new asset
			//if the sub id is found in the map, that means we just need to update the asset
			if(sub != null)
			{
				//system.debug('updating asset record for ' +astRec.name);
				
				astRec.Status=sub.status__c;
            	astRec.Marina_Resource_Ratio__c=sub.Marina_Resource_Ratio__c;
            	astRec.Fee_Schedule__c=sub.Fee_Schedule__c;
            	astRec.Platform__c=sub.Platform__c;
            	astRec.Term_Start_Date__c=sub.sbqq__startdate__c;
            	astRec.Term_End_Date__c=sub.sbqq__enddate__c;
            	astRec.Auto_Renew__c=con.Auto_Renew__c;
            	astRec.Contract_Type__c=con.Contract_Type__c;
            	astRec.Renewal_Term__c=con.sbqq__renewalterm__c;
            	astRec.Renewal_Cycle__c=con.Renewal_Cycle__c;
            	astRec.Company_Code__c=con.Company_Code__c;
            	astRec.Term__c=con.ContractTerm;
            	astrec.Quantity = sub.sbqq__quantity__c;
            	astrec.Price__c = sub.sbqq__regularprice__c;
            	
				lstupdateasset.add(astRec);
			}
	
		}//end for loop lstexistingasset
	  }
	  else
	  {    lstupdateasset = UpdateAmendmentProductInventory(lstexistingasset, con);  }
		
		system.debug('lstnewasset size is ' +lstnewasset.size());
		system.debug('lstupdateasset size is ' +lstupdateasset.size());
			
		
		//update existing assets
		if(lstupdateasset.size() > 0)
		{
			Savepoint sp = Database.setsavepoint();
			try{ update lstupdateasset; }
			catch(Exception e)
			{
				Database.rollback(sp);
				resultstring += 'Error updating assets line 233: ' +e.getmessage();
			}
		}
		
		
		//create new assets where needed
		if(lstnewasset.size() > 0)
		{
			Map<Id,SBQQ__Subscription__c> mpneedassets = New Map<Id, SBQQ__Subscription__c>();
			
			//add the list of subscription records to the map
			for(SBQQ__Subscription__c s :lstnewasset)
			{  mpneedassets.put(s.id, s); }
			
			resultstring += CreateNewAssets(mpneedassets, con); //pass in a map of subscription lines & contract
			
		}
		
		//create marina modules on any assets that don't have them
		if(lstneedsmods.size() > 0)
		{
			resultstring += CreateMarinaModuleRecords(lstneedsmods);
		}
		               
		if(!resultstring.contains('Error'))
		{  resultstring = 'Product inventory lines were updated successfully.'; }
		
		system.debug('****************END UpdateExistingAssets*************');
		
		return resultstring;
	}//end UpdateExistingAssets
	
	public static List<Asset> UpdateAmendmentProductInventory(List<Asset> lstassets, Contract c)
	{
		List<Asset> lstupdatepi = New List<Asset>();
		List<SBQQ__Subscription__c> sublist = New List<SBQQ__Subscription__c>();
		Map<Id, SBQQ__Subscription__c> mpsub = new Map<Id, SBQQ__Subscription__c>();
		Set<Id> setassetid = New Set<Id>();
		
		for(Asset a : lstassets)
		{  setassetid.add(a.id);  }
		
		sublist = [ Select Id, product_inventory__c, sbqq__contract__c, sbqq__product__c, sbqq__product__r.name,
		            status__c, sbqq__quantity__c, sbqq__account__c, parent__c from SBQQ__Subscription__c where product_inventory__c in :setassetid
		            and sbqq__contract__c = :c.id ];
		
		for(sbqq__Subscription__c s : sublist)
		{  mpsub.put(s.product_inventory__c, s);  }
		
		for(Asset ass : lstassets)
		{
			SBQQ__Subscription__c sub = New SBQQ__Subscription__c();
			if(mpsub.containskey(ass.id))
			{  sub = mpsub.get(ass.id);  }
			
			ass.contract__c = sub.sbqq__contract__c;
			ass.subscription_item__c = sub.id;  //changed from subscription__c
			ass.quantity = sub.sbqq__quantity__c;
			ass.status = sub.status__c;
			
			lstupdatepi.add(ass);
		
		}
		
		return lstupdatepi;
	}
	
	public static Map<String,List<Marina_Service_Mod_Mapping__c>> CreateMarinaModMap()
	{
		system.debug('***************BEGIN CreateMarinaModMap**************');
		
		List<Marina_Service_Mod_Mapping__c> lstmods = Marina_Service_Mod_Mapping__c.getall().values();
		
		//for(Marina_Service_Mod_Mapping__c m :lstmods)
		//{ system.debug('marina mod is ' +m.marina_module_description__c +',' +m.marina_service_module__c); }
		
		
		Map<String,List<Marina_Service_Mod_Mapping__c>> modmap = New Map<String,List<Marina_Service_Mod_Mapping__c>>();
		
		for(Marina_Service_Mod_Mapping__c mod : lstmods)
		{
			if(mod.marina_module_description__c != null || mod.marina_service_module__c != null)	
			{
				if(modmap.size() > 0 && modmap.containskey(mod.part_number__c))
				{  modmap.get(mod.part_number__c).add(mod);  }
				else
				{
					List<Marina_Service_Mod_Mapping__c> templist = New List<Marina_Service_Mod_Mapping__c>();
					templist.add(mod);
					modmap.put(mod.part_number__c,templist);
				}
			}
		}//end for loop
		
		system.debug('****************END CreateMarinaModMap*******************');
		
		return modmap;
	}//end CreateMarinaModMap
	
	
	public static string CreateMarinaModuleRecords(List<Asset> lstassets)
	{
		system.debug('**************BEGIN CreateMarinaModuleRecord****************');
		
		List<Marina_module__c> lstinsertmods = new List<Marina_module__c>();
		String resultstring = '';

	    //create the map of marina modules from the custom setting
		if(mpmods.size() < 1)
		{  mpmods = CreateMarinaModMap(); }
		
		system.debug('mpmods size is ' +mpmods.size());
		
		//loop through the list of new assets and compare the asset productcode value to the
		//marina module part number value (the marina part number value is the map key).  Wherever there is a match, create a marina module
		//record and relate it to the asset record.
		for(Asset a :lstassets)
		{
			//system.debug('asset getting a new marina module is ' +a.name +', ' +a.product2.productcode);
			
			if(mpmods.containskey(a.product2.productcode))
			{
				List<Marina_Service_Mod_Mapping__c> lstmod = New List<Marina_Service_Mod_Mapping__c>();
				lstmod = mpmods.get(a.product2.productcode);
				
				for(Marina_Service_Mod_Mapping__c mod :lstmod)
				{
					//system.debug('mod marina service module is ' +mod.marina_service_module__c);
					//system.debug('mod module description is ' +mod.marina_module_description__c);
					
					Marina_Module__c newmod = New Marina_Module__c();
					newmod.name = mod.marina_service_module__c +'-' +mod.marina_module_description__c;
					newmod.marina_module_description__c = mod.marina_module_description__c;
					newmod.marina_service_module__c = mod.marina_service_module__c;
					newmod.product_inventory__c = a.id;
					lstinsertmods.add(newmod);
					
					///system.debug('new marina module create is ' +newmod.name);
				}
			}//end if mpmods containskey
		}//end for loop assets
		
		system.debug('lstinsertmods size is ' +lstinsertmods.size());
		
		if(lstinsertmods.size() > 0)
		{
			try{ insert lstinsertmods; }
			catch(Exception e)
			{  resultstring = 'Error in CreateMarinaModuleRecords: ' +e.getmessage(); }
		}
		
		if(resultstring == null)
		{  resultstring += 'Marina modules created successfully. ' +'\n'; }
		
		system.debug('****************END CreateMarinaModuleRecords***************');
		
		return resultstring;
		
	}//end Createmarinamodulerecords
	
  
  public static string CreateExtendedWarrantyServiceContract(List<SBQQ__Subscription__c> sublist, Contract con)
  {
     
	Map<Id,Id>  mpextwarranty2prodinvparent = New Map<Id,Id>();
	Map<Id,SBQQ__Subscription__c> mpextwarrsubs = New Map<Id,SBQQ__Subscription__c>();
	Set<Id> prodparentassetids = New Set<Id>();
	String resultstring = '';

	Savepoint sp = Database.setSavepoint();
	
	for(SBQQ__Subscription__c sub : sublist)
	{
		if(sub.sbqq__product__r.name.contains('Extended Warranty'))
		{
			mpextwarranty2prodinvparent.put(sub.id, sub.parent__r.product_inventory__c);
			mpextwarrsubs.put(sub.id, sub);
			prodparentassetids.add(sub.parent__r.product_inventory__c);
			//system.debug(sub.parent__r.product_inventory__c +' was added to prodparentassetids');
		}
	}
	system.debug('mpextwarranty2prodinvparent size is ' +mpextwarranty2prodinvparent.size());
	system.debug('mpextwarrsubs size is ' +mpextwarrsubs.size());
	
	
	//if the product inventory parents are related to existing service contracts,
	//query for existing service contracts that are active and end them
	List<ServiceContract> lstactivesc = New List<ServiceContract>();
	List<ServiceContract> lstendsc = New List<ServiceContract>();
	lstactivesc = [ Select Id, Status, startdate, product_inventory__c, enddate from ServiceContract where product_inventory__c in :prodparentassetids and Status = 'Active' ];
	system.debug('lstactivesc size is ' +lstactivesc.size());
	Date endnow = system.today().adddays(-1);
	
	
	
	for(ServiceContract sc :lstactivesc)
	{   
		//system.debug('startdate is ' +sc.startdate);
		//system.debug('enddate is ' +sc.enddate);
		sc.enddate = endnow;
		lstendsc.add(sc);
	}
	
    update lstendsc;
	
	Map<Id,Entitlement> mpentitlement = New Map<Id,Entitlement>();
	List<Asset> lstgetrelatedent = New List<Asset>();
	lstgetrelatedent = [ Select Accountid, Status, Id, (Select Assetid, Id, ServiceContract.Id, Accountid, Subscription__c, 
	                     startDate, Enddate, Status from Entitlements where Status = 'Active') from Asset where id in :prodparentassetids ];
	
	for(Asset pi  :lstgetrelatedent)
	{
	
		for(Entitlement ent : pi.entitlements)
		{
		    if(ent.status == 'Active')
			{	mpentitlement.put(ent.assetid, ent);  }
			
		}
	
	}
	
	if(mpentitlement.size() > 0 || !mpentitlement.isempty())
	{
		List<ServiceContract> lstinsert = New List<ServiceContract>();
		for(Id subid : mpextwarrsubs.keyset())
		{
			SBQQ__Subscription__c sub = New SBQQ__Subscription__c();
			sub = mpextwarrsubs.get(subid);
			//system.debug('subid inside loop is ' +subid);
			
			ServiceContract sc = New ServiceContract();
		
			sc.name = sub.sbqq__product__r.name;
			sc.accountid = sub.sbqq__account__c;
			sc.subscription__c = sub.id;
			sc.startdate = con.extended_warranty_start_date__c;
			sc.term = 1;
			sc.enddate = con.extended_warranty_start_date__c.addMonths(1);
			sc.product_inventory__c = sub.parent__r.product_inventory__c;
		
			lstinsert.add(sc);
		}
		
        system.debug('lstinsert size is ' +lstinsert.size());
		
		if(lstinsert.size() > 0)
		{  
			try{  insert lstinsert;  }
			catch(Exception ex)
			{
			     resultstring = 'ERROR inserting Extended Warranties line 66: ' +ex.getmessage();  
			     system.debug(resultstring);
			     Database.rollback(sp);
			  
			}
				
			//query for the new Service Contract id's so they can be linked to entitlements
			List<ServiceContract> lstnewsc = New List<ServiceContract>();
			List<Entitlement> lstupdent = New List<Entitlement>();
			lstnewsc = [ Select Id, product_inventory__c, subscription__c, status from ServiceContract where subscription__c in :mpextwarrsubs.keyset() AND status = 'Active' ];
			
			system.debug('lstnewsc size is ' +lstnewsc.size());
			for(ServiceContract s : lstnewsc)
			{
				if(mpextwarranty2prodinvparent.containskey(s.subscription__c))
				{
					Id assetid = mpextwarranty2prodinvparent.get(s.subscription__c);
					
					if(mpentitlement.containskey(assetid))
					{
						Entitlement e = mpentitlement.get(assetid);
						e.servicecontractid = s.id;
						lstupdent.add(e);
											
					}
					
				}
			}
			
			system.debug('lstupdent size is ' +lstupdent.size());
			
			if(lstupdent.size() > 0)
			{
				try{  update lstupdent;  }
				catch(Exception exc)
				{
					resultstring = 'ERROR updating existing entitlements line 112: ' +exc.getmessage();
					system.debug(resultstring);
					Database.rollback(sp);
					
				}
			
			}

		}//end if lstinsert > 0

	}//end if mpentitlement size > 0      
	
	  	return resultstring;
                         
  }//end of createextendedwarrantyservicecontract class
    
}//end class finalizeassetscontractlogic