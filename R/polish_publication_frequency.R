#' @title Polish Publication Frequency
#' @description Harmonize publication frequencies.
#' @param x publication frequency field (a vector) 
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df <- polish_publication_frequency("Kerran vuodessa")}
#' @keywords utilities
polish_publication_frequency <- function(x) {

  # Remove periods  
  x <- condense_spaces(tolower(gsub("\\.$", "", x)))
  x <- gsub("^ca ", "", x)
  x <- gsub("\\?", " ", x)
  x <- gsub("'", " ", x)    
  x <- gsub(" */ *", "/", x)
  x <- gsub("^[0-9]+ s$", "", x)
  x <- condense_spaces(x)

  f <- system.file("extdata/replace_special_chars.csv", package = "fennica")
  spechars <- suppressWarnings(read_mapping(f, sep = ";", mode = "table", include.lowercase = TRUE))
  x <- as.character(map(x, spechars, mode = "match"))

  xorig <- x
  x <- xuniq <- unique(xorig)
  df <- do.call("rbind", lapply(x, polish_publication_frequencies))
  
  # Match to original inds and return
  df[match(xorig, xuniq),]

}
