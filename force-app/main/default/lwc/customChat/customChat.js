import { LightningElement, api, wire } from "lwc";
import createChatGenerations from "@salesforce/apex/LLMService.createChatGenerations";
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const FIELDS = ["Session__c.Name", "Session__c.Session_Summary__c"];

export default class ChatLWC extends LightningElement {
  messages = []; // Array to store chat messages
  userMessage = ""; // User input message
  isLoading = false; // Track loading state
  systemPrompt = "";
  @api recordId;

  @wire(getRecord, { recordId: "$recordId", fields: FIELDS})
  wiredSessionDetails({data, error}){
    if (data) {
      this.systemPrompt = 'User is viewing the session with title ' + data.fields.Name.value + 'and abstract ' + data.fields.Name.Session_Summary__c;
      this.error = undefined;
    } else if (error) {
      this.systemPrompt = 'Impossible to gather session details';
      let message = "Unknown error";
      if (Array.isArray(error.body)) {
        message = error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        message = error.body.message;
      }
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error loading contact",
          message,
          variant: "error",
        }),
      );
    }

  }

  // Handle user input change
  handleInputChange(event) {
    this.userMessage = event.target.value;
  }

  // Scroll to the bottom of the chat container
  renderedCallback() {
    this.scrollToBottom();
  }

  // Handle send message button click
  handleSendMessage() {
    if (this.userMessage.trim()) {
      const userMessageObj = {
        id: this.messages.length + 1,
        text: this.userMessage,
        role: "user",
        isUser: true,
      };

      // Add user message to the messages array
      this.messages = [...this.messages, userMessageObj];
      this.isLoading = true; // Show loading indicator

      // Prepare user message array for API call
      let messageArray = this.messages.map((msg) => ({
        role: msg.isUser ? "user" : "assistant",
        message: msg.text,
      }));

      // Call Apex method to fetch chat response
      createChatGenerations({ serializedMessages: JSON.stringify(messageArray), systemPrompt: this.systemPrompt})
        .then((result) => {
          this.addMessage(result);
        })
        .catch((error) => {
          console.error("Error fetching bot response", JSON.stringify(error));
        })
        .finally(() => {
          this.isLoading = false; // Hide loading indicator
        });

      this.userMessage = ""; // Clear user input
    }
  }

  // Simulate typing effect for the chat response
  addMessage(fullText) {
    const botResponseObj = {
      id: this.messages.length + 1,
      text: fullText,
      role: "assistant",
      isUser: false,
    };
    
    this.messages = [...this.messages, botResponseObj];
    this.scrollToBottom();
  }

  // Scroll to the bottom of the chat container
  scrollToBottom() {
    const chatContainer = this.template.querySelector(".slds-scrollable_y");
    if (chatContainer) {
      chatContainer.scrollTop = chatContainer.scrollHeight;
    }
  }
}