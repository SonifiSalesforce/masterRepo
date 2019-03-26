trigger StandardFileTracsTrigger on FileTracs__c (before insert, before update) {
    
    Map<Id,FileTracs__c> emptymap = New Map<Id,FileTracs__c>(); //empty map to pass in to the insert method
    
    if(trigger.isInsert)
    { FileTracsTriggerLogic.UpdateAccountandTrackingNumber(trigger.new, emptymap);  }
    
    if(trigger.isUpdate)
    { FileTracsTriggerLogic.UpdateAccountandTrackingNumber(trigger.new,trigger.oldMap);  }
    
    
}