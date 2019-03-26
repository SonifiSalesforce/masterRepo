public with sharing class CaseLegalEntityExtensionController {

    public class LegalEntityWrapper{
        public String partnerId{get;set;}
        public String partnerName{get;set;}
        public String partnerRole{get;set;}
        public String partnerAddress{get;set;}
    }
    
    public Case c;
    public String partnerId{get;set;}
    
    public CaseLegalEntityExtensionController(ApexPages.StandardController controller)
    {
        this.c = (Case)controller.getRecord();
    }
    
    public List<LegalEntityWrapper> getSitePartnerAccounts()
    {
        //Querying Account of Case
        String caseAccountId = [SELECT AccountID from Case where Id = :c.Id].AccountId;
        //Querying the related Site Partners of the related Account on Case
        List<Site_Partner__c> sitePartners = [SELECT Partner__c,Partner_Role__c from Site_Partner__c WHERE Site__c = :caseAccountId];
        List<ID> partnerAccountIDs = new List<ID>();
        for(Site_Partner__c sp : sitePartners)
        {
            partnerAccountIDs.add(sp.Partner__c);
        }
        //Querying list of Accounts to display from queried Site Partners
        Map<Id,Account> partnerAccounts = new Map<Id,Account>([SELECT Name,Physical_Street_Address_Line_1__c, Physical_City__c, Physical_State__c, Physical_Postal_Code__c from Account WHERE ID IN :partnerAccountIDs]);
        List<LegalEntityWrapper> lewList = new List<LegalEntityWrapper>();
        //Preparing wrapper list to send to Page
        for(Site_Partner__c sp : sitePartners)
        {
            Account partnerAcc = partnerAccounts.get(sp.Partner__c);
            LegalEntityWrapper lew = new LegalEntityWrapper();
            if(partnerAcc != null)
            {
                lew.partnerId = partnerAcc.Id;
                lew.partnerName = partnerAcc.Name;
                lew.partnerRole = sp.Partner_Role__c;
            
                String fullPhysicalAddress = partnerAcc.Physical_Street_Address_Line_1__c;
                if(partnerAcc.Physical_City__c != null)
                    fullPhysicalAddress += ' , '+partnerAcc.Physical_City__c;
                if(partnerAcc.Physical_State__c != null)
                    fullPhysicalAddress += ' , '+partnerAcc.Physical_State__c;
                if(partnerAcc.Physical_Postal_Code__c != null)
                    fullPhysicalAddress += ' , '+partnerAcc.Physical_Postal_Code__c;
                lew.partnerAddress = fullPhysicalAddress;
            }
            lewList.add(lew);
        }
        return lewList;
    }
}