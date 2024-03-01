#### MUSA Brownbag Lunch Demo: Map design in R ####
#### February 28, 2024
#### By: Anna Duan
#### Data: OpenDataPhilly.org

# In this tutorial, we will create a map of tree diameter at breast height 
#  in Philadelphia using the tree inventory data from the Philadelphia Parks 
#  and Recreation (PPR) Department. We will also overlay the map with the 
#  boundaries of Philadelphia, census tracts, and primary/secondary roads from 
#  the tigris package to create a simple & effective basemap.


#### Setup ####
# Packages
library(tidyverse)
library(tigris)
library(sf)
library(mapview)


#### Read tree inventory data ####
dat <- st_read("data/ppr_tree_inventory_2023.geojson") %>%
  st_transform("EPSG:2272") %>%
  st_make_valid()

#### Philly boundaries via tigris package ####
options(tigris_use_cache = TRUE) # set cache = TRUE to save time for future calls

phl_bound <- places(state = "PA", class = "city") %>% # city bounds
  filter(NAME == "Philadelphia") %>%
  st_transform("EPSG:2272") %>%
  erase_water()

phl_tract <- tracts(state = "PA", county = "Philadelphia") %>% # census tracts
  dplyr::select(GEOID) %>%
  st_transform("EPSG:2272") %>%
  st_make_valid() %>%
  erase_water(area_threshold = 0.8)

phl_roads <- primary_secondary_roads(state = "PA") %>% # primary/secondary roads
  st_transform("EPSG:2272") %>%
  st_union() %>%
  st_intersection(phl_bound) 

tract_nj <- tracts(year = 2020, state = "NJ") # NJ tracts
tract_pa <- tracts(year = 2020, state = "PA") # PA tracts

tract_bg <- rbind(tract_nj, tract_pa) %>% # Combine NJ and PA tracts
  st_transform("EPSG:2272") %>%
  st_make_valid() %>%
  st_crop(st_bbox(phl_bound)) %>%
  erase_water()

water_rect <- st_as_sfc(st_bbox(phl_bound), crs = "EPSG:2272")

#### Data manipulation ####
tract_dbh <- dat %>%
  filter(grepl("PLANETREE", tree_name)) %>%
  st_intersection(phl_tract,.) %>%
  mutate(count = 1) %>%
  group_by(GEOID) %>%
  summarize(tree_dbh = mean(tree_dbh, na.rm = TRUE),
            count = sum(count))%>%
  st_drop_geometry() %>%
  left_join(phl_tract, by = "GEOID") %>%
  st_as_sf() %>%
  mutate(area = as.numeric(word(st_area(.), 1)),
         area_sqmi = area / 27878400,
         tree_p_sqmi = round(count/area_sqmi))

#### Map #### 


ggplot() +
  geom_sf(data = water_rect, fill = "lightblue") +
  geom_sf(data = tract_bg, fill = "gray25", color = "gray35") +
  geom_sf(data = tract_dbh, aes(fill = tree_dbh/12, alpha = tree_p_sqmi), color = "transparent") +
  scale_alpha_continuous(name = "trees/sqmi", range = c(0.1, 1), breaks = c(250, 500, 750, 1000)) + # Explicitly set the legend title here
  guides(alpha = guide_legend(reverse = TRUE)) +
  scale_fill_distiller(name = "diameter (ft)", palette = "YlGn", direction = -1, na.value = "white") +
  annotate("text", x = 2695000, y = 297890, size = 8, family = "Avenir", label = "Where are Philly's Biggest Planetrees?", color = "Beige") +
  annotate("text", x = 2684000, y = 294000, size = 4, family = "Avenir", label = "2023 Philadelphia Tree Inventory; n = 16,693", color = "Beige") +
  theme_void() +
  theme(legend.position = c(0.85, 0.2),
        text = element_text(family = "Avenir", color = "beige"))
  
  
#### Histogram ####
dat %>%
  filter(tree_dbh < 80 & grepl("PLANETREE", tree_name)) %>%
  ggplot() +
  geom_histogram(aes(x = tree_dbh/12), binwidth = 0.2, fill = "lightgreen", color = "white", alpha = 0.6) +
 # theme_void() +
  theme(panel.background = element_rect(fill = "gray30"))


#### Challenge ####    
# Select a different tree species and apply one of the color schemes we discussed to tell another story about Philadelphia's trees.
# Export the map and plot as jpeg files and design a map layout featuring both of them in Canva, using custom fonts, colors, and graphics.
# 
