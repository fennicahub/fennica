polish_udk_aux <- function(x) {
  x0 <- x
  
  # Function to remove duplicates and rejoin the values
  remove_duplicates <- function(x) {
    if (is.na(x) || x == "") return(NA)  # Convert empty values to NA
    unique_values <- unique(strsplit(x, "\\|")[[1]])  # Split by '|' and remove duplicates
    paste(unique_values, collapse = "|")  # Rejoin with '|'
  }
  
  # Apply the function to the input
  harmonized <- sapply(x0, remove_duplicates)
  
  return(harmonized)
}

