import { LightningElement, api, track } from 'lwc';
import getFlights from '@salesforce/apex/FlightService.getFlights';

export default class BookFlights extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track flights = [];
    @track flightsError;

    handleSearch() {
        this.isLoading = true;
        this.flights = [];
        this.flightsError = undefined;

        getFlights({ travelRequestId: this.recordId })
            .then(result => {
                this.flights = result;
                this.isLoading = false;
            })
            .catch(error => {
                this.flightsError = 'Error fetching flights: ' + (error?.body?.message || error);
                this.isLoading = false;
            });
    }

    handleBook(event) {
        const flightId = event.target.dataset.id;
        // For now just log selected flight, later we can call Apex to create Booking
        const selectedFlight = this.flights.find(f => f.id === flightId);
        console.log('Selected flight to book:', selectedFlight);
    }
}
