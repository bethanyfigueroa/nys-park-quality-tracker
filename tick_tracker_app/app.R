# Bethany Figueroa, 3/9/26, SYSEN 5460
# Main Script for the NYS Park Tick Tracker

###### Load Packages and Data ####
library(dplyr)      # for data wrangling and pipelines
library(tidyr)      # for data cleanup, such as dropping na values
library(stringr)    # for fixing dates and other strings 
library(ggplot2)    # for visual plots of data
library(lubridate)  # for reading dates
library(DBI)        # allow for communication between R and databases
library(dbplyr)     # allow dplyr to work with databases
library(RPostgres)  # for PostgreSQL connections (SUPABASE uses PostgreSQL)
library(bslib)      # easier html construction
library(shiny)      # shiny app
library(plotly)     # interactive visuals
library(scales)     # for re-scaling values

########## 1.1 Non Reactive Definitions for Database Connection ########## 
# Define a table that is only there to track park names
table_dictionary = "park_list" # reference list for parks 

# The way park dictionary was created was from reading the unique names of state owned parks from NY
# https://data.ny.gov/Recreation/State-Park-Facility-Points/9uuk-x7vh/about_data
# See the script "make_park_list.R" for how this list was made and pushed to SUPABASE

# Make sure the working directory is correct. If not, change it. If error persists, it means the user did not include a .env file. 
# Please view the README for how to set your own .env file up. 
if (file.exists(".env")) {print(".env identified.")} else {
  print(".env was not identified. Changing working directory. If still not found, please ensure you have a .env file in the directory")
  setwd("tick_tracker")}

# Define the table of interest that will host the live data
table_of_interest = "tick_tracker" # live data table
# For the code used to generated the table schema and synthetic data, view make_tick_tracker.Rf

# Check working directory for env file. if it doesn't exist, then change directory. 

# Read the local environment file. Note that the USER NEEDS TO HAVE A .ENV WITH CORRECT CREDENTIALS
# BEFORE RECREATING THE APPLICATION. This should be the same .env you used to make your database containing 
# the tables "park_list" and "tick_tracker" from the scripts make_park_list.R and make_tick_tracker.R 
readRenviron(".env") # load environment

# SUPABASE credentials: SUPABASE_HOST, SUPABASE_PORT, SUPABASE_DB, SUPABASE_USER, and SUPABASE_PASSWORD
SUPABASE_HOST = Sys.getenv("SUPABASE_HOST")
SUPABASE_PORT = Sys.getenv("SUPABASE_PORT")
SUPABASE_DB = Sys.getenv("SUPABASE_DB")
SUPABASE_USER = Sys.getenv("SUPABASE_USER")
SUPABASE_PASSWORD = Sys.getenv("SUPABASE_PASSWORD")

# Function for connecting to the database that you gave SUPABASE credentials for 
# Note that this is just a dbConnect() but with inputs read from the SUPABASE environmental variables. 
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

########## 1.2 Non Reactive Definitions for User Interface Helpers ########## 

# Establish connection to the database's list of parks
con = connect()  

# Make a list of park choices based on the reference list of parks by collecting the column "Name"
choices_park = (tbl(con, table_dictionary) %>% select(Name,County,Region) %>% arrange(Name) %>% collect())$Name 

# These are vectors representing the county and region associated with park name list 
choices_county = (tbl(con, table_dictionary) %>% select(Name,County,Region) %>% arrange(Name) %>% collect())$County
choices_region = (tbl(con, table_dictionary) %>% select(Name,County,Region) %>% arrange(Name) %>% collect())$Region

# Exit the connection
dbDisconnect(con)

# Make a named vector so that the dataframe pushed by the user to the database has the correct county and region
park_county = setNames(object = choices_county, nm = choices_park) # Use as a look-up table for park's county
park_region = setNames(object = choices_region, nm = choices_park) # Use as a look-up table for park's region

