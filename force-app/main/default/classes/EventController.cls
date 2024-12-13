public with sharing class EventController {
    @AuraEnabled(cacheable=true)
    public static List<Conference__c> getEvents() {
        return [SELECT Id, Name, Logo_Url__c FROM Conference__c];
    }
}