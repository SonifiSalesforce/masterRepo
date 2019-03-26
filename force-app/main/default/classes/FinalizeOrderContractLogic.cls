public with sharing class FinalizeOrderContractLogic {
	
	public static Id Acctid;
	public static Id OrId;
	public static Id returnorderid;
	public static String AcctName;
	public static Map<Id,SBQQ__Subscription__c> mpProductParent = New Map<Id,SBQQ__Subscription__c>();
	public static Map<Id,String> mpsubidtoparentcode = New Map<Id,String>();
	public static List<SBQQ__Subscription__c> lstsubs = new List<SBQQ__Subscription__c>();
	public static Map<String,Id> mpproductcodetoid = new Map<String,Id>();
	public static Set<Id> setcontractids = New Set<Id>();
	public static Id ordidpassedin;
	
	public static ID ProcessOrderAndOrderItems(Boolean processOrder, ID orderId, List<SBQQ__Subscription__c> lstsublineitems)
    {
    	system.debug('********BEGIN ProcessOrderAndOrderItems*************');
    	
            MAP<ID,ID> mpContractParents=new MAP<ID,ID>();
            Map<String,Id> mpproductcodetoid = New Map<String,Id>();
            MAP<ID,SBQQ__Subscription__c> mpcontrLines=new MAP<ID,SBQQ__Subscription__c>();
            MAP<ID,Order_Item__c> mpcntrLIOrd=new MAP<ID,Order_Item__c>();
            LIST<Order_Item__c> lstorderitems =new LIST<Order_Item__c>();
            List<Order_Item__c> lstupdorderitems = new List<Order_Item__c>();
            string OrdName;
            string OrdSite;
            String constatus;
            Set<Id> setorderitemid = New Set<Id>();
            List<Order_Item__c> lstnewitems = New List<Order_Item__c>();
            Map<Id,Id> mpitemtosub = New Map<Id,Id>();
            
            
            if(orderid != null)
            {  ordidpassedin = orderId;  }// capture the orderId passed in so it can be used in other methods
            
            system.debug('ordidpassedin is ' +ordidpassedin);
        
            Savepoint sp=database.setSavepoint();
            
          lstsubs = lstsublineitems;
          //for(SBQQ__Subscription__c s :lstsubs)
          //{ system.debug('sub line passed into ProcessOrderAndOrderItems: ' +s.name__c +', ' +s.sbqq__product__r.productcode);  
            
          //}
          
          
        
           //system.debug('contractLineItemIds:'+contractLineItemIds);
           SBQQ__Subscription__c oneitem = New SBQQ__Subscription__c();
           oneitem = lstsublineitems[0];
           Acctid = oneitem.sbqq__account__c;
           AcctName = oneitem.sbqq__account__r.name;
           Constatus = oneitem.sbqq__contract__r.Contract_Status__c;
           
           
 
            Set<Id> setsubids = New Set<Id>(); //set of all the subscription item ids
            for(SBQQ__Subscription__c sub : lstsubs)
            {
            	
            	if(sub.name__c.contains('Product Parent'))
            	{ mpProductParent.put(sub.id, sub); //map of subscription ids to subscription record
            	  //system.debug('product parent map is ' +sub.id + ', ' +sub.name__c);
            	} 
            	
            	setsubids.add(sub.id);
            	
            	if(!sub.name__c.contains('Product Parent'))
            	{
            		//String prodcodeconid = '';
            		//String code = sub.parent__r.sbqq__product__r.productcode;
            		//String con = sub.sbqq__contract__c;
            		//prodcodeconid = code+con;//jjackson changed the value to productcode + contractid
            		mpsubidtoparentcode.put(sub.id, sub.parent__c); //map of subscription ids to subscription parent__c        		
            	}
            	
            	
             	
            }
 
      		//create the order *************************************************
            if (processOrder==true && orderId==null)
            {   
            
            	ID ordRecTp=Utilities.RecordTypeNameToId('Order__c','Order');
                Order__c newOrder=new Order__c();
                newOrder.Name=AcctName;
                newOrder.Site__c=Acctid;
                newOrder.RecordTypeId=ordRecTp;
                newOrder.Status__c='Order Approved';
                system.debug('Inserting New Order:');
                insert newOrder;
                OrId=newOrder.Id;
                system.debug('Order Inserted:'+OrId);  
                
                lstorderitems = CreateNewOrderItems();
                
                if(lstorderitems.size() > 0)
                { 
                	system.debug('inserting order items');
                	try{insert lstorderitems;}
                	catch(Exception exc)
                	{  system.debug('Error inserting lstorderitems : ' +exc.getmessage()); }  
                
                }
               
                system.debug('listorderitems size is ' +lstorderitems.size());
                
                if(lstorderitems.size() > 0 )
                {
                	for(Order_Item__c o : lstorderitems)
                	{	setorderitemid.add(o.id);  }
                		
                	
                	lstnewitems = [Select id, parent__c, equipment_ownership__c, project_type__c, subscription__c, subscription__r.parent__c, name, subscription__r.project_type__c,
                	               subscription__r.equipment_ownership__c from order_item__c where id in :setorderitemid ];	
                }
                
                if(lstnewitems.size() > 0)
                {	               
                	for(Order_Item__c oi : lstnewitems)
                	{
                   		mpitemtosub.put(oi.subscription__c, oi.id);
                	}
                	
                	system.debug('mpitemtosub size is ' +mpitemtosub.size());
                                    
                	for(Order_Item__c oi : lstnewitems)
                	{
                		
               			if(!oi.name.contains('Product Parent') && mpitemtosub.containskey(oi.subscription__r.parent__c))
               			{
               				oi.parent__c = mpitemtosub.get(oi.subscription__r.parent__c);
               			}
               			
               			oi.project_type__c = oi.subscription__r.project_type__c;
               			oi.equipment_ownership__c = oi.subscription__r.equipment_ownership__c;
               			lstupdorderitems.add(oi);
                		
                     	
                	}//end for listorderitems
                
                	update lstupdorderitems;  //update the order items with parent ids
                
                } //end if lstorderitems size > 0
                else
                { system.debug('Unable to complete order because no order items were created.');  }
                
            }//end if processorder = true and orderid is null
            
            if(processorder && orderid != null)  //update an existing order
            {
            	FindAndUpdateOrderItems(orderid);
            } 
            
            if(OrId != null)
            {
            	returnorderid = OrId;
            }
            else
            {   returnorderid = orderid;  }
   
    	system.debug('**************End ProcessOrderAndOrderItems*************');
 
        return returnorderid;
    }
    
	public static List<Order_Item__c> CreateNewOrderItems()
	{
		system.debug('********BEGIN CREATENEWORDERITEMS************');
		
		List<Order_Item__c> lstNewOli = New List<Order_Item__c>();
		
		system.debug('lstsubs size is ' +lstsubs.size());
		
		for(SBQQ__Subscription__c s : lstsubs)
		{
			//system.debug('s.product_parent_id__c for ' +s.name__c +' is ' +s.product_parent_id__c);
			Order_Item__c OliRec = New Order_Item__c();
			OliRec.Product_Parent_Id__c = null;
        	OliRec.Subscription__c = s.Id;
        	OliRec.Account__c=Acctid;
            OliRec.Product__c=s.sbqq__product__c;
            OliRec.Name=s.Name__c;
            OliRec.Parent__c=null;
            //system.debug('OrId is ' +OrId);
            if( ordidpassedin == null)
            { 	OliRec.Order__c=OrId; }
            else
            {   OliRec.Order__c = ordidpassedin;  }
            OliRec.Total_Remaining_Rooms__c=s.sbqq__quantity__c;
            OliRec.Total_Rooms_Ordered__c=s.sbqq__quantity__c;
            OliRec.Unit_Selling_Price__c=s.sbqq__regularprice__c;
            OliRec.Status__c=s.Status__c;
            OliRec.Asset__c = s.product_inventory__c;
            OliRec.Contract_Type__c = s.contract_type__c;
            OliRec.Product_Code__c = s.sbqq__product__r.productcode;
            OliRec.Price__c = s.sbqq__regularprice__c;
  
            if(mpProductParent.containskey(s.id)) //jjackson corrected to use s.id instead of s.product_parent_code__c
            {
            	
            	OliRec.Equipment_Ownership__c = mpProductParent.get(s.id).equipment_ownership__c;
            	OliRec.Project_Type__c = mpProductParent.get(s.id).project_type__c;
  
            }
            
            lstNewOli.add(OliRec);
         }
         
         system.debug('**********END CreateNewOrderItems***********');
         
         return lstNewOli;
      }
      
      public static void FindAndUpdateOrderItems(Id oid)
      {
      		system.debug('*********BEGIN FINDANDUPDATEORDERITEMS*************');
      	
      		Map<Id, SBQQ__Subscription__c> mpsubitems = New Map<Id, SBQQ__Subscription__c>();
      		List<Order_Item__c> lstorditem = New List<Order_Item__c>();
      		Map<Id, Order_Item__c> mpexistingoi = New map<Id, Order_Item__c>(); //subscription id to order item
      		List<Order_Item__c> lstnewitems = New List<Order_Item__c>();
      		Boolean contractmatch = false;
      		Map<String,Order_Item__c> mpproductcodetoorderitem = New Map<String,Order_Item__c>();
      		List<Order_Item__c> lstparenteditems = new List<Order_Item__c>();
      		
      	      		
      		for(SBQQ__Subscription__c sub : lstsubs)
      		{    mpsubitems.put(sub.id, sub);  }
      		
      		lstorditem = [ Select id, Name, status__c, project_type__c, subscription__c, account__c, order__c, 
      		               asset__c, product__c, contract_type__c, equipment_ownership__c, total_rooms_ordered__c,
      		               total_remaining_rooms__c, quantity__c, unit_selling_price__c, price__c, Product_Code__c,
      		               subscription__r.sbqq__contract__c, product__r.productcode, subscription__r.parent__c
      		               from Order_Item__c where order__c = :oid ];
      		               
      		  		               
      		for(Order_Item__c oi : lstorditem)
      		{  
      		   String key = '';
      		   String pcode = oi.product__r.productcode;
      		   String cid = oi.subscription__r.sbqq__contract__c;
      		   key = pcode+cid;
      		  // system.debug('key/value in mpproductcodetoid is ' +key +', ' +oi.id);
      		   mpproductcodetoid.put(key, oi.id);  //map matches order item product code&&contractid to order item id
      		   mpexistingoi.put(oi.subscription__c, oi); //map matches subscription id to existing order item
      		   setcontractids.add(oi.subscription__r.sbqq__contract__c);
      		}
      		
 			for(SBQQ__Subscription__c s :lstsubs) //jjackson spin through the subscriptions to see if the contract id exists on the existing order items
 			{
 				if(setcontractids.contains(s.sbqq__contract__c))
 				{ contractmatch = true;  }
 			}
      		
      	if(contractmatch == true)
      	{
      		Boolean extraitem = false;
      		for(Id subid : mpsubitems.keyset())
      		{
      			if(!mpexistingoi.containskey(subid))
      			{  extraitem = true;  }
      		}
      		
      		
      		
      		//if there are more subscriptions than order items, add new order items               
      		if(extraitem == true)
      		{  lstnewitems = AddOrderItems(mpexistingoi, mpsubitems, oid);  }
      		
     		//make sure order items that match the subscriptions are updated to match the subscriptions
     		MatchOItoSubscriptions(lstorditem, mpsubitems);

      	}
      	else
      	{
      		lstnewitems = CreateNewOrderItems();
      		Map<Id,Id> mpoitosub = New Map<Id,Id>(); //map of subscription id to order id
      		List<Order_Item__c> lstiteminfo = New List<Order_Item__c>();
      		
      		if(lstnewitems.size() > 0)
                { 
                	system.debug('inserting order items');
                	try{insert lstnewitems;}
                	catch(Exception exc)
                	{  system.debug('Error inserting lstorderitems : ' +exc.getmessage()); }  
                
                }
               
                system.debug('listnewitems size is ' +lstnewitems.size());
                
                //must query some subscription info related to the new order items so create a set
                Set<Id> setoiids = New Set<Id>();
                
                if(lstnewitems.size() > 0)
                {
                	for(Order_Item__c item :lstnewitems)
                	{  setoiids.add(item.id);  }
                }
                
                //need to query for the parent id of the related subscription record
                if(!setoiids.IsEmpty())
                {
                	
                	lstiteminfo = [ Select Id, subscription__c, subscription__r.parent__c, name, subscription__r.equipment_ownership__c, parent__c,
                	                subscription__r.project_type__c, project_type__c, equipment_ownership__c from Order_Item__c where
                                    id in :setoiids ];
                }	
                
                
                if(lstiteminfo.size() > 0 )
                {   
                	
                	for(Order_Item__c o : lstiteminfo)
                	{	mpoitosub.put(o.subscription__c,o.id); 
                		//system.debug('added to mpoitosub ' +o.subscription__c +', ' +o.id);
                	}
                		
                   
                    
                    system.debug('mpoitosub.size is ' +mpoitosub.size());
                
                	for(Order_Item__c oi : lstiteminfo)
                	{
                		//system.debug('order item related subscription is ' +oi.subscription__c);
         
                		if(mpoitosub.containskey(oi.subscription__r.parent__c) && !oi.name.contains('Product Parent'))
                		{
                   				Id parentid = mpoitosub.get(oi.subscription__r.parent__c);
                				system.debug('parentid is ' +parentid);
                				oi.parent__c = parentid;
                		}
                		
                		oi.project_type__c = oi.subscription__r.project_type__c;
                		oi.equipment_ownership__c = oi.subscription__r.equipment_ownership__c;
                		
                		lstparenteditems.add(oi);
                		    
                		
                		    
                	}//end forloop lstiteminfo
                }//end if lstiteminfo
                	
                	system.debug('lstparenteditems size is ' +lstparenteditems);
                	
                	if(lstparenteditems.size() > 0)
                	{  update lstparenteditems; }
       
      		
      }//end else
      
      system.debug('**********END FINDANDUPDATEORDERITEMS*************');
      
  } //end method
      
      public static list<Order_Item__c> AddOrderItems(Map<Id, Order_Item__c> mpsubtooi, Map<Id, SBQQ__Subscription__c> mpaddsubs, Id addoid)
      {
      		system.debug('************BEGIN ADD ORDER ITEMS**************');
      	
      		List<Order_Item__c> lstnewoi = New List<Order_Item__c>();
      		List<SBQQ__Subscription__c> lstnewsub = New List<SBQQ__Subscription__c>();
       		List<SBQQ__Subscription__c> lstneedassets = new List<SBQQ__Subscription__c>();
 
      		
      		for(Id subid : mpaddsubs.keyset())
      		{
      			if(!mpsubtooi.containskey(subid))
      			{
      				//shawks - CPQ 201810: Update how variables are created
      				//SBQQ__Subscription__c newsub;
      				//Order_Item__c neworderitem;
      				SBQQ__Subscription__c newsub = new SBQQ__Subscription__c();
                    Order_Item__c neworderitem = new Order_Item__c();
      				newsub = mpaddsubs.get(subid);
      				neworderitem.subscription__c = newsub.id;
      				neworderitem.name = newsub.name__c;
      				neworderitem.status__c = newsub.status__c;
      				neworderitem.project_type__c = newsub.project_type__c;
      				neworderitem.equipment_ownership__c = newsub.equipment_ownership__c;
      				neworderitem.account__c = newsub.sbqq__account__c;
      				neworderitem.product_code__c = newsub.sbqq__product__r.productcode;
      				if(newsub.product_inventory__c != null)
      				{	neworderitem.asset__c = newsub.product_inventory__c; }
      				else
      				{   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
      					                      'All Subscription items must be linked to product inventory before updating an order.', '')); 
                        return null;
                    }
      				neworderitem.product__c = newsub.sbqq__product__c;
      				neworderitem.price_USD__c = newsub.sbqq__regularprice__c;
      				neworderitem.unit_selling_price_USD__c = newsub.sbqq__regularprice__c;
      				neworderitem.order__c = addoid;
       				neworderitem.total_rooms_ordered__c = newsub.sbqq__quantity__c;
      				neworderitem.total_remaining_rooms__c = newsub.sbqq__quantity__c;
      				
      				lstnewoi.add(neworderitem);
      	     				
      			} //end if setorderitemsubid doesn't contain the sub id
      			
     		}//end for loop mpaddsubs.keyset
  
      		if(lstnewoi.size() > 0)
      		{
      		   	 try {insert lstnewoi;}
      			 catch(Exception e)
      			 {
      			 	system.debug('Error in AddOrderItems:  ' +e.getmessage());
      			 	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
      				                    'Error in AddOrderItems:  ' +e.getmessage())); 
      			 }
         		    
            }
            
            //Now that the new order items are created, they must be parented.
            List<Order_Item__c> lstupdoi = New List<Order_Item__c>();
            Set<Id> setoiid = New Set<Id>();
            List<Order_Item__c> lstoitosub = New List<Order_Item__c>();
            List<Order_Item__c> lstupdateoi = New List<Order_Item__c>();
            Map<Id,Id>mpnewoi = New Map<Id,Id>();
            for(Order_Item__c o :lstnewoi)
            {
            	mpnewoi.put(o.subscription__c, o.id);
            	setoiid.add(o.id);
            }
            
            if(!setoiid.isEmpty())
            {
            	lstoitosub = [ select Id, name, subscription__c, subscription__r.parent__c, subscription__r.equipment_ownership__c,
                           subscription__r.project_type__c, parent__c from Order_Item__c where id in :setoiid ];
                           
                           
                if(lstoitosub.size() > 0)
                {
                	for(Order_Item__c oi :lstoitosub)
                	{
                		if(!oi.name.contains('Product Parent') && mpnewoi.containskey(oi.subscription__r.parent__c))
                		{
                			Id oiparentid = mpnewoi.get(oi.subscription__c);
                			oi.parent__c = oiparentid;
                		}

                	}//end for look lstoitosub
                }//end if lstoitosub > 0
                
                           
            }//end if setoiid is not empty
 
            if(lstupdoi.size() > 0)
            {   update lstupdoi;  }
            
              
              system.debug('*************END ADD ORDER ITEMS**************');
              
         return lstnewoi;
      }//end add order items
      
      //When Finalize Order is clicked with an order id passed in, update all the existing order items to
      //match certain values on the matching subscription record
      public static void MatchOItoSubscriptions(List<Order_Item__c> lstoi, Map<Id, SBQQ__Subscription__c> mpsubs)
      {
      			List<Order_Item__c> lstupdateoi = New List<Order_Item__c>();
      			
      	for(Order_Item__c oi : lstoi)
      	{
      		if(mpsubs.containskey(oi.subscription__c))
      		{
      			SBQQ__Subscription__c sub = mpsubs.get(oi.subscription__c);
              	oi.Product__c=sub.sbqq__product__c;
            	oi.Name=sub.Name__c;
             	oi.Total_Remaining_Rooms__c=sub.sbqq__quantity__c;
            	oi.Total_Rooms_Ordered__c=sub.sbqq__quantity__c;
            	oi.Unit_Selling_Price__c=sub.sbqq__regularprice__c;
            	oi.Status__c=sub.Status__c;
            	oi.Asset__c = sub.product_inventory__c;
            	oi.Contract_Type__c = sub.contract_type__c;
            	oi.Product_Code__c = sub.sbqq__product__r.productcode;
      				
      		    lstupdateoi.add(oi);
      		}
      	}
      	
      	if(lstupdateoi.size() > 0)
      	{
      		try{  update lstupdateoi;  }
      		catch(Exception x)
      		{  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
      					                      'Error in MatchOItoSubscriptions:  ' +x.getmessage())); }
      	}
      	
    
      }    //end MatchOItoSubscriptions
}