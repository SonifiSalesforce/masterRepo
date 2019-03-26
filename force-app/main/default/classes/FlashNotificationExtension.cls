public with sharing class FlashNotificationExtension {
	
	public final Account acct;
    
	/**
	 * Constructor
	 */
    public FlashNotificationExtension(ApexPages.StandardController controller) {
        try { acct = new Account(Id=((Case)controller.getRecord()).AccountId); }
        catch (Exception e) {}
    }
	
	/**
	 * Read and return flash notifications
	 */
	public List<CustomFlashNotificationLogic.FlashNotification> flashNotifications {
		
		get {
			if (flashNotifications == null || flashNotifications.isEmpty()) {
				if (acct == null || acct.Id == null) { return null; }
				try { flashNotifications = CustomFlashNotificationLogic.GetFlashNotifications(acct.Id); }
				catch (Exception e) {}
			}
			return flashNotifications;
		}
		private set;
    }
}