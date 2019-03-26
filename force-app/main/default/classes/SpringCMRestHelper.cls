global class SpringCMRestHelper {
	public static void StartWorkflow (List <SObject> listofsobjects, String sfType, String workflowname, String sId) {
        if (String.isBlank(workflowname)) return;
        if (String.isBlank(sfType)) return;
        if (listofsobjects.isEmpty()) return;

        System.debug(UserInfo.getSessionId());
        
        String xml = buildWorkflowXML(listofsobjects, sfType);

		startWorkflow(workflowname, xml, sId);
	}

	webservice static void StartWorkflowWithRecordType(String sfId, String sfType, String workflowname, String sId, string recordType) {
        if (String.isBlank(workflowname)) return;
        if (String.isBlank(sfType)) return;
        if (String.isBlank(sfId)) return;
        
        String xml = buildWorkflowXML(sfType, sfId, recordType);

		startWorkflow(workflowname, xml, sId);
	}
    
    webservice static void StartWorkflow(String sfId, String sfType, String workflowname, String sId) {
        if (String.isBlank(workflowname)) return;
        if (String.isBlank(sfType)) return;
        if (String.isBlank(sfId)) return;
        
        String xml = buildWorkflowXML(sfType, sfId, '');

		startWorkflow(workflowname, xml, sId);
	}

	private static String buildWorkflowXML(List<SObject> listofsobjects, string sfType) {
        String xml = '';
        for (SObject obj : listofsobjects) {
            xml += buildWorkflowXML(sfType, obj.Id, '');
        }
        return String.isEmpty(xml) ? xml : '<salesforce>' + xml + '</salesforce>';
	}

	private static String buildWorkflowXML(String objecttype, string sfId, string recordType) {
		if (objecttype == null || objecttype == '') return null;
		System.debug('Type: '+objecttype);
        
        SpringCMEos.SpringCMUtilities.EOSObject eosObject = SpringCMEos.SpringCMUtilities.createEOSObject(sfId, objecttype);
		string xml = '';
		xml += '<object>';
		xml += '<id>' +  eosObject.getsfId() + '</id>';
		xml += '<type>Salesforce.' + eosObject.getsfType() + '</type>';
		xml += '<foldername>' + eosObject.getfoldername().escapeXml() + '</foldername>';
		xml += '<path>' +  eosObject.getPath().escapeXml() + '</path>';
        xml += '<recordType>' + recordType + '</recordType>';
		xml += '</object>';
		return xml;
	}
	
    @future(callout=true)
	private static void startWorkflow(String workflowname, String xml, String session) {
        System.debug(session);
		SpringCMService springcm = new SpringCMService(session);
		if (springcm.apiBaseUrl == null) return;
		SpringCMWorkflow workflow = new SpringCMWorkflow(workflowname, xml);
        workflow = springcm.startWorkflow(workflow);		
	}

	
}