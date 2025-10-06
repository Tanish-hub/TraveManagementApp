public with sharing class TravelRequestService {

    public class FlightOption {
        @AuraEnabled public String airline;
        @AuraEnabled public String flightNumber;
        @AuraEnabled public String departureAirport;
        @AuraEnabled public String departureTime;
        @AuraEnabled public String arrivalAirport;
        @AuraEnabled public String arrivalTime;
        @AuraEnabled public Integer duration; 
        @AuraEnabled public Decimal price;
    }

    @AuraEnabled(cacheable=true)
    public static List<FlightOption> getFlights(String source, String destination, String startDate, String endDate, String currenc) {

        // Get API Key from Custom Metadata
            External_API_Key__mdt apiRecord = [
                SELECT API_Key__c 
                FROM External_API_Key__mdt 
                WHERE DeveloperName = 'SerpAPI_Google_Flights'
                LIMIT 1
            ];
            String apiKey = apiRecord.API_Key__c;

        // Construct endpoint path
        String path = '/search.json?engine=google_flights' +
                      '&departure_id=' + EncodingUtil.urlEncode(source,'UTF-8') +
                      '&arrival_id=' + EncodingUtil.urlEncode(destination,'UTF-8') +
                      '&outbound_date=' + EncodingUtil.urlEncode(startDate,'UTF-8') +
                      '&return_date=' + EncodingUtil.urlEncode(endDate,'UTF-8') +
                      '&currency=' + EncodingUtil.urlEncode(currenc,'UTF-8') +
                      '&hl=en' +
                      '&api_key=' + EncodingUtil.urlEncode(apiKey,'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SerpAPI_GoogleFlights' + path);
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200) {
            throw new AuraHandledException('Error fetching flights. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        }

        // Parse JSON response
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        List<FlightOption> flightOptions = new List<FlightOption>();

        // Handle best_flights first, fallback to other_flights
        List<Object> flightsList = (List<Object>) jsonMap.get('best_flights');
        if(flightsList == null) flightsList = (List<Object>) jsonMap.get('other_flights');

        if(flightsList != null) {
            for(Object bfObj : flightsList) {
                Map<String, Object> bfMap = (Map<String, Object>) bfObj;

                List<Object> innerFlights = (List<Object>) bfMap.get('flights');
                if(innerFlights == null) continue;

                for(Object fObj : innerFlights) {
                    Map<String, Object> fMap = (Map<String, Object>) fObj;

                    FlightOption fo = new FlightOption();
                    fo.airline      = (String) fMap.get('airline');
                    fo.flightNumber = (String) fMap.get('flight_number');
                    fo.duration     = fMap.get('duration') != null ? Integer.valueOf(fMap.get('duration').toString()) : null;
                    fo.price        = fMap.get('price') != null ? Decimal.valueOf(fMap.get('price').toString()) : null;

                    // Handle nested departure airport
                    Map<String, Object> dep = (Map<String, Object>) fMap.get('departure_airport');
                    if(dep != null) {
                        fo.departureAirport = (String) dep.get('name') + ' (' + dep.get('id') + ')';
                        fo.departureTime    = (String) dep.get('time');
                    }

                    // Handle nested arrival airport
                    Map<String, Object> arr = (Map<String, Object>) fMap.get('arrival_airport');
                    if(arr != null) {
                        fo.arrivalAirport = (String) arr.get('name') + ' (' + arr.get('id') + ')';
                        fo.arrivalTime    = (String) arr.get('time');
                    }

                    flightOptions.add(fo);
                }
            }
        }

        return flightOptions;
    }
}
