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
  minDate <- arrange(sent_tweets, created_at)[1,] %>% pull("created_at")
  maxDate <- arrange(sent_tweets, desc(created_at))[1,] %>% pull("created_at")

  # Load tweet sentiment for planning area
  reloaded <- st_read("tweet_sentiment_pa.csv")
  reloaded <- st_as_sf(reloaded)
  reloaded$norm=as.numeric(levels(reloaded$norm))[reloaded$norm]

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

  minTweets <- reactive({
    input$minTweets;
  })

  dateRange <- reactive({
    sent_tweets[sent_tweets$created_at > input$dateRange[1] & sent_tweets$created_at < input$dateRange[2],]
  })

  observeEvent(input$controller, {
    updateTabsetPanel(session, "inTabset",
      selected = paste0("panel", input$controller)
    )
  })

  output$plot1 <- renderPlotly({
    plotData <- dateRange()
    p <- ggplot(data=plotData, aes(x=plotData$lon, y=plotData$lat, z=selectedData(), group=1)) +
      stat_summary_hex(binwidth=binSize(), drop=TRUE, fun=function(x) if(length(x) > minTweets()) {func()(x)} else {NA}) + coord_fixed() +
      scale_fill_gradient(low="white", high="blue") +
      scale_x_continuous(limits = c(103.6, 104)) + scale_y_continuous(limits = c(1.21, 1.49))
  })

  output$paPlots <- renderPlotly({
    # Load Rayson's map
    tweet.sentiment.pa <- ggplot() +
      # Convert to Title Case and round norm to 4 decimal places
      geom_sf(data=reloaded, aes(fill=norm, geometry = geometry, text = paste0(gsub("([[:alpha:]])([[:alpha:]]+)", "\\U\\1\\L\\2", Name, perl=TRUE), "\n", "Sentiment: ", round(norm,4))), lwd = 0) + 
      theme_void() +
      coord_sf() +
      scale_fill_viridis(
        breaks=c(0,0.25,0.3,0.35,0.4,0.45),
        name="Normalized Sentiment",
        guide=guide_legend(
          keyheight = unit(3, units = "mm"),
          keywidth=unit(12, units = "mm"),
          label.position = "bottom",
          title.position = 'top',
          nrow=1)) +
      labs(
        title = "Sentiments of Singaporeans in Different Planning Zones",
        subtitle = "Normalized Sentiment score = (Positive - Negative)/Total Count",
        caption = "Data: Ate Poorthuis | Creation: Dragon Minions"
      ) +
      theme(
        text = element_text(color = "#22211d"), 
        plot.background = element_rect(fill = "#f5f5f2", color = NA), 
        panel.background = element_rect(fill = "#f5f5f2", color = NA), 
        legend.background = element_rect(fill = "#f5f5f2", color = NA),
        plot.title = element_text(size= 22, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.4, l = 2, unit = "cm")),
        plot.subtitle = element_text(size= 17, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.43, l = 2, unit = "cm")),
        plot.caption = element_text( size=12, color = "#4e4d47", margin = margin(b = 0.3, r=-99, unit = "cm") ),
        legend.position = c(0.7, 0.09),
        panel.grid.major = element_line(colour = 'transparent'), 
        panel.grid.minor = element_line(colour = 'transparent')
      )

    ggplotly(tweet.sentiment.pa, tooltip = "text")
  })

  output$sliderOutput <- renderUI({
    sliderInput("dateRange", "Date Range:",
      min = minDate, max = maxDate,
        value = c(minDate, maxDate))
  })
}
