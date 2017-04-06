## load session
session::restore.session("data/intermediate/00-initialization.rda")

### load case-study 1 data
# load in record bbox
cs1_record_bbox <- "data/raw/record_bbox/record_bbox.shp" %>%
                    raster::shapefile() %>%
                    rgeos::writeWKT()

# load in environmental data
cs1_bioclim_raster <- raster::stack("data/raw/BioClim_variables/pca.tif")
cs1_pca_data <- "data/raw/BioClim_variables/pca.TXT" %>%
              read.table(skip = 94) %>%
              magrittr::set_names(c("Principle Component", "Eigen Value",
                                    "Variation explained (%)",
                                    "Accumulative variation explained (%)"))

### load case-study 2 data
## compile spatial grid data
# load in opportunity costs
cs2_cost_raster <- paste0("data/raw/GRUMP_V1_Population_Density/",
                          "grumpv1-popdensity.tif") %>%
                  raster::raster()

# load in species population numbers
cs2_spp_populations_data <- paste0("data/raw/Data_Meirmans_et_al_IntrabioDiv",
                                   "/NumberPopulations.csv") %>%
                            data.table::fread(data.table = FALSE)

# load grid cell centroids
cs2_grid_data <- "data/raw/Data_Meirmans_et_al_IntrabioDiv/README" %>%
                 data.table::fread(data.table = FALSE,
                                   skip = "cell\tLong\tLat") %>%
                 dplyr::rename(grid.longitude = Long, grid.latitude = Lat) %>%
                 dplyr::mutate(id = seq_along(grid.latitude))

# load in aflp data
cs2_spp_aflp_paths <- dir("data/raw/Data_Meirmans_et_al_IntrabioDiv",
                          "^.*AFLP\\.dat$", full.names = TRUE)

cs2_spp_structure_data <- plyr::llply(cs2_spp_aflp_paths,
                                      structurer::read.StructureData)

# compile species occurence data
# load in data
cs2_spp_loc_paths <- dir("data/raw/Data_Meirmans_et_al_IntrabioDiv",
                         "^.*locations\\.txt$", full.names = TRUE)

cs2_spp_samples_data <- plyr::ldply(seq_along(cs2_spp_loc_paths), function(i) {
  x <- cs2_spp_loc_paths[i] %>%
       data.table::fread(data.table = FALSE) %>%
       dplyr::mutate(species = gsub("_locations.txt", "",
                     basename(cs2_spp_loc_paths[i]), fixed = TRUE)) %>%
       dplyr::rename(cell = population, sample.longitude = longitude,
                     sample.latitude = latitude)
  return(x[as.numeric(cs2_spp_structure_data[[i]]@sample.names), ])
})
cs2_spp_samples_data %<>% dplyr::left_join(cs2_grid_data, by = "cell")

# remove individuals that are all NAs
for (i in seq_along(cs2_spp_structure_data)) {
  # find individuals that are all NAs
  curr_invalid <- which(rowSums(is.na(cs2_spp_structure_data[[i]]@matrix)) ==
                        ncol(cs2_spp_structure_data[[i]]@matrix))
  # if any invalid then remove from objects
  if (length(curr_invalid) > 0) {
    # get valid individuals
    curr_valid <- which(rowSums(is.na(cs2_spp_structure_data[[i]]@matrix)) !=
                        ncol(cs2_spp_structure_data[[i]]@matrix))
    # remove from invalid individuals
    cs2_spp_structure_data[[i]] <- cs2_spp_structure_data[[i]] %>%
      structurer:::sample.subset.StructureData(curr_valid)
    curr_rows <- which(cs2_spp_samples_data$species ==
                       unique(cs2_spp_samples_data$species)[i])
    cs2_spp_samples_data <- cs2_spp_samples_data[-curr_rows[curr_invalid], ]
  }
}

# append species data to grid data.frame (wide-format)
for (i in unique(cs2_spp_samples_data$species))
  cs2_grid_data[[i]] <- replace(rep(0, nrow(cs2_grid_data)),
                                which(cs2_grid_data$cell %in%
                                      dplyr::filter(cs2_spp_samples_data,
                                                    species == i)$cell),
                                1)

# omit grids not occupied by any individuals
cs2_grid_abundances <- rowSums(cs2_grid_data[, c(-1, -2, -3, -4), drop = FALSE])
cs2_grid_data <- cs2_grid_data[cs2_grid_abundances > 0, ]
cs2_spp_samples_data$id <- match(cs2_spp_samples_data$id, cs2_grid_data$id)
cs2_grid_data$id <- seq_len(nrow(cs2_grid_data))
rownames(cs2_grid_data) <- as.character(seq_len(nrow(cs2_grid_data)))

# create Spatial* objects
cs2_grid_points <- sp::SpatialPoints(as.matrix(cs2_grid_data[, 2:3]))
cs2_grid_polygons <- cs2_grid_points %>%
    sp::points2grid(tolerance = 0.05) %>%
    as("SpatialPolygons")

cs2_grid_polygons <- cs2_grid_polygons[cs2_grid_points %>%
                                       rgeos::gIntersects(cs2_grid_polygons,
                                                          returnDense = FALSE,
                                                          byid = TRUE) %>%
                                        sapply(`[[`, 1), ] %>%
                     sp::spChFIDs(as.character(seq_len(
                       nrow(cs2_grid_data)))) %>%
                     sp::SpatialPolygonsDataFrame(data = cs2_grid_data)
cs2_grid_polygons@proj4string <- wgs1984

## save session
session::save.session("data/intermediate/01-load-data.rda", compress = "xz")
