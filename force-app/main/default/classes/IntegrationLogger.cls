public with sharing class IntegrationLogger {

    public static void logCallout(String endpoint, String requestBody, HttpResponse response, Id relatedRecordId) {
        
        String responseBody = response.getBody();
        Integer maxLength = 100;

        Integration_Log__c log = new Integration_Log__c();
        log.Endpoint_URL__c = endpoint;
        log.Request_Body__c = requestBody;
        log.Related_Record__c = relatedRecordId;
        log.Callout_Timestamp__c = System.now();


        if (responseBody != null && responseBody.length() > maxLength) {
                log.Response_Body__c = responseBody.substring(0, maxLength) + '... [TRUNCATED]';
            } else {
                log.Response_Body__c = responseBody;
            }

        if(response != null) {
            log.Status_Code__c   = response.getStatusCode();
            log.Success__c      = (response.getStatusCode() >= 200 && response.getStatusCode() < 300);
        } else {
            log.Success__c = false;
            log.Error_Message__c = 'No response received from server.';
        }
        insert log;
    }

    public static void logError(String endpoint, String requestBody, Exception ex, Id relatedRecordId) {
        Integration_Log__c log = new Integration_Log__c();
        log.Endpoint_URL__c = endpoint;
        log.Request_Body__c = requestBody;
        log.Related_Record__c = relatedRecordId;
        log.Callout_Timestamp__c = System.now();
        log.Success__c = false;
        log.Error_Message__c = ex.getMessage();
        insert log;
    }
}
