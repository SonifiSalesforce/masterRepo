@isTest(SeeAllData=true) //ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true).
public class AccountSitePhotoExtensionTest
{
    static testMethod void getPhotoTest()
    {
        Account a = DataGenerator.createAccounts(1,true)[0];
        ID installPhotoRecordTypeId = Utilities.RecordTypeNameToId('Site_Photo__c', 'Installation');
        Site_Photo__c sp = new Site_Photo__c(
        Site__c = a.Id,
        Photo_Group__c = 'FTG',
        Photo_Type__c = 'FTG Rack - Front View',
        RecordTypeId=installPhotoRecordTypeId);
        insert sp;
        FeedItem fi = new FeedItem(
        Body='Test FeedItem body',
        ParentId = sp.Id);
        insert fi;
        sp.Feed_Item_Id__c = fi.Id;
        update sp;
        PageReference pr = Page.AccountSitePhoto;
        pr.getParameters().put('id',a.Id);
        Test.setCurrentPageReference(pr);
        Test.startTest();
        AccountSitePhotoExtension controller = new AccountSitePhotoExtension(new ApexPages.StandardController(a));
        List<AccountSitePhotoExtension.SitePhotoWrapper> wrapList = controller.photos;
        Test.stopTest();
        system.assert(wrapList.size() == 1, 'There should be one item in the returned list of Wrappers');
        
    }
        
}