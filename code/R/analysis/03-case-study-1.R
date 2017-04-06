## load session
session::restore.session("data/intermediate/01-load-data.rda")

## load parameters
cs1_parameters <- RcppTOML::parseTOML("code/parameters/case-study-1.toml") %>%
                  `[[`(MODE)

### Prepare data for prioritizations
## prepare pca layers
# select layers
cs1_bioclim_raster <- cs1_bioclim_raster[[cs1_parameters$number_pc_layers %>%
                                          seq_len()]]

# aggregate env layer to reduce computational burden
cs1_bioclim_raster %<>% raster::aggregate(
  cs1_parameters$environmental_layer_resolution / 1000)

## make planning units
# download queensland layer
aus_polygons <- raster::getData("GADM", country = "AUS", level = 1,
                                path = "data/intermediate") %>%
                                sp::spTransform(cs1_bioclim_raster@crs)
qld_polygons <- aus_polygons[aus_polygons$HASC_1 == "AU.QL", ]  %>%
                rgeos::gSimplify(1000)
aus_polygons %<>% rgeos::gSimplify(1000)

# create planning units over queensland
cs1_pus <- qld_polygons %>%
           raptr::blank.raster(cs1_parameters$pu_size) %>%
           raster::rasterToPolygons()
cs1_pus@data$id <- seq_len(nrow(cs1_pus@data))
cs1_pus@proj4string <- cs1_bioclim_raster@crs

# omit planning units that doesn't overlap with non-NA values in worldclim
# raster
values_matrix <- parallel_extract(x = cs1_bioclim_raster, y = cs1_pus,
                               threads = general_parameters$threads,
                               fun = mean)
values_matrix <- cbind(matrix(seq_len(nrow(cs1_pus@data)), ncol = 1),
                       values_matrix)
cs1_pus <- cs1_pus[which(rowSums(!is.finite(values_matrix[, -1])) == 0), ]
values_matrix <- values_matrix[cs1_pus$id, ]
cs1_pus@data$id <- seq_len(nrow(cs1_pus@data))
cs1_pus <- sp::spChFIDs(cs1_pus, as.character(seq_len(nrow(cs1_pus@data))))

# clip planning units to coastline
cs1_pus <- rgeos::gIntersection(cs1_pus, qld_polygons, byid = TRUE)
cs1_pus <- sp::SpatialPolygonsDataFrame(cs1_pus,
    data = data.frame(id = seq_along(cs1_pus@polygons),
                      area = rgeos::gArea(cs1_pus, byid = TRUE) / 100000,
                      cost = 1, status = 0L))
cs1_pus <- cs1_pus[cs1_pus$area > (max(cs1_pus$area) * 0.5), ]
cs1_pus@data$id <- seq_len(nrow(cs1_pus@data))
cs1_pus <- sp::spChFIDs(cs1_pus, as.character(seq_len(nrow(cs1_pus@data))))

## generate species range maps
# download species records
dir.create("data/intermediate/ala_cache", showWarnings = FALSE)
ALA4R::ala_config(cache_directory = "data/intermediate/ala_cache",
                  download_reason_id = 4)
cs1_records <- plyr::llply(cs1_parameters$species_names, ALA4R::occurrences,
                               wkt = cs1_record_bbox, use_data_table = TRUE)

# subset and combine records
cs1_subset_records <- plyr::llply(cs1_records, function(x) {
  # extract valid records
  x <- dplyr::filter(x$data, inferredDuplicateRecord == FALSE,
                    coordinateUncertaintyInMetres <= 10000,
                    is.finite(longitude), is.finite(latitude))
  if ("speciesOutsideExpertRange" %in% names(x))
    x <- dplyr::filter(x, speciesOutsideExpertRange == FALSE)
  if ("habitatMismatch" %in% names(x))
    x <- dplyr::filter(x, habitatMismatch == FALSE)
  # subset to first n records (used for debugging parameters)
  if (nrow(x) > cs1_parameters$max_records)
    x <- x[seq_len(cs1_parameters$max_records), ]
  # return subsetted data
  return(x)
})

# rarefy records
cs1_rarefied_records <- plyr::llply(cs1_subset_records, function(x) {
  sp::SpatialPoints(coords = as.matrix(x[,c("longitude", "latitude")]),
                   proj4string = sp::CRS("+init=epsg:4326")) %>%
  sp::spTransform(qld_polygons@proj4string) %>%
  spThin::spRarefy(grid = as.numeric(cs1_parameters$rarefy_cell_size), nrep = 1)
})

# thin records
cs1_thinned_records <- plyr::llply(cs1_rarefied_records, function(x) {
  spThin::spThin(sp::spTransform(x[[1]], sp::CRS("+init=epsg:4326")),
                 method = "gurobi",
                 great.circle.distance = TRUE,
                 dist = cs1_parameters$thin_distance,
                 Presolve = 2,
                 Threads = general_parameters$threads,
                 MIPGap = general_parameters$MIPGap)
})

# generate mcps
cs1_spp_mcp <- plyr::llply(cs1_thinned_records, function(x) {
  adehabitatHR::mcp(x[[1]], percent = cs1_parameters$mcp_percent)
})

