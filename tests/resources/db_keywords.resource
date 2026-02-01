*** Settings ***
Documentation    Encapsulates keywords for database operations in IOT testing.
Library          DatabaseLibrary
Library          OperatingSystem
*** Keywords ***
Connect To IoT Database
    [Documentation]   Establishes a connection to the SQLite database file
    ${db_path}=   Join Path   ${CURDIR}   ..  ..  sub  database.db
    Log    Connecting to DB at:  ${db_path}
    
    Connect To Database  sqlite3   ${db_path}

Disconnect From IoT Database
    [Documentation]   Closes the database connection.
    Disconnect From Database

Get Latest Device Record
    [Documentation]     Retrieves the most recent record from the devices table.
    ${query_results} =  Query    SELECT target_temp, status FROM device_state ORDER BY id DESC LIMIT 1
    ${count}=    Get Length    ${query_results}
    IF  ${count} == 0
        RETURN    ${None}
    END
    ${record}=    Set Variable    ${query_results}[0]
    RETURN    ${record}