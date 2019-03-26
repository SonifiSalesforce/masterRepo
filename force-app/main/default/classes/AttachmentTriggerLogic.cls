// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/02/2013
// Description:  Class for Trigger on Attachment Object
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class AttachmentTriggerLogic {
	
	public static final String DELETE_PERMISSIONS_ERROR = 'You do not have the permission to delete attachments.';
	
	// Trigger handler 
	public static void BeforeDeleteAttachment (Attachment[] attachments){
		
		// Validate incoming params
		if (attachments == null || attachments.isEmpty()) { return; }
		
		// Check if profile or user is allowed to delete
        if (checkAttachmentDeletePermission()) { return; }		// User can delete.
        
        // Neither profile nor user are allowed to delete attachments. Set error flag and bail.
		for(Attachment doc: attachments){
			doc.adderror(DELETE_PERMISSIONS_ERROR);
		}
	}
	
	// Checks to see if the user has the delete permission on attachments 
	// when someone tries to delete a standard Attachment
	public static Boolean checkAttachmentDeletePermission() {
		
		// Retrieve profile-level setting
        AttachmentDeletePermission__c permissionsObject = 
        		AttachmentDeletePermission__c.getInstance(UserInfo.getProfileId());
        Boolean profileCanDelete = permissionsObject.Can_Delete_Attachments__c;
        
        // Retrieve user-level setting
        permissionsObject = AttachmentDeletePermission__c.getInstance(UserInfo.getUserId());
        Boolean userCanDelete = permissionsObject.Can_Delete_Attachments__c;
        
        /*
        // Check if user is forcibly DISALLOWED from deleting
        if (permissionsObject.Id != null && !userCanDelete) {
        	// User-level override exists. User cannot delete.
        	return false;
        }
        */
        
		// Check if profile or user is allowed to delete
		return (profileCanDelete || userCandelete);
	}
}