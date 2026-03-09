# Recreating the Tick Tracker App with Your Own .env File
#### Create a Database
Before you can recreate the program, you need to create a database that can be written to by the supporting scripts in this repository. For consistency, it is highly recommended you create your own PostgreSQL Database via [Supabase](https://supabase.com/). Here are some simple steps for starting up:
1. Go to https://supabase.com and create a project, or use an existing one
2. Go to Project Settings > Database
3. Find your connection details and fill in the .env variables with your own credentials
#### Create a .env File 
After cloning the github repository, setting up Supabase, and finding your credentials - you can now create a .env file that will be referenced by the project's R scripts.  Here is a sample of what your .env file should look like. It must be created in the directory "tick_tracker_app"

```sample_env
# General Format: db.your-project-id.supabase.co
# Replace "aws-1-us-east-1.pooler.supabase.com" with your Supabase database host. 
# The example below is the Tick Tracker's Supabase Host 
SUPABASE_HOST= aws-1-us-east-1.pooler.supabase.com

# Database port. Default for the project is 5432 for PostgreSQL. 
SUPABASE_PORT= 5432

# Database name (usually "postgres" for Supabase)
SUPABASE_DB= postgres

# Database user. The admin user is usually "postgres" plus a string of characters for Supabase
# For public access to the tick tracker database, please set user as “authenticated” 
SUPABASE_USER= postgres.[YOUR PROJECT ID]

# This password would normally bypass Row Level Security 
# If you are creating your own database based on the tick tracker, please keep this secret
# This would normally be your database password, found in the Database settings. 
SUPABASE_PASSWORD= [YOUR PASSWORD]
```
#### Run the Scripts
To recreate the database with the appropriate schema and same data,  run the following scripts in the tick_tracker_app directory using RStudio or PositCloud: 
1. Run "make_park_list.R" to make the initial parks list and write the table to your database
2. Run "make_tick_tracker.R" and write the table to your database
3. Go to "app.R" and  click "Run  App" within RStudio or PositCloud. 

After completing these steps, you should have recreated the same database with the same exact table schemas used for the New York State Park Tick Tracker App. You should have a local version of the app that you can replicate and repurpose for your own park service use case. 

