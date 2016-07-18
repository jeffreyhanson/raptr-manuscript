#' Make target data using attribute spaces
#'
#' This function takes a set of species names and 
#' attribute spaces and generates a table with targets.
#'
#' @param species \code{character} species names.
#' @param genetic.space \code{AttributeSpace} object with genetic space data.
#' @param amount.target \code{numeric} amount-based target
#' @param genetic.target \code{numeric} genetic-based target
#' @seealso \code{\link[raptr]{AttributeSpace}}.
#' @export
make.targets <- function(species, genetic.spaces, amount.target=0.2, genetic.target=0.2) {
	# amount targets
	amount.targets.DF <- data.frame(
		species=seq_along(species),
		target=rep(0, length(species)),
		proportion=rep(amount.target, length(species)),
		name=paste0('amount_',species)
	)
	# genetic spaces
	genetic.targets.DF <- ldply(seq_along(genetic.spaces), .fun=function(i) {
		# get species position
		spp.pos <- which(sapply(genetic.spaces[[i]]@demand.points, function(y) {length(y@weights)})>2)
		# return data.frame
		spp.DF <- data.frame(
			species=seq_along(species),
			target=rep(i, length(species)),
			proportion=replace(
				rep(NA_real_, length(species)),
				spp.pos,
				genetic.target
			),
			name=replace(
				rep('null',length(species)),
				spp.pos,
				paste0('genetic_',species[spp.pos])
			)
		)
		return(spp.DF)
	})
	# return
	return(
		mutate(rbind(amount.targets.DF, genetic.targets.DF),
		target=as.integer(target), species=as.integer(species))
	)
}


