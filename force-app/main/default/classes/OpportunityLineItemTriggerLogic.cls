// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 06/17/2013
// Description:  Class for Opportunity TriggerLogic
// 
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************

public without sharing class OpportunityLineItemTriggerLogic {

    //******************************************************************************************
    //Author: Etherios
    //Parameters: Trigger.new, Trigger.oldMap
    //Description: Logic for creating or updating a Contract Request related to OpportunityLineItem
    //only one Active Contract Request should exist at one time per OpportunityLineItem
    //******************************************************************************************
    public static void createContractRequest(List<OpportunityLineItem> oliList, Map<Id,OpportunityLineItem> oliOldMap)
    {
        Utilities.writeLog('**********    START', OpportunityLineItemTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 

        //Newly created Contract Request are put in Contracts Administration Queue, Queue must exist
        List<Group> crQueue = [SELECT Id from Group WHERE Type = 'Queue' AND DeveloperName = 'Contract_Specialist'];
        if(crQueue.size() == 0)
        {
            oliList[0].addError('Contract_Specialist Queue not found');     
        }
        
        //Need Record type for Case
        ID rtId = Utilities.RecordTypeNameToIdWithObject(Definitions.RECORDTYPE_ContractRequest, 'Case');
        if(rtId == null)
        {
            Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Contract Request record type not found.', OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
            oliList[0].addError('Contract Request record type not found');
        }
        else
        {
            Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Record type found. Id is ' + rtId, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        }               
                
        //Collections used
        List<ID> opListID = new List<ID>();
        for(OpportunityLineItem oli: oliList)
        {
            //Getting List of Opportunity IDs
            opListID.add(oli.OpportunityId);
        }
        //Loop through to find Primary Contact Role
        List<OpportunityContactRole> ocrList = [SELECT Contact.Email, OpportunityId, ContactId from OpportunityContactRole WHERE OpportunityId IN :opListID AND IsPrimary = true];
        Map<Id,OpportunityContactRole> ocrMap = new Map<Id,OpportunityContactRole>();
        for(OpportunityContactRole ocr : ocrList)
        {
            ocrMap.put(ocr.OpportunityId,ocr);
        }
        
        Map<Id,Opportunity> opListMap = new Map<Id,Opportunity>([SELECT Id, Name, StageName, AccountId, Quota_Categories__c, Account.Management_Group__c, Special_Instructions__c
        from Opportunity WHERE Id IN :opListID]);
        //Assumption here is there are not two active Contract Requests at any time
        List<Case> contractRequestList = [SELECT Id, Opportunity__c,Status, OwnerId from Case WHERE Opportunity__c IN : opListID AND Status != 'Cancelled' AND RecordTypeId = :rtid];
        Map<Id,Case> contractRequestMap = new Map<Id,Case>();
        List<Case> crToModify = new List<Case>();
        List<Case> crToInsertWithChatter = new List<Case>();
        //Map<Id, ConnectApi.FeedItemInput> crFeedItemMap = new Map<Id,ConnectApi.FeedItemInput>();  For @mention posts
        Map<Id, Id> crUserMap = new Map<Id,Id>();
        List<FeedItem> fiList = new List<FeedItem>();
        
        Map<Id,Opportunity> opMap = new Map<Id,Opportunity>();
        //Map of Opportunity by OLI Id        
        for(OpportunityLineItem oli: oliList)
        {
            opMap.put(oli.Id, opListMap.get(oli.OpportunityId));
        }
        
        for(Case cr : contractRequestList)
        {
            contractRequestMap.put(cr.Opportunity__c, cr);
        }
        
        //Main loop through OpportunityLineItems
        for(OpportunityLineItem oli: oliList)
        {
            Utilities.writeLog('bl_OppportunityLineItem:createContractRequest: In Loop - on OpportunityLineItem : '+oli, OpportunityLineItemTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
            
            Utilities.writeLog('Contract Request map is '+contractRequestMap.get(oli.OpportunityId)+ ' Opportunity StageName is '+opMap.get(oli.Id).StageName, OpportunityLineItemTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 

                //If the related Opportunity is in stage Contract Requested 
                if(contractRequestMap.containsKey(oli.OpportunityId) == true && opMap.get(oli.Id).StageName == 'Contract Requested')
                {
                    Case crExisting = contractRequestMap.get(oli.OpportunityId);
                    Utilities.writeLog('bl_OppportunityLineItem:createContractRequest: Contract Request of Opportunity of OpportunityLineItem : '+crExisting, OpportunityLineItemTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
                    //For the Related Contract Request with Status before 'Drafting'
                    if(crExisting.Status == 'Waiting for RSM' || 
                       crExisting.Status == 'Feasibility Review' || 
                       crExisting.Status == 'Legal Review' || 
                       crExisting.Status == 'Requested')
                    {
                        crExisting.Status = 'Opportunity Updated';
                        crToModify.add(crExisting);
                    }
                    //For the related Contract Requeset with Status after 'Drafting'
                    else if(crExisting.Status == 'Drafting' || 
                            crExisting.Status == 'Pending Proofing' || 
                            crExisting.Status == 'Contract Sent')
                    {
                        crExisting.Status = 'Cancelled';
                        crToModify.add(crExisting);
                        Case crNew = OpportunityLineItemTriggerLogic.addContract(opMap.get(oli.Id),crQueue[0].Id, rtId, ocrMap);
                        crToModify.add(crNew);
                        crToInsertWithChatter.add(crNew);
                        //Chatter updates
                        //crFeedItemMap.put(crExisting.id, createChatterPostInputForContractRequest(crExisting.OwnerId));
                        fiList.add(createContractRequestFeedItem(crExisting.Id));                           
                        //crUserMap.put(oli.OpportunityId, crExisting.ownerId);
                    }                                  
                }
            
        }
        //Insert/Update the Contract Requests
        Utilities.writeLog('OpportunityLineItemTriggerLogic:createContractRequest: Contract Requests to be Inserted/Updated : '+crToModify, OpportunityLineItemTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        if(crToModify.size() > 0) {
            upsert crToModify;
        }
        
        for(Case crNew : crToInsertWithChatter)
        {
            //Chatter updates 
            //crFeedItemMap.put(crNew.id, createChatterPostInputForContractRequest(crUserMap.get(crNew.Opportunity__c))); 
            fiList.add(createContractRequestFeedItem(crNew.Id));                     
        }
        
        Utilities.writeLog('OpportunityLineItemTriggerLogic:createContractRequest: Chatter FeedItems to be Inserted : '+fiList, OpportunityLineItemTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        if(fiList.size() > 0) {
            insert fiList;
        }
        /*
        //Posting all Chatter items on Contract Requests
        for(Id crId : crFeedItemMap.keyset())
        {
            ConnectApi.ChatterFeeds.postFeedItem(null, ConnectApi.FeedType.Record, crId, crFeedItemMap.get(crId),null);
        }
        */
        Utilities.writeLog('**********    END', OpportunityLineItemTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        
    }
    
    private static Case addContract(Opportunity op, ID queueId, ID rtId, Map<Id,OpportunityContactRole> ocrMap)
    {
        Case crNew = new Case();
        crNew.AccountId = op.AccountId;
        //Calculate case subject
        String subject = 'Contract Request - '+ op.Name;
        Integer subjectLength = subject.length() > 254? 254 : subject.length();
        crNew.Subject = subject.substring(0,subjectLength);
        
        crNew.Case_Quota_Category__c = op.Quota_Categories__c;
        if(ocrMap.containsKey(op.Id))
        {
            crNew.Client_Contact__c = ocrMap.get(op.Id).ContactId;
            crNew.Recipient_Email__c = ocrMap.get(op.Id).Contact.Email;
        }
        //jjackson 3/2015 commented this out because management company field is being replaced with formula field
        //crNew.Management_Company__c = op.Account.Management_Group__c;
        crNew.RecordTypeId = rtId;
        crNew.Description = op.Special_Instructions__c;
        crNew.Opportunity__c = op.Id;
        crNew.Status = 'Requested';
        crNew.OwnerId = queueId;    
        return crNew;
    }
    
    private static FeedItem createContractRequestFeedItem(Id parentId)
    {
        FeedItem fi = new FeedItem();
        fi.ParentId = parentId;
        fi.body = 'Contract Request was cancelled due to updates to Opportunity.  A new Contract Request was created';
        return fi;
    }
    /*
    public static void alertContractAdmins(List<OpportunityLineItem> oliList)
    {
        Utilities.writeLog('**********    BEGIN', OpportunityLineItemTriggerLogic.class, 'alertContractAdmins', LoggingLevel.DEBUG); 
    	
    	Set<Id> opIds = new Set<Id>();
		for(OpportunityLineItem oli : oliList)
		{
			opIds.add(oli.OpportunityId);
		}
		List<Opportunity> opList = [SELECT Id, Name from Opportunity WHERE ID IN :opIds];
		List<String> contractStatuses = new List<String>{'Order In House','Approval Pending','Order Approved','Activated','Inactive','Cancelled','On Hold','Approved to Build','Approved to Ship and Install','Assumption Triage',
			'Assumption Sent','Assumption In-House','Assumption - Cr Appd','Assumption – Cr Decl','Assumption Completed','Assumption Rejected','Operating – Non-Assumed','Buy/Sell Assumption',
			'No Assumption Required','Credit App – Assumption','Other (See Notes)','Non-Assumption','Waiting on Execution','Ready for Approval'};
		List<Contract__c> contracts = [SELECT Opportunity__c from Contract__c WHERE Opportunity__c IN : opIds AND Status__c IN :contractStatuses];
		
		Set<Id> opportunityWithContracts = new Set<Id>();
		for(Contract__c c : contracts)
		{
			opportunityWithContracts.add(c.Opportunity__c);
		}
    	List<Opportunity> opChanged = new List<Opportunity>();


		for(Opportunity o : opList)
		{
			if(opportunityWithContracts.contains(o.Id))
			{
				opChanged.add(o);
			}
		}
		//get Contract admins
		List<User> contractUsers = new List<User>();
		List<User> contractManager = [SELECT Id from User WHERE ProfileId = :Utilities.ProfileNameToId('Contract Manager')];
		List<User> contractAdminSpecialist = [SELECT Id from User WHERE ProfileId = :Utilities.ProfileNameToId('Contracts Admin Specialist')];
		String message = 'The following Opportunities have changed: \n ';
		for(Opportunity o : opChanged)
		{
			message+=o.Name+'\n';
		}
		contractUsers.addAll(contractManager);
		contractUsers.addAll(contractAdminSpecialist);
		Map<Id,String> chatterMap = new Map<Id,String>();
		system.debug('Opportunities changed '+opChanged);
		system.debug('Chatter message '+message);
		for(User u : contractUsers)
		{
			chatterMap.put(u.Id,message);
		}								
		//Call another function here
		if(opChanged.size() > 0)
			ChatterUtilities.doChatterPosts(chatterMap);
			
        Utilities.writeLog('**********    END', OpportunityLineItemTriggerLogic.class, 'alertContractAdmins', LoggingLevel.DEBUG); 
																																																	
    }
    */
    
    /*  This is for the @ mention forum post
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
}