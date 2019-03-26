public with sharing class OrderItemTriggerLogic {

public static void OrderItemEmailNotification(List<Order_Item__c> oiList, Map<Id, Order_Item__c> oldItems)
	{
		Utilities.writeLog('Entered OrderItemEmailUpdate....'+oiList.size(), OrderItemTriggerLogic.class, 'OrderItemEmailNotification', LoggingLevel.DEBUG);
		Set<Id> OrderIds = new Set<Id>();
		Set<Id> WorkOrderIds = new Set<Id>();
		Set<Id> oiIds = new Set<Id>();
		Set<Id> mgrIds = new Set<Id>();
		String bodytxt = '';
		Map<Id, String> ordermsg = new Map<Id, String>();
		
		List<String> actstatus = new List<String> {'Pending Installation Activate','Pending Installation Deactivate','Pending De-Installation','In Development','Cancelled'};
		List<String> orderstatus = new List<String> {'Order Approved','Approved to Build','Approved to Ship & Install'};
		
		for(Order_Item__c oi : oiList)
		{
			oiIds.add(oi.Id);
			OrderIds.add(oi.Order__c);
		}
		// First gather the objects that are part of the information which is to be sent.
		oiList = [SELECT Id, Name, Status__c, Total_Rooms_Ordered__c, Order__c, Platform__c, orderlink__c, Order__r.Name from Order_Item__c WHERE Id IN :oiIds and Status__c IN :actstatus];
		// Get the Status of the order 
		Map<Id,Order__c> ordList = new Map<Id,Order__c>([SELECT Id, Name, Order_Number__c, Site__c, Site__r.Physical_City__c, Site__r.Physical_State__c, Status__c from Order__c WHERE Id IN :OrderIds and Status__c in :orderstatus]);
		Id sOrderId;
		// Locate which fields have changed and build a list of changed items.
		for (Order_Item__c Item : oiList)
		{
			
			String message = '';
			if (ordList.containsKey(Item.Order__c))
			{ 
				if (oldItems == null || Item.Name != oldItems.get(Item.id).Name)
				{
					if(oldItems != null)
			        	message += '&nbsp&nbspNew Name: '+Item.Name+'&nbsp&nbsp&nbsp&nbspOld Name: ' + oldItems.get(Item.id).Name+'<br/>';
		        	else
		        		message +='&nbsp&nbspAdded Item Name: '+Item.Name+'<br/>';
				}
				if (oldItems == null || Item.Status__c != oldItems.get(Item.id).Status__c)
				{
					if(oldItems != null)
						message += '&nbsp&nbspUpdated Status: '+Item.Status__c+'&nbsp&nbsp&nbsp&nbspPrevious Status: ' + oldItems.get(Item.id).Status__c+'<br/>';
					else
						message += '&nbsp&nbspAdded Item Status: '+Item.Status__c+'<br/>'; 
				}
				if (oldItems == null || Item.Total_Rooms_Ordered__c != oldItems.get(Item.id).Total_Rooms_Ordered__c)
				{
					if(oldItems != null)
						message += '&nbsp&nbspUpdated Total Rooms Ordered: '+Item.Total_Rooms_Ordered__c+'&nbsp&nbsp&nbsp&nbspPrevious Total Rooms Ordered: ' + oldItems.get(Item.id).Total_Rooms_Ordered__c+'<br/>';
					else
						message += '&nbsp&nbspAdded Item Total Rooms Ordered: '+Item.Total_Rooms_Ordered__c +'<br/>';
				}
				if (oldItems == null || Item.Platform__c != oldItems.get(Item.id).Platform__c)
				{
  					if(oldItems != null)
						message += '&nbsp&nbspUpdated Platform: '+Item.Platform__c+'&nbsp&nbsp&nbsp&nbspPrevious Platform: ' + oldItems.get(Item.id).Platform__c+'<br/>';
					else
					   if (Item.Platform__c != null) {
					   	  message += '&nbsp&nbspAdded Item Platform: '+Item.Platform__c+'<br/>';
					   }
				}
				
				if (message.length() > 0)
				{
					// have to add account and Order Information to the front of the message
					if (sOrderId != Item.Order__c){
					    message = 'Order Number: ' + ordList.get(Item.Order__c).Order_Number__c+'<br/>'
					    +'Site: ' + ordList.get(Item.Order__c).Name 
					    +'<br/> City: '+ordList.get(Item.Order__c).Site__r.Physical_City__c 
					    +'<br/> State: '+ordList.get(Item.Order__c).Site__r.Physical_State__c 
					    + '<br/><br/> Order Item: ' + Item.Name + '<br/>'+message;
					    sOrderId = Item.Order__c;
					} else {
						message = '<br/><br/> Order Item: ' + Item.Name + '<br/>'+message;
					}
					
					message += '<br/><br/><br/><br/>Link to Order:  '+'<br/>';
					message += Item.orderlink__c;
					

						
					bodytxt += message;
					system.debug('Message list for ID '+Item.id);
					system.debug(LoggingLevel.ERROR, 'Message being sent' +message);
					ordermsg.put(Item.id, message);
				}
			}
		}
		
		
		if (ordermsg.size()> 0)
		{
			Map<Id,List<String>> userMessageMap = new Map<Id,List<String>>();
            
            // Add the User id from the Group
			Group g = [SELECT (select userOrGroupId from groupMembers) FROM group WHERE name = 'Order Change Notification']; 
			for (GroupMember gm : g.groupMembers) { 
   				System.debug('Group Members === ' +gm.userOrGroupId);
						 addToEmailList(userMessageMap, gm.userOrGroupId,  bodytxt);
			} 		
			Utilities.writeLog('Entered OrderItemEmailUpdate.... Group Post Emails '+userMessageMap, OrderItemTriggerLogic.class, 'OrderItemEmailNotification', LoggingLevel.DEBUG);

	
			// Only send emails if changes where found
			Map<Id,Set<Id>> orderItemToWorkOrders = new Map<Id,Set<Id>>();
			
			for(Associated_Item__c ai : [SELECT Work_Order__c, Order_Item__c from Associated_Item__c WHERE Order_Item__c IN :ordermsg.keyset()])
			{
				if(orderItemToWorkOrders.containsKey(ai.Order_Item__c))
				{
					orderItemToWorkOrders.get(ai.Order_Item__c).add(ai.Work_Order__c);
				}
				else
				{
					Set<Id> temp = new Set<Id>();
					temp.add(ai.Work_Order__c);
					orderItemToWorkOrders.put(ai.Order_Item__c,temp);
				}
				WorkOrderIds.add(ai.Work_Order__c);	
			}
	    	Map<Id,Work_Order__c> woList = new Map<Id,Work_Order__c>([SELECT Id, Install_Manager__c from Work_Order__c WHERE Id IN :workOrderIds]);
			Set<Id> notificationMembers = new Set<Id>();
			if (orderItemToWorkOrders.size() > 0) 
			{
				for (Id oimsg : ordermsg.keyset())
		    	{

			    	for (Id woId : orderItemToWorkOrders.get(oimsg))
			    	{
			    		Work_Order__c mgr = woList.get(woId);
						if (mgr.Install_Manager__c != null)
						{
							notificationMembers.add(mgr.Install_Manager__c);
							System.debug('Work Order === ' +mgr.Install_Manager__c+ ' id '+mgr.Id);
						}	
		    		}

					system.debug('notification list '+notificationMembers);
					for(Id uId : notificationMembers)
					{
						addToEmailList(userMessageMap, uId,  ordermsg.get(oimsg));
					}
		    	}
			}
			// Now email the notices
			EmailUtilities.doEmailPosts(userMessageMap);
			Utilities.writeLog('Entered OrderItemEmailUpdate.... Post Emails '+userMessageMap, OrderItemTriggerLogic.class, 'OrderItemEmailNotification', LoggingLevel.DEBUG);
			Utilities.writeLog('Entered OrderItemEmailUpdate.... Email messages sent '+ordermsg.size(), OrderItemTriggerLogic.class, 'OrderItemEmailNotification', LoggingLevel.DEBUG);
		    
		}
		
		
	}
	

	private static Map<Id,List<String>> addToEmailList(Map<Id,List<String>> userMessageMap, Id userId, String message)
	{
		if(userMessageMap.containsKey(userId))
		{
			userMessageMap.get(userId).add(message);
		}
		else
		{
			List<String> tempList = new List<String>();
			tempList.add(message);
			userMessageMap.put(userId,tempList);
		}
		return userMessageMap;
	}	

	public static void rollUpChannelSummary(List<Order_Item__c> oliList)
	{
        System.debug(LoggingLevel.DEBUG,'rollupChannelSummary start');
		Set<String> parentoliIds = new Set<String>();
		for(Order_Item__c oli : oliList)
		{
			if(oli.Product_Parent_Id__c != null)
			{
				parentoliIds.add(oli.Product_Parent_Id__c);		
			}
		}
		system.debug(LoggingLevel.ERROR, 'Order Item List coming in'+oliList);
		List<Order_Item__c> childolis = [SELECT Id, Product_Parent_Id__c,Product__r.Channel_Type__c from Order_Item__c 
		WHERE Product_Parent_Id__c IN :parentoliIds
		AND Product_Parent_Family__c = 'FTG'
		AND (Status__c = 'Installed Activated' OR Status__c = 'Billing' OR Status__c = 'Pending De-Installation' OR Status__c = 'Pending Installation Activate')];
		
		//Create map of parent oli id to list of child olis
		
		Map<Id,List<Order_Item__c>> parentoliMap = new Map<Id,List<Order_Item__c>>();
		for(Order_Item__c oli : childolis)
		{
			if(parentoliMap.containsKey(oli.Product_Parent_Id__c))
			{
				parentoliMap.get(oli.Product_Parent_Id__c).add(oli);
			}
			else
			{
				List<Order_Item__c> temp = new List<Order_Item__c>();
				temp.add(oli);
				parentoliMap.put(oli.Product_Parent_Id__c,temp);
			}
		}
		system.debug(LoggingLevel.ERROR, 'parentIds'+parentOliMap.keyset());
		//Loop through list of olis
		List<Order_Item__c> parentoliList = new List<Order_Item__c>();
		for(Id parentoliId : parentoliMap.keyset())
		{
			Integer HD = 0;
			Integer SD = 0;
			Integer Analog = 0;
			for(Order_Item__c oli : parentoliMap.get(parentoliId))
			{
				if(oli.Product__r.Channel_Type__c == 'HD')
					HD ++;
				else if(oli.Product__r.Channel_Type__c == 'SD')
					SD ++;
				else if(oli.Product__r.Channel_Type__c == 'Analog')	
					Analog++;
			}
			Order_Item__c temp = new Order_Item__c(Id = parentoliId);
			temp.HD_Channel_Count__c = HD;
			temp.SD_Channel_Count__c = SD;
			temp.Analog_Channel_Count__c = Analog;
			parentoliList.add(temp);
		}
		system.debug(LoggingLevel.ERROR,parentOliList);
		update parentoliList;
        System.debug(LoggingLevel.DEBUG,'rollupChannelSummary end');
	}


}