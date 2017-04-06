#' Extract results from RapSolved object
#'
#' This function extracts results from a RapSolved object
#'
#' @param x \code{\link[raptr]{RapSolved}} object.
#'
#' @export
extract_results <- function(x) {
  # extract score
  score_data <- data.frame(
    Solution = rep(seq_along(x@results@summary$Score),
                   each = length(x@data@species$name)),
    Score = rep(x@results@summary$Score,
                each = length(x@data@species$name)))
  # extract amount held
  amount_held_data <- plyr::ldply(
    seq_len(nrow(x@results@summary)),
    function(r) {
      data.frame(Species = x@data@species$name,
                 amount.held = c(raptr::amount.held(x, y = r)))
  })
  # extract space names
  space_names <- sapply(x@data@attribute.spaces, "slot", "name")
  # extract space held
  space_held_data <- plyr::ldply(
    seq_len(nrow(x@results@summary)), function(r) {
      plyr::ldply(x@data@species$name, function(y) {
        raptr::space.held(x, y = r, species = y) %>%
        as.data.frame() %>%
        magrittr::set_names(space_names[r])
      })
  })
  # return data.frame
  score_data %>%
  cbind(amount_held_data, space_held_data)
}
