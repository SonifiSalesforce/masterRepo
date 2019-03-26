// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Class for implementing functionalities to support custom Activity 
//				 list components
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class ActivityListController extends CustomListController {
    
    public static final Integer 			COMPACT_LIST_RECORD_COUNT 			= 5;
    public static final Integer 			FULL_LIST_RECORD_COUNT 				= 100;
    
    public class CustomActivity {

    	public Id							ActivityId							{ get; set; }
    	public DateTime 					ActivityDate						{ get; set; }
    	public String 						Subject								{ get; set; }
    	public String						Status								{ get; set; }
    	public String						Priority							{ get; set; }
    	public Boolean 						IsTask								{ get; set; }
    	public Id 							OwnerId								{ get; set; }
    	public String						OwnerName							{ get; set; }
    	
    	public CustomActivity() { IsTask = false; }
    }
    
    private List<CustomActivity> activities;
    
    /**
     *
     */
    public List<CustomActivity> getRecordList() {
        if (activities == null) {
        	if (parentObject == null) { return null; }
			Utilities.writeLog(
					'Reading activity  for ' + parentObjectName + '(' + parentObject.Id + ')...', 
					ActivityListController.class, 'getRecordList', LoggingLevel.DEBUG);
			
        	// Check showAll flag
        	// TODO Consider adding paging if record set is going to get big for this query
        	Integer recordsToRead = (showAllRecords ? FULL_LIST_RECORD_COUNT : COMPACT_LIST_RECORD_COUNT);
        	
    		activities = new List<CustomActivity>();

        	String query;
        	Map<Id, CustomActivity> activitiesMap = new Map<Id, CustomActivity>();
        	
        	List<Task> tasks;
        	try {
        		query = 
        			'SELECT '
        				+ '(SELECT Id, OwnerId, Owner.Name, ActivityDate, Subject, Status '
        				+ 'FROM Tasks '
		        		+ 'ORDER BY ActivityDate DESC, LastModifiedDate DESC '
        				+ 'LIMIT ' + recordsToRead + ') '
	        		+ 'FROM ' + parentObjectName + ' '
	        		+ 'WHERE Id = \'' + parentObject.Id + '\'';
				Utilities.writeLog(
						'Reading TASK activities for ' + parentObjectName + '(' + parentObject.Id + '). Query: ' + query, 
						ActivityListController.class, 'getRecordList', LoggingLevel.DEBUG);
	        	tasks = (List<Task>)Utilities.getRelatedListData(query, 'Tasks');
	        	
	        	if (tasks != null && !tasks.isEmpty()) {
		        	for (Task t : tasks) {
		        		CustomActivity a = new CustomActivity();
		        		a.ActivityId = t.Id;
		        		a.IsTask = true;
		        		a.Subject = t.Subject;
		        		a.Status = t.Status;
		        		a.ActivityDate = t.ActivityDate;
		        		a.OwnerId = t.OwnerId;
		        		a.OwnerName = t.Owner.Name;
		        		activities.add(a);
		        		activitiesMap.put(a.ActivityId, a);
		        	}
	        	}
	        	
        	} catch (Exception e) {
				Utilities.writeLog(
						'Failed to read TASK activities for ' + parentObjectName + '. Details: ' + e.getMessage(), 
						ActivityListController.class, 'getRecordList', LoggingLevel.WARN);
        	}
        	
        	// Adjust records to read if not showing all
        	if (!showAllRecords) { recordsToRead -= activitiesMap.size(); }
        	
        	if (recordsToRead > 0) {
        		
	        	List<Event> events;
	        	try {
	        		query = 
	        			'SELECT '
	        				+ '(SELECT Id, OwnerId, Owner.Name, ActivityDate, Subject '
	        				+ 'FROM Events '
			        		+ 'ORDER BY ActivityDate DESC, LastModifiedDate DESC '
	        				+ 'LIMIT ' + recordsToRead + ') '
		        		+ 'FROM ' + parentObjectName + ' '
		        		+ 'WHERE Id = \'' + parentObject.Id + '\'';
					Utilities.writeLog(
							'Reading EVENT activities for ' + parentObjectName + '(' + parentObject.Id + '). Query: ' + query, 
							ActivityListController.class, 'getRecordList', LoggingLevel.DEBUG);
		        	events = (List<Event>)Utilities.getRelatedListData(query, 'Events');
		        	
		        	if (events != null && !events.isEmpty()) {
			        	for (Event evt : events) {
			        		CustomActivity a = new CustomActivity();
			        		a.ActivityId = evt.Id;
			        		a.Subject = evt.Subject;
			        		a.ActivityDate = evt.ActivityDate;
			        		a.OwnerId = evt.OwnerId;
			        		a.OwnerName = evt.Owner.Name;
			        		activities.add(a);
			        		activitiesMap.put(a.ActivityId, a);
			        	}
		        	}
		        	
	        	} catch (Exception e) {
					Utilities.writeLog(
							'Failed to read EVENT activities for ' + parentObjectName + '. Details: ' + e.getMessage(), 
							ActivityListController.class, 'getRecordList', LoggingLevel.WARN);
	        	}
        	}
        	
        	// Adjust records to read if not showing all
        	if (!showAllRecords) { recordsToRead -= activitiesMap.size(); }
        	
        	if (recordsToRead > 0) {
        		
	    		List<ActivityHistory> histories;
	        	try {
	        		query = 
	        			'SELECT '
	        				+ '(SELECT Id, OwnerId, Owner.Name, ActivityDate, Subject, IsTask '
			        		+ 'FROM ActivityHistories '
			        		+ 'ORDER BY ActivityDate DESC, LastModifiedDate DESC '
	        				+ 'LIMIT ' + recordsToRead + ') '
		        		+ 'FROM ' + parentObjectName + ' '
		        		+ 'WHERE Id = \'' + parentObject.Id + '\'';
					Utilities.writeLog(
							'Reading HISTORIC activities for ' + parentObjectName + '(' + parentObject.Id + '). Query: ' + query, 
							ActivityListController.class, 'getRecordList', LoggingLevel.DEBUG);
		        	histories = (List<ActivityHistory>)Utilities.getRelatedListData(query, 'ActivityHistories');
		        	
		        	if (histories != null && !histories.isEmpty()) {
			        	for (ActivityHistory ah : histories) {
			        		// Check to prevent duplication when duplicate records 
			        		// are retrieved in both current and historic activities.
			        		if (!activitiesMap.containsKey(ah.Id)) {
				        		CustomActivity a = new CustomActivity();
				        		a.ActivityId = ah.Id;
				        		a.Subject = ah.Subject;
				        		a.ActivityDate = ah.ActivityDate;
				        		a.OwnerId = ah.OwnerId;
				        		a.OwnerName = ah.Owner.Name;
				        		activities.add(a);
			        		}
			        	}
		        	}
		        	
	        	} catch (Exception e) {
					Utilities.writeLog(
							'Failed to read HISTORIC activities for ' + parentObjectName + '. Details: ' + e.getMessage(), 
							ActivityListController.class, 'getRecordList', LoggingLevel.WARN);
	        	}
        	}
        }
        
        return activities;
    }
}