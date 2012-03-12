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
    Given the following POST params
      |_apikey     |method     |
      |i_am_wrong  |environment|
    When the client requests POST /status
    Then the response body should be:
      """
      [:error, "Unauthorized"]
      """
    Then the reponse should be UNAUTHORIZED
  Scenario: Current Environment
    Given the following POST params
      |_apikey     |method     |
      |i_am_awesome|environment|
    When the client requests POST /status
    Then the response should be JSON:
      """
      {"env": "test", "method": "environment"}
      """
