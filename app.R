# app structure 
library(shiny)
library(dplyr)
library(readr)
library(leaflet)

# Load geocoded data
geocoded <- read_csv("geocoded_locations.csv") %>%
  filter(!is.na(lat) & !is.na(lon)) %>%
  filter(
    # Manual cleanup of obvious non-locations
    !text %in% c("St.", "Vol", "pp", "III", "II", "No.", "MS", "TT", "esq", "Vol.", "INTRODUOTION"),
    # Geographic bounding box for likely US colonial locations
    lat > 24 & lat < 50,
    lon > -130 & lon < -60
  )

# UI 
ui <- fluidPage(
  titlePanel("Mapped Locations from Virginia Company Records (Vol 1)"),
  
  sidebarLayout(
    sidebarPanel(
      textInput("search", "Search place name:", ""),
      sliderInput("pageRange", "OCR Page Range:",
                  min = min(geocoded$page),
                  max = max(geocoded$page),
                  value = range(geocoded$page),
                  step = 1)
    ),
    
    mainPanel(
      leafletOutput("map", height = 600)
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive filtering based on user input
  filtered_data <- reactive({
    geocoded %>%
      filter(
        page >= input$pageRange[1],
        page <= input$pageRange[2],
        grepl(input$search, text, ignore.case = TRUE)
      )
  })
  
  # Color palette for NER labels
  label_colors <- colorFactor(
    palette = c("darkblue", "magenta", "forestgreen", "orange", "purple"),
    domain = geocoded$label
  )
  
  # Render the interactive map
  output$map <- renderLeaflet({
    leaflet(filtered_data()) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~lon,
        lat = ~lat,
        color = ~label_colors(label),
        radius = 5,
        fillOpacity = 0.8,
        stroke = FALSE,
        popup = ~paste0(
          "<b>", text, "</b><br>",
          "OCR page: ", page, "<br>",
          "NER Label: ", label
        ),
        label = ~text
      ) %>%
      addLegend(
        "bottomright",
        pal = label_colors,
        values = ~label,
        title = "NER Label",
        opacity = 1
      )
  })
}

# Launch app
shinyApp(ui, server)
