#' Generate prioritisation using specific targets
#'
#' This function is a wrapper for updating targets in a \code{RapUnsolved} object and solving it.
#'
#' @param x \code{RapUnsolved} object.
#' @param amount.targets \code{numeric} amount-based targets to use.
#' @param genetic.targets \code{numeric} genetic targets.
#' @param ... arguments passed to solve.
#' @return \code{RapSolved}
species.prioritisation <- function(x, amount.targets, genetic.targets, ...) {
	# init
	genetic.pos <- grep('^genetic\\_.*$', x@data@targets$name)
	# update targets
	x@data@targets[which(x@data@targets$target==0),'proportion'] <- amount.targets
	x@data@targets[genetic.pos,'proportion'] <- genetic.targets
	# solve object
	ret<-solve(x, ...)
	return(ret)
}

