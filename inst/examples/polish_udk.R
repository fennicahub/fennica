# Load necessary libraries
library(stringi)

polish_udk <- function(x) {
  # Pre-allocate memory for the result
  x0 <- x
  
  # Combine multiple gsub operations into fewer calls for efficiency
  # Replace spaces, colons, pipe characters, and commas with semicolons
  x <- gsub(" ", "", x)
  x <- stri_replace_all_regex(x, "[:|,]", ";")
  
  # Remove all backslashes, forward slashes at the beginning and the end of the string,
  # double quotes, opening parentheses at the beginning of x, occurrences of the letter c at the beginning of x,
  # newline characters, and trailing whitespace at the end of x
  x <- stri_replace_all_regex(x, "\\\\|/^|/$|\"|^\\(+|^c|\n|\\s+$", "")
  
  # Remove the exact string "9FENNI<KEEP>" from x
  x <- stri_replace_all_fixed(x, "9FENNI<KEEP>", "")
  
  # Convert to lowercase and remove duplicates within each element of x
  x <- sapply(strsplit(tolower(x), ";"), function(x) paste(unique(x), collapse = ";"))
  
  # Replace empty strings with NA
  x[x == ''] <- NA
  
  # Load udk names
  udk <- read.csv("udk_monografia.csv", sep = ";", header = FALSE, encoding = "UTF-8")
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
