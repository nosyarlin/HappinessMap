library(plotly)

navbarPage("Social Media Sentiment in Singapore",
  tabPanel("Interactive",
    sidebarLayout(
      sidebarPanel(
        selectInput('dataset', 'Data', c("Twitter", "Instagram"), selected="Twitter"),
        selectInput('sent', 'Data Type', c("Sentiment", "Positive", "Negative", "Count"), selected="Sentiment"),
        selectInput('func', 'Aggregate Method', c("Mean", "Sum"), selected="Mean"),
        numericInput('binSize', 'Hexagon Size', 0.02,
                     min = 0.01, max = 0.05),
        numericInput('minPosts', 'Minimum Posts Threshold', 100,
                     min = 0, max = 1000),
        width=3
      ),
      mainPanel(align="center",
        plotlyOutput('plotInteractive', width="100%", height="500px"),
        br(),
        uiOutput("sliderOutput", width="100%")
      )
    )
  ),
  tabPanel("Case Studies",
    includeHTML("case_studies.html")
  ),
  tabPanel("About",
    includeMarkdown("about.md")
  )
)
