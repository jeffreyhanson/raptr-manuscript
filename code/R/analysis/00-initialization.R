#### set default error message
# parse args
args <- commandArgs(TRUE)
if (length(args)>0) {
	print(args)
	if (grepl('MODE',args))
		MODE <- strsplit(grep('MODE', args, value=TRUE), '=', fixed=TRUE)[[1]][[2]]
}
	
#### Load pacakges
# load bioconductor packages
# set checkpoint
if (!'checkpoint' %in% installed.packages()[,'Package']) install.packages('checkpoint')
library(checkpoint)
if (!file.exists('~/.checkpoint')) dir.create('~/.checkpoint')
checkpoint('2016-07-25', R.version='3.3.1')

# load CRAN packages
library(stats)
library(RColorBrewer)
library(hexbin)
library(fields)
library(ape)
library(Hmisc)
library(data.table)
library(grid)
library(gridExtra)
library(plotrix)
library(plyr)
library(dplyr)
library(tidyr)
library(pander)
library(vegan)
library(rgeos)
library(testthat)
library(parallel)
library(rworldxtra)
library(doParallel)
library(english)
library(session)
library(maptools)
library(RcppTOML)
library(knitr)
library(lazyWeave)
library(broom)
library(adehabitatHR)

## load github packages
if (!'ALA4R' %in% installed.packages()[,'Package']) {
	withr::with_libpaths(.libPaths()[1], install.packages('bitops'))
	withr::with_libpaths(.libPaths()[1], devtools::install_github('AtlasOfLivingAustralia/ALA4R', dependencies=TRUE))
}
library(ALA4R)


if (!'spThin' %in% installed.packages()[,'Package'])
	withr::with_libpaths(.libPaths()[1], devtools::install_github('paleo13/spThin', dependencies=TRUE))
library(spThin)

# install raptr
if (!'raptr' %in% installed.packages()[,'Package']) {
	withr::with_libpaths(.libPaths()[1], install.packages(c('adehabitatLT', 'adehabitatHS', 'deldir', 'R.utils', 'geometry', 'KernSmooth', 'misc3d', 'multicool', 'fastcluster', 'rgdal', 'raster', 'PBSmapping', 'RJSONIO', 'R.methodsS3', 'R.oo')))
	devtools::install_github('paleo13/raptr', dependencies=TRUE)
}
library(raptr)

if (!'bayescanr' %in% installed.packages()[,'Package'])
	withr::with_libpaths(.libPaths()[1], devtools::install_github('paleo13/bayescanr', dependencies=TRUE))
library(bayescanr)

if (!'structurer' %in% installed.packages()[,'Package'])
	withr::with_libpaths(.libPaths()[1], devtools::install_github('paleo13/structurer', dependencies=TRUE))
library(structurer)

# manually install custom fork of ggplot2 for plotting
devtools::install_github('paleo13/ggplot2', force=TRUE)
library(ggplot2)

## misc settings
# set pander options
panderOptions('knitr.auto.asis', FALSE)

# set seed for reproducibility
set.seed(500)

# set default select method
select <- dplyr::select

### Load functions
for (x in dir(file.path('code', 'R', 'functions'), full.names=TRUE)) source(x)

### set parameters
if (!exists('MODE')) MODE <- 'debug'
cat('MODE = ',MODE,'\n')
general.params.LST <- parseTOML('code/parameters/general.toml')

# save workspace
save.session('data/intermediate/00-initialization.rda', compress='xz')

 
