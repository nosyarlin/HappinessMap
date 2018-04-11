library(tidyverse)
library(rgdal)
library(spatstat)
library(sf)
library(viridis)

# read in files
tweets <- read_csv("emoji_trunc.csv")
woodland_rich <- st_read("woodland_rich.kml")
woodland_condo <- st_read("woodlands_rich (condo).kml")
planning <- st_read("planning_area.kml")


# convert to sf points and polygon
tweets <- drop_na(tweets)
tweets.sf <- st_as_sf(tweets, coords = c('lon','lat'), crs = 4326)

# add area name
woodland_rich <- woodland_rich %>% mutate(Name = "rich")

# points in polygon
join <- st_join(tweets.sf, woodland_rich, join = st_within)
join.df <- as.data.frame(join) %>% drop_na()
join.summary <- join.df %>% group_by(Name) %>% summarise(count = n(), pos = sum(pos), neg = sum(neg), neu = sum(neu)) 
join.summary <- join.summary %>% select('count', 'pos', 'neg', 'neu', 'Name') %>% drop_na()