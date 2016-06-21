## load .rda
session::restore.session('data/intermediate/01-load-data.rda')

## load parameters
cs1.params.LST <- parseTOML('code/parameters/case-study-1.toml')

### Prepare data for prioritizations
## prepare pca layers
# select layers
cs1.bioclim.RAST <- cs1.bioclim.RAST[[seq_len(cs1.params.LST[[MODE]]$n.pc.layers)]]

# aggregate env layer to reduce computational burden
cs1.bioclim.RAST <- aggregate(cs1.bioclim.RAST, cs1.params.LST[[MODE]]$environmental.layer.resolution/1000)

## make planning units
# download queensland layer
aus.PLY <- getData('GADM', country='AUS', level=1, path='data/intermediate') %>% spTransform(cs1.bioclim.RAST@crs)
qld.PLY <- aus.PLY[aus.PLY$HASC_1=='AU.QL',]  %>% gSimplify(1000)
aus.PLY <- aus.PLY %>% gSimplify(1000)

# create planning units over queensland
cs1.pus <- blank.raster(qld.PLY, cs1.params.LST[[MODE]]$pu.size) %>% rasterToPolygons()
cs1.pus@data$id <- seq_len(nrow(cs1.pus@data))
cs1.pus@proj4string <- cs1.bioclim.RAST@crs

# omit planning units that doesn't overlap with non-NA values in worldclim raster
values.MTX <- parallel_extract(x=cs1.bioclim.RAST, y=cs1.pus, threads=general.params.LST[[MODE]]$threads, fun=mean)
values.MTX <- cbind(matrix(seq_len(nrow(cs1.pus@data)),ncol=1), values.MTX)
cs1.pus <- cs1.pus[which(rowSums(!is.finite(values.MTX[,-1]))==0),]
values.MTX <- values.MTX[cs1.pus$id,]
cs1.pus@data$id <- seq_len(nrow(cs1.pus@data))
cs1.pus <- spChFIDs(cs1.pus, as.character(seq_len(nrow(cs1.pus@data))))

# clip planning units to coastline
cs1.pus <- gIntersection(cs1.pus, qld.PLY, byid=TRUE)
cs1.pus <- SpatialPolygonsDataFrame(cs1.pus, data=data.frame(id=seq_along(cs1.pus@polygons), area=gArea(cs1.pus, byid=TRUE)/100000, cost=1, status=0L))
cs1.pus <- cs1.pus[cs1.pus$area>(max(cs1.pus$area)*0.5),]
cs1.pus@data$id <- seq_len(nrow(cs1.pus@data))
cs1.pus <- spChFIDs(cs1.pus, as.character(seq_len(nrow(cs1.pus@data))))

## generate species range maps
# download species records
dir.create('data/intermediate/ala_cache', showWarnings=FALSE)
ala_config(cache_directory='data/intermediate/ala_cache', download_reason_id=4)
cs1.records.LST <- llply(cs1.params.LST[[MODE]]$species.names, occurrences, wkt=cs1.record.bbox, use_data_table=TRUE)
# subset and combine records
cs1.subset.records.LST <- llply(cs1.records.LST, function(x) {
	# extract valid records
	x <- dplyr::filter(
		x$data,
		habitatMismatch==FALSE,
		inferredDuplicateRecord==FALSE,
		coordinateUncertaintyInMetres<=10000,
		is.finite(longitude),
		is.finite(latitude)
	)
	if ('speciesOutsideExpertRange' %in% names(x)) x <- filter(x, speciesOutsideExpertRange==FALSE)
	# subset to first n records (used for debugging parameters)
	if (nrow(x) > cs1.params.LST[[MODE]]$max.records) x <- x[seq_len(cs1.params.LST[[MODE]]$max.records),]
	# return subsetted data
	return(x)
})
# rarefy records
cs1.rarefied.records.LST <- llply(cs1.subset.records.LST, function(x) {
	x.sp <- SpatialPoints(coords=as.matrix(x[,c('longitude', 'latitude')]), proj4string=CRS('+init=epsg:4326')) %>% spTransform(qld.PLY@proj4string)
	x.rfy <- spRarefy(x=x.sp, grid=as.numeric(cs1.params.LST[[MODE]]$rarefy.cell.size), nrep=1)
	return(x.rfy)
})
# thin records 
cs1.thinned.records.LST <- llply(cs1.rarefied.records.LST, function(x) {
	spThin(
		spTransform(x[[1]], CRS('+init=epsg:4326')),
		method='gurobi',
		great.circle.distance=TRUE,
		dist=cs1.params.LST[[MODE]]$thin.distance,
		Presolve=2,
		Threads=general.params.LST[[MODE]]$threads,
		MIPGap=general.params.LST[[MODE]]$MIPGap
	)
})
# generate mcps
cs1.spp.mcp.LST <- llply(cs1.thinned.records.LST, function(x) {
	mcp(x[[1]], percent=cs1.params.LST[[MODE]]$mcp.percent)
})
# convert to rasters
cs1.spp.RST <- llply(cs1.spp.mcp.LST, function(x) {
	x %>% 
		spTransform(CRSobj=cs1.bioclim.RAST@crs) %>% 
		rasterize( y=cs1.bioclim.RAST[[1]]) %>% 
		mask(mask=cs1.bioclim.RAST[[1]]) %>%
		return()
}) %>% stack()
names(cs1.spp.RST) <- cs1.params.LST[[MODE]]$common.names

