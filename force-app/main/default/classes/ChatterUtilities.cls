// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Class for co-locating Chatter utility methods
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class ChatterUtilities {
	
	public static void doChatterPosts (Map<Id,String> chatterData) {
		
        List<FeedItem> feedItems = new List<FeedItem>();                         
        for (Id parentId : chatterData.keyset()){
           	FeedItem fitem = new FeedItem();
           	fItem.parentId = parentId;
           	fItem.type = 'TextPost';
           	fItem.body = chatterData.get(parentId);
        	feedItems.add(fitem);    
        }
     
        if(feedItems.size() > 0){
        	Savepoint sp = Database.setSavepoint();
            
            try {
                insert feedItems;
            } catch (Exception e) {
                Database.rollback(sp);
                throw e;
            }             
        }     
    }
}