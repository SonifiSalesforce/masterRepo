// *********************************************************************************************
// Filename:     ContractRenewalBatchProcess
// Version:      0.0.1
// Author:       Etherios
// Date Created: 9/16/2013
// Description:  Batch Process class for Contract Auto Renewal Process
//  
// shawks 201810 : CPQ - update to use out-of-box object Contract instead of Contract__c
// SGP - 4/4/2014: Commented out update to Contract Line Items, Asset, Service Contract, Entitlements
//                 because functionality has been moved to triggers on Contract__c and Contract_Item__c
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************
global class ContractRenewalBatchProcess implements Database.Batchable<sObject>{

   global final String Query;

   global ContractRenewalBatchProcess(){
      //shawks 201810: CPQ - update to use out-of-box object Contract instead of Contract__c; update to contract fields
	  /*
	  Query = 'SELECT ' +
               	  'Id, ' +
               	  'Contract_End_Date__c, ' +
               	  'Renewal_Term__c, ' +
               	  'Renewal_Cycle__c, ' +
               	  'Auto_Renew__c, ' +
               	  'Status__c, ' +
               	  'Contract_Term_months__c ' +
              'FROM ' +
                  'Contract__c ' +
              'WHERE ' +
                  'Status__c = \'Activated\' ' +
                  'AND Contract_End_Date__c != null ' +
	              'AND Renewal_Term__c != null ' +
	              'AND Renewal_Cycle__c != null';	
	  */
	  Query = 'SELECT ' +
               	  'Id, ' +
               	  'EndDate, ' +
               	  'SBQQ__RenewalTerm__c, ' +
               	  'Renewal_Cycle__c, ' +
               	  'Auto_Renew__c, ' +
               	  'Contract_Status__c, ' +
               	  'ContractTerm ' +
              'FROM ' +
                  'Contract ' +
              'WHERE ' +
                  'Contract_Status__c = \'Activated\' ' +
                  'AND EndDate != null ' +
	              'AND SBQQ__RenewalTerm__c != null ' +
	              'AND Renewal_Cycle__c != null';
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope)
   {
	     Utilities.writeLog('Entering execute loop: scope is '+scope, ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
	   
	     /*
	     List<Id> contractIds = new List<Id>();
	     for(Contract__c c : (List<Contract__c>)scope)
	     {
	        contractIds.add(c.Id);
	     }
	     //Query list of Contract Line Items
	     Map<Id,Contract_Line_Item__c> cliMap = new Map<Id,Contract_Line_Item__c>([SELECT 
	     																			   Id,
	     																		   	   Legal_Contract__c, 
	     																		   	   Term_End_Date__c, 
	     																		   	   Renewal_Cycle__c, 
	     																		   	   Auto_Renew__c,
	     																		   	   Status__c 
	     																		   FROM 
	     																		   	   Contract_Line_Item__c
	     																		   WHERE 
	     																		   	   Legal_Contract__c IN :contractIds 
	     																		   	   AND (Status__c = 'Installed Activated' 
	     																		   	   		OR Status__c = 'Installed Deactivated' 
	     																		   	   		OR Status__c = 'Billing' 
	     																		   	   		OR Status__c = 'Pending De-Installation')]);
	     Utilities.writeLog('Contract Line Items queried '+cliMap.values(), ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
	     
	     Map<Id, List<Contract_Line_Item__c>> contractLineItemsMap = new Map<Id, List<Contract_Line_Item__c>>();
	     List<Contract_Line_Item__c> contractLineItems;
	     for(Contract_Line_Item__c cli : cliMap.values()) {
			if(!contractLineItemsMap.containsKey(cli.Legal_Contract__c)){
				contractLineItems = new List<Contract_Line_Item__c>();
			} else {
				contractLineItems = contractLineItemsMap.get(cli.Legal_Contract__c);
			}
			contractLineItems.add(cli);
			contractLineItemsMap.put(cli.Legal_Contract__c,contractLineItems);		
	     }
	     
	     //Query Assets
	     List<Asset> assetList = [SELECT 
	     							  Id,
	     							  Term__c,
	     							  Term_End_Date__c, 
	     							  Service_End_Date__c,
	     							  Legal_Contract__c ,
	     							  Legal_Contract_Line_Item__c, 
	     							  Status, 
	     							  Auto_Renew__c 
	     						  FROM 
	     						  	  Asset 
	     						  WHERE 
	     						  	  Legal_Contract_Line_Item__c IN : cliMap.keyset() 
	     						  	  AND (Status = 'Installed Activated' 
	     						  	  	   OR Status = 'Installed Deactivated' 
	     						  	  	   OR Status = 'Billing' 
	     						  	  	   OR Status = 'Pending De-Installation')];
	     Utilities.writeLog('Assets queried '+assetList, ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
	     
	     Map<Id, List<Asset>> contractLineItemAssetMap = new Map<Id, List<Asset>>();
	     List<Asset> assets;
	     for(Asset a : assetList) {
			if(!contractLineItemAssetMap.containsKey(a.Legal_Contract_Line_Item__c)){
				assets = new List<Asset>();
			} else {
				assets = contractLineItemAssetMap.get(a.Legal_Contract_Line_Item__c);
			}
			assets.add(a);
			contractLineItemAssetMap.put(a.Legal_Contract_Line_Item__c,assets);		
	     }
	     
	     //Query Entitlements
	     List<Entitlement> entitlementList = [SELECT 
	     										  Id,
			     								  EndDate, 
			     								  StartDate, 
			     								  Legal_Contract_Line_Item__c, 
			     								  Do_Not_Renew__c 
			     							  FROM 
			     							  	  Entitlement
			     							  WHERE 
			     							  	  Legal_Contract_Line_Item__c IN : cliMap.keyset() 
			     							  	  AND Do_Not_Renew__c = false];
	     Utilities.writeLog('Entitlements queried '+entitlementList, ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
	     
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
	     }
	     
	     //Query Service Contracts
	     List<ServiceContract> scList = [SELECT 
	                                        Id,
	     								    EndDate, 
	     								    StartDate, 
	     								    Legal_Contract_Line_Item__c, 
	     								    Do_Not_Renew__c 
	     								 FROM 
	     								 	ServiceContract
	     							     WHERE 
	     							     	Legal_Contract_Line_Item__c IN : cliMap.keyset() 
	     							     	AND Do_Not_Renew__c = false];
	     Utilities.writeLog('Service Contracts queried '+scList, ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
	     
	     Map<Id, List<ServiceContract>> contractLineItemServiceContractMap = new Map<Id, List<ServiceContract>>();
	     List<ServiceContract> serviceContracts;
	     for(ServiceContract sc : scList) {
			if(!contractLineItemServiceContractMap.containsKey(sc.Legal_Contract_Line_Item__c)){
				serviceContracts = new List<ServiceContract>();
			} else {
				serviceContracts = contractLineItemServiceContractMap.get(sc.Legal_Contract_Line_Item__c);
			}
			serviceContracts.add(sc);
			contractLineItemServiceContractMap.put(sc.Legal_Contract_Line_Item__c,serviceContracts);		
	     }
	     */
	     //shawks 201810: CPQ - update to use out-of-box object Contract instead of Contract__c; update to contract fields
	     //Lists of objects to be updated
	     //List<Contract__c> cUpdate = new List<Contract__c>();
	     List<Contract> cUpdate = new List<Contract>();
	     /*List<Contract_Line_Item__c> cliUpdate = new List<Contract_Line_Item__c>();
	     List<Asset> aUpdate = new List<Asset>();
	     List<Entitlement> eUpdate = new List<Entitlement>();
	     List<ServiceContract> scUpdate = new List<ServiceContract>();
	     */
	     //for(Contract__c c : (List<Contract__c>)scope)
	     for(Contract c : (List<Contract>)scope)
	     {
			//Looping through all Contracts
			//if(c.Contract_End_Date__c.addDays((Integer)c.Renewal_Cycle__c * -1) <= Date.today())
			if(c.EndDate.addDays((Integer)c.Renewal_Cycle__c * -1) <= Date.today()) 
	        {
				try 
				{
		            //If the contract has a Renewal Term and the Contract End Date is Today
		            //Update the Contract Date by adding the Term Months
		            //c.Contract_End_Date__c = c.Contract_End_Date__c.addMonths((Integer)c.Renewal_Term__c);
		            //c.Contract_Term_months__c = c.Contract_Term_months__c + (Double)c.Renewal_Term__c;
                    c.EndDate = c.EndDate.addMonths((Integer)c.SBQQ__RenewalTerm__c);
		            c.ContractTerm = c.ContractTerm + (Integer)c.SBQQ__RenewalTerm__c;
		            c.Auto_Renew__c = true;
		            cUpdate.add(c);
		            
		            /* SGP - 4/3/2014: Commented out the update to Legal Contract Line Items because 
			            	                   there is a trigger on Legal Contract when Term Start Date or End Date is 
			            	                   updated it will update Term Start Date and End Date on LCLI. So this 
			            	                   functionality becomes redundant
		            if(contractLineItemsMap.containsKey(c.Id))
		            {
		            	//Look through Contract Line Items
			            for(Contract_Line_Item__c cli : contractLineItemsMap.get(c.Id))
			            {   
			            	
		                	cli.Term_End_Date__c = c.Contract_End_Date__c;
		                	cli.Auto_Renew__c = true;
				            cliUpdate.add(cli);
				            
				            
	                		
	            		 	if(contractLineItemAssetMap.containsKey(cli.Id))
	            		 	{
	                			for(Asset a : contractLineItemAssetMap.get(cli.Id))
	                			{
	                				if(a.Term_End_Date__c != null) {
	                					a.Term_End_Date__c = c.Contract_End_Date__c;
	                				}
	                				
	                				if(a.Service_End_Date__c != null){
	                					a.Service_End_Date__c = c.Contract_End_Date__c;
	                				}
	                				
	                				if(a.Term__c == null){	
	                					a.Term__c = (Integer)c.Contract_Term_months__c;
	                				}else{
				                		a.Term__c = a.Term__c + (Integer)c.Renewal_Term__c;
	                				}
				                		
				                	a.Auto_Renew__c = true;
						            aUpdate.add(a);
	                			}
	            		 	}
	            		 	
	            		 	if(contractLineItemEntitlementMap.containsKey(cli.Id))
	            		 	{
	                			for(Entitlement e : contractLineItemEntitlementMap.get(cli.Id))
	                			{
	                				e.EndDate = c.Contract_End_Date__c;
		                			eUpdate.add(e);
	                			}
	            		 	}
	            		 		            		 	
	            		 	if(contractLineItemServiceContractMap.containsKey(cli.Id))
	            		 	{
	                			for(ServiceContract sc : contractLineItemServiceContractMap.get(cli.Id))
	                			{
	                				sc.EndDate = c.Contract_End_Date__c;
	                				sc.Term = (Integer)c.Contract_Term_months__c;
	                				scUpdate.add(sc);
	                			}
	            		 	}
	            		 	
	            		 	
			            }
		            }*/
	        	}
		    	catch(Exception e)
		    	{
					Utilities.writeLog('Error in Contract Renewal process: '+e.getMessage(), ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
		    	}
	    	}   
		 }  
 
 		 //Update Contract, Contract Line Item, Asset, Entitlement, Service Contracts
		 Utilities.writeLog('Contracts updated '+cUpdate, ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
		 /*
		   Utilities.writeLog('Contract Line Items updated '+cliUpdate, ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
		   Utilities.writeLog('Assets updated '+aUpdate, ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
		   Utilities.writeLog('Entitlements updated '+eUpdate, ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
		   Utilities.writeLog('Service Contracts updated '+scUpdate, ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 
	 	 */
		 Savepoint sp = Database.setSavepoint();
		 try
		 {
		     update cUpdate;
		     /* SGP - 4/3/2014: Commented out the update to Legal Contract Line Items because 
			            	                   there is a trigger on Legal Contract when Term Start Date or End Date is 
			            	                   updated it will update Term Start Date and End Date on LCLI. So this 
			            	                   functionality becomes redundant
		     update cliUpdate;
		     update aUpdate;
		     update eUpdate;
		     update scUpdate;
		     */
		 }
		 catch(Exception e)
		 { 
		 	Utilities.writeLog('Error in Contract Renewal DML: '+e.getMessage(), ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG);
		 	Database.Rollback(sp); 
		 }
		 Utilities.writeLog('Exiting execute loop', ContractRenewalBatchProcess.class, 'execute', LoggingLevel.DEBUG); 	 
   }

   global void finish(Database.BatchableContext BC){}

}