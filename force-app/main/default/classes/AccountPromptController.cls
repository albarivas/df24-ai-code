public with sharing class AccountPromptController {
    

    /**
     * 
     * description Method that initiate from LWC to generate Prompt based on the record account ID.
     */
    @AuraEnabled
    public static PromptResponse generatePrompt(String accountId){
        PromptResponse response = new PromptResponse();
        try {
            // Create input
            ConnectApi.EinsteinPromptTemplateGenerationsInput promptGenerationsInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            promptGenerationsInput.isPreview = false;

            // Build input map
            Map<String,ConnectApi.WrappedValue> valueMap = new Map<String,ConnectApi.WrappedValue>();

            Map<String, String> recipientEntityRecordIdMap = new Map<String, String>();
            recipientEntityRecordIdMap.put('id', accountId);

          
            ConnectApi.WrappedValue recipientEntityWrappedValue = new ConnectApi.WrappedValue();
            recipientEntityWrappedValue.value = recipientEntityRecordIdMap;

            valueMap.put('Input:Account', recipientEntityWrappedValue);

            promptGenerationsInput.inputParams = valueMap;

            // Set additional configuration values
            promptGenerationsInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            promptGenerationsInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

            // Call the service
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = 
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('0hfHn00000002E1IAI', promptGenerationsInput);

            response.response = generationsOutput.generations.get(0).text;
            Map<Id, Case> cases = getCases(accountId);

            List<ContentVersion> cvs = [SELECT Id, VersionDataUrl from ContentVersion where FirstPublishLocationId in :cases.keyset()];

            response.relatedImages = new List<String>();
            for (ContentVersion cv : cvs) {
                response.relatedImages.add(cv.VersionDataUrl);
            }

            return response;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description  Model class for the Prompt Response sent to LWC
     */
    public class PromptResponse {

        @AuraEnabled
        public String response;

        @AuraEnabled
        public List<String> relatedImages;

    }

    /**
     * 
     * @description Fetching Cases related to the Account, We can also define the criteria here. 
     */
    public static Map<Id,Case> getCases(Id accountId) {
        // 
        return new Map<Id,Case>([Select Id, Subject, CaseNumber,Type, Description from Case where AccountId =: accountId ]);
    }

    /**
     * 
     * @description This method is intiated from the Prompt Builder and runs on the Account record. It fetches the related cases of the account and return those 
     * cases in the JSON format to the Prompt. Using that JSON, Prompt Builder generates the AI Prompt.
     */
    @InvocableMethod(
    label='Damaged Cases'
    description='Find Damaged Cases for an Account'
    CapabilityType='PromptTemplateType://einstein_gpt__fieldCompletion')
    public static List<Response> getRelatedCasesPrompt(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Response response = new  Response();
        try {
            List<Map<String, String>> jsonValues = new List<Map<String, String>>();
          
            Map<String, String> jsonMap = new Map<String, String>();
            Map<Id, Case> cases = getCases(requests.get(0).RelatedEntity.id);
            if(cases.isEmpty()) {
                response.Prompt = 'There are no open cases.';
            } else {
                for(Case c : cases.values()) {  
                    jsonMap = new Map<String, String>();
                    jsonMap.put('Subject', c.subject);
                    jsonMap.put('Description', c.Description);
                    jsonMap.put('Case Number', c.CaseNumber);
                    jsonMap.put('Case Type', c.Type);

                    jsonValues.add(jsonMap);
                    System.debug('JSON Values: ' + jsonValues);
                }
                response.Prompt = JSON.serialize(jsonValues);
            }
            responses.add(response);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('JSON Responses: ' + responses);
        return responses;

    }


    /**
     * 
     * @description Request Model Input class for generating Prompt
     */
    public class Request {
        @InvocableVariable(required=true)
        public Account RelatedEntity;
    }

    /**
     * 
     * @description Response Model Output class for generating Prompt
     */
    public class Response {
        @InvocableVariable
        public String Prompt;
    }


}