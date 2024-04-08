
#' @title Polish Title
#' @description Polish the title field.
#' @param x Vector of titles
#' @return Vector of titles polished
#' @export
#' @details Remove ending commas, periods, spaces and parentheses, 
#' 	    starting prepositions etc.
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("fennica")
#' @examples \dontrun{x2 <- polish_title(x)}
#' @keywords utilities
polish_title <- function (x) {
  
  x0 <- x
  x <- as.character(x)
  x <- unique(x)
  xinds <- match(x0, x)
  
  x <- gsub("\\,$", "", x) # Remove commas at the end
  x <- gsub("[ ]+$", "", x) # Remove trailing spaces
  x <- gsub("\\]$", "", x) # Remove closing square brackets at the end
  x <- gsub("^\\[", "", x) # Remove opening square brackets at the start
  x <- gsub("^\\(", "", x) # Remove opening parentheses at the start
  x <- gsub("\\:+$", "", x) # Remove colon at the end
  x <- gsub("^\\:", "", x) # Remove colon at the start
  x <- gsub("\\;+$", "", x) # Remove semicolon at the end
  x <- gsub("/", "", x)
  x <- gsub("=", "", x)
  x <- str_replace_all(x, "\\|", "") # Remove pipe characters
  x <- str_replace_all(x, "\\/", "") # Remove slashes
  x <- gsub("\\s+$", "", x)
  x <- gsub("^\\s+", "", x)
  x <- gsub('"', "", x, fixed=TRUE) # Corrected line to remove double quotes
  
  # Capitalize the first letter of words
  x <- gsub("^a", "A", x)
  x <- gsub("^the", "The", x)
  
  # Remove periods 
  x <- gsub("\\.+$", "", as.character(x))
  x <- gsub("\\. $", "", as.character(x))
  x <- gsub("^\\.+", "", as.character(x))
  x <- gsub("^\\.+", "", as.character(x))
  
  
  x[x == ""] <- NA
  
  # Map back to originals
  x <- x[xinds]
  
  x
}
