// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 06/17/2013
// Description:  Class for Opportunity TriggerLogic
// 
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
//jjackson changes to contract request case and network engineering request May 2015
// *********************************************************************************************

/*jjackson 11/2018:  CPQ Project - added new method CustomQuoteFieldsToOpp to sync custom field values from the standard
  quote object to the matching fields in the opportunity object.  This is trigger code that runs when the syncedquote field 
  on the opportunity changes.
shawks 20180927: CPQ Project - Update alertContractAdmins method -> Replace Contract__c object references with Contract object
   - and all Opportunity__c references with SBQQ__Opportunity__c
   ---
   jjackson 6/2018 BUG-00792 Update createContractRequest method to include Healthcare opportunities.  The
   current code excludes Healthcare from the checkbox functionality.
   jjackson 4/2018 lightning transition project
   New method AssignorCreatePrimaryContact to automatically create an opportunity contact role record
   and mark it as primary for whichever contact is linked in the Proposal_Recipient__c (Primary Contact)
   field on the opportunity.  Also commented out code related to the creation of GIA Network Engineering Cases,
   since this is no longer part of the business process.  Removed validation code requiring an opportunity  have
   a primary contact to change the opportunity to closed-won or other values.  This can be done with a validation
   rule on the opportunity field going forward.
*/


