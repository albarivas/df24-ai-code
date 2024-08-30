public with sharing class NewsletterGenerator {
    @AuraEnabled
    public static String generateNewsletter(String eventId) {
        Map<String, String> event = new Map<String, String>();
        event.put('id', eventId);

        ConnectApi.WrappedValue eventValue = new ConnectApi.WrappedValue();
        eventValue.value = event;

        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        inputParams.put('Input:Event', eventValue);

        return LLMService.generateResponseFromPromptTemplate(
            'Generate_Newsletter',
            inputParams
        );
    }
}