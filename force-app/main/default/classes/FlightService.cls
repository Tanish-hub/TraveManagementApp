public with sharing class FlightService {

    // Named Credential (replace with your actual NC name in Salesforce)


    /**
     * Callout method to fetch flights from Google Flights API via SerpAPI
     * @param departureId - Departure airport code (e.g., "PEK")
     * @param arrivalId - Arrival airport code (e.g., "AUS")
     * @param outboundDate - Outbound date (YYYY-MM-DD)
     * @param returnDate - Return date (YYYY-MM-DD)
     * @return List of FlightParser.FlightOption
     */
    @AuraEnabled(cacheable=false)
    public static List<FlightParser.FlightOption> getFlights(Id travelRequestId
    ) {

            Travel_Request__c tr = [
            SELECT Source__c, Destination__c, Start_Date__c, End_Date__c
            FROM Travel_Request__c
            WHERE Id = :travelRequestId
            LIMIT 1
        ];

        try {
            // Fetch API Key from Custom Metadata Type
            External_API_Key__mdt apiRecord = [
                SELECT API_Key__c 
                FROM External_API_Key__mdt 
                WHERE DeveloperName = 'SerpAPI_Google_Flights'
                LIMIT 1
            ];
            String apiKey = apiRecord.API_Key__c;


            // Construct endpoint (relative to Named Credential)
            String endpoint = 'callout:SerpAPI_GoogleFlights/search.json?engine=google_flights'
                            + '&departure_id=' + EncodingUtil.urlEncode(tr.Source__c, 'UTF-8')
                            + '&arrival_id=' + EncodingUtil.urlEncode(tr.Destination__c, 'UTF-8')
                            + '&outbound_date=' + EncodingUtil.urlEncode(String.valueOf(tr.Start_Date__c), 'UTF-8')
                            + '&return_date=' + EncodingUtil.urlEncode(String.valueOf(tr.End_Date__c), 'UTF-8')
                            + '&currency=USD'
                            + '&hl=en'
                            + 'type=2'
                            + '&api_key=' + EncodingUtil.urlEncode(apiKey, 'UTF-8');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                // Parse and return flight options
                System.debug('JSON Response from API: ' +  res.getStatus() + ' Body: ' + res.getBody());
                return FlightParser.parseFlights(res.getBody());
                 
            } else {
                System.debug('❌ FlightService - API Call Failed: ' + res.getStatus() + ' Body: ' + res.getBody());
                return new List<FlightParser.FlightOption>();
            }
        } catch (Exception ex) {
            System.debug('❌ FlightService - Exception: ' + ex.getMessage());
            return new List<FlightParser.FlightOption>();
        }
    }
}
