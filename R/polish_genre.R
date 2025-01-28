#' @title Polish Genre Book 
#' @description Polish genre field 008/33, see 008_field.R for "Language material" #https://marc21.kansalliskirjasto.fi/bib/008.htm#BK
#' @param x Vector of genres
#' @return Vector of titles polished
#' @export
#' @details Remove ending commas, periods, spaces and parentheses, 
#' 	    starting prepositions etc.
#' @author  Julia Matveeva \email{yulmat@utu.fi}
#' @references See citation("fennica")
#' @examples \dontrun{x2 <- polish_genre_book(x)}
#' @keywords utilities
#' 

polish_genre_book <- function(x) {
  x0 <- x
  # Define the mapping
  mapping <- c(
    "0" = "Tietokirjallisuus",
    "1" = "Kaunokirjallisuus",
    "d" = "Draama",
    "e" = "Esseet",
    "f" = "Romaanit",
    "h" = "Huumori, satiiri jne.",
    "i" = "Kirjeet",
    "j" = "Novellit, kertomukset tai niiden kokoelmat",
    "m" = "Yhdistelmä",
    "p" = "Runot",
    "s" = "Puheet, esitelmät",
    "u" = "Tuntematon",
    "|" = "Ei koodattu"
  )
  
  # Harmonize genres with conditions
  genre_harmonized <- ifelse(
    is.na(x), NA, # Keep NA as NA
    ifelse(
      x == "Not a book", "Not a book", # Keep "Not a book" as-is
      ifelse(
        x %in% names(mapping), mapping[x], "Undetermined" # Map or default to "Undetermined"
      )
    )
  )
  
  # Return a data frame
  df <- data.frame(
    genre_original = x0,
    genre_harmonized = genre_harmonized,
    stringsAsFactors = FALSE
  )
  
  return(df)
}

