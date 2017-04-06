## load session
session::restore.session("data/intermediate/01-load-data.rda")

## load parameters
sim_parameters <- RcppTOML::parseTOML("code/parameters/simulations.toml") %>%
                  `[[`(MODE)

#### Simulate data
# make planning units
sim_pus <- raptr::sim.pus(as.integer(sim_parameters$number_planning_units))

# simulate species distributions
sim_spp <- lapply(c("uniform", "normal", "bimodal"), raptr::sim.species, n = 1,
                  x = sim_pus, res = 1)

# generate coordinates for pus/demand points
sim_pu_points <- sim_pus %>%
                 rgeos::gCentroid(byid = TRUE) %>%
                 slot("coords") %>%
                 raptr::PlanningUnitPoints(ids = seq_len(nrow(sim_pus@data)))


# create demand point objects
sim_demand_points <- lapply(sim_spp, function(x) raptr::DemandPoints(
  sim_pu_points@coords, c(extract(x, rgeos::gCentroid(sim_pus, byid = TRUE)))))

## create RapUnreliableOpts object
# this stores parameters for the unreliable formulation problem (ie. BLM)
sim_ro <- raptr::RapUnreliableOpts()

## create RapData object
# create data.frame with species info
sim_species <- data.frame(name = c("Uniform\nspecies", "Normal\nspecies",
                                   "Bimodal\nspecies"))
names(sim_demand_points) <- sim_species[[1]]

## create data.frame with species and space targets
# amount targets denoted with target = 0
# space targets denoted with target = 1
sim_targets <- data.frame(species = rep(1:3, each = 2), target = rep(0:1),
                          proportion = rep(c(sim_parameters$amount_target,
                                             sim_parameters$space_target), 3))

# calculate probability of each species in each pu
sim_pu_probabilities <- sim_pus %>%
                        raptr::calcSpeciesAverageInPus(raster::stack(sim_spp))

## create AttributeSpace object
# this stores the coordinates of the planning units in an attribute space
# and the coordinates and weights of demand points in the space
sim_attr_spaces <- raptr::AttributeSpaces(list(
    raptr::AttributeSpace(planning.unit.points = sim_pu_points,
                          demand.points = sim_demand_points[[1]], species = 1L),
    raptr::AttributeSpace(planning.unit.points = sim_pu_points,
                          demand.points = sim_demand_points[[2]], species = 2L),
    raptr::AttributeSpace(planning.unit.points = sim_pu_points,
                          demand.points = sim_demand_points[[3]],
                          species = 3L)),
  name = "geographic")

## create RapData object
# this stores all the input data for the prioritisation
sim_rd <- raptr::RapData(sim_pus@data, sim_species, sim_targets,
                         sim_pu_probabilities, list(sim_attr_spaces),
                         raptr::calcBoundaryData(sim_pus),
                         raptr::SpatialPolygons2PolySet(sim_pus))


## create RapUnsolved object
# this stores all the input data and parameters needed to generate prioritisations
sim.ru <- raptr::RapUnsolved(sim_ro, sim_rd)

## configure options to show that gurobi is installed
options(GurobiInstalled = list(gurobi = TRUE, rgurobi = FALSE))

## generate prioritizations
sim_prioritisations <- plyr::llply(as.character(sim_species[[1]]), function(x) {
    plyr::llply(list("Amount\ntargets" = c(NA, 0),
                     "Amount &\nspace targets" = c(sim_parameters$space_target,
                                                    0),
                     "Amount target\nand BLM" = c(NA, sim_parameters$blm),
                     "Amount & space\ntargets and BLM" = c(
                       sim_parameters$space_target, sim_parameters$blm)),
                function(j) {
      sim.ru %>%
      raptr::spp.subset(as.character(x)) %>%
      raptr::update(space.target = j[[1]], BLM = j[[2]], solve = TRUE,
                    threads = general_parameters$threads,
                    MIPGap = general_parameters$MIPGap)
      })
})
names(sim_prioritisations) <- as.character(sim_species[[1]])

## generate results table
sim_spp_results <- plyr::ldply(seq_along(sim_prioritisations), function(i) {
  data.frame(
    species = rep(as.character(sim_species[[1]][[i]]), 4),
    prioritisation = c("Amount\ntargets", "Amount &\nspace targets",
                       "Amount target\nand BLM",
                       "Amount & space\ntargets and BLM"),
    amount_held = sapply(sim_prioritisations[[i]],
                         function(s) raptr::amount.held(s)[1]) * 100,
    space_held = sapply(sim_prioritisations[[i]],
                        function(s) raptr::space.held(s)[1]) * 100,
    score = sapply(sim_prioritisations[[i]],
                   function(s) raptr:::score.RapSolved(s)[1]),
    n = sapply(sim_prioritisations[[i]], function(s) sum(raptr::selections(s))))
})

## save session
session::save.session("data/intermediate/02-simulations.rda", compress = "xz")
