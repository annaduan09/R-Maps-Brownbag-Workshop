#### Setup ####
# Packages
library(tidyverse)
library(tigris)
library(sf)
library(mapview)


#### Read tree inventory data ####
dat <- st_read("data/ppr_tree_inventory_2023.geojson") %>%
  st_transform("EPSG:2272")

#### Philly boundaries via tigris package ####
options(tigris_use_cache = TRUE) # set cache = TRUE to save time for future calls

phl_bound <- places(state = "PA", class = "city") %>% # city bounds
  filter(NAME == "Philadelphia") %>%
  st_transform("EPSG:2272")

phl_tract <- tracts(state = "PA", county = "Philadelphia") %>% # census tracts
  erase_water(area_threshold = 0.8) %>%
  dplyr::select(GEOID) %>%
  st_transform("EPSG:2272")

phl_roads <- primary_secondary_roads(state = "PA") %>% # primary/secondary roads
  st_transform("EPSG:2272") %>%
  st_union() %>%
  st_intersection(phl_bound) 
  

#### Data manipulation ####
tract_dbh <- dat %>%
  st_intersection(phl_tract) %>%
  group_by(GEOID) %>%
  summarize(tree_dbh = mean(dbh, na.rm = TRUE)) %>%

#### Map #### 
ggplot() +
  geom_sf(data = tract_dbh, aes(fill = tree_dbh), color = "transparent") +
  scale_fill_viridis_c(option = "plasma", name = "dbh (in)", labels = scales::comma) +
  theme_void()
  
  
#### Histogram ####
dat %>%
  filter(tree_dbh < 80) %>%
  ggplot() +
  geom_histogram(aes(x = tree_dbh/12), binwidth = 0.2, fill = "lightblue", color = "transparent") +
  labs(title = "Tree Diameter at Breast Height (dbh) Distribution", subtitle = "Philadelphia Tree Inventory 2023", x = "dbh (ft)", y = "trees") +
  theme_minimal()
