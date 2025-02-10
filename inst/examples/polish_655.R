#author Julia Matveeva yulmat@utu.fi

polish_genre_655 <- function(x, chunk_size = 1000) {
  # Split the input vector into chunks
  chunks <- split(x, ceiling(seq_along(x) / chunk_size))
  
  process_chunk <- function(chunk) {
    # Remove dots and perform harmonization in each chunk
    chunk <- gsub("\\.", "", as.character(chunk))  # Remove dots from chunk
    
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
    
    harmonized <- sapply(chunk, remove_duplicates)  # Apply function to the chunk
    return(harmonized)
  }
  
  # Apply the processing to each chunk and combine the results
  harmonized_results <- unlist(lapply(chunks, process_chunk))
  
  # Return the final data frame
  df <- data.frame(
    original = x,
    harmonized = harmonized_results
  )
  
  return(df)
}


 