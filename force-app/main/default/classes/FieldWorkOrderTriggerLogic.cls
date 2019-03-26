/*  
	02/2018 jjackson Add Professional Solutions case product type to the CreateTripLaborChildLines
	method so that trip and labor field work order line items for trip and labor can be auto-created
	when a case linked to a fwo has a case product type of Professional Solutions.
	01/2018 jjackson Entitlements for Third Party Partners:  added code to PopulateWorkOrderUponCreation
	to automatically assign field work order record type of Third Party FWO if the related case is a support
	case but the entitlement name on the case is contained in custom setting list ThirdPartyEntitlementName. 
	11/2017 jjackson Added code to PopulateTechField that will skip trying to get
    the user's ceridian name and region from the custom setting if the value of the
    account_country__c field is Canada.
	10/2017 jjackson Added code to EmailUponApproval method to cover email notifications for
    third party fwo's.  
	6/2017 jjackson Change PopulateWorkOrderUponCreation depending on whether the work order
    in the trigger is a third party work order or a regular work order
	Joan Jackson, Sonifi Solutions, November 2016
	This code governs functionality on the field service work order (WorkOrder object);
*/

public with sharing class FieldWorkOrderTriggerLogic
{
	//jjackson June 2017 added code to set the record type of the field work order based on the record
	//type of the related case.
	public static void PopulateWorkOrderUponCreation(List<WorkOrder> lstnewfwo)
	{
		List<WorkOrder> lstprocesswo = New List<WorkOrder>();
		List<Case> lstcasedetails = New List<Case>();
		Set<Id> setcaseid = New Set<Id>();
		Set<String> setentname = New Set<String>();
		Map<Id, Case> mpcasedetails = New Map<Id,Case>();
		List<ThirdPartyEntitlementName__c> cslist = [Select Name from ThirdPartyEntitlementName__c ];
		Id rectypeidtpp = Utilities.RecordTypeNameToId('WorkOrder', 'Third Party FWO');
		Id rectypeidfwo = Utilities.RecordTypeNameToId('WorkOrder', 'FWO');
		Id casetpprectype = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service' );
		
		for(WorkOrder fwo : lstnewfwo)
		{
			if(fwo.caseid != null)
			{  lstprocesswo.add(fwo);  }
		}
		
		for(ThirdPartyEntitlementName__c cs : cslist)
		{  setentname.add(cs.name);  }
		
		if(lstprocesswo.size() > 0)
		{
             for(WorkOrder wo : lstprocesswo)
             {  setcaseid.add(wo.caseid);  }  //get all the case ids and add them to a set for querying case details to put on the wo
		
		
			if(!setcaseid.IsEmpty())  //if there are case ids in the set, query for case details for the work order
			{
				lstcasedetails = [ Select Id, AccountId, Ownerid, Status, Priority, EntitlementId, Service_Contract_Name__c, AssetId,
			                   Account.RecordTypeId, Subject, Issue_Details_Description__c, Non_SONIFI_Issue__c, RecordtypeId, Entitlement.Name
			                   from Case where id in :setcaseid ];
			}
		
			if(lstcasedetails.size() > 0) //if the case list has cases in it, add them to a map
			{ for(Case c : lstcasedetails)
		  	{ mpcasedetails.put(c.Id, c);  }
			}
			
			if(mpcasedetails.size() > 0) //if there are cases in the map, add case info to the work orders in lstprocesswo
			{
				for(WorkOrder processwo : lstprocesswo)
				{
					if(mpcasedetails.containskey(processwo.CaseId))
					{

						processwo.priority = mpcasedetails.get(processwo.caseid).priority;
						processwo.accountid = mpcasedetails.get(processwo.caseid).accountid;
	
						processwo.non_sonifi_issue__c = mpcasedetails.get(processwo.caseid).non_sonifi_issue__c;
						processwo.subject = mpcasedetails.get(processwo.caseid).subject;
						processwo.description = mpcasedetails.get(processwo.caseid).issue_details_description__c;

						if(mpcasedetails.get(processwo.caseid).recordtypeid != casetpprectype) //if the case is not a contracted field service case
						{
							//jjackson 1/2018 if the case is a support case that does not have an ATT entitlement, create regular FWO
						  if(!setentname.Contains(mpcasedetails.get(processwo.caseid).entitlement.name))  //if the entitlement name is not in the
						  {                                                                                 //set that contains third party entitlements
							processwo.assetid = mpcasedetails.get(processwo.caseid).assetid;
						 	processwo.entitlementid = mpcasedetails.get(processwo.caseid).entitlementid;
						 	processwo.servicecontractid = mpcasedetails.get(processwo.caseid).service_contract_name__c;
						 	processwo.recordtypeid = rectypeidfwo;
						  }
						}

						String recordtypename = Utilities.RecordTypeIdToName('Account', mpcasedetails.get(processwo.caseid).Account.RecordtypeId);
						system.debug('recordtypename is ' +recordtypename);
						if(recordtypename == 'Healthcare Site')
						{  processwo.healthcare_site__c = true;  }

                        //jjackson if the case record type is contracted field service 
						if(mpcasedetails.get(processwo.caseid).recordtypeid == casetpprectype)
						{  processwo.recordtypeid = rectypeidtpp; }
						
						//jjackson 1/2018 if the case record type is not contracted field service case but
						//the case has a third party entitlement, create a third party fwo
						if(mpcasedetails.get(processwo.caseid).recordtypeid != casetpprectype &&
						    setentname.Contains(mpcasedetails.get(processwo.caseid).entitlement.name))
						{
							processwo.recordtypeid = rectypeidtpp;
							processwo.assetid = mpcasedetails.get(processwo.caseid).assetid;
						 	processwo.entitlementid = mpcasedetails.get(processwo.caseid).entitlementid;
						 	processwo.servicecontractid = mpcasedetails.get(processwo.caseid).service_contract_name__c;
							
						}
					}
				}//end for loop lstprocesswo
			}//end if mpcasedetails size > 0
			
		}//end if lstprocesswo size is > 0
	}//end PopulateWorkOrderUpon Creation
	
	//jjackson--when the field work order status changes to Submitted for Billing or the Submit for Billing box is checked, put the case owner into the technician__c
	//field on the work so that the person who worked on the order is not lost when the approval process changes the ownership.
	//if only the submit for billing box is checked, change the status on the work order to Submitted for Billing
	public static void PopulateTechField(List<WorkOrder> lstupdworkorders)
	{
			 
		  Map<Id,Id> mpworkorderowner = New Map<Id,Id>();
		  Set<Id> setownerid = New Set<Id>();
		  Map<Id,String> mpuser = New Map<Id,String>();
		  
		  for(WorkOrder wo : lstupdworkorders)
		  {		
		  		String owner = wo.ownerid;
		  		if(!owner.contains('00G')) //only add ownerid to the setownerid if the owner of the work order is not a queue
		  	    {  setownerid.add(wo.ownerid);  
		  	       mpworkorderowner.put(wo.id, wo.ownerid);  //if status is changed to submitted for billing or submit to billing = true, add to map and list
		  	    }//all add the origina ownerid to set so we can query name from the user object
		  	    
		  	    if(wo.Additional_Tech2__c != null)
		  	    { setownerid.add(wo.Additional_Tech2__c); } //also add the user id of the additional technician
		  	    
		  	    if(wo.Additional_Tech3__c != null)
		  	    { setownerid.add(wo.Additional_Tech3__c); }
		  	    //system.debug('work order in trigger is ' +wo.workordernumber +', ' +wo.status +', ' +wo.submit_for_billing__c);
		  	    if(wo.status != 'Submitted for Billing' && wo.submit_for_billing__c == true)
		  	    { wo.status = 'Submitted for Billing';  }
		  }//end for loop lstupdworkorders
		  
		  List<User> lstgetusernames = [ Select Id, Name from User where Id in :setownerid ];
		  if(lstgetusernames.size() > 0 )
		  {
		  	for(User u : lstgetusernames)
		  	{  mpuser.put(u.Id, u.Name);  }
		  } 
		
		  	for(WorkOrder updwo : lstupdworkorders)
		  	{
		  		if(mpworkorderowner.containskey(updwo.Id))
		  		{
		  			updwo.technician__c = mpworkorderowner.get(updwo.Id);  //update technician field with owner id
                    //no dml statement needed because this is running in before update trigger
                    
                    //now get the name from the map to find matching ceridian name in the custom setting
                    //also need the netsuite region for the report--it resides in the custom setting
                    //Added an "else" because when unit test is running, the Salesforce to Ceridian custom
                    //setting is not available.  For testing we must populate the variables with strings.
                   if(!test.isRunningTest())
                   {
                    if(mpuser.containskey(updwo.technician__c))
                    {
                      if(updwo.Account_Country__c != 'Canada')
                      {
                    	String techname = mpuser.get(updwo.technician__c);
                    	Salesforce_to_Ceridian_Users__c cs = Salesforce_to_Ceridian_Users__c.getInstance(techname);
                    	String ceridianname = cs.Ceridian_Name__c;
                    	String region = cs.FSR_Region__c;
                    	updwo.ceridian_name1__c = ceridianname;
                    	updwo.FSR_Region__c = region;
                    	
                      }
       	
                    }
                    else
                    {  system.debug('salesforce user id not found so could not get ceridian name.'); }
                   }
                   else //populate the variables with string values for unit tests
                   {
                   	  String techname = 'Elmer Fudd';
                   	  String ceridianname = 'Elmer Fudd';
                   	  String region = 'Northeast';
                   	  updwo.ceridian_name1__c = ceridianname;
                   	  updwo.FSR_Region__c = region;
                   }
		  		}
		  		
		  		
		  		//jjackson 11/2017 exclude Canadian work orders from finding ceridian names
		  		if(updwo.account_Country__c != 'Canada')
		  		{
		  			//also need the ceridian name for the additional tech2 and tech3
		  			if(updwo.Additional_Tech2__c != null && mpuser.containskey(updwo.Additional_Tech2__c))
		  			{
		  				String addtech = mpuser.get(updwo.Additional_Tech2__c);
		  				Salesforce_to_Ceridian_Users__c cs = Salesforce_to_Ceridian_Users__c.getInstance(addtech);
		  				String ceridname = cs.Ceridian_Name__c;
		  				updwo.tech2_ceridian_name__c = ceridname;
		  			}
		  		
		  			if(updwo.Additional_Tech3__c != null && mpuser.containskey(updwo.Additional_Tech3__c))
		  			{
		  				String addtech = mpuser.get(updwo.Additional_Tech3__c);
		  				Salesforce_to_Ceridian_Users__c cs = Salesforce_to_Ceridian_Users__c.getInstance(addtech);
		  				String ceridname = cs.Ceridian_Name__c;
		  				updwo.tech3_ceridian_name__c = ceridname;
		  			}
		  		}//end if account country is not Canada

		  	}//end for loop lstwo
		
	}//end populatetechnicanfield
	
	//jjackson whenever a field work order is created, pre-populate the field work order events list with line items
	//to track labor hours spent on each individual category for billing purposes
	public static void CreateFieldWorkOrderEvents(List<WorkOrder> lstwo)
	{   
		Id rectypeidfwo = Utilities.RecordTypeNameToId('WorkOrder', 'FWO');
		List<FieldWorkOrder_Events__c> lstnewfwoevents = New List<FieldWorkOrder_Events__c>();
		List<FieldWorkOrder_Event_Settings__c> lstevents = New List<FieldWorkOrder_Event_Settings__c>();

		//get the custom setting for all the values that go into the Field Work Order Event records
		Map<String,FieldWorkOrder_Event_Settings__c> mapcs = New Map<String, FieldWorkOrder_Event_Settings__c>();
		if(!test.IsRunningTest())
		{	mapcs = FieldWorkOrder_Event_Settings__c.getAll();
			lstevents = mapcs.Values();
		}
		
		for(WorkOrder wo : lstwo)
		{
           if(wo.recordtypeid == rectypeidfwo) //jjackson 6/2017 only create the work order events if the record type is not third party
           {
			if(test.IsRunningTest())
			{
				FieldWorkOrder_Events__c event1 = New FieldWorkOrder_Events__c(event_type__c = 'System Event', field_work_order__c = wo.id,
				                                      event_name__c = 'FTG', Event_Description__c = 'LNB|Distribution|Receivers|Modulators|Etc.',
				                                      hours__c = 1);
				                                      
				FieldWorkOrder_Events__c event2 = New FieldWorkOrder_Events__c(event_type__c = 'Other Event', field_work_order__c = wo.id,
				                                      event_name__c = 'Front Desk Equipment', Event_Description__c = 'Relocate/Replace by Request|Damage/Missing|Etc.',
				                                      hours__c = 1);
				lstnewfwoevents.add(event1);
				lstnewfwoevents.add(event2);
				           
			}
			
			for(FieldWorkOrder_Event_Settings__c fwoe : lstevents)
			{
				FieldWorkOrder_Events__c newrec = New FieldWorkOrder_Events__c();
				
				newrec.event_name__c = fwoe.event_name__c;
				newrec.event_type__c = fwoe.event_type__c;
				newrec.event_description__c = fwoe.event_description__c;
				newrec.field_work_order__c = wo.id;
				
				lstnewfwoevents.add(newrec);
			}
		}
	  }//end for loop lstwo
		
		if(lstnewfwoevents.size() > 0)
		{  insert lstnewfwoevents;  }
	}
	
	//jjackson When a field work order's status changes to Submitted for Billing, automatically put the record
	//into the billing approval process
	public static void StartWorkOrderApprovalProcess(List<WorkOrder> lstapprovewo)
	{
		   for(WorkOrder updwo : lstapprovewo)
		   {
			//for each work order in this loop, start the approval process
		  	  Approval.ProcessSubmitRequest req = New Approval.ProcessSubmitRequest();
		  	  req.setComments('Submitted for approval.');
		  	  req.setObjectId(updwo.Id);
		  	  Approval.ProcessResult result = Approval.process(req);
		  	  system.debug('field work order ' +updwo.workordernumber +' was successfully submitted for approval');
		   }	
	}

	//When a field work order is billed, auto-create the trip and labor child line items depending on a) what type of
	//product inventory is related to the work order; b) whether the site is healthcare, hotel, or the work was performed
	//by a service partner.
	public static void CreateTripLaborChildLines(List<WorkOrder> lstbillingwo)
	{
		system.debug('*****************BEGIN CreateTripLaborChildLines********************');
		

		Set<String> setproductcodes = New Set<String>();
		String NonChargeablepn;
		Map<String,Id> mpproductcodetoid = New Map<String,Id>();
		Map<Id,String> mpidtocasetype = New Map<Id,String>();
		Map<Id,String> mpidtoproducttype = New Map<Id,String>();
		Map<String,FieldWorkOrderTripandLabor__mdt> mplabortypes = New Map<String,FieldWorkOrderTripandLabor__mdt>();
		List<WorkOrderLineItem> lstinsertitems = New List<WorkOrderLineItem>();
		List<WorkOrderLineItem> lstprodtypelineitems = New List<WorkOrderLineItem>();
		List<FieldWorkOrderTripandLabor__mdt> listtriplabor = New List<FieldWorkOrderTripandLabor__mdt>();
		Id fworectypeid = Utilities.RecordTypeNameToId('WorkOrder', 'FWO');
		Id fwotprectypeid = Utilities.RecordTypeNameToId('WorkOrder', 'Third Party FWO');
		List<WorkOrder> lstthirdpartywo = New List<WorkOrder>();
		
		for(WorkOrder wo : lstbillingwo)
		{
			if(wo.recordtypeid == fworectypeid)
			{
				{ mpidtocasetype.put(wo.Id, wo.case_product_type__c); 
		  		system.debug('case product type is ' +wo.case_product_type__c);
				}
			}
		}
		
		//query custommetadata type FieldWorkOrderTripandLabor__mdt that stores all the trip and labor part numbers by
		//site type and product inventory type
		listtriplabor = [ Select product_code__c, work_order_product_parent__c, work_type__c,
		                  label, developername, case_product_type__c from fieldworkordertripandlabor__mdt ];
	
		//system.debug('listtriplabor size is ' +listtriplabor.size());
		
		//store all the custom metadata records in a map so we can pull out the ones we need depending on the work order type                                                  
		for(FieldWorkOrderTripandLabor__mdt trip : listtriplabor)
		{  mplabortypes.put(trip.developername,trip);  
		   setproductcodes.add(trip.product_code__c);  //get all the productcodes so the product2 id can be queried
		 //  system.debug(trip.developername +', ' +trip.product_code__c);
		}
		
        system.debug('setproductcodes size is ' +setproductcodes.size());		
		List<Product2> lstproduct2 = New List<Product2>();
		lstproduct2 = [ Select Id, productcode, name, isactive from product2 where productcode in :setproductcodes AND isactive = true ];
		//system.debug('lstproduct2 size is ' +lstproduct2.size());
		//create a map of product code to product2 id for use later
		for(Product2 prod : lstproduct2)
		{
			mpproductcodetoid.put(prod.productcode,prod.Id);
			//system.debug('adding to mpproductcodetoid ' +prod.productcode + ', ' +prod.id );
		}
		
		for(WorkOrder wo : lstbillingwo)  //first process all the work orders that have a product type
		{
			String casetype; //clear value of case product type variable with each new work order in the loop 
			Boolean blsub = false;
			Boolean blhc = false;
			Id rectypeid = wo.recordtypeid;  //jjackson 6/2017 get record type id of each work order

			if(rectypeid == fwotprectypeid)
			{ lstthirdpartywo.add(wo); }
		
		  if(rectypeid == fworectypeid)
		  {	
			if(mpidtocasetype.containskey(wo.id))
			{  casetype = mpidtocasetype.get(wo.Id); }  //get the case product type related to the field work order
			else
			{  system.debug('mpidtocaseproduct did not contain a case product type for ' +wo.workordernumber);  }

			//system.debug('productparent = ' +productparent);

		  if(casetype != null)	
		  {
		  	
		   if(wo.recordtypeid == fworectypeid) //proceed down this path for regular work orders only
		   {
			//determine whether the work order is for hotel, healthcare, or was done by a service partner
			if(wo.sub_partner_performed_work__c == true || wo.contractor_name__c != null)
			{  blsub = true; }
			if(wo.healthcare_site__c == true)
			{  blhc = true;  }
		
			//create blank field work order child lines for trip and labor
			WorkOrderLineItem laborline = New WorkOrderLineItem();
			WorkOrderLineItem tripline = New WorkOrderLineItem();
			WorkOrderLineItem nonchargeable = New WorkOrderLineItem();  //create non-chargeable labor line for all work orders
			
			//Instantiate records for FieldWorkOrderTripandLabor custom metadata
			FieldWorkOrderTripandLabor__mdt trip = New FieldWorkOrderTripandLabor__mdt();
			FieldWorkOrderTripandLabor__mdt labor = New FieldWorkOrderTripandLabor__mdt();
			FieldWorkOrderTripandLabor__mdt nclabor = New FieldWorkOrderTripandLabor__mdt();
			
		
			if(blsub == true) //if the work was performed by a service partner
			{
				//system.debug('blsub = ' +blsub);
				
		  		if(blhc == true) //if it is a  healthcare site
		  		{   //system.debug('blhc = ' +blhc);
		  			
					trip = mplabortypes.get('SP_Healthcare_Trip');
					labor = mplabortypes.get('SP_Healthcare_Labor');
					nclabor = mplabortypes.get('SP_Healthcare_NCLabor');
		  		}
		  		else  //if not a hospital, we then need to look at what type of case product is on the work order
		  		{
		  		  if(wo.recordtypeid == fworectypeid)
		  		  {
		  			//system.debug('inside else statement where blhc = false');
		  			if(casetype == 'Interactive' ||casetype == 'FTG'||casetype == 'SoniCast'||casetype == 'Interactive - ONCO'||casetype=='Professional Solutions')
		  			{
		  				//system.debug('inside if prodparent = itv, ftg, or sonicast');
		  				trip = mplabortypes.get('SP_ITV_Trip');
						labor = mplabortypes.get('SP_ITV_Labor');
						nclabor = mplabortypes.get('SP_ITV_NCLabor');
		  			}
		  			else 
		  			{
		  				if(casetype == 'Broadband')
		  				{  //system.debug('inside else if prod parent is broadband');
		  					trip = mplabortypes.get('SP_GIA_Trip');
							labor = mplabortypes.get('SP_GIA_Labor');
							nclabor = mplabortypes.get('SP_GIA_NCLabor');
		  				}
		  			}
		  		  }//end if record type is for a regular field work order
	
		  		}//end else
		    }//end if blsub = true
		else //if work was not performed by a service partner
		{
			if(blhc == true) //if this is a healthcare site
		    {
		    	//the ITV records can be used because the trip/labor part numbers are the same for ITV/FTG
		    	trip = mplabortypes.get('Healthcare_ITV_Trip');
				labor = mplabortypes.get('Healthcare_ITV_Labor');
				nclabor = mplabortypes.get('Healthcare_ITVNC_Labor');
		    }
		    else //if not a healthcare site
		    {
		    	//now we must check the product parent on the work order to get the right trip and labor lines
		    	if(casetype == 'Interactive'||casetype == 'SoniCast'||casetype=='Interactive - ONCO'||casetype=='Professional Solutions')
		    	{
		    		trip = mplabortypes.get('Hotel_ITV_Trip');
					labor = mplabortypes.get('Hotel_ITV_Labor');
					nclabor = mplabortypes.get('Hotel_ITV_NCLabor');
		    	}
		    	if(casetype == 'FTG')
		    	{
		    		trip = mplabortypes.get('Hotel_FTG_Trip');
					labor = mplabortypes.get('Hotel_FTG_Labor');
					nclabor = mplabortypes.get('Hotel_FTG_NCLabor');
		    	}
		    	if(casetype == 'Broadband')
		    	{
		    		trip = mplabortypes.get('Hotel_GIA_Trip');
					labor = mplabortypes.get('Hotel_GIA_Labor');
					nclabor = mplabortypes.get('Hotel_GIA_NCLabor');
		    	}
		    }//end else
		}//end else
		
		  if(trip != null)
		  {
		  	if(mpproductcodetoid.containskey(trip.product_code__c))
		  	{ tripline.part_number__c = mpproductcodetoid.get(trip.product_code__c); 
		  	  tripline.qty__c = 1.0;
		  	  tripline.workorderid = wo.id;
		  	  lstinsertitems.add(tripline);
		  	}
		  	else
		  	{  system.debug(' for this field work order could not find trip product code in the mpproductcodetoid map: ' +wo.Id);  }
		  	 
		  }
		  else
		  { system.debug('mplabortype map for trip was null for field work order' +wo.Id);  }
		  
		  if(labor != null)
		  {
		  	if(mpproductcodetoid.containskey(labor.product_code__c))
		  	{ laborline.part_number__c = mpproductcodetoid.get(labor.product_code__c); 
		  	  laborline.workorderid = wo.Id;
		  	  lstinsertitems.add(laborline);
		  	}
		  	else
		  	{  system.debug('for this field work order could not find labor product code in the mpproductcodetoid map: ' +wo.Id);  }
		  	
		  }
		  
		  if(nclabor != null)
		  {
		  	if(mpproductcodetoid.containskey(nclabor.product_code__c))
		  	{ nonchargeable.part_number__c = mpproductcodetoid.get(nclabor.product_code__c); 
		  	  nonchargeable.workorderid = wo.Id;
		  	  lstinsertitems.add(nonchargeable);
		  	}
		  	else
		  	{  system.debug('for this field work order could not find non-chargeable labor product code in the mpproductcodetoid map: ' +wo.Id);  }
		  }
		 }//end if recordtype is fworectypeid
		}//end if case type != null
		else
		{  system.debug('Did not find a case type for field work order ' +wo.workordernumber);  }
	   }//end if record type is fwo record type
	  }//end for loop

		//jjackson 10/2017 added this to process third party fwo's a little differently
	  if(lstthirdpartywo.size() > 0)
	  {
	  	for(WorkOrder tpwo : lstthirdpartywo)
	  	{   
	  		FieldWorkOrderTripandLabor__mdt tptripinfo = New FieldWorkOrderTripandLabor__mdt();
	  		FieldWorkOrderTripandLabor__mdt tplaborinfo = New FieldWorkOrderTripandLabor__mdt();
	  		WorkOrderLineItem tripline = new WorkOrderLineItem();
	  		WorkOrderLineItem laborline = new WorkOrderLineItem();

	  		if(tpwo.sub_partner_performed_work__c == false)
	  		{
	  			tptripinfo = mplabortypes.get('Third_Party_Trip');
	  			tplaborinfo = mplabortypes.get('Third_Party_Labor');
	  		}
	  		else
	  		{
	  			tptripinfo = mplabortypes.get('Third_Party_SP_Trip');
	  			tplaborinfo = mplabortypes.get('Third_Party_SP_Labor');
	  		}		  	

	  		if(tptripinfo != null)
	  		{
	  			if(mpproductcodetoid.containskey(tptripinfo.product_code__c))
	  			{
	  				Id partid = mpproductcodetoid.get(tptripinfo.product_code__c);
	  				tripline.part_number__c = partid;
	  			}
	  			tripline.workorderid = tpwo.id;
	  			lstinsertitems.add(tripline);
	  		}

	  		if(tplaborinfo != null)
	  		{
	  			if(mpproductcodetoid.containskey(tplaborinfo.product_code__c))
	  			{
	  				Id partid = mpproductcodetoid.get(tplaborinfo.product_code__c);
	  				laborline.part_number__c = partid;
	  			}
	  			laborline.workorderid = tpwo.id;
	  			lstinsertitems.add(laborline);
	  		}
          }//end for loop lstthirdparty

	  	}//end if lstthirdpartywo size > 0
	  
	   if(!lstinsertitems.IsEmpty())
		{
		  	try{insert lstinsertitems;  }
		  	catch(Exception e)
		  	{  system.debug('ERROR inserting trip and labor work order line items for field work order: ' +e.getMessage()); }
		  	
		}
		
		
	  
	  system.debug('*************************END CLASS CreateTripLaborChildLines**********************');
	  
	}//end CreateTripLaborChildLines
	
                                                       
	
	public static void PopulateExceptions(List<WorkOrder> triggernewlist)
	{
		set<Id> setacctids = New Set<Id>();
		Map<Id,String> mpacct = New Map<Id,String>();
		List<Account> lstgetaccounts = New List<Account>();
		
		for(WorkOrder wo : triggernewlist)
		{  setacctids.add(wo.accountid);  }
		
		lstgetaccounts = [ Select Id, Service_Contract_Exceptions__c from Account where id in :setacctids];
		
		if(lstgetaccounts.size() > 0)
		{
			for(Account a : lstgetaccounts)
			{
				if(a.service_contract_exceptions__c != null)	
			    {  mpacct.put(a.Id, a.service_contract_exceptions__c);  }
			}
		}
		
		if(mpacct.size() > 0)
		{
			for(WorkOrder updwo : triggernewlist)
			{
			  if(mpacct.containskey(updwo.accountid))
			  {  updwo.service_contract_exceptions__c = mpacct.get(updwo.accountid); } 
			}
		}
		//no dml update statement because this is running in a before trigger.
		
	}//end method populateexceptions
	
	
	//when the work order Submit for Billing checkbox is checked, send an email to the customer 
	//(using Customer Email field or contact email field) that shows work performed and field work order events
	public static void EmailUponApproval(List<WorkOrder> lstsubmittedwo)
	{
		system.debug('***************BEGIN EmailUponApproval*******************');
		
		Id rectypeidfwo = Utilities.RecordTypeNameToId('WorkOrder', 'FWO'); //jjackson 6/2017 determine the record type
		List<FieldWorkOrder_Events__c> fwoelist = New List<FieldWorkOrder_Events__c>();
		Map<Id,WorkOrder> mpapprovedwo = New Map<Id,WorkOrder>();
		Map<Id, List<FieldWorkOrder_Events__c>> mpfwotofwoe = New Map<Id,List<FieldWorkOrder_Events__c>>();
		
		//put the submitted for billing work orders in a map if the record type is FWO.  We don't want to send
		//emails out where the record type is for a third party partner work order        
		for(WorkOrder wo : lstsubmittedwo)
		{
		   if(wo.recordtypeid == rectypeidfwo)   //jjackson 6/2017
		   {   mpapprovedwo.put(wo.id, wo);  }

		} 
		
	if(mpapprovedwo.size() > 0)  //the following code processes third party work orders
	{	//query the field work order events related to the work orders that are billing approved
		fwoelist = [ Select field_work_order__c, Event_Name__c, Event_Description__c, LongComments__c, Hours__c, event_type__c 
		             from FieldWorkOrder_Events__c where
		             hours__c != null AND hours__c > 0 AND field_work_order__c in :mpapprovedwo.keyset() ];
		             
        
		//create another map that matches work order id to the related list of field work order events
		
		//SAMPLE CODE Create map of type <Id,List<SObject>>
		for(FieldWorkOrder_Events__c fwoe : fwoelist)
		{
			if(mpfwotofwoe.containskey(fwoe.field_work_order__c))
			{
				mpfwotofwoe.get(fwoe.field_work_order__c).add(fwoe);
			}
			else
			{
				List<FieldWorkOrder_Events__c> templist = New List<FieldWorkOrder_Events__c>();
				templist.add(fwoe);
				mpfwotofwoe.put(fwoe.field_work_order__c, templist);
			}
		}
 
 		EmailUtilities.FieldWorkOrderCustomerNotification(mpapprovedwo, mpfwotofwoe);
 		
 		system.debug('*****************************END EmailUponApproval***********************');          
	} //end if mpapprovedwo size > 0	
  }//end method EmailUponApproval

}//end class FieldWorkOrderTriggerLogic