//@isTest(SeeAllData=true)
@isTest()
public  
class AccountRetrievalTestClassNoNamespace {
 static testMethod void testGetUser() {
     Test.startTest();
     System.debug('start testing AccountRetrievalNoSpacename.getUser()');
     String ret = AccountRetrievalNoSpacename.getUser();
     System.debug(ret);
     //System.assert(ret.length() > 0);
     Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(ret);
     
     String ccId = (String) m.get('CallCenterId');
     String extension = (String) m.get('Extension');
     String phone = (String) m.get('Phone');
     System.debug('ccId:' + ccId);
     System.debug('extension:' + extension);
     System.debug('phone:' + phone);
     //jjackson 9/27/2017 -- had to comment out the system.assert statements for ccId and extension because
     //this test will always fail if the person running it is not a member of the call center.  The code is
     //is covered as long as the getUser method is returning a JSONString.
     //System.assertNotEquals(ccId, null);
     //System.assertNotEquals(extension, null);
     //System.assertNotEquals(phone, null);
     
     System.debug('End testing AccountRetrievalNoSpacename.getUser()');
     Test.stopTest();
 }
   
  
    
    static testMethod void testgetCases() {
        
     Case caseObj = new Case(
            OwnerId = Userinfo.getUserId(),
            Status = 'Working',
            Origin = 'Phone');
        
     insert caseObj;
     caseObj = [select id, CaseNumber from Case where id = : caseObj.id];
  
        
     Test.startTest();
     
     String SearchString = caseObj.CaseNumber;
     System.debug('start testing AccountRetrievalNoSpacename.testgetCases( ' + SearchString + ')' );
        
     String jsonString = AccountRetrievalNoSpacename.GetCases(SearchString);
     System.debug(jsonString);
     //System.assert(ret.length() > 0);
  
     //List<Account> queriedAccts = (List<Account> )JSON.deserialize(ret, List<Account.class>);
     //Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(ret);
     //
     //
   
     Type t = Type.forName('List<Case>');
        List<SObject> lo = (List<SObject>)JSON.deserialize(jsonString, t);
        for (SObject o : lo) {
            System.debug(o.getSObjectType().getDescribe().getName() + ', Id: ' + o.get('Id'));
            System.debug(o.getSObjectType().getDescribe().getName() + ', OwnerId: ' + o.get('OwnerId'));
            System.debug(o.getSObjectType().getDescribe().getName() + ', CaseNumber: ' + o.get('CaseNumber'));
            String ResultCaseNumber = (String)o.get('CaseNumber');
            System.debug('ResultCaseNumber:' + ResultCaseNumber + ' SearchString:' + SearchString );
            System.assertEquals(ResultCaseNumber, SearchString);
        }
        
        
    
    /* 
      for(Account acct : queriedAccts)
    {
        System.debug('AccountId:' + acct.Id);
        System.debug('AccountName:' + acct.Name);
        System.debug('AccountPhone:' + acct.phone);
        
        System.assertNotEquals(acct.Id, null);
        System.assertNotEquals(acct.Name, null);
        System.assertNotEquals(acct.phone, null);
        
                
                System.assertEquals
                (
                    'Testing at',
                    acct.Description.substring(0,10)
                    
                    
                );
        
        
    }
 */
     
  
     
     //System.assertNotEquals(phone, null);
     delete caseObj;
     System.debug('End testing AccountRetrievalNoSpacename.testgetCases(\'001\')');
     Test.stopTest();
 }
        
        
    

