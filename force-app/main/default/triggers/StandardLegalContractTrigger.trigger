trigger StandardLegalContractTrigger on Contract__c (before insert, before update, after insert, after update) {
   /*shawks 01/2019 - CPQ: Comment out all since not needed after using out-of-box Contract object
    // Check for trigger processing blocked by custom setting
    try{ 
        if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
            return;
        } else if(LegalContractTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
            return; 
        }
    }
    catch (Exception e) {}
    
    if(Trigger.isBefore)
    {
       MultiCurrencyLogic.convertMultiCurrency(Trigger.oldMap, Trigger.new, new Map<String,String>{'TOD_Project_E__c'=> 'TOD_Project_USD__c', 'TOD_Sub_K__c' => 'TOD_Sub_K_USD__c'});
        
       if(trigger.isUpdate)
       {
        StandardLegalContractTriggerLogic.updateConversionDate(Trigger.new); 
        StandardLegalContractTriggerLogic.UpdateContractLineItems(trigger.new, trigger.oldmap);
       }
    } 
    if(Trigger.isafter)
    {
        if(Trigger.isUpdate)
        {
            //StandardLegalContractTriggerLogic.updateLCLITermDates(Trigger.new,Trigger.oldMap);
            //jjackson 6/30/2014 This populates install start ftg and interactive dates to the related work order.
            //BUG-00361 July 2014
            system.debug('calling GetClockStartDate');
            StandardLegalContractTriggerLogic.GetClockStartDate(trigger.oldMap,trigger.new);

          if(triggerRecursionBlock.flag == true) 
            {
                 StandardLegalContractTriggerLogic.SendGroupServicesEmail(trigger.new, trigger.oldmap);
                 triggerRecursionBlock.flag = false;
            }
            
          if(test.isRunningTest())
          {  StandardLegalContractTriggerLogic.SendGroupServicesEmail(trigger.new, trigger.oldmap);  }
        }
        //if(Trigger.isInsert)
        //{
        //  StandardLegalContractTriggerLogic.updateLCLITermDates(Trigger.new,null);
        //}
    }
    **CPQ - end **/
}