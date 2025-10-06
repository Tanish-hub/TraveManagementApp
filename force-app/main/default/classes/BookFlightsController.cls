public with sharing class BookFlightsController {

    @AuraEnabled(cacheable=false)
    public static Map<String, List<Map<String, Object>>> fetchFlights(Id travelRequestId) {
        // 1. Fetch Travel Request record to get parameters
        Travel_Request__c tr = [SELECT Source__c, Destination__c, Start_Date__c, End_Date__c 
                                FROM Travel_Request__c 
                                WHERE Id = :travelRequestId
                                LIMIT 1];

        // 2. Get API key from Custom Metadata
        External_API_Key__mdt apiRecord = [
            SELECT API_Key__c 
            FROM External_API_Key__mdt 
            WHERE DeveloperName = 'SerpAPI_Google_Flights'
            LIMIT 1
        ];

        String apiKey = apiRecord.API_Key__c;

        // 3. Construct API endpoint URL
        // Using Named Credential 'SerpAPI_GoogleFlights' for authentication
        String endpoint = 'callout:SerpAPI_GoogleFlights/search.json';
        endpoint += '?engine=google_flights';
        endpoint += '&departure_id=' + EncodingUtil.urlEncode(tr.Source__c, 'UTF-8');
        endpoint += '&arrival_id=' + EncodingUtil.urlEncode(tr.Destination__c, 'UTF-8');
        endpoint += '&outbound_date=' + String.valueOf(tr.Start_Date__c);
        endpoint += '&return_date=' + String.valueOf(tr.End_Date__c);
        endpoint += '&currency=USD';
        endpoint += '&hl=en';
        endpoint += '&api_key=' + apiKey;

        // 4. Make HTTP callout
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        HttpResponse res = http.send(req);

        // 5. Check response status
        if(res.getStatusCode() != 200) {
            throw new AuraHandledException('API call failed with status: ' + res.getStatusCode());
        }

        // 6. Parse JSON response to Map<String,Object>
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        // 7. Initialize result Map to send to LWC
        Map<String, List<Map<String, Object>>> flightData = new Map<String, List<Map<String, Object>>>();
        flightData.put('best_flights', new List<Map<String, Object>>());
        flightData.put('other_flights', new List<Map<String, Object>>());

        // 8. Helper function to extract flight details
        // Iterate over best_flights
        if(responseMap.containsKey('best_flights')) {
            List<Object> bestFlights = (List<Object>) responseMap.get('best_flights');
            for(Object fObj : bestFlights) {
                Map<String, Object> fMap = (Map<String, Object>) fObj;
                Map<String, Object> flightOption = extractFlightOption(fMap);
                flightData.get('best_flights').add(flightOption);
            }
        }

        // Iterate over other_flights
        if(responseMap.containsKey('other_flights')) {
            List<Object> otherFlights = (List<Object>) responseMap.get('other_flights');
            for(Object fObj : otherFlights) {
                Map<String, Object> fMap = (Map<String, Object>) fObj;
                Map<String, Object> flightOption = extractFlightOption(fMap);
                flightData.get('other_flights').add(flightOption);
            }
        }

        return flightData;
    }

    // Helper method to extract flight legs and price from a flight option
    private static Map<String, Object> extractFlightOption(Map<String, Object> fMap) {
        Map<String, Object> flightOption = new Map<String, Object>();

        // Get price and type
        flightOption.put('price', fMap.get('price'));
        flightOption.put('type', fMap.get('type'));

        // Extract flight legs
        List<Map<String, Object>> legsList = new List<Map<String, Object>>();
        if(fMap.containsKey('flights')) {
            List<Object> flights = (List<Object>) fMap.get('flights');
            for(Object lObj : flights) {
                Map<String, Object> leg = (Map<String, Object>) lObj;
                Map<String, Object> legData = new Map<String, Object>();
                
                legData.put('airline', leg.get('airline'));
                legData.put('flight_number', leg.get('flight_number'));
                legData.put('duration', leg.get('duration'));

                // Departure airport
                Map<String, Object> dep = (Map<String, Object>) leg.get('departure_airport');
                legData.put('departure_name', dep.get('name'));
                legData.put('departure_code', dep.get('id'));
                legData.put('departure_time', dep.get('time'));

                // Arrival airport
                Map<String, Object> arr = (Map<String, Object>) leg.get('arrival_airport');
                legData.put('arrival_name', arr.get('name'));
                legData.put('arrival_code', arr.get('id'));
                legData.put('arrival_time', arr.get('time'));

                legsList.add(legData);
            }
        }

        flightOption.put('flights', legsList);
        return flightOption;
    }

}
