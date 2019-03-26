public with sharing class PriceBookSelectorExtension {
	public Account acc {get;set;}
	private List<PricebookEntry> priceBookEntry {get;set;}
	private String pricebookName {get;set;}
	public Id pricebookId {get;set;}
	public List<SelectOption> pricebookList {get;set;}
	private String id {get;set;}
	private Map<String, Pricebook2> id2Pricebook {get;set;}
	public Map<Id, CustomPrice> id2Custom {get;set;}
	public class CustomPrice {
		public Id									priceId									{ get; set; }
		public String 								name									{ get; set; }
	}
	
	public List<Id> priceList {get;set;}
	public Boolean shouldRedirect {get;set;}
	public String redirectUrl {get;set;}
	
	public PriceBookSelectorExtension(ApexPages.StandardController stdController){
		this.acc = (Account)stdController.getRecord();
		this.pricebookList = new List<SelectOption>();
		this.priceBookEntry = new List<PricebookEntry>();
		this.pricebookId = null;
		this.pricebookName = '';
		this.id2Pricebook = new Map<String, Pricebook2>();
		this.priceList = new List<Id>();
		this.id2Custom = new Map<Id, CustomPrice>();
		this.shouldRedirect = false;
		
		//get the id of the site survey if passed through parameters
    	if(System.currentPageReference().getParameters().containsKey('Id')) {
    		this.id= System.currentPageReference().getParameters().get('Id');
    		loadAccount();
    		loadPricebooks();
    	}
	}
	
	
	public void selectPrice(){
		//set the fields
		System.debug('Pricebook id is ' + this.pricebookId);
		
		
		//get all the parameters 
    	Map<String, String> params = ApexPages.currentPage().getParameters();
    	System.debug('Params ' + params);
		
		//get the parameters and set their values
    	if(params.containsKey('priceId')){
    		this.pricebookId = params.get('priceId') != ''? params.get('priceId'): null;
    	}
    	
		this.acc.Pricebook_Id__c = this.pricebookId;
		if(this.pricebookId != null){
			this.acc.Pricebook_Name__c = this.id2Pricebook.get(this.pricebookId).Name;
			this.shouldRedirect = true;
			this.redirectUrl = '/' + this.acc.Id;
		} else {
			this.acc.Pricebook_Name__c = '';
		}
		
		System.debug('Account is ' + this.acc);
		
		//update account
		update acc;
	}
	
	/***********************************************************************************************************
	***************************************** LOAD FUNCTIONS ****************************************************
	***********************************************************************************************************/
	
	public void loadPricebooks() {
		String fieldQuery;
		
		//get fields on Product
		fieldQuery = String.join(getSObjectFields(PricebookEntry.getSObjectType()), ',');
		
		//query for pricebookentries that are family of labor task
		this.priceBookEntry = Database.query('SELECT ' + fieldQuery + ', Pricebook2.Name FROM PricebookEntry WHERE Product2.Family = \'Labor Task\''); //HC Yr 1 on Recurring   Labor Task
		
		//make a set of the Pricebooks
		Set<Pricebook2> priceBookSet = new Set<Pricebook2>();
		Pricebook2 book = new Pricebook2();
		for(PricebookEntry entry : this.priceBookEntry){
			
			book = new Pricebook2(Id = entry.Pricebook2Id, Name = entry.Pricebook2.Name);
			pricebookSet.add(book);
		}
		
		for(Pricebook2 p : priceBookSet){
			//create the custom price
			CustomPrice custom = new CustomPrice();
			
			//set values
			custom.priceId = p.id;
			custom.name = p.Name;
			
			//map the custom to id
			this.id2Custom.put(custom.priceId, custom);
			
			//this.pricebookList.add(new SelectOption(p.Id, p.Name));
			this.id2Pricebook.put(p.Id, p);
			
			this.priceList.add(custom.priceId);
		}
		System.debug('Pricebook set is ' + this.pricebookList);
	}
	
	public void loadAccount() {
		String fieldQuery;
		
		//get fields on Product
		fieldQuery = String.join(getSObjectFields(Account.getSObjectType()), ',');
		
		//get the account
		List<Account> accList = new List<Account>();
		accList = Database.query('SELECT ' + fieldQuery + ' FROM Account WHERE Id = \'' + this.id + '\' limit 1');
		
		//set the account
		if(accList.size() > 0){
			this.acc = accList[0];
			
			if(this.acc.Pricebook_Name__c != null && this.acc.Pricebook_Name__c != ''){
				this.pricebookId = this.acc.Pricebook_Id__c;
			}
		} 
		
	}
	
	
	/***********************************************************************************************************
	***************************************** HELPER FUNCTIONS ****************************************************
	***********************************************************************************************************/
    
      /* Returns all fields in an SObject */ 
	  public static List<String> getSObjectFields(Schema.SObjectType objectType) {
	    
	    // Check for object type 
	    if (objectType == null) { return null; }
	    
	    // Get field map
	    Map<String, SObjectField> fieldMap = objectType.getDescribe().fields.getMap();	      
	   
	    List<String> fieldList = new List<String>();
	    for (String f : fieldMap.keySet()) {
	    	if(f != 'geolocation__c'){
		       // DescribeFieldResult field = fieldMap.get(f).getDescribe();
		     	fieldList.add(f);
	    	}
	    }
	    
	    //return the list of fields
	    return fieldList;
	  }
}