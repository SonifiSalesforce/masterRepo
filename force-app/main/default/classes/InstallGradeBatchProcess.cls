global class InstallGradeBatchProcess implements Database.Batchable<sObject>{

   global final String Query;

    global InstallGradeBatchProcess(){
        Query = 'SELECT Grade__c, Installer__c, Work_Order__c from Install_Grade__c';
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        Utilities.writeLog('Entering execute, scope: '+scope,InstallGradeBatchProcess.class,'execute',LoggingLevel.DEBUG);
    	
        List<Id> igIds = new List<Id>();
        for(Install_Grade__c ig : (List<Install_Grade__c>)scope)
        {
            igIds.add(ig.Installer__c);
        }

        Utilities.writeLog('Ids of Installer in Install Grade in scope : '+igIds,InstallGradeBatchProcess.class,'execute',LoggingLevel.DEBUG);

        //Query all Contacts related to Install Grades
        List<Contact> cList = [SELECT AccountId, Grade__c, Id from Contact WHERE Id IN :igIds];
        
        Utilities.writeLog('Contacts queried : '+cList,InstallGradeBatchProcess.class,'execute',LoggingLevel.DEBUG);
        
        List<Id> aIds = new List<Id>();
        for(Contact c : cList)
        {
            aIds.add(c.AccountId);
        }
        //Query all Accounds related to Contacts
        List<Account> aList = [SELECT Id from Account WHERE Id IN :aIds];
        Utilities.writeLog('Accounts related to Contacts queried: '+aList,InstallGradeBatchProcess.class,'execute',LoggingLevel.DEBUG);
        
        
        //Average out Grade per Contact
        for(Contact c : cList)
        {
            Decimal contactGrade = 0;
            Integer contactCount = 0;
            for(Install_Grade__c ig : (List<Install_Grade__c>)scope)
            {
                if(ig.Installer__c == c.Id && ig.Grade__c != null)
                {
                    contactGrade += ig.Grade__c;
                    contactCount++;
                }
            }
            c.Grade__c = contactGrade/contactCount;
        }
		
		//Update Contacts with new Grade Average        
        update cList;

        Utilities.writeLog('Updated Contacts with Grade: '+cList,InstallGradeBatchProcess.class,'execute',LoggingLevel.DEBUG);
        cList = [SELECT AccountId, Grade__c from Contact WHERE Id IN :igIds];
        
        //Average out Contact grades for Account
        for(Account a : aList)
        {
            Decimal acctGrade = 0;
            Integer acctCount = 0;
            for(Contact c : cList)
            {
                if(c.AccountId == a.id && c.Grade__c != null)
                {
                    acctGrade += c.Grade__c;
                    acctCount++;
                }
            }
            a.Grade__c = acctGrade/acctCount;
        }
        update aList;
        Utilities.writeLog('Updated Accounts with Grade: '+aList,InstallGradeBatchProcess.class,'execute',LoggingLevel.DEBUG);

        Utilities.writeLog('Exiting execute',InstallGradeBatchProcess.class,'execute',LoggingLevel.DEBUG);
    }

   global void finish(Database.BatchableContext BC){
   }

}