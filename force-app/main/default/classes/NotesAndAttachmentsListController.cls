// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Class for implementing functionalities to support custom Notes & Attachments
//				 list components.
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class NotesAndAttachmentsListController extends CustomListController {
	
    public List<NoteAndAttachment> getRecordList() {
        if (recordList == null) {
        	if (parentObject == null) { return null; }
			Utilities.writeLog(
					'Reading notes and attachments for ' + parentObjectName + '(' + parentObject.Id + ')...', 
					NotesAndAttachmentsListController.class, 'records', LoggingLevel.DEBUG);
        	String query = 
        		'SELECT '
        		+ 	'(SELECT Id, CreatedById, CreatedBy.Name, '
        		+   'LastModifiedDate, Title, IsNote '
        		+ 	'FROM NotesAndAttachments '
        		+ 	'ORDER BY LastModifiedDate DESC ';
        	
        	// Check showAll flag
        	// TODO Consider adding paging if record set is going to get big for this query
        	if (!showAllRecords) { query += 'LIMIT 5'; }
        	
        	query += ') '
        		+ 'FROM ' + parentObjectName + ' '
        		+ 'WHERE Id = \'' + parentObject.Id + '\'';
        		
			try { 
				recordList = Utilities.getRelatedListData(query, 'NotesAndAttachments');
				if (recordList == null) { return null; }
			}
			catch (Exception e) { /* The page will handle empty dataset situations */ }
        }
        return recordList;
    }
}