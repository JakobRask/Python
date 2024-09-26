import logging
import pandas as pd

logger = logging.getLogger(__name__)


def clean_data(data):
    """Transformning DataFrame for chosen purpose.

    Args:
        data (Pandas DataFrame): raw data from API converted from json format.

    Returns:
        Pandas DataFrame: transformed DataFrame prepared for SQL storing.
    """
    logger.info('Starting data cleaning.')
    try:
        df = data.drop(['EUR_per_kWh', 'EXR'], axis=1)
    except KeyError as ke:
        logger.error('Columns not found:', ke)
        df = data
    except Exception as e:
        logger.error('An error occurred:', e)
    df = df.round(2)
    df['Date'] = pd.to_datetime(df['time_start']).dt.date
    df['time_start'] = pd.to_datetime(df['time_start']).dt.hour
    df['time_end'] = pd.to_datetime(df['time_end']).dt.hour
    return df
