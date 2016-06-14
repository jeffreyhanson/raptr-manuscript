#' Extract results from RapSolved object
#'
#' This function extracts results from a RapSolved object
#'
#' @param x \code{RapSolved} object.
#' @export
extractResults <- function(x) {
	# extract score
	score.DF <- data.frame(
		Solution=rep(seq_along(x@results@summary$Score), each=length(x@data@species$name)),
		Score=rep(x@results@summary$Score,each=length(x@data@species$name))
	)
	# extract amount held
	amount.held.DF <- ldply(
		seq_len(nrow(x@results@summary)),
		function(r) {
			data.frame(
			Species=x@data@species$name,
			amount.held=c(amount.held(x,y=r))
		)
	})
	# extract space names
	space.names <- sapply(x@data@attribute.spaces, 'slot', 'name')
	# extract space held
	space.held.DF <- ldply(
		seq_len(nrow(x@results@summary)),
		function(r) {
		ldply(
			x@data@species$name, 
			function(y) {
			# get space names
			curr.DF <- as.data.frame(space.held(x, y=r, species=y))
			names(curr.DF) <- space.names
			# make data.frame
			return(curr.DF)
		})
	})
	# return data.frame
	return(
		cbind(
			score.DF,
			amount.held.DF,
			space.held.DF
		)
	)
}
