import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitApplication from '@salesforce/apex/GrantApplicationController.submitApplication';

export default class GrantApplicationForm extends LightningElement {
    @track firstName = '';
    @track lastName = '';
    @track phone = '';
    @track postalCode = '';
    @track monthlyIncome = 0;
    @track supportOption = '';

    supportOptions = [
        { label: 'Option 1', value: 'Option 1' },
        { label: 'Option 2', value: 'Option 2' },
        { label: 'Option 3', value: 'Option 3' },
    ];

    handleInputChange(event) {
        const field = event.target.dataset.id;
        if (field) {
            this[field] = event.target.value;
        }
    }

    handleSubmit() {
        submitApplication({
            firstName: this.firstName,
            lastName: this.lastName,
            phone: this.phone,
            postalCode: this.postalCode,
            monthlyIncome: this.monthlyIncome,
            supportOption: this.supportOption
        })
        .then(() => {
            this.showToast('Success', 'Application Submitted Successfully', 'success');
            // Optionally reset form fields here
        })
        .catch(error => {
            this.showToast('Error', 'Error in Application Submission', 'error');
            console.error(error);
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}