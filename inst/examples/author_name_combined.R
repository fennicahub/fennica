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
  rename(combined_author_name = author_name_kanto)

author_name_fennica <- author_name_fennica %>%
  rename(combined_author_name = author_name)

# Ensure same type for joining
author_name_fennica <- author_name_fennica %>%
  mutate(melinda_id = as.character(melinda_id))

author_name_kanto <- author_name_kanto %>%
  mutate(melinda_id = as.character(melinda_id))

author_name_combined <- full_join(
  author_name_fennica,
  author_name_kanto,
  by = c("melinda_id", "combined_author_name")
)

# Save result
write.table(author_name_combined, "output.tables/combined_author_name.csv", sep = ",", row.names = FALSE, quote = FALSE)

##################################################################


# Define field and save harmonized data
field <- "combined_author_name"
df.tmp <- author_name_combined
df.orig <- author_name_combined # define original

data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# Read back
df <- readRDS(data.file)

# ---Summaries for Full Dataset ---

file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE)

message("Discarded entries in the original data")

# Find discarded entries (those that became NA)
inds <- which(is.na(df.tmp[[field]]))
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

tmp <- write_xtable(original.na, file_discarded, count = TRUE)

# ---Summaries for 19th Century Subset ---
df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]

data.file_19 <- paste0(field, "_19.Rds")
saveRDS(df_19, file = data.file_19)

df_19 <- readRDS(data.file_19)

file_accepted_19  <- paste0(output.folder, field, "_accepted_19.csv")
file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")

message("Accepted entries in the preprocessed data for 1809-1917")
s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)

message("Discarded entries for 1809-1917")

inds <- which(is.na(df_19[[field]]))
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]

tmp19 <- write_xtable(original.na, file_discarded_19, count = TRUE)
