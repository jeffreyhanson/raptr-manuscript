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
if (!file.exists('~/.checkpoint')) dir.create('~/.checkpoint')
checkpoint::checkpoint('2016-11-01', R.version='3.3.1')
if (!'checkpoint' %in% installed.packages()[,'Package']) install.packages('checkpoint')

# load CRAN packages
library(stats)
library(checkpoint)
library(session)
library(data.table)
library(RcppTOML)

library(parallel)
library(doParallel)

library(RColorBrewer)
library(hexbin)
library(grid)
library(gridExtra)
library(plotrix)

library(plyr)
library(dplyr)
library(tidyr)
library(testthat)


library(raptr)
library(rgeos)
library(rworldxtra)
library(maptools)
library(adehabitatHR)

library(vegan)
library(fields)
library(ape)

library(Hmisc)
library(pander)
library(english)
library(knitr)
library(lazyWeave)
library(broom)
library(rmarkdown)


## load github packages
if (!'ALA4R' %in% installed.packages()[,'Package']) {
	withr::with_libpaths(.libPaths()[1], install.packages('bitops'))
	withr::with_libpaths(.libPaths()[1], devtools::install_github('AtlasOfLivingAustralia/ALA4R', dependencies=NA))
}
library(ALA4R)


if (!'spThin' %in% installed.packages()[,'Package'])
	withr::with_libpaths(.libPaths()[1], devtools::install_github('jeffreyhanson/spThin', dependencies=NA))
library(spThin)

if (!'bayescanr' %in% installed.packages()[,'Package'])
	withr::with_libpaths(.libPaths()[1], devtools::install_github('jeffreyhanson/bayescanr', dependencies=NA))
library(bayescanr)

if (!'structurer' %in% installed.packages()[,'Package'])
	withr::with_libpaths(.libPaths()[1], devtools::install_github('jeffreyhanson/structurer', dependencies=NA))
library(structurer)

if (!'gurobi' %in% installed.packages()[,'Package']) {
	# find gurobi R package
	gurobi.PTH <- dir('/opt', 'gurobi', full.names=TRUE)
	gurobi.PTH <- paste0(gurobi.PTH[length(gurobi.PTH)], '/linux64/R')
	gurobi.PTH <- dir(gurobi.PTH, 'gurobi', full.names=TRUE)[1]
	# install pkgs
	withr::with_libpaths(.libPaths()[1], install.packages('slam'))
	withr::with_libpaths(.libPaths()[1], install.packages(gurobi.PTH))
}

# manually install custom fork of ggplot2 for plotting
devtools::install_github('jeffreyhanson/ggplot2', force=TRUE)
library(ggplot2)

### set parameters
if (!exists('MODE')) MODE <- 'debug'
cat('MODE = ',MODE,'\n')
general.params.LST <- RcppTOML::parseTOML('code/parameters/general.toml')

## misc settings
# set pander options
panderOptions('knitr.auto.asis', FALSE)

# set seed for reproducibility
set.seed(500)

# set default select method
select <- dplyr::select

### Load functions
for (x in dir(file.path('code', 'R', 'functions'), full.names=TRUE)) source(x)

# save workspace
save.session('data/intermediate/00-initialization.rda', compress='xz')

 
