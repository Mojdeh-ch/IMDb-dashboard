# app.R

# Source the UI and server scripts
source("ui.R")
source("server.R")
source("global.R")

# Run the application 
shinyApp(ui = ui, server = server)

