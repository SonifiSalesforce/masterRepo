@isTest
private class AttachmentTriggerLogicTests {
	
	static testMethod void testDeleteAttachments() {
		
		// Create users
		Integer usersToCreate = 3;
		List<User> userList = createUsers(usersToCreate, true);
		System.assertNotEquals(null, userList);
		System.assertEquals(usersToCreate, userList.size());
		
		// Create an account to work with
		Account acct = createAccounts(1, true)[0];
		
		// Create attachments
		// NOTE Create 2 more attachments than user to ensure deletion logic works below
		Integer attachmentsToCreate = usersToCreate + 2;
		List<Attachment> attachmentList = createAttachments(acct.Id, attachmentsToCreate, true);
		System.assertNotEquals(null, attachmentList);
		System.assertEquals(attachmentsToCreate, attachmentList.size());
		
		// Create permissions object
		List<AttachmentDeletePermission__c> permissions = new List<AttachmentDeletePermission__c>();
		
		// Specifically set user 1 permissions to FALSE
		// Id userWhoCannotDelete = userList[0].Id;
		AttachmentDeletePermission__c adp =
				AttachmentDeletePermission__c.getInstance(userList[0].Id);
		System.assertNotEquals(null, adp);
		System.assertEquals(null, adp.Id);
		adp.Can_Delete_Attachments__c = false;
		permissions.add(adp);

		// Specifically set user 2 permissions to TRUE
		Id userWhoCanDelete = userList[1].Id;
		adp = AttachmentDeletePermission__c.getInstance(userList[1].Id);
		System.assertNotEquals(null, adp);
		System.assertEquals(null, adp.Id);
		adp.Can_Delete_Attachments__c = true;
		permissions.add(adp);
		
		// NOTE Leave user 3 alone so that there is no record at all to check
		insert permissions;
		
		Test.startTest();
		
		// ATTEMPT TO DELETE WITHOUT PROFILE FLAG TO ENSURE 
		// ONLY USERS WITH USER-LEVEL PERMISSION CAN DELETE
		Attachment attachmentToDelete = attachmentList.remove(0);
		for (User u : userList) {
			
			System.runAs(u) {
				try {
					
					// Attempt to delete
					delete attachmentToDelete;
					
					// Assert that the only successful deletion is for the intended user
					System.assertEquals(userWhoCanDelete, u.Id);
					
					// Get the next attachment to remove
					attachmentToDelete = attachmentList.remove(0);
					
				} catch (System.Dmlexception dmlEx) {
					
					// Assert that ALL exceptions are the result of the intended failures
					for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
						System.debug('******************* DML EXCEPTION: ' + dmlEx.getDmlMessage(i));
						System.assertEquals(true, dmlEx.getDmlMessage(i).contains(AttachmentTriggerLogic.DELETE_PERMISSIONS_ERROR));
					}
										
				} catch (Exception e) {
					
					// Some other exception occurred
					System.assert(false, 'EXPECTED A DIFFERENT EXCEPTION. DETAILS: ' + e.getMessage());
					 
				}
			}
		}
		
		// SET DELETE FLAG FOR PROFILE
		adp = AttachmentDeletePermission__c.getInstance(userList[0].ProfileId);
		System.assertNotEquals(null, adp);
		System.assertEquals(null, adp.Id);
		adp.Can_Delete_Attachments__c = true;
		insert adp;
		
		// RE-RUN TESTS WITH PROFILE FLAG SET TO ENSURE SUCCESS FOR ALL USERS
		for (User u : userList) {
			System.runAs(u) {
				try {
					
					// Attempt to delete
					delete attachmentToDelete;
					
					// Get the next attachment to remove
					attachmentToDelete = attachmentList.remove(0);
					
				/*
				} catch (System.Dmlexception dmlEx) {
					
					// Assert that the only failure is for the intended user
					System.assertEquals(userWhoCannotDelete, u.Id);
					
					// Assert that ALL exceptions are the result of the intended failures
					for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
						System.assertEquals(true, dmlEx.getDmlMessage(i).contains(AttachmentTriggerLogic.DELETE_PERMISSIONS_ERROR));
					}
				*/
								
				} catch (Exception e) {
					
					// Some other exception occurred
					System.assert(false, 'TEST SHOULD NOT HAVE FAILED. DETAILS: ' + e.getMessage());
					 
				}
			}
		}
		
		// Confirm that 1 attachment was deleted for each user
		AggregateResult[] attachmentCounts = 
			[SELECT COUNT(Id) NumAttachments 
			 FROM Attachment 
			 WHERE Id IN :attachmentList];
		Integer numAttachments = Integer.valueOf(attachmentCounts[0].get('NumAttachments'));
		System.assertEquals(0, numAttachments);
		
		Test.stopTest();
	}


/***************************************************************************************************
 * GENERIC TEST DATA CREATION METHODS
 */	
 
	// Create Accounts
	public static List<Account> createAccounts(Integer recordsToCreate, Boolean insertRecords) {
		return createAccounts(null, recordsToCreate, insertRecords);
	}
	
	// Create Accounts
	public static List<Account> createAccounts(Id parentId, Integer recordsToCreate, Boolean insertRecords) {
		
		// Create accounts
		List<Account> accountList = new List<Account>();
		for (Integer i = 1; i <= recordsToCreate; i++) {

			Account a = new Account();
			a.Name = 'Account ' + i;
			a.ParentId = parentId;
			//a.Number_of_Locations__c = 0;
			accountList.add(a);
		}
		
		// Check flag and insert records
		if (insertRecords) { insert accountList; }
		
		// Return accounts
		return accountList;
	}
	
	// Create Customer Support Users
	static List<User> createUsers(Integer recordsToCreate, Boolean insertRecords) {
		
		// Get LodgeNet Customer Support User Profile
		Profile supportUserProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		if (supportUserProfile == null) return null;
		
		// Create users
		List<User> userList = new List<User>();
		for (Integer i = 1; i <= recordsToCreate; i++) {
			
			User u = new User(Alias = 'usr' + i, Email='user' + i + '@test.lodgenet.com', 
					LastName='User' + i, UserName='user' + i + '@test.lodgenet.com', 
					EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
					ProfileId = supportUserProfile.Id, 
					TimeZoneSidKey='America/Los_Angeles');
			
			userList.add(u);
		}
		
		// Check flag and insert records
		if (insertRecords) { insert userList; }
		
		// Return users
		return userList;
	}
	
	// Create attachments
	static List<Attachment> createAttachments(Id parentId, Integer recordsToCreate, Boolean insertRecords) {
		
		// Create attachments
		List<Attachment> attachmentList = new List<Attachment>();
		for (Integer i = 1; i <= recordsToCreate; i++) {
			
			Attachment a = new Attachment();
			a.ParentId = parentId;
			a.Name = 'Attachment' + i;
			a.Body = Blob.valueOf('Attachment' + i + ' body'); 
			
			attachmentList.add(a);
		}
		
		// Check flag and insert records
		if (insertRecords) { insert attachmentList; }
		
		// Return attachments
		return attachmentList;
	}
}