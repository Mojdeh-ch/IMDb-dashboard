# Server.R

server <- function(input, output, session) {
  
  con <- dbConnect(
    RMySQL::MySQL(),
    user = "root",
    password = "SSSS",
    dbname = "IMDb",
    host = "localhost"
  )
  
  
  output$titleTypePlot <- renderPlotly({
    
    query <- "SELECT * FROM title_counts;"
    
    title_counts <- dbGetQuery(con, query)
    
    plot_ly(
      data = title_counts,
      x = ~reorder(titleType, -total),
      y = ~total,
      type = 'bar',
      marker = list(color = "#F5C518")
    ) %>%
      layout(
        title = list(
          text = "Total Number of Titles by Type",
          font = list(color = "white")
        ),
        xaxis = list(
          title = list(
            text = "Title Type",
            font = list(color = "white")
          ),
          tickangle = -45,
          tickfont = list(color = "white"),
          gridcolor = "rgba(255, 255, 255, 0.2)"
        ),
        yaxis = list(
          title = list(
            text = "Total Count",
            font = list(color = "white")
          ),
          tickfont = list(color = "white"),
          gridcolor = "rgba(255, 255, 255, 0.2)"
        ),
        margin = list(b = 100),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)" 
      )
  })
  output$genreTreemap <- renderPlotly({
    query <- "SELECT * FROM genre_counts"
    genre_counts <- dbGetQuery(con, query)
    
    plot_ly(
      data = genre_counts,
      labels = ~genre,
      parents = NA,
      values = ~total,
      type = 'treemap',
      textinfo = 'label+value',
      marker = list(colors = colorRampPalette(c("#FFD700", "#FF4500"))(nrow(genre_counts)))
    ) %>%
      layout(
        title = list(text = "Distribution of Titles by Genre",
                     font = list(color = "white")),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)" 
      )
  })
  
  output$stackedPlot <- renderPlotly({
    
    query <- "SELECT * FROM titles_per_year;"
    titles_data <- dbGetQuery(con, query)
    
    if (input$titleTypeFilter != "All") {
      time_series_data <- subset(titles_data, titleType == input$titleTypeFilter)
    }
    
    
    plot_ly(
      data = time_series_data,
      x = ~startYear,
      y = ~total_titles,
      color = ~titleType,
      type = 'scatter',
      mode = 'lines',
      fill = 'tonexty'
    ) %>%
      layout(
        title = list(
          text = "Stacked Plot of Titles Released Over Time by Type",
          font = list(color = "white")
        ),
        xaxis = list(
          title = list(
            text = "Year",
            font = list(color = "white")
          ),
          tickfont = list(color = "white"),
          gridcolor = "rgba(255, 255, 255, 0.2)"
        ),
        yaxis = list(
          title = list(
            text = "Number of Titles",
            font = list(color = "white")
          ),
          tickfont = list(color = "white"),
          gridcolor = "rgba(255, 255, 255, 0.2)"
        ),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)"
      )
    
  })
  
  output$directorsTable <- DT::renderDataTable({
    query <- ""
    
    directors_data <- dbGetQuery(con, query)
    
    DT::datatable(
      directors_data,
      options = list(
        pageLength = 10,
        order = list(list(2, 'desc'), list(3, 'desc'))
      ),
      rownames = FALSE
    )
  })

  output$writersTable <- DT::renderDataTable({
    query <- ""
    
    writers_data <- dbGetQuery(con, query)
    
    DT::datatable(
      writers_data,
      options = list(
        pageLength = 10,
        order = list(list(2, 'desc'), list(3, 'desc'))
      ),
      rownames = FALSE
    )
  })
  
  output$bubbleChart <- renderPlotly({
    
    query <- "SELECT * FROM genre_movie_weighted_rating"
    top_rated_movies <- dbGetQuery(con, query)
    
    
    filtered_data <- top_rated_movies %>%
      filter(startYear >= input$yearRange[1] & startYear <= input$yearRange[2])
    
    
    top_250_movies <- filtered_data %>%
      arrange(desc(weighted_rating)) %>%
      head(250)
    
    
    max_size <- 30
    min_size <- 5
    
    plot_ly(
      data = top_250_movies,
      x = ~weighted_rating,
      y = ~v,
      type = 'scatter',
      mode = 'markers',
      marker = list(
        size = ~((v - min(v)) / (max(v) - min(v)) * (max_size - min_size) + min_size),
        color = ~weighted_rating,
        opacity = 0.8,
        colorscale = 'Plasma',
        colorbar = list(title = "Rating", titlefont = list(color = "white"), tickfont = list(color = "white")) # White color for colorbar text
      ),
      text = ~paste("Title:", primaryTitle, "<br>Year:", startYear, "<br>Rating:", round(weighted_rating, 1), "<br>Votes:", v)
    ) %>%
      layout(
        title = list(
          text = paste("Top 250 Movies between", input$yearRange[1], "and", input$yearRange[2]),
          font = list(color = "white")
        ),
        xaxis = list(
          title = list(
            text = "Weighted Rating",
            font = list(color = "white")
          ),
          tickfont = list(color = "white"),
          gridcolor = "rgba(255, 255, 255, 0.2)"
        ),
        yaxis = list(
          title = list(
            text = "Number of Votes",
            font = list(color = "white")
          ),
          tickfont = list(color = "white"),
          gridcolor = "rgba(255, 255, 255, 0.2)"
        ),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)"
      )
    
    
  })
  
  output$treemap <- renderPlotly({
  
    query <- "SELECT * FROM genre_movie_weighted_rating;"
genre_data <- dbGetQuery(con, query)


genre_avg <- genre_data %>%
  group_by(genre) %>%
  summarise(avg_weighted_rating = round(mean(weighted_rating, na.rm = TRUE)))


top_movies_per_genre <- genre_data %>%
  group_by(genre) %>%
  top_n(20, weighted_rating)%>%
  mutate(weighted_rating = round(weighted_rating, 1))


treemap_data <- rbind(
  data.frame(
    id = genre_avg$genre,
    parent = NA,
    value = genre_avg$avg_weighted_rating,
    label = genre_avg$genre,
    color = genre_avg$avg_weighted_rating
  ),
  data.frame(
    id = paste(top_movies_per_genre$genre, top_movies_per_genre$primaryTitle, sep = "-"),
    parent = top_movies_per_genre$genre,
    value = top_movies_per_genre$weighted_rating,
    label = top_movies_per_genre$primaryTitle,
    color = top_movies_per_genre$weighted_rating
  )
)

plot_ly(
  data = treemap_data,
  type = "treemap",
  labels = ~label,
  parents = ~parent,
  values = ~value,
  textinfo = "label+value",
  marker = list(
    colors = ~color,
    colorscale = "Viridis",
    showscale = TRUE,
    colorbar = list(
      title = list(
        text = "Color Scale",
        font = list(color = "white")
      ),
      tickfont = list(color = "white")
    )
  )
) %>%
  layout(
    title = list(text = "Treemap of Genres and Top 20 Movies by Weighted Rating",
                 font = list(color = "white")),
    paper_bgcolor = "rgba(0,0,0,0)",
    plot_bgcolor = "rgba(0,0,0,0)" 
  )
  })
}