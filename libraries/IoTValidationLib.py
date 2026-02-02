import logging

class IoTValidationLib:
    """
    Custom testing library for validating IoT device business rules and 
    ensuring data consistency across system components.
    """
    def validate_temperature_range(self, temperature):
        """
        Simulates industrial sensor logic to verify if the input temperature 
        falls within the safe operating range [-40, 85].
        Raises a ValueError if the temperature is out of bounds, causing the test to fail.
        """
        temp = float(temperature)
        if not(-40 <= temp <= 85):
            raise ValueError(f"Safety Violation: Temperature {temp} out of range (-40 to 85).")
        logging.info(f"Temperature {temp} is within the safe operating range.")
        return True
    def verify_data_consistency(self, api_response_json, db_record):
        """
        Performs "Triangle Verification" to ensure strict consistency between 
        the real-time API response and the persisted database record.
        :param api_response_json: JSON dictionary returned by the API (e.g., {'target_temperature': 25.5, ...})
        :param db_record: Tuple returned by the Database query (e.g., (25.5, 'CONFIGURED'))
        """
        if not db_record:
            raise AssertionError("Database record is missing! Persistence failed.")
        
        # 1. Extract data from the Database tuple
        db_temp = float(db_record[0])
        db_status = db_record[1]

        # 2. Extract data from the API JSON response
        api_temp_raw = api_response_json.get('target_temperature')
        api_status = api_response_json.get('status')
        if api_temp_raw is None or api_status is None:
            raise AssertionError(f"Critical data missing in API response! JSON: {api_response_json}")
        api_temp = float(api_temp_raw)
        # 3. Perform comparison
        # Compare temperatures (allowing for minor floating-point tolerance)
        if abs(db_temp - api_temp) > 0.001:
            raise AssertionError(f"Data Mismatch! API says temp={api_temp}, but DB says temp={db_temp}")
        # Compare device status
        if db_status != api_status:
            raise AssertionError(f"Status Mismatch! API says '{api_status}', but DB says '{db_status}'")
        logging.info("SUCCESS: API response matches Database persistence perfectly.")
        return True
        