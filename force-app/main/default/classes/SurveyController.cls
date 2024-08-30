public class SurveyController {
        @AuraEnabled
        public static void saveSurvey(Id eventId, String surveyQuestionsJSON) {
            try {
                
                List<SurveyQuestion> surveyQuestions = (List<SurveyQuestion>) JSON.deserialize(surveyQuestionsJSON, List<SurveyQuestion>.class);
    
                List<Survey__c> questionsToInsert = new List<Survey__c>();
                List<Survey_Question_Options__c> optionsToInsert = new List<Survey_Question_Options__c>();
    
                for (SurveyQuestion questionData : surveyQuestions) {
                    Survey__c question = new Survey__c();
                    // question.Event_Name__c = eventName;
                    question.Event_Name__c = eventId;
                    question.Question__c = questionData.question;
                    question.Question_Type__c = questionData.dataType;
                    questionsToInsert.add(question);
                }
    
                insert questionsToInsert;
    
                for (Integer i = 0; i < questionsToInsert.size(); i++) {
                    SurveyQuestion questionData = surveyQuestions[i];
                    Survey__c insertedQuestion = questionsToInsert[i];
    
                    if (questionData.options != null) {
                        for (SurveyOption optionData : questionData.options) {
                            Survey_Question_Options__c option = new Survey_Question_Options__c();
                            option.Survey_Question__c = insertedQuestion.Id;
                            option.Option__c = optionData.label;
                            optionsToInsert.add(option);
                        }
                    }
                }
    
                insert optionsToInsert;
            } catch (Exception e) {
                throw new AuraHandledException('Error saving survey: ' + e.getMessage());
            }
        }
    
        public class SurveyQuestion {
            public String question { get; set; }
            public String dataType { get; set; }
            public List<SurveyOption> options { get; set; }
        }
    
        public class SurveyOption {
            public String label { get; set; }
            public String value { get; set; }
        }
}