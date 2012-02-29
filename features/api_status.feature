Feature: API Status
  In order to check the health and status of the API
  I need some urls to check.
  
  Scenario: Ping check
    When the client requests GET /ping
    Then the reponse should be OK

  Scenario: Status check with missing API key
    When the client requests POST /status
    Then the reponse should be BAD REQUEST
    Then the response body should be:
      """
      {"error":"[\"_apikey\"] identifier missing"}
      """
  Scenario: Status check with invalid API key
    Given an invalid API key
    When the client requests POST /status
    Then the reponse should be UNAUTHORIZED
    Then the response body should be:
      """
      [:error, "Unauthorized"]
      """
  Scenario: Status check
    Given a valid API key
    When the client requests POST /status
    Then the response should be JSON:
      """
        {"env": "test"}
      """