########## 2. Define User Interface ########## 
ui = function(){
  ########## TITLE CARD #################################
  c1 = bslib::card(
    # Make a card header with dark color background and light text
    card_header(class = "bg-dark text-light",
                # Add this title                
                card_title("New York State Park Tick Tracker: Live Monitoring of Ticks Across State Parks")
                )
  )
  ########## SELECTOR CARD #################################
  c2_1 = bslib::card(
    
    # Give user the choice to full screen selector card if they cant read all the options
    full_screen = TRUE,
    
    # Make card header for filters (viewparks)
    bslib::card_header(card_title("VIEW TICK REPORTS")),
    bslib::card_body(
      ########## Selectors: Filter #########
      # Drop-downs for user can select from
      selectInput(inputId = "viewpark", label = "CLICK THE BOTTOM RIGHT EXPAND BUTTON FOR THE FULL LIST OF PARKS", choices = choices_park, selected = choices_park[2])
    )
  )
  c2_2 = bslib::card(
    # Make card header for the submission form, with a park selector, tick numeric input, and bites numeric input
    bslib::card_header(card_title("FILE A REPORT OF YOUR TICK ENCOUNTER")),
    bslib::card_body(
      ########## Selectors: Form Submission #########
      selectInput(inputId = "submitpark", label = "PARK NAME", choices = choices_park, selected = choices_park[2]),
      numericInput(inputId = "ticks", label = "TICKS SPOTTED", value = 1),
      numericInput(inputId = "bites", label = "BITES RECEIVED", value = 1),
      actionButton("send", "SUBMIT FORM"), textOutput("submit") # trigger submission when send button is pressed
    )
  )
  ########## PLOT CARD #################################
  c3 = bslib::layout_column_wrap(
    ########## Plots #################################
    bslib::card(plotlyOutput(outputId = "plot_track_tick_total")), # for ticks tracked by region
    width = 1/2, # set width of plot to half of card
    layout_column_wrap(
      width = 1,
      heights_equal = "row", # set rows equal for plot card and filter card
      bslib::card(plotlyOutput(outputId = "plot_track_tick_park")),
      c2_1) # filter card included in wrap
  )
  ########## TEXT CARDS FOR THE CHARTS #################################
  c4 = bslib::layout_column_wrap(
    bslib::card(
      bslib::card_header("What data does the New York State Park Tick Tracker include?", class = "bg-dark"),
      bslib::card_footer(textOutput("text_highlight"))),
  )
  
  ########## VALUE BOXES CARD #################################
  box1 = bslib::value_box(
    title = "Total Number of Ticks Tracked", value = textOutput("overall_ticks"),
    class = "bg-info text-light", # user color by association to connect it to share of cost chart
    # add a fontawesome icon representing solar power
    showcase = shiny::icon("bug"))  
  
  box2 = bslib::value_box(
    title = "Park with the Most Ticks", value = textOutput("top_park"),
    class = "bg-danger text-light", # user color by association to connect it to the solar yield rebates chart
    # add a fontawesome icon representing solar power
    showcase = shiny::icon("triangle-exclamation"))  
  
  box3 = bslib::value_box( # Show the date of the last form submitted along with the park 
    title = "Last Report Issued", value = textOutput("last_update_date"),
    class = "bg-secondary text-light", # user color by association to connect it to the confidence interval
    # add a fontawesome icon representing solar power
    showcase = shiny::icon("clock"))  
  
  # Bundle the value boxes and include a header
  c5 = bslib::card(
    # Bundle the value boxes together and adjust width
    bslib::card_body(layout_column_wrap(box1, box2, box3, width = 1/3))
  )
  
  ########## TABLE CARDs #################################
  c6 = card( tableOutput("table_tick_tracker") ) # raw look at the tick tracker
  c7 = card( tableOutput("table_stat_park_summary") ) # summary of tick tracker by park
  c8 = card( tableOutput("table_stat_region_summary") ) # summary of tick tracker by region
  
  ########## PAGE SETTINGS #################################
  # Create a sidebar mainsplit layout (based on NYC flights template)
  bslib::page(
    title = "New York State Parks Tick Tracker", 
    
    # Apply a theme to the page, preferably a non-distracting one from: https://bootswatch.com/
    theme = bslib::bs_theme(preset = "united"),

    # Stack cards, starting with Title and Value Boxes 
    c1, # header for the app
    # Put next cards in a sidebar-main panel split layout
    bslib::layout_sidebar(
      # Sidebar for the Selectors
      sidebar = bslib::sidebar(c2_2, position = c("right")), 
      
      # Main Panel: Introduce value boxes
      c5,
      # Make a series of panels for plots, the raw data, and summary tables
      bslib::navset_card_pill(
        selected = "plots",
        # Open plots
        bslib::nav_panel(title = "VISUALS", value = "plots", c3), # plots
        # Open table 1 (tick tracker)
        bslib::nav_panel(title = "TICK TRACKER", value = "table_1", c6), # table
        # Open table 2 (tick summary by park)
        bslib::nav_panel(title = "INDIVIDUAL PARKS", value = "table_1", c7),
        # Open table 3 (tick summary by region)
        bslib::nav_panel(title = "PARK REGIONS", value = "table_1", c8)
      ),
      # Text Render for description of the tool 
      c4)
  )
}

