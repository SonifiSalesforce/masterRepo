global class LCLISteveBatch implements Database.Batchable<sObject>{

   global final String Query;

   global LCLISteveBatch(){

      Query = 'SELECT steveecheckbox__c from Contract_Line_Item__c';
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope)
   {
     for(Contract_Line_Item__c a : (List<Contract_Line_Item__c>)scope)
     {
     	a.steveecheckbox__c = true;
     }  
     
	update scope;
	}

   global void finish(Database.BatchableContext BC){
   }

}