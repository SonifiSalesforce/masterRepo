@istest
public with sharing class StandardOrderTriggerLogicTest {
	
	static testMethod void testUpdateAssetsonOrderFulfilled()
	{
		Account acc = DataGenerator.createAccounts(1,true)[0];
		Product2 p = new Product2(Name = 'Test Product1');
 		insert p;
        
		Asset ass1 = new Asset();
        ass1.AccountId = acc.Id;
        ass1.Name = 'Test Install';
        ass1.Status = 'Billing';
        ass1.Product2Id = p.Id;
        insert ass1;
        
         
        Order__c neworder = new Order__c(Name='Test Order',Site__c=acc.id, Status__c='Order Approved');
        insert neworder;
        
        Order_Item__c oi1 = new Order_Item__c();
        oi1.Name = 'oi1Name';
        oi1.Asset__c = ass1.Id;
        oi1.Status__c ='Installed Activated';
        oi1.Total_Rooms_Ordered__c = 100;
        oi1.Total_Remaining_Rooms__c = 100;
        oi1.Order__c = neworder.id;
 		insert oi1;       
 		
		User adminuser = [ Select Id, Profile.Name from User where Profile.Name = 'System Administrator' LIMIT 1 ];
		
		Id workOrderRecordType = Utilities.RecordTypeNameToId('Work_Order__c', 'Install');
		Work_Order__c wo = new Work_Order__c(RecordTypeId = workOrderRecordType, Site__c = acc.Id, Install_Manager__c = adminuser.Id, Approver__c = adminuser.Id,
		                                     Project_Coordinator__c = adminuser.Id, Actual_Start_Date__c = system.Today().addmonths(-3),
		                                     Estimated_Completion_Date__c = system.Today().addmonths(-1), Approval_Status__c = 'Billing Approved',
		                                     Install_Complete_Date__c = system.Today(), Status__c = 'Billing/Go Live');
        insert wo;
        
        Associated_Item__c ai1 = new Associated_Item__c();
        ai1.Name = 'Test1 Product Parent';
        ai1.Order_Item__c = oi1.Id;
        ai1.Work_Order__c = wo.Id;
        ai1.Status__c = 'Installed Activated';
        ai1.Flagged_for_Billing__c = true;
 		insert ai1;
        
        test.startTest();
        
        List<Work_Order__c> lstwo = new List<Work_Order__c>();
        List<Work_Order__c> lstupdwo = new List<Work_Order__c>();
        lstwo = [Select Id, Status__c, Previous_Status_Go_Live__c, Previous_Status_Complete__c from Work_Order__c where Id = :wo.Id];
        for(Work_Order__c recwo : lstwo)
        {
        	  recwo.Previous_Status_Go_Live__c = true;  //jjackson must set these two booleans to true so validation rule will not fail.
              recwo.Previous_Status_Complete__c = true;
        	  recwo.Status__c = 'Work Order Complete';
        	  lstupdwo.add(recwo);
        	  
        	  system.debug('recwo is ' +recwo.Id +', ' + recwo.Status__c);
        }    
        
        update lstupdwo;
        
        List<Order_Item__c> lstoi = New List<Order_Item__c>();
        lstoi = [ Select Id, Name, asset__c, asset__r.status, order__r.status__c from Order_Item__c where name = 'oi1Name'];
        
        test.stopTest();
        
        for(Order_Item__c oirec : lstoi)
        {
  			system.assert(oirec.asset__r.status == 'Installed Activated');
        }
	}//end testUpdateAssetsonOrderFulfilled

}