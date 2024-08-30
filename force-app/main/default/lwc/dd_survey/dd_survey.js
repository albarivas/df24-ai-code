import { LightningElement, wire } from 'lwc';
import generateText from '@salesforce/apex/LLMService.generateText';
import saveSurvey from '@salesforce/apex/SurveyController.saveSurvey';
import getEvents from '@salesforce/apex/EventController.getEvents';
import eventLogoResource from '@salesforce/resourceUrl/EventLogo';

export default class DdSurvey extends LightningElement {
    eventName = 'Dubai Dreamin';
    selectedEvent;
    selectedEventId;
    surveyQuestions = [];
    visibleQuestions = [];
    error;
    isLoading = false;
    showGenerateSurveyPage = false
    isModalOpen = false;
    showSurveyForm=false
    modalQuestion = {};
    currentPage = 1;
    totalPages = 1;
    numQuestions = 6;

    pageSize = 2;
     eventOptions = [];

     eventLogo = eventLogoResource;
     get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

 @wire(getEvents)
    wiredEvents({ error, data }) {
        if (data) {
            this.eventData = data
            this.eventOptions = data.map(event => {
                return { 
                    label: event.Name, 
                     value: event.Id 
                    
                };
            });
            console.log(' eventData :',  JSON.stringify(this.eventData ));
        } else if (error) {
            console.error('Error fetching events:', error);
        }
    }

    handleEventNameChange(event) {
        this.selectedEventId = event.target.value;
        this.selectedEvent = this.eventData.find(event => event.Id === this.selectedEventId);
        this.eventName = this.selectedEvent.Name;
        console.log('eventName : ', this.eventName);
        console.log('selectedEvent : ', this.selectedEvent);
        this.showGenerateSurveyPage = true;
    }

    handleNumQuestionsChange(event) {
        this.numQuestions = event.target.value;
    }

    async handleGenerateSurvey() {
        this.isLoading = true; // Start loader
        const prompt = `Generate a JSON list of ${this.numQuestions} survey questions for the ${this.eventName} event. 
        The response, called surveyQuestions, should include the following details:
        - Question
        - Id
        - dataType (text, radio, multi-select, or number)
        - if data type multi-select or radio provide it's options as well
        - Boolean keys indicating the data type: textType, radioType, multiSelectType, and numberType.`;

        try {
            const result = await generateText({ prompt });
            console.log('Result: ', result);
            this.surveyQuestions = JSON.parse(result).surveyQuestions;
            this.surveyQuestions.forEach(question => {
                if (question.options) {
                    question.options = question.options.map(option => ({ label: option, value: option }));
                }
            });
            this.totalPages = Math.ceil(this.surveyQuestions.length / this.pageSize);
            this.updateVisibleQuestions();
            console.log('questions : ', JSON.stringify(this.surveyQuestions));
        } catch (error) {
            this.error = 'Error generating survey: ' + error.body.message;
            console.error('Error generating survey:', error);
        } finally {
            this.showSurveyForm= true
            this.isLoading = false; // Stop loader
        }
    }

    updateVisibleQuestions() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        this.visibleQuestions = this.surveyQuestions.slice(startIndex, endIndex);
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

    // handleEditClick(event) {
    //     const questionId = event.target.dataset.questionid;
    //     this.modalQuestion = JSON.parse(JSON.stringify(this.surveyQuestions.find(question => question.id === parseInt(questionId))));
    //     let qq = JSON.parse(JSON.stringify(this.surveyQuestions.find(question => question.id === parseInt(questionId))));
    //      qq.options.forEach((option, index) => {
    //         option.id = index + 1;
    //     });
    //     console.log('qq : ',JSON.stringify(qq));
    //      this.modalQuestion= qq
    //     this.isModalOpen = true;
    // }


    handleEditClick(event) {
        const questionId = event.target.dataset.questionid;
        const question = this.surveyQuestions.find(question => question.id === parseInt(questionId));
    
        if (!question) return;
    
      
        const clonedQuestion = JSON.parse(JSON.stringify(question));
    
      
        if (clonedQuestion.options) {
            clonedQuestion.options = clonedQuestion.options.map((option, index) => ({
                ...option,
                id: index + 1
            }));
        }
    
        this.modalQuestion = clonedQuestion;
        this.isModalOpen = true;
        console.log('Modal Question: ', JSON.stringify(this.modalQuestion));
    }
    
    handleModalQuestionChange(event) {
        this.modalQuestion.question = event.target.value;
    }

    handleModalOptionChange(event) {
        const index = event.target.dataset.index;
        if (this.modalQuestion.options && this.modalQuestion.options[index]) {
            this.modalQuestion.options[index].value = event.target.value;
            this.modalQuestion.options[index].label = event.target.value;
        }

    }

    handleSaveModal() {
        const index = this.surveyQuestions.findIndex(question => question.id === this.modalQuestion.id);
        if (index !== -1) {
            this.surveyQuestions[index] = { ...this.modalQuestion };
        }
        this.updateVisibleQuestions();
        this.closeModal();
    }

    closeModal() {
        this.isModalOpen = false;
    }

   
        // Handle survey submission
        async handleSubmit() {
            try {
                const surveyQuestionsJSON = JSON.stringify(this.surveyQuestions);
                if (surveyQuestionsJSON) {
                    await saveSurvey({ eventId: this.selectedEventId, surveyQuestionsJSON });
                    window.alert('Survey submitted successfully');
                } else {
                    console.error('Empty surveyQuestionsJSON:', surveyQuestionsJSON);
                }
            } catch (error) {
                console.error('Error saving survey:', error);
            }
        }
        
        
        
        
    }