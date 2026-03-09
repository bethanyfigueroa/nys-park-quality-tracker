# New York State Park Tick Quality Tracker App

A simple app for users to evaluate and report encounters with ticks at New York State parks. This app is intended to help hikers understand the level of risk certain parks may carry for tick-borne diseases, as well as help  state park service administrators monitor potential tick outbreaks. Users are encouraged to document the number of ticks observed and any tick bites received during their hike via this app. New entries will automatically be pushed to the Tick Tracker database. 
#### Database Schema 
The database for the New York State Park Tick Tracker is divided into a primary and secondary data table. The primary data table "tick_tracker" is updated live by the user entries, while the secondary table "park_list" is a reference list for park names and locations. The schema for the tick_tracker table is shown below along with definitions for each variable.

| **Name in App**  | **Variable in tick_tracker** | **Data Type** | **Description**                                                                                                                                                            |
| ---------------- | ---------------------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Park Name        | name                         | Text          | Official name of the park as defined by New York State's inventory of parks                                                                                                |
| Park County      | county                       | Text          | County where the park is located                                                                                                                                           |
| Park Region      | region                       | Text          | Name of the region the park is located, as defined by New York State                                                                                                       |
| Date of Incident | report_date                  | Timestamp     | Date of the reported tick sighting, stored in the database as a universal date time. This is recorded automatically whenever the user submits a response to the database.  |
| Ticks Spotted    | ticks_identified             | Numeric float | Number of ticks spotted during the reported hike. Must be at least one or greater. It is assumed the user is only using the app to report a tick sighting                  |
| Bites Received   | tick_bites                   | Numeric float | Number of tick bites received from the reported hike. The number must be zero or greater.                                                                                  |

The schema for the park_list is shown below, based on the "[State Park Facility Points](https://data.ny.gov/Recreation/State-Park-Facility-Points/9uuk-x7vh/about_data)" database and New York's list of [Park Regions](https://parks.ny.gov/visit/regions) developed by the [New York State Office of Parks, Recreation and Historic Preservation (2024)](https://data.ny.gov/Recreation/State-Park-Facility-Points/9uuk-x7vh/about_data) 

| **Variable in park_list** | **Data Type** | **Description**                                                      |
| ------------------------- | ------------- | -------------------------------------------------------------------- |
| Name                      | Text          | Name of State Park                                                   |
| County                    | Text          | Name of County the park is located in                                |
| Region                    | Text          | Name of the region the park is located, as defined by New York State |
| Longitude                 | Numeric Float | X coordinate of a facility in the park                               |
| Latitude                  | Numeric Float | Y coordinate of a facility in the park                               |
#### Running the App
It is recommended you access this app via the following shinyapp-io link: 
[https://lm68o2-bethany-figueroa.shinyapps.io/tick_tracker_app/](https://lm68o2-bethany-figueroa.shinyapps.io/tick_tracker_app/)

The app can be reproduced on your local machine by cloning the github repository and running the R-script file found in the path "nys-park-quality-tracker/tick_tracker_app/app.R". Before you can run this app, you will need to add your own .env file to connect to the database. View the README located in the app directory for more information on making a .env file for your copy. 

**By default, accessing the code this way will prevent you from pushing new entries into the database.** However, it will still let you connect to the database  and select tables, allowing you to copy the data and write them to your own database if you wish to reproduce this app. 
#### About the Data 
The default data presented in this app is purely synthetic. The code that was used to generate the schema for the table "tick_tracker" and the initial seed of data is available in the script "make_tick_tracker.R" located in the app directory. The code used to generate the reference list of parks is available in  "park_list_reference/make_park_list.R" alongside the raw data for the referenced list of parks contained in "State_Park_Facility_Points_12_2024.csv"
#### About the  Author
This app was developed by Bethany Figueroa as a midterm assignment for the class SYSEN 5460 "[Data Science for Socio-Technical Systems: Decision-Making and Data Communication at Scale](https://classes.cornell.edu/browse/roster/SU25/class/SYSEN/5460)" taught by Professor Fraser as part of Cornell University's Systems Engineering Program. 

