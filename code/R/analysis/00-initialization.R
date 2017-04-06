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

## Install gurobi R package if missing
if (!requireNamespace("gurobi")) {
  # find gurobi R package
  gurobi_path <- dir("/opt", "gurobi", full.names = TRUE)
  gurobi_path <- paste0(gurobi_path[length(gurobi_path)], "/linux64/R")
  gurobi_path <- dir(gurobi_path, "gurobi", full.names = TRUE)[1]
  # install pkgs
  install.packages(gurobi_path)
}

## Load parameters
general_parameters <- RcppTOML::parseTOML("code/parameters/general.toml") %>%
                      `[[`(MODE)


## Load functions
for (x in dir(file.path("code", "R", "functions"), full.names = TRUE)) {
  source(x)
}

## Set seed for reproducibility
set.seed(500)

# save session
session::save.session("data/intermediate/00-initialization.rda",
                      compress = "xz")
