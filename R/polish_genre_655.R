polish_genre_655 <- function(x) {
  x0 <- x
  x <- gsub("\\.", "", as.character(x))  # Ensure x is treated as a character and remove dots
  
  # Load the genre-language mapping
  genre_lang_df <- read.csv("genre_655.csv", sep = ";", stringsAsFactors = FALSE)
  
  # Function to remove duplicates, capitalize first letter, and rejoin the values
  remove_duplicates <- function(x) {
    if (is.na(x) || x == "") return(NA)  # Convert empty values to NA
    unique_values <- unique(strsplit(x, "\\|")[[1]])  # Split by '|', remove duplicates
    unique_values <- sapply(unique_values, function(val) {
      val <- trimws(val)  # Remove leading/trailing spaces
      paste0(toupper(substring(val, 1, 1)), substring(val, 2))  # Capitalize the first letter
    })
    paste(unique_values, collapse = "; ")  # Rejoin with '; '
  }
  
  # Apply the function to the input
  harmonized <- sapply(x, remove_duplicates)  # Apply on x, not x0
  
  # Function to determine languages
  assign_languages <- function(genre_list) {
    if (is.na(genre_list)) return(c(NA, NA, NA))  # If NA, return NA for all languages
    genres <- unlist(strsplit(genre_list, "; "))  # Split by '; ' to get individual genres
    
    # Check which languages exist for each genre
    finnish <- swedish <- english <- NA
    for (genre in genres) {
      lang <- genre_lang_df$language[match(genre, genre_lang_df$genre)]
      if (!is.na(lang)) {
        if (lang == "Finnish") finnish <- ifelse(is.na(finnish), genre, paste(finnish, genre, sep = "; "))
        if (lang == "Swedish") swedish <- ifelse(is.na(swedish), genre, paste(swedish, genre, sep = "; "))
        if (lang == "English") english <- ifelse(is.na(english), genre, paste(english, genre, sep = "; "))
      }
    }
    return(c(finnish, swedish, english))
  }
  
  # Assign languages based on harmonized genres
  lang_matrix <- t(sapply(harmonized, assign_languages))
  
  df <- data.frame(
    original = x0,
    harmonized = harmonized,
    finnish = lang_matrix[,1],
    swedish = lang_matrix[,2],
    english = lang_matrix[,3],
    stringsAsFactors = FALSE
  )
  
  return(df)
}