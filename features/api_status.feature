Feature: API Status
  In order to check the health and status of the API
  I need some urls to check.

  Scenario: Ping check
    When the client requests GET /ping
    Then the reponse should be OK

  Scenario: Status check with missing API key
    When the client requests GET /v1/status.json
    Then the reponse should be BAD REQUEST
    Then the response body should be:
      """
      [:error, "[\"_apikey\"] identifier missing"]
      """
  Scenario: Status check with invalid API key
    When the client requests GET /v1/status.json?_apikey=i_am_wrong
    Then the response body should be:
      """
      [:error, "Unauthorized"]
      """
    Then the reponse should be UNAUTHORIZED
  Scenario: Status check with valid API key
    When the client requests GET /v1/status?_apikey=i_am_awesome
    Then the JSON should include:
    """
    {
      "_apikey": "i_am_awesome"
    }
    """
