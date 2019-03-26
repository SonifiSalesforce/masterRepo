public class ThirdPartyFieldService {
    
    public Account acct {get; private set;}
	public List<Account> acclist {get;set;}
	public String searchname {get;set;}
	public String searchcity {get;set;}
	public String searchstate {get;set;}
	public String searchadd {get;set;}
	public String accname {get;set;}
    public String tppuniqueid {get;set;}
    public SelectOption thirdpartyname {get;set;}
	public Id acctid;
    public List<SelectOption> partneroptions {get;set;}
    public string tpname {get;set;}

 	
	public class cAccount //jjackson--wrapper class for creating list of selected accounts from the visual force page 
	{

		public Account acc {get;set;}
		public Boolean selected {get;set;}

        
		public cAccount(Account a)
		{
			acc = a;
   			selected = false;
            acc.id = a.id;
            acc.name = a.name;
            acc.physical_street_address_line_1__c = a.physical_street_address_line_1__c;
			acc.physical_city__c = a.physical_city__c;
			acc.physical_state__c = a.physical_state__c;
	
		}
   } //end class cAccount
	
	public List<cAccount> lstcheckedaccts {get;set;}

    public List<SelectOption> getpartnernames()
    {
        List<SelectOption> partneroptions = New List<SelectOption>();
        List<Third_Party_Partner_Names__c> cslist = Third_Party_Partner_Names__c.getall().values();
        partneroptions.add(new selectOption('Please Select', '---Please Select---'));
        
        if(test.isRunningTest()) //third_party_partner_names__c is a custom setting so for testing we have to add our own value
        { partneroptions.add(new selectOption('Test Third Party', 'Test Third Party')); }
        else
        {
        	for(Third_Party_Partner_Names__c cs : cslist)
        	{   

            	partneroptions.add(new selectOption(cs.Account_Name__c, cs.Account_Name__c));
        	}
        }

        return partneroptions;
    }
  	
	public List<cAccount> getCheckedAccount(List<Account> accountlist)
	{
		if(lstcheckedaccts == null)
		{
			lstcheckedaccts = New List<cAccount>();
			for(Account ac: accountlist)
			{
				lstcheckedaccts.add(new cAccount(ac));
			}
		}
		
		return lstcheckedaccts;
	}
	

	public void FindRecords()
    {
    	String likename = '%'+searchname+'%';
        String likeadd;

        if(searchadd != null)
        {
            if(searchadd.left(1).IsNumeric()==true)
            { likeadd = searchadd +'%';}
            else
            { likeadd = '%'+searchadd+'%'; }
        }

    	List<Account> getaccounts = New List<Account>();
    	List<Account> acclist = new List<Account>();
        Map<Id,List<Account_Third_Party_Partner__c>> mpaccttpps = new Map<Id,List<Account_Third_Party_Partner__c>>();
    	
        //search by %name% only
        if(getaccounts.IsEmpty())
        {
    	   if(searchname != '' && searchadd == '' && searchcity == '' && searchstate == '')             
		   {
    		 String searchquery1 = 'Select Id, name, physical_street_address_line_1__c, physical_city__c, physical_state__c '
                            +'from Account where name like :likename';
             getaccounts= Database.query(searchquery1);
             system.debug('likename is ' +likename);
             system.debug('getaccounts.size is ' +getaccounts.size());
             if(getaccounts.size() >= 1)
                {acclist = getaccounts; }
 
          }
        }

		if(getaccounts.IsEmpty())
		{
            //search by %name% and city only
			if(searchname != '' && searchadd == '' && searchcity != '' && searchstate == '' )
			{
				string searchquery2 = 'Select Id, Name, physical_street_address_line_1__c, physical_city__c, physical_state__c, ' 
		                   + 'physical_country__c, physical_postal_code__c, phone, time_zone__c, third_party_id__c '
		                   + 'from Account where (Name like :likename AND physical_city__c = :searchcity)';
		                   
		    	getaccounts = Database.query(searchquery2);
		    	if(getaccounts.size() >= 1)
		    	{   acclist = getaccounts;  }
		    }
		}
		
		if(getaccounts.IsEmpty())
		{   
            //search by searchadd only
			if(searchname == '' && searchadd != '' && searchcity == '' && searchstate == '' )
			{
		
		    	string searchquery3 = 'Select Id, Name, physical_street_address_line_1__c, physical_city__c, physical_state__c, '
		                  + 'physical_country__c, physical_postal_code__c, phone, time_zone__c, third_party_id__c '
		                  + 'from Account where physical_street_address_line_1__c like :likeadd';
		                   
		        getaccounts = Database.query(searchquery3);
		        if(getaccounts.size() >= 1)
		        {  acclist = getaccounts;  }
		       
		    }
		}

        if(getaccounts.IsEmpty())
        {   
            //search by address, city, state only
            if(searchname == ''  && searchadd != '' && searchcity != '' && searchstate != '')
            {
        
                string searchquery4 = 'Select Id, Name, physical_street_address_line_1__c, physical_city__c, physical_state__c, '
                          + 'physical_country__c, physical_postal_code__c, phone, time_zone__c, third_party_id__c '
                          + 'from Account where physical_street_address_line_1__c = :likeadd AND physical_city__c = :searchcity '
                          + 'AND physical_state__c = :searchstate';
                           
                getaccounts = Database.query(searchquery4);
                if(getaccounts.size() >= 1)
                {  acclist = getaccounts;  }
               
            }
        }
		
		if(getaccounts.IsEmpty())
		{
            //search by city and state only
			if(searchname == '' && searchadd == '' && searchcity != '' && searchstate != '')
			{
		
		    	string searchquery5 = 'Select Id, Name, physical_street_address_line_1__c, physical_city__c, physical_state__c, '
		                  + 'physical_country__c, physical_postal_code__c, phone, time_zone__c, third_party_id__c '
		                  + 'from Account where physical_city__c = :searchcity AND physical_state__c = :searchstate';
		                   
		        getaccounts = Database.query(searchquery5);
		        if(getaccounts.size() >= 1)
		        {  acclist = getaccounts;  }
		       
		    }
		}
		
		//take the query results list (acclist) and pass it into the method that turns it into a list of cAccount, which
		//is an account converted to the wrapper class that adds the checkbox to the account record
		if(getaccounts.size() != 0)
		{
			lstcheckedaccts = getCheckedAccount(acclist);
		}
		
		if(getaccounts.size() == 0)
		{  
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'No matching accounts were found. Click Clear and '
			                                                + 'try again using different search criteria or enter Account information '
			                                                + 'in the form below to create a new one. ');
            ApexPages.addMessage(myMsg);	
		}

    }
    
    public PageReference ClearSearch()
    {
    	searchname = null;
    	searchcity = null;
        searchadd = null;
    	searchstate = null;
    	
    	List<cAccount> emptyacctlist = New List<cAccount>();
    	lstcheckedaccts=emptyacctlist;
    	PageReference pr = ApexPages.currentPage();
    	pr.setRedirect(true);
    	return pr;
    }

    
    public PageReference CreateCase()
    {
    	List<cAccount> lstselected = New List<cAccount>();
       	String Message1 = 'You must select an account from the list before clicking the Create Case button.';
    	String Message2 = 'Please choose only one account and click Create Case again.';
        String Message3 = 'You must select a Third Party Partner from the picklist below in order to create a case.';
    	String redirecturl;
    	Id caseid;
        Id tppid;
        String tppname;

        system.debug('tpname value is ' +tpname);  

        if(tpname == 'Please Select')
        {
           ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Message3);
           ApexPages.addMessage(myMsg);
           return null;
        }
 
    	for(cAccount cac : lstcheckedaccts)
    	{
    		if(cac.selected == true)
    		{
    			lstselected.add(cac);
    		}
    	}



    	
    	if(lstselected.size() == 0)
    	{
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Message1);
           ApexPages.addMessage(myMsg);
            
    	}
    	
    	if(lstselected.size() > 1)
    	{
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Message2);
            ApexPages.addMessage(myMsg);
            
    	}
    	
    	if(lstselected.size() == 1)
    	{
    		for(cAccount cact : lstselected)
    		{
    			acctid = cact.acc.Id;
    		}
    	}
    	
    	if(acctid != null)
    	{


            
            List<Account_Third_Party_Partner__c> lstacctpartner = [Select Id, third_party_partner_account__r.name, related_account__c from
                                                           Account_Third_Party_Partner__c where related_account__c = :acctid AND
                                                           third_party_partner_account__r.name = :tpname LIMIT 1 ];
            if(lstacctpartner.size() == 1)
            {
                for(Account_Third_Party_Partner__c tpp : lstacctpartner)
                {    tppid = tpp.id;  
  
                }
            }
            else
            {
                Account_Third_Party_Partner__c newtpp = CreateThirdPartyPartner(tpname, acctid);
                tppid = newtpp.id;
      
            }

    		Case newcase = New Case();
    		Id recid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
    		newcase.recordtypeid = recid;
    		newcase.accountid = acctid;
            newcase.third_party_partner__c = tppid;
            newcase.related_third_party_partner_name__c = tpname;
    		insert newcase;
    		caseid = newcase.id;
    		system.debug('case id from newcase is ' +caseid);
    		redirecturl  = ('/' +caseid);
    		
  
    	}

		PageReference pr = ApexPages.currentPage();
    	
    	if(caseid != null)
    	{
    	  	pr = New PageReference(redirecturl);
    	  	pr.setRedirect(true);

    	}

    	
    	return pr;  
    	
    
    }
    
    public ThirdPartyFieldService()
	{
		Id id = ApexPages.currentPage().getParameters().get('id');
		acct = (id == null) ? new Account(): [Select Id, name, Physical_Street_Address_Line_1__c, Physical_City__c, Physical_State__c,
		        Physical_Country__c, Physical_Postal_Code__c, phone, Time_Zone__c, site_id__c
		        from Account where Id = :id ];
		
		acct.physical_country__c = 'USA';    
		system.debug('acct name is ' +acct.name);
        partneroptions = getpartnernames();
   
	}
    
    public PageReference CreateNewAccount()
    {
    	system.debug('CreateNewAccount acct name is ' +acct.name);

        String tpid;

        if(tppuniqueid != null || tppuniqueid != '')
        { tpid = tppuniqueid; }

        if(accname == null || accname == '')
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'You must enter a name for the new account.');
            ApexPages.addMessage(myMsg);                                               
            return null;
        }

        Account_Third_Party_Partner__c newtpp = New Account_Third_Party_Partner__c();
        Account partneraccount = New Account();

        if(tpname == 'Please Select')
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select a Third Party Partner to create an account.');
            ApexPages.addMessage(myMsg);                                               
            return null;
        }

    	
    	Id rectypeid = Utilities.RecordTypeNameToId('Account', 'Third Party Contracted Service');
    	
    	if(rectypeid != null)
    	{
    		acct.recordtypeid = rectypeid;
    	}

        //put the form info into the new account record

        acct.name = accname;
        insert acct;

        newtpp = CreateThirdPartyPartner(tpname, acct.id, tpid);
      	
    	PageReference acctPage = New PageReference( '/' +acct.id);
    	   	   	
    	//empty acct so it will clear the entries in the vf page
    	acct = null;
    	
    	acctPage.setRedirect(true);
    	
    	return acctPage;
    }

    //this version of the method is called by CreateAccount where the user can enter a third party id
    public static Account_Third_Party_Partner__c CreateThirdPartyPartner(String acctname, Id accountid, 
                                                                        String thirdpartyid)
    {
         
         Account_Third_Party_Partner__c accttpp = New Account_Third_Party_Partner__c();
         List<Account> lstaccount = [ Select Id, Name from Account where name = :acctname LIMIT 1 ];
         Id acctid;
         for(Account a : lstaccount)
         {  acctid = a.id; }
         accttpp.related_account__c = accountid;
         accttpp.third_party_partner_account__c = acctid;

         if(thirdpartyid != null)
         { accttpp.third_party_unique_id__c = thirdpartyid; }

         insert accttpp;

         return accttpp;
    }

    //need a second method with different signature because when this method is called within Create Case,
    //there will be no third party id to pass in
    public static Account_Third_Party_Partner__c CreateThirdPartyPartner(String acctname, Id accountid)
    {
         
         Account_Third_Party_Partner__c accttpp = New Account_Third_Party_Partner__c();
         List<Account> lstaccount = [ Select Id, Name from Account where name = :acctname LIMIT 1 ];
         Id acctid;
         for(Account a : lstaccount)
         {  acctid = a.id; }
         accttpp.related_account__c = accountid;
         accttpp.third_party_partner_account__c = acctid;

         insert accttpp;

         return accttpp;
    }

   

}