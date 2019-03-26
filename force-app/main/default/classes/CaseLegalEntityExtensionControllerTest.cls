@isTest
public class CaseLegalEntityExtensionControllerTest
{
    static testMethod void getSitePartnerTest()
    {
        Account acc = DataGenerator.createAccounts(1,true)[0];
        Account partner = DataGenerator.createAccounts(1,true)[0];
        Case c = (Case)DataGenerator.createSObjectWithDefaultValues('Case');
        c.AccountId = acc.id;
        insert c;
        Site_Partner__c sp = new Site_Partner__c();
        sp.Site__c = acc.Id;
        sp.Partner__c = partner.Id;
        insert sp;
        PageReference pr = Page.CaseLegalEntities;
        pr.getParameters().put('id',c.id);
        Test.setCurrentPageReference(pr);
        Test.startTest();
        CaseLegalEntityExtensionController controller = new CaseLegalEntityExtensionController(new ApexPages.StandardController(c));
        List<CaseLegalEntityExtensionController.LegalEntityWrapper> wrapList = controller.getSitePartnerAccounts();
        Test.stopTest();
        system.assert(wrapList.size() == 1);
           
    }
}