########## 3. Define the Server Function ########## 
server = function(input, output, session) {
  
  ########## 3.1 Reactive Connections ########## 
  # Collect the tick tracker table from the connected database 
  stat_tick_tracker = reactive({ 
    con = connect()
    # Connect to database, retrieve table of interest (tick_tracker)
    tbl(con, table_of_interest) %>% 
             # Order the query by most recent reports, in descending order of date
             arrange(desc(report_date)) %>% collect() 
  }) %>% bindEvent({ input$send},  # update if user updated the database.
    ignoreNULL = FALSE) # ignore null action button so the data table loads up during app launch
  
  # Reactive expression triggered when the user is sending a form
  output$submit = reactive({
    # connect to the database
    con = connect() 
    # Create a dataframe using the user's inputs. Formatted with exact schema as the database table
    inputform = tibble(name = input$submitpark, county = park_county[input$submitpark], 
                       region = park_region[input$submitpark],
                       # Save the date time of the report using the system's time. Use location to account for timezone
                       report_date = ymd_hms(Sys.time(), tz = Sys.timezone(location = TRUE)), 
                       # Report the number of identified ticks. Clean user's input by making it a positive integer
                       ticks_identified = abs(as.integer(round(input$ticks))), 
                       # Report the number of bites recieved. Clean user's input by making it a positive integer
                       tick_bites = abs(as.integer(round(input$bites))))
    
    # Insert user's dataframe as a new row into the table of interest using a postgre query
    dbSendQuery(
      con, "INSERT INTO tick_tracker (name,county,region,report_date,ticks_identified,tick_bites) VALUES ($1, $2, $3, $4, $5, $6);",
      list(inputform$name,inputform$county,inputform$region, 
           inputform$report_date, inputform$ticks_identified, inputform$tick_bites))
    
    # Confirm submission and report the date of submission cleanly for NY timezone
    a = paste("SUBMITTED:",stamp("3/1/26 1:00 PM")(with_tz((ymd_hms(Sys.time(), tz = Sys.timezone())),tzone = "America/New_York")))
    
  }) %>% bindEvent(input$send)
  
  # Disconnect from the tick tracker database. Ensures connections established by previous expressions do not persist
  dbDisconnect(con)
  
  ########## 3.2 Reactive Stat: Park Summary ########## 
  stat_park_summary = reactive({
    # Create a reactive table based on the data collected from the tick_tracker database
    (stat_tick_tracker() %>%  
       # Mutate to append year and month data for the summary
       mutate(Year = year(report_date), Month = month(report_date)) %>%
       
       # Group by park name, year, and report month
       group_by(name, Year, Month) %>% 
       
       # Summarize the number of reports and the total number of tick sightings and bites for the given month & year
       summarize(Reports = n(), total_ticks = sum(ticks_identified), total_bites = sum(tick_bites),
                 # Calculate some statistics for tick sightings per hike and tick bites per hike, including confidence intervals
                 avg_ticks = mean(ticks_identified), 
                 ticks_ci_low = quantile(ticks_identified, probs = 0.025), ticks_ci_high = quantile(ticks_identified, probs = 0.975),
                 avg_bites = mean(tick_bites),
                 bites_ci_low = quantile(tick_bites, probs = 0.025), bites_ci_high = quantile(tick_bites, probs = 0.975)) %>%
       
       # Arrange by month, year, and total number of tick observations for a park
       # Use descending order for ticks_identified so parks with the highest number of ticks are shown at top
       arrange(Year, Month, desc(total_ticks)))
    
  }) %>% bindEvent({ stat_tick_tracker() }) # Update if the tick tracker changed

  ########## 3.3 Reactive Stat: Regional Summary ##########
  stat_region_summary = reactive({
    stat_tick_tracker() %>%  
      # Mutate with year and month based on the time of the tick report
      mutate(Year = year(report_date), Month = month(report_date)) %>%
      
      # Group by park name, year, and report month
      group_by(region, Year, Month) %>% 
      
      # Summarize the number of reports and the total number of tick sightings and bites for the given month & year
      summarize(Reports = n(), total_ticks = sum(ticks_identified), total_bites = sum(tick_bites),
                # Calculate some statistics for tick sightings per hike and tick bites per hike, including confidence intervals
                avg_ticks = mean(ticks_identified), 
                ticks_ci_low = quantile(ticks_identified, probs = 0.025), ticks_ci_high = quantile(ticks_identified, probs = 0.975),
                avg_bites = mean(tick_bites),
                bites_ci_low = quantile(tick_bites, probs = 0.025), bites_ci_high = quantile(tick_bites, probs = 0.975)) %>%
      
      # Arrange by month, year, and total number of tick observations for a park
      # Use descending order for ticks_identified so parks with the highest number of ticks are shown at top
      arrange(Year, Month, desc(total_ticks))
    
  }) %>% bindEvent({ stat_tick_tracker() }) # Update if the tick tracker changed
  
  ########## 4.1 Reactive Visuals: Plot Total Ticks by Date for a selected park ########## 
  output$plot_track_tick_park = renderPlotly({ 
    # Show a visual for the number of ticks reported for the selected park (input$viewpark)
    ggplot_track_tick_park = stat_tick_tracker() %>% 
      
      # Mutate the plot and summarize by aggregate number of ticks per day
      mutate(report_day = date(report_date)) %>% 
      group_by(name, report_day) %>%
      summarize(total_ticks = sum(ticks_identified)) %>%
      
      # Filter for only the user's scope of interest
      filter(name == input$viewpark) %>% 
      
      # Set the aesthetic such that x-axis is date time and y-axis as ticks reported. No hoverlabel, leave blank
      ggplot(mapping = aes(x = report_day, y = total_ticks, text = ""))+
      
      # Create a line plot for the tick tracker for the park selected
      geom_line(alpha = 1, color = "red", size = 2) + 
      
      # Add labels for the tracker
      labs(
        # Add a title for the graph 
        title = paste("How Many Ticks Were Reported at Your Park?"),
        
        # Add the label for the horizontal axis (the time frame of interest)
        x = paste("Date of Tick Sightings at",input$viewpark,"Park"),
        
        # Add the label for the vertical axis (Number of ticks spotted)
        y = "Number of Ticks per Hike") + 
      
      # Change the theme to classic
      theme_classic() + 
      
      # Make the title bold so it stands out to the reader
      theme(plot.title = element_text(face = "bold")) + 
      
      # Use scales to show the x-axis as date time
      scale_x_datetime(date_labels = "%b %d") +
      
      # Use rounded numbers for the y axis, with the last part of the graph defined as one plus the max
      scale_y_continuous(breaks = c(1: (max((stat_tick_tracker())$ticks_identified)))) 
    
    # Return the ggplot visualization as a plotly graph. Pipeline it to a layout where tooltip is blank
    plotly::ggplotly(ggplot_track_tick_park, tooltip = c("text")) %>%
      
      # Adjust plotly buttons available for graph (remove logo and keep download image button)
      plotly::config(displaylogo = FALSE, modeBarButtons = list(list("toImage")))
    
    # Update if database or selected park changed
  }) %>% bindEvent({ stat_tick_tracker() ; input$viewpark }) 
  
  ########## 4.2 Reactive Visuals: Plot Tick Tracker Database by Month ##########
  output$plot_track_tick_total = renderPlotly({
    
    # Make a bar chart for the severity of tick encounters per park region using the average as a comparable metric
    ggplot_track_tick_total = stat_region_summary() %>%
      
      # Give the data a new column representing the text for the hoverlabel 
      mutate(hoverlabel = paste0(
        "<b>Park Region:</b> ", region, "<br>", # label for region, break with html <br>
        "<b>Mean Tick Bites:</b> ",scales::number(avg_bites, accuracy = 0.1), "per hike<br>",
        "<b>95% Confidence Interval</b>: ", scales::number(bites_ci_low, accuracy = 0.1)," to ",
        scales::number(bites_ci_high, accuracy = 0.1),"<br>","<b>From ", Reports," reports</b>"
      )) %>%
      
      # Set the aesthetic such that x-axis is date time and y-axis as ticks reported. Set text to hoverlabel
      ggplot(mapping = aes(x = region, y = avg_bites, text = hoverlabel)) +
      
      # Create a scatter plot for the tick reports
      geom_bar(position = "dodge", stat = "identity", alpha = 0.9) + 
      
      # Add labels for the tracker
      labs(
        # Add a title for the graph 
        title = paste0("How Severe are Tick Encounters in Parks?"),
        
        # x-axis: regions representing groups of parks in New York. Give the graph some
        x = "New York State Park Region",
        
        # Add the label for the y-axis (Number of ticks spotted) along with the scope of the datas
        y = paste0("Average Bites per Encounter \n[From ",length((stat_tick_tracker())$report_date),
                   " reports in ",stamp("3/01/26")(ymd_hms(min((stat_tick_tracker())$report_date), tz = "EST")),
                  # Using lubridate's stamp function to make cleaner labels for dates
                  " - ", stamp("3/01/26")(ymd_hms(max((stat_tick_tracker())$report_date), tz = "EST")),"]")) + 
      
      # Change the theme to classic and set a friendly upper and lower bound for the chart
      theme_classic() + 
      
      # Make the title bold so it stands out to the reader
      theme(plot.title = element_text(face = "bold")) + 
      
      # Coordinate flip to make the plot easier to read
      coord_flip()
    
    # Turn the ggplot into a plotly visual
    plotly::ggplotly(ggplot_track_tick_total, tooltip = c("text")) %>%
      # Pipeline into a custom layout to apply the hoverlabel. 
      plotly::layout(hoverlabel = list(align = "left", 
                                       # Use white text for contrast. Make border and background black to match bars
                                       font = list(color = "white",bordercolor = "black", bgcolor = "black"))) %>%
      # Remove buttons except for downloading image
      plotly::config(displaylogo = FALSE, modeBarButtons = list(list("toImage")))
    
  }) %>% bindEvent({ stat_tick_tracker() }) # update when tick tracker changes
  
  ########## 4.3 Reactive: Render Table of Tick Tracker Database ########## 
  output$table_tick_tracker = renderTable({ 
    stat_tick_tracker() %>%
      
      # Change the report date column to a format that is user friendly 
      mutate(report_date = as.character(stamp("March 1, 2026 1:00 PM")(with_tz(report_date,tzone = "America/New_York"))), 
             
             # Need to round and set as characters to avoid showing unwanted decimal points
             ticks_identified = as.character(round(ticks_identified))) %>%
      
      # Rename the columns for consistency with the app. Put date of report as first entry 
      select(`Reported Date Time` = report_date, `Park Name` = name, `Park County` = county, 
             `Park Region` = region, `Ticks Spotted` = ticks_identified, `Bites Received` = tick_bites) 
  }, 
  # Table settings (make striped, hover-able, and fit to page)
  striped = TRUE, hover = TRUE, width = "100%"
  ) %>% bindEvent({ stat_tick_tracker()}) # update if database changed
  
  ########## 4.4 Reactive: Render Park Summary Statistics Table ########## 
  output$table_stat_park_summary = renderTable({ 
    stat_park_summary() %>% 
      # Need to round and set as characters to avoid showing unwanted decimal points 
      mutate(Year = as.character(round(Year)), Month = as.character(round(Month)), total_ticks = as.character(round(total_ticks))) %>%
      
      # Rename the columns for consistency with the app. Keep capital lettered variables the same
      select(`Park Name` = name, Year = Year, Month = Month, Reports = Reports,
             `Total Ticks` = total_ticks, `Total Bites` = total_bites, `Mean Ticks` = avg_ticks,
             `Mean Ticks 2.5% Confidence Interval` = ticks_ci_low , 
             `Mean Ticks 97.5% Confidence Interval` = ticks_ci_high, 
             `Mean Bites` = avg_bites,
             `Mean Bites 2.5% Confidence Interval` = bites_ci_low , 
             `Mean Bites 97.5% Confidence Interval` = bites_ci_high)
  }, 
  # Make striped, hoverable, and fit to page
  striped = TRUE, hover = TRUE, width = "100%"
  ) %>% bindEvent({ stat_park_summary()}) # update if summary table changed
  
  ########## 4.5 Reactive: Render Region Summary Statistics Table ########## 
  output$table_stat_region_summary = renderTable({ 
    stat_region_summary() %>%
      # Need to round and set as characters to avoid showing unwanted decimal points
      mutate(Year = as.character(round(Year)), Month = as.character(round(Month)), total_ticks = as.character(round(total_ticks))) %>%
      # Rename the columns for consistency with the app. Keep capital lettered variables the same
      select(`Park Region` = region, Year = Year, Month = Month, Reports = Reports,
             `Total Ticks` = total_ticks, `Total Bites` = total_bites, `Mean Ticks` = avg_ticks,
             `Mean Ticks 2.5% CI` = ticks_ci_low , `Mean Ticks 97.5% CI` = ticks_ci_high, `Mean Bites` = avg_bites,
             `Mean Bites 2.5% CI` = bites_ci_low , `Mean Bites 97.5% CI` = bites_ci_high)
  }, 
  # Make striped, hoverable, and fit to page
  striped = TRUE, hover = TRUE, width = "100%"
  ) %>% bindEvent({ stat_region_summary()}) # update if summary table changed
  
  ########## 5.1 Render: Text Highlight ########## 
  output$text_highlight = renderText({
    # Output a line of text that reads out the number of solar projects included in the selected scope
    paste("Data is intended to represent", as.character(scales::comma(sum((stat_region_summary())$total_ticks))), "ticks from",
          as.character(scales::comma(sum((stat_region_summary())$Reports))), 
          "reports submitted by hikers visiting one of",as.character(length(choices_park)), "New York State owned parks.",
          "If your selected park does not show any data, it means nobody has reported ticks there yet!\n",
          "All entries prior to March 9th, 2026, represent synthetic data for tick sightings and bites based on a poisson distribution",
          "with a mean of 1 tick and 1 bite per encounter. Synthetic data assumes a random sample of parks and reports based on a normal distribution",
          "with a mean reporting time of 2:00 PM EST and a standard deviation of ± 3 hours.", 
          'This app was created by Bethany Figueroa for the class "SYSEN5460: Data Science for Socio-Technical Systems"',
          "taught by Professor Fraser at Cornell University.")
    # Update whenever the stat for region summaries changes 
  }) %>% bindEvent({ stat_region_summary() })
  
  ########## 5.2 Value boxes ########## 
  
  # Value Box 1: Total Ticks Tracked
  output$overall_ticks = renderText({ 
    as.character(scales::comma(sum((stat_region_summary())$total_ticks))) 
  }) %>% bindEvent({ stat_region_summary() }) # Update if  stat changed
  
  # Value Box 2: Park with most amount of Ticks 
  output$top_park = renderText({ 
    (stat_park_summary())$name[1]
  }) %>% bindEvent({ stat_park_summary()}) # update if summary table changed
  
  #Value Box 3: Last reported date of tick sighting
  output$last_update_date = renderText({ 
    # Report date of last report. Time stamp with a simple format. 
    as.character(stamp("3/1/26")(ymd_hms(max( (stat_tick_tracker())$report_date),tz = "America/New_York")))
    }) %>% bindEvent({ stat_tick_tracker() }) # Update if stat changed
}

########## Run the application ########## 
shinyApp(ui = ui, server = server)

