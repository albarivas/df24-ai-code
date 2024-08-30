public class EmailController {

 
    public class FlowInput {
        @InvocableVariable(label='Event ID')
        public String eventId;
        
       
    }
    
    public class FlowOutput {
        @InvocableVariable(label='Generated Text')
        public String generatedText;
    }

    @InvocableMethod(label='Email Prompt Generations')
    public static List<FlowOutput> promptGenerations(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();

        for (FlowInput input : inputs) {
            
            String prompt = 'Create an email for attendees to provide feedback on the Dreamin event. ' +
                            'Please include the following link for survey submission:\n\n' +
                            '(https://d4u000000ufituai-dev-ed.develop.my.salesforce-sites.com/survey?id=' +
                            input.eventId + '&attendeeId=78676' +  'Attendee name and attendeeId in the url should be dynamic.event id will be the value of variable eventId' + 
                            ' Give specific variable for adding attendee name in salutation. Do not include subject and add "Dreamin Event Organizer" in regards' + ')';

            
            aiplatform.ModelsAPI.createGenerations_Request request = new aiplatform.ModelsAPI.createGenerations_Request();

            request.modelName = 'sfdc_ai__DefaultOpenAIGPT35Turbo';

            aiplatform.ModelsAPI_GenerationRequest body = new aiplatform.ModelsAPI_GenerationRequest();
            request.body = body;

            body.prompt = prompt;

            String generatedText = '';

            try {
        
                aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
                aiplatform.ModelsAPI.createGenerations_Response response = modelsAPI.createGenerations(request);

               
                generatedText = response.Code200.generation.generatedText;

       
            } catch(aiplatform.ModelsAPI.createGenerations_ResponseException e) {
                System.debug('Response code: ' + e.responseCode);
                System.debug('The following exception occurred: ' + e);

               
                generatedText = 'Unable to generate text. Error code: ' + e.responseCode;
            }

            FlowOutput output = new FlowOutput();
            output.generatedText = generatedText;

         
            outputs.add(output);
        }

        return outputs;
    }
}