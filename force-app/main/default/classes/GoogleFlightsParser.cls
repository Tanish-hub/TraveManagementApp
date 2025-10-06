public with sharing class GoogleFlightsParser {

    public class FlightLeg {
        @AuraEnabled public String departureAirport;
        @AuraEnabled public String departureTime;
        @AuraEnabled public String arrivalAirport;
        @AuraEnabled public String arrivalTime;
        @AuraEnabled public String airline;
        @AuraEnabled public String airlineLogo;
        @AuraEnabled public String flightNumber;
        @AuraEnabled public String travelClass;
        @AuraEnabled public Integer duration;
        @AuraEnabled public String uniqueKey;
    }

    public class FlightOptionWrapper {
        @AuraEnabled public Integer price;
        @AuraEnabled public Integer totalDuration;
        @AuraEnabled public List<FlightLeg> legs;
        @AuraEnabled public String uniqueKey;
    }

    @AuraEnabled(cacheable=false)
    public static List<FlightOptionWrapper> parse(String rawJson) {
        List<FlightOptionWrapper> options = new List<FlightOptionWrapper>();
        if (String.isBlank(rawJson)) return options;

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(rawJson);

        List<Object> bestFlights = (List<Object>) parsed.get('best_flights');
        List<Object> otherFlights = (List<Object>) parsed.get('other_flights');

        List<Object> allFlights = new List<Object>();
        if (bestFlights != null) allFlights.addAll(bestFlights);
        if (otherFlights != null) allFlights.addAll(otherFlights);

        Integer idx = 0;
        for (Object obj : allFlights) {
            Map<String, Object> flightOptionMap = (Map<String, Object>) obj;
            FlightOptionWrapper option = new FlightOptionWrapper();
            option.price = (Integer) flightOptionMap.get('price');
            option.totalDuration = (Integer) flightOptionMap.get('total_duration');
            option.legs = new List<FlightLeg>();

            List<Object> legsList = (List<Object>) flightOptionMap.get('flights');
            for (Object legObj : legsList) {
                Map<String, Object> legMap = (Map<String, Object>) legObj;
                FlightLeg leg = new FlightLeg();
                leg.departureAirport = ((Map<String,Object>)legMap.get('departure_airport')).get('name') + ' (' + ((Map<String,Object>)legMap.get('departure_airport')).get('id') + ')';
                leg.departureTime = (String)((Map<String,Object>)legMap.get('departure_airport')).get('time');
                leg.arrivalAirport = ((Map<String,Object>)legMap.get('arrival_airport')).get('name') + ' (' + ((Map<String,Object>)legMap.get('arrival_airport')).get('id') + ')';
                leg.arrivalTime = (String)((Map<String,Object>)legMap.get('arrival_airport')).get('time');
                leg.airline = (String) legMap.get('airline');
                leg.airlineLogo = (String) legMap.get('airline_logo');
                leg.flightNumber = (String) legMap.get('flight_number');
                leg.travelClass = (String) legMap.get('travel_class');
                leg.duration = (Integer) legMap.get('duration');
                option.legs.add(leg);
            }

            option.uniqueKey = 'option-' + idx;
            options.add(option);
            idx++;
            if (idx >= 5) break; // Limit to 5
        }

        return options;
    }
}