## create RapUnsolved object
# create template RapUnsolved with dummy attribute space data
cs1.ru <- rap(pus=cs1.pus, species=cs1.spp.RST, spaces=list(cs1.bioclim.RAST), kernel.method='hypervolume',amount.target=cs1.params.LST[[MODE]]$amount.target, space.target=cs1.params.LST[[MODE]]$space.target, solve=FALSE, quantile=0.95, n.demand.points=20, n.species.points=rep(20, nlayers(cs1.spp.RST)), Threads=general.params.LST[[MODE]]$threads, MIPGap=general.params.LST[[MODE]]$MIPGap, NumberSolutions=1, include.geographic.space=FALSE)
cs1.ru@data@species[[1]] <- cs1.params.LST[[MODE]]$common.names
# create new attribute spaces
cs1.spaces <- llply(seq_along(cs1.params.LST[[MODE]]$common.names), .fun=function(i) {
	## extract coordinates of planning units in environmental space
	curr.ids<-cs1.ru@data@attribute.spaces[[1]]@spaces[[i]]@planning.unit.points@ids
	curr.pu.coords <- values.MTX[curr.ids,-1,drop=FALSE]
	# z-score coordinates
	curr.pu.coords.mean <- apply(curr.pu.coords, 2, mean)
	curr.pu.coords.sd <- apply(curr.pu.coords, 2, sd)
	curr.pu.coords<-sweep(curr.pu.coords,MARGIN=2,FUN='-',curr.pu.coords.mean)
	curr.pu.coords<-sweep(curr.pu.coords,MARGIN=2,FUN='/',curr.pu.coords.sd) 
	## extract coordinates in environmental space
	curr.species.geo.points <- SpatialPoints(coords=randomPoints(cs1.spp.RST[[i]], n=200), proj4string=cs1.spp.RST[[i]]@crs)
	curr.species.env.points <- extract(cs1.bioclim.RAST,curr.species.geo.points)
	# omit outlying points in the randomly generated points
	curr.species.env.points.sp <- SpatialPoints(curr.species.env.points)
	curr.species.env.points.mcp <- mcp(curr.species.env.points.sp, percent=cs1.params.LST[[MODE]]$mcp.percent)
	curr.species.env.points <- curr.species.env.points[gIntersects(curr.species.env.points.sp,curr.species.env.points.mcp,byid=TRUE)[1,],]
	# z-score coodinates
	curr.species.env.points.mean <- apply(curr.species.env.points, 2, mean)
	curr.species.env.points.sd <- apply(curr.species.env.points, 2, sd)
	curr.species.env.points<-sweep(curr.species.env.points,MARGIN=2,FUN='-',curr.species.env.points.mean)
	curr.species.env.points<-sweep(curr.species.env.points,MARGIN=2,FUN='/',curr.species.env.points.sd)
	# generate demand points
	raw.curr.species.dps <- make.DemandPoints(curr.species.env.points,  n=cs1.params.LST[[MODE]]$dp.number, quantile=cs1.params.LST[[MODE]]$dp.quantile, kernel.method='hypervolume', bandwidth=cs1.params.LST[[MODE]]$dp.bandwidth)
	raw.curr.species.dps@coords<-sweep(raw.curr.species.dps@coords,MARGIN=2,FUN='*',curr.species.env.points.sd)
	raw.curr.species.dps@coords<-sweep(raw.curr.species.dps@coords,MARGIN=2,FUN='+',curr.species.env.points.mean)
	## put demand points on the same scale as the planning unit coordinates
	curr.species.dps <- raw.curr.species.dps
	curr.species.dps@coords<-sweep(curr.species.dps@coords,MARGIN=2,FUN='-',curr.pu.coords.mean)
	curr.species.dps@coords<-sweep(curr.species.dps@coords,MARGIN=2,FUN='/',curr.pu.coords.sd) 
	return(
		AttributeSpace(
			planning.unit.points=PlanningUnitPoints(coords=curr.pu.coords,ids=curr.ids),
			demand.points=curr.species.dps,
			species=i
		)
	)
})
cs1.ru@data@attribute.spaces <- list(AttributeSpaces(space=cs1.spaces,name='niche'))
# check that modifications are acceptable
validObject(cs1.ru, test=FALSE)

## make prioritizations
cs1.prioritisations <- llply(
	list(
		'Amount targets'=list(cs1.params.LST[[MODE]]$amount.target,NA),
		'Amount & niche targets'=list(cs1.params.LST[[MODE]]$amount.target,cs1.params.LST[[MODE]]$space.target)
	),
	function(y) {
		update(cs1.ru, amount.target=y[[1]], space.target=y[[2]], solve=TRUE)
	}
)
names(cs1.prioritisations) <- c('Amount targets','Amount & niche targets')

## extract results
cs1.spp.DF <- ldply(
	seq_along(cs1.prioritisations),
	.fun=function(i) {
		mutate(
			extractResults(cs1.prioritisations[[i]]),
			Prioritisation=names(cs1.prioritisations)[i]
		)
	}
)

## save workspace
save.session('data/intermediate/03-case-study-1.rda', compress='xz')
 
