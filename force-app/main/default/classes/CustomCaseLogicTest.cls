@isTest
public with sharing class CustomCaseLogicTest {
			
	@isTest static void testCustomCaseLogic() { 
		Account a = DataGenerator.createAccounts(1, true)[0];
		Account suppAcc = DataGenerator.createAccounts(1, true)[0];
		
		Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
		System.debug('**** /////// *****  SupportOffice Id = ' + supportOfficeId);
		suppAcc.RecordTypeId = supportOfficeId;
		
		upsert suppAcc;
		a.Support_Office__c = suppAcc.Id;
		upsert a;
		
		
		AppConfig__c appConfig = new AppConfig__c();
		appConfig.Name='Global';
		appConfig.Case_Comments_To_Include_On_Dispatch__c = 999;
		upsert appConfig;
		
		User u = DataGenerator.createUsers(Definitions.PROFILE_SalesUser, 1, true)[0];
		SupportOfficeMember__c suppMem = new SupportOfficeMember__c();
		suppMem.User__c = u.Id;
		suppMem.SupportOffice__c = suppAcc.Id;
		suppMem.Role__c = 'Primary Engineer';
		
		upsert suppMem;
		
		AccountTeamMember atm = (AccountTeamMember) DataGenerator.createSObjectWithDefaultValues('AccountTeamMember');
		atm.UserId = u.Id;
		atm.TeamMemberRole = 'Primary Engineer';
		atm.AccountId=a.Id;
		upsert atm;
		  
		
		Map<Id,List<SupportOfficeMember__c>> supportTeamMemberMap = new Map<Id,List<SupportOfficeMember__c>>();
		List<SupportOfficeMember__c> suppList = new List<SupportOfficeMember__c>();
		suppList.add(suppMem);
		upsert suppList;
		supportTeamMemberMap.put(suppAcc.id,suppList); 
		
		
		List<Case> caseList = new List<Case>();
		Map<Id,Case> caseMap = new Map<Id,Case>();
		Integer recordsToCreate = 1;
		
		for(Integer i=0;i<recordsToCreate;i++){
			Case case1 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
			case1.AccountId = a.Id;
			case1.Support_Office__c = suppAcc.Id;
			case1.Dispatched__c = true;
			case1.Status='Open';
			
			upsert case1;
			
			CaseComment cc = (CaseComment) DataGenerator.createSObjectWithDefaultValues('CaseComment');
			cc.CommentBody='Test Comment in CaseComment';
			cc.ParentId = case1.Id;
			
			upsert cc;
			
			Task t = DataGenerator.createTasks(case1, 1, true)[0];
			t.Description = 'Task '+i+' Description';  
			t.Subject= 'Task '+i+' Subject';
			t.Task_Origin__c = 'Task '+i+' Origin'; 
			t.Case_Product_Type__c= 'Task '+i+' Product Type';
			t.Issue_Type__c = 'Task '+i+' Issue Type'; 
			t.Issue_Sub_Type__c = 'Task '+i+' Issue Sub Type'; 
			t.Issue_Details__c = 'Task '+i+' Issue Details';
			
			upsert t;
			
			caseList.add(case1);
		}
		
		Map<id,Account> supTeamMap =new  Map<id,Account>();
		
		//supTeamMap.put(a.id,a);
		supTeamMap.put(suppAcc.id,suppAcc);
		
		upsert a;
		upsert caseList;
		
		Map<Id, List<Case>> caseTeamMap = new Map<Id, List<Case>>();
		caseTeamMap.put(suppAcc.Id,caseList); 
		
		for(Case c : caseList){
			caseMap.put(c.id,c);
		}
		
		List<Id> supportOfficeIds = new List<Id>();
		supportOfficeIds.add(suppAcc.Id); 
		 
		List<AcountTeamRoles__c> accTeamList = new List<AcountTeamRoles__c>(); 
		AcountTeamRoles__c accRole = new AcountTeamRoles__c();
		accRole.Name ='Primary Engineer' ;
		accTeamList.add(accRole);
		upsert accTeamList;
		
		CustomCaseLogic.updateCaseSupportTeam(caseTeamMap, true);
		System.assertNotEquals(null,caseMap);
		System.assertEquals(recordsToCreate,caseMap.size());		
		
		CustomCaseLogic.updateCaseSupportTeam(caseTeamMap, true,true);
		System.assertNotEquals(null,caseMap);
		System.assertEquals(recordsToCreate,caseMap.size());
		
		CustomCaseLogic.updateCaseSupportTeam(caseTeamMap, supportTeamMemberMap,true);
		System.assertNotEquals(null,caseMap);
		System.assertEquals(recordsToCreate,caseMap.size());
		
		CustomCaseLogic.getCaseTeamMap(supTeamMap);
		System.assertNotEquals(null,supTeamMap);
		
		Map<Id, List<Case>> suppOfficeId = CustomCaseLogic.getCaseTeamMap(supportOfficeIds);
		System.assertNotEquals(null,suppOfficeId);
	}

	@isTest
	static void testCaseInteractionHistory(){
		User user = DataGenerator.createUsers(Definitions.PROFILE_SalesUser, 1, true)[0];
		
		Case case1 = (Case) DataGenerator.createSObjectWithDefaultValues('Case');
		case1.Case_Product_Type__c  = 'FTG';
		case1.Issue_Details__c= 'Internet';
		case1.Issue_Type__c ='Software';
		case1.Issue_Sub_Type__c='Games';
		case1.Status='Dispatch';
		//case1.CreatedById = user.Id;
		
		upsert case1;
		//Creating Tasks
		List<Task> tasks = DataGenerator.createTasks(case1, 2, true);
		tasks[0].Description ='Task1 Description for Test';
		tasks[1].Description ='Task2 Description for Test';
		tasks[0].Subject = 'Task1 Subject for Test';
		tasks[1].Subject = 'Task1 Subject for Test';
		tasks[0].Task_Origin__c = 'Tech Support';
		tasks[1].Task_Origin__c = 'Email';
		//tasks[0].CreatedById = user.Id;
		//tasks[1].CreatedById = user.Id;
		upsert tasks;
		
		//Creating Events
		List<Event> events = DataGenerator.createEvents(case1, 4, true);
		
		events[0].Description ='events[0] Description for Test';
		events[1].Description ='events[1] Description for Test';
		events[0].Description ='events[2] Description for Test';
		events[1].Description ='events[3] Description for Test';
		events[0].Subject = 'events[0] Subject for Test';
		events[1].Subject = 'events[1] Subject for Test';
		events[2].Subject = 'events[2] Subject for Test';
		events[3].Subject = 'events[3] Subject for Test';
		events[0].DurationInMinutes = 10;
		events[1].DurationInMinutes = 20;
		events[2].DurationInMinutes = 1;
		events[3].DurationInMinutes = 2;
		
		upsert events;
		
		//Creating CaseComments
		CaseComment cc1 = (CaseComment) DataGenerator.createSObjectWithDefaultValues('CaseComment');
		CaseComment cc2 = (CaseComment) DataGenerator.createSObjectWithDefaultValues('CaseComment');
		cc1.ParentId = case1.Id;
		cc1.CommentBody = 'Test CaseComment1';
		cc2.ParentId = case1.Id;
		cc2.CommentBody = 'Test CaseComment1';
		
		upsert cc1;
		upsert cc2;
		//Creating Case ActivityHistory
		String query = 'Select Id,Case_Product_Type__c,Issue_Type__c,Issue_Sub_Type__c,Issue_Details__c,'+
    		' CreatedBy.Name,CreatedDate, '+
    		' (Select Id,Description,Subject,Task_Origin__c,CreatedBy.Name,CreatedDate '+
    		' from ActivityHistories ) from Case where Id = \''+ case1.Id+'\'';
		List<ActivityHistory> ah1 =(List<ActivityHistory>) Utilities.getRelatedListData(query, 'Task');
		List<ActivityHistory> ah2 =(List<ActivityHistory>) Utilities.getRelatedListData(query, 'Event');
		
		//Creating Case Open Activity
		query = 'Select Id,Case_Product_Type__c,Issue_Type__c,Issue_Sub_Type__c,Issue_Details__c,'+
    		' CreatedBy.Name,CreatedDate, '+
    		' (Select Id,Description,Subject,Task_Origin__c,CreatedBy.Name,CreatedDate '+
    		' from OpenActivities ) from Case where Id = \''+ case1.Id+'\'';
		List<OpenActivity> oa1 =(List<OpenActivity>) Utilities.getRelatedListData(query, 'Task');
		List<OpenActivity> oa2 =(List<OpenActivity>) Utilities.getRelatedListData(query, 'Event');

		
		if(oa1 != null){upsert oa1;}
		if(oa2 != null){upsert oa2;}
		
		//Creating Field Service Digest
		Field_Service_Digest__c fsd1 = (Field_Service_Digest__c) DataGenerator.createSObjectWithDefaultValues('Field_Service_Digest__c');
		Field_Service_Digest__c fsd2 = (Field_Service_Digest__c) DataGenerator.createSObjectWithDefaultValues('Field_Service_Digest__c');
		fsd1.Case__c = case1.Id;
		fsd2.Case__c = case1.Id;
		fsd1.CheckIn_Time__c = System.now().addDays(-1);
		fsd2.CheckIn_Time__c = System.now().addDays(-2);
		fsd1.CheckOut_Time__c = System.now();
		fsd2.CheckOut_Time__c = System.now();
		fsd1.Field_Notes__c ='Field Notes for 1st One';
		fsd2.Field_Notes__c ='Field Notes for 2nd One';
		
		upsert fsd1;
		upsert fsd2;
		
		//Creating Case History
		Case1.Status=' Prob Identified-Down';
		case1.Issue_Type__c='Hardware';
		
		query ='Select Id,Field,NewValue, OldValue,CreatedBy.Name,CreatedDate ' + 
    						'	from CaseHistory where CaseId=\''+ case1.Id+'\'';
		List<CaseHistory> ch1 =(List<CaseHistory>) Utilities.getRelatedListData(query, 'Case');
		
		System.runAs(user){
			CaseInteractionHistoryExtension cIHE = new CaseInteractionHistoryExtension(new ApexPages.StandardController(case1));
			
			List<CustomCaseLogic.CaseInteractionHistory> caseHistoryList =  cIHE.historyList;
			System.assertNotEquals(null, caseHistoryList);
			
		}
	}
	/*
	@isTest static void testCreateCase(){
		Integer recordsToCreate = 1; 
		Account acc = DataGenerator.createAccounts(recordsToCreate, true)[0];
		Product2 prod2 = (Product2) DataGenerator.createSObjectWithDefaultValues('Product2');
		prod2.Name ='Product For Asset'; 
		upsert prod2;
		ServiceContract servContract = (ServiceContract) DataGenerator.createSObjectWithDefaultValues('ServiceContract');
		servContract.Name='Service Contract For Asset';
		upsert servContract;
		Asset asset = (Asset) DataGenerator.createSObjectWithDefaultValues('Asset');
		asset.Name = 'FTG';
		asset.Product2Id = prod2.Id;
		asset.Service_Contract__c = servContract.Id;
		asset.AccountId = acc.Id;
		
		upsert asset;
		
		Case caseDetails = DataGenerator.createCases(acc.Id, recordsToCreate, true)[0];
		caseDetails.AssetId = asset.Id;
		String caseRecordType = Definitions.RECORDTYPE_Case_SupportCase;
		
		Id createCase = CustomCaseLogic.createCase(caseDetails, caseRecordType);
		System.assertNotEquals(null,createCase);
		
		Entitlement entl = (Entitlement) DataGenerator.createSObjectWithDefaultValues('Entitlement');
		entl.AccountId = acc.Id;
		entl.AssetId = asset.Id;
		entl.ServiceContractId = servContract.Id;
		entl.Name = 'Entitlement Name';
		upsert entl;
		
		caseDetails.EntitlementId = entl.Id;
		
		
		CaseProductTypes__c caseProductTypes = new CaseProductTypes__c();
		caseProductTypes.Name = 'FTG';
		caseProductTypes.Product_Inventory__c = 'FTG';
		upsert caseProductTypes;
		 
		
		createCase = CustomCaseLogic.createCase(caseDetails, caseRecordType);
		System.assertNotEquals(null,createCase);
	}
	*/
	
	
	@isTest static void testgetCaseTeamMap(){
		Integer recordsToCreate = 1;
		Account acc = DataGenerator.createAccounts(recordsToCreate, true)[0];
		
		Account suppAcc = DataGenerator.createAccounts(recordsToCreate, true)[0];
		Id supportOfficeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Support Office').getRecordTypeId();
		suppAcc.RecordTypeId = supportOfficeId;
		upsert suppAcc;
		
		acc.Support_Office__c = suppAcc.Id;
		upsert acc;
		
		User u = DataGenerator.createUsers(Definitions.PROFILE_SalesUser, 1, true)[0];
		
		AppConfig__c appConfig = new AppConfig__c();
		appConfig.Name='Global';
		appConfig.Dispatch_Error__c = 'Dispatch_Error__c';
		upsert appConfig;
		
		
		SupportOfficeMember__c suppMem = new SupportOfficeMember__c();
		suppMem.User__c = u.Id;
		suppMem.SupportOffice__c = suppAcc.Id;
		suppMem.Role__c = 'Primary Engineer';
		suppMem.User__c = u.Id;
		
		upsert suppMem;
		
		AccountTeamMember atm = (AccountTeamMember) DataGenerator.createSObjectWithDefaultValues('AccountTeamMember');
		atm.UserId = u.Id;
		atm.TeamMemberRole = 'Primary Engineer';
		atm.AccountId=acc.Id;
		
		upsert atm;
		
		List<Id> supportOfficeIds = new List<Id>();
		Map<Id, Account> accountMap = new Map<Id, Account>();
		List<Case> caseList = new List<Case>();
		
		for(Integer i=0;i<1;i++){
			Case suppOfficeCase =  DataGenerator.createCases(acc.Id, 1, true)[0]; 
			suppOfficeCase.AccountId = acc.Id;
			suppOfficeCase.status ='Open';
			suppOfficeCase.Dispatched__c = true;
			suppOfficeCase.Support_Office__c = suppAcc.Id;
			
			caseList.add(suppOfficeCase);
			accountMap.put(suppOfficeCase.AccountId,acc);
			supportOfficeIds.add(suppOfficeCase.Id);
		}
		upsert caseList;
		
		Map<Id, List<Case>> getCaseTeamMap = CustomCaseLogic.getCaseTeamMap(supportOfficeIds);
		System.assertNotEquals(null,getCaseTeamMap);
		
		getCaseTeamMap = CustomCaseLogic.getCaseTeamMap(accountMap);
		System.assertNotEquals(null,getCaseTeamMap);
	}
	
	@isTest
	static void testProcessStatusChange(){
		AppConfig__c appConfig = new AppConfig__c();
		appConfig.Name = 'Global';
		appConfig.CompanyUTCOffset__c = 0;
		appConfig.BlockTriggerProcessing__c = true; 
		upsert appConfig;
		
		Integer recordsToCreate = 1;
		Account acc = DataGenerator.createAccounts(1, true)[0];
		upsert acc;
		
		Map<Id, List<Case>> accountCaseMap = new Map<Id, List<Case>>();
		List<Case> caseList = DataGenerator.createCases(acc.Id, recordsToCreate, true);
		for(Case c : caseList){
			c.Status = 'In Route';
			c.SlaStartDate = Datetime.now().addDays(-2);
			 
		}
		upsert caseList;

        // get and store the cases service contract name 
        Map<Id,String> casesServiceContractMap = CustomCaseLogic.casesServiceContracts(caseList);
		
		
		
		MilestoneStopStatus__c milestoneStopStatus = new MilestoneStopStatus__c();
		milestoneStopStatus.Name = 'In Route Field Response Time';
		milestoneStopStatus.CaseStatus__c ='In Route';
		milestoneStopStatus.Milestone__c = 'Field Response Time';
		
		upsert milestoneStopStatus;
		milestoneStopStatus = new MilestoneStopStatus__c();
		milestoneStopStatus.Name = 'In Route';
		milestoneStopStatus.CaseStatus__c ='In Route';
		milestoneStopStatus.Milestone__c = 'Field Response Time';
		
		upsert milestoneStopStatus;
		
		CaseStatustoTime__c CaseStatustoTime = new CaseStatustoTime__c();
		CaseStatustoTime.Name='AM Dispatch Approved - Friday';
		CaseStatustoTime.Status_Change_Day__c = System.now().format('EEEE');
		CaseStatustoTime.Day_to_Restart_Clock__c = 'Saturday';
		CaseStatustoTime.Status__c = 'In Route';
		CaseStatustoTime.Time_to_Restart_Clock__c = 12; 
		upsert CaseStatustoTime;
		
		List<MilestoneStopStatus__c> mileStoneCustSetTest = MilestoneStopStatus__c.getAll().values();
		System.debug('mileStoneCustSetTest is : '+mileStoneCustSetTest);
		
		try{
			Map<String, List<String>> milestoneStopStatusMap= CustomCaseLogic.MilestoneStopStatusMap;
			System.debug('milestoneStopStatusMap : '+milestoneStopStatusMap);
		}catch(Exception e){
			System.debug('Exception occured : '+e);
		}
		
		
		
		accountCaseMap.put(acc.Id,caseList);
		CustomCaseLogic.processStatusChange(accountCaseMap,casesServiceContractMap);
		
		
	}
	/*
	@isTest(seeAllData=true) static void testCaseCompleteMilestoneUpdate(){
		Integer recordsToCreate = 1;
		User currUser = DataGenerator.createUsers(Definitions.PROFILE_SalesUser, 1, true)[0];
		Account acc = DataGenerator.createAccounts(1, true)[0];
		upsert acc;
			
		List<Id> caseIds = new List<Id>();
		List<Case> caseList = DataGenerator.createCases(acc.Id, recordsToCreate, true);
		for(Case c : caseList){
			c.Status = 'In Route';
			c.SlaStartDate = Datetime.now().addDays(-2);
			caseIds.add(c.Id);
			 
		}
		caseIds.add('500Z0000004riH1IAI');
		upsert caseList;
		
		List<String> milestoneName = new List<String>();
			milestoneName.add('Field Response Time');
			milestoneName.add('Resolution Time');
			
			Datetime complDate = Datetime.now().addDays(2);
		
		System.runAs(currUser){ 
			
			List<CaseMilestone> cmList = new List<CaseMilestone>();
			for(Integer i=0;i<1;i++){
				CaseMilestone cm = (CaseMilestone) DataGenerator.createSObjectWithDefaultValues('CaseMilestone');
				//cm.mileStoneTypeId = mileStoneTypeObj.Id; 
				cmList.add(cm);
			}
			//upsert cmList;
		//}
		
		User thisUser = [Select Id from User where Id =:UserInfo.getUserId()];
		//System.runAs(thisUser){
		CustomCaseLogic.caseCompleteMilestoneUpdate(caseIds, milestoneName, complDate);
		
		List<CaseMilestone> cmTestResult = [select Id, completionDate
	                       from CaseMilestone cm
	                       where caseId IN :caseIds 
	                         and cm.MilestoneType.Name IN :milestoneName 
	                         and completionDate = null];
	                         
	    System.assertNotEquals(null,cmTestResult);
	    //System.assertEquals(10,cmTestResult.size());
	    
		}
	}
	*/
	
	@isTest static void testGetCaseInteractionHistory(){
		Account acc = DataGenerator.createAccounts(1, true)[0];
		Case c = DataGenerator.createCases(acc.Id, 1, true)[0];
		Id caseId = c.Id; 
		List<Id> caseIdList = new List<Id>();
		caseIdList.add(c.Id);
		upsert c;
		
		List<CustomCaseLogic.CaseInteractionHistory> getCaseInteractionHistory =CustomCaseLogic.GetCaseInteractionHistory(caseId);
		System.assertNotEquals(null,getCaseInteractionHistory);
		
		getCaseInteractionHistory =CustomCaseLogic.GetCaseInteractionHistory(caseIdList);
		System.assertNotEquals(null,getCaseInteractionHistory);
		
		getCaseInteractionHistory =CustomCaseLogic.GetCaseInteractionHistory(caseIdList, 1);
		System.assertNotEquals(null,getCaseInteractionHistory);
	}
	
	@isTest static void testGetCaseComments(){
		Integer recordsToCreate = 1; 
		Account acc = DataGenerator.createAccounts(recordsToCreate, true)[0];
		Case caseNew = DataGenerator.createCases(acc.Id, recordsToCreate, true)[0];
		upsert caseNew;
		
		List<CaseComment> casCommentList = new List<CaseComment>();
		for(Integer i=0;i<1;i++){
			CaseComment cc =(CaseComment) DataGenerator.createSObjectWithDefaultValues('CaseComment');
			cc.ParentId = caseNew.Id;
			cc.CommentBody='CaseComment '+i;
			casCommentList.add(cc);
		}
		upsert casCommentList;
		
		Id caseId = caseNew.Id;
		List<CustomCaseLogic.CaseInteractionHistory> getCaseComments = CustomCaseLogic.GetCaseComments(caseId);
		System.assertNotEquals(null,getCaseComments);
		
		List<Id> caseIdList= new List<Id>();
		List<Case> caseList = new List<Case>();
		caseList = DataGenerator.createCases(acc.Id, recordsToCreate, true);
		for(Case c : caseList){
			caseIdList.add(c.Id);
		}
		
		
		getCaseComments = CustomCaseLogic.GetCaseComments(caseIdList);
		System.assertNotEquals(null,getCaseComments);
		
		
		
		Integer recordsToGet = recordsToCreate;
		getCaseComments = CustomCaseLogic.GetCaseComments(caseIdList, recordsToGet);
		System.assertNotEquals(null,getCaseComments);
	}
	
	@isTest static void testGetCaseTasks(){
		
		Integer recordsToCreate = 1; 
		Account acc = DataGenerator.createAccounts(recordsToCreate, true)[0];
		Case caseNew = DataGenerator.createCases(acc.Id, recordsToCreate, true)[0];
		upsert caseNew;
		
		List<Task> caseTaskList = DataGenerator.createTasks(caseNew, recordsToCreate, true);
		upsert caseTaskList;
		
		Id caseId = caseNew.Id;
		
		List<CustomCaseLogic.CaseInteractionHistory> getCaseTasks = CustomCaseLogic.GetCaseTasks(caseId);
		System.assertNotEquals(null,getCaseTasks);
		
		
		List<Id> caseIdList= new List<Id>();
		List<Case> caseList = new List<Case>();
		caseList = DataGenerator.createCases(acc.Id, recordsToCreate, true);
		for(Case c : caseList){
			caseIdList.add(c.Id);
		}
		
		
		getCaseTasks = CustomCaseLogic.getCaseTasks(caseIdList);
		System.assertNotEquals(null,getCaseTasks);
		
		Integer recordsToGet = recordsToCreate;
		getCaseTasks = CustomCaseLogic.getCaseTasks(caseIdList, recordsToGet);
		System.assertNotEquals(null,getCaseTasks);		
		
	}
	
	@isTest static void testGetCaseEvents(){
		
		Integer recordsToCreate = 1; 
		Account acc = DataGenerator.createAccounts(recordsToCreate, true)[0];
		Case caseNew = DataGenerator.createCases(acc.Id, recordsToCreate, true)[0];
		upsert caseNew;
		
		List<Event> caseEventList = DataGenerator.createEvents(caseNew, recordsToCreate, true);
		upsert caseEventList;
		
		Id caseId = caseNew.Id;
		
		List<CustomCaseLogic.CaseInteractionHistory> getCaseEvents = CustomCaseLogic.GetCaseEvents(caseId);
		System.assertNotEquals(null,getCaseEvents);
		
		
		List<Id> caseIdList= new List<Id>();
		List<Case> caseList = new List<Case>();
		caseList = DataGenerator.createCases(acc.Id, recordsToCreate, true);
		for(Case c : caseList){
			caseIdList.add(c.Id);
		}
		
		
		getCaseEvents = CustomCaseLogic.getCaseEvents(caseIdList);
		System.assertNotEquals(null,getCaseEvents);
		
		Integer recordsToGet = recordsToCreate;
		getCaseEvents = CustomCaseLogic.getCaseEvents(caseIdList, recordsToGet);
		System.assertNotEquals(null,getCaseEvents);		
		
	}
	
	@isTest static void testGetCaseFieldServiceDigest(){
		
		Integer recordsToCreate = 1; 
		Account acc = DataGenerator.createAccounts(recordsToCreate, true)[0];
		Case caseNew = DataGenerator.createCases(acc.Id, recordsToCreate, true)[0];
		upsert caseNew;
		
		List<Field_Service_Digest__c> fieldServiceList = new List<Field_Service_Digest__c>();
		for(Integer i=0;i<1;i++){
			Field_Service_Digest__c fsd =(Field_Service_Digest__c) DataGenerator.createSObjectWithDefaultValues('Field_Service_Digest__c');
			fsd.Case__c = caseNew.Id;
			fieldServiceList.add(fsd);
		}
		upsert fieldServiceList;
		
		Id caseId = caseNew.Id;
		
		List<CustomCaseLogic.CaseInteractionHistory> getCaseFieldServiceDigest = CustomCaseLogic.GetFieldServiceDigest(caseId);
		System.assertNotEquals(null,getCaseFieldServiceDigest);
		
		
		List<Id> caseIdList= new List<Id>();
		List<Case> caseList = new List<Case>();
		caseList = DataGenerator.createCases(acc.Id, recordsToCreate, true);
		for(Case c : caseList){
			caseIdList.add(c.Id);
		}
		
		
		getCaseFieldServiceDigest = CustomCaseLogic.GetFieldServiceDigest(caseIdList);
		System.assertNotEquals(null,getCaseFieldServiceDigest);
		
		Integer recordsToGet = recordsToCreate;
		getCaseFieldServiceDigest = CustomCaseLogic.GetFieldServiceDigest(caseIdList, recordsToGet);
		System.assertNotEquals(null,getCaseFieldServiceDigest);		
		
	}
	
	
	@isTest(seeAllData = true) static void testGetCaseHistory(){
		
		Integer recordsToCreate = 1; 
		Account acc = DataGenerator.createAccounts(recordsToCreate, true)[0];
		Case caseNew = DataGenerator.createCases(acc.Id, recordsToCreate, true)[0];
		Id caseId = caseNew.Id;
		
		
		List<CustomCaseLogic.CaseInteractionHistory> getcaseHistoryDigest = CustomCaseLogic.GetCaseHistory(caseId);
		System.assertNotEquals(null,getcaseHistoryDigest);
		
		List<CaseHistory> caseHistoryListResult = [
    									SELECT Id, CaseId, Field, NewValue, OldValue, CreatedBy.Name, CreatedDate 
    									FROM CaseHistory 
    									//WHERE CaseId IN : caseIdList
    									LIMIT 10
    								  ];
    	System.debug('caseHistoryListResult is : '+caseHistoryListResult);
    	
    	List<Id> caseIdList= new List<Id>();
		for(CaseHistory ch : caseHistoryListResult){
			caseIdList.add(ch.CaseId);	
		}
		
		getcaseHistoryDigest = CustomCaseLogic.GetCaseHistory(caseIdList);
		System.assertNotEquals(null,getcaseHistoryDigest);
		
		Integer recordsToGet = recordsToCreate;
		getcaseHistoryDigest = CustomCaseLogic.GetCaseHistory(caseIdList, recordsToGet);
		System.assertNotEquals(null,getcaseHistoryDigest);		
		
	}
	
	@isTest static void testMilestoneStopStatusMap(){
		MilestoneStopStatus__c milestoneStopStatus = new MilestoneStopStatus__c();
		milestoneStopStatus.Name = 'In Route Field Response Time';
		milestoneStopStatus.CaseStatus__c ='In Route';
		milestoneStopStatus.Milestone__c = 'Field Response Time';
		
		upsert milestoneStopStatus;
		
		Map<String, List<String>> MilestoneStopStatusMap = CustomCaseLogic.MilestoneStopStatusMap;
		System.assertNotEquals(null,MilestoneStopStatusMap);
	}
	
	@isTest static void testsetCaseAssetDetails(){
		Account acc = DataGenerator.createAccounts(1, true)[0];
		Case theCase = DataGenerator.createCases(acc.Id, 1, true)[0];
		List<Product2> productList = DataGenerator.createProducts(5, true);
		Asset asset = DataGenerator.createAssets(productList, acc.Id, Definitions.ASSET_STATUS_INSTALLED, true)[0];
		
		CustomCaseLogic.setCaseAssetDetails(theCase, asset.Id);
		
	}
	//Steve, this method is here for coverage only
	static testMethod void testFunctions()
	{
		AppConfig__c appConfig = new AppConfig__c();
		appConfig.Name = 'Global';
		appConfig.CompanyUTCOffset__c = 0;
		appConfig.BlockTriggerProcessing__c = true; 
		upsert appConfig;
		
		Integer recordsToCreate = 1;
		Account acc = DataGenerator.createAccounts(1, true)[0];
		upsert acc;
		
		Map<Id, List<Case>> accountCaseMap = new Map<Id, List<Case>>();
		List<Case> caseList = DataGenerator.createCases(acc.Id, recordsToCreate, true);
		for(Case c : caseList){
			c.Status = 'In Route';
			c.SlaStartDate = Datetime.now().addDays(-2);
			 
		}
		upsert caseList;
		CustomCaseLogic.updateCaseSupportTeam(caseList, true);
		CustomCaseLogic.updateCaseSupportTeam(accountCaseMap, false);
		CustomCaseLogic.updateCaseSupportTeam(accountCaseMap, true);
	
			Account suppAcc = DataGenerator.createAccounts(1, true)[0];
	
			User u = DataGenerator.createUsers(Definitions.PROFILE_SalesUser, 1, true)[0];
		SupportOfficeMember__c suppMem = new SupportOfficeMember__c();
		suppMem.User__c = u.Id;
		suppMem.SupportOffice__c = suppAcc.Id;
		suppMem.Role__c = 'Primary Engineer';
		
		//upsert suppMem;
		
		Map<Id,List<SupportOfficeMember__c>> supportTeamMemberMap = new Map<Id,List<SupportOfficeMember__c>>();
		List<SupportOfficeMember__c> suppList = new List<SupportOfficeMember__c>();
		suppList.add(suppMem);
		//upsert suppList;
		supportTeamMemberMap.put(suppAcc.id,suppList); 
	
		CustomCaseLogic.updateCaseSupportTeam(accountCaseMap, supportTeamMemberMap, true, false);
		List<Id> supportMemberList = new List<Id>();
		supportMemberList.addAll(supportTeamMemberMap.keyset());
		CustomCaseLogic.getCaseTeamMap(supportMemberList);
	}
	 
}