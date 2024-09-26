import logging
import requests
import pandas as pd
from datetime import datetime, timedelta

# Tomorrows date for use in url.
tomorrow = datetime.now() + timedelta(1)  
year = tomorrow.strftime('%Y')
month = tomorrow.strftime('%m')
day = tomorrow.strftime('%d')
is_today = False
url = f'https://www.elprisetjustnu.se/api/v1/prices/{year}/{month}-{day}_SE4.json'

class API:
    """Getting electricity prices from https://www.elprisetjustnu.se/ and returns a Pandas DataFrame.
        If data for tomorrow is not available then data for today is fetched.

    Returns:
        Pandas DataFrame: Returns json as Pandas DataFrame.
    """
    # Tomorrows date for use in url.
    tomorrow = datetime.now() + timedelta(1)  
    year = tomorrow.strftime('%Y')
    month = tomorrow.strftime('%m')
    day = tomorrow.strftime('%d')
    what_day = "tomorrow"
    url = f'https://www.elprisetjustnu.se/api/v1/prices/{year}/{month}-{day}_SE4.json'
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        
    def get_data(self):
        # Gets tomorrows data if available, or else gets todays data.
        self.logger.info('Getting data from API')
        response = requests.get(url)
        if response.status_code == 200:
            try:
                self.logger.info('Data for tomorrow downloaded.')
                return pd.DataFrame(response.json())
            except Exception as e:
                self.logger.error('An error occurred:', e)
        else:
            self.logger.error('Data for tomorrow not available.')
            self.year = datetime.now().strftime('%Y')
            self.month = datetime.now().strftime('%m')
            self.day = datetime.now().strftime('%d')
            self.what_day = "today"
            response = requests.get(f'https://www.elprisetjustnu.se/api/v1/prices/{year}/{month}-{day}_SE4.json')
            self.logger.info('Data for today downloaded.')
            return pd.DataFrame(response.json())
   