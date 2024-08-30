import { api, LightningElement } from 'lwc';
import generateNewsletter from '@salesforce/apex/NewsletterGenerator.generateNewsletter';

export default class GenerateNewsletter extends LightningElement {
    error;
    showSpinner = false;
    @api recordId;

    async generateNewsletter() {
        this.showSpinner = true;
        try {
            const response = await generateNewsletter({
                eventId: this.recordId
            });
            const parsedResponse = JSON.parse(response);
            this.template.querySelector('div.newsletter').innerHTML = parsedResponse.code;
            this.error = undefined;
        } catch (error) {
            this.template.querySelector('div.newsletter').innerHTML = '';
            this.error = JSON.stringify(error);
        } finally {
            this.showSpinner = false;
        }
    }
}