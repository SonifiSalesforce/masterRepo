@isTest
public with sharing class TaskTriggerLogicTest {
    
    @isTest static void testTaskTrigger() {
        
        Account acct = DataGenerator.createAccounts(1, true)[0];
        
        // Get support case record type
        String supportCaseRecordTypeId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Case_SupportCase);
        System.assertNotEquals(null, supportCaseRecordTypeId);
        
        // Create support cases
        Integer casesToCreate = 10;
        List<Case> caseList = DataGenerator.createCases(acct.Id, casesToCreate, false);
        System.assertEquals(casesToCreate, caseList.size());
        
        for (Case c : caseList) { c.RecordTypeId = supportCaseRecordTypeId; }
        insert caseList; 
        
        // Get support case task record type
        String supportCaseTaskRecordTypeId = Utilities.RecordTypeNameToId('Task', Definitions.RECORDTYPE_Task_SupportCase);
        System.assertNotEquals(null, supportCaseTaskRecordTypeId);
        
        Test.startTest();
        
        // Create support case tasks
        Integer tasksToCreate = 100;
        List<Id> caseIds = new List<Id>();
        List<Task> taskList = new List<Task>();
        for (Case c : caseList) { 
            caseIds.add(c.Id);
            taskList.addAll(DataGenerator.createTasks(c, tasksToCreate, false)); 
        }
        System.assertEquals(casesToCreate * tasksToCreate, taskList.size());
        
        for (Task t : taskList) { 
            t.RecordTypeId = supportCaseTaskRecordTypeId;
            t.Case_Status__c = 'Pending Close';
            t.Issue_Details_Description__c = 'Test issue details description.'; 
        }
        insert taskList;
        
        Test.stopTest();
        
        for (Case c : [
                        SELECT Id, Status, Issue_Details_Description__c
                        FROM Case
                        WHERE Id IN :caseIds
                      ]) {
            
            System.assertEquals('Pending Close', c.Status);
            System.assertEquals('Test issue details description.', c.Issue_Details_Description__c);
        }
    }

/*  
    @isTest 
    static void testTaskTriggerLogic() {
        TaskTriggerLogic ttl = new TaskTriggerLogic();
        Map<Id,Task> oldTaskMap ;
        Map<Id,Task> newTaskMap = new Map<Id,Task>();
        List<Case> caseList = new List<Case>();
        Id supportCaseId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
        System.debug('**** /////// *****  Support Case Id = ' + supportCaseId);

        Id supportTaskId = Task.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Case Task').getRecordTypeId();
        System.debug('**** /////// *****  Support Case Task Id = ' + supportTaskId);

        Case c = (Case)DataGenerator.createSObjectWithDefaultValues('Case', supportCaseId);
        upsert c;
        List<Task> oldTaskList = new List<Task>();
        List<Task> newTaskList = new List<Task>();
        
        for(Integer i=0;i<200;i++){
            Task t = new Task(recordTypeId = supportTaskId);
            t.WhatId = c.Id;
            System.debug('********************  Task RecordType: ' + t.RecordTypeId);
            System.debug('********************  Task RecordType: ' + c.RecordTypeId);
            
            t.Issue_Details__c = 'Issue_Details__c';
            t.Issue_Details_Description__c = 'Issue_Details_Description__c';
            t.Issue_Sub_Type__c = 'Issue_Sub_Type__c';
            t.Issue_Type__c = 'Issue_Type__c';
            newTaskList.add(t);
        }
         
        upsert newTaskList;
        

        
        
        //Map<Id,Task> updtTrigger = ttl.callUpdateTaskTriggerLogic(oldTaskMap, newTaskMap);
         TaskTriggerLogic.updateTaskTriggerLogic(oldTaskList, newTaskList);
        
        
        
    }
*/
}