public class SurveyResponseTranslator {

    public class FlowInput {
        @InvocableVariable(label='Survey Response ID')
        public Id responseId;
    }

    @InvocableMethod(label='Translate Survey Response')
    public static void translateSurveyResponses(List<FlowInput> flowInputs) {
        Id responseId = flowInputs[0].responseId;

        Survey_Response__c response = [SELECT Id, Response__c FROM Survey_Response__c WHERE Id = :responseId];
        String userLocale = UserInfo.getLocale();
        String prompt = 'Translate the following text to ' + userLocale + '. Only return the translated text: ' + response.Response__c;

        String translatedResponse = generateText(prompt, userLocale);

        Survey_Response__c updatedResponse = new Survey_Response__c(
            Id = responseId,
            Translated_Response__c = translatedResponse
        );
        update updatedResponse;
    }

    public static String generateText(String prompt, String userLocale) {
        String accessToken = fetchAccessToken(); 

        String endpoint = 'https://api.salesforce.com/einstein/platform/v1/models/sfdc_ai__DefaultAzureOpenAIGPT35Turbo/generations';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accessToken); 
        req.setHeader('x-sfdc-app-context', 'EinsteinGPT');
        req.setHeader('x-client-feature-id', 'ai-platform-models-connected-app');
        req.setHeader('Content-Type', 'application/json;charset=utf-8');

        String requestBody = JSON.serialize(new Map<String, Object>{
            'prompt' => prompt,
            'localization' => new Map<String, Object>{
                'defaultLocale' => userLocale,
                'inputLocales' => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'locale' => 'auto', 
                        'probability' => 0.8
                    }
                },
                'expectedLocales' => new List<String>{ userLocale }
            },
            'tags' => new Map<String, Object>()
        });

        req.setBody(requestBody);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            Map<String, Object> generation = (Map<String, Object>)jsonResponse.get('generation');
            return (String)generation.get('generatedText');
        } else {
            throw new CalloutException('Failed to translate response. HTTP Status: ' + res.getStatusCode());
        }
    }

    public static String fetchAccessToken() {
        String endpoint = 'https://d4u000000ufituai-dev-ed.develop.my.salesforce.com/services/oauth2/token';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String requestBody = 'grant_type=client_credentials&client_id=3MVG9y7s1kgRAI8YSGZwIwf079JX.JuFmNX5tgLba4b7ozu5yL1xisX_Nh6yaNCsVBTy0RhJGcE57UyD8nvUR&client_secret=5979FAFE14D3CFBA25B61EB1E5186A53FA4F445FBD2BC6E8B4E7FAEA4A250E54';
        req.setBody(requestBody);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            return (String)jsonResponse.get('access_token');
        } else {
            throw new CalloutException('Failed to fetch access token. HTTP Status: ' + res.getStatusCode());
        }
    }
}