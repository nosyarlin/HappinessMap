library(tidyverse)
library(rgdal)
library(spatstat)
library(sf)
library(viridis)
library(plotly)

# read in files
tweets <- read_csv("emoji_trunc.csv")
filenames <- list.files("detail_polygons", pattern="*.kml", full.names=TRUE)
polygons <- lapply(filenames, st_read)

# combine polygon kml dfs into one df
polygons.df <- do.call("rbind", polygons)

# convert to sf points and polygon
tweets <- drop_na(tweets)
tweets.sf <- st_as_sf(tweets, coords = c('lon','lat'), crs = 4326)
polygons.sf <- st_as_sf(polygons.df, crs = 4326)

# points in polygon
join <- st_join(tweets.sf, polygons.sf, join = st_within)
join.df <- as.data.frame(join) %>% drop_na()
join.summary <- join.df %>% group_by(Name) %>% summarise(count = n(), pos = sum(pos), neg = sum(neg), neu = sum(neu)) 

# create column for housing type
join.summary <- join.summary %>% mutate(housing_type = str_extract(Name, regex("(?<= )[:alpha:]*$")))

# create normalized column
join.summary <- join.summary %>% mutate(norm = (pos-neg)/count)

# add geometry back
polygons.sf <- merge(polygons.sf, join.summary, by = "Name")
polygons.sf <- st_as_sf(polygons.sf, crs = 4326)

# create map
p <- ggplot(polygons.sf) +
  geom_sf(aes(fill = norm, text = paste0(Name, "\n", "Sentiment: ", norm)), lwd = 0) + 
  theme_void() +
  coord_sf() +
  scale_fill_viridis(
    breaks=c(0,0.25,0.4,0.415,0.43,0.46),
    name="Normalized Sentiment",
    guide=guide_legend(
      keyheight = unit(3, units = "mm"),
      keywidth=unit(12, units = "mm"),
      label.position = "bottom",
      title.position = 'top',
      nrow=1)) +
  labs(
    title = "Sentiments of Singaporeans Living in Different Housing Types",
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

ggplotly(p)

save(polygons.sf, file="richpoor.sent")
