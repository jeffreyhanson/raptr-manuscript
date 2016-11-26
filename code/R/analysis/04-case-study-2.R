## load .rda
checkpoint::checkpoint('2016-11-26', R.version='3.3.1', scanForPackages=FALSE)
session::restore.session('data/intermediate/01-load-data.rda')

## load parameters
cs2.params.LST <- parseTOML('code/parameters/case-study-2.toml')

### prepare genetic attribute-spaces
# subset to relevant species
cs2.params.LST[[MODE]]$species.name <- gsub(' ', '_', cs2.params.LST[[MODE]]$species.name, fixed=TRUE)
spp.pos <- which(unique(cs2.spp.samples.DF$species) %in% cs2.params.LST[[MODE]]$species.name)
cs2.spp.StructureData.LST <- cs2.spp.StructureData.LST[spp.pos]
cs2.spp.samples.DF <- cs2.spp.samples.DF[cs2.spp.samples.DF$species %in% cs2.params.LST[[MODE]]$species.name,]

# run mds
cs2.spp.nmds.LST <- llply(
	seq_along(cs2.spp.StructureData.LST),
	.fun=function(i) {
		# manually classify loci as neutral or adaptive
		curr.spp <- bayescanr::BayeScanData(
			cs2.spp.StructureData.LST[[i]]@matrix,
			primers=cs2.spp.StructureData.LST[[i]]@loci.names,
			populations=rep('1', nrow(cs2.spp.StructureData.LST[[i]]@matrix)),
			labels=cs2.spp.StructureData.LST[[i]]@sample.names
		)
		curr.nmds <- bayescanr::nmds(
			curr.spp,
			metric='gower',
			max.stress=cs2.params.LST[[MODE]]$max.stress,
			min.k=cs2.params.LST[[MODE]]$min.k,
			max.k=cs2.params.LST[[MODE]]$max.k,
			trymax=cs2.params.LST[[MODE]]$trymax
		)
	}
)

# store mds rotations for each sample
cs2.spp.samples.DF <- ldply(
	seq_along(unique(cs2.spp.samples.DF$species)),
	.fun=function(i) {
		cbind(
			filter(cs2.spp.samples.DF, species==unique(cs2.spp.samples.DF$species)[i]),
			`names<-`(
				as.data.frame(cs2.spp.nmds.LST[[i]]$points),
				paste0('genetic_d',seq_len(cs2.spp.nmds.LST[[i]]$ndim))
			)
		)
	}
)

# store nmds average rotation for each grid
for (i in seq_along(unique(cs2.spp.samples.DF$species))) {
	curr.sub <- filter(cs2.spp.samples.DF, species==unique(cs2.spp.samples.DF$species)[i])
	for (k in seq_len(cs2.spp.nmds.LST[[i]]$ndim)) {
		curr.vals <- tapply(
			curr.sub[[paste0('genetic_d',k)]],
			curr.sub$cell,
			FUN=mean
		)
		curr.pos <- match(names(curr.vals), cs2.grid.DF$cell)
		cs2.grid.DF[curr.pos,paste0(unique(cs2.spp.samples.DF$species)[i],'_genetic_d',k)] <- curr.vals
	}
}

# update grid.PLY with additional attributes
cs2.grid.PLY@data <- cs2.grid.DF

# subset planning units occupied by species used in analysis
cells <- cs2.grid.DF$cell[rowSums(cs2.grid.DF[,c(cs2.params.LST[[MODE]]$species.name),drop=FALSE])>0]
cs2.spp.samples.sub.DF <- cs2.spp.samples.DF %>% filter(cell %in% cells)
cs2.grid.sub.DF <- cs2.grid.DF %>% filter(cell %in% cells)
cs2.grid.sub.PLY <- cs2.grid.PLY[cs2.grid.PLY$cell %in% cells,]
cs2.grid.sub.PLY <- spChFIDs(cs2.grid.sub.PLY, as.character(seq_len(nrow(cs2.grid.sub.PLY@data))))

### prepare data
# generate attribute spaces for genetic data
cs2.genetic.AS <- AttributeSpaces(
	spaces=llply(
		seq_along(unique(cs2.spp.samples.sub.DF$species)),
		function(i) {
			make.genetic.AttributeSpace(
				site.data=select(cs2.grid.sub.DF, contains(paste0(unique(cs2.spp.samples.sub.DF$species)[i], '_genetic'))),
				species.data=na.omit(select(cs2.grid.sub.DF, contains(paste0(unique(cs2.spp.samples.sub.DF$species)[i], '_genetic')))),
				species=i
			)
		}
	),
	name='genetic'
)

# make table with temporary targets
cs2.target.DF <- data.frame(
	species=rep(seq_along(unique(cs2.spp.samples.sub.DF$species)),2),
	target=rep(0:1, each=n_distinct(cs2.spp.samples.sub.DF$species)),
	proportion=rep(c(0.2, 0.5), each=n_distinct(cs2.spp.samples.sub.DF$species)),
	name=paste0(
		rep(c('amount_', 'genetic_'), each=n_distinct(cs2.spp.samples.sub.DF$species)),
		rep(unique(cs2.spp.samples.sub.DF$species),2)
	)
)

# extract costs
costs.MTX <- cs2.grid.sub.PLY %>% rasterize(cs2.cost.RAST, field='id') %>% zonal(x=cs2.cost.RAST, fun='sum')
costs.MTX[,2] <- log(costs.MTX[,2])

# make Rap objects
cs2.rd <- RapData(
	polygon=SpatialPolygons2PolySet(cs2.grid.sub.PLY),
	pu=data.frame(
		cost=costs.MTX[,2],
		area=1,
		status=rep(0L, nrow(cs2.grid.sub.DF))
	),
	species=data.frame(name=unique(cs2.spp.samples.sub.DF$species)),
	target=cs2.target.DF,
	attribute.spaces=list(cs2.genetic.AS),
	pu.species.probabilities=ldply(
		seq_along(unique(cs2.spp.samples.sub.DF$species)),
		.fun=function(i) {
			data.frame(
				species=i,
				pu=which(cs2.grid.sub.DF[[unique(cs2.spp.samples.sub.DF$species)[i]]]==1),
				value=1
			)
		}
	),
	boundary=calcBoundaryData(cs2.grid.sub.PLY)
)

# create RapUnsolved without cost data
cs2.ru <- RapUnsolved(RapUnreliableOpts(), cs2.rd)

### generate prioritizations
cs2.prioritisations <- llply(
	list(
		list(cs2.params.LST[[MODE]]$amount.target,NA),
		list(cs2.params.LST[[MODE]]$amount.target,cs2.params.LST[[MODE]]$genetic.target)
	),
	function(y) {
		species.prioritisation(
			x=cs2.ru,
			amount.targets=y[[1]],
			genetic.targets=y[[2]],
			Threads=general.params.LST[[MODE]]$threads,
			MIPGap=general.params.LST[[MODE]]$MIPGap,
			NumberSolutions=1L
		)
	}
)

### generate results table
cs2.spp.DF <- ldply(
	seq_along(cs2.prioritisations),
	.fun=function(i) {
		mutate(
			extractResults(cs2.prioritisations[[i]]),
			Prioritisation=c('Amount','Genetic')[i],
			amount.held=amount.held*100,
			genetic=genetic*100
		)
	}
)

## save workspace
save.session('data/intermediate/04-case-study-2.rda', compress='xz')

