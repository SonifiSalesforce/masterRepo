@isTest
public class ThirdPartyFieldServiceTest {


    public static testMethod void testThirdPartyFieldServiceController()
    {

     	Account a = existingaccount();
     	Account tpacct = partneraccount();
   
     	
     	List<Account> alist = New List<Account>();
     	alist.add(a);
 
 
 	//test the FindRecords method by passing in different search values      	
        ThirdPartyFieldService con = new ThirdPartyFieldService();
        con.searchname = 'Test Hotel';
        con.searchadd = '';
        con.searchcity = '';
        con.searchstate = '';
      	con.FindRecords();
     	con.ClearSearch();
     	
     	con.searchname = 'Test Hotel';
     	con.searchcity = 'Los Angeles';
     	con.searchadd = '';
     	con.searchstate = '';
     	con.FindRecords();
     	con.ClearSearch();
     	
     	con.searchname = '';
     	con.searchadd = '100 Testing';
     	con.searchcity = '';
     	con.searchstate = '';
     	con.FindRecords();
     	con.ClearSearch();
     	
  		con.searchname = '';
  		con.searchadd = '';
  		con.searchcity = 'Los Angeles';
  		con.searchstate = 'CA';
  		con.FindRecords();
  		con.ClearSearch();
  		
  		con.searchname = '';
  		con.searchadd = '100 Testing';
  		con.searchcity = 'Los Angeles';
  		con.searchstate = 'CA';
  		con.FindRecords();
     	
     	//test the part of the controller that creates the drop-down list for third party partners
     	List<SelectOption> partnernameslist = New List<SelectOption>();
     	partnernameslist = con.getpartnernames();
     	con.partneroptions = partnernameslist;
     	
     	//test the CreateCase method by setting a third party partner name and acctid
     	con.tpname = 'Test Third Party';
     	con.acctid = a.id;
     	con.CreateCase();
     	
     	//test the CreateNewAccount method by setting the third party id and passing account info
     	con.tppuniqueid = tpacct.id;
     	con.accname = 'New Test Hotel';
     	con.CreateNewAccount();
     	
  		
     	
     	
     	
     	
     	
    }
    
    public static testmethod Account existingaccount()
    {
    	Id rectypeid = Utilities.RecordTypeNameToId('Account', 'Third Party Contracted Service');
    	
    	Account a = New Account();
    	//a.site_id__c = 'test1234';
    	a.name = 'Test Hotel';
    	a.physical_street_address_line_1__c = '100 Testing Street';
    	a.physical_city__c = 'Los Angeles';
    	a.physical_state__c = 'CA';
    	a.physical_country__c = 'USA';
    	a.physical_postal_code__c = '33444';
    	a.phone = '777-777-7777';
    	a.recordtypeid = rectypeid;
    	insert a;
    	
    	return a;
    	
    }
    
    public static testmethod Account partneraccount()
    {
    	Id rectypeid = Utilities.RecordTypeNameToId('Account', 'Third Party');
    	Account tpaccount = New Account();
    	
    	tpaccount.recordtypeid = rectypeid;
    	tpaccount.name = 'Test Third Party';
    	tpaccount.physical_street_address_line_1__c = '12345 Test Street';
    	tpaccount.physical_city__c = 'Sioux Falls';
    	tpaccount.physical_state__c = 'SD';
    	tpaccount.physical_country__c = 'USA';
    	tpaccount.physical_postal_code__c = '57104';
    	tpaccount.phone = '605-888-9999';
    	insert tpaccount;
    	
    	return tpaccount;
    }
}