@isTest
private class ContractRenewalBatchProcessTest {
    @testSetup
    static void setup()	
	{
      Date todayDate = system.today();
	  List<Account> acctlist = new List<Account>();
	  List<Contract> contlist = new List<Contract>();
	  List<SBQQ__Subscription__c> sublist = new List<SBQQ__Subscription__c>();

	  Account acct1 = new Account(Name = 'Test Acc 1');
	  acctlist.add(acct1);
	  Account acct2 = new Account(Name = 'Test Acc 2');
	  acctlist.add(acct2);
	  insert acctlist;

	  //This Contract should get renewed
	  Contract cont1 = new Contract(
         AccountId = acct1.id,
		 Renewal_Cycle__c = 60,
		 SBQQ__RenewalTerm__c = 1,
		 Auto_Renew__c = false,
		 ContractTerm = 1,
		 startDate = todayDate.addMonths(-1),
		 Contract_Status__c = 'Activated',
		 endDate = todayDate.addDays(-1)
		 );
	  contlist.add(cont1);
	  //This Contract should NOT get renewed
	  Contract cont2 = new Contract(
	     AccountId = acct2.id,
		 Renewal_Cycle__c = 30,
		 SBQQ__RenewalTerm__c = 3,
		 Auto_Renew__c = false,
		 ContractTerm = 3,
		 startDate = todayDate.addMonths(-1),
		 Contract_Status__c = 'Activated',
		 endDate = todayDate.addMonths(2).addDays(-1)
		 );
	  contlist.add(cont2);
	  insert contlist;
	}

   static testmethod void testContractRenewal() 
   {
	  Test.startTest();
	     //Execute the batch process
         ContractRenewalBatchProcess batchTest = new ContractRenewalBatchProcess();
         database.executeBatch(batchTest);
	  test.stopTest();

      //Find all contracts
      List<Contract> lstContract = [ SELECT Id, Contract_Status__c, startDate, endDate, ContractTerm, Renewal_Cycle__c, SBQQ__RenewalTerm__c, 
	                                        Auto_Renew__c, contractnumber
	                                 FROM Contract ];
      //Verify correct contract has new end date 
	  for(Contract recCont: lstContract) {
	     if(recCont.Auto_Renew__c){   //Value was updated to true by batch process
            Date contractEndDate = system.today().addDays(-1);
            system.debug('Test - Contract End Date 1 actual/expected: '+ recCont.endDate+'/'+contractEndDate.addMonths(1));
            //End date of first contract pushed out a month since yesterday was old end date
	     	system.assert(contractEndDate.addMonths(1) == recCont.endDate);
	     }	
	     else {
            system.debug('Test - Contract End Date 2 actual/expected: '+ recCont.endDate+'/'
                          +recCont.startDate.addMonths((Integer)recCont.SBQQ__RenewalTerm__c).addDays(-1));
	        //End date of second contract should be unchanged
	        system.assert(recCont.startDate.addMonths((Integer)recCont.SBQQ__RenewalTerm__c).addDays(-1) == recCont.endDate);
	     }
	  }
   }
}