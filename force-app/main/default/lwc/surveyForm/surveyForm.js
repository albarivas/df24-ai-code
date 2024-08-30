import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getEventDetails from '@salesforce/apex/SurveyFormController.getEventDetails';
import getSurveyQuestions from '@salesforce/apex/SurveyFormController.getSurveyQuestions';
import saveSurveyResponses from '@salesforce/apex/SurveyFormController.saveSurveyResponses';

export default class SurveyForm extends NavigationMixin(LightningElement) {
    @track eventDetails;
    @track surveyQuestions = [];
    @track visibleQuestions = [];
    @track isLoading = false;
    @track showSurveyForm = false;
    @track currentPage = 1;
    @track totalPages = 1;
    @track error;
    @track showThankYouMessage = false;
    eventId;
    attendeeId;
    pageSize = 2;

    connectedCallback() {
        const url = window.location.href;
        const urlParams = new URL(url);
        this.eventId = urlParams.searchParams.get('id');
        this.attendeeId = urlParams.searchParams.get('attendeeId');
        if (this.eventId) {
            this.loadEventDetails();
        }
    }

    loadEventDetails() {
        if (this.eventId) {
            this.isLoading = true;
            console.log('Fetching event details for eventId:', this.eventId);
            getEventDetails({ eventId: this.eventId })
                .then(result => {
                    this.isLoading = false;
                    console.log('Event details fetched:', result);
                    this.eventDetails = result;
                    this.error = undefined;
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error('Error fetching event details:', error);
                    this.error = error;
                    this.eventDetails = undefined;
                });
        }
    }

    async handleGenerateSurvey() {
        try {
            this.isLoading = true;
            console.log('Starting survey generation for eventId:', this.eventId);

            const result = await getSurveyQuestions({ eventId: this.eventId });
            console.log('Survey questions fetched:', result);

            this.surveyQuestions = result.map(question => {
                const isRadioOrMultiSelect = question.questionType === 'radio' || question.questionType === 'multi-select';
                return {
                    ...question,
                    radioType: question.questionType === 'radio',
                    multiSelectType: question.questionType === 'multi-select',
                    numberType: question.questionType === 'number',
                    textType: question.questionType === 'text',
                    options: isRadioOrMultiSelect && Array.isArray(question.options) ? question.options.map(option => ({
                        label: option.option,
                        value: option.option
                    })) : [],
                    selectedOptions: [],
                    selectedOption: '',
                    response: ''
                };
            });

            this.totalPages = Math.ceil(this.surveyQuestions.length / this.pageSize);
            console.log('Total pages calculated:', this.totalPages);
            this.updateVisibleQuestions();
            this.showSurveyForm = true;
        } catch (error) {
            console.error('Error fetching survey questions:', error);
            this.error = 'Error fetching survey questions: ' + (error.body ? error.body.message : error.message);
        } finally {
            this.isLoading = false;
        }
    }

    updateVisibleQuestions() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        this.visibleQuestions = this.surveyQuestions.slice(startIndex, endIndex);
        console.log('Visible questions updated:', this.visibleQuestions);
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updateVisibleQuestions();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updateVisibleQuestions();
        }
    }

    handleOptionChange(event) {
        const questionId = event.target.dataset.id;
        const selectedOption = event.target.value;
        const question = this.surveyQuestions.find(q => q.id === questionId);
        if (question) {
            question.selectedOption = selectedOption;
        }
    }

    handleCheckboxChange(event) {
        const questionId = event.target.dataset.id;
        const selectedOptions = event.detail.value;
        const question = this.surveyQuestions.find(q => q.id === questionId);
        if (question) {
            question.selectedOptions = selectedOptions;
        }
    }

    handleInputChange(event) {
        const questionId = event.target.dataset.id;
        const response = event.target.value;
        const question = this.surveyQuestions.find(q => q.id === questionId);
        if (question) {
            question.response = response;
        }
    }

    async handleSubmit() {
        this.isLoading = true;
        try {
            const surveyResponses = this.surveyQuestions.map(question => {
                let responseValue = '';
                if (question.radioType) {
                    responseValue = question.selectedOption;
                } else if (question.multiSelectType) {
                    responseValue = question.selectedOptions.join(',');
                } else {
                    responseValue = question.response;
                }
                return {
                    questionId: question.id,
                    response: responseValue
                };
            });

            console.log('Survey responses to be saved:', surveyResponses);

            const result = await saveSurveyResponses({
                eventId: this.eventId,
                attendeeId: this.attendeeId,
                surveyResponses
            });
            console.log('Survey responses saved successfully:', result);
            this.error = undefined;
            this.showThankYouMessage = true;
            this.showSurveyForm = false;
            
        } catch (error) {
            console.error('Error saving survey responses:', error);
            this.error = 'Error saving survey responses: ' + (error.body ? error.body.message : error.message);
        } finally {
            this.isLoading = false;
        }
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }
}