import logging
import sqlite3

logger = logging.getLogger(__name__)

connection = sqlite3.connect('prices.db')

def store_data(data):
    """Store data as SQL table.

    Args:
        data (Pandas DataFrame): transformed DataFrame ready for SQL storing.
    """
    logger.info('Saving data to SQL.')
    try:
        data.to_sql('Prices_SE4', connection, if_exists='fail')
    except ValueError:
        data.to_sql('Prices_SE4', connection, if_exists='replace')
        logger.info('SQL table is replaced with latest data.')
    except Exception as e:
        logger.error('An error occurred:', e)

