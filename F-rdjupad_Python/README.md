# Scheduled pipeline project

Using the API for elprisetjustnu.se the script gets the hourly prices for tomorrow (if available).<br>
https://www.elprisetjustnu.se/elpris-api <br>
The extracted data is transformed using <i>pandas</i> and loaded into a SQL table.

By creating an automated task using Task Scheduler in Windows the script is executed at a certain time every day.

![Scheduler](https://github.com/user-attachments/assets/198d12bc-6c5a-4c76-bbb5-36f576d20222)


To ensure we get the data we want, a visualization is made which displays the date and if the data is for today or tomorrow.<br>
Data for tomorrow is available somewhere after 13:00 each day.<br>
Data extraction made before 13:00 will result in getting the data for today, as seen below.

![image](https://github.com/user-attachments/assets/b4b5e77f-fb38-49be-b56c-1f8492f044c2)

Data extraction made after 13:00 should result in getting the data for tomorrow, as seen below.

![image](https://github.com/user-attachments/assets/2339a794-d643-4cac-b1fa-ce31a6e100ee)

Depending on if we get data for today or tomorrow the log will look a bit different, as seen in <i>logs/log_pipeline.log</i>
