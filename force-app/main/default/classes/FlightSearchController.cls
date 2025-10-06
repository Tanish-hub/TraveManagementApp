public with sharing class FlightSearchController {

    @AuraEnabled(cacheable=false)
    public static String fetchFlights(Id travelRequestId) {
        try {
            // 1. Get Travel Request details
            Travel_Request__c tr = [
                SELECT Source__c, Destination__c, Start_Date__c, End_Date__c
                FROM Travel_Request__c
                WHERE Id = :travelRequestId
                LIMIT 1
            ];

            // 2. Get API Key from Custom Metadata
            External_API_Key__mdt apiRecord = [
                SELECT API_Key__c 
                FROM External_API_Key__mdt 
                WHERE DeveloperName = 'SerpAPI_Google_Flights'
                LIMIT 1
            ];
            String apiKey = apiRecord.API_Key__c;

            // 3. Format dates for API (yyyy/MM/d)
            // 3. Format dates for API (yyyy/MM/d)
String outboundDate = tr.Start_Date__c.year() + '/' + tr.Start_Date__c.month() + '/' + tr.Start_Date__c.day();
String returnDate = tr.End_Date__c.year() + '/' + tr.End_Date__c.month() + '/' + tr.End_Date__c.day();


            // 4. Build Named Credential endpoint URL
            String endpoint = 'callout:SerpAPI_GoogleFlights/search.json' +
                              '?engine=google_flights' +
                              '&departure_id=' + EncodingUtil.urlEncode(tr.Source__c, 'UTF-8') +
                              '&arrival_id=' + EncodingUtil.urlEncode(tr.Destination__c, 'UTF-8') +
                              '&outbound_date=' + outboundDate +
                              '&return_date=' + returnDate +
                              '&currency=USD' +
                              '&hl=en' +
                              '&api_key=' + apiKey;

            // 5. Make HTTP Callout
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');

            HttpResponse res = http.send(req);

            // 6. Check response
            if (res.getStatusCode() == 200) {
                return res.getBody(); // Send full JSON response to LWC
            } else {
                throw new AuraHandledException('Error from API: ' + res.getStatusCode() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Failed to fetch flights: ' + e.getMessage());
        }
    }
}
