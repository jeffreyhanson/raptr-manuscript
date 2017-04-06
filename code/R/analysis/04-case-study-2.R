## load session
session::restore.session("data/intermediate/01-load-data.rda")

## load parameters
cs2_parameters <- RcppTOML::parseTOML("code/parameters/case-study-2.toml") %>%
                  `[[`(MODE)

### prepare genetic attribute-spaces
# subset to relevant species
cs2_parameters$species_name <- gsub(" ", "_", cs2_parameters$species_name,
                                    fixed = TRUE)
spp_pos <- which(unique(cs2_spp_samples_data$species) %in%
                 cs2_parameters$species_name)
cs2_spp_structure_data <- cs2_spp_structure_data[spp_pos]
cs2_spp_samples_data <- cs2_spp_samples_data[cs2_spp_samples_data$species %in%
                                             cs2_parameters$species_name, ]

# run mds
cs2_spp_nmds <- plyr::llply(seq_along(cs2_spp_structure_data), function(i) {
    # manually classify loci as neutral or adaptive
    curr_spp <- bayescanr::BayeScanData(
      cs2_spp_structure_data[[i]]@matrix,
      primers = cs2_spp_structure_data[[i]]@loci.names,
      populations = rep("1", nrow(cs2_spp_structure_data[[i]]@matrix)),
      labels = cs2_spp_structure_data[[i]]@sample.names)
    curr.nmds <- bayescanr::nmds(curr_spp, metric = "gower",
                                 max.stress = cs2_parameters$max_stress,
                                 min.k = cs2_parameters$min_k,
                                 max.k = cs2_parameters$max_k,
                                 trymax = cs2_parameters$trymax)
})

# store mds rotations for each sample
cs2_spp_samples_data <- plyr::ldply(
  seq_len(dplyr::n_distinct(cs2_spp_samples_data$species)),
  function(i) {
    cs2_spp_samples_data %>%
    dplyr::filter(species == unique(cs2_spp_samples_data$species)[i]) %>%
    cbind(magrittr::set_names(as.data.frame(cs2_spp_nmds[[i]]$points),
                              paste0("genetic_d",
                                     seq_len(cs2_spp_nmds[[i]]$ndim))))
})

# store nmds average rotation for each grid
for (i in seq_along(unique(cs2_spp_samples_data$species))) {
  curr_sub <- cs2_spp_samples_data %>%
              dplyr::filter(species == unique(cs2_spp_samples_data$species)[i])
  for (k in seq_len(cs2_spp_nmds[[i]]$ndim)) {
    curr_vals <- tapply(curr_sub[[paste0("genetic_d", k)]], curr_sub$cell,
                        FUN = mean)
    curr_pos <- match(names(curr_vals), cs2_grid_data$cell)
    curr_cols <- paste0(unique(cs2_spp_samples_data$species)[i], "_genetic_d",
                        k)
    cs2_grid_data[curr_pos, curr_cols] <- curr_vals
  }
}

# update grid.PLY with additional attributes
cs2_grid_polygons@data <- cs2_grid_data

# subset planning units occupied by species used in analysis
cells <- rowSums(cs2_grid_data[, c(cs2_parameters$species_name), drop = FALSE])
cells <- cs2_grid_data$cell[cells > 0]
cs2_spp_samples_sub_data <- cs2_spp_samples_data %>%
                            dplyr::filter(cell %in% cells)
cs2_grid_sub_data <- cs2_grid_data %>%
                     dplyr::filter(cell %in% cells)
cs2_grid_sub_polygons <- cs2_grid_polygons[cs2_grid_polygons$cell %in% cells, ]
cs2_grid_sub_polygons %<>% sp::spChFIDs(as.character(seq_len(nrow(
                           cs2_grid_sub_polygons@data))))

### prepare data
# generate attribute spaces for genetic data
cs2_genetic_attribute_spaces <- raptr::AttributeSpaces(
  name = "genetic",
  spaces = plyr::llply(
    seq_along(unique(cs2_spp_samples_sub_data$species)),
    function(i) {
      make_genetic_attribute_space(
        site_data = cs2_grid_sub_data %>%
                    dplyr::select(dplyr::contains(paste0(unique(
                      cs2_spp_samples_sub_data$species)[i], "_genetic"))),
        species_data = cs2_grid_sub_data %>%
                       dplyr::select(dplyr::contains(paste0(unique(
                       cs2_spp_samples_sub_data$species)[i], "_genetic"))) %>%
                       na.omit(),
        species = i)
  })
)

# make table with temporary targets
cs2_target_data <- data.frame(
  species = rep(seq_along(unique(cs2_spp_samples_sub_data$species)), 2),
  target = rep(0:1, each = dplyr::n_distinct(cs2_spp_samples_sub_data$species)),
  proportion = rep(c(0.2, 0.5),
                   each = dplyr::n_distinct(cs2_spp_samples_sub_data$species)),
  name = paste0(rep(c("amount_", "genetic_"),
                each = dplyr::n_distinct(cs2_spp_samples_sub_data$species)),
                rep(unique(cs2_spp_samples_sub_data$species), 2))
)

# extract costs
costs_matrix <- cs2_grid_sub_polygons %>%
                raster::rasterize(cs2_cost_raster, field = "id") %>%
                raster::zonal(x = cs2_cost_raster, fun = "sum")
costs_matrix[, 2] <- log(costs_matrix[, 2])

# make Rap objects
cs2_rd <- raptr::RapData(
  polygon = raptr::SpatialPolygons2PolySet(cs2_grid_sub_polygons),
  pu = data.frame(cost = costs_matrix[, 2], area = 1,
                  status = rep(0L, nrow(cs2_grid_sub_data))),
  species = data.frame(name = unique(cs2_spp_samples_sub_data$species)),
  target = cs2_target_data,
  attribute.spaces = list(cs2_genetic_attribute_spaces),
  pu.species.probabilities = plyr::ldply(
    seq_along(unique(cs2_spp_samples_sub_data$species)),
    function(i) {
      data.frame(
        species = i,
        pu = which(cs2_grid_sub_data[[unique(
             cs2_spp_samples_sub_data$species)[i]]] == 1),
        value = 1)
    }
  ),
  boundary = raptr::calcBoundaryData(cs2_grid_sub_polygons)
)

# create RapUnsolved without cost data
cs2_ru <- raptr::RapUnsolved(raptr::RapUnreliableOpts(), cs2_rd)

## configure options to show that gurobi is installed
options(GurobiInstalled = list(gurobi = TRUE, rgurobi = FALSE))

### generate prioritizations
cs2_prioritisations <- plyr::llply(list(
    list(cs2_parameters$amount_target, NA), list(cs2_parameters$amount_target,
         cs2_parameters$genetic_target)),
  function(y) {
    species_prioritisation(x = cs2_ru, amount_targets = y[[1]],
                           genetic_targets = y[[2]],
                           Threads = general_parameters$threads,
                           MIPGap = general_parameters$MIPGap,
                           NumberSolutions = 1L)
})

### generate results table
cs2_spp_results <- plyr::ldply(seq_along(cs2_prioritisations), function(i) {
    cs2_prioritisations[[i]] %>%
    extract_results() %>%
    dplyr::mutate(Prioritisation = c("Amount", "Genetic")[i],
                  amount.held = amount.held * 100,
                  genetic = genetic * 100)
})

## save workspace
session::save.session("data/intermediate/04-case-study-2.rda", compress = "xz")