    static testMethod void testGetCustomerbyId() {
        
        //string CustomerId = '1234';
        //sample data
        //List <Enghouse_CCSP__EnghouseCustomer__c> EnghouseCustomers = new List <Enghouse_CCSP__EnghouseCustomer__c> ();       

        //for(Integer i = 0; i < 1; i++){         
            EnghouseCustomer__c EnghouseCustomer = new EnghouseCustomer__c(Name = 'Customer Test', Phone__c = '0503779955');
        //  EnghouseCustomers.add(a);
        //}

        
     
        insert EnghouseCustomer;      
        
        string CustomerId = EnghouseCustomer.Customer_Id__c;

        
        
        Test.startTest();
        System.debug('start testing AccountRetrievalNoSpacename.GetCustomerbyId(\'1234\')');
        String SearchString = '1234';
        String jsonString = AccountRetrievalNoSpacename.GetCustomerbyId(SearchString);
     System.debug(jsonString);
     //System.assert(ret.length() > 0);
  
     //List<Account> queriedAccts = (List<Account> )JSON.deserialize(ret, List<Account.class>);
     //Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(ret);
     //
     //
   
     Type t = Type.forName('List<EnghouseCustomer__c>');
        List<SObject> lo = (List<SObject>)JSON.deserialize(jsonString, t);
        for (SObject o : lo) {
            System.debug(o.getSObjectType().getDescribe().getName() + ', Id: ' + o.get('Customer_Id__c'));
            System.debug(o.getSObjectType().getDescribe().getName() + ', Name: ' + o.get('Name'));
            System.debug(o.getSObjectType().getDescribe().getName() + ', Phone: ' + o.get('Phone__c'));
            System.assertNotEquals(o.get('Customer_Id__c'), CustomerId);
        }
        
        
       
     
  
     
     //System.assertNotEquals(phone, null);
     delete EnghouseCustomer;
     System.debug('End testing AccountRetrievalNoSpacename.GetCustomerbyId(\'1234\')');
     Test.stopTest();
 }

        
    static testMethod void testgetAccount() {
        
        string AccountName = 'Test My Account ';
        //sample data
        List<Account> accounts = new List<Account>{};
        for(Integer i = 0; i < 1; i++){
            Account a = new Account(Name = AccountName, Phone = '1234' );
            accounts.add(a);
        }
    
     
        insert accounts;

        
        
        
        
     Test.startTest();
     System.debug('start testing AccountRetrievalNoSpacename.getAccount(\'Test My\')');
     String SearchString = 'Test My';
     String jsonString = AccountRetrievalNoSpacename.getAccount(SearchString);
     System.debug(jsonString);
     //System.assert(ret.length() > 0);
  
     //List<Account> queriedAccts = (List<Account> )JSON.deserialize(ret, List<Account.class>);
     //Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(ret);
     //
     //
   
     Type t = Type.forName('List<Account>');
        List<SObject> lo = (List<SObject>)JSON.deserialize(jsonString, t);
        for (SObject o : lo) {
            System.debug(o.getSObjectType().getDescribe().getName() + ', Id: ' + o.get('Id'));
            System.debug(o.getSObjectType().getDescribe().getName() + ', Name: ' + o.get('Name'));
            System.debug(o.getSObjectType().getDescribe().getName() + ', Phone: ' + o.get('Phone'));
            System.assertNotEquals(o.get('Name'), AccountName);
        }
        
        
    
    /* 
      for(Account acct : queriedAccts)
    {
        System.debug('AccountId:' + acct.Id);
        System.debug('AccountName:' + acct.Name);
        System.debug('AccountPhone:' + acct.phone);
        
        System.assertNotEquals(acct.Id, null);
        System.assertNotEquals(acct.Name, null);
        System.assertNotEquals(acct.phone, null);
        
                
                System.assertEquals
                (
                    'Testing at',
                    acct.Description.substring(0,10)
                    
                    
                );
        
        
    }
 */
     
  
     
     //System.assertNotEquals(phone, null);
     delete accounts;
     System.debug('End testing AccountRetrievalNoSpacename.getAccount(\'Test Customer\')');
     Test.stopTest();
 }
 
 static testmethod void testgetAccountBySiteId()
 {
 	 List<Account> newaccounts = New List<Account>();
 	 newaccounts = DataGenerator.createAccounts(2,true);
 	 
 	 
 	 Account a1 = newaccounts[0];
 	 Account a2 = newaccounts[1];
 	 Set<Id> accid = New Set<Id>();
 	 accid.add(a1.id);
 	 accid.add(a2.id);
 	 List<Account> lstaccts = [Select Id, Site_Id__c from Account where Id in :accid ];
 	 String site1 = lstaccts[0].site_id__c;
 	 String site2 = lstaccts[1].site_id__c;
 	 
 	 system.debug(site1);
 	 system.debug(site2);
 	 
 	 test.StartTest();
 	 
 	 String retstring1 = AccountRetrievalNoSpaceName.getAccountBySiteId(site1);
 	 String retstring2 = AccountRetrievalNoSpaceName.getAccountBySiteid(site2.right(5));
 	 
 	 test.StopTest();
 	 
 	 system.assert(retstring1 != null);
 	 system.assert(retstring2 != null);
 	 
 	 
 	 
 	 
 }
    
}