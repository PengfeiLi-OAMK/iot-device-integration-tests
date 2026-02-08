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
    # Precondition: Ensure test input is within valid industrial range
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
    # Snapshoting the original state before sending invalid request
    ${original_record}=    Get Latest Device Record
    # Send invalid configuration to the device
    ${invalid_temp}=    Set Variable    -50
    Send Configuration To Device    ${invalid_temp}
    ${response}=       Send Configuration To Device    ${invalid_temp}
    # Check HTTP status code is 400 Bad Request
    Should Be Equal As Integers    ${response.status_code}    400
    # Check error response body for specific error message
    ${json}=    Set Variable       ${response.json()}
    Dictionary Should Contain Key  ${json}    error
    Should Contain                 ${json['error']}    out of range
    # VERIFICATION: Get current state
    ${current_record}=     Get Latest Device Record
    # Compare if "original state" and "current state" are exactly the same
    Should Be Equal    ${current_record}    ${original_record}

