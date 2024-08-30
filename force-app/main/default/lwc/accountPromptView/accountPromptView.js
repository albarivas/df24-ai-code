import { LightningElement,api } from 'lwc';
import  generatePrompt  from '@salesforce/apex/AccountPromptController.generatePrompt';

const CONST_PROMPT_TESTING = 'Prompt Testing';

export default class AccountPromptView extends LightningElement {

    @api recordId;
    prompt;
    promptLoading = false;
    images = [];


    regenerateResponse() {
        this.promptLoading = true;
        generatePrompt({accountId: this.recordId})
        .then(promptResponse => {
            this.prompt = promptResponse.response;
            this.images = promptResponse.relatedImages;
            this.promptLoading = false;
        })
    }


}