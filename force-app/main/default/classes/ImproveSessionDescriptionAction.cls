public with sharing class ImproveSessionDescriptionAction {
    @InvocableMethod(
        label='Improve Session Title and Abstract'
        description='Improves title and abstract for a given session.'
    )
    public static List<Response> generate(List<Request> requests) {
        Id sessionId = (Id) requests[0].sessionId;
        Session__c session = [SELECT Name, Session_Abstract__c FROM Session__c WHERE Id = :sessionId];

        String prompt = 'Generate a better title and abstract for the next session:\n';
        prompt += '- Original title: ' + session.Name + '\n';
        prompt += '- Original abstract: ' + session.Session_Abstract__c + '\n';
        prompt += 'Return a valid JSON indicating the new suggested title and abstract.\n';
        prompt += 'Example:\n';
        prompt += '{ "sessionTitle": "Title for the session", "sessionAbstract": "Abstract for the session" }';


        String promptTemplateResponse = LLMService.generateText(
            prompt
        );

        Response response = (Response) JSON.deserialize(
            promptTemplateResponse,
            Response.class
        );

        return new List<Response>{ response };
    }

    public class Request {
        @InvocableVariable(
            required=true
            description='Id of the session for which we want to improve its title and abstract.'
        )
        public Id sessionId;
    }

    public class Response {
        @InvocableVariable(
            description='Generated title'
        )
        public String sessionTitle;
        @InvocableVariable(
            description='Generated abstract'
        )
        public String sessionAbstract;
    }
}