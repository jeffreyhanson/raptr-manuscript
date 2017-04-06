## load session
session::restore.session("data/intermediate/04-case-study-2.rda")
load("data/intermediate/03-case-study-1.rda")
load("data/intermediate/02-simulations.rda")
load("data/intermediate/05-benchmark-analysis.rda")

## case-study 2
# generate inverse distance matrix
cs2_pu_centroids <- cs2_grid_sub_polygons %>%
                    rgeos::gCentroid(byid = TRUE) %>%
                    sp::spTransform(sp::CRS("+init=epsg:4326"))
cs2_pu_inv_dists <- cs2_pu_centroids@coords %>%
                    fields::rdist.earth()
cs2_pu_inv_dists <- 1 / cs2_pu_inv_dists
diag(cs2_pu_inv_dists) <- 0

# calculate Morans I
cs1_nmds_morans_i <- plyr::llply(
  unique(cs2_spp_samples_sub_data$species),
  function(x) {
    curr_data <- cs2_grid_sub_data %>%
                 dplyr::select(dplyr::contains(paste0(x, "_genetic_d")))
    plyr::llply(seq_len(ncol(curr_data)), function(i) {
      curr_col <- curr_data[[i]]
      curr_pos <- which(!is.na(curr_data[[i]]))
      ape::Moran.I(curr_data[[i]][curr_pos],
                   cs2_pu_inv_dists[curr_pos, curr_pos], scale = TRUE)
    })
})

# calculate numbers and generate vectors for article
amount_represented_species_names <- cs1_spp_results %>%
  dplyr::filter(Prioritisation == "Amount targets",
                niche >= (cs1_parameters[["space_target"]] * 100)) %>%
  `[[`("Species")
amount_not_represented_species_names <- cs1_spp_results %>%
  dplyr::filter(Prioritisation == "Amount targets",
                niche < (cs1_parameters[["space_target"]] * 100)) %>%
  `[[`("Species")

if (length(amount_represented_species_names) > 1) {
  parsed_representative_space_held_names <- sapply(
    as.character(amount_represented_species_names),
    function(x) {
      paste0(tolower(x), " (",
             round(dplyr::filter(cs1_spp_results,
                                 Prioritisation == "Amount targets",
                                 Species == x)$niche, 2), " %)")
  })
  not_last <- parsed_representative_space_held_names[-length(
              parsed_representative_space_held_names)]
  parsed_representative_space_held_names <- paste0(paste(not_last,
    collapse = ", "), ", and the ",
    dplyr::last(parsed_representative_space_held_names))
} else {
  parsed_representative_space_held_names <- paste0(
    amount_represented_species_names, " (",
    round(filter(cs1_spp_results, Prioritisation == "Amount targets",
    Species == amount_represented_species_names)$niche, 2), " %)")
}

if (length(amount_not_represented_species_names) > 1) {
  parsed_not_representative_space_held_names <- sapply(
    as.character(amount_not_represented_species_names),
    function(x) {
      paste0(tolower(x), " (", round(filter(cs1_spp_results,
        Prioritisation == "Amount targets", Species == x)$niche, 2), " %)")
  })
  not_last <- parsed_not_representative_space_held_names[
    -length(parsed_not_representative_space_held_names)]
  parsed_not_representative_space_held_names <- paste0(paste(not_last,
     collapse=", "), ", and the ",
     dplyr::last(parsed_not_representative_space_held_names))
} else if (length(amount_not_represented_species_names) == 1) {
  parsed_not_representative_space_held_names <- paste0(
    amount_not_represented_species_names, "(", round(dplyr::filter(
      cs1_spp_results, Prioritisation == "Amount targets",
      Species == amount_not_represented_species_names)$niche, 2), " %)")
} else {
  parsed_not_representative_space_held_names <- c()
}

amount_represented_species_names  %<>% tolower()
amount_not_represented_species_names %<>% tolower()

## save session
session::save.session("data/intermediate/06-statistical-analysis.rda",
                      compress = "xz")
