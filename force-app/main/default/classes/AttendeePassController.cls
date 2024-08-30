public with sharing class AttendeePassController {
    

    @AuraEnabled
    public static Boolean sendEmail(String emaiLBody){
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'mrehman@cloud-1.co'};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Attendee Pass');
            mail.setHtmlBody(emaiLBody);
            // Pass this email message to the built-in sendEmail method 
            // of the Messaging class
            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                                     new Messaging.SingleEmailMessage[] { mail });
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}