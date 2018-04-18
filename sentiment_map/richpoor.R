```{r, echo=FALSE, warning=FALSE, message=FALSE}

rounded <- polygons.sf$norm %>% 
  unique() 
rounded <- rounded[order(rounded)]
rounded <- round(rounded, 3)

tampines <- get_map("Singapore-Tampines", zoom = 14, maptype = "toner-lines")

p <- ggmap(tampines) +
  geom_sf(data = polygons.sf,
          aes(fill = factor(norm), text = paste0(Name, "\n", "Sentiment: ", round(norm,2))),
          lwd = 0, 
          alpha = 0.8,
          inherit.aes = FALSE) + 
  theme_void() +
  coord_sf() +
  scale_fill_viridis(
    discrete = T,
    name="Normalized Sentiment",
    labels = rounded,
    guide=guide_legend(
      keyheight = unit(4, units = "mm"),
      keywidth=unit(8, units = "mm"),
      label.position = "right",
      title.position = 'top',
      alpha = 1)) +
  labs(
    title = "Sentiments of Singaporeans Living Near Tampines",
    subtitle = "Normalized Sentiment score = (Positive - Negative)/Total Count",
    caption = "Data: Ate Poorthuis | Creation: Dragon Minions"
  ) +
  theme(
    text = element_text(color = "#22211d"),
    plot.background = element_rect(fill = "#ffffff", color = NA),
    panel.background = element_rect(fill = "#ffffff", color = NA),
    legend.background = element_rect(fill = "#ffffff", color = NA),
    plot.title = element_text(size= 16, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.4, l = 2, unit = "cm")),
    panel.grid.major = element_line(colour = 'transparent'),
    panel.grid.minor = element_line(colour = 'transparent')
  ) 

#p

l <- list(
  font = list(
    family = "sans-serif",
    size = 12,
    color = "#000"),
  x = 0.7,
  y = 0,
  bgcolor = "transparent",
  bordercolor = "#FFFFFF",
  orientation = 'h',
  borderwidth = 0)

ggplotly(p, tooltip = "text") %>%
  highlight(
    "plotly_hover",
    opacityDim = 1
  ) %>%
  layout(legend = l)
```

From this map, we can see that people living in landed properties are generally the happiest, followed by condo owners, and finally HDB flat owners. This could be a good indication of the correlation between wealth and happiness. People living in private estates represent wealthier families and are actually happier than less well-off Singaporeans. However, the sample size is relatively small. While the data is interesting and supports the intuitive correlation between wealth and happiness, more investigation is needed. This is a good starting point in opening up a thesis for social research on wealth and happiness nonetheless.
