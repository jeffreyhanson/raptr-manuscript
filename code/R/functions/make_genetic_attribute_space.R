#' Make AttributeSpace using genetic data
#'
#' This function creates an \code{AttributeSpace} object with for a single species.
#'
#' @param site_data \code{data.frame} with coordinates for planning units.
#'
#' @param species_data \code{data.frame} with coordinates of demand points for the species.
#'
#' @return \code{AttributeSpace}.
#'
#' @seealso \code{\link[raptr]{AttributeSpace}}.
#'
#' @export
make_genetic_attribute_space <- function(site_data, species_data, species) {
  # extract ids of pus where the species is found
  curr_ids <- which(rowSums(is.na(site_data)) == 0)
  # return attribute space
  raptr::AttributeSpace(
    planning.unit.points = raptr::PlanningUnitPoints(
      coords = as.matrix(site_data[curr_ids, , drop = FALSE]),
      ids = curr_ids),
    demand.points = raptr::DemandPoints(coords = as.matrix(species_data),
                                        weights = rep(1, nrow(species_data))),
    species = as.integer(species)
  )
}
