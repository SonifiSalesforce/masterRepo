@isTest
public with sharing class WorkOrderTriggerLogicTest2 {

    static testMethod void WorkOrderTriggerLogicTestOtherStuff()
    {
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest2 WorkOrderTriggerLogicTestOtherStuff Test .  **********    START');
        Account a = DataGenerator.createAccounts(1,true)[0];
        Work_Order__c wo = (Work_Order__c)DataGenerator.createSObjectWithDefaultValues('Work_Order__c',null);
        Work_Order__c wo2 = (Work_Order__c)DataGenerator.createSObjectWithDefaultValues('Work_Order__c',null);
        wo.Site__c = a.Id;
        wo2.Site__c = a.Id;
        insert wo;
        insert wo2;
        Test.startTest();
        wo.Status__c = 'Complete';
        update wo;
        wo2.Status__c = 'Billing/Go Live';
        update wo2;
        Test.stopTest();
        Work_Order__c cWorkOrder = [select id, name, Previous_Status_Complete__c from Work_Order__c where id = :wo.Id];
        Work_Order__c cWorkOrder2 = [select id, name, Previous_Status_Go_Live__c from Work_Order__c where id = :wo2.Id];
        system.assertEquals(cWorkOrder.Previous_Status_Complete__c, True);
        system.assertEquals(cWorkOrder2.Previous_Status_Go_Live__c, True);
        System.debug(LoggingLevel.DEBUG,'WorkOrderTriggerLogicTest2 WorkOrderTriggerLogicTestOtherStuff Test .  **********    Finished');
    }
    
    static testMethod void testUpdateOrderStatus()
    {
    	List<User> userlist = New List<User>();
    	Id userid;
    	userlist = [Select Id from User where profileid in(Select Id from Profile where name = 'System Administrator')];
    	for(User userrec : userlist)
    	{  userid = userrec.id;  }

    	Account acc = DataGenerator.createAccounts(1,true)[0];
    	
    	Order__c testorder = New Order__c(site__c = acc.id, Name = acc.name, status__c = 'Order Approved');
    	insert testorder;
    	
    	Product2 testprod = New Product2(name = 'FTG Product Parent', productcode = 'cc-test-01');
    	
    	Order_Item__c oiline = New Order_Item__c(name=testprod.name, status__c = 'Installed Activated', project_type__c = 'FTG New Rooms',
    	                                         account__c = acc.id, order__c = testorder.id);
    	insert oiline;
    	
    	Id rectypeid;
    	List<Recordtype> typelist = [Select Id from recordtype where name = 'Install'];
    	for(RecordType rec : typelist)
    	{ rectypeid = rec.Id;  }
    	                                     
    	Work_Order__c wo = New Work_Order__c(site__c = acc.id, name=acc.site_id__c, ownerid = userid, approver__c = userid,
    	                                     install_manager__c = userid, project_coordinator__c = userid, division__c = 'Domestic',
    	                                     region__c = 'Southeast', status__c = 'Billing/Go Live', approval_status__c = 'Billing Approved',
    	                                     recordtypeid = rectypeid);
    	insert wo;
    	
    	Associated_Item__c ai = New Associated_Item__c(name=testprod.name, order_item__c = oiline.id, work_order__c = wo.id, quantity__c = 100,
    	                                               status__c = 'Installed Activated', billing_commencement_date__c = system.today());
    	insert ai;
    	
    	test.startTest();
    	
    	Id approverid = UserInfo.getUserId();
    	
    	//TODO EXAMPLE CODE: How to run an approval process with apex code
    	//this part submits the work order for final approval
		Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
		req1.setComments('Submitting request for approval.');
		req1.setObjectId(wo.id);
		req1.setSubmitterId(approverid);
		req1.setProcessDefinitionNameOrId('Installation_Work_Order_Completion');
		Approval.ProcessResult result = Approval.process(req1);
		system.debug('result instance status is ' +result.getInstanceStatus());
		List<Id> newWorkItemIds = result.getNewWorkitemIds();
		
		//this part does the first approval on the work order
		Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
		req2.setComments('Approving request.');
		req2.setAction('Approve');
		req2.setNextApproverIds(new Id[] {approverid});
		req2.setWorkitemId(newWorkItemIds.get(0));
		Approval.ProcessResult result2 = Approval.process(req2);
		system.debug('result2 instance status is ' +result2.getInstanceStatus());
		List<Id> processid = result2.getNewWorkitemIds();
		
		//this part does the second (and final) approval on the work order
		//only use this second approval if a record must be approved by more than one person
		Approval.ProcessWorkitemRequest req3 = New Approval.ProcessWorkitemRequest();
		req3.setComments('Approving request.');
		req3.setAction('Approve');
		req3.setNextApproverIds(new Id[] {approverid});
		req3.setWorkitemId(processid.get(0));
		Approval.ProcessResult result3 = Approval.process(req3);
		system.debug('result3 instance status is ' +result3.getInstanceStatus());
		
		
		Work_Order__c getwo = [Select Id, status__c from work_order__c LIMIT 1 ];
    	
    	Order__c updorder = [Select Id, Name, status__c from Order__c LIMIT 1];
    	
    	test.stopTest();
    	
    	//system.debug('order status was changed to ' +updorder.status__c);
    	system.assert(updorder.status__c == 'Order Fulfilled');
    	system.assert(getwo.status__c == 'Work Order Complete');
    	
    }//end testUpdateOrderStatus()
    
    static testmethod void ProCentricNotificationTest()
    {
    	Account acct = CreateTestRecords.DefaultHospitalityAccount();
    	Order__c o = CreateTestRecords.DefaultOrder(acct.id);
    	Order_Item__c oiparent = New Order_Item__c(Name='Interactive Product Parent', status__c = 'Pending Installation Activate',
    	                                            project_type__c = 'Interactive New Rooms', order__c = o.id);
    	insert oiparent;
    	
    	Order_Item__c oichild = New Order_Item__c(Name='Pro:Centric Direct Customization', status__c = 'Pending Installation Activate',
    	                                            project_type__c = 'Interactive New Rooms', order__c = o.id, parent__c=oiparent.id); 
    	insert oichild;                                                                                     
    	
    	
    	
    	Work_Order__c rackbuild = CreateTestRecords.DefaultRackBuild(acct.id);
    	Associated_Item__c aiparent = New Associated_Item__c(Name='Interactive Product Parent', work_order__c = rackbuild.parent_work_order__c,
    	                                                     status__c = 'Pending Installation Activate', order_item__c = oiparent.id);
    	Associated_Item__c aichild = New Associated_Item__c(Name='Pro:Centric Direct Customization', work_order__c = rackbuild.parent_work_order__c,
    	                                                     status__c = 'Pending Installation Activate', order_item__c = oichild.id);
    	List<Associated_Item__c> ailist = New List<Associated_Item__c>();
    	ailist.add(aiparent);
    	ailist.add(aichild);
    	insert ailist;
    	
    	test.startTest();
    	
    	Date thisdate = system.today();
    	
    	rackbuild.to_warehouse_date__c = thisdate;
    	update rackbuild;
    	
    	test.stopTest();
    	
    	//no system assert statement here because no way to verify email actually went out when date was set
    	
    	
    }

}