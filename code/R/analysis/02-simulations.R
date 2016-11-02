## load .rda
checkpoint::checkpoint('2016-11-01', R.version='3.3.1', scanForPackages=FALSE)
session::restore.session('data/intermediate/01-load-data.rda')

## load parameters
sim.params.LST <- parseTOML('code/parameters/simulations.toml')

#### Simulate data
# make planning units
sim.pus <- sim.pus(as.integer(sim.params.LST[[MODE]]$number.planning.units))

# simulate species distributions
sim.spp <- lapply(
	c('uniform', 'normal', 'bimodal'),
	sim.species,
  n=1,
  x=sim.pus,
  res=1
)

# generate coordinates for pus/demand points
sim.pu.points <- PlanningUnitPoints(
	coords=gCentroid(sim.pus, byid=TRUE)@coords,
	ids=seq_len(nrow(sim.pus@data))
)

# create demand point objects
sim.dps <- lapply(
	sim.spp,
	function(x) {
		return(
			DemandPoints(
				sim.pu.points@coords,
				c(extract(x, gCentroid(sim.pus, byid=TRUE)))
			)
		)
	}
)

## create RapUnreliableOpts object
# this stores parameters for the unreliable formulation problem (ie. BLM)
sim.ro <- RapUnreliableOpts()

## create RapData object
# create data.frame with species info
sim.species <- data.frame(name=c('Uniform\nspecies', 'Normal\nspecies', 'Bimodal\nspecies'))
names(sim.dps) <- sim.species[[1]]

## create data.frame with species and space targets
# amount targets denoted with target=0)
# space targets denoted with target=1)
sim.targets <- data.frame(
	species=rep(1:3, each=2),
  target=rep(0:1),
  proportion=rep(c(sim.params.LST[[MODE]]$amount.target, sim.params.LST[[MODE]]$space.target), 3)
)

# calculate probability of each species in each pu
sim.pu.probabilities <- calcSpeciesAverageInPus(sim.pus, stack(sim.spp))

## create AttributeSpace object
# this stores the coordinates of the planning units in an attribute space
# and the coordinates and weights of demand points in the space
sim.attr.spaces <- AttributeSpaces(
	list(
		AttributeSpace(
			planning.unit.points=sim.pu.points,
			demand.points=sim.dps[[1]],
			species=1L
		),
		AttributeSpace(
			planning.unit.points=sim.pu.points,
			demand.points=sim.dps[[2]],
			species=2L
		),
		AttributeSpace(
			planning.unit.points=sim.pu.points,
			demand.points=sim.dps[[3]],
			species=3L
		)
	),
	name='geographic'
)

## create RapData object
# this stores all the input data for the prioritisation
sim.rd <- RapData(
  sim.pus@data,
  sim.species,
  sim.targets,
  sim.pu.probabilities,
  list(sim.attr.spaces),
  calcBoundaryData(sim.pus),
  SpatialPolygons2PolySet(sim.pus)
)

## create RapUnsolved object
# this stores all the input data and parameters needed to generate prioritisations
sim.ru <- RapUnsolved(sim.ro, sim.rd)

## generate prioritizations
sim.prioritisations <- llply(
	as.character(sim.species[[1]]),
	.fun=function(x) {
		llply(
			list(
			'Amount\ntargets'=c(NA, 0),
			'Amount &\nspace targets'=c(sim.params.LST[[MODE]]$space.target, 0),
			'Amount target\nand BLM'=c(NA, sim.params.LST[[MODE]]$blm),
			'Amount & space\ntargets and BLM'=c(sim.params.LST[[MODE]]$space.target, sim.params.LST[[MODE]]$blm)
		),
			function(j) {
				sim.ru %>% spp.subset(x) %>% update(space.target=j[[1]], BLM=j[[2]], solve=TRUE,
				threads=general.params.LST[[MODE]]$threads, MIPGap=general.params.LST[[MODE]]$MIPGap)
			}
		)
	}
)
names(sim.prioritisations) <- as.character(sim.species[[1]])

## generate results table
sim.spp.DF <- ldply(
	seq_along(sim.prioritisations),
	.fun=function(i) {
		data.frame(
			species=rep(as.character(sim.species[[1]][[i]]), 4),
			prioritisation=c('Amount\ntargets', 'Amount &\nspace targets', 'Amount target\nand BLM', 'Amount & space\ntargets and BLM'),
			amount.held=sapply(sim.prioritisations[[i]], function(s) {amount.held(s)[1]})*100,
			space.held=sapply(sim.prioritisations[[i]], function(s) {space.held(s)[1]})*100,
			score=sapply(sim.prioritisations[[i]], function(s) {score(s)[1]}),
			n=sapply(sim.prioritisations[[i]], function(s) {sum(selections(s))})
		)
	}
)


## save workspace
save.session('data/intermediate/02-simulations.rda', compress='xz')
 
