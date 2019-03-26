public class Submit_To_Deal_DeskController {

    

    private final Opportunity opp;
    
    public Submit_To_Deal_DeskController(Opportunity testOpp){
        opp= testOpp;    
    }
    public Submit_To_Deal_DeskController(ApexPages.StandardController stdController) {
        
        this.opp = (Opportunity)stdController.getRecord();

    }

public String buildWorkflowXML(String objecttype, string sfId, string recordType) {
    if (objecttype == null || objecttype == '') return null;
    System.debug('Type: '+objecttype);
        
        SpringCMEos.SpringCMUtilities.EOSObject eosObject = SpringCMEos.SpringCMUtilities.createEOSObject(sfId, objecttype);
    string xml = '';
    xml += '<object>';
    xml += '<id>' +  eosObject.getsfId() + '</id>';
    xml += '<type>Salesforce.' + eosObject.getsfType() + '</type>';
    If(!Test.isRunningTest()){
    	xml += '<foldername>' + eosObject.getfoldername().escapeXml() + '</foldername>';
    	xml += '<path>' +  eosObject.getPath().escapeXml() + '</path>';
    }
        xml += '<recordType>' + recordType + '</recordType>';
    xml += '</object>';
    return xml;
  }
    
    public string StartWorkflow{get{
       
        if (  opp.Proposal_Recipient__c == null){
           
             return 'Primary Contact field can\'t be empty in order to proceed with the workflow';
             
           
            } 
        else { 
           
            String xml;
            
             //if (!Test.isRunningTest()){
                xml     = buildWorkflowXML('Opportunity', opp.Id, '');
             //}else{
             //    xml = '<test>';
             //    xml += '</test>';
            // }
            SpringCMService svc = new SpringCMService();
            SpringCMWorkflow wf = new SpringCMWorkflow('Create Contract',xml);
            
            system.debug(xml);
            SpringCMWorkflow wfs = new SpringCMWorkflow('test','test');
            if (!Test.isRunningTest()){
                wfs= svc.startWorkflow(wf);
            }
          system.debug(wfs.Href);
            
            return 'Contract Request for ' + opp.Name +' was submitted to Deal Desk successfully';
            
            }
    }
        
    }
    
    
    
    
    
}