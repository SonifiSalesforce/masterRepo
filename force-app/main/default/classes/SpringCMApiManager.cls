public class SpringCMApiManager {
    private String apiURL;
    private SpringCMApiEnvironment__mdt apiEnvironment;

    private String localAccessToken;
    private String localTokenExpiration;
    private String localApiBaseUrl;
    private String session;

    private Boolean sessionauth = true;

    public string AccessToken {
        get { 
            validateAccessToken();
            return localAccessToken;
        }
    }
 
    public string ApiBaseUrl {
        get {
            validateAccessToken();
            return localApiBaseUrl;
        }
    }

    private void validateAccessToken() {
        System.debug(localTokenExpiration);
        //if (String.isBlank(localAccessToken) || localTokenExpiration < DateTime.now()) {
            if (String.isBlank(localAccessToken) ) {
                System.debug('Refreshing access token');
                authenticate();
        }
    }

    public SpringCMApiManager() {
        apiURL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/28.0/' + UserInfo.getOrganizationId();
        apiEnvironment = SpringCMApiEnvironment.getApiEnvironment();
    }

    public SpringCMApiManager(Boolean authflag, String session) {
        apiURL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/28.0/' + UserInfo.getOrganizationId();
        apiEnvironment = SpringCMApiEnvironment.getApiEnvironment();
        sessionauth = authflag;
        this.session = session;
        System.debug(apiEnvironment);
    }

    private void authenticate() {
        SpringCMAuthRequest springCMAuthRequest = createAuthRequest();
        String responseBody = post(springCMAuthRequest,apiEnvironment.AuthEndpoint__c + (sessionauth ? 'salesforce' : 'apiuser'));
        if (responseBody == null) return;
        SpringCMAuthResponse springCMAuthResponse = (SpringCMAuthResponse)JSON.deserialize(responseBody, Type.forName('SpringCMAuthResponse'));
        saveAuthResponse(springCMAuthResponse);
    }
 
    private SpringCMAuthRequest createAuthRequest() {
        SpringCMAuthRequest springCMAuthRequest = new SpringCMAuthRequest();
        springCMAuthRequest.client_id = apiEnvironment.Client_Id__c;
        springCMAuthRequest.client_secret = apiEnvironment.Client_Secret__c;
        if (sessionauth) {
            springCMAuthRequest.session_id = session;
            springCMAuthRequest.api_url = apiUrl;
        }
        return springCMAuthRequest;
    }
 
    private void saveAuthResponse(SpringCMAuthResponse authResponse) {
        localAccessToken = authResponse.access_token;
        localApiBaseUrl = authResponse.api_base_url;
        localTokenExpiration = authResponse.expires_in;
    }

    public String get(String endpoint) { 
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/json');

        HttpResponse response = doGet(request,endpoint);
        return response == null ? null : response.getBody();
    }

    public Blob getBlob(String endpoint, String acceptHeader) {
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/json');
        if (String.isNotBlank(acceptHeader)) request.setHeader('Accept', acceptHeader);

        HttpResponse response = doGet(request,endpoint);
        return response == null ? null : response.getBodyAsBlob();
    }

    private HttpResponse doGet(HttpRequest request, String endpoint) {
        request.setMethod('GET');
        request.setEndpoint(endpoint);
        request.setTimeout(120000);

        //We will get in a loop if we try to add the access token to an auth call
        //since the access token is what we are trying to retrieve
        if (!endpoint.startsWith(apiEnvironment.AuthEndpoint__c)) {
            request.setHeader('Authorization','oauth '+AccessToken);
        }

        return doRequest(request);
    }

    public String post(Object body, String endpoint) {
        HttpRequest request = new HttpRequest();
        String req = JSON.serialize(body);
        request.setBody(req);
        request.setHeader('Content-Type', 'application/json');

        HttpResponse response = doPost(request,endpoint);
        return response == null ? null : response.getBody();
    }

    public String postBlob(Blob body, String endpoint, String contentType) {
        HttpRequest request = new HttpRequest();
        if (String.isNotEmpty(contentType)) request.setHeader('Content-Type', contentType);
        request.setBodyAsBlob(body);

        HttpResponse response = doPost(request,endpoint);
        return response == null ? null : response.getBody();
    }

    private HttpResponse doPost(HttpRequest request, String endpoint) {
        request.setMethod('POST');
        request.setEndpoint(endpoint);
        request.setTimeout(120000);

        //We will get in a loop if we try to add the access token to an auth call
        //since the access token is what we are trying to retrieve
        if (!endpoint.startsWith(apiEnvironment.AuthEndpoint__c)) {
            request.setHeader('Authorization','oauth '+AccessToken);
        }

        return doRequest(request);
    }

    public String del(String endpoint) {
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/json');

        HttpResponse response = doDelete(request,endpoint);
        return response == null ? null : response.getBody();
    }

    private HttpResponse doDelete(HttpRequest request, String endpoint) {
        request.setMethod('DELETE');
        request.setEndpoint(endpoint);
        request.setTimeout(120000);

        //We will get in a loop if we try to add the access token to an auth call
        //since the access token is what we are trying to retrieve
        if (!endpoint.startsWith(apiEnvironment.AuthEndpoint__c)) {
            request.setHeader('Authorization','oauth '+AccessToken);
        }

        return doRequest(request);
    }

    private HttpResponse doRequest(HttpRequest request) {
        Http http = new Http();
        HttpResponse response;
        try {
            response = http.send(request);
        }
        catch (Exception e) {
            response = retry(request, 5, 1);
        }

        if (response != null) {
            if (response.getStatusCode() == 401) System.debug(String.format('SpringCM Auth Error - Request Body:{0}, Request Endpoint:{1}', new String[] {request.getBody(), request.getEndpoint()}));
            validateResponse(response);
        }
        return response;
    }

    private HttpResponse retry(HttpRequest request, Integer maxattempts, Integer count) {
        System.debug('Attempting to retry ' + maxattempts + ' times, this is attempt ' + count);
        Http http = new Http();
        HttpResponse response;
        try {
            response = http.send(request);
        }
        catch (Exception e) {
            if (++count >= maxattempts) return response;
            retry(request, maxattempts, count);
        }
        return response;
    }

    private void validateResponse(HttpResponse response) {
        if (response.getStatusCode() >= 400) {
            system.debug(response);
            SpringCMApiError error;
            String userMessage;
            String[] errorArguments;
            try {
                error = (SpringCMApiError)JSON.deserialize(response.getBody(), Type.forName('SpringCMApiError'));

                errorArguments = new String[]{ String.valueOf(error.Error.HttpStatusCode),
                                                        String.valueOf(error.Error.ErrorCode),
                                                        error.Error.ReferenceId,
                                                        error.Error.DeveloperMessage };

                userMessage = error.Error.UserMessage;
            }
            catch (Exception e) {
                HttpError httperror = (HttpError)JSON.deserialize(response.getBody(), Type.forName('HttpError'));

                errorArguments = new String[]{ String.valueOf(httperror.StatusCode),'','',httperror.Status };

                userMessage = '';
            }
            String errorLog = String.format('SpringCM API Error - HttpStatusCode:{0}, ErrorCode:{1}, ReferenceId:{2}, DeveloperMessage:{3}',errorArguments);
            System.debug(LoggingLevel.ERROR, errorLog);

            if(Integer.valueOf(errorArguments[0]) == 422) {
                for(SpringCMApiError.SpringCMValidationError validationError : error.ValidationErrors) {
                    userMessage += ' : ' + validationError.UserMessage;
                }
            }

            System.debug(userMessage);
            throw new SpringCMException(userMessage.escapeHtml4());
        }
    }
}