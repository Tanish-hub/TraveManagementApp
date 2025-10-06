public with sharing class GoogleFlightsFacade {
    @AuraEnabled(cacheable=false)
    public static List<GoogleFlightsParser.FlightOptionWrapper> getFlights(Id travelRequestId) {
        // 1. Get raw JSON from callout
        String rawJson = GoogleFlightsService.getFlights(travelRequestId);

        // 2. Parse JSON
        return GoogleFlightsParser.parse(rawJson);
    }
}
