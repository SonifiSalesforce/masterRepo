public without sharing class WorkOrderTriggerLogicUpdate {
	@future
	public static void productActivationUpdates(String asUpdateString, String oiUpdateString, String paUpdateString, String aiUpdateString)
	{
        Utilities.writeLog('Entering Method',WorkOrderTriggerLogicUpdate.class,'productActivationUpdates',LoggingLevel.DEBUG);        
		
        Utilities.writeLog('Serialized Assets '+asUpdateString,WorkOrderTriggerLogicUpdate.class,'productActivationUpdates',LoggingLevel.DEBUG);        
        Utilities.writeLog('Serialized Order Items '+oiUpdateString,WorkOrderTriggerLogicUpdate.class,'productActivationUpdates',LoggingLevel.DEBUG);        
        Utilities.writeLog('Serialized Product Activations '+paUpdateString,WorkOrderTriggerLogicUpdate.class,'productActivationUpdates',LoggingLevel.DEBUG);        
        Utilities.writeLog('Serialized Associated Item Activations '+aiUpdateString,WorkOrderTriggerLogicUpdate.class,'productActivationUpdates',LoggingLevel.DEBUG);        


		List<Asset> assetUpdate = (List<Asset>)JSON.deserialize(asUpdateString,List<Asset>.class);
		List<Order_Item__c> oiUpdate = (List<Order_Item__c>)JSON.deserialize(oiUpdateString,List<Order_Item__c>.class);
		List<Product_Activation__c> paUpdate = (List<Product_Activation__c>)JSON.deserialize(paUpdateString,List<Product_Activation__c>.class);
		List<Associated_Item__c> aiUpdate = (List<Associated_Item__c>)JSON.deserialize(aiUpdateString,List<Associated_Item__c>.class);

        Utilities.writeLog('Deserialized Assets '+assetUpdate,WorkOrderTriggerLogicUpdate.class,'productActivationUpdates',LoggingLevel.DEBUG);        
        Utilities.writeLog('Deserialized Order Items '+oiUpdate,WorkOrderTriggerLogicUpdate.class,'productActivationUpdates',LoggingLevel.DEBUG);        
        Utilities.writeLog('Deserialized Product Activations '+paUpdate,WorkOrderTriggerLogicUpdate.class,'productActivationUpdates',LoggingLevel.DEBUG);        
        Utilities.writeLog('Deserialized Associated Items '+aiUpdate,WorkOrderTriggerLogicUpdate.class,'productActivationUpdates',LoggingLevel.DEBUG);        
		
		try{
			update aiUpdate;
			update assetUpdate;
			update oiUpdate;
			insert paUpdate;
		}
		catch(Exception e)
		{
			system.debug('Failure in WorkOrderTriggerUpdate update '+e.getMessage());
		}
        Utilities.writeLog('Exiting Method',WorkOrderTriggerLogicUpdate.class,'productActivationUpdates',LoggingLevel.DEBUG);        
	}
}