# convert to rasters
cs1_spp_raster <- plyr::llply(cs1_spp_mcp, function(x) {
  x %>% sp::spTransform(cs1_bioclim_raster@crs) %>%
        raster::rasterize(y = cs1_bioclim_raster[[1]]) %>%
        raster::mask(mask = cs1_bioclim_raster[[1]])
})
cs1_spp_raster %<>% raster::stack()
names(cs1_spp_raster) <- cs1_parameters$common_names

## create RapUnsolved object
# create template RapUnsolved with dummy attribute space data
cs1_ru <- raptr::rap(pus = cs1_pus, species = cs1_spp_raster,
                     spaces = list(cs1_bioclim_raster),
                     kernel.method = "hypervolume",
                     amount.target = cs1_parameters$amount_target,
                     space.target = cs1_parameters$space_target,
                     solve = FALSE, quantile = 0.95, n.demand.points = 20,
                     n.species.points = rep(20,
                                            raster::nlayers(cs1_spp_raster)),
                     Threads = general_parameters$threads,
                     MIPGap = general_parameters$MIPGap,
                     NumberSolutions = 1,
                     include.geographic.space = FALSE)
cs1_ru@data@species[[1]] <- cs1_parameters$common_names

# create new attribute spaces
cs1_spaces <- plyr::llply(seq_along(cs1_parameters$common_names), function(i) {
  ## extract coordinates of planning units in environmental space
  curr_ids <- cs1_ru@data@attribute.spaces[[1]]@spaces[[i]]
  curr_ids <- curr_ids@planning.unit.points@ids
  curr_pu_coords <- values_matrix[curr_ids, -1, drop = FALSE]
  # z-score coordinates
  curr_pu_coords_mean <- apply(curr_pu_coords, 2, mean)
  curr_pu_coords_sd <- apply(curr_pu_coords, 2, sd)
  curr_pu_coords <- sweep(curr_pu_coords, MARGIN = 2, FUN = "-",
                          curr_pu_coords_mean)
  curr_pu_coords <- sweep(curr_pu_coords, MARGIN = 2, FUN = "/",
                          curr_pu_coords_sd)
  ## extract coordinates in environmental space
  curr_species_geo_points <- sp::SpatialPoints(
    coords = dismo::randomPoints(cs1_spp_raster[[i]], n = 200),
    proj4string = cs1_spp_raster[[i]]@crs)
  curr_species_env_points <- raster::extract(cs1_bioclim_raster,
    curr_species_geo_points)
  # put environmental coordinates on same scale as planning units
  curr_species_env_points <- sweep(curr_species_env_points, MARGIN = 2,
                                   FUN = "-", curr_pu_coords_mean)
  curr_species_env_points <- sweep(curr_species_env_points, MARGIN = 2,
                                   FUN = "/", curr_pu_coords_sd)
  # omit outlying coordinates
  curr_species_env_points_sp <- sp::SpatialPoints(curr_species_env_points)
  curr_species_env_points_mcp <- adehabitatHR::mcp(curr_species_env_points_sp,
                                   percent = cs1_parameters$mcp_percent)
  intersecting_pos <- rgeos::gIntersects(curr_species_env_points_sp,
                                         curr_species_env_points_mcp,
                                         byid = TRUE)[1, ]
  curr_species_env_points <- curr_species_env_points[intersecting_pos, ]

  # generate demand points
  curr_species_demand_points <- raptr::make.DemandPoints(
    curr_species_env_points,  n = cs1_parameters$dp_number,
    quantile = cs1_parameters$dp_quantile, kernel.method = "hypervolume",
    bandwidth = cs1_parameters$dp_bandwidth)

  ## assemble attribute space
  raptr::AttributeSpace(
    planning.unit.points = raptr::PlanningUnitPoints(coords = curr_pu_coords,
                                                     ids = curr_ids),
    demand.points = curr_species_demand_points, species = i)
})
cs1_ru@data@attribute.spaces <- list(raptr::AttributeSpaces(space = cs1_spaces,
                                                            name = "niche"))

# check that modifications are acceptable
validObject(cs1_ru, test = FALSE)

## configure options to show that gurobi is installed
options(GurobiInstalled = list(gurobi = TRUE, rgurobi = FALSE))

## make prioritizations
cs1_prioritisations <- plyr::llply(list(
  "Amount targets" = list(cs1_parameters$amount.target, NA),
  "Amount & niche targets" = list(cs1_parameters$amount.target,
                                  cs1_parameters$space.target)),
  function(y) {
    raptr::update(cs1_ru, amount.target = y[[1]], space.target = y[[2]],
                  Threads = general_parameters$threads, solve = TRUE,
                  MIPGap = general_parameters$MIPGap)
  }
)
names(cs1_prioritisations) <- c("Amount targets", "Amount & niche targets")

## extract results
cs1_spp_results <- plyr::ldply(seq_along(cs1_prioritisations), function(i) {
  cs1_prioritisations[[i]] %>%
  extract_results() %>%
  dplyr::mutate(Prioritisation = names(cs1_prioritisations)[i],
                amount.held = amount.held * 100,
                niche = niche * 100)
})

## save session
session::save.session("data/intermediate/03-case-study-1.rda", compress = "xz")
