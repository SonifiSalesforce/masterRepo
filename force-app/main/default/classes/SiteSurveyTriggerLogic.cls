public with sharing class SiteSurveyTriggerLogic {
/*
	//after insert on Site_Survey__c
	public static void cloneTVType(List<Site_Survey__c> siteList) {
		//initialize variables
		List<TV_Type__c> tvList = new List<TV_Type__c>();
		List<TV_Type__c> tvNewList = new List<TV_Type__c>();
		Set<String> accIds = new Set<String>();
		TV_Type__c tempTv;
		Map<Id, List<TV_Type__c>> id2TvMap = new Map<Id, List<TV_Type__c>>();
		
		//get all the account ids so you can query for the tv type
		for(Site_Survey__c site : siteList) {
			accIds.add(site.AccountId__c);
		}
		SYstem.debug('Account ids are ' + accIds);
		
		//get all the fields that need to be queried
		String fieldQuery = String.join( SiteSurveyExtension.getSObjectFields(TV_Type__c.getSObjectType()), ',');
		System.debug('Field Querys are ' + fieldQuery);
		tvList = Database.query('SELECT ' + fieldQuery + ' FROM TV_Type__c WHERE Site__c IN :accIds');
		System.debug('Tv list is ' + tvList);
		
		//map the account id to the tv types
		for(TV_Type__c tv : tvList) {
			if(id2TvMap.containsKey(tv.Site__c)) {
				id2TvMap.get(tv.Site__c).add(tv);
			} else {
				id2TvMap.put(tv.Site__c, new List<TV_Type__c>{tv});
			}
		}
		System.debug('Map is ' + id2TvMap);
		
		//go through the site survey
		for(Site_Survey__c site : siteList) {
			if( id2TvMap.containsKey(site.AccountId__c)) {
				for(TV_Type__c tv : id2TvMap.get(site.AccountID__c) ) {
					tempTv = tv.clone(false, true);
					tempTv.Site_Survey__c = site.id;
					tvNewList.add(tempTv);
				}
			}
		}
		System.debug('Tvs about to be inserted: ' + tvNewList);
		
		//insert dup tv records
		if( tvNewList.size() != 0 ) {
			insert tvNewList;
		}
	}
	
	*/
	
/*	jjackson 2/2016  Changes in business practices require more than one survey on an opportunity
	public static void noDuplicateSiteSurvey(List<Site_Survey__c> newSiteList) {

		//initialize variables
		List<Site_Survey__c> siteCreatedList = new List<Site_Survey__c>();
		List<Site_Survey__c> upsertList = new List<Site_Survey__c>();
		Set<Id> oppIds = new Set<Id>();
		Map<Id, List<Site_Survey__c>> oppId2SitesMap = new Map<Id, List<Site_Survey__c>>();
		
		//create set of opportunity ids
		for(Site_Survey__c site : newSiteList){
			oppIds.add(site.Opportunity__c);
		}
		
		//query for the site surveys
		if(oppIds.size() > 0){
			siteCreatedList = [SELECT Id, Opportunity__c FROM Site_Survey__c WHERE Opportunity__c IN :oppIds ];
		}
		
		//map the opportunity id to the site surveys
		for(Site_Survey__c site : siteCreatedList) {
			if(oppId2SitesMap.containsKey(site.Opportunity__c)){
				oppId2SitesMap.get(site.Opportunity__c).add(site);
			} else {
				oppId2SitesMap.put(site.Opportunity__c, new List<Site_Survey__c>{site});
			}
		}
		
		//go through possible insert site surveys and make sure there isnt a pre-existent site survey looking up to opportunity
		for(Site_Survey__c site : newSiteList) {
			if( oppId2SitesMap.containsKey(site.Opportunity__c) && site.Opportunity__c != null) {
				//ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Site Already exists on Opportunity: ' + site.Opportunity__c));
				site.addError('Site Survey already exists on Opportunity');
				Utilities.writeLog('Site Already exists on Opportunity: ' + site.Opportunity__c,
					SiteSurveyTriggerLogic.class, 'noDuplicateSiteSurvey', LoggingLevel.DEBUG);
			}
		}
	}
	*/
	
	//update the bids approval status if site survey approval status changes
	public static void updateRelatedBids(Map<Id, Site_Survey__c> oldMap, Map<Id, Site_Survey__c> newMap){
		//intialize var
		Set<Id> siteSurveyIds = new Set<Id>();
		List<Bid__c> bids = new List<Bid__c>();
		
		//check to see if the site survey approval status field has changed
		for(Id b : newMap.KeySet()){
			if(oldMap.get(b).Approval_Status__c != newMap.get(b).Approval_Status__c){
				siteSurveyIds.add(b);
			}
		}
		
		//query for the bids
		bids = [SELECT id, Site_Survey__c, Approval_Status__c FROM Bid__c WHERE Site_Survey__c IN:siteSurveyIds];
		
		//update status
		for(Bid__c bid : bids){
			bid.Approval_Status__c = newMap.get(bid.Site_Survey__c).Approval_Status__c;
		}
		
		//update bids
		update bids;
	}
	
	//update the Part list approval status if site survey approval status changes
	public static void updateRelatedPartList(Map<Id, Site_Survey__c> oldMap, Map<Id, Site_Survey__c> newMap){
		//intialize var
		Set<Id> siteSurveyIds = new Set<Id>();
		List<Part_List__c> parts = new List<Part_List__c>();
		
		//check to see if the site survey approval status field has changed
		for(Id b : newMap.KeySet()){
			if(oldMap.get(b).Approval_Status__c != newMap.get(b).Approval_Status__c){
				siteSurveyIds.add(b);
			}
		}
		
		//query for the bids
		parts = [SELECT id, Site_Survey__c, Approval_Status__c FROM Part_List__c WHERE Site_Survey__c IN:siteSurveyIds];
		
		//update status
		for(Part_List__c part : parts){
			part.Approval_Status__c = newMap.get(part.Site_Survey__c).Approval_Status__c;
		}
		
		//update bids
		update parts;
	}
	
	public static void updateOwner(Map<Id, Site_Survey__c> oldMap, List<Site_Survey__c> newRecords){
		
		Set<ID> contactIds = new Set<ID>();
		Map<Id,Site_Survey__c> updateSiteSurveys = new Map<Id,Site_Survey__c>();
		
		for(Site_Survey__c siteSurvey : newRecords){
			if(siteSurvey.Assign_Record__c == true && siteSurvey.Crew_Person_Turnkey__c != null){
				contactIds.add(siteSurvey.Crew_Person_Turnkey__c);
				updateSiteSurveys.put(siteSurvey.Id, siteSurvey);
			}
		}
		
		List<User> ownerUsers = [SELECT u.Id, u.Name, u.ContactId FROM User u WHERE u.ContactId IN :contactIds];
		
		Map<ID, User> contactUserMap = new Map<ID, User>();
		for(User ownerUser : ownerUsers){
			contactUserMap.put(ownerUser.ContactId, ownerUser);
		}
		
		for(Site_Survey__c updateSiteSurvey : newRecords) {
			if(updateSiteSurvey.Assign_Record__c == true && updateSiteSurveys.containsKey(updateSiteSurvey.Id)){
				if(contactUserMap.containsKey(updateSiteSurvey.Crew_Person_Turnkey__c)){
					updateSiteSurvey.OwnerId = contactUserMap.get(updateSiteSurvey.Crew_Person_Turnkey__c).Id;
				}
			}
			updateSiteSurvey.Assign_Record__c = false;			
		}
	}
}