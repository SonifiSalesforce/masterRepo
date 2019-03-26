// *********************************************************************************************
// Filename:     Trigger_Attachmentobject
// Version:      0.0.1
// Author:       Etherios
// Date Created: 09/08/2012
// Description:  Trigger on Attachment object to flag a record when there is an attachment, 
//               unflag when there is none and prevent deletion by user.
//          
//  
// Copyright 2012 Etherios. All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

trigger StandardAttachmentTrigger on Attachment (before delete) {
	
	// Check for trigger processing blocked by custom setting
    try{ 
    	if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
    		return;
    	} else if(AttachmentTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
			return; 
		}
    }
    catch (Exception e) {}
	
    Attachment [] oldAttachments = Trigger.old;

    // Check for attachments to process
    if (oldAttachments == null || oldAttachments.isEmpty()) { return; }
    
    // Process attachments
    AttachmentTriggerLogic.BeforeDeleteAttachment(oldAttachments);
}