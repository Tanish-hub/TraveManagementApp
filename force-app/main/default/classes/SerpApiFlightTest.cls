
public with sharing class SerpApiFlightTest {

    @AuraEnabled
    public static void testCallout() {
        try {
            // 1️⃣ Fetch API key from Protected Custom Metadata
            External_API_Key__mdt apiRecord = [
                SELECT API_Key__c 
                FROM External_API_Key__mdt 
                WHERE DeveloperName = 'SerpAPI_Google_Flights'
                LIMIT 1
            ];
            String apiKey = apiRecord.API_Key__c;

            // 2️⃣ Sample flight search parameters
            String source = 'New York';
            String destination = 'London';
            String startDate = '2025-10-25';

            // 3️⃣ Build query string with API key
            String endpoint =  '/search.json?engine=google_flights'
                  + '&departure_id=JFK'
                  + '&arrival_id=LHR'
                  + '&outbound_date=2025-10-25'
                  + '&return_date=2025-10-30'
                  + '&currency=USD'
                  + '&hl=en'
                  + '&api_key=' + apiKey;

            // 4️⃣ Prepare HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:SerpAPI_GoogleFlights' + endpoint);
            req.setMethod('GET');
            req.setTimeout(6000);

            // 5️⃣ Send request
            Http http = new Http();
            HttpResponse res = http.send(req);

            // 6️⃣ Debug logs for verification
            System.debug('Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());

        } catch(Exception e) {
            System.debug('Callout Error: ' + e.getMessage());
        }
    }
}
