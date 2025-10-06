public with sharing class BookingService {

    @AuraEnabled
    public static Booking__c createFlightBooking(Map<String, Object> flightData, Id travelRequestId) {
        try {
             // Safely convert duration to Integer
            Decimal durationDecimal = (Decimal) flightData.get('duration');
            Integer durationInt = durationDecimal != null ? durationDecimal.intValue() : null;
            Booking__c booking = new Booking__c(
                RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Booking__c' AND Name='Flight Booking' LIMIT 1].Id,
                Airline__c = String.valueOf(flightData.get('airline')),
                Departure_Airport__c = String.valueOf(flightData.get('departureAirport')),
                Departure_Time__c = String.valueOf(flightData.get('departureTime')),
                Arrival_Airport__c = String.valueOf(flightData.get('arrivalAirport')),
                Arrival_Time__c = String.valueOf(flightData.get('arrivalTime')),
                Flight_Number__c = String.valueOf(flightData.get('flightNumber')),
                Duration__c = (Integer)durationInt ,
                Currency__c = (Decimal)flightData.get('price'),
                Travel_Request__c=travelRequestId
            );

            insert booking;
            return booking;

        } catch(Exception ex) {
            throw new AuraHandledException('Error creating Booking: ' + ex.getMessage());
        }
    }
}
