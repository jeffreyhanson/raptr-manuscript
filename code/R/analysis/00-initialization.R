## Set parameters
args <- commandArgs(TRUE)
if (length(args) > 0) {
  print(args)
  if (grepl("MODE", args))
    MODE <- strsplit(grep("MODE", args, value = TRUE), "=",
                          fixed = TRUE)[[1]][[2]]
}

if (!exists("MODE")) MODE <- "debug"
cat("MODE = ", MODE, "\n")

## Load packages
library(magrittr)
library(raster)
library(sp)

## Load parameters
general_parameters <- RcppTOML::parseTOML("code/parameters/general.toml") %>%
                      `[[`(MODE)


## Load functions
for (x in dir(file.path("code", "R", "functions"), full.names = TRUE)) {
  print(x)
  source(x)
}

## Set seed for reproducibility
set.seed(500)

# save session
session::save.session("data/intermediate/00-initialization.rda",
                      compress = "xz")
