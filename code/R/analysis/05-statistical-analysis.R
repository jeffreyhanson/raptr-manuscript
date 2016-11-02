## load .rda
checkpoint::checkpoint('2016-11-01', R.version='3.3.1', scanForPackages=FALSE)
session::restore.session('data/intermediate/04-case-study-2.rda')
load('data/intermediate/03-case-study-1.rda')
load('data/intermediate/02-simulations.rda')

## simulation study

## case-study 1

## case-study 2
# generate inverse distance matrix
cs2.pu.centroids <- gCentroid(cs2.grid.sub.PLY, byid=TRUE) %>% spTransform(CRS('+init=epsg:4326'))
cs2.pu.inv.dists <- cs2.pu.centroids@coords %>% rdist.earth
cs2.pu.inv.dists <- 1/cs2.pu.inv.dists
diag(cs2.pu.inv.dists) <- 0

# calculate Morans I
cs1.nmds.MoransI <- llply(
	unique(cs2.spp.samples.sub.DF$species),
	function(x) {
		curr.DF <- select(cs2.grid.sub.DF, contains(paste0(x,'_genetic_d')))
		return(
			llply(
				seq_len(ncol(curr.DF)),
				function(i) {
					curr.col <- curr.DF[[i]]
					curr.pos <- which(!is.na(curr.DF[[i]]))
					return(
						Moran.I(curr.DF[[i]][curr.pos], cs2.pu.inv.dists[curr.pos, curr.pos])
					)
				}
			)
		)
	}
)

# calculate numbers and generate vectors for article
amount.represented.species.names <- filter(cs1.spp.DF, Prioritisation=='Amount targets', niche >= (cs1.params.LST[[MODE]]$'space.target'*100))$Species
amount.not.represented.species.names <- filter(cs1.spp.DF, Prioritisation=='Amount targets', niche<(cs1.params.LST[[MODE]]$'space.target'*100))$Species

if (length(amount.represented.species.names)>1) {
	parsed.representative.space.held.names <- sapply(
		as.character(amount.represented.species.names),
		function(x) {
			paste0(tolower(x), ' (', round(filter(cs1.spp.DF, Prioritisation=='Amount targets', Species==x)$niche,2), ' %)')		
		}
	)
	parsed.representative.space.held.names <- paste0(paste(parsed.representative.space.held.names[-length(parsed.representative.space.held.names)], collapse=', '), ', and the ', last(parsed.representative.space.held.names))
} else {
	parsed.representative.space.held.names <- paste0(amount.represented.species.names, ' (', round(filter(cs1.spp.DF, Prioritisation=='Amount targets', Species==amount.represented.species.names)$niche,2), ' %)')
}

if (length(amount.not.represented.species.names)>1) {
	parsed.not.representative.space.held.names <- sapply(
		as.character(amount.not.represented.species.names),
		function(x) {
			paste0(tolower(x), ' (', round(filter(cs1.spp.DF, Prioritisation=='Amount targets', Species==x)$niche,2), ' %)')		
		}
	)
	parsed.not.representative.space.held.names <- paste0(paste(parsed.not.representative.space.held.names[-length(parsed.not.representative.space.held.names)], collapse=', '), ', and the ', last(parsed.not.representative.space.held.names))
} else if (length(amount.not.represented.species.names)==1) {
	parsed.not.representative.space.held.names <- paste0(amount.not.represented.species.names, '(', round(filter(cs1.spp.DF, Prioritisation=='Amount targets', Species==amount.not.represented.species.names)$niche,2), ' %)')
} else {
	parsed.not.representative.space.held.names=c()
}

## save workspace
save.session('data/intermediate/05-statistical-analysis.rda', compress='xz')
 

