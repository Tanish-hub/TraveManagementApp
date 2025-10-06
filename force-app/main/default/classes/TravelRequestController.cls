public with sharing class TravelRequestController {

    /**
     * Fetch flights for a Travel Request
     * @param travelRequestId Id of the Travel Request
     * @return List of FlightOption objects
     */
    @AuraEnabled(cacheable=true)
    public static List<TravelRequestService.FlightOption> fetchFlights(Id travelRequestId) {
        // Fetch Travel Request data
        Travel_Request__c tr = [
            SELECT Source__c, Destination__c, Start_Date__c, End_Date__c
            FROM Travel_Request__c
            WHERE Id = :travelRequestId
            LIMIT 1
        ];

        // Call service class to get flights
        List<TravelRequestService.FlightOption> flights = TravelRequestService.getFlights(
            tr.Source__c,
            tr.Destination__c,
            String.valueOf(tr.Start_Date__c),
            String.valueOf(tr.End_Date__c)
        );

        return flights;
    }
}
