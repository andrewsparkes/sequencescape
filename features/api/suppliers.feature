@api @json @supplier @single-sign-on @new-api
Feature: Access suppliers through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual suppliers through their UUID
  And I want to be able to perform other operations to individual suppliers
  And I want to be able to do all of this only knowing the UUID of a supplier
  And I understand I will never be able to delete a supplier through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a UUID
    Given a supplier called "John's Genes" with ID 1
    And the UUID for the supplier "John's Genes" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "supplier": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "sample_manifests": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_manifests"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "John's Genes",
          "email": null,
          "address": null,
          "contact_name": null,
          "phone_number": null,
          "fax": null,
          "url": null,
          "abbreviation": null
        }
      }
      """
