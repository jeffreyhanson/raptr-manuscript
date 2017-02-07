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
  if (!'RandomFields' %in% rownames(installed.packages()))
    stop('the "RandomFields" package needs to be installed to simulate data')
  assertthat::assert_that(
    inherits(x, 'RasterLayer'),
    assertthat::is.number(n),
    is.finite(raster::cellStats(x, 'max')),
    inherits(model, 'RMmodel'),
    inherits(transform, 'function'))
  # generate values for rasters
  coords <- as(x, 'SpatialPoints')@coords
  mtx <- RandomFields::RFsimulate(model=model, x=coords[,1], y=coords[,2],
                                  n=n, spConform=FALSE, ...)
  # convert to matrix if not a matrix
  if (!inherits(mtx, 'matrix'))
    mtx <- matrix(mtx, ncol=1)
  # generate populate rasters with values
  stk <- raster::stack(lapply(seq_len(ncol(mtx)), function(i) {
    r <- x
    r[raster::Which(!is.na(r))] <- transform(mtx[,i])
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
simulate_species <- function(x, n=1, model=RandomFields::RMgauss(),
                             transform=plogis, ...) {
  simulate_data(x=x, n=n, model=model, transform=transform, ...)
}

#' Simulate problem data
#'
#' Simulates data for a conservation planning problem. 
#'
#' @param number.planning.units \code{integer} number of planning units in problem.
#' @param number.features \code{integer} number of features in problem.
#' @param probability.of.occupancy \code{numeric} probability that features occupancy planning units.
#' @param amount.taget \code{numeric} target for capturing an adequate sample of the features.
#' @param space.taget \code{numeric} target for capturing a representative sample of the features.
#'
#' @return \code{RapData}.
simulate.problem.data <- function(number.planning.units, number.features, probability.of.occupancy,
                                  amount.target=0.2, space.target=0.8) {
  # simulate planning units
  curr.landscape <- raster::raster(ncol=ceiling(sqrt(number.planning.units)), nrow=ceiling(sqrt(number.planning.units))) %>%
    setValues(1) %>%  `extent<-`(c(0,1,0,1))
  curr.pus <- rasterToPolygons(curr.landscape, n=4)
  curr.pus <- curr.pus[seq_len(number.planning.units),]
  
  # simulate species
  curr.spp <- simulate_species(curr.landscape, n=number.features, 
                model=RPbernoulli(RMgauss()), transform=identity)

  # find out which species are in which pus
  pu.pts <- gCentroid(curr.pus, byid=TRUE)
  mtx <- extract(curr.spp, pu.pts)
  mtx[which(mtx > 0)] <- probability.of.occupancy
  # if a species is not found in a single pu, then assign it to two pus
  for (j in which(apply(mtx, 2, sum) < 2)) {
    mtx[sample.int(nrow(mtx), size=2),j] <- probability.of.occupancy
  }
  
  # create AttributeSpace object
  curr.attr.spaces <- AttributeSpaces(
    lapply(seq_len(nlayers(curr.spp)), function(j) {
      AttributeSpace(
        planning.unit.points=PlanningUnitPoints(
          pu.pts@coords[mtx[,j]>0,,drop=FALSE],
          ids=which(mtx[,j]>0)
        ),
        demand.points=DemandPoints(
          pu.pts@coords[mtx[,j]>0,,drop=FALSE],
          rep(1, length(which(mtx[,j]>0)))
        ),
        species=as.integer(j)
      )
    }),
    name='geographic'
  )
  
  # create data.frame with species and space targets
  curr.targets <- data.frame(
    species=seq_len(nlayers(curr.spp)),
    target=0L,
    proportion=amount.target
  ) %>% rbind(data.frame(
    species=seq_len(nlayers(curr.spp)),
    target=1L,
    proportion=space.target
  ))

  # calculate probability of each species in each pu
  curr.pu.occurrences <- data.frame(
    species=rep(seq_len(nlayers(curr.spp)), each=nrow(curr.pus)),
    pu=rep(seq_len(nrow(curr.pus)), nlayers(curr.spp)),
    value=c(mtx)
  )
  curr.pu.occurrences <- curr.pu.occurrences[curr.pu.occurrences[[3]]>0,]
  
  # compile data object
  curr.rd <- RapData(
    data.frame(
      cost=rep(1, nrow(curr.pus)),
      area=rep(1, nrow(curr.pus)),
      status=rep(0L, nrow(curr.pus))
    ),
    data.frame(name=names(curr.spp)),
    curr.targets,
    curr.pu.occurrences,
    list(curr.attr.spaces),
    calcBoundaryData(curr.pus),
    SpatialPolygons2PolySet(curr.pus)
  )
  
  # return result
  return(curr.rd)
}