public without sharing class  OpportunityTriggerLogic { 
    
    //******************************************************************************************
    //Author: Etherios
    //Parameters: Trigger.new, Trigger.oldMap
    //Description: Logic for creating or updating a Contract Request related to Opportunity
    //only one Active Contract Request should exist at one time per Opportunity
    //jjackson 4/16/2015 changing this to allow more than one case per opportunity as well
    //as creating a Network Engineering case, method createNetworkEngineeringCase  BUG-00459
    //******************************************************************************************
    public static void createContractRequest(List<Opportunity> opList, Map<Id,Opportunity> opOldMap)
    {
        Utilities.writeLog('**********    START', OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        
        Id hospopid = Utilities.RecordTypeNameToId('Opportunity','Hospitality Opportunities');
        Id hcoppid = Utilities.RecordTypeNameToId('Opportunity', 'Healthcare Opportunities'); //jjackson 6/2018
        
        //of the opportunities in trigger.new, pick out the ones that meet the criteria for creating a contract request case
        //if opOldMap is null (new insert), look for create_contract_request__c = true for opportunities that were cloned
        Set<Id> setcreatecases = New Set<Id>();
        List<Opportunity> lstcreatecases = New List<Opportunity>();
        List<Opportunity> lstupdateopps = New List<Opportunity>();
        for(Opportunity newop : opList)
        {   
    	
            if(opOldMap == null)  //if inserting
            {
            	
                if(newop.Create_Contract_Request__c == true)
                {   setcreatecases.add(newop.Id);    
                    lstcreatecases.add(newop);  
                    
                    if(newop.proposal_recipient__c == null && (newop.recordtypeid == hospopid || newop.recordtypeid == hcoppid))
                    {newop.adderror('You must add a contact to the Primary Contact field on ' +newop.name +' to create a Contract Request.'); 
                     return;
                    }
                    
                }
            }
            else
            {
                if(opOldMap.get(newop.id).Create_Contract_Request__c == false && newop.Create_Contract_Request__c == true)
                {   setcreatecases.add(newop.Id);    
                    lstcreatecases.add(newop);  
                    
                    if(newop.proposal_recipient__c == null && (newop.recordtypeid == hospopid || newop.recordtypeid == hcoppid))
                    { newop.adderror('You must add a contact to the Primary Contact field on ' +newop.name +' to create a Contract Request.');  
                      return;
                    }
                }
            }
        }
        

        String rectypename = 'Contract Request';
        //Need Record type for Case
        ID rtId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_ContractRequest);

        if(rtId == null)
        {
            Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Contract Request record type not found.', OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
            opList[0].addError('Contract Request record type not found');
            return;  //if the Contract Request record type is not found, don't go any further
        }
        //else  //jjackson omitted this 6/2018
        //{
        //    Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Record type found. ' + rtId, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        //}               
 
        //jjackson find all open cases related to the opportunity so they can be closed before creating a new one
        List<Case> contractRequestList = [SELECT Id, Opportunity__c,Status,OwnerId, Subject from Case WHERE Opportunity__c IN :setcreatecases AND Status != 'Cancelled'
                                          AND Status != 'Closed - Completed' AND RecordTypeId = :rtId];

        //Map to easily get the relevent Contract Request for Opportunity
        Map<Id,Case> contractRequestMap = new Map<Id,Case>(); 

        //jjackson Modify existing contract requests and change them to cancelled
        List<Case> crToModify = new List<Case>(); 
        List<CaseComment> commlist = new List<CaseComment>();
        //List of Contract Requests that must be inserted first before a Chatter Post can be made
        List<Case> crToInsertWithChatter = new List<Case>(); 

        //Map<Id, ConnectApi.FeedItemInput> crFeedItemMap = new Map<Id,ConnectApi.FeedItemInput>(); //Used to keep track of Chatter items for Insert

        List<FeedItem> fiList = new List<FeedItem>();
        Map<Id,Id> crUserMap = new Map<Id,Id>();
        
        for(Case cr : contractRequestList)
        {
            contractRequestMap.put(cr.Opportunity__c, cr);  //map contains opportunity id and related case
            system.debug('adding case record to contractRequestMap: ' +cr.Opportunity__c +', ' + cr.Id +', ' + cr.subject);
        }

        //Utilities.writeLog('bl_Oppportunity:createContractRequest: Contract Request Map : '+contractRequestMap, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 

        //Loop through to find Primary Contact Role
               
        Set<Id> hosopps = New set<Id>();
        for(Opportunity op : lstcreatecases)
        {   //String opprectype = Utilities.RecordTypeIdtoName('Opportunity', op.RecordTypeId);
            if(op.recordtypeid == hospopid || op.recordtypeid == hcoppid) //only add Hospitality & Healthcare opps to the list
            {   
                hosopps.add(op.Id);
            }
        }
        
        List<OpportunityContactRole> ocrList = [SELECT Contact.Email, OpportunityId, ContactId, Role from OpportunityContactRole WHERE OpportunityId IN :hosopps AND IsPrimary = true];
        Map<Id,OpportunityContactRole> ocrMap = new Map<Id,OpportunityContactRole>();
        
        system.debug('ocrlist size is ' +ocrList.Size());
        for(OpportunityContactRole ocr : ocrList)
        {
                ocrMap.put(ocr.OpportunityId,ocr);
                system.debug('Opportunity added to ocr map is ' + ocr.OpportunityId + ', ' +ocr.Role);
        }

        //Main loop through Opportunities
        for(Opportunity op: lstcreatecases)
        {
          if(op.Create_Contract_Request__c == true)
          {  //if there is no existing contract request case on the opportunity and box is checked go ahead and create case
            if(!contractRequestMap.containsKey(op.Id))
                {    crToInsertWithChatter.add(OpportunityTriggerLogic.addContract(op, rtId, ocrMap, rectypename));
                    system.debug('opportunity added to crToInsertWithChatter is ' + op.Name);
   
                }
            
            //if there is an existing contract request and the box is checked, close the existing case and create a new one
            if(contractRequestMap.containsKey(op.Id) && op.Create_Contract_Request__c == true)
 
                {   Case crExisting = contractRequestMap.get(op.Id); //get Existing Contract Request case to close it
                     
                     crExisting.Status = 'Cancelled';
                     crToModify.add(crExisting);
                     crToInsertWithChatter.add(OpportunityTriggerLogic.addContract(op, rtId, ocrMap, rectypename));
                     system.debug('opportunity added to crExisting is ' +op.Name);
                } 
                
          }//end if create_contract_request__c == true
               
         } //end for loop
       
		 system.debug('OpportunityTriggerLogic:createContractRequest: Contract Requests to be Inserted/Updated : '+crToModify); 


        if(crToModify.size() > 0) 
        {
            try{
                update crToModify;
            }
            catch(DMLException e)
            {
                opList[0].addError('Cannot update Case related to Opportunities, error is :'+e.getMessage());  
            }
            
            for(Case crexisting : crToModify) 
            {
            //Chatter updates 
                system.debug('Case being cancelled is ' +crexisting.Id +', ' + crexisting.Subject);
                fiList.add(createContractRequestFeedItem(crexisting.Id)); 
                Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Chatter FeedItems to be Inserted : '+fiList, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
            }
            

        }
        
        if(crToInsertWithChatter.Size() > 0 )
        {
            try{ insert crToInsertWithChatter;  }
            catch(DMLException err)
            {  opList[0].addError('Cannot insert case related to Opportunities, error is : '  +err.getMessage());  }
        
        }
        

        if(fiList.size() > 0) {
              try { insert fiList;  }
              catch (DMLException ex)
              {   opList[0].addError('Cannot create feed item related to case, error is : ' +ex.getMessage());  }
            } //end if filist size      
            
 
        Utilities.writeLog('**********    END', OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        
  
   } //end method

 //jjackson 4/2018 this code removed because no longer needed, per the business during sales team lightning transition
 /*    public static void createNetworkEngineeringCase(List<Opportunity> opList, Map<Id,Opportunity> opOldMap)
    {
        Utilities.writeLog('**********    START', OpportunityTriggerLogic.class, 'createNetworkEngineeringCase', LoggingLevel.DEBUG); 
        
        List<Opportunity> lstprocessopp = New List<Opportunity>();
        
        //determine which opportunities in the trigger require network engineering cases
        for( Opportunity newop : opList )
        {
          	 	
            if(newop.GIA_Network_Engineering_Request__c == true && opOldMap.get(newop.Id).GIA_Network_Engineering_Request__c == false)
            {   
                
                if(newop.proposal_recipient__c == null && newop.recordtypeid == opprectype)
        	    {
        		newop.addError('You must add a Primary Contact to opportunity ' +newop.name +' to create a Networking Engineering Case.');  
        		return;
        	    }
                  	
                lstprocessopp.add(newop);
            }
        }
  
        String rectypename = 'Network Engineering';
       //Need Record type for Case
       //ID rtId = Utilities.RecordTypeNameToIdWithObject(Definitions.RECORDTYPE_Network_Engineering, 'Case');  DEPRECATED
       ID rtId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Network_Engineering);
        if(rtId == null)
        {
            Utilities.writeLog('OpportunityTriggerLogic:createNetworkEngineeringCase: Network Engineering record type not found.', OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
            opList[0].addError('Network Engineering case record type not found');
        }
        else
        {
            Utilities.writeLog('OpportunityTriggerLogic:createNetworkEngineeringCase: Record type found. ' + rtId, OpportunityTriggerLogic.class, 'createNetworkEngineeringCase', LoggingLevel.DEBUG); 
        }             
        
        Set<Id> hosopps = New set<Id>();
        for(Opportunity op : lstprocessopp)
        {   String opprectype = Utilities.RecordTypeIdtoName('Opportunity', op.RecordTypeId);
            if(opprectype == 'Hospitality Opportunities')
            {   
                hosopps.add(op.Id);
            }
        }
       
        List<OpportunityContactRole> ocrList = [SELECT Contact.Email, OpportunityId, ContactId from OpportunityContactRole WHERE OpportunityId IN :hosopps AND IsPrimary = true];
        Map<Id,OpportunityContactRole> ocrMap = new Map<Id,OpportunityContactRole>();
        
        //Loop through to find Primary Contact Role
         for(OpportunityContactRole ocr : ocrList)
            {
                ocrMap.put(ocr.OpportunityId,ocr);
            }
        List<Case> lstneteng = New List<Case>();
        List<FeedItem> fiList = New List<FeedItem>();
        
        for(Opportunity opp : lstprocessopp)
        {   
             Case neNew = addContract(opp,rtId,ocrMap,rectypename);
             lstneteng.add(neNew);
                          
             //Create new Chatter update to be inserted on the opportunity
              fiList.add(NECaseCreated(opp.Id));
              
              Utilities.writeLog('OpportunityTriggerLogic:createNetworkEngineeringCase: Network Engineering Requests to be Inserted: '+neNew, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
          
        }                              
        
 
        if(lstneteng.Size() > 0) {
            try{
                insert lstneteng;
            }
            catch(DMLException e)
            {
                opList[0].addError('Cannot insert Network Engineering Case related to Opportunities, error is :'+e.getMessage());  
            }
        }

        
        Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Chatter FeedItems to be Inserted : '+fiList, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        if(fiList.size() > 0) {
            insert fiList;
        }
        

        Utilities.writeLog('**********    END', OpportunityTriggerLogic.class, 'createNetworkEngineeringCase', LoggingLevel.DEBUG); 
        
  } //end method  */
    
  
    //jjackson--this is for adding a contract request CASE, not for adding a legal contract
    private static Case addContract(Opportunity op, ID rtId, Map<Id,OpportunityContactRole> ocrMap, String caserectype)
    {
        Case crNew = new Case();
        crNew.AccountId = op.AccountId;
        //Calculate case subject
        
        If(caserectype == 'Contract Request')
        {  String subject = 'Contract Request - '+ op.Name;
           Integer subjectLength = subject.length() > 254? 254 : subject.length();
           crNew.Subject = subject.substring(0,subjectLength);
        
            crNew.Case_Quota_Category__c = op.Quota_Categories__c;
            
            if(ocrMap.containsKey(op.Id))
            {
            	
                crNew.contactid = ocrMap.get(op.Id).ContactId; //populate contactid field on case instead of client_contact__c
               //jjackson 6/2018--no need to populate contactemail, as this is a formula field
               // crNew.contactemail = ocrMap.get(op.Id).Contact.Email; //populate contactemail field on case instead of recipient_email__c
              }
            //crNew.Management_Company__c = op.Account.Management_Group__c;  This is now a formula field that pulls mgmt co from account
            crNew.RecordTypeId = rtId;
            crNew.Description = op.Special_Instructions__c;
            crNew.Opportunity__c = op.Id;
            crNew.Status = 'Requested';
            //****SGP 03/12/2014 - Changed per SOW0003 - Sonifi Enhancements - Sprint 5 - Req 8.2
            //****crNew.OwnerId = queueId;   
            crNew.OwnerId = op.OwnerId;
            crNew.RSM_Name__c = op.OwnerId;
        }
        /*else  jjackson 4/2018 no longer needed because network engineering cases no longer used
        {  
           String subject = 'Network Engineering Request - '+ op.Name;
           Integer subjectLength = subject.length() > 254? 254 : subject.length();
           crNew.Subject = subject.substring(0,subjectLength);
           //crNew.Management_Company__c = op.Account.Management_Group__c;
           crNew.RecordTypeId = rtId;
           crNew.Opportunity__c = op.Id;
           crNew.Status = 'Requested';
           crNew.OwnerId = op.OwnerId;
        }  */
        
        return crNew;
    }

 //jjackson as of 4/2018 this code no longer needed. comment out per the business during sales team lightning transition.
 /*   public static void opportunityPrimaryContactCheck(List<Opportunity> opList)
    {
        List<ID> opListID = new List<ID>();
        String rectypename;
        Set<Id> hosopps = New Set<Id>();
        
        //jjackson May 2015 only check for primary contact if it is a hospitality opportunity
        for(Opportunity op: opList)
        {
            
            rectypename = Utilities.RecordTypeIdtoName('Opportunity', op.RecordTypeId);
            system.debug('PrimaryContactCheck opportunity is ' +op.Name +', ' +rectypename);
            if(rectypename == 'Hospitality Opportunities')
            {   
                hosopps.add(op.Id);
            }
            
        }
                //Loop through to find Primary Contact Role
        List<OpportunityContactRole> ocrList = [SELECT Contact.Email, OpportunityId, ContactId from OpportunityContactRole WHERE OpportunityId IN :hosopps AND IsPrimary = true];
        Map<Id,OpportunityContactRole> ocrMap = new Map<Id,OpportunityContactRole>();
        system.debug('in PrimaryContactCheck, ocrlist size is ' +ocrList.Size());
        
        If(!hosopps.IsEmpty())
        { for(OpportunityContactRole ocr : ocrList)
          {
            ocrMap.put(ocr.OpportunityId,ocr);
          }
          for(Opportunity o : opList)
          {
            //if(o.StageName== 'Approved Proposal' || o.StageName == 'Contract Sent' || o.StageName == 'Closed Won')
            //jjackson 7/28/2014  Remove stagename values except Closed Won and add check for Create_Contract_Request__c
            if(o.StageName=='Closed Won'||o.Create_Contract_Request__c==true||o.GIA_Network_Engineering_Request__c == true)
            {
                system.debug('PrimaryContactCheck inside opportunity for loop ' +o.Name);
                if(!ocrMap.containsKey(o.Id) && hosopps.Contains(o.Id))
                {
                    o.Create_Contract_Request__c = false;  //prevent case from being created if this error is thrown
                    String link = '<a href =\"'+URL.getSalesforceBaseUrl().toExternalForm()+'/p/opp/ContactRoleEditUi/e?oppid='+o.Id+'&retURL=%2F'+o.Id+'\"> Click to Add </a>';
                    o.addError('Primary Contact must be added to the Contact Roles for this Opportunity '+link, false);                
                }
            }
          }
        }   
    }*/
    

    private static FeedItem createContractRequestFeedItem(Id parentId)
    {
        FeedItem fi = new FeedItem();
        fi.ParentId = parentId;
        fi.body = 'Contract Request was cancelled because a new one was created for the Opportunity.';
        return fi;      
    }
    
    /*private static FeedItem NECaseCreated(Id oppid)
    {
        FeedItem fi = new FeedItem();
        fi.ParentId = oppid;
        fi.body = 'Network Engineering Case was created for this opportunity on ' + system.today();
        return fi;      
    } *///jjackson 6/2018 the Network Engineering case functionality is no longer needed
    
    //shawks 20180927: CPQ Project - Replace all Contract__c object references with Contract object
    // and all Opportunity__c references with SBQQ__Opportunity__c in this method    
    public static void alertContractAdmins(List<Opportunity> opList, Map<Id,Opportunity> opOldMap)
    {
        Set<Id> opIds = new Set<Id>();
        for(Opportunity o : opList)
        {
          opIds.add(o.Id);
        }
        
        Set<String> contractStatuses = new Set<String>();
        
        for(String statusName : OpportunityRelatedContractAlertStatuses__c.getAll().keyset())
        {
            contractStatuses.add(statusName);
        }
        //List<Contract__c> contracts = [SELECT Opportunity__c from Contract__c WHERE Opportunity__c IN : opIds AND Status__c IN :contractStatuses];
        List<Contract> contracts = [SELECT SBQQ__Opportunity__c from Contract WHERE SBQQ__Opportunity__c IN : opIds AND contract_status__c IN :contractStatuses];

        Set<Id> opportunityWithContracts = new Set<Id>();
        //for(Contract__c c : contracts)
        for(Contract c : contracts)
        {
          //opportunityWithContracts.add(c.Opportunity__c);
          opportunityWithContracts.add(c.SBQQ__Opportunity__c);
        }
        List<Opportunity> opChanged = new List<Opportunity>();  
    
        for(Opportunity o : opList)
        {
          if((o.Amount != opOldMap.get(o.Id).Amount) && opportunityWithContracts.contains(o.Id))
          {
            opChanged.add(o);
          }
        }
        //get Contract admins
        List<User> contractUsers = new List<User>();
        String contractManagerProfile = Utilities.ProfileNameToId('Contract Manager');
        String contractAdminSpecialistProfile = Utilities.ProfileNameToId('Contracts Admin Specialist');
        
        List<User> contractManager = [SELECT Id from User WHERE ProfileId = :contractManagerProfile];
        List<User> contractAdminSpecialist = [SELECT Id from User WHERE ProfileId = :contractAdminSpecialistProfile];
        //shawks 201811 CPQ: Remove \n since not generating new lines newer releases
        //String message = 'The following Opportunities have changed: \n ';
        String message = 'The following Opportunities have changed: ';
        for(Opportunity o : opChanged)
        {
            //message+=o.Name+'\n';
            message = message + o.Name + ';';
        }
        contractUsers.addAll(contractManager);
        contractUsers.addAll(contractAdminSpecialist);
        Map<Id,String> chatterMap = new Map<Id,String>();
        for(User u : contractUsers)
        {
            chatterMap.put(u.Id,message);
        }                
        //Call another function here
        if(opChanged.size() > 0)
          ChatterUtilities.doChatterPosts(chatterMap);                                                                                                  
    }

    public static void updateSiteSurvey(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        //check to make sure new list is not empty
        if(newList == null || newList.isEmpty()) {
            throw new Exceptions.IllegalArgumentException('Opportunity new list is empty or missing');
        }
        
        //write log
        Utilities.writeLog('Update site survey for ' + newList.size() + ' opportunities.',
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);
       // Only change the rooms with a status of 
       //   Schedule Survey
       //   Scheduled
       //   In Progress
       //   On Hold
       // on the Site Survey
            
       //**********************************************
       // Process flow
       //  Gather a list of all Opportunity IDs
       //   soql of Site_survey__c for all matching Opportunity Ids
       //   Update each Site_survey__c number of rooms field from the Opportunity 
       //     when the status of the Site_survey is equal to above.
       //   
       //**********************************************

        Set<Id> opIds = new Set<Id>();
        
        // Gather all the Opportunities where the Old and New version's Room numbers change
        for (Opportunity opList: newList) {
            if(oldMap != null) {
                if(opList.of_Rooms_Opportunity__c != oldMap.get(opList.id).of_Rooms_Opportunity__c) { 
                    opIds.add(opList.Id);
                }
            } else {
                opIds.add(opList.Id);
            }
        }
        
        
        //query for the site surveys that are attached to the opportunity
        List<Site_Survey__c> siteSurveyList = [SELECT 
                                                  Id, 
                                                  Opportunity__c, 
                                                  Number_of_Rooms__c, 
                                                  Status__c 
                                               FROM 
                                                  Site_Survey__c 
                                               WHERE 
                                                  Opportunity__c IN :opIds 
                                                  AND Status__c IN :Opportunity_Site_Survey_Update_Status__c.getAll().keySet()];

        
        List<Opportunity> oppList = [SELECT 
                                        Id, 
                                        of_Rooms_Opportunity__c 
                                     FROM 
                                        Opportunity 
                                     WHERE 
                                        Id IN :opIds];

        Utilities.writeLog('Update site survey Sitesurvey list '+siteSurveyList+ ' size '+siteSurveyList.size(),
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);

        Utilities.writeLog('Update site survey Opportunity list '+oppList + ' size '+oppList.size(),
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);
        
        List<Site_Survey__c> updateSiteSurveys = new List<Site_Survey__c>();                   
        for (Opportunity upopList: oppList) {
            Utilities.writeLog('Update site opportunity ID ..........'+upoplist.id,
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);

           for (Site_Survey__c siteitem : siteSurveyList)
           {
              if  (siteitem.Opportunity__c == upoplist.id) 
              {
                 updateSiteSurveys.add(New Site_Survey__c(Id=siteItem.Id, 
                                                          Number_of_Rooms__c=upoplist.of_Rooms_Opportunity__c));       
                 Utilities.writeLog('Update site Sitesurvey ID ..........'+siteitem.id+' '+siteitem.Opportunity__c+ ' status '+siteitem.Status__c+'  rooms '+siteitem.Number_of_Rooms__c,
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);
                 
              }
           }
        }                            
          
        if(updateSiteSurveys.size() > 0){
            update updateSiteSurveys;
        }     
        
        Utilities.writeLog('Exit Update site survey..........total '+updateSiteSurveys.size(),
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);
        
    }
    
    public static void AssignorCreatePrimaryContact(List<Opportunity> triggernewlist, Map<Id, Opportunity> trigoldmap, String triggertype)
    {
    	List<Opportunity> opplist = New List<Opportunity>();
     	List<OpportunityContactRole> oppconlist = New List<OpportunityContactRole>();
    	List<OpportunityContactRole> updoclist = New List<OpportunityContactRole>();
    	List<OpportunityContactRole> newoclist = New List<OpportunityContactRole>();
     	Map<Id,OpportunityContactRole> mapopcon = New Map<Id,OpportunityContactRole>();
     	Map<Id, List<OpportunityContactRole>> mapopconlist = New Map<Id,List<OpportunityContactRole>>();
     	Set<Id> setoppnoprimary = new Set<Id>();
     	
     	    	
    	system.debug('*********BEGIN AssignorCreatePrimaryContact**************');
    	//loop through the opportunities in the trigger to determine whether a primary contact is
    	//being linked to the opportunity
    	for(Opportunity op : triggernewlist)
    	{
    		
    		
    		if(triggertype == 'Insert' && (op.proposal_recipient__c != null || op.proposal_recipient__c !='' )) //if this is a new opportunity record
    		{   opplist.add(op);  }
    		
    		system.debug('opplist size at insert is ' +opplist.size());
    		
    		if(triggertype == 'Update' && op.proposal_recipient__c != null && //if the primary contact is changed on the record
    		   (trigoldmap.get(op.id).proposal_recipient__c != op.proposal_recipient__c))
    		{   opplist.add(op);  }
    		
    		if(triggertype == 'Update' && op.proposal_recipient__c == null && //if the primary contact is changed on the record
    		   (trigoldmap.get(op.id).proposal_recipient__c != op.proposal_recipient__c))
   			{ setoppnoprimary.add(op.Id);  
   			  opplist.add(op);
   			}
    		
    	 }
    	 
    	 if(opplist.size() > 0)
    	 {
    	 	Set<Id> setoppids = New Set<Id>();
    	 	for(Opportunity o : opplist)
    	 	{   setoppids.add(o.id);  
    	 	   // mapopp.put(o.id, o); //add all the needed opportunities to a map --might not need this
    
    	 	}
    	 	
    	 	//Query for the OpportunityContactRole records that are related to the opportunities in opplist
    	 	oppconlist=[select opportunityid, contactid, isprimary from OpportunityContactRole where opportunityid in :setoppids ];
    	 }
    	 
    	 system.debug('oppconlist size is ' +oppconlist.size());
    	 
    	 if(oppconlist.size() > 0)
    	 {
    	 	for(OpportunityContactRole opcon : oppconlist) //add the opportunitycontactrole records to map with contactid as key
    	 	{ mapopcon.put(opcon.contactid, opcon); 
    	 	
    	 		//create a map of Id, List<OpportunityContactRole> so you can spin through all the other
    	 		//opportunitycontactrole records related to the opportunity and remove any IsPrimary designation
    	 		if(mapopconlist.containskey(opcon.opportunityid))
    	 		{
    	 			mapopconlist.get(opcon.opportunityid).add(opcon);
    	 		}
    	 		else
    	 		{
    	 			List<OpportunityContactRole> templist = New List<OpportunityContactRole>();
    	 			templist.add(opcon);
    	 			mapopconlist.put(opcon.opportunityid, templist);
    	 		}
    	 	
    	 	}
    	 }
    	 
    	 for(Opportunity opp : opplist)
    	 {
    	     OpportunityContactRole ocr;
    	     system.debug('opp id is ' +opp.id);
    	     system.debug('opp proposal recipient is ' +opp.proposal_recipient__c);
    	     
    	    if(opp.proposal_recipient__c != null)
    	    {
    	 	  if(mapopcon.size() > 0)
    	 	  {
    	 	  	if(mapopcon.containskey(opp.proposal_recipient__c))
    	 	  	{
    	 	  	 ocr = mapopcon.get(opp.proposal_recipient__c);
    	 	  	 if(ocr.opportunityid == opp.id)
    	 	  	 {
    	 	  	 	ocr.IsPrimary = true;
    	 	  	 	updoclist.add(ocr);
    	 	  	 }
    	 	    }
    	 	  }//end if mapopcon size > 0
    	 	  
    	 	  if(mapopcon.size() < 1 || !mapopcon.containskey(opp.proposal_recipient__c))
    	 	  {
    	 	  	   OpportunityContactRole newocr = New OpportunityContactRole();
    	 	  	   newocr.opportunityid = opp.id;
    	 	  	   newocr.contactid = opp.proposal_recipient__c;
    	 	  	   newocr.isprimary = true;
    	 	  	   newocr.role = 'Decision Maker';
    	 	  	   newoclist.add(newocr);
    	 	  }
    	     
    	 	  
    	 	  if(mapopconlist.size() > 0)
    	 	  {
    	 	  	if(mapopconlist.containskey(opp.id))
    	 	  	{
    	 	  	 List<OpportunityContactRole> listocr = mapopconlist.get(opp.id);
    	 	  	 for(OpportunityContactRole conrole : listocr)
    	 	  	 {
    	 	  	 		if(conrole.contactid != opp.proposal_recipient__c && conrole.IsPrimary == true)
    	 	  	 		{  conrole.IsPrimary = false;
    	 	  	 	   		updoclist.add(conrole);
    	 	  	 		}
    	 	  	 	
    	 	  	 }
    	 	  	}//end if mapopconlist containskey
    	 	  }//end if mapopconlist size
    	    }//end if opp.proposal_recipient__c != null
    	    else
    	    {
    	    	if(setoppnoprimary.contains(opp.Id))
    	    	{
    	    		if(mapopconlist.containskey(opp.id))
    	    		{
    	    			List<OpportunityContactRole> conrolelist = New List<OpportunityContactRole>();
    	    			conrolelist = mapopconlist.get(opp.id);
    	    			for(OpportunityContactRole contactrole : conrolelist)
    	    			{
    	    				contactrole.isprimary = false;
    	    				updoclist.add(contactrole);
    	    			}
    	    			
    	    		}
    	    	}
    	    }
    	    
    	 }//end for loop opplist
    	    	 
    	 if(updoclist.size() > 0)
    	 {
    	 	update updoclist;
    	 }
    	 
    	 if(newoclist.size() > 0)
    	 {
    	 	insert newoclist;
    	 }
    	 
    	 system.debug('****************END AssignorCreatePrimaryContact************ ');
    }
    
    public static void CPQCustomQuoteFieldsToOpp(List<Opportunity> triggernewlist, Map<Id,Opportunity> triggeroldmap)
    {
    	system.debug('***********BEGIN CustomQuoteFieldsToOpp***************');
    	
    	Map<Id,Opportunity> mpopptoquote = New Map<Id,Opportunity>();
    	Map<Id,Opportunity> mpremovequote = New Map<Id,Opportunity>();
    	List<SBQQ__Quote__c> lstprimaryquote = New List<SBQQ__Quote__c>();
    	List<Opportunity> lstremovequotevals = new List<Opportunity>();
    	List<Opportunity> lstupdateopportunities = new List<Opportunity>();
    	List<Opportunity> lstupdateopp = New List<Opportunity>();
    	Set<Id> setsyncedquoteids = New Set<Id>();
    	
    	//for the opportunities in the trigger, figure out which one had a change to the SyncedQuote field
    	//or whether a SyncedQuote was removed from that field
    	for(Opportunity o :triggernewlist)
    	{
    		if(o.SBQQ__PrimaryQuote__c !=null)
    		{
    		  if(triggeroldmap.get(o.id).SBQQ__PrimaryQuote__c == null || o.SBQQ__PrimaryQuote__c != triggeroldmap.get(o.id).SBQQ__PrimaryQuote__c)
    		  {  mpopptoquote.put(o.SBQQ__PrimaryQuote__c, o); }
    		}
    		
    		if(o.SBQQ__PrimaryQuote__c == null && triggeroldmap.get(o.id).SBQQ__PrimaryQuote__c != null)
    		{  mpremovequote.put(o.id, o); }
    	}
    	
    	system.debug('mpopptoquote size is ' +mpopptoquote.size());
    	system.debug('mpremovequote size is ' +mpremovequote.size());
    	
    	//if there are opportunities where the primary quote field value changed, use an
    	//SObject method to add all the CPQ quote fields to a map, then create a query string that
    	//will query all of the quote fields.  This is easier than typing out 100 quote fields in
    	//a soql query
    	//SAMPLE Code:  Create a soql query for a lot of fields using Schema getGlobalDescribe
    	if(mpopptoquote.size() > 0)
    	{	
    		List<String> lstmapkeys = New List<String>();
    		for(Id key :mpopptoquote.keyset())
    		{  lstmapkeys.add(string.valueof(key)); }
			
			system.debug('lstmapkeys are' +lstmapkeys);
			
    		String objectname = 'SBQQ__Quote__c';
    		String quotequery = 'Select ';
    		Map<String,Schema.SObjectField> mpquotefields = Schema.getGlobalDescribe().get(objectname).getDescribe().fields.getMap();
    		
    		for(String s :mpquotefields.keyset())
    		{  quotequery +='' +s +',';  } //this builds the query string of all quote fields
    		
    		if(quotequery.subString(quotequery.length()-1, quotequery.length()) ==',')
    		{  quotequery = quotequery.subString(0,quotequery.Length()-1);  } //strip off the comma at the end of the query string
    		
    		quotequery += ' from ' +objectname;  //add query From statement
    		
    		quotequery += ' where id in :lstmapkeys'; //add where clause
    		
    		system.debug('quotequery is ' +quotequery);
    		
    		lstprimaryquote = database.query(quotequery);
    		system.debug('lstprimaryquote size is ' +lstprimaryquote.size());
    		
    		//now loop through the list of quotes and get the matching opportunity from the map,
    		//then update the opportunity fields with quote record values
    		
    		if(lstprimaryquote.size() > 0)
    		{
    			for(SBQQ__Quote__c q :lstprimaryquote)
    			{
    				if(mpopptoquote.containskey(q.id))
    				{	
    					
    					Opportunity opp = New Opportunity();
    					opp = mpopptoquote.get(q.id);
    					opp.of_Public_Areas_that_Need_Programming__c= q.of_Public_Areas_that_Need_Programming__c;
						opp.of_Televisions__c=q.of_Televisions__c;
						opp.X1_hotel_open_HD_channel__c=q.X1_hotel_open_HD_channel__c;
						opp.X1_hotel_open_SD_channel__c=q.X1_hotel_open_SD_channel__c;
						opp.X1_HVOD_link_to_video__c=q.X1_HVOD_link_to_video__c;
						opp.X1_Main_or_Sub_Menu_Category__c=q.X1_Main_or_Sub_Menu_Category__c;
						opp.X2_hotel_open_HD_channels__c=q.X2_hotel_open_HD_channels__c;
						opp.Additional_One_time_Incentive_SoniCast__c=q.Additional_One_time_Incentive_SoniCast__c;
						opp.Add_on_Services_Recurring__c=q.Add_on_Services_Recurring__c;
						opp.Analog_Channel_Lineup_for_Public_Space__c=q.Analog_Channel_Lineup_for_Public_Space__c;
						opp.Bar_Lounge__c=q.Bar_Lounge__c;
						opp.Branding_Marketing_Per_Month__c=q.Branding_Marketing_Per_Month__c;
						opp.Chromecast_Ultra_Quantity__c=q.Chromecast_Ultra_Quantity__c;
						opp.Chromecast_Ultra_Total__c=q.Chromecast_Ultra_Total__c;
						opp.Custom_Background__c=q.Custom_Background__c;
						opp.Custom_Logo__c=q.Custom_Logo__c;
						opp.Down_Payment__c=q.Down_Payment__c;
						opp.Equip_Installation_One_Time_Fee__c=q.Equip_Installation_One_Time_Fee__c;
						opp.EVO__c=q.EVO__c;
						opp.FCO__c=q.FCO__c;
						opp.Fees_Name__c=q.Fees_Name__c;
						opp.Financing_Amount_System_Sale__c=q.Financing_Amount_System_Sale__c;
						opp.Financing_Party__c=q.Financing_Party__c;
						opp.FTG_Analog_Channels__c=q.FTG_Analog_Channels__c;
						opp.FTG_HD_Channels__c=q.FTG_HD_Channels__c;
						opp.FTG_SD_Channels__c=q.FTG_SD_Channels__c;
						opp.FTG_Equip_Installation__c=q.FTG_Equip_Installation__c;
						opp.FTG_Monthly_Programming_Fee__c=q.FTG_Monthly_Programming_Fee__c;
						opp.FTG_System_Sale_Revenue__c=q.FTG_System_Sale_Revenue__c;
						opp.GIA_Base_Guest_Access__c=q.GIA_Base_Guest_Access__c;
						opp.Group_Services_Recurring__c=q.Group_Services_Recurring__c;
						opp.Group_Services_Upfront__c=q.Group_Services_Upfront__c;
						opp.Guest_Apps_Per_Month__c=q.Guest_Apps_Per_Month__c;
						opp.Happenings_Channel__c=q.Happenings_Channel__c;
						opp.HD_Channel_Lineup__c=q.HD_Channel_Lineup__c;
						opp.Healthclubs__c=q.Healthclubs__c;
						opp.Hotel_Directory__c=q.Hotel_Directory__c;
						opp.Incentives_System_Sale__c=q.Incentives_System_Sale__c;
						opp.In_Room_Equip_Sale_Revenue__c=q.In_Room_Equip_Sale_Revenue__c;
						opp.Interactive_Program_Guide__c=q.Interactive_Program_Guide__c;
						opp.iTV_System_Installation__c=q.iTV_System_Installation__c;
						opp.IPG__c=q.IPG__c;
						opp.IPG_data_feed__c=q.IPG_data_feed__c;
						opp.IP_or_RF__c=q.IP_or_RF__c;
						opp.IRD_GR_App__c=q.IRD_GR_App__c;
						opp.Lobby__c=q.Lobby__c;
						opp.Marketing_Creative_Services_Per_Month__c=q.Marketing_Creative_Services_Per_Month__c;
						opp.MATV_One_Time_Fee__c=q.MATV_One_Time_Fee__c;
						opp.Mobile_Hotel_Directory__c=q.Mobile_Hotel_Directory__c;
						opp.Monthly_Financing_Fee__c=q.Monthly_Financing_Fee__c;
						opp.Non_Standard_Discount__c=q.Non_Standard_Discount__c;
						opp.Offer_Price_PRPM__c=q.Offer_Price_PRPM__c;
						opp.Offer_Price_One_Time__c=q.Offer_Price_One_Time__c;
						opp.On_Demand_Per_Month__c=q.On_Demand_Per_Month__c;
						opp.One_Time_Add_on_Services__c=q.One_Time_Add_on_Services__c;
						opp.Other__c=q.Other__c;
						opp.Overall_Margin_FTG__c=q.Overall_Margin_FTG__c;
						opp.Overall_Margin_FTG_One_Time__c=q.Overall_Margin_FTG_One_Time__c;
						opp.Overall_Margin_iTV__c=q.Overall_Margin_iTV__c;
						opp.Overall_Margin_iTV_One_Time__c=q.Overall_Margin_iTV_One_Time__c;
						opp.Overall_Margin_Other__c=q.Overall_Margin_Other__c;
						opp.Percentage_of_VOD_receipts__c=q.Percentage_of_VOD_receipts__c;
						opp.Percentage_of_VOD_receipts_Tier_2__c=q.Percentage_of_VOD_receipts_Tier_2__c;
						opp.Percentage_of_VOD_receipts_Tier_3__c=q.Percentage_of_VOD_receipts_Tier_3__c;
						opp.Pricing__c=q.Pricing__c;
						opp.Public_Space_Distr_Non_SMATV__c=q.Public_Space_Distr_Non_SMATV__c;
						opp.Public_Space_Distr_SMATV__c=q.Public_Space_Distr_SMATV__c;
						opp.Public_Space_Per_Month__c=q.Public_Space_Per_Month__c;
						opp.Public_Space_Prog_Pkg_1_Name__c=q.Public_Space_Prog_Pkg_1_Name__c;
						opp.Public_Space_Prog_Pkg_2_Monthly_Fee__c=q.Public_Space_Prog_Pkg_2_Monthly_Fee__c;
						opp.Public_Space_Prog_Pkg_2_Name__c=q.Public_Space_Prog_Pkg_2_Name__c;
						opp.Public_Space_Programming__c=q.Public_Space_Programming__c;
						opp.Recurring_Gross_Profit__c=q.Recurring_Gross_Profit__c;
						opp.Remaining_SONIFI_contract__c=q.Remaining_SONIFI_contract__c;
						opp.Remaining_SONIFI_contract_Total__c=q.Remaining_SONIFI_contract_Total__c;
						opp.Repayment_of_DTV_incentives__c=q.Repayment_of_DTV_incentives__c;
						opp.Repayment_of_DTV_incentives_Total__c=q.Repayment_of_DTV_incentives_Total__c;
						opp.SD_Channel_Lineup__c=q.SD_Channel_Lineup__c;
						opp.Service_Support__c=q.Service_Support__c;
						opp.Service_Support_Per_Month__c=q.Service_Support_Per_Month__c;
						opp.SoniCast_Contract_Term_Incentive_Total__c=q.SoniCast_Contract_Term_Incentive_Total__c;
						opp.SoniCast_Discount_One_time_Total__c=q.SoniCast_Discount_One_time_Total__c;
						opp.SoniCast_Down_Payment__c=q.SoniCast_Down_Payment__c;
						opp.SoniCast_Incentive_Quantity__c=q.SoniCast_Incentive_Quantity__c;
						opp.SoniCast_Incentive_Total_Price__c=q.SoniCast_Incentive_Total_Price__c;
						opp.SoniCast_Incentive_Unit_Price__c=q.SoniCast_Incentive_Unit_Price__c;
						opp.SoniCast_Initial_Term__c=q.SoniCast_Initial_Term__c;
						opp.SoniCast_Marketing_Material_Quantity__c=q.SoniCast_Marketing_Material_Quantity__c;
						opp.SoniCast_Marketing_Material_Total_Price__c=q.SoniCast_Marketing_Material_Total_Price__c;
						opp.SoniCast_Marketing_Material_Unit_Price__c=q.SoniCast_Marketing_Material_Unit_Price__c;
						opp.SoniCast_SNC_Quantity__c=q.SoniCast_SNC_Quantity__c;
						opp.SoniCast_SNC_Total_Price__c=q.SoniCast_SNC_Total_Price__c;
						opp.SoniCast_SNC_Unit_Price__c=q.SoniCast_SNC_Unit_Price__c;
						opp.SoniCast_Technology_Fee_Quantity__c=q.SoniCast_Technology_Fee_Quantity__c;
						opp.SoniCast_Technology_Fee_Total_Price__c=q.SoniCast_Technology_Fee_Total_Price__c;
						opp.SoniCast_Technology_Fee_Unit_Price__c=q.SoniCast_Technology_Fee_Unit_Price__c;
						opp.SoniCast_Total_One_time_Total_Price__c=q.SoniCast_Total_One_time_Total_Price__c;
						opp.SoniCast_Wired_Quantity__c=q.SoniCast_Wired_Quantity__c;
						opp.SoniCast_Wired_Total_Price__c=q.SoniCast_Wired_Total_Price__c;
						opp.SoniCast_Wired_Unit_Price__c=q.SoniCast_Wired_Unit_Price__c;
						opp.SoniCast_Wireless_Quantity__c=q.SoniCast_Wireless_Quantity__c;
						opp.SoniCast_Wireless_Total_Price__c=q.SoniCast_Wireless_Total_Price__c;
						opp.SoniCast_Wireless_Unit_Price__c=q.SoniCast_Wireless_Unit_Price__c;
						opp.Spare_Chromecasts_Quantity__c=q.Spare_Chromecasts_Quantity__c;
						opp.Spare_Chromecasts_Total_Price__c=q.Spare_Chromecasts_Total_Price__c;
						opp.Spare_Chromecasts_Unit_Price__c=q.Spare_Chromecasts_Unit_Price__c;
						opp.STAYConnect_Mobile_Per_Month__c=q.STAYConnect_Mobile_Per_Month__c;
						opp.Subsidy_Name__c=q.Subsidy_Name__c;
						opp.Subtotal_System_Sale__c=q.Subtotal_System_Sale__c;
						opp.Total_Fees_Per_Month__c=q.Total_Fees_Per_Month__c;
						opp.Turn_on_Channel_Change__c=q.Turn_on_Channel_Change__c;
						opp.TV_Installation_Services__c=q.TV_Installation_Services__c;
						opp.TV_Types_at_Hotel__c=q.TV_Types_at_Hotel__c;
						opp.Upfront_Gross_Profit__c=q.Upfront_Gross_Profit__c;
						opp.VIW_Space_up_to_50__c=q.VIW_Space_up_to_50__c;
						opp.W_LG_W_App__c=q.W_LG_W_App__c;
						opp.Welcome_Channel_Video__c=q.Welcome_Channel_Video__c;
						opp.Term_Months__c=q.Term_Months__c;
						
						//lstupdateopp.add(opp);
    					
    				}//end if mpopptoquote containskey
    			}//end forloop lstsyncedquote
    		}//end if 
    	
    	}//end if mpopptoquote size
    	
    	
    	//if a quote id has been removed from the syncedquote field on opportunity, wipe out all the
    	//field values from that quote
    	if(mpremovequote.size() > 0)
    	{
    		lstremovequotevals = mpremovequote.values();
    		for(opportunity o :lstremovequotevals)
    		{
    			o.of_Public_Areas_that_Need_Programming__c=null;
				o.of_Televisions__c=null;
				o.X1_hotel_open_HD_channel__c=null;
				o.X1_hotel_open_SD_channel__c=null;
    			o.X1_HVOD_link_to_video__c=null;
				o.X1_Main_or_Sub_Menu_Category__c=null;
				o.X2_hotel_open_HD_channels__c=null;
				o.Additional_One_time_Incentive_SoniCast__c=null;
				o.Add_on_Services_Recurring__c=null;
				o.Analog_Channel_Lineup_for_Public_Space__c=null;
				o.Bar_Lounge__c=null;
				o.Branding_Marketing_Per_Month__c=null;
				o.Chromecast_Ultra_Quantity__c=null;
				o.Chromecast_Ultra_Total__c=null;
				o.Cinamenities_LTV__c=null;
				o.Custom_Background__c=null;
				o.Custom_Logo__c=null;
				o.Down_Payment__c=null;
				o.Equip_Installation_One_Time_Fee__c=null;
				o.EVO__c=null;
				o.FCO__c=null;
				o.Fees_Name__c=null;
				o.Financing_Amount_System_Sale__c=null;
				o.Financing_Party__c=null;
				o.FTG_Analog_Channels__c=null;
				o.FTG_HD_Channels__c=null;
				o.FTG_SD_Channels__c=null;
				o.FTG_Equip_Installation__c=null;
				o.FTG_LTV__c=null;
				o.FTG_Monthly_Programming_Fee__c=null;
				o.FTG_System_Sale_Revenue__c=null;
				o.GIA_Base_Guest_Access__c=null;
				o.GIA_LTV__c=null;
				o.Group_Services_Recurring__c=null;
				o.Group_Services_Upfront__c=null;
				o.Guest_Apps_Per_Month__c=null;
				o.Happenings_Channel__c=null;
				o.HD_Channel_Lineup__c=null;
				o.Healthclubs__c=null;
				o.Hotel_Directory__c=null;
				o.Incentives_System_Sale__c=null;
				o.In_Room_Equip_Sale_Revenue__c=null;
				o.Interactive_Program_Guide__c=null;
				o.iTV_System_Installation__c=null;
				o.IPG__c=false;
				o.IPG_data_feed__c=null;
				o.IP_or_RF__c=null;
				o.IRD_GR_App__c=null;
				o.iTV_LTV__c=null;
				o.Lifetime_Value_of_Deal__c=null;
				o.Lobby__c=null;
				o.Marketing_Creative_Services_Per_Month__c=null;
				o.MATV_One_Time_Fee__c=null;
				o.Mobile_Hotel_Directory__c=null;
				o.Monthly_Financing_Fee__c=null;
				o.Non_Standard_Discount__c=null;
				o.Offer_Price_PRPM__c=null;
				o.Offer_Price_One_Time__c=null;
				o.On_Demand_Per_Month__c=null;
				o.One_Time_Add_on_Services__c=null;
				o.Other__c=null;
				o.Overall_Margin_FTG__c=null;
				o.Overall_Margin_FTG_One_Time__c=null;
				o.Overall_Margin_iTV__c=null;
				o.Overall_Margin_iTV_One_Time__c=null;
				o.Overall_Margin_Other__c=null;
				o.Percentage_of_VOD_receipts__c=null;
				o.Percentage_of_VOD_receipts_Tier_2__c=null;
				o.Percentage_of_VOD_receipts_Tier_3__c=null;
				o.Pricing__c=null;
				o.Public_Space_Distr_Non_SMATV__c=null;
				o.Public_Space_Distr_SMATV__c=null;
				o.Public_Space_Per_Month__c=null;
				o.Public_Space_Prog_Pkg_1_Name__c=null;
				o.Public_Space_Prog_Pkg_2_Monthly_Fee__c=null;
				o.Public_Space_Prog_Pkg_2_Name__c=null;
				o.Public_Space_Programming__c=null;
				o.Recurring_Gross_Profit__c=null;
				o.Remaining_SONIFI_contract__c=null;
				o.Remaining_SONIFI_contract_Total__c=null;
				o.Repayment_of_DTV_incentives__c=null;
				o.Repayment_of_DTV_incentives_Total__c=null;
				o.SD_Channel_Lineup__c=null;
				o.Service_Support__c=null;
				o.Service_Support_Per_Month__c=null;
				o.SoniCast_Contract_Term_Incentive_Total__c=null;
				o.SoniCast_Discount_One_time_Total__c=null;
				o.SoniCast_Down_Payment__c=null;
				o.SoniCast_Incentive_Quantity__c=null;
				o.SoniCast_Incentive_Total_Price__c=null;
				o.SoniCast_Incentive_Unit_Price__c=null;
				o.SoniCast_Initial_Term__c=null;
				o.SoniCast_Marketing_Material_Quantity__c=null;
				o.SoniCast_Marketing_Material_Total_Price__c=null;
				o.SoniCast_Marketing_Material_Unit_Price__c=null;
				o.SoniCast_SNC_Quantity__c=null;
				o.SoniCast_SNC_Total_Price__c=null;
				o.SoniCast_SNC_Unit_Price__c=null;
				o.SoniCast_Technology_Fee_Quantity__c=null;
				o.SoniCast_Technology_Fee_Total_Price__c=null;
				o.SoniCast_Technology_Fee_Unit_Price__c=null;
				o.SoniCast_Total_One_time_Total_Price__c=null;
				o.SoniCast_Wired_Quantity__c=null;
				o.SoniCast_Wired_Total_Price__c=null;
				o.SoniCast_Wired_Unit_Price__c=null;
				o.SoniCast_Wireless_Quantity__c=null;
				o.SoniCast_Wireless_Total_Price__c=null;
				o.SoniCast_Wireless_Unit_Price__c=null;
				o.Spare_Chromecasts_Quantity__c=null;
				o.Spare_Chromecasts_Total_Price__c=null;
				o.Spare_Chromecasts_Unit_Price__c=null;
				o.STAYConnect_Mobile_Per_Month__c=null;
				o.Subsidy_Name__c=null;
				o.Subtotal_System_Sale__c=null;
				o.Total_Fees_Per_Month__c=null;
				o.Turn_on_Channel_Change__c=null;
				o.TV_Installation_Services__c=null;
				o.TV_Types_at_Hotel__c=null;
				o.Upfront_Gross_Profit__c=null;
				o.Upfront_Subsidy__c=null;
				o.VIW_Space_up_to_50__c=null;
				o.W_LG_W_App__c=null;
				o.Welcome_Channel_Video__c=null;
				o.Term_Months__c=null;
				
				//lstupdateopp.add(o);
    			
    		}
    	}
    	
    	system.debug('lstupdateopp size is ' +lstupdateopp.size());
    	
    	//if(lstupdateopp.size() > 0)
    	//{
    	//	try{  update lstupdateopp;  }
    	//	catch(Exception e)
    	//	{
    	//		system.debug('Error syncing or unsyncing quote field to opportunity: ' +e.getMessage());
    	//	}
    	//}  //*/
    	
    	system.debug('**************END CustomQuoteFieldsToOpp*****************');
    	
    }//end CustomQuoteFieldsToOpp
    
    
    
    /*
    private ConnectApi.FeedItemInput createChatterPostInputForContractRequest(Id crId)
    {
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        if(Schema.SObjectType.Group.getSobjectType() != crId.getSobjectType())
        {
            ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
            mentionSegment.id = crId;
            messageInput.messageSegments.add(mentionSegment);
        }
        textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = ' Contract Request was cancelled due to updates to Opportunity.  A new Contract Request was created';
        messageInput.messageSegments.add(textSegment);
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        return input;
    }
   */
    
    /*
     ***************************************************************************************
            Jim Johnson - Moved Functionality to Custom Button on the Opportunity
            Method code has been moved to the CustomOpportunityLogic
     ***************************************************************************************
    
    public static void createSiteSurvey(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        //check to make sure new list is not empty
        if(newList == null || newList.isEmpty()) {
            throw new Exceptions.IllegalArgumentException('Opportunity new list is empty or missing');
        }
        
        //write log
        Utilities.writeLog('Creating site survey for ' + newList.size() + ' opportunities.',
                            CustomOpportunityLogic.class, 'createSiteSurvey', LoggingLevel.DEBUG);
        
        //initialize var
        Site_Survey__c site;
        List<Opportunity> createList = new List<Opportunity>();
        List<Site_Survey__c> upsertList = new List<Site_Survey__c>();
        List<Site_Survey__c> siteSurveyList = new List<Site_Survey__c>();
        Set<String> oppIds = new Set<String>();
        Map<Id, Site_Survey__c> oppId2SiteSurveyMap = new Map<id, Site_Survey__c>();
        String siteSurvey = '';
        String desktopSurvey = '';
        
        //query for the queue
        QueueSobject groupQueue = [SELECT id,QueueId FROM QueueSobject WHERE SobjectType = 'Site_Survey__c'  AND Queue.DeveloperName = 'Installs_Site_Surveys' limit 1]; 
        
        //query for the record type ids
        List<RecordType> recordTypes = [SELECT SobjectType, Id, DeveloperName From RecordType WHERE SobjectType = 'Site_Survey__c' ];
        //set the record type ids
        for(RecordType rec : recordTypes){
            if(rec.DeveloperName == 'Site_Survey'){
                siteSurvey = rec.id;
            } else if(rec.DeveloperName == 'Desktop_Review') {
                desktopSurvey = rec.id;
            }
        }
        System.debug('Site survey record id is ' + siteSurvey + '. Desktop is ' + desktopSurvey);
        
        for(Opportunity opp : newList) {
            if(oldMap != null) {
                //check to see if the status has changed or initial value is end status
                if((opp.stageName =='Site Survey Order Approved' && oldMap.get(opp.id).stageName != 'Site Survey Order Approved') || (opp.stageName == 'Desktop Review Required' && oldMap.get(opp.id).stageName != 'Desktop Review Required')) {                                                                     
                    createList.add(opp);
                    oppIds.add(opp.id);
                }
            } else if(opp.stageName == 'Site Survey Order Approved' || opp.stageName == 'Desktop Review Required') {
                createList.add(opp);
            }
        }
        System.debug('Create list is ' + createList);
        
        //query for the site surveys that might be attached to the opportunity already
        siteSurveyList = [SELECT id, RecordTypeId, Opportunity__c FROM Site_Survey__c WHERE Opportunity__c IN :oppIds];
        System.debug('Site survey list is ' + siteSurveyList);
        
        //map opp id to site survey object
        for(Site_Survey__c s : siteSurveyList){
            oppId2SiteSurveyMap.put(s.Opportunity__c, s);
        }
        
        for(Opportunity opp : createList) {
            if(oppId2SiteSurveyMap.containsKey(opp.id)){
                if(opp.StageName == 'Desktop Review Required'){
                    oppId2SiteSurveyMap.get(opp.id).RecordTypeId = desktopSurvey;
                } else {
                    oppId2SiteSurveyMap.get(opp.id).RecordTypeId = siteSurvey;
                }
                upsertList.add(oppId2SiteSurveyMap.get(opp.id));
            } else {
                site = new Site_Survey__c();
                //initialize the fields
                site.Opportunity__c = opp.id;
                site.Site__c = opp.Account_ID__c;
                site.Number_of_Rooms__c = opp.of_Rooms_Opportunity__c;
                if(opp.StageName == 'Desktop Review Required'){
                    site.RecordTypeId = desktopSurvey;
                } else {
                    site.RecordTypeId = siteSurvey;
                }
                upsertList.add(site);
            }
        }
        System.debug('Upsert List is ' + upsertList);
        
        //loop through Site Surveys and if not created then set owner to queue; if not then leave it alone
        for(Site_Survey__c s : upsertList){
            s.OwnerId = groupQueue.QueueId;
        }
        System.debug('Upsert List is ' + upsertList);
        
        //if size of insert list is not 0 then insert the list
        if(upsertList.size() > 0) {
            try {
                upsert upsertList;
            } catch( Exception e) {
                Utilities.writeLog('Unable to upsert site survey to opportunities with details: ' +e.getMessage(),
                OpportunityTriggerLogic.class, 'createSiteSurvety', LoggingLevel.DEBUG);
            }
        }
    }
    */
}