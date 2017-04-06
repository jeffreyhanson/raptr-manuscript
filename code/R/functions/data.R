#' WGS1984 CRS
#'
#' This object stores the coordinate reference system (CRS) for latitude/longitude data (WGS1984).
#'
#' @seealso \code{\link[sp]{CRS}}
#' @examples
#' wgs1984
wgs1984 <- sp::CRS("+init=epsg:4326")

#' Europe Lambert Conformal Conic CRS
#'
#' This object stores the equal-area coordinate reference system (CRS) for the Europe Lambert Conformal Conic projection.
#'
#' @seealso \code{\link[sp]{CRS}}
#' @examples
#' europe_ea
europe_ea <- sp::CRS("+init=esri:102014")

#' Europe Equidistant Conic
#'
#' This object stores the equi-distant coordinate reference system (CRS) for the  projection.
#'
#' @seealso \code{\link[sp]{CRS}}
#' @examples
#' europe_ed
europe_ed <- sp::CRS("+init=esri:102031")
