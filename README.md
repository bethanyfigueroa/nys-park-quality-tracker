# New York State Park Tick Tracker App

A simple app for users to evaluate and report encounters with ticks at New York State parks. This app is intended to help hikers understand the level of risk certain parks may carry for tick-borne diseases, as well as help  state park service administrators monitor potential tick outbreaks. Users are encouraged to document the number of ticks observed and any tick bites received during their hike via this app. New entries will automatically be pushed to the private database servicing the [New York State Park Tick Tracker App](https://lm68o2-bethany-figueroa.shinyapps.io/tick_tracker_app/). 
#### Database Schema 
The database for the New York State Park Tick Tracker is divided into a primary and secondary data table. The primary data table "tick_tracker" is updated live by the user entries, while the secondary table "park_list" is a reference list for park names and locations. The schema for the tick_tracker table is shown below along with definitions for each variable.

| **Name in App**    | **Variable in tick_tracker** | **Data Type** | **Description**                                                                                                                                                                                                                         |
| ------------------ | ---------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Park Name          | name                         | Text          | Official name of the park as defined by New York State's inventory of parks                                                                                                                                                             |
| Park County        | county                       | Text          | County where the park is located                                                                                                                                                                                                        |
| Park Region        | region                       | Text          | Name of the region the park is located, as defined by New York State                                                                                                                                                                    |
| Reported Date Time | report_date                  | Timestamp     | Date of the reported tick sighting, stored in the database as a universal date time. This is recorded automatically whenever the user submits a response to the database.                                                               |
| Ticks Spotted      | ticks_identified             | Numeric       | Number of ticks spotted during the reported hike. It is assumed the user is only using the app to report tick sightings, so synthetic data reports this as one or greater. All values saved to the database are positive real integers. |
| Bites Received     | tick_bites                   | Numeric       | Number of tick bites received from the reported hike. This variable is a positive real integer.                                                                                                                                         |

The schema for the park_list is shown below, based on the "[State Park Facility Points](https://data.ny.gov/Recreation/State-Park-Facility-Points/9uuk-x7vh/about_data)" database and New York's list of [Park Regions](https://parks.ny.gov/visit/regions) developed by the [New York State Office of Parks, Recreation and Historic Preservation (2024)](https://data.ny.gov/Recreation/State-Park-Facility-Points/9uuk-x7vh/about_data) 

| **Variable in park_list** | **Data Type** | **Description**                                                      |
| ------------------------- | ------------- | -------------------------------------------------------------------- |
| Name                      | Text          | Name of State Park                                                   |
| County                    | Text          | Name of County the park is located in                                |
| Region                    | Text          | Name of the region the park is located, as defined by New York State |
| Longitude                 | Numeric Float | X coordinate of a facility in the park                               |
| Latitude                  | Numeric Float | Y coordinate of a facility in the park                               |
#### Running the App
To access this app, open the program via the following shinyapp-io link: 
[https://lm68o2-bethany-figueroa.shinyapps.io/tick_tracker_app/](https://lm68o2-bethany-figueroa.shinyapps.io/tick_tracker_app/)

The App includes a dashboard with summary statistics for New York’s park regions and a visual of the time trends for the total number of ticks reported at a selected park. The user can view the raw tick tracker database by selecting the "TICK TRACKER" tab. The mean and 95% confidence interval are calculated based on the sample size (hiker reports) for each park and region, available in the tabs "INDIVIDUAL PARKS" and "PARK REGIONS" respectively. 

![[ticktracker_example.png](https://github.com/bethanyfigueroa/nys-park-quality-tracker/blob/main/ticktracker_example.png)

The app can be recreated on your local machine by cloning the github repository and running the R project file "nys-park-quality-tracker.Rproj" found in the main directory opened via Posit Cloud or RStudio. Before you can recreate the program, you must add your own .env file with the credentials for your own PostgreSQL Database, such as [Supabase](https://supabase.com/).  Details on how to create an .env file are available in the README located in the app directory. **By default, accessing the code this way will prevent you from pushing new entries into the Tick Tracker database.** It will only allow you to remake the application, along with the tick tracker's schema and synthetic data. 

To recreate the database with the appropriate schema and same data,  run the following scripts in the tick_tracker_app directory using RStudio or PositCloud: 
1. Run "make_park_list.R" to make the initial parks list and write the table to your database
2. Run "make_tick_tracker.R" and write the table to your database
3. Go to "app.R" and  click "Run  App" within RStudio or PositCloud. 
#### About the Data 
The default data presented in this app is purely synthetic. The first 350 rows were seeded using  a combination of poisson and normal distributions, with all other rows present in the app  generated via form submissions. The code that was used to generate the schema for the table "tick_tracker" and the initial seed of data is available in the script "make_tick_tracker.R" located in the tick_tracker_app directory. The code used to generate the reference list of parks is available in  "tick_tracker_app/make_park_list.R" alongside the raw data for the referenced list of parks contained in "park_list_reference/State_Park_Facility_Points_12_2024.csv"
#### About the  Author
This app was developed by Bethany Figueroa as a midterm assignment for the class SYSEN 5460 "[Data Science for Socio-Technical Systems: Decision-Making and Data Communication at Scale](https://classes.cornell.edu/browse/roster/SU25/class/SYSEN/5460)" taught by Professor Fraser as part of Cornell University's Systems Engineering Program. 

