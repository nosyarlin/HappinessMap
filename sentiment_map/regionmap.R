library(tidyverse)
library(rgdal)
library(spatstat)
library(sf)
library(viridis)
library(plotly)

# read in files
#tweets <- read_csv("emoji_trunc.csv")
tweets <- read_csv("instagram_trunc.csv")
shape <- readOGR(dsn = 'sg-shape', layer ='sg-all')
kml <- st_read("planning_area.kml")

# convert to sf points and polygon
tweets <- drop_na(tweets)
tweets.sf <- st_as_sf(tweets, coords = c('lon','lat'), crs = 4326)

# points in polygon
join <- st_join(tweets.sf, kml, join = st_within)
join.df <- as.data.frame(join)
join.summary <- join.df %>% group_by(Name) %>% summarise(count = n(), pos = sum(pos), neg = sum(neg), neu = sum(neu)) 
join.summary <- join.summary %>% select('count', 'pos', 'neg', 'neu', 'Name') %>% drop_na()

kml.data <- merge(join.summary, kml, by = "Name") %>% st_as_sf()
kml.data <- st_as_sf(kml.data)
kml.data <- kml.data %>% mutate(norm = (pos-neg)/count)


p <- ggplot() +
  geom_sf(data = kml.data, aes(fill = cut((pos-neg)/count, c(0,0.25,0.4,0.415,0.43,0.46,0.5)), geometry = geometry, text = paste0(Name, "\n", "Sentiment: ", norm)), lwd = 0) + 
  theme_void() +
  coord_sf() +
  scale_fill_viridis(
    breaks=c(0,0.25,0.4,0.415,0.43,0.46),
    name="Normalized Sentiment",
    discrete = T,
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

p

  
#ggplotly(p, tooltip = "text") %>%
#  highlight(
#    "plotly_hover",
#    opacityDim = 1
#  )

#st_write(kml.data, "tweet_sentiment_pa.csv")

  
ggplotly(p, tooltip = "text") %>%
  highlight(
    "plotly_hover",
    opacityDim = 1
  )

st_write(kml.data, "tweet_sentiment_pa.csv")

