library(tidyverse)
library(sp)
library(sf)
library(raster)
library(rgeos)
library(rgdal)
library(viridis)
library(gridExtra)
library(rasterVis)
require(spatialEco)
library(plotly)

set.seed(1)

# Retrieved with thanks from http://strimas.com/spatial/hexagonal-grids/
make_grid <- function(x, cell_diameter, cell_area, clip = FALSE) {
  if (missing(cell_diameter)) {
    if (missing(cell_area)) {
      stop("Must provide cell_diameter or cell_area")
    } else {
      cell_diameter <- sqrt(2 * cell_area / sqrt(3))
    }
  }
  ext <- as(extent(x) + cell_diameter, "SpatialPolygons")
  projection(ext) <- projection(x)
  # generate array of hexagon centers
  g <- spsample(ext, type = "hexagonal", cellsize = cell_diameter, 
                offset = c(0.5, 0.5))
  # convert center points to hexagons
  g <- HexPoints2SpatialPolygons(g, dx = cell_diameter)
  # clip to boundary of study area
  if (clip) {
    g <- gIntersection(g, x, byid = TRUE)
  } else {
    g <- g[x, ]
  }
  # clean up feature IDs
  row.names(g) <- as.character(1:length(g))
  return(g)
}

# read in files
tweets <- read_csv("emoji_trunc.csv")
insta <- read_csv("instagram_trunc.csv")
shape <- readOGR(dsn = 'sg-shape', layer ='sg-all')
shape <- gBuffer(shape, byid=TRUE, width=0) # clean up polygons

# convert to sp points and polygon
tweets <- drop_na(tweets)
# p <- SpatialPointsDataFrame(tweets, data.frame(id=1:728138))
tweets.sf <- st_as_sf(tweets, coords = c('lon','lat'), crs=4326)

insta <- drop_na(insta)
insta.sf <- st_as_sf(insta, coords=c('lon', 'lat'), crs=4326)

pa.kml <- st_read("planning_area.kml")
pa.sf <- st_as_sf(pa.kml, crs=4326)
pa.utm <- as(st_zm(pa.sf), "Spatial")
pa.utm <- gBuffer(pa.utm, byid=TRUE, width=0) # clean up polygons
shape_utm <- spTransform(shape, CRS(proj4string(shape)))
hex_grid <- make_grid(shape_utm, cell_area = 0.0001, clip = T)
hex.sf <- st_as_sf(hex_grid, crs=4326)
hex.sf <- tibble::rowid_to_column(hex.sf, "hexID")

# points in polygon
colnames(tweets.sf) <- c("t.neg", "t.neu", "t.pos", "t.created_at", "t.sent", "geometry")
colnames(insta.sf) <- c("i.created_at", "i.pos", "i.neu", "i.neg", "i.sent", "geometry")

t.join <- st_join(tweets.sf, hex.sf, join = st_within)
t.join.df <- as.data.frame(t.join)
t.join.summary <- t.join.df %>% group_by(hexID) %>% summarise(t.count = n(), t.pos = sum(t.pos), t.neg = sum(t.neg), t.neu = sum(t.neu)) 
i.join <- st_join(insta.sf, hex.sf, join = st_within)
i.join.df <- as.data.frame(i.join)
i.join.summary <- i.join.df %>% group_by(hexID) %>% summarise(i.count = n(), i.pos = sum(i.pos), i.neg = sum(i.neg), i.neu = sum(i.neu)) 

# Add default values for missing hexagons
for (i in hex.sf$hexID) {
  if (!(i %in% i.join.summary$hexID)) {
    i.join.summary <- rbind(i.join.summary, data.frame(i.count=1, i.pos=0, i.neg=0, i.neu=0, hexID=i))
  }
  if (!(i %in% t.join.summary$hexID)) {
    t.join.summary <- rbind(t.join.summary, data.frame(t.count=1, t.pos=0, t.neg=0, t.neu=0, hexID=i))
  }
}

join.summary <- merge(t.join.summary, i.join.summary, by="hexID")
#join.summary <- join.summary %>% select('t.count', 't.pos', 't.neg', 't.neu', 'i.count', 'i.pos', 'i.neg', 'i.neu', 'hexID') %>% drop_na()

kml.data <- merge(join.summary, hex.sf, by = "hexID") %>% st_as_sf()
kml.data <- st_as_sf(kml.data)
kml.data <- kml.data %>% mutate(t.norm = (t.pos-t.neg)/t.count, i.norm = (i.pos-i.neg)/i.count, odds=t.pos/i.pos)
kml.data[!is.finite(kml.data$odds),]$odds <- 0

# Plot a histogram of the odds
ggplot(kml.data) + geom_histogram(aes(x=odds), bins=30)

p <- ggplot() +
  geom_sf(data = kml.data, aes(fill=t.norm, geometry=geometry, text=paste0("Odds Ratio: ", odds)), lwd=0) + 
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
  # scale_fill_distiller(
  #   palette="Spectral",
  #   limits=c(0,2),
  #   breaks=c(0,0.3,0.6,1,1.5,2),
  #   na.value="grey",
  #   name="Normalized Sentiment",
  #   guide=guide_legend(
  #     keyheight = unit(3, units = "mm"),
  #     keywidth=unit(12, units = "mm"),
  #     label.position = "bottom",
  #     title.position = 'top',
  #     nrow=1)) +
  labs(
    title = "Social Media Sentiments in Singapore",
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

#p
ggplotly(p, tooltip = "text") %>%
  highlight(
    "plotly_hover",
    opacityDim = 1
  )

hex.sent <- st_as_sf(kml.data, coords = c("lon", "lat"), crs = 4326)
save(hex.sent, file="hex.sent")
#st_write(hex.sent, "plots/hex_sent.kml")
