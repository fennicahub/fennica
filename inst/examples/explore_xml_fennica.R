# Load necessary libraries
library(dplyr)

# Example list of IDs to search for, including the two provided IDs
velka_not_full_fennica_ids <- c("004046084", "001924068", velka_not_full_fennica_df$melinda_id)  # Add actual data here
velka_not_full_fennica_ids <- c(head(df.orig$melinda_id,100))

# Step 2: Open the GZipped file for reading using gzcon
con <- gzcon(file("fennica.xml.zip", "rb"))

# Step 3: Create a connection to the temporary file to store the matching IDs
matching_ids_file <- tempfile()  # Create a temporary file for storing matching IDs
matching_ids_con <- file(matching_ids_file, "w")  # Open file for writing

# Clean up velka_not_full_fennica_ids
velka_not_full_fennica_ids <- velka_not_full_fennica_ids[!is.na(velka_not_full_fennica_ids) & velka_not_full_fennica_ids != ""]
velka_not_full_fennica_ids <- trimws(velka_not_full_fennica_ids)  # Trim whitespace
velka_not_full_fennica_ids <- gsub("[^[:print:]]", "", velka_not_full_fennica_ids)  # Remove non-printable chars

# Step 4: Read the file in chunks (by line) and process matching IDs
chunk_size <- 10000  # Adjust chunk size as needed
all_matching_ids <- c()

repeat {
  # Read a chunk of lines
  chunk_lines <- readLines(con, n = chunk_size, warn = FALSE)
  
  # Break if we've reached the end of the file
  if (length(chunk_lines) == 0) break
  
  # Process the chunk to find <controlfield tag="001"> entries
  id_lines <- grep('<controlfield tag="001">', chunk_lines, value = TRUE)
  
  # Extract the ID from the <controlfield tag="001"> lines and clean up spaces
  extracted_ids <- gsub(".*<controlfield tag=\"001\">(.*?)</controlfield>.*", "\\1", id_lines)
  extracted_ids <- trimws(extracted_ids)  # Remove leading/trailing spaces
  extracted_ids <- gsub("[^[:print:]]", "", extracted_ids)  # Remove non-printable characters
  
  # Debugging output: Print the first few extracted IDs to check
  cat("Extracted IDs (first 5):\n", paste(extracted_ids[1:5], collapse = "\n"), "\n")
  
  # Find matching IDs
  matching_ids <- intersect(velka_not_full_fennica_ids, extracted_ids)
  
  # Write the matching IDs directly to the file
  write(matching_ids, matching_ids_con, append = TRUE)
  
  # Optionally print progress
  cat("Processed", length(all_matching_ids) + length(matching_ids), "matches so far...\n")
}

# Step 5: Close the connection and matching IDs file
close(con)  # Close the GZipped file connection
close(matching_ids_con)  # Close the matching IDs file connection

# Step 6: Read the matching IDs from the file (if needed)
matching_ids <- readLines(matching_ids_file)

# Step 7: Print the final matching IDs
cat("Total matching melinda_ids found:", length(matching_ids), "\n")
print(matching_ids)

# Step 8: Clean up the temporary files
unlink(downloaded_file)
unlink(matching_ids_file)



