public with sharing class EventController {
    @AuraEnabled(cacheable=true)
    public static List<Event__c> getEvents() {
        return [SELECT Id, Name, Logo_Url__c FROM Event__c];
    }
}