@isTest
public with sharing class BatchRenewExtendedWarrantyTest {
	
	static testmethod void RenewExtendedWarranty()
	{
		Account acc = New Account(Name = 'Test Account');
		insert acc;
		
		Date todday = system.today();
		
		ServiceContract sc = New ServiceContract(Name = 'Extended Warranty STAY1000', accountid = acc.id, startdate = todday.addDays(-30),
		                                         enddate = todday, term = 1);
		
		insert sc;
		
		List<ServiceContract> sclist = New List<ServiceContract>();
		sclist.add(sc);
		
		test.startTest();
		
			BatchRenewExtendedWarrantySC.RenewExtendedWarrantyServiceContracts(sclist);
			ServiceContract updatedsc = [ Select Id, Name, Enddate from ServiceContract where id = :sc.id LIMIT 1 ];
			system.assert(updatedsc.enddate == todday.addMonths(1));
		test.stopTest();
	}
    
}