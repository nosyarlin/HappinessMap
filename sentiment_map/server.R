library(tidyverse)
library(plotly)
library(rgdal)
library(spatstat)
library(sf)
library(viridis)

function(input, output, session) {
  # read in files
  load("plots/sent_tweets")
  load("plots/sent_insta")

  # sent_insta <- mutate(sent_insta, sent=pos-neg)
  # sent_insta <- mutate(sent_insta, created_at=as.numeric(as.POSIXct(created_at)) * 1000)
  # sent_insta <- sent_insta[ , !(names(sent_insta) %in% c("X1"))]
  # save(sent_insta, file="sent_insta")
  
  # sent_tweets <- read_csv("emoji_trunc.csv")
  # sent_tweets <- drop_na(sent_tweets)
  # save(sent_tweets, file="sent_tweets")

  # sent_insta <- read_csv("instagram_trunc.csv")
  # sent_insta <- drop_na(sent_insta)
  # save(sent_insta, file="sent_insta")

  sg.st <- st_read("planning_area.kml")
  sg.sf <- st_as_sf(sg.st)

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
      as.vector(matrix(1, length(plotData$sent)))
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

  output$plotInteractive <- renderPlotly({
    plotData <- dateRange()
    p <- ggplot(data=plotData, aes(x=plotData$lon, y=plotData$lat, z=selectedData(), group=1), stat="identity") +
      stat_summary_hex(aes(text = paste0(input$sent, ": ", selectedData())),
        binwidth=binSize(), drop=TRUE, show.legend=T, fun=function(x) if(length(x) > minPosts()) {func()(x)} else {NA}) + coord_fixed() +
      scale_fill_viridis(name=input$sent) +
      labs(x="Longitude", y="Latitude") +
      scale_x_continuous(limits = c(103.6, 104)) + scale_y_continuous(limits = c(1.17, 1.48)) +
      theme(
        text = element_text(color = "#22211d"), 
        legend.position = c(0.7, 0.09),
        plot.background = element_rect(fill = "#FFFFFF", color = NA),
        panel.background = element_rect(fill = "#FFFFFF", color = NA),
        legend.background = element_rect(fill = "#FFFFFF", color = NA),
        panel.grid.major = element_line(colour = 'transparent'), 
        panel.grid.minor = element_line(colour = 'transparent')
      )

    # p

    ggplotly(p, tooltip = "text") %>%
     highlight(
       "plotly_hover",
       opacityDim = 1
     )
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
