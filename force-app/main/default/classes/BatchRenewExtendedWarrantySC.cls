/*
   jjackson Sonifi Solutions May 2017
   New batch process for BUG-00770 to auto-renew extended warranty service contracts month-to-month.
*/

public with sharing class BatchRenewExtendedWarrantySC 
{
    public static void RenewExtendedWarrantyServiceContracts(List<ServiceContract> lstsc)
    {
    	 system.debug('***************Begin RenewExtendedWarrantySC***************');
    	 
    	 Date nextmonth = system.today().addmonths(1);
    	 List<ServiceContract> lstupdatesc = new List<ServiceContract>();
    	 
    	 for(ServiceContract sc :lstsc)
    	 {  sc.enddate = nextmonth; 
    	 	lstupdatesc.add(sc);
    	 }
    	 
    	 system.debug('number of extended warranty service contracts to be auto-renewed = ' +lstupdatesc.size());
    	 
    	 if(lstupdatesc.size() > 0)
    	 {
    	 	try{ update lstupdatesc;  }
    	 	catch(Exception e)
    	 	{ system.debug('Error in RenewExtendedWarrantyServiceContracts :' +e.getMessage());  }
    	 }
    	 
    	 system.debug('***********END RenewExtendedWarrantySC***********');	
    }
}//end BatchRenewExtendedWarrantySC