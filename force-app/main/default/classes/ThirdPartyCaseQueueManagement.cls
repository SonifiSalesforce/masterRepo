public without sharing class ThirdPartyCaseQueueManagement {
	
	public String qname {get;set;}
	public List<SelectOption> qlist {get;set;}
    public String searchlast {get;set;}
    public String searchfirst {get;set;}

	
    
    public ThirdPartyCaseQueueManagement()
	{
		Id id = ApexPages.currentPage().getParameters().get('id');
        qlist = getqueuenames();
   
	}


	public List<SelectOption> getqueuenames()
	{
		List<Group> grouplist = new List<Group>();
		List<SelectOption> qlist = New List<SelectOption>();
        grouplist = [Select type, name from group where name like 'Third Party Case%' AND type = 'Queue'];
        qlist.add(new selectOption('Please Select', '---Please Select---'));
        for(Group g : grouplist)
        {   

            qlist.add(new selectOption(g.name, g.name));
        }

        return qlist;
	}

	public class cUser //jjackson--wrapper class for creating list of selected accounts from the visual force page 
	{

		public User u {get;set;}
		public Boolean selected {get;set;}

        
		public cUser(User thisuser)
		{
			u = thisuser;
   			selected = false;
            u.id = thisuser.id;
            u.lastname = thisuser.lastname;
            u.firstname = thisuser.firstname;
            u.email = thisuser.email;
            u.mobilephone = thisuser.mobilephone;
 		}
   } //end class cUser	

	public List<cUser> lstcheckedqueuemembers {get;set;}
	public List<cUser> lstcheckedtechs {get;set;}

    public void GetQueueMembers()
    {
    	List<GroupMember> lstgm = New List<GroupMember>();
    	List<User> lstusers = New List<User>();
    	Set<Id> setuserids = New Set<Id>();

    	Group g = [Select Id, name from Group where name = :qname LIMIT 1 ];

    	if(g != null)
    	{
    		lstgm = [ Select groupid, userorgroupid from GroupMember where groupid = :g.id ];

    		if(lstgm.size() == 0)
    		{
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The selected queue '
                	                                                                    +'has no members.');
            	ApexPages.addMessage(myMsg);	
    		}
    		else
    		{
    			for(GroupMember gm : lstgm)
    			{
    				{  setuserids.add(gm.userorgroupid);  }
    			}
              
    			lstusers = [Select Id, IsActive, firstname, lastname, email, mobilephone from User where
    			            Id in :setuserids AND IsActive = true order by lastname ];

    			if(lstusers.size() == 0)
    			{
     				ApexPages.Message Msg = new ApexPages.Message(ApexPages.Severity.INFO,'No active users are associated with this queue.');               	                                                                   
                    ApexPages.addMessage(Msg);
    			}
    			else
    			{
    				lstcheckedqueuemembers = CreateCheckedList(lstusers);
    			}


    		}
    	}
    	else
    	{
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The selected queue name does not match an existing queue.');               	                                                                    
            ApexPages.addMessage(myMsg);	
    	}

    	
    }

    public List<cUser> CreateCheckedList(List<User> lsttechusers)
    {
       
    	//if(lstcheckedqueuemembers != null)
    	//{
    		//List<cUser> emptylist = New List<cUser>();
    	//	lstcheckedqueuemembers = null;
    	//}

    	//if(lstcheckedqueuemembers == null)
		//{
			lstcheckedqueuemembers = New List<cUser>();
			for(User u: lsttechusers)
			{
				lstcheckedqueuemembers.add(new cUser(u));
			}
		//}
		
		return lstcheckedqueuemembers;

    }//end createcheckedlist

    public List<cUser> CreateCheckedTechList(List<User> lsttechusers)
    {
    	system.debug('lstcheckedtechs is ' +lstcheckedtechs);
    	
        if(lstcheckedtechs != null)
        {
        	List<cUser> emptylist = new List<cUser>();
        	lstcheckedtechs = null;
        }

    	if(lstcheckedtechs == null)
		{
			lstcheckedtechs = New List<cUser>();
			for(User u: lsttechusers)
			{
				lstcheckedtechs.add(new cUser(u));
			}
		}
		
	    system.debug('lstcheckedtechs before return = ' +lstcheckedtechs);
		
		return lstcheckedtechs;

    }//end createcheckedtechlist

    public PageReference RemoveMembers()
    {
    	Boolean boolprocess = true;
    	Set<Id> setuserid = new Set<Id>();
    	List<GroupMember> lstgm = new List<GroupMember>();
    	List<cUser> lstcheckedusers = New List<cUser>();
    	List<GroupMember> lstremainingusers = new List<GroupMember>();
    	List<User> lstusers = new List<User>();
    	List<cUser> emptyuserlist = new List<cUser>();
    	String selectedqueue = qname;

    	for(cUser cu : lstcheckedqueuemembers)
    	{
    		if(cu.selected == true)
    		{
    			lstcheckedusers.add(cu);
    		}

    		if(lstcheckedusers.size() > 0)
    		{
    			for(cUser cuser : lstcheckedusers)
    			{
    				setuserid.add(cuser.u.id);
    				system.debug('cuserid is ' +cuser.u.id);
    			}
    		}

    	}

    	if(lstcheckedusers.IsEmpty())
    	{
    		boolprocess = false;
    		ApexPages.Message mymsg = New ApexPages.Message(ApexPages.Severity.INFO, 'Please select one or more '
    		                                                                        +' names to remove.');
    		ApexPages.addMessage(mymsg);
    	}

    	if(boolprocess == true)
    	{
    		system.debug('qname in removemembers is ' +qname);
    		Group g = [Select Id, name from Group where name = :qname LIMIT 1 ];

    		if(g != null)
    	    {
    		    lstgm = [ Select groupid, userorgroupid from GroupMember where groupid = :g.id AND
    		              userorgroupid in :setuserid ];

    		    if(lstgm.size() > 0)
    		    {
    		    	delete lstgm;

 
    		    }
    		}

    		if(g != null)
    		{
    			lstremainingusers = [ Select groupid, userorgroupid from GroupMember where groupid = :g.id AND
    		              userorgroupid in :setuserid ];

    		    if(lstremainingusers.size() > 0)
    		    { 
    		      lstusers = [Select Id, lastname, firstname, email, mobilephone from User where
    		                 id in :setuserid ];

    		      if(lstusers.size() > 0)
    		      {           
    	          		//lstcheckedqueuemembers = emptyuserlist;
    	          		//lstcheckedqueuemembers = CreateCheckedList(lstusers);
    	          		GetQueueMembers();
    		      }  
                }
            } 		

    	}

    	
    	PageReference pr = ApexPages.currentPage();
    	pr.setRedirect(true);
        qname = selectedqueue;
    	return pr;
    	
    	
    }

    public void SearchTechs()
    {
    	boolean matchfound = false;
    	Id fieldmgrid = Utilities.ProfileNameToId('Field Manager/SC');
    	Id fieldsrmgrid = Utilities.ProfileNameToId('Field Sr. Manager');
    	List<User> lstgetusers = new List<User>();
    	system.debug('searchname = ' +searchfirst);

       if(matchfound == false)
       {
    		if(searchfirst == '' && searchlast != '')
    		{
                String search1 = 'Select Id, firstname, lastname, profileid, email, mobilephone from User '
                                 +'where lastname = :searchlast AND (profileid = :fieldmgrid '
                                 +'or profileid = :fieldsrmgrid)';

                lstgetusers=Database.query(search1);
                system.debug('lstgetusers size ' +lstgetusers.size());
                
                   	if(lstgetusers.size() >= 1)
                	{   
                   		matchfound = true;
                		CreateCheckedTechList(lstgetusers);
                	}
                	else
                	{
                		ApexPages.Message mymsg = New ApexPages.Message(ApexPages.Severity.INFO,'No field manager or '
         			                                                           +'Lead Tech found matching your search criteria.');
         			    ApexPages.addMessage(mymsg);
                	}

                
    		}
       }

       if(matchfound == false)
       {

       		if(searchfirst !='' && searchlast == '')
       		{
       			String search2 = 'Select Id, firstname, lastname, profileid, email, mobilephone from User '
                                 +'where firstname = :searchfirst AND (profileid = :fieldmgrid '
                                 +'or profileid = :fieldsrmgrid)';

                lstgetusers=Database.query(search2);
                
                   	if(lstgetusers.size() >= 1)
                	{   
                		matchfound = true;
                  		CreateCheckedTechList(lstgetusers);
                	}
                	else
                	{
                		ApexPages.Message mymsg = New ApexPages.Message(ApexPages.Severity.INFO,'No field manager or '
         			                                                           +'Lead Tech found matching your search criteria.');
         			    ApexPages.addMessage(mymsg);
                	}
       		}
       }

  
       if(matchfound == false)
       {
    	if(searchfirst !='' && searchlast != '')
    	{
    		String search3 = 'Select Id, firstname, lastname, profileid, email, mobilephone from User '
                                 +'where firstname = :searchfirst AND lastname = :searchlast AND (profileid = :fieldmgrid '
                                 +'or profileid = :fieldsrmgrid)';

                lstgetusers=Database.query(search3);
                
                   	if(lstgetusers.size() >= 1)
                	{   
                		matchfound = true;
                   		CreateCheckedTechList(lstgetusers);
                	}
                	else
                	{
                		ApexPages.Message mymsg = New ApexPages.Message(ApexPages.Severity.INFO,'No field manager or '
         			                                                           +'Lead Tech found matching your search criteria.');
         			    ApexPages.addMessage(mymsg);
                	}
       		}
    	}
    	
    	if(matchfound == false)
    	{
    		if(searchfirst == '' && searchlast == '')
    		{
    			String search4 = 'Select Id, firstname, lastname, profileid, email, mobilephone from User '
                                 +'where profileid = :fieldmgrid or profileid = :fieldsrmgrid Order By lastname';
                                 
                lstgetusers=Database.query(search4);
                
                if(lstgetusers.size() >= 1)
                {
                	matchfound = true;
                	CreateCheckedTechList(lstgetusers);
                }
                else
                {
                	ApexPages.Message mymsg = New ApexPages.Message(ApexPages.Severity.INFO,'There was an error querying Lead Techs and Field Managers.');
                	ApexPages.addMessage(mymsg);
                }
    		}
    	}


  
    }//end SearchTechs

    public void ClearSearchNames()
    {
    	String emptystring;
    	searchfirst = emptystring;
    	searchlast = emptystring;
    	List<cUser> emptylist = New List<cUser>();
    	lstcheckedtechs = emptylist;
    }
    
    public void AddQueueMembers()
    {
    	List<cUser> lstcheckedusers = New List<cUser>();
    	Set<Id> setuserid = New Set<Id>();
    	String selectedq = qname;
    	List<GroupMember> lstgm = New List<GroupMember>();
    	List<GroupMember> lstexistingmembers = new List<GroupMember>(); 
    	List<Group> lstgroup = New List<Group>();
    	Id gid;
    	String gname;
    	
    	if(selectedq == null || selectedq == 'Please Select')
    	{
    		ApexPages.Message mymsg = New ApexPages.Message(ApexPages.Severity.ERROR,'You must select a queue name before you can add members.');
    		ApexPages.addMessage(mymsg);
    		
    	}
    	else
    	{
    		for(cUser cu : lstcheckedtechs)
    		{
    			if(cu.selected == true)  //spin through the checked list and find the names that are selected
    			{
    				lstcheckedusers.add(cu);  //add selected names to a separate list
    			}
    		}//end for loop lstcheckedtechs
    		
    		if(lstcheckedusers.size() > 0)
    		{
    			for(cUser cuser : lstcheckedusers)
    			{
    				setuserid.add(cuser.u.id);
    			}
    			
    			lstgroup = [ Select Id, Name, Type from Group where Name = :selectedq and type = 'Queue' LIMIT 1];
    			for(Group g :lstgroup)
    			{
    				gid = g.id;
    				gname = g.name;
    			}
    			
    			//query the selected queue and userids first to make sure a selected user doesn't already belong to the queue
    			lstexistingmembers = [Select GroupId, UserOrGroupId from GroupMember where GroupId = :gid AND UserOrGroupId in :setuserid ];
    			
    			//if one or more selected users already belongs to the selected queue, throw error message, else continue on
    			if(lstexistingmembers.size() > 0 )
    			{
    				Map<Id,User> mpuser = New Map<Id,User>([Select Id, firstname, lastname from User where Id in :setuserid] );
    				
    				for(GroupMember gm : lstexistingmembers)
    				{   
    					if(mpuser.containskey(gm.UserorGroupId))
    					{ ApexPages.Message mymsg = New ApexPages.Message(ApexPages.Severity.ERROR, mpuser.get(gm.UserOrGroupId).firstname + ' ' +mpuser.get(gm.UserorGroupId).lastname +' already belongs to selected queue.'); 
    					  ApexPages.addMessage(mymsg);
    					}
    				}
    			}
    			else
    			{
    				for(Id uid :setuserid)
    				{
    					Groupmember gm = New Groupmember();
    					gm.UserOrGroupId = uid;
    					gm.GroupId = gid;
    					lstgm.add(gm);
    				}
    			
    				if(lstgm.size() > 0)
    				{
    					try{ insert lstgm; }
    					catch(Exception ex)
    					{  ApexPages.Message mymsg = New ApexPages.Message(ApexPages.Severity.ERROR,'Error adding queue member: ' +ex.getMessage());  
    					   ApexPages.addMessage(mymsg);
    					}
    				}
    			}//end else
    		}
    		else
    		{
    		   ApexPages.Message mymsg = New ApexPages.Message(ApexPages.Severity.ERROR,'Please select one or more names before clicking Add Queue Members.');
    		   apexpages.AddMessage(mymsg);	
    		   
    		}//end else
    	}//end else
    }//end AddQueueMembers


}//end thirdpartycasequeuemanagement