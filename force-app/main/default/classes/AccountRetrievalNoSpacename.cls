//**********************************************************************************
//
//            Copyright 2016 Enghouse Interactive. All rights reserved
//
// The source code contained or described herein and all documents related to the
// source code ("Material") are owned by Enghouse Interactive or its suppliers or
// licensors.  Title to the Material remains with Enghouse Interactive or its
// suppliers and licensors.  The Material contains trade secrets and proprietary
// and confidential information of Enghouse or its suppliers and licensors.  The
// Material is protected by worldwide copyright and trade secret laws and treaty
// provisions. No part of the Material may be used, copied, reproduced, modified,
// published, uploaded, posted, transmitted, distributed, or disclosed in any way
// without Enghouse's prior express written permission.
//
// No license under any patent, copyright, trade secret or other intellectual
// property right is granted to or conferred upon you by disclosure or delivery
// of the Materials,  either expressly, by implication, inducement, estoppel or
// otherwise. Any license under such intellectual property rights must be express
// and approved by Enghouse in writing.
//
//**********************************************************************************

//
// Modification History
// 13/12/2015 added Case ID retrieval
// 2015-07-06 added getAccountBySiteID by AEllsworth
//

global class AccountRetrievalNoSpacename{
    
    webService static String getAccount(String strName) {
        List<Account> accounts = new List<Account>();
        
        
//      for (Account account : Database.query('Select Id, Name, phone from Account ')){
        for (Account account : Database.query('Select Id, Name, phone from Account where Name Like \'%' + strName + '%\'')){
            accounts.add(account);
        }
        String JSONString = JSON.serialize(accounts);
        return JSONString;
    }
    
    
    webService static String GetCases (String CaseNumber) { 
        List <Case> Cases = new List <Case> (); 
        for (Case Acase: [Select Id, Casenumber, contactId, accountId, Subject from Case where Casenumber =: CaseNumber]) { 
            Cases .Add (Acase); 
        } 
        String JSONString = JSON.serialize(Cases);
        Return JSONString; 
}


    webService static String GetCustomerbyId (String CustomerId) { 
        List <EnghouseCustomer__c> EnghouseCustomers = new List <EnghouseCustomer__c> (); 
        for (EnghouseCustomer__c AEnghouseCustomer: [Select Customer_Id__c, Name, Phone__c from EnghouseCustomer__c where Customer_Id__c =: CustomerId]) { 
            EnghouseCustomers .Add (AEnghouseCustomer); 
        } 
        String JSONString = JSON.serialize(EnghouseCustomers);
        Return JSONString; 
}

    
   /* 
    webService static String getCaller(String callerId) {
        List<List<SObject>> searchList = search.query('FIND {' + callerId + '} IN PHONE FIELDS RETURNING ACCOUNT(Type,AccountNumber,Name,Id),CASE(CaseNumber,Status,Priority,Id),CONTACT(Title,Name,Id),LEAD(Company,Title,LeadSource,Name,Id)');
        String JSONString = JSON.serialize(searchList);
        return JSONString;
    }
*/
    /*
    webService static String getUserPhone() {
         return [select Phone from User where id = :UserInfo.getUserId()].Phone;
    }
    */
    webService static String getUser() {
         //List<User> users = new List<User>();
         //for (User user : Database.query('select AccountId, CallCenterId, Phone, FirstName,LastName, MobilePhone,Extension, Email from User where id =' + UserInfo.getUserId() +'' )){
            //users.add(user);
        //}
         //User users;
        // A simple bind
         User users = [select id, CallCenterId, Phone, FirstName,LastName, MobilePhone,Extension, Email from User where id = :UserInfo.getUserId() LIMIT 1];
         String JSONString = JSON.serialize(users );
         //system.debug('return JSONString = ' +JSONString);
         return JSONString;
    }

    webService static String getAccountBySiteID(String SiteID) {
        List<Account> accounts = new List<Account>();
        
        String sitevar;
       
        
        if(SiteID.length() == 7)
        { sitevar = SiteID; 
          for (Account account : Database.query('Select Id, Name, phone from Account where Site_ID_Ext_ID__c = :sitevar')){
            accounts.add(account);
          }
        }
        
        
        if(SiteID.length() < 7)
        { sitevar = '%'+SiteID;  
          for (Account account : Database.query('Select Id, Name, phone from Account where Site_ID_Ext_ID__c like :sitevar')){
            accounts.add(account);
          }
        
        }
       
        
        String JSONString = JSON.serialize(accounts);
        return JSONString;
    }

    
    
}