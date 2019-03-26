@isTest
public class AccountOpportunitiesExtensionTest {
	
	@isTest public static void testAccountOpptys() {
		
		// Create running user
		User u = DataGenerator.createUsers(Definitions.PROFILE_HealthcareSales, 1, true)[0];
		System.assertNotEquals(null, u);
		
		// Create accounts
		Integer accountsToCreate = 2;
		List<Account> accountList = DataGenerator.createAccounts(accountsToCreate, true);
		System.assertNotEquals(null, accountList);
		System.assertEquals(accountsToCreate, accountList.size());
		
		// Associate accounts
		Account hotelParent = accountList[0];
		Account hotel = accountList[1];
		hotel.Management_Group__c = hotelParent.Id;
		hotel.Name = 'Test Hotel';
		hotel.OwnerId = u.Id;
		update hotel;
		System.assertEquals(hotelParent.Id, hotel.Management_Group__c);
		
		// Create opptys
		Integer opptysToCreate = 2;
		List<Opportunity> opptyList = DataGenerator.createOpptys(hotel, opptysToCreate, true);
		System.assertNotEquals(null, opptyList);
		System.assertEquals(opptysToCreate, opptyList.size());
		
		System.runAs(u) {
			
			// Create page
			ApexPages.PageReference pageRef = Page.AccountOpportunities;
			Test.setCurrentPage(pageRef); 
			
			// Create invalid page extension
			AccountOpportunitiesExtension ext = new AccountOpportunitiesExtension(null);
			System.assertNotEquals(null, ext);
			
			// Create page extension
			ext = new AccountOpportunitiesExtension(new ApexPages.StandardController(hotel));
			System.assertNotEquals(null, ext);
			
			// Set page parameters and recreate class
			ApexPages.currentPage().getParameters().put('showAll', 'true');
			
			// Create page extension
			ext = new AccountOpportunitiesExtension(new ApexPages.StandardController(hotel));
			System.assertNotEquals(null, ext);
				
			// Assertions
			System.assertNotEquals(null, ext.getCloneableInterface());
			System.assertNotEquals(null, ext.getParentObject());
			System.assertEquals(hotel.Id, ext.getParentObject().Id);
			System.assertNotEquals(null, ext.getWhoId());
			
			// Not implemented in this class
			System.assertEquals(null, ext.getCloneToItems());
			System.assertEquals(null, ext.getItemObjectFieldMap());
		}			
	} 
}