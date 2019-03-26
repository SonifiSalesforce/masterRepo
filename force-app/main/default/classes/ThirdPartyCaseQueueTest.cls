@IsTest
public class ThirdPartyCaseQueueTest {
	
   public static TestMethod void testThirdPartyCaseQueue()
   {
   	  Group testqueue = new Group(Type='Queue', Name='Third Party Cases TEST', DeveloperName='Third_Party_Cases_TEST');
   	  insert testqueue;
   	  
   	  Id uid = UserInfo.getUserId();
   	  String lastname = UserInfo.getLastName();
   	  String firstname = UserInfo.getFirstName();
   	  User thisuser = [Select Id, firstname, lastname, profileid from User where id = :uid LIMIT 1 ];
   	  List<User> lstfieldusers = [Select Id, firstname, lastname, email,mobilephone, profileid, profile.name from user where profile.name = 'Field Sr. Manager' ];
   	  system.debug('lstfieldusers size is ' +lstfieldusers.size());                
   	  
   	  GroupMember member = New Groupmember(UserOrGroupId=uid, GroupId=testqueue.id);
   	  insert member;
   
      PageReference pageRef = Page.ThirdPartyCaseQueueManagement;
      Test.setCurrentPage(pageRef);
      
      ThirdPartyCaseQueueManagement controller = new ThirdPartyCaseQueueManagement();
      controller.qname = 'Third Party Cases TEST';
      controller.GetQueueMembers();
      
      controller.CreateCheckedTechList(lstfieldusers);
  
      
      controller.searchlast = lstfieldusers[0].lastname;
      controller.searchfirst = '';
      controller.searchTechs();
      controller.ClearSearchNames();
      
      controller.searchfirst = lstfieldusers[0].firstname;
      controller.searchlast = '';
      controller.searchTechs();
      controller.ClearSearchNames();
      
       //jjackson this is how to reference the cUser (checked user) wrapper class contained in the controller class
      ThirdPartyCaseQueueManagement.cUser cu = new ThirdPartyCaseQueueManagement.cUser(lstfieldusers[0]);
      cu.selected = true;  //change selected to true for the checked user
      controller.lstcheckedtechs.add(cu);
      controller.AddQueueMembers();
      
      GroupMember gm = New GroupMember(UserOrGroupId = lstfieldusers[1].id, GroupId = testqueue.id);
      insert gm;
      
      
      ThirdPartyCaseQueueManagement.cUser cuser = new ThirdPartyCaseQueueManagement.cUser(thisuser);
      cuser.selected = true;
      controller.lstcheckedqueuemembers.add(cuser);
      controller.RemoveMembers();
      
      
      
   }
   
   
}