public class SendEmailController {

    public class EmailInput {
        @InvocableVariable(label='Attendee Lists')
        public List<Attendee__c> attendeeLists;

        @InvocableVariable(label='Generated Email Template')
        public String generatedEmail;

        @InvocableVariable(label='Email Subject')
        public String subject;
    }

    @InvocableMethod(label='Send Customized Emails')
    public static void sendCustomizedEmails(List<EmailInput> inputs) {
        for (EmailInput input : inputs) {
            List<Attendee__c> attendees = input.attendeeLists;
            String generatedEmail = input.generatedEmail;
            String subject = input.subject;

            for (Attendee__c attendee : attendees) {
                String personalizedEmail = generatedEmail.replace('attendeeId=78676', 'attendeeId=' + attendee.Id);
                personalizedEmail = personalizedEmail.replace('[Attendee Name]',  attendee.Name);
                sendEmail(attendee.Email__c, subject, personalizedEmail);
            }
        }
    }

    private static void sendEmail(String recipientEmail, String subject, String body) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { recipientEmail });
        email.setSubject(subject);
        email.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}