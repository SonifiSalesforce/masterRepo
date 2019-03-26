public with sharing class CustomContractLogicforCPQ {
	/*
		jjackson Jan 2019--Created for the CPQ project to take the place of the old CustomContractLogic.
		There is no test class for this because the code is covered at 83% by other test classes:
		OpportunityProgrammingHierarchyTest
		AccountAssetHierarchyTest
	*/
	public static string createSubscriptionItems(List<Id> assets, Id contractId){
        //initialize variables
        String returnstring = null;
        SBQQ__Subscription__c subitem = new SBQQ__Subscription__c();
        List<Asset> assetList = new List<Asset>(); // holds the List of the assets passed into the method
        List<SBQQ__Subscription__c> lstinsertsubs = New List<SBQQ__Subscription__c>();
        List<SBQQ__Subscription__c> cLIList = new List<SBQQ__Subscription__c>(); //holds the SBQQ__Subscription__c that are currently attached to the contract
        List<SBQQ__Subscription__c> insertList = new List<SBQQ__Subscription__c>(); //insert list for SBQQ__Subscription__c
        List<SBQQ__Subscription__c> insertedCLIList = new List<SBQQ__Subscription__c>(); //requeried list of SBQQ__Subscription__c that will be updated with the parent SBQQ__Subscription__c
        List<Integer> removeCLI = new List<Integer>(); // list of integers (position of the cli in the insert list) that already have been created and need to be removed before CLI are inserted
        Set<Id> productIds = new Set<Id>(); // set of the product ids so that mulptiple CLIs are not created on the same contract
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        Set<Id> newCLIIds = new Set<ID>();
        Map<Id, Id> assetId2CLIIdMap = new Map<Id, Id>();
        Boolean needsqty = false;
        
        //get the fields that need to be queried
        //String fieldAssetQuery = String.join( Utilities.getSObjectFields(Asset.getSobjectType()) ,',');
        //make the query for the asset ids
        //String assetIds = '';
        Set<Id> assetids = New Set<Id>();
        for(String a : assets){
            //assetIds += ',\'' + a + '\'';
            assetids.add(a); 
            system.debug('asset id added to set assetids is ' +a);  
        }

        SObjectType assettype = Schema.getGlobalDescribe().get('Asset');
        Map<String,Schema.SObjectField> mpassetfields = assettype.getDescribe().fields.getMap();
        String querystring = '';
        for(String key :mpassetfields.keyset()) //the string key is the api name of the assetfield
        { querystring += ', ' +key; }
        String subquerystring = querystring.substringAfter(',');
        assetlist = Database.query('Select ' +subquerystring +',  Product2.Name from Asset Where Id in :assetids');
        system.debug('assetlist size is ' +assetlist.size());
  
        //loop through assets check for quantity before creating new subscriptions
        for(Asset a : assetList){
 
            if(a.Quantity == null || a.Quantity < 1)
            {
            	needsqty = true;
            	returnstring += 'Product Inventory ' +a.name +' must have a quantity greater than zero.';
            }
        }
        
        if(needsqty == false)     
        {  lstinsertsubs = CreateSubscriptions(assetlist, contractId);  }  
  
        // SYstem.debug('SBQQ__Subscription__c insert list before removing duplicates:: ' + insertList);
        
        //once we have new subscription line items, finish the code.  if there are none,
        //return returnstring error message to the controller extension class
        if( lstinsertsubs.size() > 0)
        {
        	//query for the CLI already on the contract
        	cLIList = [SELECT id, SBQQ__Product__c, SBQQ__Product__r.Name, Parent__c, Product_Inventory__c, SBQQ__Contract__c FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c =:contractId];
        	//System.debug('CLI already on contract are ' + cLIList);
        
           if(cLIList.size() > 0)
           {	
        	//make a set of products so that duplicates can be removed
        	for(SBQQ__Subscription__c cli : cLIList){
            	productIds.add(cli.SBQQ__Product__c);
            	assetId2CLIIdMap.put(cli.Product_Inventory__c, cli.id);
            	//system.debug('products set for removal are ' +cli.SBQQ__product__r.name);
        	}
        
        	        
        	//loop through lstinsertsubs and remove any items where product is in set productIds
        	for(integer i = 0; i < lstinsertsubs.size(); i++){
            	if(productIds.contains(insertList[i].SBQQ__Product__c)){
                	removeCLI.add(i);
                	system.debug('removed cli with product ' +insertList[i].name +'index num ' +i);
            	}
        	}
 
        	//loop through removeCli and remove list items from insertList
        	for(integer i = removeCLI.size()-1; i >= 0; i--){
            	lstinsertsubs.remove(i);
            	system.debug('line item removed from insert list is ' +i);
        	}
 
           }//end if cLIList > 0
           
 			//if there are any subscription items in the list after removing duplicates, insert them
        	if(lstinsertsubs.size() > 0){
              try{
                	saveResults = Database.insert(lstinsertsubs);
                
                	for(Database.SaveResult result : saveResults)
                	{
                    	newCLIIds.add(result.getId());
                	}
            	} 
            	catch(Exception e){  
                  returnstring += e.getMessage();
                }
           } //end if lstinsertsubs.size
  
         //requery for the SBQQ__Subscription__c.  This must be done to parent the new subscription items
        insertedCLIList = [SELECT id, SBQQ__Product__c, Parent__c, Product_Inventory__c, Product_Inventory__r.Parent_Asset__c FROM SBQQ__Subscription__c WHERE Id IN :newCLIIds];
        
        System.debug('SBQQ__Subscription__c after insert:: ' + insertedCLIList.size());
        
        //loop through list and map (assetId2CLIIdMap) Product_Inventory__c to SBQQ__Subscription__c id
        for(SBQQ__Subscription__c cli : insertedCLILIst){
            assetId2CLIIdMap.put(cli.Product_Inventory__c, cli.id);
        }
        
        System.debug('full map of asset id to cli ' + assetId2CLIIdMap.size());
        
        //loop through insertCLIList and put the correct parent for the SBQQ__Subscription__c
        for(SBQQ__Subscription__c cli : insertedCLIList){
            //System.debug('Asset parent id ' + cli.Product_Inventory__r.Parent_Asset__c);
            if(cli.Product_Inventory__r.Parent_Asset__c != null)
            {
            	if(assetId2ClIIdMap.containskey(cli.Product_Inventory__r.Parent_Asset__c))
                { cli.Parent__c = assetId2CLIIdMap.get(cli.Product_Inventory__r.Parent_Asset__c); }
                else
                {  system.debug('There is no parent asset for ' +cli.product_inventory__r.name);  }
            }
        }

        update insertedCLIList;
     
     }//end if lstinsertsubs.size
        
        return returnstring;
    }
    
    public static list<SBQQ__Subscription__c> CreateSubscriptions(List<Asset> lstasset, Id conid)
    {
    	List<SBQQ__Subscription__c> insertlist = New List<SBQQ__Subscription__c>();
 
    	
    	for(Asset a : lstasset)
    	{   	
    		SBQQ__Subscription__c subitem = new SBQQ__Subscription__c();
            
            //set the fields
            subitem.SBQQ__Product__c = a.Product2Id;
            subitem.Product_Inventory__c = a.id;
            subitem.SBQQ__Contract__c = conid;
            //subitem.Name__c = a.Product2.Name;  undo
            subitem.Marina_Resource_Ratio__c = a.Marina_Resource_Ratio__c;
            subitem.Platform__c = a.Platform__c;
            subitem.Fee_Schedule__c = a.Fee_Schedule__c;
            subitem.CurrencyIsoCode = a.CurrencyIsoCode;
            subitem.Contract_Type__c = a.Contract_Type__c;
            subitem.SBQQ__RegularPrice__c = a.Price__c;
            subitem.SBQQ__Quantity__c = a.Quantity;
            subitem.Status__c = a.Status;
            subitem.sbqq__account__c = a.AccountId;
            //add cli to the insert list
            insertList.add(subitem);
    	
    	}
    	
    	return insertList;
    
  }

    //Create Subscriptions from Opportunity Programming Lines - Used with SPT (should not be needed with CPQ)
    public static void createSubscriptionsFromOpportunity(List<Id> programmingIds, Id contractId, Id opportunityId, Id AccountId, Boolean append)
    {
    //  system.debug('programming ids '+programmingIds + ' contractid '+contractId);
        //initialize variables
        SBQQ__Subscription__c subscriptionRec = new SBQQ__Subscription__c();
        //Map objects to maintain parent relationship
        Map<Id,Id> programmingParentMap = new Map<Id,Id>();  //map of programming to its parent if it exists
        List<Programming__c> pList = new List<Programming__c>(); // holds the List of the OLI passed into the method
        Map<Id,SBQQ__Subscription__c> programmingToSubMap = new Map<Id,SBQQ__Subscription__c>();
        List<Asset> assetList = new List<Asset>(); //List of assets to be inserted with new Subscriptions
        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>(); //holds the SBQQ__Subscription__c that are currently attached to the contract
        List<SBQQ__Subscription__c> insertList = new List<SBQQ__Subscription__c>(); //insert list for SBQQ__Subscription__c
        List<SBQQ__Subscription__c> insertedSubList = new List<SBQQ__Subscription__c>(); //requeried list of SBQQ__Subscription__c that will be updated with the parent SBQQ__Subscription__c

        List<Integer> removeSub = new List<Integer>(); // list of integers (position of the Sub in the insert list) that already have been created and need to be removed before Subs are inserted
        Set<Id> productIds = new Set<Id>(); // set of the product ids so that mulptiple Subs are not created on the same contract
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        Set<Id> newSubIds = new Set<ID>();
        Map<Id, Id> SubId2SubIdMap = new Map<Id, Id>();
        
        //Query Programming object
        pList = [SELECT ProductName__c, Qty__c, Price__c, Product__c, Parent__c, Total__c, Opportunity__r.AccountId from Programming__c WHERE Id IN :programmingIds];
        
        //Populate map of Parents
        for(Programming__c p : pList)
        {
          if(p.Parent__c != null)
            programmingParentMap.put(p.Id, p.Parent__c);
        }
        System.debug('OLI list is ' + pList);
        
        //loop through assets and make Subs and add them to insertList
        //jjackson 4/2016--BUG-00411
        for(Programming__c p : pList)
        {
          if(p.Qty__c == null || p.Qty__c == 0)
          {
            String errorstring = p.ProductName__c +' has an incorrect quantity.  Correct the quantity to be greater than 0.';
            throw new Exceptions.UnsupportedOperationException(errorstring);
          }
          else
          {
              //initialize var
              subscriptionRec = new SBQQ__Subscription__c();
              //set the fields
              subscriptionRec.SBQQ__Product__c = p.Product__c;
              // lookup to OLI needed?
              subscriptionRec.SBQQ__Contract__c = contractId;
              subscriptionRec.SBQQ__Account__c = AccountId;
              //subscriptionRec.Name__c = p.ProductName__c;  undo
              subscriptionRec.SBQQ__Quantity__c = p.Qty__c;
              subscriptionRec.SBQQ__RegularPrice__c  = p.Price__c;
              programmingToSubMap.put(p.Id,subscriptionRec);
              //add Sub to the insert list
              insertList.add(subscriptionRec);
            }
         }
        //Update contract with Opportunity reference
        Contract contractRec = new Contract();
        contractRec.Id = contractId;
        contractRec.SBQQ__Opportunity__c = opportunityId;

        //Query for the Sub already on the contract
        //cLIList = [SELECT id, Account__c, Product__c, Parent__c, Product_Inventory__c, Legal_Contract__c FROM Contract_Line_Item__c WHERE Legal_Contract__c =:contractId];
        subList = [SELECT id, SBQQ__Account__c, SBQQ__Product__c, Parent__c, Product_Inventory__c, SBQQ__Contract__c FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c =:contractId];
    //Set Savepoint
    Savepoint sp = Database.setSavepoint();
    try
    {
      if(append == false)
      {
        delete subList;
      }
      insert insertList;  
      update contractRec;
    }
    catch(Exception e)
    {
      system.debug('Exception in updating contract: '+e.getMessage());
      Database.rollback(sp);
    }
    
    //Create Asset on Subscription after insert
    for(SBQQ__Subscription__c sub : insertList)
    {
      Asset tempAsset = new Asset();
      tempAsset.AccountId = pList[0].Opportunity__r.AccountId;
      tempAsset.Status = 'Draft';
      tempAsset.Name = sub.Name;
      assetList.add(tempAsset);
    }
    
    //Update Assets
    for(Integer i = 0; i < insertList.size(); i++)
    {
      insertList.get(i).Product_Inventory__c = assetList.get(i).Id;
    }
    try
    {
      update insertList;
    }
    catch(Exception e)
    {
      system.debug(e.getMessage());
    }

    //Setup parents on Subscription
    List<SBQQ__Subscription__c> updateList = new List<SBQQ__Subscription__c>();
    for(Id pId : programmingIds)
    {
      if(programmingParentMap.containsKey(pId))
      {
        Id parentProgrammingId = programmingParentMap.get(pId);
         SBQQ__Subscription__c tempSub = programmingToSubMap.get(pId);
        SBQQ__Subscription__c tempSubParent = programmingToSubMap.get(parentProgrammingId);
        tempSub.parent__c = tempSubParent.Id;
        updateList.add(tempSub);
      }
    }
    try
    {
      update updateList;
    }
    catch(Exception e)
    {
      system.debug('Error in updating Sub parents: '+e.getMessage());
    }

    }   
}//end class CustomContractLogicforCPQ