@isTest
public class FileTracsTriggerLogicTest {
	
	static testmethod void testUpdateAccountandTrackingNumber()
	{
		Account acc1 = DataGenerator.createAccounts(1, true).get(0);
		Account acc2 = DataGenerator.createAccounts(1, true).get(0);
		
		Account getacct = [ Select Id, Name, site_id__c from Account where Id = :acc1.Id LIMIT 1 ];
		Account getacct2 = [ Select Id, Name, site_id__c from Account where Id = :acc2.Id LIMIT 1 ];
		
		FileTracs__c ftrac = New FileTracs__c(Name = getacct.site_id__c, file_id__c = '785', rack_id__c = '9', shelf_id__c = '5');
		FileTracs__c ftrac2 = New FileTracs__c(Name = getacct.site_id__c, file_id__c = '85', rack_id__c = '19', shelf_id__c = '6');
		FileTracs__c ftrac3 = New FileTracs__c(Name = getacct.site_id__c, file_id__c = '5', rack_id__c = '1', shelf_id__c = '6');
		
		test.startTest();
			insert ftrac;
			insert ftrac2;
			insert ftrac3;
			
			FileTracs__c updft = [ Select Id, Name, AccountName__c, Tracking_Number__c, file_id__c, rack_id__c from FileTracs__c where
			                       Id = :ftrac.Id LIMIT 1];
			                       
			FileTracs__c updft2 = [ Select Id, Name, AccountName__c, Tracking_Number__c, file_id__c, rack_id__c from FileTracs__c where
			                       Id = :ftrac2.Id LIMIT 1];
			                       
                
			system.assert(updft.tracking_number__c == '09-5-00785');
			system.assert(updft2.tracking_number__c == '19-6-00085');
			
			updft.file_id__c = '1785';
			update updft;
			
			updft2.Name = getacct2.site_id__c;
			updft2.file_id__c = '2';
			update updft2;
			
		test.stopTest();
		
		List<FileTracs__c> ftlist = [ Select Id, tracking_number__c, accountname__c from FileTracs__c ];
		
		for(FileTracs__c ft : ftlist)
		{
			if(ft.Id == updft.id)
			{
				system.assert(ft.tracking_number__c == '09-5-01785' );
			}
			else if(ft.Id == updft2.Id)
			{
				system.assert(ft.accountname__c == getacct2.Id);
			}
		}		
	
	}//end testUpdateAccountandTrackingNumber
    
}