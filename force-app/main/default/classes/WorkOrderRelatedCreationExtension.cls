public with sharing class WorkOrderRelatedCreationExtension 
{
	public Work_Order__c wo{get;set;}
	public Boolean hasCircuit{get;set;}
	public Boolean hasCustomization{get;set;}
	public Boolean shouldRedirect{get;set;}
	public List<RecordTypeSelect> WorkOrderTypes{get;set;}
	public class RecordTypeSelect
	{
		public String name{get;set;}
		public Id key{get;set;}
		public Boolean checked{get;set;}
		public recordTypeSelect(String n, Id i)
		{
			this.name = n;
			this.key = i;
			this.checked = false;
		}		
	}
	public WorkOrderRelatedCreationExtension(ApexPages.StandardSetController  controller)
	{
    	Map<String, String> params = ApexPages.currentPage().getParameters();
    	Id workOrderId = params.get('Id');
		wo = [SELECT Id, Site__c from  Work_Order__c WHERE Id = :workOrderId][0];
		system.debug('Parent Work Order: '+wo);
		hasCircuit = false;
		hasCustomization = false;
		getWorkOrderRecordTypes();
		
		//Query associated tiems of work order
		List<Associated_Item__c> masterList = [SELECT Order_Item__r.Product__r.Circuit__c, Order_Item__r.Product__r.Customization_Needed__c from Associated_Item__c WHERE Work_Order__c = :wo.Id];
		
		//Setting circuit and cusotmization flags
		for(Associated_Item__c ai : masterList)
		{
			if(ai.Order_Item__r.Product__r.Circuit__c == true)
				hasCircuit = true;
			else if(ai.Order_Item__r.Product__r.Customization_Needed__c == true)
				hasCustomization = true;
		}
		if(hasCircuit == false)
		{
				    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING,'No Circuit Line Items are found.  Press save to create anyway',''));
		}
		if(hasCustomization == false)
		{
				    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING,'No Customization Line Items are found.  Press save again to create anyway',''));			
		}
		
		
	}

	public void getWorkOrderRecordTypes()
	{
		List<RecordTypeSelect> options = new List<RecordTypeSelect>();
		List<ChildWorkOrderRecordTypes__c> cw = [SELECT name from ChildWorkOrderRecordTypes__c];
		List<String> childRecordTypeNames = new List<String>();
		for(ChildWorkOrderRecordTypes__c c : cw)
		{
			childRecordTypeNames.add(c.Name);
		}
		for(String childRecordTypeName : childRecordTypeNames)
		{
			options.add(new RecordTypeSelect(childRecordTypeName, Utilities.RecordTypeNameToId('Work_Order__c', childRecordTypeName)));
		}
		this.WorkOrderTypes = options;
	}
	
	public PageReference saveRelatedWorkOrders()
	{
		//Assume list of RecordTypeIds
        List<Id> recordTypes = new List<Id>();
        for(RecordTypeSelect s : WorkOrderTypes)
        {
        	if(s.checked == true)
        		recordTypes.add(s.key);
        }
        system.debug(Logginglevel.ERROR,'The record type ids are' + recordTypes);
		
		List<Work_Order__c> relatedWorkOrders = new List<Work_Order__c>();
		for(Id recordType : recordTypes)
		{
			Work_Order__c relatedTemp = new Work_Order__c();
			relatedTemp.OwnerId = UserInfo.getUserId();
			relatedTemp.Parent_Work_Order__c = wo.Id;
			relatedTemp.recordTypeId = recordType;
			relatedTemp.Site__c = wo.Site__c;
			relatedWorkOrders.add(relatedTemp);
		}
		
		//Insert new Work ORders
		Savepoint sp = Database.setSavepoint();
		try
		{
			insert relatedWorkOrders;
		}
		catch(Exception e)
		{
		    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Error inserting new Work Orders : '+e.getMessage()));
			system.debug(Logginglevel.ERROR,'Error inserting new Work Orders : '+e.getMessage());
			return null;
		}
		return new PageReference('/'+wo.Id);
	}
	
	public PageReference cancel()
	{
		PageReference pr = new PageReference('/'+wo.Id);
		return pr;
	}
}