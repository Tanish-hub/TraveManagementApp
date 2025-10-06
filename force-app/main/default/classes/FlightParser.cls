public class FlightParser {

    // Wrapper class to represent each flight option we care about
    public class FlightOption {
        @AuraEnabled public String id;                  // internal ID we assign
        @AuraEnabled public String airline;             // Airline name
        @AuraEnabled public String airlineLogo;         // Airline logo URL
        @AuraEnabled public String flightNumber;        // Flight number

        @AuraEnabled public String departureAirportId;  // Departure airport code
        @AuraEnabled public String departureAirportName;// Departure airport name
        @AuraEnabled public String departureTime;       // Departure time

        @AuraEnabled public String arrivalAirportId;    // Arrival airport code
        @AuraEnabled public String arrivalAirportName;  // Arrival airport name
        @AuraEnabled public String arrivalTime;         // Arrival time

        @AuraEnabled public Integer durationMinutes;    // Duration in minutes
        @AuraEnabled public Decimal price;              // Ticket price
    }

    /**
     * Parse flight JSON response into list of FlightOption objects.
     */
    public static List<FlightOption> parseFlights(String jsonString) {
        List<FlightOption> flightOptions = new List<FlightOption>();

        if (String.isBlank(jsonString)) {
            return flightOptions;
        }

        Map<String, Object> root;
        try {
            // Convert raw JSON into a generic Map<String, Object>
            root = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        } catch (Exception ex) {
            System.debug('❌ FlightParser - JSON parsing failed: ' + ex.getMessage());
            return flightOptions;
        }

        // Google Flights API can return flights in "best_flights" or "other_flights"
        List<Object> candidates = (List<Object>) root.get('best_flights');
        if (candidates == null || candidates.isEmpty()) {
            candidates = (List<Object>) root.get('other_flights');
        }

        if (candidates == null || candidates.isEmpty()) {
            System.debug('⚠️ FlightParser - No flights found in response');
            return flightOptions;
        }

        // Loop through each flight entry
        Integer counter = 1;
        for (Object item : candidates) {
            if (!(item instanceof Map<String, Object>)) continue;

            Map<String, Object> f = (Map<String, Object>) item;
            FlightOption fo = new FlightOption();
            fo.id = 'FLIGHT_' + counter++;

            // Airline details
            fo.airline = getStringSafe(f, 'airline');
            fo.airlineLogo = getStringSafe(f, 'airline_logo');
            fo.flightNumber = getStringSafe(f, 'flight_number');

            // Departure airport
            Map<String, Object> dep = (Map<String, Object>) f.get('departure_airport');
            if (dep != null) {
                fo.departureAirportId = getStringSafe(dep, 'id');
                fo.departureAirportName = getStringSafe(dep, 'name');
                fo.departureTime = getStringSafe(dep, 'time');
            }

            // Arrival airport
            Map<String, Object> arr = (Map<String, Object>) f.get('arrival_airport');
            if (arr != null) {
                fo.arrivalAirportId = getStringSafe(arr, 'id');
                fo.arrivalAirportName = getStringSafe(arr, 'name');
                fo.arrivalTime = getStringSafe(arr, 'time');
            }

            // Duration
            if (f.containsKey('duration')) {
                fo.durationMinutes = safeInteger(f.get('duration'));
            } else if (f.containsKey('total_duration')) {
                fo.durationMinutes = safeInteger(f.get('total_duration'));
            }

            // Price
            if (f.containsKey('price')) {
                fo.price = safeDecimal(f.get('price'));
            }

            flightOptions.add(fo);
        }

        return flightOptions;
    }

    // Utility method to safely extract string values
    private static String getStringSafe(Map<String, Object> mapData, String key) {
        if (mapData == null || !mapData.containsKey(key) || mapData.get(key) == null) return null;
        return String.valueOf(mapData.get(key));
    }

    // Utility method to safely parse integer
    private static Integer safeInteger(Object value) {
        try { return Integer.valueOf(String.valueOf(value)); } catch (Exception e) { return null; }
    }

    // Utility method to safely parse decimal
    private static Decimal safeDecimal(Object value) {
        try { return Decimal.valueOf(String.valueOf(value)); } catch (Exception e) { return null; }
    }
}
