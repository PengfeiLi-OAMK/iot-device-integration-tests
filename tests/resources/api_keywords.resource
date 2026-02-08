*** Settings ***
Documentation   Resource file for keywords related to IOT API testing.
Library         RequestsLibrary
Library         Collections

*** Variables ***
${BASE_URL}      http://127.0.0.1:5000

*** Keywords ***
Initialize API Session
    [Documentation]   Initializes a session.Must be called before API requests.
    Create Session   iot_session   ${BASE_URL}   disable_warnings=1

Send Configuration To Device
    [Documentation]   Send POST /api/config request to configure the IOT device.
    [Arguments]       ${target_temp}    ${firmware}=v1.0
    ${body} =   Create Dictionary   target_temperature=${target_temp}    firmware_version=${firmware}
    ${response}=   POST On Session   iot_session   /api/config   json=${body}   expected_status=any
    RETURN    ${response}

Get Device Status
    [Documentation]   Send GET /api/status request to retrieve the device status.
    ${response}=   GET On Session    iot_session   /api/status   expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200
    
    #try to parse JSON, if it fails, log the actual response body for debugging
    TRY
        ${json_check}=    Set Variable    ${response.json()}
    EXCEPT    AS    ${error_msg}
        Log    Critical Failure: Non-JSON response received!\nOriginal Body:\n${response.text}    level=WARN
        Log    Python Exception Trace: ${error_msg}    level=DEBUG
        Fail    Device status response is not valid JSON (Status: ${response.status_code}). Response Body: ${response.text}
    END
    RETURN    ${response}