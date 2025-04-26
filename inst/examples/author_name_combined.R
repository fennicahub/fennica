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
write.csv(author_name_combined, "output.tables/author_name_combined.csv", row.names = FALSE)

#############################
###########################


field <- "author_name"
# Define output folder if not defined earlier
output.folder <- "output.tables/"

# Define output file paths
file_accepted  <- paste0(output.folder, field, "_combined_accepted.csv")
file_discarded <- paste0(output.folder, field, "_combined_discarded.csv")

# Generate data summaries for the whole data set

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df.tmp[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

# These are the "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)

###################################


# Filter to subset of interest
df_combined_19 <- author_name_combined[author_name_combined$melinda_id %in% melindas_19, ]

# Set field name
field <- "author_name"

# Save as .Rds with the field name
data.file <- paste0(field, ".Rds")
saveRDS(df_combined_19, file = data.file)

# Generate markdown summary
df_combined_19 <- readRDS(data.file)

# Define output files for the 1807–1917 subset
file_accepted_19  <- paste0(output.folder, field, "_combined_accepted_19.csv")
file_discarded_19 <- paste0(output.folder, field, "_combined_discarded_19.csv")


message("Accepted entries in the preprocessed data for 1809-1917")
s <- write_xtable(df_combined_19[[field]], file_accepted_19, count = TRUE)

message("Discarded entries for 1809-1917")
inds <- which(is.na(df_combined_19[[field]]))
original.na <- df.orig[match(df_combined_19$melinda_id[inds], df.orig$melinda_id), field]
tmp19 <- write_xtable(original.na, file_discarded_19, count = TRUE)
