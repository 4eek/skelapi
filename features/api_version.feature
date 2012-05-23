Feature: API Version
  In order to be sure I'm using the correct API version
  I need some url to check check the version.

  Scenario: Version check with missing API key
    When the client requests GET /v1/version.json
    Then the reponse should be BAD REQUEST
    Then the response body should be:
      """
      [:error, "[\"_apikey\"] identifier missing"]
      """
  Scenario: Version check with invalid API key
    When the client requests GET /v1/version.json?_apikey=i_am_wrong
    Then the response body should be:
      """
      [:error, "Unauthorized"]
      """
    Then the reponse should be UNAUTHORIZED
  Scenario: Version check with valid API key
    When the client requests GET /v1/version?_apikey=i_am_awesome
    Then the JSON response at "version" should be "v1"
    And the JSON response at "build_number" should be an integer
    And the JSON response at "build_time" should be a string

