public with sharing class LLMService {
    public static String generateResponseFromPromptTemplate(
        String promptTemplateDeveloperName,
        Map<String, ConnectApi.WrappedValue> inputParams
    ) {
        // Create input
        ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';

        // Set additional values
        executeTemplateInput.isPreview = false;
        executeTemplateInput.inputParams = inputParams;

        // Call the service
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
            promptTemplateDeveloperName,
            executeTemplateInput
        );
        if (generationsOutput.generations.size()==0) {
            throw new EinsteinGenerativeGatewayException(JSON.serialize(generationsOutput));
        }

        ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
        return response.text;
    }

    @AuraEnabled
    public static string generateText(String prompt) {

        // Create generations request
        aiplatform.ModelsAPI.createGenerations_Request request = new aiplatform.ModelsAPI.createGenerations_Request();

        // Specify model
        request.modelName = 'sfdc_ai__DefaultOpenAIGPT35Turbo';

        // Create request body
        aiplatform.ModelsAPI_GenerationRequest body = new aiplatform.ModelsAPI_GenerationRequest();
        request.body = body;

        // Add prompt to body
        body.prompt = prompt;

        String modelsApiResponse = '';

        try {
            // Make request
            aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
            aiplatform.ModelsAPI.createGenerations_Response response = modelsAPI.createGenerations(request);
            System.debug('Prompt Response: ' +response);
            // Add response to return value
            modelsApiResponse = response.Code200.generation.generatedText;

        // Handle error
        } catch(aiplatform.ModelsAPI.createGenerations_ResponseException e) {
            System.debug('Response code: ' + e.responseCode);
            System.debug('The following exception occurred: ' + e);

            // Add error to the return value
            modelsApiResponse = 'Unable to get a valid response. Error code: ' + e.responseCode;
        }
        System.debug(modelsApiResponse);
        // Return response

        return modelsApiResponse;
    }

    @AuraEnabled
    public static String createChatGenerations(String serializedMessages, String systemPrompt) {
        List<ChatMessage> messages = (List<ChatMessage>) JSON.deserialize(
            serializedMessages,
            List<ChatMessage>.class
        );

        // Instantiate the API class
        aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();

        // Prepare the request and body objects
        aiplatform.ModelsAPI.createChatGenerations_Request request = new aiplatform.ModelsAPI.createChatGenerations_Request();
        aiplatform.ModelsAPI_ChatGenerationsRequest body = new aiplatform.ModelsAPI_ChatGenerationsRequest();

        // Specify model
        request.modelName = 'sfdc_ai__DefaultGPT35Turbo';

        // Create a list to hold chat messages
        List<aiplatform.ModelsAPI_ChatMessageRequest> messagesList = new List<aiplatform.ModelsAPI_ChatMessageRequest>();

        // Loop through the input messages and create message requests
        for (ChatMessage msg : messages) {
            aiplatform.ModelsAPI_ChatMessageRequest messageRequest = new aiplatform.ModelsAPI_ChatMessageRequest();
            messageRequest.content = msg.message != null ? msg.message : ''; // Handle null message
            messageRequest.role = msg.role != null ? msg.role : 'user'; // Handle null role
            messagesList.add(messageRequest);
        }

        // Create system message
        aiplatform.ModelsAPI_ChatMessageRequest systemMessageRequest = new aiplatform.ModelsAPI_ChatMessageRequest();
        systemMessageRequest.content = systemPrompt;
        systemMessageRequest.role = 'system';
        messagesList.add(systemMessageRequest);

        // Set the messages in the request body
        body.messages = messagesList;

        // Set the request body and model name
        request.body = body;

        String response = '';

        try {
            // Call the API and get the response
            aiplatform.ModelsAPI.createChatGenerations_Response apiResponse = modelsAPI.createChatGenerations(
                request
            );

            // Check that we have a non-null response
            if (
                apiResponse?.Code200?.generationDetails?.generations != null &&
                !apiResponse.Code200.generationDetails.generations.isEmpty()
            ) {
                // Set the variable from the response
                response = apiResponse.Code200.generationDetails.generations[0]
                    .content;
            } else {
                // Handle the case where response is null
                response = 'No content generated';
            }

        // Handle error
        } catch(aiplatform.ModelsAPI.createChatGenerations_ResponseException e) {
            System.debug('Response code: ' + e.responseCode);
            System.debug('The following exception occurred: ' + e);

            // Add error to the output
            response = 'Unable to get a valid response. Error code: ' + e.responseCode;
        }

        return response;
    }

    public class ChatMessage {
        @AuraEnabled
        public String role;
    
        @AuraEnabled
        public String message;
    
        public ChatMessage() {
        }
    
        public ChatMessage(String role, String message) {
            this.role = role;
            this.message = message;
        }
    }

    public class EinsteinGenerativeGatewayException extends Exception {}
}