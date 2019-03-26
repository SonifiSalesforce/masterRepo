public with sharing class CaseInteractionHistoryExtension  {
	
	public final Case theCase;
     
	/**
	 * Constructor
	 */
    public CaseInteractionHistoryExtension(ApexPages.StandardController controller) {
        try { theCase = (Case)controller.getRecord(); }
        catch (Exception e) {}
    }
    
	/**
	 * Read and return the case interaction history
	 */
	public List<CustomCaseLogic.CaseInteractionHistory> historyList {
		get {
			if (historyList == null) {
				if (theCase == null || theCase.Id == null) { return null; }
				try { 
					historyList = CustomCaseLogic.GetCaseInteractionHistory(theCase.Id);
					for (CustomCaseLogic.CaseInteractionHistory record : historyList) {
						record.details = record.details.replace('\n', '<br/>');
					} 
				}
				catch (Exception e) {}
			}
			return historyList;
		}
		private set;
	}
}