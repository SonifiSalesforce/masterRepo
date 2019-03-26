@isTest
private class SpringCMApiManagerTests {
    static testMethod void testAccessTokenUserSession() {
        SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
        SpringCMApiManager api = new SpringCMApiManager();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        String token = api.AccessToken;
        Test.stopTest(); 
        System.assertEquals(token,'accesstokenstub');
    }

    static testMethod void testAccessTokenAPIUser() {
        SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
        SpringCMApiManager api = new SpringCMApiManager(false, null);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        String token = api.AccessToken;
        Test.stopTest();
        System.assertEquals(token,'accesstokenstub');
    }

    static testMethod void testValidateApiBaseUrl() {
        SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
        SpringCMApiManager api = new SpringCMApiManager();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        String url = api.ApiBaseUrl;
        Test.stopTest();
        System.assertEquals(url,'https://apiuatna11.springcm.com'); 
    }

    static testMethod void testDeserializeErrorResponse() {
        String errorJson = '{"Error":{"HttpStatusCode":401,"UserMessage":"Access Denied","DeveloperMessage":"Access Denied","ErrorCode":103,"ReferenceId":"b8272254-af64-4a3e-af03-b814ede87cc4"}}';
        SpringCMApiError error = (SpringCMApiError)JSON.deserialize(errorJson, Type.forName('SpringCMApiError'));

        System.assertEquals(error.Error.HttpStatusCode,401);
    }

    static testMethod void testDeserializeValidationErrorResponse() {
        String errorJson = '{"Error":{"HttpStatusCode": 422,"UserMessage": "Validation Error","DeveloperMessage": "See the list of validation errors","ErrorCode": 101,"ReferenceId": "430df1ca-9756-48e8-a69d-89fd73642d25"},"ValidationErrors":[{"PropertyName": "Name","UserMessage": "Names cannot contain the following characters:|","DeveloperMessage": "Names cannot contain the following characters: |","ErrorCode": 1001}]}';
        SpringCMApiError error = (SpringCMApiError)JSON.deserialize(errorJson, Type.forName('SpringCMApiError'));

        System.assertEquals(error.Error.HttpStatusCode,422);
        System.assertEquals(error.ValidationErrors[0].UserMessage,'Names cannot contain the following characters:|');
    }

    static testMethod void testHandleApiError() {
        SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
        mock.ReturnError = true;
        SpringCMApiManager api = new SpringCMApiManager(true, UserInfo.getSessionId());
        Boolean correctExceptionReturned = false;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        try {
            String token = api.AccessToken;
        }
        catch(Exception e) {
            correctExceptionReturned = e.getMessage()=='Validation Error : Names cannot contain the following characters:|';
        }
        Test.stopTest();
        System.Assert(correctExceptionReturned);
    }

    static testMethod void testHandleCalloutException() {
        SpringCMApiManagerMock mock = new SpringCMApiManagerMock();
        mock.ReturnException = true;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        SpringCMService springcm = new SpringCMService();
        Test.stopTest();

        System.assertEquals(springcm.apiBaseUrl, null);
    }

    static testMethod void testDeserializeWorkflow() {
        String workflowJson = '{"Name":"Test Workflow","CreatedDate":"2012-09-13T14:25:21.24Z","CreatedBy":"klitwin@springcm.com","UpdatedDate":"2012-09-13T14:25:21.237Z","UpdatedBy":"klitwin@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/fdb66189-aefd-e111-af1f-005056950d63"},"BrowseDocumentsUrl":"https://uatna11.springcm.com/atlas/Link/Folder/7000/6e9a32d3-aefd-e111-af1f-005056950d63","AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"Documents":{"Href":"https://apiuatna11.springcm.com/v201411/folders/6e9a32d3-aefd-e111-af1f-005056950d63/documents"},"Folders":{"Href":"https://apiuatna11.springcm.com/v201411/folders/6e9a32d3-aefd-e111-af1f-005056950d63/folders"},"EosInfo":{"Name":"Test Opp","Path":"Salesforce/Accounts/My First Account","ObjectId":"006E0000005yGr0IAE","ObjectType":"Salesforce.Opportunity","Folder":"https://apiuatna11.springcm.com/v201411/folders/6e9a32d3-aefd-e111-af1f-005056950d63"},"ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/folders/6e9a32d3-aefd-e111-af1f-005056950d63/sharelinks"},"CreateDocumentHref":"https://testdocumentuploadfolder{?name}","Href":"https://apiuatna11.springcm.com/v201411/folders/6e9a32d3-aefd-e111-af1f-005056950d63"}';
        SpringCMWorkflow workflow = (SpringCMWorkflow)JSON.deserialize(workflowJson, Type.forName('SpringCMWorkflow'));

        System.assertEquals(workflow.Name, 'Test Workflow');
    }

    static testMethod void testConstructorWorkflow() {
        String params = '<params />';

        Test.startTest();
        String name = 'Test Workflow';
        SpringCMWorkflow workflow = new SpringCMWorkflow(name, params);
        Test.stopTest();

        System.assertEquals(workflow.Name, name);
    }
}