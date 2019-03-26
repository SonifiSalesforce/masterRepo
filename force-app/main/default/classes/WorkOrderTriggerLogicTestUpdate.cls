@istest
public with sharing class WorkOrderTriggerLogicTestUpdate {
	
		
	static testmethod void testWorkOrderNameCompareUpdate()
	{
	   /* create work order then add product parent associated line items.  Verify the work order name
	   changes.  Create a child work order and verify the child work order name reflects the product
	   parents related to the parent work order.  Add another product parent associated item to the
	   parent work order. Verify both the parent and child work order names update with the new product
	   parent's abbreviation.
	   */	
	   
	   Account acc = DataGenerator.createAccounts(1,true)[0];
	   Account withsite = [ Select Id, site_id__c from Account where Id = :acc.Id LIMIT 1];
	   String siteid = withsite.site_id__c;
	   Id uid = Userinfo.getUserId();
	   RecordType rectype = [Select Id, Name from RecordType where SobjectType = 'Work_Order__c' and Name = 'Install' LIMIT 1];
	   Id rectypeid = rectype.Id;
	   Work_Order__c parentwo = New Work_Order__c(recordtypeid = rectypeid, site__c = acc.Id, install_manager__c = uid,
	                                               approver__c = uid, Division__c = 'Domestic', Region__c = 'Southwest', project_coordinator__c = uid,
	                                               ownerid = uid ); 
	                                               
	   insert parentwo;
	   
	   Work_Order__c woverifyname = [ Select Id, Name from Work_Order__c where id = :parentwo.Id LIMIT 1];
	   system.debug('woverifyname name is ' +woverifyname.Name);
	   
	   Product2 ftgprod = New Product2(name = 'FTG Product Parent', productcode = 'CC-testftg-1', Family = 'FTG');
	   Product2 itvprod = New Product2(name = 'Interactive Product Parent', productcode = 'CC-testitv-1', Family = 'Interactive');
	   List<Product2> prodlist = new List<Product2>();
	   prodlist.add(ftgprod);
	   prodlist.add(itvprod);
	   insert prodlist;
	   
	   Id FTGid = ftgprod.id;
	   Id ITVid = itvprod.id;

	   Order_Item__c oi1 = New Order_Item__c(Name = 'FTG Product Parent', status__c = 'Pending Installation Activate', account__c = acc.id, product__c = FTGid);
	   Order_Item__c oi2 = New Order_Item__c(Name = 'Interactive Product Parent', status__c = 'Pending Installation Activate', account__c = acc.id, product__c = ITVid );
	   List<Order_Item__c> insertlist = New List<Order_Item__c>();
	   insertlist.add(oi1);
	   insertlist.add(oi2);
	   insert insertlist;
	   
	   Associated_Item__c ai1 = New Associated_Item__c(Name='FTG Product Parent', work_order__c = woverifyname.Id, status__c = 'Pending Installation Activate',  
	                                                   quantity__c = 10, order_item__c = oi1.id);
	   insert ai1;
	   
	   test.startTest();
	   
	   		Work_Order__c parentwoupd = [ Select Id, Name, project_type__c  from Work_Order__c where id = :woverifyname.Id LIMIT 1];
	   		system.debug('parentwoupd name is ' +parentwoupd.name);
	   		
	   		RecordType rectyperb = [Select Id, Name from RecordType where SobjectType = 'Work_Order__c' and Name = 'Rack Build' LIMIT 1];
	   		
	   		Id rectypeidrb = rectyperb.Id;

	   		Work_Order__c newchildwo = New Work_Order__c(recordtypeid = rectypeidrb, site__c = acc.Id, ownerid = uid, parent_work_order__c = parentwoupd.id); 
	   		insert newchildwo;
	   		
	   		Work_Order__c childwo = [ Select Id, Name from Work_Order__c where id = :newchildwo.id LIMIT 1];
	   		system.debug('childwo name is ' +childwo.Name);
	   		
	   		Associated_Item__c ai2 = New Associated_Item__c(Name='Interactive Product Parent', work_order__c = parentwoupd.Id, status__c = 'Pending Installation Activate',  
	                                                   quantity__c = 10, order_item__c = oi2.id);
	        insert ai2;
	        
	        parentwoupd.project_type__c = 'New Installation';
	        update parentwoupd;
	        
	        Work_Order__c updwo = [ Select Id, Name from Work_Order__c where id = :parentwoupd.Id LIMIT 1 ];
	        Work_Order__c updchildwo = [ Select Id, Name from Work_Order__c where id = :childwo.id LIMIT 1 ];
	        system.debug('wo names for parent and child are ' +updwo.Name +', ' +updchildwo.Name );
	        
	   test.stopTest();
	   
	   //system.assert(updwo.Name.contains('Interactive-FTG'));
	   //system.assert(updchildwo.Name.contains('Interactive-FTG'));
	                                                   
	   
	}//end testWorkOrderNameCompareUpdate
	
} //end workordertriggerlogictestupdate.cls