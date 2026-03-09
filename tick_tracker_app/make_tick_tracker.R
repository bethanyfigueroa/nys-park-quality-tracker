# Bethany Figueroa, 3/9/26, SYSEN 5460
# Script for creating the Schema and synthetic data for the NYS Park Tick Tracker

##### Load Packages####
library(DBI)        # for database connections
library(RPostgres)  # for PostgreSQL connections (SUPABASE uses PostgreSQL)
library(dplyr)      # for data manipulation with pipelines
library(dbplyr)     # for extending dplyr to work with databases
library(tidyr)      # for data cleanup, such as dropping na values
library(stringr)    # for fixing dates and other strings 
library(lubridate)  # for reading dates

# Define a table that is only there to track park names
table_dictionary = "park_list"

# The park dictionary was created was from reading the unique names of state owned parks from NY
# https://data.ny.gov/Recreation/State-Park-Facility-Points/9uuk-x7vh/about_data
# Run the script "mark_list.R" in the park_list_reference directory first if you are trying to reproduce
# the trick tracker on your own database 

# Define the table of interest that will host the live data for the trick tracker for NY parks
table_of_interest = "tick_tracker" # main live data table

# Note that the USER NEEDS TO HAVE A .ENV FILE WITH CORRECT CREDENTIALS to run this script
# Since this script is not a part of the app and purely intended to setup the tick_tracker, no public permissions are allowed
# To reproduce this data, please create your own .env and enter your SUPABASE credentials into the following lines

# NOTE THAT YOU MUST SET THE GITHUB DIRECTORY (nys-park-quality-tracker) AS YOUR WORKING DIRECTORY IN ORDER TO RUN THIS SCRIPT
# Use setwd(insert your directory's path here) if needed
# Read the local environment fill (it must match with your SUPABASE credentials)
readRenviron("tick_tracker_app/.env") 

# SUPABASE credentials. The password pulled from the .env is strictly confidential 
# If you are making your own database for the tick tracker, please add your own credentials for:  
# SUPABASE_HOST, SUPABASE_PORT, SUPABASE_DB, SUPABASE_USER, and SUPABASE_PASSWORD
SUPABASE_HOST = Sys.getenv("SUPABASE_HOST")
SUPABASE_PORT = Sys.getenv("SUPABASE_PORT")
SUPABASE_DB = Sys.getenv("SUPABASE_DB")
SUPABASE_USER = Sys.getenv("SUPABASE_USER")
SUPABASE_PASSWORD = Sys.getenv("SUPABASE_PASSWORD")

# Function for connecting to the database that you gave SUPABASE credentials for 
connect = function(password = SUPABASE_PASSWORD, user = SUPABASE_USER) {
  db = dbConnect(
    drv = RPostgres::Postgres(),
    host = SUPABASE_HOST,
    port = as.integer(SUPABASE_PORT),
    dbname = SUPABASE_DB,
    user = user,
    password = password
  )
  return(db)
}
con = connect() # establish connect 
con %>% dbListTables() # check tables

# Connect to park list and collect data. Dont need the coordinates, only the park name, county, and region. 
park_list = tbl(con, table_dictionary) %>% select(Name, County, Region) %>%  collect() 

# Double check that the table only has unique park names, no duplicates
print("No Duplicate Locations in Park list:")
print(length(unique(park_list$Name)) == length(park_list$Name))

# As a basis, will assume a minimum report date-time of 8:00 AM EST and assume there are 50 reports per day. 
start_date = ymd_hms("2026-03-01 8:00:00",tz = "EST")
reports_per_day = 50
report_days = 7

# Set an arbitrary seed for the synthetic data (e.g. 382026)
# This ensures the same results will be reproducible for anyone replicating this app
set.seed(382026) 

# Each row will represent a date time increment from 3/1/26 to 3/7/26 (seven days)
# Make a vector of floats between 1 and days*reports_per_day (350 rows). Floor to round to each day
sample_days = days(floor(c(0:(7*reports_per_day-1))/reports_per_day)) + ymd_hms("2026-03-01 8:00:00",tz = "EST")

# Reports per day will assume to follow a normal distribution with the mean centered at 2 PM (6 hours after 8 AM)
# With a sigma  of three hours (3*60*60 seconds)
random_seconds = rnorm(n = reports_per_day * report_days, mean = 6*60*60, sd = 3*60*60)
hist(random_seconds) # Look at the histogram

# Add the random time to the list of days Note that random_time has to be rounded and converted to 
report_date_time = sample_days + seconds(round(random_seconds))
report_date_time # check values

# Assume at least one tick per report (otherwise they wouldn't be using the app!)
# Assume the frequency follows a poisson distribution with an average of 1, shifted by a value of 1. 
ticks = rpois(n = reports_per_day * report_days, lambda = 1) +1
hist(ticks) # check the histogram
ticks # check the list

# Assume a random number of bites following a poisson distribution with a mean of one. 
bites = rpois(n = reports_per_day * report_days, lambda = 1)
hist(bites) # check the histogram
bites # check the list

# Create 350 rows of synthetic data using four random draws of the parks_list dataframe
random_parks = bind_rows(  park_list[sample(nrow(park_list),150),] , 
                           park_list[sample(nrow(park_list),150),],
                           park_list[sample(nrow(park_list),50),])

# Mutate the columns to attach the vectors of random date times, ticks, and bites
tick_tracker = random_parks %>% 
  mutate(report_date = report_date_time, ticks_identified = ticks, tick_bites = bites) %>%
  # Arrange by date from first report to last report 
  arrange(report_date)

# Check the tick tracker entries
tick_tracker %>% print(n = 350)

# Note that the column names for park Name, County, and Region are all capital letters
# This is not ideal, as it will cause issues for the table schema. As such, rename the column names to lower case
tick_tracker = tick_tracker %>% rename(name = Name, county = County, region = Region)

# Write the table to your SUPABASE database. 
dbWriteTable(con, table_of_interest,tick_tracker) 

# Check the table is there 
con %>% dbListTables()

# Exit the connection
dbDisconnect(con)

# clear cache and remove variables 
rm(list = ls()); gc()
