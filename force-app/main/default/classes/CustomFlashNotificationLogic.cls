global with sharing class CustomFlashNotificationLogic {

    global class FlashNotification {
        public Id                                   flashId                                 { get; set; }
        public String                               subject                                 { get; set; }
        public String                               description                             { get; set; }
        public Boolean                              isUrgent                                { get; set; }
        public Boolean                              neverExpires                            { get; set; }
        public String                               startDateFormatted                      { get; set; }
        public String                               endDateFormatted                        { get; set; }
        
        public void setStartDate(Date startDate) {
            if (startDate == null) { 
                startDateFormatted = '';
            } else {
                startDateFormatted = startDate.format();
            }
        }
        
        public void setEndDate(Date endDate, Boolean neverExpires) {
            if (neverExpires) { 
                endDateFormatted = 'Never Expires'; 
            } else if (endDate == null) {
                endDateFormatted = '';
            } else {
                endDateFormatted = endDate.format();
            }
        }
    }
    
    /**
     * 
     */
    global static List<FlashNotification> GetFlashNotifications(Id accountId) {
        
        // Check for account Id passed
        if (accountId == null) { return null; }
        
        // Read flash notifications for account
        List<FlashNotification> flashList = new List<FlashNotification>();
        try {
            for (Flash_Notification__c item : [
                            SELECT Id, Name, Subject__c, Urgent__c, 
                                 Start_Date__c, End_Date__c, Never_Expires__c, Description__c
                            FROM Flash_Notification__c
                            WHERE Account__c = :accountId
                              AND (Never_Expires__c = true OR End_Date__c >= :Date.today())
                            ORDER BY Urgent__c DESC, Never_Expires__c DESC, End_Date__c ASC
                         ]) {
                
                FlashNotification flash = new FlashNotification();
                flash.flashId = item.Id;
                flash.subject = item.Subject__c == null ? '' : item.Subject__c;
                flash.description = item.Description__c == null ? '' : item.Description__c;
                flash.isUrgent = item.Urgent__c == null ? false : item.Urgent__c;
                flash.neverExpires = item.Never_Expires__c == null ? false : item.Never_Expires__c;
                flash.setStartDate(item.Start_Date__c);
                flash.setEndDate(item.End_Date__c, flash.neverExpires);
                
                flashList.add(flash);
            }
        } catch (Exception e) {}
        
        // Return results
        return flashList;
    }
    
}