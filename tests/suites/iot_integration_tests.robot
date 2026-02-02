*** Settings ***
Documentation       IoT Device Integration Test Suite
...                 Verifies API configuration, database persistence, and business rule consistency 
...                 using a "Triangle Verification" strategy.

Library             Collections
Resource            ../resources/api_keywords.resource
Resource            ../resources/db_keywords.resource
Resource            ../resources/common.resource
Library             ../../libraries/IoTValidationLib.py

Suite Setup         Initialize Test Suite
Suite Teardown      Cleanup Test Suite
# run script: robot -d results tests/suites/iot_integration_tests.robot

*** Test Cases ***
TestCase 01: Verify Successful Device Configuration
    [Documentation]    Happy Path: Verifies that valid temperature configuration is correctly 
    ...                processed by the API, persisted in the DB, and passes business rule validation.
    [Tags]             integration    critical
    ${target_temp}=    Set Variable    25.5
    # Guard Clause: Validate temperature against bussiness rules.Don't even talk to the API if data violates physics.
    Validate Temperature Range    ${target_temp} 
    ${response}=    Send Configuration To Device    ${target_temp}
    # Check HTTP status code is 200 OK
    Should Be Equal As Integers    ${response.status_code}    200
    # Get latest status from API (for comparison)
    ${status_response}=    Get Device Status
    ${api_json}=    Set Variable    ${status_response.json()}
    # Query latest record from Database
    ${db_record}=    Get Latest Device Record
    # Triangle Verification (Data Consistency)
    Verify Data Consistency    ${api_json}    ${db_record}  

TestCase 02: Verify Reject Invalid Temperature
    [Documentation]    Negative Path: Verifies that out-of-range temperature (-50) is rejected 
    ...                by the API and is NOT persisted in the database (Safety Mechanism).
    [Tags]             integration    negative
    ${invalid_temp}=    Set Variable    -50
    ${response}=       Send Configuration To Device    ${invalid_temp}
    # Check HTTP status code is 400 Bad Request
    Should Be Equal As Integers    ${response.status_code}    400
    # Check error response body for specific error message
    ${json}=    Set Variable       ${response.json()}
    Dictionary Should Contain Key  ${json}    error
    Should Contain                 ${json['error']}    out of range
    # Ensure the invalid value was NOT persisted
    ${db_record}=    Get Latest Device Record
    # # Check if database has records (Normal case) or is empty (Initial state)
    IF  ${db_record}
        ${latest_saved_temp}=    Set Variable    ${db_record}[0]
        Should Not Be Equal As Numbers    ${latest_saved_temp}    ${invalid_temp}
    ELSE
        Log    Database is empty. Invalid data was successfully rejected and not persisted.
    END
