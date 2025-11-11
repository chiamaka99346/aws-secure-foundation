Feature: Tagging compliance
  All resources must be properly tagged for governance and cost allocation

  Scenario: Resources that support tagging must have tags defined
    Given I have resource that supports tags defined
    Then it must contain tags
