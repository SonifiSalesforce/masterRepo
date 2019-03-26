// *********************************************************************************************
// Filename:     CustomContractLogic
// Version:      0.0.1
// Author:       Etherios
// Date Created: 8/2/2013
// Description:  Contains methods for generating asset and order records based on contract 
//               details.
//  
// Copyright 2013 Etherios. All rights reserved. Customer confidential. Do not distribute.
//
/* 
	shawks 10/17 - BUG00220: Product Inventory (Asset) record can have 0 to many Marina Servie Modules but no duplicates
	jjackson 5/2017 BUG-00722 Create extended warranty service contracts for STAY1000 hotels
	
	jjackson 4/2016 BUG-00588 populate price, quantity, project type, and equipment ownership
	 into product inventory line items and order items

   jjackson 8/2014 For BUG-00329, relate entitlement to the product parent it goes to on the contract.
   Do not relate it to the line item it goes to on the contract.  Only the service contract goes to
   the warranty line item.
*/
// *********************************************************************************************
// *********************************************************************************************

public with sharing class CustomContractLogic {
    
    public class ContractUpdate {
        public Contract__c contract;
        public LIST<ID> ContractLIIDs;
        public Map<Id, Contract_Line_Item__c> lineItems;
        public Boolean hasContractStatusChange = false;
        public ContractUpdate(Contract__c c) { this.contract = c; }
    }
    
    /**
     * Gets the list of custom fields for the Contract__c object for pushing field
     * data into same-named fields on the Order__c object
     * Allows us to keep a single static variable reference per processing instance.
     */
    
    public static List<String> contractFields {
        get {
            if (contractFields == null) {
                contractFields = Utilities.getSObjectFields(Contract__c.getSObjectType(), false);
            }
            return contractFields;
        }
        private set;
    }
    
    /**
     * Gets the list of custom fields for the Contract_Line_Item__c object for pushing field
     * data into same-named fields on the Order_Item__c object
     * Allows us to keep a single static variable reference per processing instance.
     */
    public static List<String> contractItemFields {
        get {
            if (contractItemFields == null) {
                contractItemFields = Utilities.getSObjectFields(Contract_Line_Item__c.getSObjectType(), false);
            }
            return contractItemFields;
        }
        private set;
    }
    
    /**
     * Gets the list of custom fields for the Order_Item__c object for pushing field
     * data into same-named fields on the Asset object
     * Allows us to keep a single static variable reference per processing instance.
     */
    public static List<String> orderItemFields {
        get {
            if (orderItemFields == null) {
                orderItemFields = Utilities.getSObjectFields(Order_Item__c.getSObjectType(), false);
            }
            return orderItemFields;
        }
        private set;
    }
    
    /**
     * Gets the list of  fields for the Asset object for pushing field
     * data into same-named fields on the Asset object
     * Allows us to keep a single static variable reference per processing instance.
     */
     
     
    public static List<String> assetFields {
        get {
            if (assetFields == null) {
                assetFields = Utilities.getSObjectFields(Asset.getSObjectType(), false);
            }
            return assetFields;
        }
        private set;
    }
    
    
    
    public static List<String> Prod2Fields {
        get {
            if (Prod2Fields == null) {
                Prod2Fields = Utilities.getSObjectFields(Product2.getSObjectType(), false);
            }
            return Prod2Fields;
        }
        private set;
    }
    
    
    /**
     * Gets the list of  fields for the ServiceCOntract object for pushing field
     * data into same-named fields on the Asset object
     * Allows us to keep a single static variable reference per processing instance.
     */
     
     
    public static List<String> SvcCntrFields {
        get {
            if (SvcCntrFields == null) {
                SvcCntrFields = Utilities.getSObjectFields(ServiceContract.getSObjectType(), false);
            }
            return SvcCntrFields;
        }
        private set;
    }
    
    public static Map<String, List<Marina_Service_Mod_Mapping__c>> MarinaModulesByProductCode {
    	get {
    		if (MarinaModulesByProductCode == null) {
				MarinaModulesByProductCode = new Map<String, List<Marina_Service_Mod_Mapping__c>>();
            	
            	List<Marina_Service_Mod_Mapping__c> allMarinaModuleMappings = Marina_Service_Mod_Mapping__c.getAll().values();
             	List<Marina_Service_Mod_Mapping__c> marinaMappings;
				
                for(Marina_Service_Mod_Mapping__c marinaModuleMapping : allMarinaModuleMappings){
	                if (MarinaModulesByProductCode.containskey(marinaModuleMapping.Part_Number__c)){
	                    marinaMappings = MarinaModulesByProductCode.get(marinaModuleMapping.Part_Number__c);
	                    marinaMappings.add(marinaModuleMapping);
	                    MarinaModulesByProductCode.put(marinaModuleMapping.Part_Number__c, marinaMappings);
	                }
	                else {
	                    marinaMappings = new List<Marina_Service_Mod_Mapping__c>();
	                    marinaMappings.add(marinaModuleMapping);
	                    MarinaModulesByProductCode.put(marinaModuleMapping.Part_Number__c, marinaMappings);
	                } 
	            }    			
    		}
    		return MarinaModulesByProductCode;
    	}
    	private set;    
    }
   
            

    /* Returns BusinessHours */
    
    public static BusinessHours getBizHours (string bizName){
        
        BusinessHours newBizHrs=new BusinessHours();
        newBizHrs =[Select ID from BusinessHours where name=:bizName];
        return newBizHrs;
        
    }


/* Returns Entitlment Process */
    
    public static MAP<string,SlaProcess> getEntlProc (){
        
        MAP<string,SlaProcess> mpEntProcess=new MAP<string,SlaProcess>();
        
        for (SlaProcess slproc:[Select ID,Name from SlaProcess where isActive=true]){
            mpEntProcess.put(slproc.name,slproc);
        }
        return mpEntProcess;
        
    }
    
    
    /*Method to return all Contract Line Items for given contract Line Item ID */
    public static LIST <Contract_Line_Item__c> getContractItems(LIST<ID> ContractItmIds) {
        
            LIST <Contract_Line_Item__c> lstContLI=new LIST <Contract_Line_Item__c>();  
            string dbQry='';          
            for (string lstCOntrItmField:contractItemFields){
               // system.debug('lstCOntrItmField:'+lstCOntrItmField); 
                if (dbqry==null){
                    dbqry =lstCOntrItmField+',';
                }
                else {
                dbqry +=lstCOntrItmField+',';
                }
                
            }
            dbQry ='Select '+dbqry.left(dbqry.length()-1) + ' From Contract_Line_Item__c where ID IN (\'' + String.join(ContractItmIds, '\',\'') + '\')';
          //  system.debug('dbqry:'+dbqry);
            
            lstContLI= Database.query(dbQry);
            return lstContLI;
    }
    
    
    /*Method to return all Contract Line Items for given contract ID */
    public static LIST <Contract_Line_Item__c> getContractItemsforContract(ID ContractIds) {
            string dbQry='';
            for (string lstCOntrItmField:contractItemFields){
               // system.debug('lstCOntrItmField:'+lstCOntrItmField); 
                if (dbqry==null){
                    dbqry =lstCOntrItmField+',';
                }
                else {
                dbqry +=lstCOntrItmField+',';
                }
                
            }
            
            
            dbQry ='Select '+dbqry.left(dbqry.length()-1) + ' From Contract_Line_Item__c where Legal_Contract__c =\'' + ContractIds + '\'';
          //  system.debug('dbqry:'+dbqry);
            LIST <Contract_Line_Item__c> lstContLI=new LIST <Contract_Line_Item__c>();  
            lstContLI= Database.query(dbQry);
                      
            return lstContLI;
    }
    
    
    public static Contract__c getContractRec(ID ContractIds) {
        
            LIST<String> lstLegalContrFlds=new LIST<String>();
            lstLegalContrFlds=Utilities.getSObjectFields('Contract__c');
           // system.debug('lstLegalContrFlds:'+lstLegalContrFlds);
            string dbQry='';
            for (string lstCOntrField:lstLegalContrFlds){
               // system.debug('lstCOntrField:'+lstCOntrField);   
                if (dbqry==null){
                    dbqry =lstCOntrField+',';
                }
                else {
                dbqry +=lstCOntrField+',';
                }
                
            }
            
            dbQry ='Select '+dbqry.left(dbqry.length()-1) + ',Total_Rooms__c From Contract__c where ID =\'' + ContractIds + '\'';
          //  system.debug('dbqry:'+dbqry);
            Contract__c lstContr=new Contract__c();  
            lstContr= Database.query(dbQry);
                      
            return lstContr;
    }
    
    public static Account getAcctRec(ID AcctId) {
        
            LIST<String> lstAcctFlds=new LIST<String>();
            lstAcctFlds=Utilities.getSObjectFields('Account');
            //system.debug('lstAcctFlds:'+lstAcctFlds);
            string dbQry='';
            for (string lstAcctField:lstAcctFlds){
                //system.debug('lstAcctField:'+lstAcctFlds);  
                if (dbqry==null){
                    dbqry =lstAcctField+',';
                }
                else {
                dbqry +=lstAcctField+',';
                }
                
            }
            
            
            dbQry ='Select '+dbqry.left(dbqry.length()-1) + ' From Account where ID =\'' + AcctId + '\'';
            //system.debug('dbqry:'+dbqry);
            Account lstAcct=new Account();  
            lstAcct= Database.query(dbQry);
                      
            return lstAcct;
        
    }
    
    
    /*Method to return all Assets for given contract Line Item ID */
    public static LIST <Asset> getAssetsforCLI(LIST<Contract_Line_Item__c> ContractLIIds) {
        
            string query;
            LIST<ID> lstContractIDs=new LIST<ID>();
            for (Contract_Line_Item__c cLIRec:ContractLIIds){
                lstContractIDs.add(cLIRec.ID);
            }
            
            string dbQry='';
            for (string lstAssetfield:assetFields){
              //  system.debug('lstAssetfield:'+lstAssetfield);   
                if (dbqry==null){
                    dbqry =lstAssetfield+',';
                }
                else {
                dbqry +=lstAssetfield+',';
                }
                
            }
            
            //aded Product2.ProductCode with asset field, sp it could be checked during Marina module creation
            dbQry ='Select '+dbqry.left(dbqry.length()-1) + ',Product2.ProductCode From Asset where Legal_Contract_Line_Item__c IN (\'' + String.join(lstContractIDs, '\',\'') + '\')';
           // system.debug('dbqry:'+dbqry);
    
            List<Asset> assets=new LIST<Asset>();
            assets = Database.query(dbQry);
          //  system.debug('assets:'+assets);
            return assets;
        
    }
    
    
    /*Method to return all Assets for given contract Line Item ID based on Asset ID */
    public static MAP <ID,Asset> getAssetsforCLIAsstID(LIST<Contract_Line_Item__c> ContractLIIds) {
        
            string query;
            LIST<ID> lstContractIDs=new LIST<ID>();
            for (Contract_Line_Item__c cLIRec:ContractLIIds){
                lstContractIDs.add(cLIRec.Product_Inventory__c);
            }
            
            string dbQry='';
            MAP<ID,Asset> mpAssetRecs=new MAP<ID,Asset>();
            for (string lstAssetfield:assetFields){
               // system.debug('lstAssetfield:'+lstAssetfield);   
                if (dbqry==null){
                    dbqry =lstAssetfield+',';
                }
                else {
                dbqry +=lstAssetfield+',';
                }
                
            }
            
            
            dbQry ='Select '+dbqry.left(dbqry.length()-1) + ' From Asset where ID IN (\'' + String.join(lstContractIDs, '\',\'') + '\')';
           // system.debug('dbqry:'+dbqry);
            
            
            List<Asset> assets=new LIST<Asset>();
            assets = Database.query(dbQry);
          //  system.debug('assets:'+assets);
            for (Asset astRec:assets){
                mpAssetRecs.put(astRec.ID,astRec);
            }
            
            return mpAssetRecs;
        
    }
    
    
    
    
    /* method to retrive assets for a given contract Line Item */
    
        public static MAP<ID,Asset> getCLIAssetmap(LIST<Contract_Line_Item__c> mpcontrLines){   
            
            system.debug('within getCLIAssetmap');
            LIST<Asset> lstAssts=new LIST<Asset>();
            
            lstAssts=CustomContractLogic.getAssetsforCLI(mpcontrLines);
            MAP<ID,Asset> mpcntrLIAsst=new MAP<ID,Asset>();
         //   system.debug('mpcontrLines in method:'+mpcontrLines);
         //   system.debug('lstAssts withn method:'+lstAssts);
            for (Asset AstRec:lstAssts){
             //   system.debug('creating asset map:');
                mpcntrLIAsst.put(AstRec.Legal_Contract_Line_Item__c,AstRec);
            }
    
         //   system.debug('mpcntrLIAsst:'+mpcntrLIAsst);
            return mpcntrLIAsst;
        }
        
    /* Method to return Order Items for given Contract Line Item */
    /* method to retrive assets for a given contract Line Item */
    
        public static MAP<ID,Order_Item__c> getCLIOLImap(LIST<Contract_Line_Item__c> mpcontrLines,string OrderNo){  
            
            
            LIST<ID> lstContractIDs=new LIST<ID>();
            for (Contract_Line_Item__c cLIRec:mpcontrLines){
                lstContractIDs.add(cLIRec.ID);
            }
            
            system.debug('within getCLIOLImap');
            
            string dbQry='';
            for (string lstOIfield:orderItemFields){
             //   system.debug('lstOIfield:'+lstOIfield); 
                if (dbqry==null){
                    dbqry =lstOIfield+',';
                }
                else {
                dbqry +=lstOIfield+',';
                }
                
            }
            
            
            dbQry ='Select '+dbqry.left(dbqry.length()-1) + ' From Order_Item__c WHERE Legal_Contract_Line_Item__c IN (\'' + String.join(lstContractIDs, '\',\'') + '\') and Order__c=\''+ OrderNo +'\'';
            
            
            
            LIST<Order_Item__c> lstOrdItms=new LIST<Order_Item__c>();
            
            lstOrdItms=Database.query(dbQry);
            MAP<ID,Order_Item__c> mpcntrLIOrd=new MAP<ID,Order_Item__c>();
                    
            
            for (Order_Item__c OrdRec:lstOrdItms){
             //   system.debug('creating OLI map:');
              //  system.debug('OrdRec.Order__c:'+OrdRec.Order__c);
             //   system.debug('OrdRec.OLI:'+OrdRec.id);
                mpcntrLIOrd.put(OrdRec.Legal_Contract_Line_Item__c,OrdRec);
            }
    
          //  system.debug('mpcntrLIOrd:'+mpcntrLIOrd);
            return mpcntrLIOrd;
        }   
    
    /*Get ServiceCOntracts for a list of Contract Line Items */
    
    public static MAP<ID,ServiceContract> getSvcCntrmap(LIST<Contract_Line_Item__c> mpcontrLines){  
            
            
            LIST<ID> lstContractIDs=new LIST<ID>();
            for (Contract_Line_Item__c cLIRec:mpcontrLines){
                lstContractIDs.add(cLIRec.ID);
            }
            
            system.debug('within getSvcCntrmap');
            
            string dbQry='';
            for (string lstSvcfield:SvcCntrFields){
                    
                if (dbqry==null){
                    dbqry =lstSvcfield+',';
                }
                else {
                dbqry +=lstSvcfield+',';
                }
                
            }
            
            dbQry ='SELECT '+dbqry.left(dbqry.length()-1)  + ' FROM ServiceContract WHERE Legal_Contract_Line_Item__c IN (\'' + String.join(lstContractIDs, '\',\'') + '\')';
            
            LIST<ServiceContract> lstSvcItms=new LIST<ServiceContract>();
            
            lstSvcItms=Database.query(dbQry);
            MAP<ID,ServiceContract> mpSvcCntI=new MAP<ID,ServiceContract>();
                    
            
            for (ServiceContract SvcRec:lstSvcItms){
                
                mpSvcCntI.put(SvcRec.Legal_Contract_Line_Item__c,SvcRec);
            }
            
            return mpSvcCntI;
        }   
    
    
    /*Get Products for a list of Contract Line Items */
    
    public static MAP<ID,Product2> getProdmap(LIST<Contract_Line_Item__c> mpcontrLines){    
            
            
            LIST<ID> lstProductIDs=new LIST<ID>();
            for (Contract_Line_Item__c cLIRec:mpcontrLines){
                lstProductIDs.add(cLIRec.Product__c);
            }
            
            system.debug('within getSvcCntrmap');
            
            
            
            LIST<String> lstPrdFlds=new LIST<String>();
        
            string dbQry='';
            for (string lstPrdfield:Prod2Fields){
                    
                if (dbqry==null){
                    dbqry =lstPrdfield+',';
                }
                else {
                dbqry +=lstPrdfield+',';
                }
                
            }
            
            
                dbQry ='SELECT '+dbqry.left(dbqry.length()-1)  + ' FROM Product2 WHERE ID IN (\'' + String.join(lstProductIDs, '\',\'') + '\')';
            
            
            
            
                LIST<Product2> lstPrdItms=new LIST<Product2>();
            
                lstPrdItms=database.query(dbQry);
                MAP<ID,Product2> mpPrdCnt = new MAP<ID,Product2>();
                    
            
                for (Product2 PrdRec:lstPrdItms){
                
                    mpPrdCnt.put(PrdRec.ID,PrdRec);
                }
    
            
            return mpPrdCnt;
            
        }
    
    //jjackson 5/7/2014 Create a map of the product parent line items to pass into ParentProjectType
    public static MAP<ID,Contract_Line_Item__c> getProductParents(LIST<Contract_Line_Item__c> lstContLI){
         MAP<ID,Contract_Line_Item__c> mpProdParents = new MAP<ID,Contract_Line_Item__c>();
      //   system.debug('entering new code getProductParents');
         for(Contract_Line_Item__c contritm : lstContLI)
           {
           	 String contritmname=contritm.Name;
           	 if(contritmname.contains('Product Parent'))
           	 {  mpProdParents.put(contritm.ID,contritm);
           	   //system.Debug('getProductParent map is ' + contritm.Id + ', ' + contritm.project_type__c);
           	 }
           }
         return mpProdParents;
    }
    
    //jjackson 5/7/2014 get the project type from the product parent of the contract line item to put on order items
    //jjackson 4/2016 don't need this code anymore, can get the project type from product parent map using product parent id field
    //on the legal contract line item
  /*
    public static string ParentProjectType(MAP<ID,String> mpProdParent, Contract_Line_Item__c contritm, LIST<Contract_Line_Item__c> lclilist){
    	// system.debug('entering new code ParentProjectType for line item name ' + contritm.Name);
       	 String projecttype;
    	 Id lcliparent;
    	 Id packageparent;
    	 Map<ID,ID> mpPackageLine = new Map<ID,ID>();
    	 
    	 lcliparent = contritm.parent__c;
    	 if(lcliparent != null||lcliparent <>''){
    	 	//if the parent__c id on the line item is in the product parent map, the line is a package/standalone line
    	 	if(mpProdParent.containskey(lcliparent))
    	 	{  projecttype = mpProdParent.get(lcliparent);
    	 	 //  system.debug('project type for line item with prod parent as parent is ' + projecttype);
    	 	}
    	 	
    	  }
    	  
    	  //Now make a map of the package lines
    	  for(Contract_Line_Item__c reclineitm : lclilist)
    	  {
    	  	if(lcliparent != null||lcliparent <> '')
    	  	{
    	  		if(mpProdParent.containskey(reclineitm.parent__c)) //line is a package line so add to package map
    	  		{
    	  			mpPackageLine.put(reclineitm.id, reclineitm.parent__c);
    	  		}
    	  	}
    	  	
    	  }
    	  
      	  
    	  //if projecttype is still empty, the line item is a child line
    	  if(projecttype == null||projecttype == '')
    	  { for(Contract_Line_Item__c lineitemrec : lclilist)
    	  	{
    	  		if(lcliparent==lineitemrec.id)   //find the parent record of the line item record passed in
    	  		{
    	  			ID prodparentid = lineitemrec.parent__c;  //this is the id of the child line's grandparent
    	  			if(mpProdParent.containskey(prodparentid))   //the grandparent is a product parent line
    	  			  { projecttype=mpProdParent.get(prodparentid); }
    	  
    	  		}

    	  	 // system.debug('project type for child line is ' + projecttype);
    	  	}
    	  	
    	  }
    	  
    	  //if projecttype is still empty, the line is a child of a child line (a sub-child)
    	  if(projecttype == null||projecttype == '')
    	    {
    	    	for(Contract_Line_Item__c childrec : lclilist)
    	    	{
    	    		if(contritm.parent__c==childrec.id)  //if the line item id in the list = parent__c of the line item passed in, we have the line's parent
    	    		{
    	    			ID subchildgrandparent = mpPackageLine.get(childrec.parent__c); //get the id/parent__c value of the grandparent (package line)
    	    			if(mpProdParent.containskey(subchildgrandparent))
    	    			{
    	    				projecttype=mpProdParent.get(subchildgrandparent);
    	    			//	system.debug('got the project type for the sub child ' + projecttype);
    	    			}
    	    		}
    	    	}
    	    }
    	
    	return projecttype;
    }
    
   */ 
    
    public static string OrderNo {get;set;}
    
    
    
    /* Returns Associated Asset record which is not entitlement and Service contract */
    
    public static LIST<Entitlement> EntAsstPopulated(LIST<Entitlement> lstEntlnoAsset,LIST<Contract_Line_Item__c> lstAllContractLI){
        LIST<ID> lstContrLIIDs=new LIST<ID>();
        MAP<ID,Entitlement> mpEntlIds=new MAP<ID,Entitlement>();
        MAP<ID,ID> mpParentCOnrLIs=new MAP <ID,ID>();
        MAP<ID,Contract_Line_Item__c> mpCntrLI=new MAP<ID,Contract_Line_Item__c>();
        MAP<ID,ServiceContract> mpSvcPrdIn=new MAP<ID,ServiceContract> ();
        
        //loop through the contract line items.  If the line item has a parent,
        //add it to mpParentCOnrLIs.  If no parent, add it to mpCntrLI, it's a product parent.
        for(Contract_Line_Item__c cntrLI:lstAllContractLI){
            if(cntrLI.Parent__c!=null){
                mpParentCOnrLIs.put(cntrLI.Parent__c,cntrLI.ID);   //package lines and child lines
            }
 
              mpCntrLI.put(cntrLI.ID,cntrLI); 
        }
        
        //ServiceContract contains warranty/service information for all product parent types.  Each record is related to a contract line item
        LIST <ServiceContract> lstSrvCtrForEntl=new LIST<ServiceContract>();
        lstSrvCtrForEntl=[Select ID,Legal_contract_Line_Item__c,Product_Inventory__c from ServiceContract where Legal_contract_Line_Item__c in :lstAllContractLI];
        for (ServiceContract Sconrec:lstSrvCtrForEntl){
            mpSvcPrdIn.put(Sconrec.Product_Inventory__c,Sconrec);   //from the Servicecontract table, makes a map of asset id and the scr it goes to
            
        }
        
        for (Entitlement EntCntrrec: lstEntlnoAsset){
            
            lstContrLIIDs.add(EntCntrrec.Legal_Contract_Line_Item__c);
            mpEntlIds.put(EntCntrrec.Legal_Contract_Line_Item__c,EntCntrrec);
        }
        LIST<Contract_Line_Item__c> lstCntrLItm=new LIST<Contract_Line_Item__c>();
        lstCntrLItm=CustomContractLogic.getContractItems(lstContrLIIDs);
        MAP<ID,Product2> mpPrdRecCntrID=new MAP<ID,Product2>();
        mpPrdRecCntrID=CustomContractLogic.getProdmap(lstCntrLItm);
        LIST <Entitlement> lstPopAsstEntl=new LIST<Entitlement>();
        MAP<ID,Asset> mpcntrLIAsstEntl=new MAP<ID,Asset>();
        MAP<ID,Entitlement> mpAllEntl=new MAP<ID,Entitlement>();
        mpcntrLIAsstEntl=CustomContractLogic.getCLIAssetmap(lstAllContractLI);
       
       
       //if the lcli/asset map contains the lcli.id in the loop
       //create a new entitlement record where the id is lcli.id and the assetId is from the lcli associated asset
       //If the asset id on the entitlement exists in the Service Contract map,
       //add the service contract id to the entitlement record.     
        for (Contract_Line_Item__c contrLIRec:lstCntrLItm) {
            if(mpcntrLIAsstEntl.containsKey(contrLIRec.ID)) {
                Entitlement entlRrec=new Entitlement();
                entlRrec=mpEntlIds.get(contrLIRec.ID);
                entlRrec.AssetId=mpcntrLIAsstEntl.get(contrLIRec.ID).ID;
                if(mpSvcPrdIn.containsKey(entlRrec.AssetId)){
                    entlRrec.ServiceContractId=mpSvcPrdIn.get(entlRrec.AssetId).ID;//lstSrvCtrForEntl[0].id;
                }
                lstPopAsstEntl.add(entlRrec);   //add the entitlement record to this list
                
            }
             //if the lcli/asset map does not contain the lcli.id in the loop
             //get the parent id of the line item.  If the parent product map contains
             //the id of the line item, the line is a product parent. If the lcli/asset map
             //contains the id of the product parent,create a new entitlement record where'
             //the id is the lcli.id and the assetid is from the parent record.
             //if the Service Contract map contains the id of this product parent entitlement,
             //add the service contract id to the entitlement rec.  Add the entl record to the list.
            else {
                ID parentID=contrLIRec.Parent__c;
                while(parentID !=null) {
                    if (mpCntrLI.containsKey(parentID)){
                        Contract_Line_Item__c cntrLIforParent=new Contract_Line_Item__c();
                        cntrLIforParent=mpCntrLI.get(parentID);
                        if(mpcntrLIAsstEntl.containsKey(cntrLIforParent.ID)) {
                            Entitlement entlRrec=new Entitlement();
                            entlRrec=mpEntlIds.get(contrLIRec.ID);
                            entlRrec.AssetId=mpcntrLIAsstEntl.get(cntrLIforParent.ID).ID;
                            if(mpSvcPrdIn.containsKey(entlRrec.AssetId)){
                                entlRrec.ServiceContractId=mpSvcPrdIn.get(entlRrec.AssetId).ID;//lstSrvCtrForEntl[0].id;
                            }
                            lstPopAsstEntl.add(entlRrec);
                            
                            break;
                    }
                    else {
                        
                        parentID=cntrLIforParent.Parent__c;
                    }   
                    }
                }
                
            }
        }
        return lstPopAsstEntl;  //return the list of new entitlement records
    }
    

    /* Returns Associated Service Contrct record wwith proper product inventory */
    
    public static LIST<ServiceContract> SvcCntrAsstPopulated(LIST<ServiceContract> lstsvcnoAsset,LIST<Contract_Line_Item__c> lstAllContractLI){
        LIST<ID> lstContrLIIDs=new LIST<ID>();
        MAP<ID,ServiceContract> mpSvcIds=new MAP<ID,ServiceContract>();
        MAP<ID,ID> mpParentCOnrLIs=new MAP <ID,ID>();
        MAP<ID,Contract_Line_Item__c> mpCntrLI=new MAP<ID,Contract_Line_Item__c>();
        
        for(Contract_Line_Item__c cntrLI:lstAllContractLI){
            if(cntrLI.Parent__c!=null){
                mpParentCOnrLIs.put(cntrLI.Parent__c,cntrLI.ID);
            }
  
              mpCntrLI.put(cntrLI.ID,cntrLI);   
        }
        
        
        for (ServiceContract SvcCntrrec: lstsvcnoAsset){
            
            lstContrLIIDs.add(SvcCntrrec.Legal_Contract_Line_Item__c);
            mpSvcIds.put(SvcCntrrec.Legal_Contract_Line_Item__c,SvcCntrrec);
        }
        LIST<Contract_Line_Item__c> lstCntrLItm=new LIST<Contract_Line_Item__c>();
        lstCntrLItm=CustomContractLogic.getContractItems(lstContrLIIDs);
        MAP<ID,Product2> mpPrdRecCntrID=new MAP<ID,Product2>();
        mpPrdRecCntrID=CustomContractLogic.getProdmap(lstCntrLItm);
        LIST <ServiceContract> lstPopAsstSvc=new LIST<ServiceContract>();
        MAP<ID,Asset> mpcntrLIAsstEntl=new MAP<ID,Asset>();
        MAP<ID,ServiceContract> mpAllSvcRecs=new MAP<ID,ServiceContract>();
        mpcntrLIAsstEntl=CustomContractLogic.getCLIAssetmap(lstAllContractLI);
            
        for (Contract_Line_Item__c contrLIRec:lstCntrLItm) {
            if(mpcntrLIAsstEntl.containsKey(contrLIRec.ID)) {
                ServiceContract SvcCntrRrec=new ServiceContract();
                SvcCntrRrec=mpSvcIds.get(contrLIRec.ID);
                SvcCntrRrec.Product_Inventory__c =mpcntrLIAsstEntl.get(contrLIRec.ID).ID;
                lstPopAsstSvc.add(SvcCntrRrec);
                
            }
            else {
                ID parentID=contrLIRec.Parent__c;
                while(parentID !=null) {
                    if (mpCntrLI.containsKey(parentID)){
                        Contract_Line_Item__c cntrLIforParent=new Contract_Line_Item__c();
                        cntrLIforParent=mpCntrLI.get(parentID);
                        if(mpcntrLIAsstEntl.containsKey(cntrLIforParent.ID)) {
                            ServiceContract SvcCntrRrec=new ServiceContract();
                            SvcCntrRrec=mpSvcIds.get(contrLIRec.ID);
                            SvcCntrRrec.Product_Inventory__c =mpcntrLIAsstEntl.get(cntrLIforParent.ID).ID;
                            lstPopAsstSvc.add(SvcCntrRrec);
                            
                            break;
                    }
                    else {
                        
                        parentID=cntrLIforParent.Parent__c;
                    }   
                    }
                }
                
            }
        }
        return lstPopAsstSvc;
    }
        
    
    /** Method called from Contract Line Item FInalize Order
    
    */
    
        
    public static ID CreateRelatedRecords(List<ID> contractLineItemIds,Boolean processOrder,
    ID orderId, Boolean affectAssets,Boolean affectServiceContracts ,Boolean affectEntitlements,
    Boolean affectMarinaModules,ID ContractID){
            
            LIST<ID> lstCtrIds=new LIST<ID>();
            LIST<Contract_Line_Item__c> lstContLI =new LIST<Contract_Line_Item__c>();
            
            
            MAP<ID,ID> mpContractParents=new MAP<ID,ID>();
            MAP<ID,Contract_Line_Item__c> mpcontrLines=new MAP<ID,Contract_Line_Item__c>();
            MAP<ID,Asset> mpcntrLIAsst=new MAP<ID,Asset>();
            LIST<ID> AssetCreatedIDs=new LIST<ID>();
            LIST<Asset> lstAstUpdParent=new LIST<Asset>();
            MAP<ID,Order_Item__c> mpcntrLIOrd=new MAP<ID,Order_Item__c>();
            LIST<Order_Item__c> lstOrdUpdParent=new LIST<Order_Item__c>();
            string OrdName;
            string OrdSite;
        
            Savepoint sp=database.setSavepoint();
        
          //  system.debug('contractLineItemIds:'+contractLineItemIds);
            Contract__c ContractData=new Contract__c();
            if (ContractID == null){
                
                Contract_Line_Item__c ContrHdr=new Contract_Line_Item__c();
                ContrHdr=[Select Legal_Contract__c from Contract_Line_Item__c where id=:contractLineItemIds[0]];
                ContractData=CustomContractLogic.getContractRec(ContrHdr.Legal_Contract__c);
            }
            else {
                ContractData=CustomContractLogic.getContractRec(ContractId);
            }
            Account AcctData=new Account();
            AcctData=CustomContractLogic.getAcctRec(ContractData.Account_Name__c);
            
            
            LIST<ServiceContract> lstSrvCtract=new LIST<ServiceContract>();
            boolean crEntitlement=true;
            LIST<Entitlement> lstEntlmnt=new LIST<Entitlement>();
            
            
                
            if (contractLineItemIds <> null && contractLineItemIds.size()>0){
            lstContLI=CustomContractLogic.getContractItems(contractLineItemIds);
            }
            else if(ContractID!=null) {
                lstContLI=CustomContractLogic.getContractItemsforContract(ContractID);
            }
        
            MAP<ID,Asset> mpAssetRecID=new MAP<ID,Asset>();
            
            mpAssetRecID=getAssetsforCLIAsstID(lstContLI);
            
            
            MAP<ID,Product2> mpPrdRecID=new MAP<ID,Product2>();
            mpPrdRecID=CustomContractLogic.getProdmap(lstContLI);
            
            //jjackson 5/7/2014  create a map of the product parent id's and project types from the contract
            MAP<ID,Contract_Line_Item__c> mpProductParent = new MAP<ID,Contract_Line_Item__c>();
            mpProductParent=CustomContractLogic.getProductParents(lstContLI);
        //    system.debug('mpProductParent map was created as ' + mpProductParent);

       //     system.debug('lstContLI:'+lstContLI);
            /* Getting Contract LI and Asset map */
            mpcntrLIAsst=new MAP<ID,Asset>();
            mpcntrLIAsst=CustomContractLogic.getCLIAssetmap(lstContLI);
            
           
            MAP<string,SlaProcess> mpEntlSLAProc=new MAP<string,SlaProcess>();
            mpEntlSLAProc=CustomContractLogic.getEntlProc();
            AppConfig__c appCnfg=AppConfig__c.getInstance('Global');
            
            /* Get default business hour */
            
            BusinessHours bizTime=new BusinessHours();
            bizTime=CustomContractLogic.getBizHours(appCnfg.Business_Hours__c);
            
            string EntlProdFamily=appCnfg.Entitlement_Product_Family__c;
            string SCProdFmily=appCnfg.Service_Contract_Product_Family__c;
            /* Getting COntract LI and Order Item mapping */
            
            
            for (Contract_Line_Item__c ctrLItm:lstContLI){
                OrdName=AcctData.Name;
                OrdSite=ContractData.Account_Name__c;
              
              //if the product id/record map contains the product__c id on the line item and the part number's family is Warranty  
              //create a new service contract where name is the part number(product) name,
              //the account id is the account related to the contract, the legal_contract_line_item__c is the
              //id of the lcli, and add this record to a list
                if (affectServiceContracts==true){
                    if(mpPrdRecID.containsKey(ctrLItm.Product__c) && (mpPrdRecID.get(ctrLItm.Product__c).Family==SCProdFmily)){
                        ServiceContract srvContract=new ServiceContract() ;
                        Utilities.writeCustomFields(ctrLItm,srvContract, contractItemFields);
                        srvContract.Name=mpPrdRecID.get(ctrLItm.Product__c).Name; 
                        srvContract.AccountId=ContractData.Account_Name__c;
                        srvContract.Legal_Contract_Line_Item__c=ctrLItm.ID;
                        srvContract.Clarify_ID__c=null;
                        lstSrvCtract.add(srvContract);
                       // system.debug('added to service contract list ' +srvContract);  //jjackson 8/2014
                    }
                }
                
                
            }
            
            Database.Saveresult[] srSvrCntr;
            LIST<ID> SrvCntrID=new LIST<ID>();
            List<ServiceContract> lstnewservcons = new List<ServiceContract>();
            MAP<ID,ServiceContract> mpCntrLISvcItm=new MAP<ID,ServiceContract>();
            if (lstSrvCtract.size()>0)
            {   lstnewservcons=RemoveDuplicateServiceContracts(lstSrvCtract,lstContLI);
            	if(lstnewservcons.size()>0)
                {  srSvrCntr=Database.insert(lstnewservcons); }
                   mpCntrLISvcItm=CustomContractLogic.getSvcCntrmap(lstContLI);
                
            }
            
            
        
        

            if (processOrder==true && orderId==null){
                //RecordType Rtype=new RecordType();
                //Rtype=[Select ID from RecordType where sObjectType='Order__c' and name='Order'];
                
                ID ordRecTp=Utilities.RecordTypeNameToId('Order__c','Order');
                Order__c newOrder=new Order__c();
                newOrder.Name=OrdName;
                newOrder.Site__c=OrdSite;
                newOrder.RecordTypeId=ordRecTp;
                newOrder.Status__c=ContractData.Status__c;
                system.debug('Inserting New Order:');
                insert newOrder;
                OrderID=newOrder.Id;
                system.debug('Order Inserted:'+OrderID);            
            }   
            
            
            if (processOrder==true){
            	mpcntrLIOrd=CustomContractLogic.getCLIOLImap(lstContLI,OrderID);
            }
            
        
            LIST <Asset> lstNewAsset=new LIST<Asset>();
            LIST <Asset> lstNewAssetUpd=new LIST<Asset>();
            LIST <Order_Item__c> lstNewOli=new LIST<Order_Item__c>();
            LIST <Order_Item__c> lstUpdOli=new LIST<Order_Item__c>();
                    
            for (Contract_Line_Item__c cntrLI:lstContLI ){
            	String project;
            	String ownership;
                if (cntrLI.Parent__c!=null){
                    mpContractParents.put(cntrLI.ID,cntrLI.Parent__c);
                }
                mpcontrLines.put(cntrLI.ID,cntrLI);
                if (affectAssets==true && (mpPrdRecID.get(cntrLI.Product__c).Family <> EntlProdFamily ) && (mpPrdRecID.get(cntrLI.Product__c).Family <> SCProdFmily)){
                    if (!mpcntrLIAsst.containsKey(cntrLI.ID) && !mpAssetRecID.containsKey(cntrLI.Product_Inventory__c)) {
                    	//create asset record
                        Asset astRec=new Asset();
                        Utilities.writeCustomFields(cntrLI,astRec, contractItemFields);
                        astRec.Legal_Contract_Line_Item__c=cntrLI.ID;
                        astRec.AccountId=ContractData.Account_Name__c;
                        astRec.Product2Id=cntrLI.Product__c;
                        astRec.Name=cntrLI.Name;
                        astRec.Status=cntrLI.Status__c;
                        astRec.Marina_Resource_Ratio__c=cntrLI.Marina_Resource_Ratio__c;
                        astRec.Fee_Schedule__c=cntrLI.Fee_Schedule__c;
                        astRec.Platform__c=cntrLI.Platform__c;
                        astRec.Term_Start_Date__c=cntrLI.Term_Start_Date__c;
                        astRec.Term_End_Date__c=cntrLI.Term_End_Date__c;
                        astRec.Auto_Renew__c=ContractData.Auto_Renew__c;
                        astRec.Contract_Type__c=ContractData.Contract_Type__c;
                        astRec.Renewal_Term__c=ContractData.Renewal_Term__c;
                        astRec.Renewal_Cycle__c=ContractData.Renewal_Cycle__c;
                        astRec.Total_Room_Count__c=ContractData.Total_Rooms__c;
                        astRec.Company_Code__c=ContractData.Company_Code__c;
                        astRec.Term__c=ContractData.Contract_Term_months__c;
                        astrec.Clarify_ID__c=null;
                        //jjackson 5/30/2014  populate legal_contract__c field on the asset record
                        astrec.Legal_Contract__c=ContractData.Id;
                        //jjackson 4/2016 BUG-00588 populate qty and price on product inventory line items
                        //when contract is finalized
                        astrec.Quantity = cntrLI.quantity__c;
                        astrec.Price__c = cntrLI.price__c;
                        lstNewAsset.add(astRec);
     
                    }
                    else if(mpAssetRecID.containsKey(cntrLI.Product_Inventory__c)){
                        Asset astRec=new Asset();
                        astRec=mpAssetRecID.get(cntrLI.Product_Inventory__c);
                        astRec.Legal_Contract_Line_Item__c=cntrLI.ID;
                        astRec.Status=cntrLI.Status__c;
                        astRec.Marina_Resource_Ratio__c=cntrLI.Marina_Resource_Ratio__c;
                        astRec.Fee_Schedule__c=cntrLI.Fee_Schedule__c;
                        astRec.Platform__c=cntrLI.Platform__c;
                        astRec.Term_Start_Date__c=cntrLI.Term_Start_Date__c;
                        astRec.Term_End_Date__c=cntrLI.Term_End_Date__c;
                        astRec.Auto_Renew__c=ContractData.Auto_Renew__c;
                        astRec.Contract_Type__c=ContractData.Contract_Type__c;
                        astRec.Renewal_Term__c=ContractData.Renewal_Term__c;
                        astRec.Renewal_Cycle__c=ContractData.Renewal_Cycle__c;
                        astRec.Total_Room_Count__c=ContractData.Total_Rooms__c;
                        astRec.Company_Code__c=ContractData.Company_Code__c;
                        astRec.Term__c=ContractData.Contract_Term_months__c;
                        //jjackson 5/30/2014 populate legal_contract__c field on the asset record
                        astRec.Legal_Contract__c=ContractData.Id;
                        //jjackson 4/2016 BUG-00588 populate qty and price on product inventory line items
                        //when contract is finalized
                        astrec.Quantity = cntrLI.quantity__c;
                        astrec.Price__c = cntrLI.price__c;
                        lstNewAssetUpd.add(astRec);
                     }
                }
             //   system.debug('Value for processOrder:'+processOrder);
 
                if (!mpcntrLIOrd.containsKey(cntrLI.ID)&& processOrder==true) {
                    //Create Order LI record
                    system.debug('Creating Ord LI');
                    Order_Item__c OliRec=new Order_Item__c();

                    Utilities.writeCustomFields(cntrLI,OliRec, contractItemFields);
                    //Steve 3/26/2014
                    OliRec.Product_Parent_Id__c = null;
                    
                    OliRec.Legal_Contract_Line_Item__c=cntrLI.ID;
                    OliRec.Account__c=ContractData.Account_Name__c;
                    OliRec.Product__c=cntrLI.Product__c;
                    OliRec.Name=cntrLI.Name;
                    OliRec.Parent__c=null;
                    OliRec.Order__c=OrderID;
                    OliRec.Total_Remaining_Rooms__c=cntrLI.Quantity__c;
                    OliRec.Total_Rooms_Ordered__c=cntrLI.Quantity__c;
                    OliRec.Unit_Selling_Price__c=cntrLI.Price__c;
                    OliRec.Status__c=cntrLI.Status__c;
                    OliRec.Clarify_ID__c=null;
                    //jjackson 5/14 add project type to all order items
                    if(cntrLI.Name.contains('Product Parent')){
                        project=cntrLI.Project_Type__c; 
                        ownership=cntrLI.Equipment_Ownership__c;
                    }
                    else if(mpProductParent.containskey(cntrLI.product_parent_id__c))
                    	{ project = mpProductParent.get(cntrLI.product_parent_id__c).project_type__c; 
                    	  ownership=mpProductParent.get(cntrLI.product_parent_id__c).equipment_ownership__c;
                    	}
 
                    //system.debug('setting project type in the new order line item = ' + project);
                    OliRec.Project_Type__c=project;
                    OliRec.Equipment_Ownership__c = ownership;
                    lstNewOli.add(OliRec);
                }
                else if(mpcntrLIOrd.containsKey(cntrLI.ID)&& processOrder==true) { //Added this on 3/13/2014
                    system.debug('Order LI getting Updated:');
                   Order_Item__c OliRecUpd=new Order_Item__c();
                   	OliRecUpd=mpcntrLIOrd.get(cntrLI.ID);
                    //No need to call below utility method, as this is existing Order Item record.
                    //Utilities.writeCustomFields(cntrLI,OliRecUpd, contractItemFields);
                    OliRecUpd.Legal_Contract_Line_Item__c=cntrLI.ID;
                    OliRecUpd.Account__c=ContractData.Account_Name__c;
                    OliRecUpd.Product__c=cntrLI.Product__c;
                    OliRecUpd.Name=cntrLI.Name;
                    
                    OliRecUpd.Order__c=OrderID;
                    OliRecUpd.Total_Remaining_Rooms__c=cntrLI.Quantity__c;
                    OliRecUpd.Total_Rooms_Ordered__c=cntrLI.Quantity__c;
                    OliRecUpd.Unit_Selling_Price__c=cntrLI.Price__c;
                    OliRecUpd.Status__c=cntrLI.Status__c;
                    //jjackson 5/2014 add product parent project type to all order items
                    //jjackson 4/2016 add equipment ownership to all order items
                    if(cntrLI.Name.contains('Product Parent'))
                    {    project=cntrLI.Project_Type__c; 
                    	 ownership=cntrLI.Equipment_Ownership__c;
                    }
                    else if(mpProductParent.containskey(cntrLI.product_parent_id__c))
                    {    project = mpProductParent.get(cntrLI.product_parent_id__c).project_type__c;  
                    	 ownership=mpProductParent.get(cntrLI.product_parent_id__c).equipment_ownership__c;
                    }
                    OliRecUpd.Project_Type__c=project;
                    OliRecUpd.Equipment_Ownership__c = ownership;
                    OliRecUpd.Clarify_ID__c=null;
                    lstUpdOli.add(OliRecUpd);
                   
                }
           //     system.debug('lstUpdOli:'+lstUpdOli);
                
                
              //if the id/product2 map contains the prodct__c id on the line item and the product__c family is Entitlement,
              //create a new entitlement where the name is the part number name, the account id is the account related 
              //to the contract, legal_contract_line_item__c is the legal contract line item id, the business hours are Default.
                
                if (affectEntitlements==true){
                    if(mpPrdRecID.containsKey(cntrLI.Product__c) && (mpPrdRecID.get(cntrLI.Product__c).Family==EntlProdFamily)){
                        Entitlement entlmnt=new Entitlement();
                        Utilities.writeCustomFields(cntrLI,entlmnt, contractItemFields);
                        entlmnt.Name=mpPrdRecID.get(cntrLI.Product__c).Name;//cntrLI.Name;
                        entlmnt.AccountId=ContractData.Account_Name__c;
                        entlmnt.Legal_Contract_Line_Item__c=cntrLI.Parent__c; //jjackson 7/2014 use the product parent of the entitlement line item, not the line item itself
                        entlmnt.BusinessHoursId=bizTime.ID;
                        entlmnt.Clarify_ID__c=null;
                        if (mpEntlSLAProc.containsKey(entlmnt.Name)){
                            entlmnt.SlaProcessId=mpEntlSLAProc.get(entlmnt.Name).ID;
                        }
                        //entlmnt.SlaProcessId=
                        lstEntlmnt.add(entlmnt);
                       // system.debug('entitlement added to the list is ' +entlmnt);   //jjackson 8/2014
                    }
                }   
                
            }
        
            if (lstNewAsset.size()>0){
                try{
                insert lstNewAsset;
                }
                catch(Exception ex){
                    database.rollback(sp);
                }
            }
            if (lstNewAssetUpd.size()>0){
                try{
                update lstNewAssetUpd;
                }
                catch(Exception ex){
                    database.rollback(sp);
                }
            }
        
            mpcntrLIAsst=new MAP<ID,Asset>();
            mpcntrLIAsst=CustomContractLogic.getCLIAssetmap(lstContLI);
        
            
            /* Update product Inventory to ServiceContract */
        
            LIST<ServiceContract> lstSvrUpDAsset=new LIST<ServiceContract> ();
            LIST<ServiceContract> lstServiceRecsnoAsset=new LIST<ServiceContract> ();
            lstServiceRecsnoAsset=mpCntrLISvcItm.values();
            lstSvrUpDAsset=CustomContractLogic.SvcCntrAsstPopulated(lstServiceRecsnoAsset,lstContLI);
        
	        if (lstSvrUpDAsset.size()>0){
	            update lstSvrUpDAsset;
	        }
            
           // Database.UpsertResult[] srOLI;
            if (lstNewOli.size()>0){
                LIST <Order_Item__c> InsOLI=new LIST<Order_Item__c>();
                //Added below variable for update on 3/13/2014
               // LIST <Order_Item__c> UpdateOLI=new LIST<Order_Item__c>();
                
                for (Order_Item__c oitmRec:lstNewOli){
                    if (mpcntrLIAsst.containsKey(oitmRec.Legal_Contract_Line_Item__c)){
                    	oitmRec.Asset__c=mpcntrLIAsst.get(oitmRec.Legal_Contract_Line_Item__c).ID;
                    	oitmRec.Product_Inventory__c=mpcntrLIAsst.get(oitmRec.Legal_Contract_Line_Item__c).ID;
                    }
                    
                  InsOLI.add(oitmRec);
                    
                }
                //Schema.Sobjectfield fldOliExt=Order_Item__c.Clarify_ID__c;                
                if (InsOLI.size()>0){
                	//srOLI=Database.upsert(InsOLI, false);
                	insert InsOLI;
                }
                
            }
                
                //Added below part on 3/13/2014
                if (lstUpdOli.size()>0){
                //Added below variable for update on 3/13/2014
                	system.debug('Updating OLI');
                	LIST <Order_Item__c> UpdateOLI=new LIST<Order_Item__c>();
                    for (Order_Item__c oitmRec:lstUpdOli){
                    if (mpcntrLIAsst.containsKey(oitmRec.Legal_Contract_Line_Item__c)){
                    	oitmRec.Asset__c=mpcntrLIAsst.get(oitmRec.Legal_Contract_Line_Item__c).ID;
                    	oitmRec.Product_Inventory__c=mpcntrLIAsst.get(oitmRec.Legal_Contract_Line_Item__c).ID;
                    }
                  system.debug('Updating Order Items from Contract Line Items:'); 
                  UpdateOLI.add(oitmRec);
                    
                }
                    
                    if(UpdateOLI.size()>0) {
                		system.debug('Updating Order Line Item for same order');
                		update UpdateOLI;
                	}
                
                }
                
            
            
            if (processOrder==true){
                mpcntrLIOrd=new MAP<ID,Order_Item__c>();
                mpcntrLIOrd=CustomContractLogic.getCLIOLImap(lstContLI,OrderID);
            }
                
            for (Contract_Line_Item__c cLIRec:lstContLI){
                if (affectAssets==true && mpcntrLIAsst.containsKey(cLIRec.ID)){
                    Asset astRecParent=new Asset();
                    astRecParent=mpcntrLIAsst.get(cLIRec.ID);
                    if (mpContractParents.containsKey(cLIRec.ID)){                                    
                        astRecParent.Parent_Asset__c=mpcntrLIAsst.get(mpContractParents.get(cLIRec.ID)).ID;
                    }
                    astRecParent.AccountId=ContractData.Account_Name__c;
                    astRecParent.Product2Id=cLIRec.Product__c;
                    //jjackson 6/11/2014 set legal contract lookup field on asset line item
                    astRecParent.Legal_Contract__c=ContractData.Id;
                    if(mpCntrLISvcItm.containsKey(cLIRec.ID)){
                        astRecParent.Service_Contract__c=mpCntrLISvcItm.get(cLIRec.ID).ID;
                    }
                    lstAstUpdParent.add(astRecParent);
                }
                
                if (processOrder==true){
                    Order_Item__c OrdRecParent=new Order_Item__c();
                    OrdRecParent=mpcntrLIOrd.get(cLIRec.ID);
                    if (mpContractParents.containsKey(cLIRec.ID)){
                                    
                        if (mpContractParents.containsKey(cLIRec.ID)) {
                            if (mpcntrLIOrd.containsKey(mpContractParents.get(cLIRec.ID))) {
                                OrdRecParent.Parent__c=mpcntrLIOrd.get(mpContractParents.get(cLIRec.ID)).ID;
                                lstOrdUpdParent.add(OrdRecParent);
                            }
                        }
                    }
                }
            }
        
            
            if (lstAstUpdParent.size()>0 && affectAssets==true){
                try{
            		update lstAstUpdParent;
                }
                catch(Exception ex){
                    database.rollback(sp);
                }                
            }
            
            /*Updatinh Order LI Parent */
            
            if (lstOrdUpdParent.size()>0){
                try {
                	update lstOrdUpdParent;
                }
                catch(Exception ex){
                    database.rollback(sp);
                }
            }
            
            /*Inserting Entitlements */
            
            
        /* Creating entitlement
        */
        //jjackson Jan 2015 BUG-00408 Added check for duplicate entitlements before inserting new entitlements
        if (lstEntlmnt.size()>0){
            LIST <Entitlement> lstCrEntitlemnt=new LIST <Entitlement>();
            LIST <Entitlement> lstnewentitlements = new LIST<Entitlement>();  //jjackson
            lstCrEntitlemnt=CustomContractLogic.EntAsstPopulated(lstEntlmnt,lstContLI);
            if(lstCrEntitlemnt.size()>0){
            	//system.debug('lstCrEntitlemnt size is ' +lstCrEntitlemnt.size());
            	lstnewentitlements = RemoveDuplicateEntitlements(lstCrEntitlemnt,lstContLI);  //jjackson
            	if(lstnewentitlements.size()>0)
                {   //system.debug('lstnewentitlements size is ' +lstnewentitlements.size());
                	insert lstnewentitlements;  }
            }
        }
        
        /* create Marina Module
        */
        
        if (affectMarinaModules==true && affectAssets==true ){            
             system.debug('creating Marina module:'); 
             //<<shawks - BUG00220: Create map of all the Marina Service Modules linked to the assets 
             MAP<Id,SET<String>> mpAssetIdMarina = new MAP<Id,SET<String>>();
             for(Asset lstassetqry: [SELECT id, (SELECT marina_service_module__c FROM marina_modules__r) FROM asset WHERE id IN : mpcntrLIAsst.values()]){
             	SET<String> setModNum = new SET<String>();
             	for(marina_module__c lstmarinaqry: lstassetqry.marina_modules__r){
             		setModNum.add(lstmarinaqry.marina_service_module__c);
             	}
             	mpAssetIdMarina.put(lstassetqry.id,setModNum);
             }  //>>
            List<Marina_Module__c> lstMarina = new List<Marina_Module__c>();
            for (Asset astMarina : mpcntrLIAsst.values()){
            //    system.debug('astMarina.Product2.ProductCode:'+astMarina.Product2.ProductCode);
                if(MarinaModulesByProductCode.containsKey(astMarina.Product2.ProductCode)){
                //	system.debug('marina module found for product code::'+astMarina.Product2.ProductCode);    
                    for (Marina_Service_Mod_Mapping__c marimaps : MarinaModulesByProductCode.get(astMarina.Product2.ProductCode)){
	             //       system.debug('Marina module inside for loop');
	                    //shawks - BUG00220: Only create new Marina Module records if the Marina Service Module does not already exist for the asset
	                    if(!mpAssetIdMarina.get(astMarina.id).contains(marimaps.marina_service_module__c)){
	                       Marina_Module__c marinaRec = new Marina_Module__c();
	                       marinaRec.Marina_Class__c = marimaps.Marina_Class__c;//Marina_Service_Mod_Mapping__c.getInstance (astMarina.Product2.ProductCode).Marina_Class__c;
	                       marinaRec.Marina_Module_Description__c = marimaps.Marina_Module_Description__c;//Marina_Service_Mod_Mapping__c.getInstance (astMarina.Product2.ProductCode).Marina_Module_Description__c;
	                       marinaRec.Marina_Service_Module__c = marimaps.Marina_Service_Module__c;//Marina_Service_Mod_Mapping__c.getInstance (astMarina.Product2.ProductCode).Marina_Service_Module__c;
	                       marinaRec.Product_Inventory__c = astMarina.id;
	                       string marinaname = marimaps.Marina_Service_Module__c + '-' + marimaps.Marina_Module_Description__c;
	                       if (marinaname.length()>=80){
	                           marinaRec.Name = marinaname.substring(0,79);
	                       }
	                       else {
	                           marinaRec.Name = marinaname;
	                       }
	                   	   lstMarina.add(marinaRec);
	                    }
                    }
                }
            }
            if (lstMarina.size()>0){
            	system.debug('inserting marina modules');  
                insert lstMarina;
            }        
        }
        
        /* Update CLI Asset field */
        if (affectAssets==true){
            LIST<Contract_Line_Item__c> UpdContrItmAsst=new LIST<Contract_Line_Item__c>();

            for (Contract_Line_Item__c cntrLI:lstContLI ){
	                if ((cntrLI.Product_Inventory__c==null||cntrLI.Product_Inventory__c <> mpcntrLIAsst.get(cntrLI.ID).ID)&& mpcntrLIAsst.containsKey(cntrLI.ID)){
	                    cntrLI.Product_Inventory__c=mpcntrLIAsst.get(cntrLI.ID).ID;
	                    UpdContrItmAsst.add(cntrLI);
	            }
	        }


            if (UpdContrItmAsst.size()>0) {
                update UpdContrItmAsst;
            }
            
        }
        return OrderId;
    }
    
    
    /*
        Creates contract line items to the contract id passed in based on the assets
    */
    
    public static void createContractLineItems(List<Id> assets, Id contractId){
        //initialize variables
        Contract_Line_Item__c contractLineItem = new Contract_Line_Item__c();
        List<Asset> assetList = new List<Asset>(); // holds the List of the assets passed into the method
        List<Contract_Line_Item__c> cLIList = new List<Contract_Line_Item__c>(); //holds the Contract_Line_Item__c that are currently attached to the contract
        List<Contract_Line_Item__c> insertList = new List<Contract_Line_Item__c>(); //insert list for Contract_Line_Item__c
        List<Contract_Line_Item__c> insertedCLIList = new List<Contract_Line_Item__c>(); //requeried list of Contract_Line_Item__c that will be updated with the parent Contract_Line_Item__c
        List<Integer> removeCLI = new List<Integer>(); // list of integers (position of the cli in the insert list) that already have been created and need to be removed before CLI are inserted
        Set<Id> productIds = new Set<Id>(); // set of the product ids so that mulptiple CLIs are not created on the same contract
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        Set<Id> newCLIIds = new Set<ID>();
        Map<Id, Id> assetId2CLIIdMap = new Map<Id, Id>();
        
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
        //assetIds = assetIds.substring(1);
        
        //query for the assets and make it a map
        //assetList = (Database.query('SELECT id, ' + fieldAssetQuery + ', Product2.Name FROM Asset WHERE Id IN (' + assetIds + ')'));
        //System.debug('Asset list is ' + assetList);
        
        //jjackson changed code to get asset fields a different way from the Utilities method because the method wasn't pulling all fields
        //3/22/2016
        SObjectType assettype = Schema.getGlobalDescribe().get('Asset');
        Map<String,Schema.SObjectField> mpassetfields = assettype.getDescribe().fields.getMap();
        String querystring = '';
        for(String key :mpassetfields.keyset()) //the string key is the api name of the assetfield
        { querystring += ', ' +key; }
        String subquerystring = querystring.substringAfter(',');
        assetlist = Database.query('Select ' +subquerystring +',  Product2.Name from Asset Where Id in :assetids');
        system.debug('assetlist size is ' +assetlist.size());
        //loop through assets and make CLI and add them to insertList
        for(Asset a : assetList){
            //initialize var
            
            system.debug('asset being made into a contract line item is ' +a.name);
            
            contractLineItem = new Contract_Line_Item__c();
            
            //set the fields
            contractLineItem.Product__c = a.Product2Id;
            contractLineItem.Product_Inventory__c = a.id;
            contractLineItem.Legal_Contract__c = contractId;
            contractLineItem.Name = a.Product2.Name;
            contractLineItem.Marina_Resource_Ratio__c = a.Marina_Resource_Ratio__c;
            contractLineItem.Platform__c = a.Platform__c;
            contractLineItem.Fee_Schedule__c = a.Fee_Schedule__c;
            contractLineItem.CurrencyIsoCode = a.CurrencyIsoCode;
            contractLineItem.Contract_Type__c = a.Contract_Type__c;
            contractLineItem.Price__c = a.Price__c;
            contractLineItem.Quantity__c = a.Quantity;
            contractLineItem.Status__c = a.Status;
            //add cli to the insert list
            insertList.add(contractLineItem);
        }
       // SYstem.debug('Contract_Line_Item__c insert list before removing duplicates:: ' + insertList);
        
        //query for the CLI already on the contract
        cLIList = [SELECT id, Product__c, Product__r.Name, Parent__c, Product_Inventory__c, Legal_Contract__c FROM Contract_Line_Item__c WHERE Legal_Contract__c =:contractId];
        //System.debug('CLI already on contract are ' + cLIList);
        
        //make a set of products so that duplicates can be removed
        for(Contract_Line_Item__c cli : cLIList){
            productIds.add(cli.Product__c);
            assetId2CLIIdMap.put(cli.Product_Inventory__c, cli.id);
            system.debug('products set for removal are ' +cli.product__r.name);
        }
        //System.debug('Product ids are ' + productIds);
        
        //loop through insert list and remove any items where product is in set productIds
        for(integer i = 0; i < insertList.size(); i++){
            if(productIds.contains(insertList[i].Product__c)){
                removeCLI.add(i);
                system.debug('removed cli with product ' +insertList[i].name +'index num ' +i);
            }
        }
 
        
        //loop through removeCli and remove list items from insertList
        for(integer i = removeCLI.size()-1; i >= 0; i--){
            insertList.remove(i);
            system.debug('line item removed from insert list is ' +i);
        }
        for(Contract_line_item__c cli : insertlist)
        {
        	system.debug('cli left on insertlist is ' +cli.name);
        }
        
        if(insertList.size() > 0){
            try{
                saveResults = Database.insert(insertList);
                
                for(Database.SaveResult result : saveResults){
                    newCLIIds.add(result.getId());
                }
            } catch(Exception e){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, e.getMessage()));
            }
        } else {
            return;
        }
        
        //requery for the Contract_Line_Item__c
        insertedCLIList = [SELECT id, Product__c, Parent__c, Product_Inventory__c, Product_Inventory__r.Parent_Asset__c FROM Contract_Line_Item__c WHERE Id IN :newCLIIds];
        System.debug('Contract_Line_Item__c after insert:: ' + insertedCLIList);
        
        //loop through list and map (assetId2CLIIdMap) Product_Inventory__c to Contract_Line_Item__c id
        for(Contract_Line_Item__c cli : insertedCLILIst){
            assetId2CLIIdMap.put(cli.Product_Inventory__c, cli.id);
        }
        System.debug('full map of asset id to cli ' + assetId2CLIIdMap);
        
        //loop through insertCLIList and put the correct parent for the Contract_Line_Item__c
        for(Contract_Line_Item__c cli : insertedCLIList){
            //System.debug('Asset parent id ' + cli.Product_Inventory__r.Parent_Asset__c);
            if(cli.Product_Inventory__r.Parent_Asset__c != null){
                cli.Parent__c = assetId2CLIIdMap.get(cli.Product_Inventory__r.Parent_Asset__c);
            }
        }
        //System.debug('Contract_Line_Item__c after updates to parent::' + insertedCLIList);
        
        //update the Contract_Line_Item__c
        update insertedCLIList;
    }
    
     //jjackson Jan 2015 BUG-00408 Before inserting new entitlements determine whether the same entitlement already exists
    //for the line item and remove it from the insert list
    public static List<Entitlement> RemoveDuplicateEntitlements(List<Entitlement> newentllist, List<Contract_Line_Item__c> lstlcli)
    {
    	system.debug('*****************BEGIN RemoveDuplicateEntitlements ****************************');
    	List<Entitlement> returnlist = New List<Entitlement>();
    	List<Entitlement> existinglist = New List<Entitlement>();
    	Map<ID,Entitlement> mpentl = New Map<Id,Entitlement>();
    	
   
        //pull a list of any entitlements that might be related to the contract line items    	
    	existinglist = [ Select Id, Name, Status, Legal_Contract_Line_Item__c from Entitlement where Legal_Contract_Line_Item__c in :lstlcli
    	                 AND Status in ('Active', 'Inactive') ];
        
        if(!existinglist.IsEmpty())    	                 
        {
    		for(Entitlement e : existinglist)
    		{  mpentl.put(e.Legal_Contract_Line_Item__c,e);  }
    		   //system.debug('existing entitlement is : ' + e.name + ', ' + e.Legal_Contract_Line_Item__c);}
    	
    		for(Entitlement ent : newentllist)
    		{
    			if(mpentl.containsKey(ent.Legal_Contract_Line_Item__c))  //if map of existing entitlements contains lcli id of a new entitlement
    			{
    				if(ent.Name != mpentl.get(ent.Legal_Contract_Line_Item__c).Name) //determine whether the names match
    				{   returnlist.add(ent);   }
    					//system.debug('added ent to return list ' +ent.Name +', ' +ent.Legal_Contract_Line_Item__c);  }  //if not, add the entitlement to the return list
    			
    			}
    			else
    			{   returnlist.add(ent);   } 
    				//system.debug('added entitlement to return list ' +ent.Name +', ' + ent.Legal_Contract_Line_Item__c);  } //if this entitlement's lcli id is not in the existing map, add to return list
    		}
        }
    	else
    	{  //if there are no existing entitlements on any of the line items, return the whole new list
    	     returnlist = newentllist;	
    	     //system.debug('added all new entitlements to return list ');
    	}
    	system.debug('returnlist size is ' +returnlist.size());
    	return returnlist;
    	
    	
    } //end RemoveDuplicateEntitlements   
    
     //jjackson Jan 2015 BUG-00408 Before inserting new service contracts, determine whether a service contract already exists
    //for the line item and remove it from the insert list
    public static List<ServiceContract> RemoveDuplicateServiceContracts(List<ServiceContract> newsclist, List<Contract_Line_Item__c> lstlcli)
    {
    	system.debug('*****************BEGIN RemoveDuplicateServiceContracts ****************************');
    	List<ServiceContract> returnlist = New List<ServiceContract>();
    	List<ServiceContract> existinglist = New List<ServiceContract>();
    	Map<ID,ServiceContract> mpsc = New Map<Id,ServiceContract>();
    	
   
        //pull a list of any entitlements that might be related to the contract line items    	
    	existinglist = [ Select Id, Name, Status, Legal_Contract_Line_Item__c from ServiceContract where Legal_Contract_Line_Item__c in :lstlcli
    	                 AND Status in ('Active', 'Inactive') ];
        
        if(!existinglist.IsEmpty())    	                 
        {
    		for(ServiceContract sc : existinglist)
    		{  mpsc.put(sc.Legal_Contract_Line_Item__c,sc);  }
    		   //system.debug('existing service contract is : ' + sc.name + ', ' + sc.Legal_Contract_Line_Item__c);}
    	
    		for(ServiceContract recsc : newsclist)
    		{
    			if(mpsc.containsKey(recsc.Legal_Contract_Line_Item__c))  //if map of existing entitlements contains lcli id of a new entitlement
    			{
    				if(recsc.Name != mpsc.get(recsc.Legal_Contract_Line_Item__c).Name) //determine whether the names match
    				{   returnlist.add(recsc);   }
    					//system.debug('added sc to return list ' +recsc.Name +', ' +recsc.Legal_Contract_Line_Item__c);  }  //if not, add the entitlement to the return list
    			
    			}
    			else
    			{   returnlist.add(recsc); }
    				//system.debug('added service contract to return list ' +recsc.Name +', ' + recsc.Legal_Contract_Line_Item__c);  } //if this entitlement's lcli id is not in the existing map, add to return list
    		}
        }
    	else
    	{  //if there are no existing service contracts on any of the line items, return the whole new list
    	     returnlist = newsclist;	
    	     //system.debug('added all new service contracts to return list ');
    	}
    	system.debug('returnlist size is ' +returnlist.size());
    	return returnlist;
    	
    } //end RemoveDuplicateServiceContracts
    
    public static void createContractLineItemsFromOpportunity(List<Id> programmingIds, Id contractId, Id opportunityId, Boolean append)
    {
    //	system.debug('programming ids '+programmingIds + ' contractid '+contractId);
        //initialize variables
        Contract_Line_Item__c contractLineItem = new Contract_Line_Item__c();
        //Map objects to maintain parent relationship
        Map<Id,Id> programmingParentMap = new Map<Id,Id>();  //map of programming to its parent if it exists
        List<Programming__c> pList = new List<Programming__c>(); // holds the List of the OLI passed into the method
        Map<Id,Contract_Line_Item__c> programmingToCLIMap = new Map<Id,Contract_Line_Item__c>();
        List<Asset> assetList = new List<Asset>(); //List of assets to be inserted with new Contract Line Items
        List<Contract_Line_Item__c> cLIList = new List<Contract_Line_Item__c>(); //holds the Contract_Line_Item__c that are currently attached to the contract
        List<Contract_Line_Item__c> insertList = new List<Contract_Line_Item__c>(); //insert list for Contract_Line_Item__c
        List<Contract_Line_Item__c> insertedCLIList = new List<Contract_Line_Item__c>(); //requeried list of Contract_Line_Item__c that will be updated with the parent Contract_Line_Item__c
        List<Integer> removeCLI = new List<Integer>(); // list of integers (position of the cli in the insert list) that already have been created and need to be removed before CLI are inserted
        Set<Id> productIds = new Set<Id>(); // set of the product ids so that mulptiple CLIs are not created on the same contract
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        Set<Id> newCLIIds = new Set<ID>();
        Map<Id, Id> OLIId2CLIIdMap = new Map<Id, Id>();
        
        //Query Programming object
        pList = [SELECT ProductName__c, Qty__c, Price__c, Product__c, Parent__c, Total__c, Opportunity__r.AccountId from Programming__c WHERE Id IN :programmingIds];
        
        //Populate map of Parents
        for(Programming__c p : pList)
        {
        	if(p.Parent__c != null)
        		programmingParentMap.put(p.Id, p.Parent__c);
        }
        System.debug('OLI list is ' + pList);
        
        //loop through assets and make CLI and add them to insertList
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
            	contractLineItem = new Contract_Line_Item__c();
            	//set the fields
            	contractLineItem.Product__c = p.Product__c;
            	// lookup to OLI needed?
            	contractLineItem.Legal_Contract__c = contractId;
            	contractLineItem.Name = p.ProductName__c;
            	contractLineItem.Quantity__c = p.Qty__c;
            	contractLineItem.Price__c = p.Price__c;
            	programmingToCLIMap.put(p.Id,contractLineItem);
            	//add cli to the insert list
            	insertList.add(contractLineItem);
            }
         }
        //Update contract with Opportunity reference
        Contract__c contract = new Contract__c();
        contract.Id = contractId;
        contract.Opportunity__c = opportunityId;
        
        //SYstem.debug('Contract_Line_Item__c insert list before removing duplicates:: ' + insertList);
        //query for the CLI already on the contract
        cLIList = [SELECT id, Account__c, Product__c, Parent__c, Product_Inventory__c, Legal_Contract__c FROM Contract_Line_Item__c WHERE Legal_Contract__c =:contractId];
       // System.debug('CLI already on contract are ' + cLIList);
		//Set Savepoint
		Savepoint sp = Database.setSavepoint();
		try
		{
			if(append == false)
			{
				delete cLIList;
			}
			insert insertList;	
			update contract;
		}
		catch(Exception e)
		{
			system.debug('Exception in updating contract: '+e.getMessage());
			Database.rollback(sp);
		}
		
		//Create Asset on Legal Contract Line Item after insert
		for(Contract_Line_Item__c cli : insertList)
		{
			Asset tempAsset = new Asset();
			tempAsset.AccountId = pList[0].Opportunity__r.AccountId;
			tempAsset.Status = 'Draft';
			tempAsset.Name = cli.Name;
			assetList.add(tempAsset);
		}
		
		//Insert Assets
		try
		{
			//Commented out for now in order to maintian status quo
			//insert assetList;
		}
		catch(Exception e)
		{
			system.debug(e.getMessage());
		}
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
		
		
		//setup parents on contract line item
		List<Contract_Line_Item__c> updateList = new List<Contract_Line_Item__c>();
		for(Id pId : programmingIds)
		{
			if(programmingParentMap.containsKey(pId))
			{
				Id parentProgrammingId = programmingParentMap.get(pId);
				Contract_Line_Item__c tempCLI = programmingToCLIMap.get(pId);
				Contract_Line_Item__c tempCLIParent = programmingToCLIMap.get(parentProgrammingId);
				tempCLI.parent__c = tempCLIParent.Id;
				updateList.add(tempCLI);
			}
		}
		try
		{
			update updateList;
		}
		catch(Exception e)
		{
			system.debug('Error in updating CLI parents: '+e.getMessage());
		}

        /*
        //make a set of products so that duplicates can be removed
        for(Contract_Line_Item__c cli : cLIList){
            productIds.add(cli.Product__c);
            OLIId2CLIIdMap.put(cli.Product_Inventory__c, cli.id);
        }
        System.debug('Product ids are ' + productIds);
        
        //loop through insert list and remove any items where product is in set productIds
        for(integer i = 0; i < insertList.size(); i++){
            if(productIds.contains(insertList[i].Product__c)){
                removeCLI.add(i);
            }
        }
        System.debug('Remove list is ' + removeCLI);
        
        //loop through removeCli and remove list items from insertList
        for(integer i = removeCLI.size()-1; i >= 0; i--){
            insertList.remove(i);
        }
        System.debug('Contract_Line_Item__c insert list after removing duplicates::' + insertList);
        
        if(insertList.size() > 0){
            try{
                saveResults = Database.insert(insertList);
                
                for(Database.SaveResult result : saveResults){
                    newCLIIds.add(result.getId());
                }
            } catch(Exception e){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, e.getMessage()));
            }
        } else {
            return;
        }
        
        //requery for the Contract_Line_Item__c
        insertedCLIList = [SELECT id, Product__c, Parent__c, Product_Inventory__c, Product_Inventory__r.Parent_Asset__c FROM Contract_Line_Item__c WHERE Id IN :newCLIIds];
        System.debug('Contract_Line_Item__c after insert:: ' + insertedCLIList);
        
        //loop through list and map (assetId2CLIIdMap) Product_Inventory__c to Contract_Line_Item__c id
        for(Contract_Line_Item__c cli : insertedCLILIst){
            assetId2CLIIdMap.put(cli.Product_Inventory__c, cli.id);
        }
        System.debug('full map of asset id to cli ' + OLIId2CLIIdMap);
        
        //loop through insertCLIList and put the correct parent for the Contract_Line_Item__c
        for(Contract_Line_Item__c cli : insertedCLIList){
            System.debug('Asset parent id ' + cli.Product_Inventory__r.Parent_Asset__c);
            if(cli.Product_Inventory__r.Parent_Asset__c != null){
                cli.Parent__c = OLIId2CLIIdMap.get(cli.Product_Inventory__r.Parent_Asset__c);
            }
        }
        System.debug('Contract_Line_Item__c after updates to parent::' + insertedCLIList);
        
        //update the Contract_Line_Item__c
        update insertedCLIList;
        */
    }   
    
    		
	//jjackson 5/2017 BUG-00722 the contract id passed in is for a contract amendment with extended warranty line item
	public static void CreateExtendedWarrantyServiceContract(Id conid)
	{
		system.debug('*****************BEGIN CreateExtendedWarrantyServiceContract******************');
		
		List<Contract_Line_Item__c> lstlcli = New List<Contract_Line_Item__c>();
		List<Asset> lstasset = New List<Asset>();
		Set<String> setprodparentnames = New Set<String>();
		Set<Id> setacctids = New Set<Id>();
		Map<Id,Contract_Line_Item__c> maplineitems = New Map<Id,Contract_Line_Item__c>();
		//get the extended warranty line items related to the contract id
		lstlcli = [ Select Id, name, legal_contract__c, legal_contract__r.extended_warranty_start_date__c,
		            legal_contract__r.account_name__c, parent__c, parent__r.name from 
		            contract_line_item__c where legal_contract__c = :conid
		            AND name like '%Extended Warranty%' ];
		            
		for(Contract_Line_Item__c lcli : lstlcli)
		{
			if(lcli.parent__c != null)
			{  
			  if(lcli.parent__r.name.contains('Product Parent'))  //add the product parent names to a set
			  {  setprodparentnames.add(lcli.parent__r.name);  }
			  else
			  { throw new Exceptions.UnsupportedOperationException('Extended Warranty line items must fall below a Product Parent Line.'); }
			}
			else
			{  throw new Exceptions.UnsupportedOperationException('Extended Warranty line items must fall below a Product Parent Line.'); }
			
			maplineitems.put(lcli.id, lcli); //add the extended warranty line items to a map
			setacctids.add(lcli.legal_contract__r.account_name__c); //create a set of related account id's
		}

		lstasset = [Select Id, Name, Status, AccountId, (Select Name, AccountId, AssetId, Status, servicecontractid,
		            ServiceContract.Id, ServiceContract.EndDate, ServiceContract.Status from Entitlements) from
		            Asset where Name in :setprodparentnames AND AccountId in :setacctids AND Status = 'Installed Activated' ];
		            
		//separate the related entitlements from the assets so they can be related to the new extended warranty service contract
		Map<String, Entitlement> mpasset2entitlement = New Map<String, Entitlement>();
		Map<String, Id> mpasset2lcli = New Map<String, Id>();
		List<Entitlement> lstupdscenddate = New List<Entitlement>();
		
		for(Asset pi : lstasset) //loop through the asset list and the entitlements that are related to them
		{
			system.debug('asset product parent is ' +pi.name);
			for(Entitlement ent : pi.entitlements)
			{   
								
				if(ent.servicecontractid != null && ent.ServiceContract.Status == 'Active')
				{ 
					ent.ServiceContract.EndDate = system.today();
					lstupdscenddate.add(ent);
				}
				
				system.debug('entitlement status is ' +ent.status);
				if(ent.status == 'Active') //for every active entitlement, put the product parent name+account id as key and ent id as value
				{mpasset2entitlement.put(pi.name+pi.accountid,ent);  
				system.debug('key just added to mpasset2entitlement is ' +pi.name+pi.accountid);}
				mpasset2lcli.put(pi.name+pi.accountid,pi.id);

				
			}	
		}
		
		//if the service contract related to the entitlement above is active, set the enddate to today
		//so it will expire.  Do the update to commit the change to the old service contract before
		//relinking the entitlement to the extended warranty service contract in the code below
		if(lstupdscenddate.size() > 0)
		{
			try{  update lstupdscenddate;  }
			catch(Exception exp)
			{ system.debug('ERROR updating service contract enddates line 1773: ' +exp.getmessage()); }
		}

		//now loop through the extended warranty line items again to create the service contract
		//add each new service contract to an empty list for insert
		List<ServiceContract> lstnewsc = New List<ServiceContract>();
		for(Contract_Line_Item__c item : lstlcli)
		{
			ServiceContract newsc = New ServiceContract();
			
			newsc.Name = item.Name;
			newsc.AccountId = item.legal_contract__r.account_name__c;
			newsc.Legal_Contract_Line_Item__c = item.id;
			newsc.StartDate = item.legal_contract__r.extended_warranty_start_date__c;
			newsc.Term = 1;
			
            newsc.enddate = item.legal_contract__r.extended_warranty_start_date__c.addmonths(1);
			system.debug('sc end date is ' +item.legal_contract__r.extended_warranty_start_date__c.addmonths(1));
			//get the asset record that matches the product parent name + accountid of the current line item
			if(mpasset2lcli.containskey(item.parent__r.name+item.legal_contract__r.account_name__c))
			{	
				newsc.Product_Inventory__c = mpasset2lcli.get(item.parent__r.name+item.legal_contract__r.account_name__c);
				system.debug('map key for mpasset2lcli is ' +item.parent__r.name+item.legal_contract__r.account_name__c);
			}
			else
			{
				throw new Exceptions.UnsupportedOperationException('Custom Contract Logic line 1767: Product Parent plus accountid key not found for: ' +item.id);
			}
			
			lstnewsc.add(newsc);
	
		}//end for loop for the lstlcli
		
		if(lstnewsc.size() > 0)
		{
			try{ insert lstnewsc;  }
			catch(Exception e)
			{
				system.debug('Error Inserting Extended Warranty Service Contract: ' +e.getmessage());
			}
		}

		//now get the extended warranty service contracts just inserted so they can be related to the entitlements in mpasset2entitlement
		List<ServiceContract> lstnewservicecons = New List<ServiceContract>();
		List<Entitlement> lstupdateentitlements = New List<Entitlement>();
		lstnewservicecons = [Select Id, Name, product_inventory__c, product_inventory__r.name, accountid , legal_contract_line_Item__c from
		                     ServiceContract where legal_contract_line_item__c in :lstlcli ];
		                     
		for(ServiceContract sc : lstnewservicecons)
		{
			String key = String.valueof(sc.product_inventory__r.name)+String.valueof(sc.accountid);
			system.debug('key for mpasset2entitlementmap is ' +key);
			Entitlement activeent = New Entitlement();
			if(mpasset2entitlement.containskey(key))
			{

				activeent = mpasset2entitlement.get(key);
				activeent.servicecontractid = sc.id;
				lstupdateentitlements.add(activeent);
			}
			else
			{
				system.debug('CustomContractLogic Line 1819: No matching entitlement for service contract ' +sc.product_inventory__c);
			}
		}//end of service contract for loop
		
		if(lstupdateentitlements.size() > 0)
		{
			try{  update lstupdateentitlements;  }
			catch(Exception ex)
			{ system.debug('CustomContractLogic Line 1837: Error updating entitlements: ' +ex.getmessage()); }
		}
		
		system.debug('****************END CreateExtendedWarrantyServiceContract*********************');		                   
		                     
	}//end of createextendedwarrantyservicecontract class
		     
}//end of customcontractlogicclass