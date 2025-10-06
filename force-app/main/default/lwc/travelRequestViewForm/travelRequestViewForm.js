import { LightningElement, api, track } from 'lwc';
import getFlights from '@salesforce/apex/GoogleFlightsFacade.getFlights';
import createFlightBooking from '@salesforce/apex/BookingService.createFlightBooking';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TravelRequestViewForm extends LightningElement {
    @api recordId;
    @track flightOptions = [];
        showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant, // 'success', 'error', 'info', 'warning'
        });
        this.dispatchEvent(evt);
    }

    handleSearchFlights() {
        getFlights({ travelRequestId: this.recordId })
            .then(result => {
                let options = result.map((option, idx) => {
                    option.uniqueKey = 'option-' + idx;
                    option.legs = option.legs.map(leg => {
                        return {
                            ...leg,
                            uniqueKey: leg.flightNumber + '-' + leg.departureTime
                        };
                    });
                    return option;
                });
                this.flightOptions = options.slice(0, 5);
            })
            .catch(error => {
                console.error('Error fetching flights:', error);
            });
    }

    handleBookFlight(event) {
    const optionKey = event.target.dataset.optionKey;
    const selectedOption = this.flightOptions.find(opt => opt.uniqueKey === optionKey);

    if (selectedOption) {
        // Prepare minimal payload
        const bookingPayload = {
            airline: selectedOption.legs[0].airline,
            departureAirport: selectedOption.legs[0].departureAirport,
            departureTime: selectedOption.legs[0].departureTime,
            arrivalAirport: selectedOption.legs[selectedOption.legs.length - 1].arrivalAirport,
            arrivalTime: selectedOption.legs[selectedOption.legs.length - 1].arrivalTime,
            flightNumber: selectedOption.legs[0].flightNumber,
            duration: selectedOption.totalDuration,
            price: selectedOption.price
        };

        createFlightBooking({ flightData: bookingPayload, travelRequestId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Booking created successfully!', 'success'); })
            .then(result => {
                this.showToast('Success', 'Booking created: ' + result.Id, 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }
}

}
