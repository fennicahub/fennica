
x <- df.orig$`080x`
polish_080_x <- function(x) {
  x0 <- x
  # Function to remove duplicates and rejoin the values
  remove_duplicates <- function(x) {
    unique_values <- unique(strsplit(x, "\\|")[[1]])  # Split by '|' and remove duplicates
    paste(unique_values, collapse = "|")  # Rejoin with '|'
  }
  
  # Apply the function to the 'orig' column
  df$harmonize <- sapply(df$orig, remove_duplicates)
  

  df <- data.frame(
    original = x0,
    harmonized = paste(unique_values, collapse = "|")
  )
  
  return(unique_values)
}
