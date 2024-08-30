import { LightningElement, api } from 'lwc';

export default class SurveyPrompt extends LightningElement {

    @api surveyBody;
    firstRender = true;
    // attendeePassBodySampe = '``html <!DOCTYPE html> <html lang="en"> <head> <meta charset="UTF-8"> <meta name="viewport" content="width=device-width, initial-scale=1.0"> <title>E-Pass for Dreamin\' Event - Novak Djokovic</title> <style> body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4; } .container { max-width: 600px; margin: 20px auto; background: #fff; padding: 20px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); } .header { text-align: center; padding-bottom: 20px; } .header img { max-width: 100px; } .event-info { margin-bottom: 20px; } .event-info h2, .event-info p { margin: 0; padding: 4px 0; } .e-pass { background: #e7f3fe; border-left: 6px solid #2196F3; padding: 10px 20px; margin: 20px 0; font-size: 16px; } </style> </head> <body> <div class="container"> <div class="header"> <img src="event_logo.png" alt="Dreamin\' Event Logo"> <h1>Dreamin\' Event</h1> </div> <div class="event-info"> <h2>E-Pass for Entry</h2> <p>Name: Novak Djokovic</p> <p>Event: Dreamin\' Event</p> <p>Date: 2023-09-15</p> <p>Time: 18:00</p> <p>Venue: Dreamland Arena, New York</p> </div> <div class="e-pass"> Please present this E-Pass at the entrance. Enjoy the event! </div> </div> </body> </html> ```';

    renderedCallback() {
        if (!this.firstRender) {
            return;
        }
        this.firstRender = false;
        console.log(this.surveyBody);
        this.surveyBody = this.surveyBody.replace('```html', '');
        this.surveyBody = this.surveyBody.replace('```', '');
        // let surveyBodyText = 
        this.surveyBody =  this.surveyBody.split('<body>')[1];
        this.surveyBody =  this.surveyBody.split('</body>')[0];
        
    }

}