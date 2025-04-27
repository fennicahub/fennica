# Load necessary library
library(dplyr)

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
all_matching_ids <- c()
all_extracted_ids <- c()

# Read the file in chunks
chunk_size <- 100000  # Adjust as needed
repeat {
  # Read a chunk of lines
  chunk_lines <- readLines(con, n = chunk_size, warn = FALSE)
  
  # Break if end of file is reached
  if (length(chunk_lines) == 0) break
  
  # Extract all IDs from <controlfield tag="001">
  id_lines <- grep('<controlfield tag="001">', chunk_lines, value = TRUE)
  extracted_ids <- gsub(".*<controlfield tag=\"001\">(.*?)</controlfield>.*", "\\1", id_lines)
  
  # Clean up extracted IDs
  extracted_ids <- trimws(extracted_ids)
  extracted_ids <- gsub("[^[:print:]]", "", extracted_ids)
  
  # Store extracted IDs
  all_extracted_ids <- c(all_extracted_ids, extracted_ids)
}

# Close the GZipped file connection
close(con)

# Debugging output: Print the first few extracted IDs
cat("Total extracted IDs:", length(all_extracted_ids), "\n")
cat("First 5 extracted IDs:\n", paste(head(all_extracted_ids, 5), collapse = "\n"), "\n")


# Example list of IDs to search for
velka_not_full_fennica_ids <- c(velka_not_full_fennica_df$melinda_id)
# Step 2: Compare extracted IDs with velka_not_full_fennica_ids
matching_ids <- intersect(velka_not_full_fennica_ids, all_extracted_ids)

# Print results
cat("Total matching melinda_ids found:", length(matching_ids), "\n")
print(matching_ids)

# Unmatching IDs in df.orig but not in all_extracted_ids
unmatching_ids_in_df <- setdiff(velka_not_full_fennica_ids, all_extracted_ids)

# Unmatching IDs in all_extracted_ids but not in df.orig
unmatching_ids_in_all_extracted <- setdiff(all_extracted_ids, velka_not_full_fennica_ids)

# Print results for unmatching IDs
cat("Total unmatching melinda_ids in df.orig:", length(unmatching_ids_in_df), "\n")
print(unmatching_ids_in_df)

cat("Total unmatching melinda_ids in all_extracted_ids:", length(unmatching_ids_in_all_extracted), "\n")
print(unmatching_ids_in_all_extracted)

velka_not_full_fennica_df$title

# Extract title columns from both data frames
titles_velka <- velka_not_full_fennica_df$title
titles_df <- df.orig$title

# Get matching titles
matching_titles <- intersect(titles_velka, titles_df)

# Print the matching titles
cat("Total matching titles found:", length(matching_titles), "\n")
print(matching_titles)


