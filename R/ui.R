#ui.R

ui <- dashboardPage(
  dashboardHeader(
    title = "IMDb Analytics Dashboard"
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Titles", tabName = "titles", icon = icon("film")),
      menuItem("People", tabName = "people", icon = icon("user")),
      menuItem("Ratings", tabName = "ratings", icon = icon("star"))
    )
  ),
  dashboardBody(
    tags$head(
      includeCSS("imdb_style.css")
    ),
    tabItems(
      # Titles Tab
      tabItem(tabName = "titles",
              h2("Titles Overview"),
              fluidRow(
                box(title = "Title Counts by Type", width = 6, 
                    plotlyOutput("titleTypePlot")),
                box(title = "Distribution of Titles by Genre", width = 6, 
                    plotlyOutput("genreTreemap"))
              ),
              fluidRow(
                box(title = "Time Series of Titles by Year", width = 12, 
                    selectInput("titleTypeFilter", "Select Title Type:", 
                                choices = c("All", "short", "movie", "tvShort", "tvMovie", 
                                            "tvEpisode", "tvSeries", "tvMiniSeries", "tvSpecial", 
                                            "video", "videoGame", "tvPilot"),
                                selected = "movie"),
                    plotlyOutput("stackedPlot"))
              )
      ),
      
      # People Tab
      tabItem(tabName = "people",
              h2("People Overview"),
              fluidRow(
                box(title = "Top Directors by Average Rating", width = 6, 
                    DT::dataTableOutput("directorsTable")),
                box(title = "Top Writers by Average Rating", width = 6, 
                    DT::dataTableOutput("writersTable"))
              )
      ),
      
      # Ratings Tab
      tabItem(tabName = "ratings",
              h2("Ratings Overview"),
              fluidRow(
                box(title = "Top Movies by Year", width = 12,
                    sliderInput("yearRange", 
                                "Select Year Range:", 
                                min = 1920, 
                                max = 2024, 
                                value = c(2000, 2024), 
                                step = 1),
                    plotlyOutput("bubbleChart"))
              ),
              fluidRow(
                box(title = "Top Movies by Genre", width = 12,
                    plotlyOutput("treemap"))
              )
      )
    )
  )
)
