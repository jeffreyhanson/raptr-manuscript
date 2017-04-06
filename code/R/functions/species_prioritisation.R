#' Generate prioritisation using specific targets
#'
#' This function is a wrapper for updating targets in a
#' \code{\link[raptr]{RapUnsolved}} object and solving it.
#'
#' @param x \code{RapUnsolved} object.
#'
#' @param amount.targets \code{numeric} amount-based targets to use.
#'
#' @param genetic.targets \code{numeric} genetic targets.
#'
#' @param ... arguments passed to solve.
#'
#' @return \code{\link[raptr]{RapSolved}}
species_prioritisation <- function(x, amount_targets, genetic_targets, ...) {
  # init
  genetic_pos <- grep("^genetic\\_.*$", x@data@targets$name)
  amount_pos <- which(x@data@targets$target == 0)
  # update targets
  x@data@targets[amount_pos, "proportion"] <- amount_targets
  x@data@targets[genetic_pos, "proportion"] <- genetic_targets
  # solve object
  ret <- raptr::solve(x, ...)
  return(ret)
}
