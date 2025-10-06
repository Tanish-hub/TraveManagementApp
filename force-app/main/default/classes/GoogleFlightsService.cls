public with sharing class GoogleFlightsService {
    @AuraEnabled(cacheable=false)
    public static String getFlights(Id travelRequestId) {
        Travel_Request__c tr = [
            SELECT Source__c, Destination__c, Start_Date__c 
            FROM Travel_Request__c 
            WHERE Id = :travelRequestId 
            LIMIT 1
        ];

        // Format date YYYY-MM-DD
        String startDate = tr.Start_Date__c != null 
            ? String.valueOf(tr.Start_Date__c.year()) + '-' +
              String.valueOf(tr.Start_Date__c.month()) + '-' +
              String.valueOf(tr.Start_Date__c.day())
            : '';

        // Fetch API key from custom metadata
        External_API_Key__mdt apiKeyRecord = [
            SELECT API_Key__c 
            FROM External_API_Key__mdt 
            WHERE DeveloperName='SerpAPI_Google_Flights' 
            LIMIT 1
        ];
        String apiKey = apiKeyRecord.API_Key__c;

        String endpoint = '/search.json?engine=google_flights'
            + '&departure_id=' + EncodingUtil.urlEncode(tr.Source__c, 'UTF-8')
            + '&arrival_id=' + EncodingUtil.urlEncode(tr.Destination__c, 'UTF-8')
            + '&outbound_date=' + EncodingUtil.urlEncode(startDate, 'UTF-8')
            + '&currency=INR&hl=en&type=2&api_key=' + EncodingUtil.urlEncode(apiKey, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SerpAPI_GoogleFlights' + endpoint); // Named Credential
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res;

        try {
            res = http.send(req);

            // ✅ Log the callout (success or failure)
            IntegrationLogger.logCallout(
                'callout:SerpAPI_GoogleFlights' + endpoint, // full endpoint
                null,                                      // no request body (GET call)
                res,
                travelRequestId                            // link back to Travel Request
            );

            if (res.getStatusCode() == 200) {
                return res.getBody();
            } else {
                throw new AuraHandledException('Flight API call failed with status: ' + res.getStatus());
            }

        } catch (Exception ex) {
            // ✅ Log the exception
            IntegrationLogger.logError(
                'callout:SerpAPI_GoogleFlights' + endpoint,
                null,
                ex,
                travelRequestId
            );
            throw new AuraHandledException('Exception during flight API call: ' + ex.getMessage());
        }
    }
}
