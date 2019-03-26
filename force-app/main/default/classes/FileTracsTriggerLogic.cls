public with sharing class FileTracsTriggerLogic {
    
    public static void UpdateAccountandTrackingNumber(List<FileTracs__c> triggernewlist, Map<Id,FileTracs__c> triggeroldMap)
    {
        system.debug('*********************BEGIN UpdateAccountandTrackingNumber*****************************');
        Set<String> setsiteids = New Set<String>();
        
        for(FileTracs__c ft : triggernewlist)
        { setsiteids.add(ft.Name);  }
        
        List<Account> acctlist = New List<Account>();
        Map<String,Id> siteidtoacct = New Map<String,Id>();
        
        acctlist = [ Select Id, site_id__c from Account where site_id__c in :setsiteids ];
        for(Account acc : acctlist)
        { siteidtoacct.put(acc.site_id__c,acc.Id);  }
        
        
        if(triggeroldMap.size() == 0) //this is an insert so find the account and create the tracking number
        {

            for(FileTracs__c ft : triggernewlist)
            {
               if(siteidtoacct.containskey(ft.Name))
                { ft.accountname__c = siteidtoacct.get(ft.Name); }
                else
                { ft.accountname__c = null;
                  triggernewlist[0].Name.addError('Site ID not found.  Please check and try again.') ; 
                }
                
                if(ft.rack_id__c == null)
                { triggernewlist[0].rack_id__c.addError('Rack Id is null.  There must be a rack id to create a tracking number.'); }
                if(ft.shelf_id__c == null)
                { triggernewlist[0].shelf_id__c.addError('Shelf Id is null.  There must be a shelf id to create a tracking number.'); }
                if(ft.file_id__c == null)
                { triggernewlist[0].file_id__c.addError('File Id is null.  There must be a file id to create a tracking number.'); }
                
                String padrack;
                String padfile;
                Integer fileidlength;
                
                if(ft.rack_id__c != null && ft.rack_id__c.length() < 2)  //the first part of the tracking number should always be 2 characters -- use leading zero
                { padrack = '0'+ft.rack_id__c; }
                else
                { padrack = ft.rack_id__c;  }
                
                if(ft.file_id__c != null && ft.file_id__c.length() < 5) //the last part of the tracking number should always be 5 characters -- use leading zeroes
                {
                	fileidlength = ft.file_id__c.length();
                	if(fileidlength == 4)
                	{ padfile = '0'+ft.file_id__c; }
                	else if(fileidlength == 3)
                	{ padfile = '00'+ft.file_id__c; }
                	else if(fileidlength ==2)
                	{ padfile = '000'+ft.file_id__c; }
                	else if(fileidlength == 1)
                	{ padfile = '0000' +ft.file_id__c; }
                		
                }
                else
                {
                	padfile = ft.file_id__c;
                }
                ft.tracking_number__c = padrack +'-' +ft.shelf_id__c +'-' +padfile;
            }
        }
        else  //something was updated so check whether it was the site id or one of the items that makes up the tracking number
        {
            
            for(FileTracs__c ft : triggernewlist)
            {
                Boolean updaterec = false;
                
                if(ft.Name != triggeroldMap.get(ft.Id).Name || ft.rack_id__c != triggeroldMap.get(ft.Id).rack_id__c ||
                   ft.shelf_id__c != triggeroldMap.get(ft.Id).shelf_id__c || ft.file_id__c != triggeroldMap.get(ft.Id).file_id__c)
                {  updaterec = true;  }
                
                if(updaterec == true)
                {
                    if(ft.Name != triggeroldMap.get(ft.Id).Name)
                    {
                        if(siteidtoacct.containskey(ft.Name))
                        {  ft.accountname__c = siteidtoacct.get(ft.Name); }
                        else
                        {  ft.accountname__c = null;  
                            triggernewlist[0].Name.addError('Site ID not found.  Please check and try again.') ;
                        }
                    }
                    
                    if(ft.rack_id__c == null)
                    { triggernewlist[0].rack_id__c.addError('Rack Id is null.  There must be a rack id to create a tracking number.'); }
                    if(ft.shelf_id__c == null)
                    { triggernewlist[0].shelf_id__c.addError('Shelf Id is null.  There must be a shelf id to create a tracking number.'); }
                    if(ft.file_id__c == null)
                    { triggernewlist[0].file_id__c.addError('File Id is null.  There must be a file id to create a tracking number.'); }
                    
                    String padrack;
                	String padfile;
                	Integer fileidlength;
                
                	if(ft.rack_id__c != null && ft.rack_id__c.length() < 2)  //the first part of the tracking number should always be 2 characters -- use leading zero
                	{ padrack = '0'+ft.rack_id__c; }
                	else
                	{ padrack = ft.rack_id__c;  }
                
                	if(ft.file_id__c != null && ft.file_id__c.length() < 5) //the last part of the tracking number should always be 5 characters -- use leading zeroes
                	{
                		fileidlength = ft.file_id__c.length();
                		if(fileidlength == 4)
                		{ padfile = '0'+ft.file_id__c; }
                		else if(fileidlength == 3)
                		{ padfile = '00'+ft.file_id__c; }
                		else if(fileidlength ==2)
                		{ padfile = '000'+ft.file_id__c; }
                		else if(fileidlength == 1)
                		{ padfile = '0000' +ft.file_id__c; }
                		
                	}
                	else
                	{
                		padfile = ft.file_id__c;
                	}
                    
                    ft.tracking_number__c = padrack +'-' +ft.shelf_id__c +'-' +padfile;
                }//end if updaterec = true
            } //end for loop triggernewlist
        }//end else
        //No DML to insert or update is needed because the record we are updating is already in the trigger
        system.debug('*************************END UpdateAccountandTrackingNumber***********************************');
    }//end UpdateAccountandTrackingNumber
    
    public Void addError(String errormsg)
    {
        
    }
    
}//end class