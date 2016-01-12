@api @reports
Feature: Reports

  After publishing test results to Probe Dock for different projects within an organization, users of that
  organization should be able to access a list of reports for the project.



  @wip
  Scenario: An organization member should be able to get a report of a private organization by ID.
    Given private organization Rebel Alliance exists
    And private organization Galactic Empire exists
    And project X-Wing exists within organization Rebel Alliance
    And project Y-Wing exists within organization Rebel Alliance
    And project TIE Fighter exists within organization Galactic Empire
    And user hsolo who is a member of Rebel Alliance exists
    And user palpatine who is a member of Galactic Empire exists
    And test result report A was generated for organization Rebel Alliance
    And test payload A1 sent by hsolo for version 1.2.3 of project X-Wing was used to generate report A
    And test result report B was generated for organization Rebel Alliance
    And test payload B1 sent by hsolo for version 4.5.6 of project Y-Wing was used to generate report B
    And test result report C was generated for organization Rebel Alliance
    And test payload C1 sent by hsolo for version 1.2.3 of project X-Wing was used to generate report C
    And test result report D was generated for organization Galactic Empire
    And test payload D1 sent by palpatine for version 1.2.3 of project TIE Fighter was used to generate report D
    When hsolo sends a GET request to /api/reports?organizationId={@idOf: Rebel Alliance}&projectId={@idOf: X-Wing}
    Then the response code should be 200
    And the response body should be the following JSON:
      """
      [
        {
          "id": "@idOf: C",
          "duration": "@valueOf(C1, duration)",
          "resultsCount": 0,
          "passedResultsCount": 0,
          "inactiveResultsCount": 0,
          "inactivePassedResultsCount": 0,
          "startedAt": "@iso8601",
          "endedAt": "@iso8601",
          "createdAt": "@iso8601",
          "organizationId": "@idOf: Rebel Alliance"
        },
        {
          "id": "@idOf: A",
          "duration": "@valueOf(A1, duration)",
          "resultsCount": 0,
          "passedResultsCount": 0,
          "inactiveResultsCount": 0,
          "inactivePassedResultsCount": 0,
          "startedAt": "@iso8601",
          "endedAt": "@iso8601",
          "createdAt": "@iso8601",
          "organizationId": "@idOf: Rebel Alliance"
        }
      ]
      """
    And nothing should have been added or deleted
