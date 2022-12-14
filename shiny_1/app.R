

library(shiny)
library(flexdashboard)
library(tidyverse)
library(plotly)

nypd_complaint = 
  read_csv("nypd_complaint_two_year_data.csv")

complaint_select=nypd_complaint %>% 
  janitor::clean_names() %>% 
  select(month,day,year,ofns_desc,susp_sex,susp_race,susp_age_group,latitude,longitude,vic_race,vic_sex,vic_age_group) %>% 
  drop_na(susp_sex,susp_race,susp_age_group,vic_race,vic_sex,vic_age_group)%>% 
  mutate(
    date=str_c(year,month,day, sep = "-"),
    location=str_c(longitude,latitude,sep=", "))

crime_type=complaint_select %>% 
  group_by(ofns_desc,year) %>% 
  summarise(obs=n()) %>% 
  filter(obs>5000)

min_longitude=complaint_select %>% distinct(longitude) %>% min()
max_longitude=complaint_select %>% distinct(longitude) %>% max()

min_latitude=complaint_select %>% distinct(latitude) %>% min()
max_latitude=complaint_select %>% distinct(latitude) %>% max()

complaint_select %>% distinct(date) %>% pull()

crime_distinct=crime_type %>% distinct(ofns_desc) %>% pull()

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("NYPD Complaints During The Pandemic"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
          #sliderInput
          sliderInput("longitude_start", 
                      label = h3("Longitude Start"), 
                      min = min_longitude, 
                      max = max_longitude,
                      value = -74
          ),
          
          sliderInput("longitude_end", 
                      label = h3("Longitude End"), 
                      min = min_longitude, 
                      max = max_longitude,
                      value = -74
          ),   
          
          sliderInput("latitude_start", 
                      label = h3("Latitude Start"), 
                      min = min_latitude, 
                      max = max_latitude,
                      value = 40.6
          ),
          
          sliderInput("latitude_end", 
                      label = h3("Latitude End"), 
                      min = min_latitude, 
                      max = max_latitude,
                      value = 40.6
          ),   
          #dateRangeInput
          dateRangeInput("start_date", 
                         label = h3("Date Range Start"),
                         start = "2020-1-1",
                         end   = "2021-9-9",
                         min = "2020-1-1",
                         max = "2021-9-9"),
          
          #dateRangeInput
          dateRangeInput("end_date", 
                         label = h3("Date Range End"),
                         start = "2020-1-1",
                         end   = "2021-9-9",
                         min = "2020-1-1",
                         max = "2021-9-9"),
          
          #checkboxInput
          checkboxGroupInput("Crime_Type", 
                             label = h3("Crime Type"), 
                             choices = list("ASSAULT 3 & RELATED OFFENSES", 
                                            "CRIMINAL MISCHIEF & RELATED OF" , 
                                            "GRAND LARCENY",
                                            "HARRASSMENT 2",
                                            "PETIT LARCENY"
                             ),
                             selected = list("ASSAULT 3 & RELATED OFFENSES", 
                                             "CRIMINAL MISCHIEF & RELATED OF" , 
                                             "GRAND LARCENY",
                                             "HARRASSMENT 2",
                                             "PETIT LARCENY"
                             ))
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotlyOutput("Plot1"),plotlyOutput("Plot2"),textOutput("text")
          
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

  output$Plot1 <- renderPlotly({
    complaint_select %>% 
      filter(
        date >= input[["start_date"]][1] & date <= input[["end_date"]][2],
        ofns_desc == input[["Crime_Type"]]
      ) %>%
      group_by(ofns_desc,date) %>% 
      summarise(obs=n()) %>% 
      mutate(text_label=str_c("Crime: ", ofns_desc, '\nDate: ', date)
      ) %>% 
      plot_ly(
        x = ~date, type = "bar",
        alpha = 0.5, color = ~ofns_desc, text = ~text_label)
  })
    
    output$Plot2=renderPlotly({
      complaint_select %>% 
        filter(
          longitude <= max(input[["longitude_start"]], input[["longitude_end"]]) & longitude >= min(input[["longitude_start"]], input[["longitude_end"]]),
          latitude <= max(input[["latitude_start"]],input[["latitude_end"]]) & latitude >= min(input[["latitude_start"]],input[["latitude_end"]]),
          ofns_desc == input[["Crime_Type"]]
        ) %>%
        mutate(text_label = str_c("Crime: ", ofns_desc, '\nLongitude: ', longitude, '\nLatitude: ', latitude)) %>% 
        plot_ly(
          x=~latitude, y = ~longitude, type = "scatter", mode = "markers",
          alpha = 0.5, color = ~ofns_desc, text = ~text_label, showlegend = FALSE) %>% 
        layout(
          xaxis = list(
            range=c(min_latitude,max_latitude)
          )) %>% 
        layout(yaxis = list(range = c(min_longitude,max_longitude)))
    })
    
    output$text=renderPrint({ input$Crime_Type })
}

# Run the application 
shinyApp(ui = ui, server = server)
