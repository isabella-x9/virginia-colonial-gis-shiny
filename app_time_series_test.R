# RShiny new app
library(shiny)
library(leaflet)
library(dplyr)
library(readr)
library(tidygeocoder)

# Load cleaned entities
entities <- read_csv("/Users/izzi/Desktop/Duke/Data+/RShiny/entities_clean.csv")

# approximate year using page numbers
entities <- entities %>%
  mutate(
    year = case_when(
      `PAGE NUMBER` >= 1 & `PAGE NUMBER` <= 50 ~ 1607,
      `PAGE NUMBER` >= 51 & `PAGE NUMBER` <= 100 ~ 1610,
      `PAGE NUMBER` >= 101 & `PAGE NUMBER` <= 150 ~ 1614,
      `PAGE NUMBER` >= 151 & `PAGE NUMBER` <= 200 ~ 1617,
      `PAGE NUMBER` >= 201 & `PAGE NUMBER` <= 250 ~ 1622,
      TRUE ~ 1625  # anything else
    )
  )

# filter GPE/LOC only
geo_entities <- entities %>%
  filter(LABEL %in% c("GPE", "LOC")) %>%
  distinct(`ENTITY NAME`, .keep_all = TRUE)

# geocode 
geocoded <- geo_entities %>%
  geocode(`ENTITY NAME`, method = "osm", lat = lat, long = lon)

# join back
geo_entities <- geo_entities %>%
  left_join(
    geocoded %>% select(`ENTITY NAME`, lat, lon),
    by = "ENTITY NAME"
  ) %>%
  filter(!is.na(lat) & !is.na(lon))

# UI
ui <- fluidPage(
  titlePanel("Virginia Company Records Time Series Map"),
  sidebarLayout(
    sidebarPanel(
      sliderInput(
        "yearRange", "Year Range:",
        min = min(geo_entities$year, na.rm = TRUE),
        max = max(geo_entities$year, na.rm = TRUE),
        value = c(1607, 1625),
        step = 1,
        sep = ""
      ),
      textInput("search", "Search Place Name:", "")
    ),
    mainPanel(
      leafletOutput("map", height = 600)
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # color palette for labels
  label_colors <- colorFactor(
    palette = c("blue", "darkgreen", "orange", "purple", "red"),
    domain = geo_entities$LABEL
  )
  
  filtered <- reactive({
    geo_entities %>%
      filter(
        year >= input$yearRange[1],
        year <= input$yearRange[2],
        grepl(input$search, `ENTITY NAME`, ignore.case = TRUE)
      )
  })
  
  output$map <- renderLeaflet({
    leaflet(filtered()) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~lon,
        lat = ~lat,
        color = ~label_colors(LABEL),
        popup = ~paste0("<b>", `ENTITY NAME`, "</b><br>Label: ", LABEL, "<br>Year (approx): ", year),
        radius = 5,
        fillOpacity = 0.8,
        stroke = FALSE
      ) %>%
      addLegend(
        "bottomright",
        pal = label_colors,
        values = geo_entities$LABEL,
        title = "NER Label",
        opacity = 1
      )
  })
}


shinyApp(ui, server)
