public with sharing class FlashNotificationListController {

	public Id theAccountId { get; set; }
    
	/**
	 * Read and return flash notifications
	 */
	public List<CustomFlashNotificationLogic.FlashNotification> flashNotifications {
		
		get {
			if (flashNotifications == null || flashNotifications.isEmpty()) {
				if (theAccountId == null) { return null; }
				try { flashNotifications = CustomFlashNotificationLogic.GetFlashNotifications(theAccountId); }
				catch (Exception e) {}
			}
			return flashNotifications;
		}
		private set;
    }
}