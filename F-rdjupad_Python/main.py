import logging
import matplotlib.pyplot as plt 
import seaborn as sns
from api import API
import datacleaner as dc
import datatosql as ds

logger = logging.getLogger(__name__)

logging.basicConfig(
    filename='logs/log_pipeline.log', 
    format='[%(asctime)s][%(name)s][%(levelname)s] %(message)s', 
    datefmt='%Y-%m-%d %H:%M:%S', 
    level=logging.INFO)

api = API()

# Pipeline
logger.info('Data pipeline starting.')
data = api.get_data()
cleaned_data = dc.clean_data(data)
ds.store_data(cleaned_data)
    
# Plot prices with the latest data (today or tomorrow).
logger.info(f'Plotting data for {api.what_day}.')
plt.set_loglevel(level='warning')
fig, ax = plt.subplots(figsize=(10, 4))
ax = sns.barplot(data=cleaned_data, x="time_start", y="SEK_per_kWh", hue="SEK_per_kWh") 
for i in ax.containers:
    ax.bar_label(i,)
plt.legend(loc="upper left", bbox_to_anchor=(1,1))
plt.title(f"Hourly prices for {api.what_day} ({api.year}-{api.month}-{api.day}), region SE4")
plt.xlabel("Hour (beginning from)")
plt.ylabel("SEK / kWh")
plt.show() 