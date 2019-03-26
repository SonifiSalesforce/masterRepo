global class AssetSteveBatch implements Database.Batchable<sObject>{

   global final String Query;

   global AssetSteveBatch(){

      Query = 'SELECT steveecheckbox__c from Asset';
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope)
   {
     for(Asset a : (List<Asset>)scope)
     {
     	a.steveecheckbox__c = true;
     }  
     
	update scope;
	}

   global void finish(Database.BatchableContext BC){
   }

}