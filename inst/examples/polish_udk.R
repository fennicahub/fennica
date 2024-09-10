

polish_udk <- function(x) {
  # Optimized clean_string function for vectorized processing
  clean_string <- function(input_strings, symbols = c(" ", "-", "[", "/", "|", "\\", "\"", ".")) {
    
    # Collapse symbols into a single string with proper escaping for regex
    pattern <- paste0("\\", symbols, collapse = "")
    
    # Vectorized cleaning: remove symbols from edges and redundant spaces
    cleaned_strings <- str_remove_all(input_strings, paste0("^[", pattern, "]+|[", pattern, "]+$"))
    
    return(cleaned_strings)
  }
  
  # Apply the clean_string function to the entire vector
  x <- clean_string(x)
  
  # Split, deduplicate, and rejoin in a vectorized manner
  x_split <- strsplit(x, "\\|") # Split strings by "|"
  
  # Deduplicate within each component (vectorized using lapply and unique)
  x_dedup <- sapply(x_split, function(components) paste(unique(components), collapse = "|"))
  
  # Remove remaining spaces and replace empty strings with NA
  x_final[x_final == ""] <- NA
  
  # Output the cleaned result
  x <- x_final
  x <- gsub("\\|", ";", x)
  
  # Load udk names
  udk <- read.csv("udk.csv", sep = ";", header = FALSE, encoding = "UTF-8")
  colnames(udk) <- c("synonyme", "name")
  
  df <- data.frame(original = x0, cleaned = x)
  
  # Function to match and concatenate names, including undetermined and handling NA
  match_and_concatenate <- function(value) {
    if (is.na(value)) {
      return(NA)
    }
    
    split_value <- strsplit(value, ";")[[1]]
    converted_values <- c()
    
    for (val in split_value) {
      match_index <- match(val, udk$synonyme)
      if (!is.na(match_index)) {
        converted_values <- c(converted_values, udk$name[match_index])
      } else {
        converted_values <- c(converted_values, "Undetermined")
      }
    }
    
    return(paste(converted_values, collapse = ";"))
  }
  
  # Apply the function to each element of x to get df$converted
  
  df$converted <- sapply(x, match_and_concatenate)
  
  # Split values for further processing
  split_values <- strsplit(df$cleaned, ";")
  
  # Create a data frame for further analysis
  xu <- data.frame(unlist(split_values))
  xu2 <- data.frame(unlist(strsplit(df$converted, ";")))
  
  f <- data.frame(c = xu, h = xu2)
  colnames(f) <- c("udk", "explanation")
  f$explanation <- as.character(f$explanation)
  
  # Filter for undetermined and accepted values
  undetermined <- filter(f, f$explanation == "Undetermined")
  accepted <- filter(f,f$explanation != "Undetermined")
  
  # Return the results
  return(list(full = df, undetermined = undetermined, accepted = accepted))
}
