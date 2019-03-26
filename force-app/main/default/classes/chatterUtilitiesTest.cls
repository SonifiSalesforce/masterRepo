@isTest
public class chatterUtilitiesTest
{
    static testMethod void testdoChatterPosts()
    {
        Datetime starttime = Datetime.now();
        List<User> users = DataGenerator.createUsers('System Administrator', 100, true);
        Map<Id,String> chatMap = new Map<Id, String>();
        for (User user :users) {
              System.debug('=== ' + user.Name);
              chatMap.put(user.Id,'Testing Chatter post');  
        }
        
        Test.startTest();
            ChatterUtilities.doChatterPosts(chatMap);    
       
   		    List<FeedItem> feedItems = [SELECT Id,ParentId  from FeedItem WHERE CreatedDate >= :starttime];  
            System.debug('Total feed items === ' + feedItems.size());
            for (Integer i = 0; i < feedItems.size(); i++) {
                System.debug('=== ' + feedItems[i].Id + ' parent '+feedItems[i].ParentId);
            }    
    	Test.stopTest();
        // system.assert(feedItems.size() == 0,'NO items where posted to Chatter');
  	    system.assertEquals(users.size(),feedItems.size(),'Not enough chatter events where posted');    	          
    }

}