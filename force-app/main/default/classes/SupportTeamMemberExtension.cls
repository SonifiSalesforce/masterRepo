public with sharing class SupportTeamMemberExtension {
    
    private ApexPages.StandardController            controller                              ;
    private Account                                 acct                                    ;
    private Id                                      supportOfficeId                         { get; private set; }
    
    public Boolean                                  isSupportOffice                         { get; private set; } 
    public Boolean                                  isEditMode                              { get { if (isEditMode == null) { isEditMode = false; } return isEditMode; } private set; }
    
    transient public Boolean                        hasPageError                            { get; private set; }
    public Boolean                                  displaySite                             { get; private set; }
    
    public String displayMode {
        get {
            if (isEditMode) { return 'inlineedit'; }
            return 'maindetail';
        }
        private set;
    }
    
    public SupportTeamMemberExtension(ApexPages.StandardController controller) {
        try {
            this.controller = controller;
            acct = (Account)controller.getRecord();
            
            //Check if account is a Hospitality or HealthCare Site
            Id HospitalitySiteTypeId = Utilities.RecordTypeNameToId('Account', Definitions.RECORDTYPE_Hospitality_Site);
            Id HealthCareSiteTypeId = Utilities.RecordTypeNameToId('Account', Definitions.RECORDTYPE_Healthcare_Site);
                 
            if((acct.RecordTypeId == HospitalitySiteTypeId) || (acct.RecordTypeId == HealthCareSiteTypeId)){
                displaySite = true;
                
                if(acct.Support_Office__c == null){
                ApexPages.addMessage(
                        new ApexPages.Message(ApexPages.Severity.INFO, 
                            '<b>No support office assigned to account.</b>', 
                            'To view support team members for this account, you must first assign a support office to the account.'));
                }
            } else {
                displaySite = false;
            }
            
            
            // Check if current account has a support office
            if (acct.Support_Office__c == null) {
                
                // Check if account IS a support office
                Id supportOfficeTypeId = Utilities.RecordTypeNameToId('Account', Definitions.RECORDTYPE_SupportOffice);
                
                 
                if (acct.RecordTypeId == supportOfficeTypeId) {
                    isSupportOffice = true;
                    supportOfficeId = acct.Id;
                }else {
                    hasPageError = true;
                    ApexPages.addMessage(
                        new ApexPages.Message(ApexPages.Severity.INFO, 
                            '<b>No support office assigned to account.</b>', 
                            'To view support team members for this account, you must first assign a support office to the account.'));
                }
            } else {
                supportOfficeId = acct.Support_Office__c;
            }
        }
        catch (Exception e) {
            hasPageError = true;
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR, 
                    '<b>Unable to read support office team members for account.</b>', e.getMessage()));
        }
    }
    
    /**
     * Gets the list of team members associated with the support office
     */
    public List<SupportOfficeMember__c> supportTeamMembers {
        get {
            if (supportTeamMembers == null || supportTeamMembers.isEmpty()) {
                if (supportOfficeId == null) { return null; }
                try {
                    supportTeamMembers = [
                        SELECT Id, Role__c, User__c,User__r.Name, Contact__c,Contact__r.Name, 
                            Phone__c, MobilePhone__c, Email__c, IsContact__c
                        FROM SupportOfficeMember__c
                        WHERE SupportOffice__c = :supportOfficeId
                    ];
                } catch (Exception e) {
                    hasPageError = true;
                    ApexPages.addMessage(
                        new ApexPages.Message(ApexPages.Severity.ERROR, 
                            '<b>Unable to read support office team members.</b>', e.getMessage()));
                }
                
                // Fill in list with missing roles
                Map<String, SupportOfficeMember__c> memberRoleMap = new Map<String, SupportOfficeMember__c>();
                for (SupportOfficeMember__c member : supportTeamMembers) {
                    memberRoleMap.put(member.Role__c, member);
                }
                
                List<AcountTeamRoles__c> teamRoles = AcountTeamRoles__c.getAll().values();
                
                // Check for display only site
                if (!displaySite) {
                    
                    for (AcountTeamRoles__c role : teamRoles) {
                        if (!memberRoleMap.containsKey(role.Name)) {
                            memberRoleMap.put(
                                role.Name, 
                                new SupportOfficeMember__c(
                                    Role__c = role.Name, 
                                    SupportOffice__c = supportOfficeId,
                                    IsContact__c = role.IsContact__c
                                ));
                        }
                    }
                }
                
                // Sort list
                supportTeamMembers = sortTeamMembers(memberRoleMap, teamRoles);
            }
            return supportTeamMembers;
        }
        set;
    }
    
    /**
     * Sorts the team member list based on time-of-day and day-of-week criteria established
     * in the Account Team Roles custom setting
     */
    private List<SupportOfficeMember__c> sortTeamMembers(
            Map<String, SupportOfficeMember__c> memberRoleMap, 
            List<AcountTeamRoles__c> teamRoles) {
        
        // Determine time of day at the SITE
        // Calculate seconds offset (within the same day)
        // NOTE Sites that do not support DST will be an hour LATER in DST months
        /*
        Integer siteDstOffset = (Definitions.IS_DST && !acct.Observes_DST__c) ? Definitions.DST_OFFSET : 0;
        DateTime curSiteTime; 
        if (acct.UTC_Offset__c != null) {
            curSiteTime = DateTime.now().addSeconds(acct.UTC_Offset__c.intValue() + siteDstOffset);
        } else {
             curSiteTime = DateTime.now();
        }
        */
        
        DateTime curSiteTime = DateTime.now();
        system.debug('curSiteTime = ' + curSiteTime);
        Integer userUtcOffset = Integer.valueOf(curSiteTime.hourGmt() - curSiteTime.hour()) * -3600;
        system.debug('userUtcOffset = ' + userUtcOffset);
        //jjackson 5/22/14 sitedstoffset is incorrectly set at 60 in Definitions but could not change it because
        //there is some job scheduled against that class and I would have to delete them all because I don't know
        //which one it is.  Therefore have to times dst offset (60) by 60 to get 3600 seconds for the offset.
        Integer siteDstOffset = (Definitions.IS_DST && acct.Observes_DST__c) ? Definitions.DST_OFFSET * 60 : 0;
        system.debug('siteDstOffset = ' + siteDstOffset);
        Integer secondsOffset;
        if (acct.UTC_Offset__c != null) {
            secondsOffset = (acct.UTC_Offset__c.intValue() + siteDstOffset) - userUtcOffset;
            //system.debug('first secondsOffset = ' + secondsOffset);
        } else {
            secondsOffset = userUtcOffset - siteDstOffset;
            //system.debug('second secondsOffset = ' + secondsOffset);
        }
        
        // Calculate time at site
        if (secondsOffset != 0) { curSiteTime = curSiteTime.addSeconds(secondsOffset); }
        system.debug('curSiteTime is ' + curSiteTime + 'for account ' + acct.ID);
        String roleIndexName;
        String curSiteDay = curSiteTime.format('EEEE').toUpperCase();
        if (curSiteDay == 'SUNDAY') {
            roleIndexName = 'Sunday_Order__c';
        } else if (curSiteDay == 'SATURDAY') {
            roleIndexName = 'Saturday_Order__c';
        } else if (curSiteTime.hour() >= 17 || curSiteTime.hour() < 8) {
            roleIndexName = 'After_Hours_Order__c';
        } else {
            roleIndexName = 'Normal_Hours_Order__c';
        }
        
        
       // System.debug('********************  SupportTeamMemberExtension.sortTeamMembers. DST OFFSET: ' + siteDstOffset);
       // System.debug('********************  SupportTeamMemberExtension.sortTeamMembers. USER OFFSET: ' + userUtcOffset);
       // System.debug('********************  SupportTeamMemberExtension.sortTeamMembers. SITE OFFSET: ' + acct.UTC_Offset__c.intValue());
       // System.debug('********************  SupportTeamMemberExtension.sortTeamMembers. USER CURRENT TIME: ' + DateTime.now().format());
       // System.debug('********************  SupportTeamMemberExtension.sortTeamMembers. SITE CURRENT TIME: ' + curSiteTime.format());
       // System.debug('********************  SupportTeamMemberExtension.sortTeamMembers. SITE CURRENT DAY: ' + curSiteTime.format('EEEE'));
       // System.debug('********************  SupportTeamMemberExtension.sortTeamMembers. SITE CURRENT HOUR: ' + curSiteTime.Hour());
       // System.debug('********************  SupportTeamMemberExtension.sortTeamMembers. ROLE INDEX NAME: ' + roleIndexName);
        
        
        // Get support team role and index values
        Map<Integer, String> roleMap = new Map<Integer, String>();
        for (AcountTeamRoles__c role : teamRoles) {
            Integer roleIndex;
            try { roleIndex = Integer.valueOf(role.get(roleIndexName)); }
            catch (Exception e) { roleIndex = 999; }
            roleMap.put(roleIndex, role.Name);
        }
        
        // Sort list of indices
        List<Integer> roleIndices = new List<Integer>(roleMap.keyset());
        roleIndices.sort();
        
        // Rebuild support team list in order
        List<SupportOfficeMember__c> sortedList = new List<SupportOfficeMember__c>();
        for (Integer roleIndex : roleIndices) {
            String roleName = roleMap.get(roleIndex);
            if (memberRoleMap.containsKey(roleName)) {
                sortedList.add(memberRoleMap.get(roleName));
            }
        }
        
        return sortedList;
    }
    
    /**
     * Extends standard edit functionality
     */
    public PageReference edit() {
        isEditMode = true;
        return null;
    }
    
    /**
     * Extends standard cancel functionality
     */
    public PageReference cancel() {
        isEditMode = false;
        return null;
    }
    
    /**
     * Extends standard save functionality
     */
    public PageReference save() {
        
        List<SupportOfficeMember__c> deletedMembers = new List<SupportOfficeMember__c>();
        List<SupportOfficeMember__c> updatedMembers = new List<SupportOfficeMember__c>();
        for (SupportOfficeMember__c member : supportTeamMembers) {
            if (member.User__c != null || member.Contact__c != null) {
                System.debug('Updating Member ' + member.Role__c + ' - ' + member);
                updatedMembers.add(member);
            } else if (member.Id != null) {
                System.debug('Deleting Member ' + member.Role__c + ' - ' + member);
                deletedMembers.add(member);
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            if (!updatedMembers.isEmpty()) { upsert updatedMembers; }
            if (!deletedMembers.isEmpty()) { 
                
                delete deletedMembers;
                
                // When a member is deleted, we need to re-get the list
                // so that we don't have a deleted member Id in the list
                supportTeamMembers = null; 
            }
        }
        catch (Exception e) {
            Database.rollback(sp);
            supportTeamMembers = null;
            hasPageError = true;
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR, 
                    '<b>Failed to save changes to the support team members.</b>', e.getMessage()));
        }
        
        isEditMode = false;
        return null;
    }
}