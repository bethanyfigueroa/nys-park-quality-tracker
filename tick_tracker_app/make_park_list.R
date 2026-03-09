# Bethany Figueroa, 3/9/26, SYSEN 5460
# Script for making a list of park locations for the NYS Park Tick Quality Tracker

##### Load Packages####
library(readr)      # for reading data, such as csv files
library(DBI)        # for database connections
library(RPostgres)  # for PostgreSQL connections (SUPABASE uses PostgreSQL)
library(dplyr)      # for data manipulation with pipelines
library(dbplyr)     # for extending dplyr to work with databases

# Define a table that is only there to track park names for the NYS Park Quality Tracker database
table_dictionary = "park_list"

# Note that the USER NEEDS TO HAVE A .ENV FILE WITH CORRECT CREDENTIALS to run this script
# Since this script is not a part of the app and purely intended to setup the park_list, no public permissions
# Are granted to modify the park_list table in the NYS Park Quality Tracker 

# The way park dictionary was created was from reading the unique names of state owned parks from NY
# https://data.ny.gov/Recreation/State-Park-Facility-Points/9uuk-x7vh/about_data
# See the script "update_park_list.R" for how this list was made and pushed to SUPABASE

# NOTE THAT YOU MUST THE GITHUB DIRECTORY (nys-park-quality-tracker) IN ORDER TO RUN THIS SCRIPT
# Use setwd(insert your directory's path here) if needed
park_table = read_csv("park_list_reference/State_Park_Facility_Points_12_2024.csv")

# NY Makes the following definitions for variables of interest: 
#> Name: Data Type = Text: Name of State Park Facility
#> Category: Data Type = Text: Classification of state park facility
#> Region: Date Type = Numeric: State Park Region ID
#> County: Data Type = Text: Name of County
#> Longitude: Date Type = Numeric:  X coordinate of facility
#> Latitude: Date Type = Numeric: Y coordinate of facility

# Read the local environment file. 
# It must match with the variables listed under SUPABASE credentials
readRenviron("tick_tracker_app/.env") # load environment

# SUPABASE credentials. The password pulled from the .env is strictly confidential 
# If you are making your own database for the tick tracker, please add your own credentials next to the following 
# Indexed as SUPABASE_HOST, SUPABASE_PORT, SUPABASE_DB, SUPABASE_USER, and SUPABASE_PASSWORD
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

# Filter sites that are classified as "State Park" only 
park_table = park_table %>% filter(Category == "State Park") %>% 
  # Only select the state park name, category, county, longitude, latitude and location. 
  select(Name, County, Region, Longitude, Latitude) %>% 
  # Filter to make sure no repeat parks are included, since a park may have multiple facilities. 
  distinct(Name, .keep_all = TRUE) 

# Note that New York categorizes park regions with a code from 1-12. 
region_id = c(1:12)	
# These codes aren't intuitive to the user. As such, they should be renamed to their official names
# https://parks.ny.gov/visit/regions 
region_name = c("Niagara","Allegany",	"Genesee","Finger Lakes",	"Central","Adirondacks/Catskills",
                "Taconic","Palisades","Long Island","Thousand Islands",	"Saratoga/Capital","New York City")

# Note that the 6th index (Adirondacks/Catskills) does not technically have parks associated with it based on
# The list of parks from https://data.ny.gov/Recreation/State-Park-Facility-Points/9uuk-x7vh/about_data
# As such, do not worry if none of the parks in your database are associated with that region. 

# Make a named vector to convert the region column to park region names 
park_regions = setNames(nm = region_id, object = region_name)

# Update the park_table to replace the Region IDs with Region Names 
park_table = park_table %>% mutate(Region = park_regions[Region])

# Check the park_table
park_table %>% glimpse()

# Write the database to SUPABASE 
dbWriteTable(con, table_dictionary,park_table)

# Check the table is there 
con %>% dbListTables()

# Exit the connection
dbDisconnect(con)

# clear cache and remove variables 
rm(list = ls()); gc()









