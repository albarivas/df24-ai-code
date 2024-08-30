public without sharing class SurveyFormController {

    @AuraEnabled(cacheable=true)
    public static Event__c getEventDetails(String eventId) {
        System.debug('Event Id: ' + eventId);
        return [SELECT Id, Name, Logo_Url__c FROM Event__c WHERE Id = :eventId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static List<Object> getSurveyQuestions(String eventId) {
        List<Object> surveyQuestions = new List<Object>();
        try {
            System.debug('Fetching surveys for eventId: ' + eventId);
            List<Survey__c> surveys = [SELECT Id, Question__c, Question_Type__c 
                                       FROM Survey__c 
                                       WHERE Event_Name__c = :eventId];
            System.debug('Fetched surveys: ' + surveys);

            for (Survey__c survey : surveys) {
                Map<String, Object> questionMap = new Map<String, Object>();
                questionMap.put('id', survey.Id);
                questionMap.put('question', survey.Question__c);
                questionMap.put('questionType', survey.Question_Type__c);
                System.debug('Processing survey: ' + survey);

                if (survey.Question_Type__c == 'radio' || survey.Question_Type__c == 'multi-select') {
                    List<Object> optionsList = new List<Object>();
                    List<Survey_Question_Options__c> options = [SELECT Id, Option__c 
                                                                 FROM Survey_Question_Options__c 
                                                                 WHERE Survey_Question__c = :survey.Id];
                    System.debug('Fetched options for survey ' + survey.Id + ': ' + options);
                    for (Survey_Question_Options__c option : options) {
                        Map<String, Object> optionMap = new Map<String, Object>();
                        optionMap.put('id', option.Id);
                        optionMap.put('option', option.Option__c);
                        optionsList.add(optionMap);
                    }
                    questionMap.put('options', optionsList);
                }
                surveyQuestions.add(questionMap);
            }
            System.debug('Survey questions mapped: ' + surveyQuestions);
        } catch (Exception e) {
            System.debug('Error in getSurveyQuestions: ' + e.getMessage());
        }
        return surveyQuestions;
    }

    @AuraEnabled
    public static List<Survey_Response__c> saveSurveyResponses(Id eventId, Id attendeeId, List<Map<String, String>> surveyResponses) {
        List<Survey_Response__c> responsesToInsert = new List<Survey_Response__c>();
        Set<Id> questionIds = new Set<Id>();
        Map<Id, String> questionNames = new Map<Id, String>();
        
        for (Map<String, String> response : surveyResponses) {
            questionIds.add(response.get('questionId'));
        }
        
        if (!questionIds.isEmpty()) {
            List<Survey__c> questions = [SELECT Id, Name FROM Survey__c WHERE Id IN :questionIds];
            for (Survey__c question : questions) {
                questionNames.put(question.Id, question.Name);
            }
        }
        
        String attendeeName = '';
        if (attendeeId != null) {
            List<Attendee__c> attendees = [SELECT Id, Name FROM Attendee__c WHERE Id = :attendeeId LIMIT 1];
            if (!attendees.isEmpty()) {
                attendeeName = attendees[0].Name;
            }
        }
        
        for (Map<String, String> response : surveyResponses) {
            Survey_Response__c surveyResponse = new Survey_Response__c();
            surveyResponse.Event__c = eventId;
            surveyResponse.Attendee__c = attendeeId;
            surveyResponse.Survey_Question__c = response.get('questionId');
            surveyResponse.Response__c = response.get('response');
            
            String questionId = response.get('questionId');
            String questionName = questionNames.get(questionId);
           
                surveyResponse.Name = questionName + ' - ' + attendeeName;
           
            
            responsesToInsert.add(surveyResponse);
        }
        
        try {
            insert responsesToInsert;
            return responsesToInsert;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    

//     @future(callout=true)
//     public static void translateResponse(String responseJson) {
//         List<Survey_Response__c> responses = (List<Survey_Response__c>) JSON.deserialize(responseJson, List<Survey_Response__c>.class);
//         System.debug('Deserialized responses: ' + responses);
    

//         List<Survey_Response__c> responsesToUpdate = new List<Survey_Response__c>();
    
       
//         for (Survey_Response__c response : responses) {
//             String prompt = 'If the content of the response is not in English, then translate the text into English: ' + response.Response__c;
            
      
//             String translatedResponse = SurveyController.promptGenerations(prompt);
    
          
//             response.Translated_Response__c = translatedResponse;
    
//             responsesToUpdate.add(response);
//         }
//         try {
//             update responsesToUpdate;

//     }
//     catch (Exception e){
//         System.debug('Error in translating response: ' +e.getMessage());
//     }
    

// }
}