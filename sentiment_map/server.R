library(tidyverse)
library(plotly)
library(rgdal)
library(spatstat)
library(sf)
library(viridis)

function(input, output, session) {
  # read in files
  sent_tweets <- read_csv("emoji_trunc.csv")
  sent_tweets <- drop_na(sent_tweets)

  sent_insta <- read_csv("instagram_trunc.csv")
  sent_insta <- drop_na(sent_insta)

  # Load tweet sentiment for planning area
  # reloaded <- st_read("plots/tweet_sentiment_pa.kml")
  # reloaded <- st_as_sf(reloaded)
  # reloaded$norm=as.numeric(levels(reloaded$norm))[reloaded$norm]

  # sg.st <- st_read("planning_area.kml")
  # sg.sf <- st_as_sf(sg.st)

  dataset <- reactive({
    if(input$dataset == "Twitter") {
      sent_tweets;
    }
    else {
      sent_insta;
    }
  })

  # Combine the selected variables into a new data frame
  selectedData <- reactive({
    plotData <- dateRange()
    if(input$sent == "Positive") {
      plotData$pos;
    }
    else if(input$sent == "Negative") {
      plotData$neg;
    }
    else if(input$sent == "Sentiment") {
      plotData$sent;
    }
    else if(input$sent == "Count") {
      matrix(1, length(plotData$sent))
    }
  })

  func <- reactive({
    if(input$func == "Sum") {
      sum;
    }
    else if(input$func == "Mean") {
      mean;
    }
  })

  binSize <- reactive({
    input$binSize;
  })

  minPosts <- reactive({
    input$minPosts;
  })

  dateRange <- reactive({
    returnData <- dataset()
    startDate <- as.numeric(as.POSIXct(input$dateRange[1])) * 1000
    endDate <- as.numeric(as.POSIXct(input$dateRange[2])) * 1000
    returnData[returnData$created_at > startDate & returnData$created_at < endDate,]
  })

  observeEvent(input$controller, {
    updateTabsetPanel(session, "inTabset",
      selected = paste0("panel", input$controller)
    )
  })

  output$plot1 <- renderPlotly({
    plotData <- dateRange()
    p <- ggplot() +
      # geom_sf(data=sg.sf) +
      stat_summary_hex(data=plotData, aes(x=plotData$lon, y=plotData$lat, z=selectedData(), group=1), binwidth=binSize(), drop=TRUE, fun=function(x) if(length(x) > minPosts()) {func()(x)} else {NA}) + coord_fixed() +
      scale_fill_viridis(
      guide=guide_legend(
        keyheight = unit(3, units = "mm"),
        keywidth=unit(12, units = "mm"),
        label.position = "bottom",
        title.position = 'top',
        nrow=1)) +
      scale_x_continuous(limits = c(103.6, 104)) + scale_y_continuous(limits = c(1.21, 1.49))

    ggplotly(p)
  })

  output$paPlots <- renderPlotly({
  })

  output$sliderOutput <- renderUI({
    returnData <- dataset()
    minMS <- arrange(returnData, created_at)[1,] %>% pull("created_at")
    maxMS <- arrange(returnData, desc(created_at))[1,] %>% pull("created_at")
    minDate = as.POSIXct(minMS/1000, origin="1970-01-01")
    maxDate = as.POSIXct(maxMS/1000, origin="1970-01-01")
    sliderInput("dateRange", "Date Range:",
      min = as.Date(minDate), max = as.Date(maxDate),
        value = c(as.Date(minDate), as.Date(maxDate)), step=1)
  })
}
