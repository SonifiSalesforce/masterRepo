@IsTest
public with sharing class OpportunityProgrammingHierarchyTest {

	@testSetup static void setup()
	{
		//Create custom setting
		List<Profile> currentUserProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
		OpportunityProgrammingHierarchyAdd__c cs_Profile = new OpportunityProgrammingHierarchyAdd__c(name = currentUserProfile[0].Name);

		Account a = new Account(Name = 'testAccount');
		insert a;
		List<Product2> lstProduct2 = new List<Product2>();
		Product2 p = new Product2(Name = 'Test Product Parent', ProductCode = 'Test_Parent_01');
		insert p;
		Product2 p01 = new Product2(Name = 'Child Product 01', ProductCode = 'Child_01', Parent_Part__c = p.id);
		Product2 p02 = new Product2(Name = 'Child Product 02', ProductCode = 'Child_02', Parent_Part__c = p.id);
		lstProduct2.add(p01);
		lstProduct2.add(p02);
		insert lstProduct2;

		Opportunity o = new Opportunity(AccountId = a.Id, Name = 'TestOp', StageName = 'Prospect', CloseDate = Date.today());
		insert o;

        //Create quotes
        //SPT Quote
        Quote spt_Quote = new Quote(Name = 'SPT Quote 01', Status = 'Draft', opportunityId = o.id);
        insert spt_Quote;
        //CPQ Quote
        SBQQ__Quote__c cpq_Quote = new SBQQ__Quote__c(sbqq__account__c = a.id, sbqq__type__c='Quote',
   		                    sbqq__status__c = 'Approved', sbqq__opportunity2__c = o.id);
        insert cpq_Quote;

		List<Programming__c> pList = new List<Programming__c>();
		Programming__c prg = new Programming__c(Product__c = p.id, Name = 'Program Parent', parent__c = NULL);
		insert prg;
		Programming__c prg01 = new Programming__c(Product__c = p01.id, Name = 'Program Child 01', parent__c = prg.id);
		Programming__c prg02 = new Programming__c(Product__c = p02.id, Name = 'Program Child 02', parent__c = prg.id);
		pList.add(prg01);
		pList.add(prg02);
		insert pList;
		
		//Create contracts
		Contract c = new Contract(SBQQ__Opportunity__c = o.Id, Contract_Type__c = 'FTG', Contract_Status__c = 'Draft', AccountId = a.Id);
		insert c;
	}

	@isTest static void testSPT_CPQ_error()
	{		
		contract c = [ SELECT id FROM contract LIMIT 1 ];
		opportunity o = [ SELECT id, AccountId, Name, StageName, CloseDate, Applied_Quote__c, SBQQ__PrimaryQuote__c FROM opportunity LIMIT 1 ];
		Quote spt_Quote = [ SELECT id, name, OpportunityId FROM Quote LIMIT 1 ];
		SBQQ__Quote__c cpq_Quote = [ SELECT id, SBQQ__Primary__c, sbqq__opportunity2__c FROM SBQQ__Quote__c LIMIT 1 ];

		//Set Applied Quote (SPT) on Opportunity
		o.Applied_Quote__c = spt_Quote.id;
		update o;

		//Set Quote as Primary (CPQ)
		cpq_Quote.SBQQ__Primary__c = true;
		update cpq_Quote;

		PageReference pr = Page.OpportunityProgrammingHeirarchy; 
		pr.getParameters().put('contractId',c.id);
		pr.getParameters().put('appendToContractBoolean', 'false');
		List<ID> programmingList = new List<ID>();
		pr.getParameters().put('selectedKeys',JSON.serialize(programmingList));
		Test.setCurrentPageReference(pr);
		Test.startTest();

		OpportunityProgrammingHeirarchyExtension controller = new OpportunityProgrammingHeirarchyExtension(new ApexPages.StandardController(o));
		controller.loadContracts();
		controller.saveTasks();
		test.stopTest();
	}

	@isTest static void testCPQ()
	{		
		contract c = [ SELECT id FROM contract LIMIT 1 ];
		SBQQ__Quote__c cpq_Quote = [ SELECT id, SBQQ__Primary__c FROM SBQQ__Quote__c LIMIT 1 ];
		//Set Quote as Primary
		cpq_Quote.SBQQ__Primary__c = true;
		update cpq_Quote;
		opportunity o = [ SELECT id, AccountId, Name, StageName, CloseDate, SBQQ__PrimaryQuote__c, SBQQ__Contracted__c, Applied_Quote__c FROM opportunity LIMIT 1 ];

		PageReference pr = Page.OpportunityProgrammingHeirarchy; 
		pr.getParameters().put('contractId',c.id);
		pr.getParameters().put('appendToContractBoolean', 'false');
		List<ID> programmingList = new List<ID>();
		pr.getParameters().put('selectedKeys',JSON.serialize(programmingList));
		Test.setCurrentPageReference(pr);
		Test.startTest();

		OpportunityProgrammingHeirarchyExtension controller = new OpportunityProgrammingHeirarchyExtension(new ApexPages.StandardController(o));
		controller.saveTasks();
		controller.updateAsContracted();
		test.stopTest();
		
		opportunity opp = [ SELECT id, SBQQ__PrimaryQuote__c, SBQQ__Contracted__c FROM opportunity LIMIT 1 ];

        //Verify Contracted box is checked; if it is then the CPQ process should create a contract
		system.assert(opp.SBQQ__Contracted__c == true);
	}

	@isTest static void testSTP()
	{		
		contract c = [ SELECT id FROM contract LIMIT 1 ];
		opportunity o = [ SELECT id, AccountId, Name, StageName, CloseDate, SBQQ__PrimaryQuote__c, Applied_Quote__c FROM opportunity LIMIT 1 ];
		Quote spt_Quote = [ SELECT id, name, OpportunityId FROM Quote LIMIT 1 ];

		//Set Applied Quote (SPT) on Opportunity
		o.Applied_Quote__c = spt_Quote.id;
		update o;

		List<ID> programmingList = new List<ID>();
		List<Programming__c> listPrg = new List<Programming__c>();
        for(Programming__c recPrg: [ SELECT id FROM Programming__c ]) {   //Select Programming Lines
           programmingList.add(recPrg.id);
           recPrg.Opportunity__c = o.id;
           listPrg.add(recPrg);
        }
        update listPrg;  //Relate Programming to Opportunity

		PageReference pr = Page.OpportunityProgrammingHeirarchy; 
 		pr.getParameters().put('contractId',c.id);
        pr.getParameters().put('appendToContractBoolean', 'false');
		pr.getParameters().put('selectedKeys',JSON.serialize(programmingList));
		Test.setCurrentPageReference(pr);
		Test.startTest();

		OpportunityProgrammingHeirarchyExtension controller = new OpportunityProgrammingHeirarchyExtension(new ApexPages.StandardController(o));
		controller.loadContracts();
		controller.saveTasks();
		test.stopTest();
	}
}