@isTest
public with sharing class CustomListControllerTest {

	@isTest
	static void testClassInstantiation() {
		CustomListController customCon;
		AccountActivityListExtension accHisExt;
		
		// Create running user
		User u = DataGenerator.createUsers(Definitions.PROFILE_HealthcareSales, 1, true)[0];
		
		System.runAs(u) {
			
			// Create accounts
			Integer accountsToCreate = 2;
			List<Account> accountList = DataGenerator.createAccounts(accountsToCreate, true);
			System.assertNotEquals(null, accountList);
			System.assertEquals(accountsToCreate, accountList.size());
			
			for (Integer i = 1; i < accountsToCreate; i++) {
				// Built acct hierarchy
				accountList[i].Management_Group__c = accountList[0].Id;
			}
	
			Event ev = new Event();
			ev.Subject = 'Test event';
			ev.OwnerId = u.Id;
			ev.startdatetime = datetime.now().addDays(-1);
			ev.enddatetime = datetime.now().addDays(-1); 
			
			insert ev;
			
			
			//Invalid Account
			Account acc;
			try{
				acc = (Account)DataGenerator.createSObjectWithDefaultValues('INVALID');
				System.assert(false, 'UNEXPECTED RESULT. EXPECTED ERROR.');
			} catch (Exception e) {
			}
			System.assertEquals(null,acc);
			
	
			// Test with valid account
			accHisExt = new AccountActivityListExtension(new ApexPages.StandardController(accountList[0]));
			System.assertNotEquals(null, accHisExt);
			System.assertEquals(u.Id, accountList[0].OwnerId);
	
			customCon = new CustomListController();
			customCon.cloneableInterfaceObject = null;
			System.assertEquals(null,customCon.cloneableInterfaceObject);
			
			customCon.cloneableInterfaceObject = accHisExt;
			
			System.assertEquals(accountList[0].Id, customCon.parentObject.Id);
			System.assertNotEquals(null, customCon.parentObject.Id);

			customCon.showAllRecords = true;
			
			Sobject parObj = customCon.parentObject;
			System.assertNotEquals(null,parObj);
			
			String str = customCon.getRedirectUrl();
			System.assertEquals(null,str);
			
			String name = customCon.parentObjectName;
			System.assertNotEquals(null,name);
			
			Id own =customCon.parentObjectOwner;
			System.assertNotEquals(null,own);
			
			String parName= customCon.parentObjectRecordName;
			System.assertNotEquals(null,parName);
			
			Id parWho = customCon.parentObjectWho;
			System.assertNotEquals(null,parWho);
			
			System.assertNotEquals(null, accHisExt.getItemObjectFieldMap());
			
			customCon.getCloneToItems();
			
			List<Opportunity> opprList = DataGenerator.createOpptys(accountList[0], 2, true);
			System.assertNotEquals(null,opprList);
			System.assertEquals(2,opprList.size());
			
			String itemJson = customCon.getCloneToItemsJson();
			System.assertNotEquals(null,itemJson);
			
			
			
			//Empty cloning
			Pagereference pg;
			try{
				pg = customCon.cloneItems();	
			}catch(Exception e){}
			
			System.assertEquals(null,pg);
			
			//Valid Cloning
			
			ApexPages.currentPage().getParameters().put('cloneableItemIdList',ev.Id ); 
			ApexPages.currentPage().getParameters().put('cloneToIdList',opprList[0].Id + ','+ opprList[1].Id);
			
			Pagereference pageRef = customCon.cloneItems();
			System.assertEquals(null,pageRef);
			
			
			
			
			//Empty Delete
			Pagereference pgDel;
			try{
				pgDel = customCon.deleteItems();	
			}catch(Exception e){}
			
			//Valid Delete
			ApexPages.currentPage().getParameters().put('deletedItemIdList',opprList[0].Id + ','+ opprList[1].Id);
			
			pgDel = customCon.deleteItems(); 
			System.assertEquals(null,pgDel);
			
			List<Opportunity> opList;
			try{
				 opList = [Select Id from Opportunity where Id =:opprList[0].Id OR Id =: opprList[1].Id];	
			}catch(Exception E){}
			
			System.assertEquals(true,opList.isEmpty());
			
			   
		}
	
	}
		
}