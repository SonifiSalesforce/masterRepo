@isTest(SeeAllData=true)
public class OpportunityLineItemTriggerLogicTest
{
    
    static testMethod void oliNoRelatedContractRequest()
    {
        Test.startTest();
        List<Account> accounts = DataGenerator.createAccounts(1, true);
        List<Contact> contacts = DataGenerator.createContacts(accounts[0], 1, true);
        List<Opportunity> opportunities = DataGenerator.createOpptys(accounts[0], 1, false);
        
        Opportunity o = opportunities[0];
        o.StageName = 'Proposal Sent';
        insert o;
        
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=contacts[0].Id,IsPrimary=true);
        insert ocr;
        
        List<RecordType> rtList = [select Id,name from RecordType where name='Contract Request' and SObjectType='Case' limit 1];
        Id rtId = rtList[0].Id;     
        
        List<Case> crRelated = [SELECT Status from Case WHERE Opportunity__c = :o.Id AND Status = 'Requested' AND RecordTypeId = :rtId];
        //system.assert(crRelated.size() == 0);
        
        //Opportunity reaches status of 'Contract Requested'
        o.StageName = 'Contract Requested';
        update o;
        
        crRelated = [SELECT Status from Case WHERE Opportunity__c = :o.Id AND Status = 'Requested']; 
        //system.assert(crRelated.size() == 1, 'Size should be 1, is '+crRelated.size());
        
        //Updating opportunity again, should not be new contract request created
        List<OpportunityLineItem> oliList = DataGenerator.createOpptyProducts(o, 1, true);
        oliList[0].Quantity = 10;
        update oliList;
        Test.stopTest();
        crRelated = [SELECT Status from Case WHERE Opportunity__c = :o.Id AND Status = 'Opportunity Updated'];
        //system.assert(crRelated.size() == 1, 'Size should be 1, is '+crRelated.size());        
    }
    
    static testMethod void oliRelatedDraftingContractRequest()
    {
        Test.startTest();
        List<Account> accounts = DataGenerator.createAccounts(1, true);
        List<Contact> contacts = DataGenerator.createContacts(accounts[0], 1, true);
        List<Opportunity> opportunities = DataGenerator.createOpptys(accounts[0], 1, false);
        
        Opportunity o = opportunities[0];
        o.StageName = 'Proposal Sent';
        insert o;
        
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=contacts[0].Id,IsPrimary=true);
        insert ocr;
        
        List<RecordType> rtList = [select Id,name from RecordType where name='Contract Request' and SObjectType='Case' limit 1];
        Id rtId = rtList[0].Id;     
        
        List<Case> crRelated = [SELECT Status from Case WHERE Opportunity__c = :o.Id AND Status = 'Requested' AND RecordTypeId = :rtId];
        //system.assert(crRelated.size() == 0);
        
        //Opportunity reaches status of 'Contract Requested'
        o.StageName = 'Contract Requested';
        update o;
        
        crRelated = [SELECT Id, Status from Case WHERE Opportunity__c = :o.Id AND Status = 'Requested']; 
        //system.assert(crRelated.size() == 1, 'Size should be 1, is '+crRelated.size());
        if(crRelated.size() > 0)
        {
        crRelated[0].Status = 'Drafting';
        update crRelated[0];
        }
        
        //Updating opportunity again, should not be new contract request created
        List<OpportunityLineItem> oliList = DataGenerator.createOpptyProducts(o, 1, true);
        oliList[0].Quantity = 2;
        update oliList;
        
        Test.stopTest();
        crRelated = [SELECT Status from Case WHERE Opportunity__c = :o.Id AND Status = 'Opportunity Updated'];
        //system.assert(crRelated.size() == 1, 'Size should be 1, is '+crRelated.size());        
    }
    
}