# Running the Tick Tracker App with Your Own Credentials
#### Running the App
The app can be reproduced on your local machine by cloning the github repository and running the R-script file found in the path "nys-park-quality-tracker/tick_tracker_app/app.R". Before you can run this app, you will need to add your own .env file to connect to the database. 

**By default, accessing the code this way will prevent you from pushing new entries into the database.** However, it will still let you connect to the database - which can allow you to copy the database's two tables and write them to your own database if you wish to reproduce this app. 
#### About the Data 
The default data presented in this app is purely synthetic. The code that was used to generate the schema for the table "tick_tracker" and the initial seed of data is available in the script "make_tick_tracker.R" located in the app directory. The code used to generate the reference list of parks is available in  "park_list_reference/make_park_list.R" alongside the raw data for the referenced list of parks contained in "State_Park_Facility_Points_12_2024.csv"


