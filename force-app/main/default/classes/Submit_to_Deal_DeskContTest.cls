@isTest
public class Submit_to_Deal_DeskContTest {

    
    static testmethod void TestDealDeskKickoff(){
        Opportunity opp1 = new Opportunity();
        opp1.Id = getFakeId(Opportunity.SObjectType);
        Submit_To_Deal_DeskController cont = new Submit_To_Deal_DeskController(opp1);
        system.debug(cont.StartWorkflow);
        
        opp1.Proposal_Recipient__c = getFakeId(Contact.SObjectType);
        Submit_To_Deal_DeskController cont2 = new Submit_To_Deal_DeskController(opp1);
        system.debug(cont2.StartWorkflow);
    }
    
    
    static Integer s_num = 1;

   public static String getFakeId(Schema.SObjectType sot)
   {
      String result = String.valueOf(s_num++);
      return sot.getDescribe().getKeyPrefix() + 
         '0'.repeat(12-result.length()) + result;
   }
}