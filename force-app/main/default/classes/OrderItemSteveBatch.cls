global class OrderItemSteveBatch implements Database.Batchable<sObject>{

   global final String Query;

   global OrderItemSteveBatch(){

      Query = 'SELECT steveecheckbox__c from Order_Item__c';
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope)
   {
     for(Order_Item__c a : (List<Order_Item__c>)scope)
     {
     	a.steveecheckbox__c = true;
     }  
     
	update scope;
	}

   global void finish(Database.BatchableContext BC){
   }

}