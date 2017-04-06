#' Simulate data
#'
#' Simulate spatially auto-correlated data using random fields.
#'
#' @param x \code{\link[raster]{RasterLayer-class}} object to use as
#    a template.
#'
#' @param n \code{integer} number of species to simulate.
#'
#' @param model \code{\link[RandomFields]{RP}} model object
#'   to use for simulating data.
#'
#' @param transform \code{function} to transform values output
#'   from the random fields simulation.
#'
#' @param ... additional arguments passed to
#'   \code{\link[RandomFields]{RFsimulate}}.
#'
#' @return \code{\link[raster]{RasterStack-class}} object with a
#'   layer for each species.
#'
#' @seealso \code{\link[RandomFields]{RFsimulate}},
#'   \code{\link{simulate_cost}}, \code{\link{simulate_species}}.
#'
simulate_data <- function(x, n, model, transform=identity, ...) {
  # assert valid arguments
  if (!"RandomFields" %in% rownames(installed.packages()))
    stop("the \"RandomFields\" package needs to be installed to simulate data")
  assertthat::assert_that(
    inherits(x, "RasterLayer"),
    assertthat::is.number(n),
    is.finite(raster::cellStats(x, "max")),
    inherits(model, "RMmodel"),
    inherits(transform, "function"))
  # generate values for rasters
  coords <- as(x, "SpatialPoints")@coords
  mtx <- RandomFields::RFsimulate(model = model, x = coords[, 1],
                                  y = coords[, 2], n = n, spConform = FALSE,
                                  ...)
  # convert to matrix if not a matrix
  if (!inherits(mtx, "matrix"))
    mtx <- matrix(mtx, ncol = 1)
  # generate populate rasters with values
  stk <- raster::stack(lapply(seq_len(ncol(mtx)), function(i) {
    r <- x
    r[raster::Which(!is.na(r))] <- transform(mtx[, i])
    r
  }))
  # return raster stack with simulated distributions
  return(stk)
}

#' Simulate species habitat suitabilities
#'
#' Generates a random set of species using random field models. By default,
#' the output will contain values between zero and one.
#'
#' @inheritParams simulate_data
#'
#' @return \code{\link[raster]{RasterStack-class}} object.
#'
#' @seealso \code{\link{simulate_data}}.
#'
simulate_species <- function(x, n = 1, model = RandomFields::RMgauss(),
                             transform=plogis, ...) {
  simulate_data(x = x, n = n, model = model, transform = transform, ...)
}

#' Simulate problem data
#'
#' Simulates data for a conservation planning problem.
#'
#' @param number.planning.units \code{integer} number of planning units in
#'   problem.
#'
#' @param number.features \code{integer} number of features in problem.
#'
#' @param probability.of.occupancy \code{numeric} probability that features
#'   occupancy planning units.
#'
#' @param amount_target \code{numeric} target for capturing an adequate sample
#'   of the features.
#'
#' @param space_target \code{numeric} target for capturing a representative
#'   sample of the features.
#'
#' @return \code{RapData}.
simulate_problem_data <- function(number_planning_units, number_features,
                                  probability_of_occupancy,
                                  amount_target = 0.2, space_target = 0.8) {
  # simulate landscape
  curr_landscape <- raster::raster(
    ncol = ceiling(sqrt(number_planning_units)),
    nrow = ceiling(sqrt(number_planning_units))) %>%
    raster::setValues(1)
  raster::extent(curr_landscape) <- c(0, 1, 0, 1)

  # simulate species
  curr_spp <- simulate_species(curr_landscape, n = number_features,
                               transform = identity,
                               model = RandomFields::RPbernoulli(
                                 RandomFields::RMgauss()))

  # change extents so that polygon boundarys are not too small
  raster::extent(curr_landscape) <- c(0, ceiling(sqrt(number_planning_units)),
                                      0, ceiling(sqrt(number_planning_units)))
  raster::extent(curr_spp) <- raster::extent(curr_landscape)

  # simulate pus
  curr_pus <- raster::rasterToPolygons(curr_landscape, n = 4)
  curr_pus <- curr_pus[seq_len(number_planning_units), ]

  # find out which species are in which pus
  pu_pts <- rgeos::gCentroid(curr_pus, byid = TRUE)
  mtx <- raster::extract(curr_spp, pu_pts)
  mtx[which(mtx > 0)] <- probability_of_occupancy
  # if a species is not found in a single pu, then assign it to two pus
  for (j in which(apply(mtx, 2, sum) < 2)) {
    mtx[sample.int(nrow(mtx), size = 2), j] <- probability_of_occupancy
  }

  # create AttributeSpace object
  curr_attr_spaces <- raptr::AttributeSpaces(
    lapply(seq_len(nlayers(curr_spp)), function(j) {
      raptr::AttributeSpace(
        planning.unit.points = raptr::PlanningUnitPoints(
          pu_pts@coords[mtx[, j] > 0, , drop = FALSE],
          ids = which(mtx[, j] > 0)),
        demand.points = raptr::DemandPoints(
          pu_pts@coords[mtx[, j] > 0, , drop = FALSE],
          rep(1, length(which(mtx[, j] > 0)))),
        species = as.integer(j))
    }),
    name = "geographic")

  # create data.frame with species and space targets
  curr_targets <- data.frame(species = seq_len(nlayers(curr_spp)),
                             target = 0L, proportion = amount_target) %>%
                  rbind(data.frame(species = seq_len(nlayers(curr_spp)),
                                   target = 1L, proportion = space_target))

  # calculate probability of each species in each pu
  curr_pu_occurrences <- data.frame(species = rep(seq_len(nlayers(curr_spp)),
                                                  each = nrow(curr_pus)),
                                    pu = rep(seq_len(nrow(curr_pus)),
                                             nlayers(curr_spp)),
                                    value = c(mtx))
  curr_pu_occurrences <- curr_pu_occurrences[curr_pu_occurrences[[3]] > 0, ]

  # compile data object
  raptr::RapData(data.frame(cost = rep(1, nrow(curr_pus)),
                                      area = rep(1, nrow(curr_pus)),
                                      status = rep(0L, nrow(curr_pus))),
                 data.frame(name = names(curr_spp)),
                 curr_targets,
                 curr_pu_occurrences,
                 list(curr_attr_spaces),
                 raptr::calcBoundaryData(curr_pus),
                 raptr::SpatialPolygons2PolySet(curr_pus))
}
