#polish_signum.R
#Author: Julia Matveeva yulmat@utu.fi

polish_signum <- function(x) {
  # Convert input to character
  x_original <- as.character(x)
  
  # Replace '|' with ';'
  x_harmonized <- gsub("\\|", ";", x_original)
  
  # Process each row safely
  x_harmonized <- lapply(strsplit(x_harmonized, ";"), function(vals) {
    if (is.null(vals) || length(vals) == 0 || all(is.na(vals)) || all(vals == "")) {
      return(NA)  # Convert empty or NA rows to NA
    }
    
    vals <- unique(trimws(vals))  # Keep only unique values and trim whitespace
    vals <- vals[vals != ""]  # Remove empty strings
    
    if (length(vals) == 0) return(NA)  # Convert completely empty cases to NA
    
    paste(vals, collapse = ";")  # Reconstruct the cleaned string
  })
  
  # Convert list back to a character vector
  x_harmonized <- unlist(x_harmonized)
  
  # Create a data frame with original and harmonized values
  df <- data.frame(
    x_original = x_original,
    x_harmonized = x_harmonized,
    stringsAsFactors = FALSE
  )
  
  return(df)
}

