## load .rda
session::restore.session('data/intermediate/00-initialization.rda')

### load simulation data
# all data is simulated using functions in the package - no data to load

### load case-study 1 data
# load in record bbox
cs1.record.bbox <- shapefile('data/raw/record_bbox/record_bbox.shp') %>% writeWKT

# load in environmental data
cs1.bioclim.RAST <- stack('data/raw/BioClim_variables/pca.tif')
cs1.pca.DF <- read.table('data/raw/BioClim_variables/pca.TXT', skip=94) %>% `names<-`(
	c('Principle Component', 'Eigen Value', 'Variation explained (%)',
	'Accumulative variation explained (%)')
)

### load case-study 2 data
## compile spatial grid data
# load in opportunity costs
cs2.cost.RAST <- raster('data/raw/GRUMP_V1_Population_Density/grumpv1-popdensity.tif')

# load in species population numbers
cs2.spp.populations.DF <- fread('data/raw/Data_Meirmans_et_al_IntrabioDiv/NumberPopulations.csv', data.table=FALSE)

# load grid cell centroids
cs2.grid.DF <- fread(
	'data/raw/Data_Meirmans_et_al_IntrabioDiv/README',
	data.table=FALSE,
	skip='cell\tLong\tLat'
) %>% rename(
		grid.longitude=Long,
		grid.latitude=Lat
) %>% mutate(
	id=seq_along(grid.latitude)
)

# load in aflp data
cs2.spp.aflp.paths <- dir(
	'data/raw/Data_Meirmans_et_al_IntrabioDiv',
	'^.*AFLP\\.dat$',
	full.names=TRUE
)

cs2.spp.StructureData.LST <- llply(
	cs2.spp.aflp.paths,
	read.StructureData
)

# compile species occurence data
# load in data
cs2.spp.loc.paths <- dir(
	'data/raw/Data_Meirmans_et_al_IntrabioDiv',
	'^.*locations\\.txt$',
	full.names=TRUE
)
cs2.spp.samples.DF <- ldply(
	seq_along(cs2.spp.loc.paths),
	.fun=function(i) {
		x <- mutate(
			fread(cs2.spp.loc.paths[i], data.table=FALSE),
			species=gsub('_locations.txt', '', basename(cs2.spp.loc.paths[i]), fixed=TRUE)
		) %>% rename(
			cell=population,
			sample.longitude=longitude,
			sample.latitude=latitude
		)
		return(x[as.numeric(cs2.spp.StructureData.LST[[i]]@sample.names),])
	}
) %>% left_join(
		cs2.grid.DF,
		by='cell'
)

# remove individuals that are all NAs
for (i in seq_along(cs2.spp.StructureData.LST)) {
	# find individuals that are all NAs
	curr.invalid <- which(rowSums(is.na(cs2.spp.StructureData.LST[[i]]@matrix))==ncol(cs2.spp.StructureData.LST[[i]]@matrix))
	# if any invalid then remove from objects
	if (length(curr.invalid)>0) {
		# get valid individuals
		curr.valid <- which(rowSums(is.na(cs2.spp.StructureData.LST[[i]]@matrix))!=ncol(cs2.spp.StructureData.LST[[i]]@matrix))
		# subset from StructureData
		cs2.spp.StructureData.LST[[i]] <- structurer:::sample.subset.StructureData(cs2.spp.StructureData.LST[[i]], curr.valid)
		# remove from cs2.spp.samples.DF
		cs2.spp.samples.DF <- cs2.spp.samples.DF[-which(cs2.spp.samples.DF$species==unique(cs2.spp.samples.DF$species)[i])[curr.invalid],]
	}
}

# append species data to grid data.frame (wide-format)
for (i in unique(cs2.spp.samples.DF$species))
	cs2.grid.DF[[i]] <- replace(
		rep(0, nrow(cs2.grid.DF)),
		which(cs2.grid.DF$cell %in% filter(cs2.spp.samples.DF, species==i)$cell),
		1
	)

# omit grids not occupied by any individuals
cs2.grid.DF <- cs2.grid.DF[rowSums(cs2.grid.DF[,c(-1, -2, -3, -4),drop=FALSE])>0,]
cs2.spp.samples.DF$id <- match(cs2.spp.samples.DF$id, cs2.grid.DF$id)
cs2.grid.DF$id <- seq_len(nrow(cs2.grid.DF))
rownames(cs2.grid.DF) <- as.character(seq_len(nrow(cs2.grid.DF)))

# create Spatial* objects
cs2.grid.PTS <- SpatialPoints(as.matrix(cs2.grid.DF[,2:3]))
cs2.grid.PLY <- cs2.grid.PTS %>%
	points2grid(tolerance=0.05) %>%
	as('SpatialPolygons')
cs2.grid.PLY <- cs2.grid.PLY[sapply(gIntersects(cs2.grid.PTS, cs2.grid.PLY, byid=TRUE, returnDense=FALSE), `[[`, 1),] %>%
	spChFIDs(as.character(seq_len(nrow(cs2.grid.DF)))) %>% 
	SpatialPolygonsDataFrame(data=cs2.grid.DF)
cs2.grid.PLY@proj4string <- wgs1984

## save workspace
save.session('data/intermediate/01-load-data.rda', compress='xz')
 
