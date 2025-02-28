#polish publication times from field 008
#author = Julia Matveeva 

x <- head(df.orig$)
polish_years_008 <- function(x) {
  # Save the original column as x0 for reference
  x0 <- x
  
  # Get the current year
  current_year <- as.numeric(format(Sys.Date(), "%Y"))
  
  # Create publication_year_from and publication_year_till
  from <- ifelse(
    grepl(" ", x),  # Check if there are two dates
    as.numeric(substr(x, start = 1, stop = 4)),  # Extract first year
    as.numeric(x)  # Use the single year if no space
  )
  
  till <- ifelse(
    grepl(" ", x),  # Check if there are two dates
    as.numeric(substr(x, start = 6, stop = nchar(x))),  # Extract second year
    NA  # If no second year, assign NA
  )
  
  # Apply the conditions
  # 1. If 'from' > 'till', set both to NA
  invalid_order <- !is.na(from) & !is.na(till) & (from > till)
  from[invalid_order] <- NA
  till[invalid_order] <- NA
  
  # 2. If 'from' > current_year, set it to NA
  from_invalid <- !is.na(from) & from > current_year
  from[from_invalid] <- NA
  
  # 3. If 'till' > current_year, set it to NA
  till_invalid <- !is.na(till) & till > current_year
  till[till_invalid] <- NA
  
  # Create publication_year (first date)
  publication_year <- from
  
  # Create publication_decade_original (first year rounded down to nearest decade)
  decade <- ifelse(
    !is.na(publication_year),
    floor(publication_year / 10) * 10,  # Round down to the nearest decade
    NA
  )
  
  # Combine all columns into the output dataframe
  out <- data.frame(
    original = x0,  # Original column
    from = from,
    till = till,
    publication_year = publication_year,
    decade = decade
  )
  
  # Return the resulting dataframe
  return(out)
}
