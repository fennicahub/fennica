# Read CSVs
author_name_fennica <- read.csv(
  "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_name.csv",
  header = TRUE,
  sep = ";",
  check.names = TRUE,
  stringsAsFactors = FALSE
)

author_name_kanto <- read.csv(
  "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_name_kanto.csv",
  header = TRUE,
  sep = ";",
  check.names = TRUE,
  stringsAsFactors = FALSE
)
# Standardize column names
author_name_kanto <- author_name_kanto %>%
  rename(author_name = author_name_kanto)

# Ensure same type for joining
author_name_fennica <- author_name_fennica %>%
  mutate(melinda_id = as.character(melinda_id))

author_name_kanto <- author_name_kanto %>%
  mutate(melinda_id = as.character(melinda_id))

author_name_combined <- full_join(
  author_name_fennica,
  author_name_kanto,
  by = c("melinda_id", "author_name")
)

# Save result
write.table(author_name_combined, "output.tables/author_name_combined.csv", sep = ",", row.names = FALSE, quote = FALSE)

#--------------------


field <- "author_name"

# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
# Generate markdown summary
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE, sep = ";", row.names = FALSE)

##################################################################

# Define output files for the whole dataset
file_accepted  <- paste0(output.folder, field, "_combined_accepted.csv")
file_discarded <- paste0(output.folder, field, "_combined_discarded.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df.tmp[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)


# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "author_name"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Generate markdown summary
df_19 <- readRDS(data.file)


# Define output files for the 1807-1917 subset
file_accepted_19  <- paste0(output.folder, field, "_combined_accepted_19.csv")
file_discarded_19 <- paste0(output.folder, field, "_combined_discarded_19.csv")

# ------------------------------------------------------------

# Generate data summaries for 1809-1917
message("Accepted entries in the preprocessed data for 1809-1917")
s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)

message("Discarded entries for 1809-1917")

# NA values in the final harmonized data
inds <- which(is.na(df_19[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp19 <- write_xtable(original.na, file_discarded_19, count = TRUE)



