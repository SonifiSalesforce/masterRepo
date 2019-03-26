public with sharing class SiteSurveyPhotoController 
{
    public List<SitePhotoWrapper> photos{get;set;}
    public class SitePhotoWrapper
    {
        public String Name{get;set;}
        public String PhotoGroup{get;set;}
        public String Type{get;set;}
        public String downloadUrl{get;set;}
        public String imageUrl{get;set;}  
        public String description{get;set;}
        public String spId{get;set;}      
    }
    
    public Id ssId{get;set;}

    public SiteSurveyPhotoController(ApexPages.StandardController controller)
    {
        this.ssId = ((Site_Survey__c)controller.getRecord()).Id;
        this.photos = retrievePhotos(); 
    }
    public List<SitePhotoWrapper> retrievePhotos()
    {
        ID siteSurveyPhotoRecordTypeId = Utilities.RecordTypeNameToId('Site_Photo__c', 'Site Survey');
        List<SitePhotoWrapper> wrapList = new List<SitePhotoWrapper>();
        List<Site_Photo__c> spList = [SELECT Id, Name, Photo_Comment__c, Photo_Name__c, Photo_Group__c, Photo_Type__c, Feed_Item_Id__c FROM Site_Photo__c 
        WHERE Site_Survey__c= :ssId AND RecordTypeId = :siteSurveyPhotoRecordTypeId];
        
        if(spList.size() > 0)
        {
            Set<ID> spListIDs = new Set<Id>();
            Map<Id,ConnectApi.FeedItem> cafiList = new Map<Id,ConnectApi.FeedItem>();
            for(Site_Photo__c sp : spList)
            {
                spListIDs.add(sp.Feed_Item_Id__c);
                try{
                    cafiList.put(sp.Id,ConnectApi.ChatterFeeds.getFeedItem(null,sp.Feed_Item_Id__c));
                }
                catch(Exception e){spListIDs.remove(sp.Feed_Item_Id__c);}
            }

            Map<Id,FeedItem> fiMap= new Map<Id,FeedItem>([SELECT Id, ContentData from FeedItem WHERE Id IN :spListIDs]);

            Map<Id,FeedItem> cdMap = new Map<Id,FeedItem>();
            
            for(FeedItem cdl : fiMap.values())
            {
                cdMap.put(cdl.Id, cdl);
            }
            

            for(Site_Photo__c sp : spList)
            {
                SitePhotoWrapper w = new SitePhotoWrapper();
                w.Name = sp.Photo_Name__c;
                w.PhotoGroup= sp.Photo_Group__c;
                w.Type = sp.Photo_type__c;
                w.description = sp.Photo_Comment__c;
                w.spId = sp.Id;
                if(cafiList.get(sp.Id) != null && cafiList.get(sp.Id).attachment != null)
                {
                    w.imageUrl = ((ConnectApi.ContentAttachment)(cafiList.get(sp.Id).attachment)).renditionUrl;
                }
                if(cafiList.get(sp.Id) != null && cafiList.get(sp.Id).attachment != null)
                {
                    w.downloadUrl = ((ConnectApi.ContentAttachment)(cafiList.get(sp.Id).attachment)).downloadUrl;
                }
                wraplist.add(w);
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                                 '<b>No Site Photos available for this Site Survey.</b>', 
                                 'To view site photos for this account, you must first add a site photo to the Site Survey.'));
        }

        return wrapList;        
    }
    
}