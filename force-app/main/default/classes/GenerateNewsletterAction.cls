public with sharing class GenerateNewsletterAction {
    @InvocableMethod(
        label='Generate Newsletter for Conference'
        description='Generates a newsletter for a given conference.'
    )
    public static List<Response> generate(List<Request> requests) {
        Id conferenceId = (Id) requests[0].conferenceId;

        Map<String, String> conference = new Map<String, String>();
        conference.put('id', conferenceId);

        ConnectApi.WrappedValue conferenceValue = new ConnectApi.WrappedValue();
        conferenceValue.value = conference;

        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        inputParams.put('Input:Conference', conferenceValue);

        String promptTemplateResponse = LLMService.generateResponseFromPromptTemplate(
            'Generate_Newsletter_RichText_Plain',
            inputParams
        );

        System.debug(promptTemplateResponse);

        Newsletter__c newsletter = new Newsletter__c();
        newsletter.Content__c = promptTemplateResponse;
        newsletter.Conference__c = conferenceId;
        insert newsletter;

        Response response = new Response();
        response.code = promptTemplateResponse;
        return new List<Response>{ response };
    }

    public class Request {
        @InvocableVariable(
            required=true
            description='Id of the conference for which we want to generate the newsletter.'
        )
        public String conferenceId;
    }

    public class Response {
        @InvocableVariable(
            description='Generated newsletter rich text'
        )
        public String code;
    }
}