#' Make target data using attribute spaces
#'
#' This function takes a set of species names and
#' attribute spaces and generates a table with targets.
#'
#' @param species \code{character} species names.
#'
#' @param genetic_space \code{AttributeSpace} object with genetic space data.
#'
#' @param amount_target \code{numeric} amount-based target
#'
#' @param genetic_target \code{numeric} genetic-based target
#'
#' @seealso \code{\link[raptr]{AttributeSpace}}.
#'
#' @export
make_targets <- function(species, genetic_spaces, amount_target = 0.2,
                          genetic_target = 0.2) {
  # amount targets
  amount_targets_data <- data.frame(species = seq_along(species),
                                    target = rep(0, length(species)),
                                    proportion = rep(amount_target,
                                                     length(species)),
                                    name = paste0("amount_", species))
  # genetic spaces
  genetic_targets_data <- plyr::ldply(seq_along(genetic.spaces), function(i) {
    # get species position
    spp_pos <- which(sapply(genetic_spaces[[i]]@demand.points,
                            function(y) length(y@weights)) > 2)
    # return data.frame
    spp_data <- data.frame(species = seq_along(species),
                           target = rep(i, length(species)),
                           proportion = replace(rep(NA_real_, length(species)),
                                              spp.pos, genetic.target),
                           name = replace(rep("null", length(species)),
                                        spp.pos,
                                        paste0("genetic_", species[spp.pos])))
  })
  # return targets
  amount_targets_data %>%
  rbind(genetic_targets_data) %>%
  dplyr::mutate(target = as.integer(target), species = as.integer(species))
}
