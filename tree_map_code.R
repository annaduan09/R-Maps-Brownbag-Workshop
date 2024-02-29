#### MUSA Brownbag Lunch Demo: Map design in R ####
#### February 28, 2024
#### By: Anna Duan
#### Data: OpenDataPhilly.org

# In this tutorial, we will create a map of tree diameter at breast height 
#  in Philadelphia using the tree inventory data from the Philadelphia Parks 
#  and Recreation (PPR) Department. We will also overlay the map with the 
#  boundaries of Philadelphia, census tracts, and primary/secondary roads from 
#  the tigris package to create a simple yet effective basemap.


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

#### Data manipulation ####
tract_dbh <- dat %>%
  filter(grepl("PLANETREE", tree_name)) %>%
  st_intersection(phl_tract,.) %>%
  group_by(GEOID) %>%
  summarize(tree_dbh = mean(tree_dbh, na.rm = TRUE))%>%
  st_drop_geometry() %>%
  left_join(phl_tract, by = "GEOID") %>%
  st_as_sf()

#### Map #### 
water_rect <- st_as_sfc(st_bbox(phl_bound), crs = "EPSG:2272")

ggplot() +
  geom_sf(data = water_rect, fill = "lightblue") +
  geom_sf(data = tract_bg, fill = "gray90", color = "gray80") +
  geom_sf(data = tract_dbh, aes(fill = tree_dbh), color = "transparent") +
  scale_fill_viridis_c(option = "plasma", name = "dbh (in)", labels = scales::comma, direction = -1) +
  labs(title = "Where are Philly's Biggest Planetrees?", subtitle = "2023 Philadelphia Tree Inventory; n = 16,693", fill = "dbh (in)") +
  theme_void() +
  theme(legend.position = c(0.8, 0.2))
  
  
#### Histogram ####
dat %>%
  filter(tree_dbh < 80 & grepl("PLANETREE", tree_name)) %>%
  ggplot() +
  geom_histogram(aes(x = tree_dbh/12), binwidth = 0.2, fill = "lightblue", color = "transparent") +
  labs(title = "Planetree Diameter at Breast Height (dbh) Distribution", subtitle = "Philadelphia Tree Inventory 2023", x = "dbh (ft)", y = "trees") +
  theme_minimal()


#### Challenge ####    
# Export the map and plot as jpeg files and design a map layout featuring both of them in Canva. 
# Select a different tree species and use custom fonts, colors, and graphics to make it your own.
