public class SpringCMApiEnvironment {
    public static SpringCMApiEnvironment__mdt getApiEnvironment() {
        SpringCMEos.RetrieveEnvironment environment = new SpringCMEos.RetrieveEnvironment();
        String environmentPrefix = environment.getEnvironmentPrefix();

        //Default to Prod if for some reason its blank        
        String environmentqueryname = 'PROD';

        String prefix;
        if (String.isNotBlank(environmentPrefix)) 
            prefix = environmentPrefix.substringBefore('.').toLowerCase();

        if (prefix=='na11' || prefix=='na21' || prefix=='www')
            environmentqueryname = 'PROD';

        else if (prefix=='uatna11' || prefix=='uat')
            environmentqueryname = 'UAT';

        else if (prefix=='qana11' || prefix=='qana21' || prefix=='qa')
            environmentqueryname = 'QA';

        else if (prefix=='qarna11')
            environmentqueryname = 'QAR';
        
        if (Test.isRunningTest())
            environmentqueryname = 'TEST';

        return [SELECT Client_Id__c, Client_Secret__c, AuthEndpoint__c
                FROM SpringCMApiEnvironment__mdt
                WHERE DeveloperName =: environmentqueryname];
    }
}