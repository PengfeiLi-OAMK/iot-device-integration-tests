*** Settings ***
Resource            ../resources/api_keywords.resource
Resource            ../resources/db_keywords.resource

*** Keywords ***
Initialize Test Suite
    [Documentation]    Suite Setup: Initialize API session and connect to the database.
    Initialize API Session
    Connect To IoT Database

Cleanup Test Suite
    [Documentation]    Suite Teardown: Disconnect from the database.
    Disconnect From IoT Database
    