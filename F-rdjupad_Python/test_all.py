import pandas as pd
from api import API
import datacleaner as dc
import datatosql as ds
import main

api = API()

# Testing instances in api script.
def test_api():
    assert isinstance(api.get_data(), pd.DataFrame)
    assert isinstance(api.year, str)
    assert isinstance(api.month, str)
    assert isinstance(api.day, str)
    assert isinstance(api.what_day, str)

# Testing testing instances in datacleaner script.
def test_datacleaner():
    assert isinstance(dc.clean_data(main.data), pd.DataFrame)
    assert isinstance(dc.clean_data(main.data)['Date'], pd.Series)

# Testing datatosql script, validating sql table.
def test_datatosql():
    to_validate = pd.read_sql('SELECT * FROM Prices_SE4', ds.connection)
    to_validate.equals(main.cleaned_data)
    
# Testing main script.
def test_main():
    assert isinstance(main.data, pd.DataFrame)
    assert isinstance(main.cleaned_data, pd.DataFrame)
    assert len(main.cleaned_data) == 24