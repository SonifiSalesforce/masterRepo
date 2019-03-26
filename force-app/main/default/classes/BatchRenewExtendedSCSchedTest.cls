@isTest
public with sharing class BatchRenewExtendedSCSchedTest {
   static testmethod void testSchedule()
   {
      Date todayDate = system.today();
	  List<Account> acctlist = new List<Account>();
	  List<Contract> contlist = new List<Contract>();
	  List<SBQQ__Subscription__c> sublist = new List<SBQQ__Subscription__c>();
	  List<ServiceContract> sclist = new List<ServiceContract>();
	  
	  Account acct1 = new Account(Name = 'Test Acc 1');
	  acctlist.add(acct1);
	  Account acct2 = new Account(Name = 'Test Acc 2');
	  acctlist.add(acct2);
	  insert acctlist;
	  
	  Contract cont1 = new Contract(AccountId = acct1.Id, Terminate_Extended_Warranty__c = false);
	  contlist.add(cont1);
	  //The Service Contract related to this contract (through Subscription) should not extend since Terminate_Extended_Warranty__c = true
	  Contract cont2 = new Contract(AccountId = acct2.Id, Terminate_Extended_Warranty__c = true);
	  contlist.add(cont2);
	  insert contlist;
	  
	  SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
	     Name__c = 'Test Parent 1',
		 SBQQ__Contract__c = cont1.Id,
         SBQQ__Quantity__c = 4,
         Status__c = 'Contract Sent');
	  sublist.add(sub1);
	  SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
	     Name__c = 'Test Parent 2',
		 SBQQ__Contract__c = cont2.Id,
         SBQQ__Quantity__c = 3,
         Status__c = 'Contract Sent');
	  sublist.add(sub2);
	  insert sublist;

	  ServiceContract sc1 = new ServiceContract(Name = 'Extended Warranty 1', accountid = acct1.id, startdate = todayDate.addDays(-30),
	                                            enddate = todayDate, term = 1, Subscription__c = sub1.id); //,status = 'Active'
	  sclist.add(sc1);
	  ServiceContract sc2 = new ServiceContract(Name = 'Extended Warranty 2', accountid = acct2.id, startdate = todayDate.addDays(-30),
	                                            enddate = todayDate, term = 1, Subscription__c = sub2.id); //,status = 'Active'
	  sclist.add(sc2);
	  insert sclist;
	  
	  test.startTest();
	     BatchRenewExtendedSCSchedule sh1 = new BatchRenewExtendedSCSchedule();
		 String sch = '0 0 23 * * ?';
		 system.schedule('Test check', sch, sh1);
	  test.stopTest();
	  List<ServiceContract> sc_updates = [ SELECT Name, startdate, enddate, status
	                                       FROM ServiceContract 
	                                       WHERE Name = 'Extended Warranty 1' AND enddate <> :todayDate ];
	  system.debug('Number of Service Contracts updated: '+ sc_updates.size());
	  system.assert(sc_updates.size() == 1);
   } 
}