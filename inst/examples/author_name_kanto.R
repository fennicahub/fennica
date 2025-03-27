authors_df <- finto::get_kanto(df.orig) %>%
  rename(author_name = prefLabel)
field <- "author_name"
# Step 1: Remove duplicates by author_ID
df.orig <- authors_df %>%
  distinct(author_ID, .keep_all = TRUE) %>%
  select(author_ID = author_ID, author_name)

# Step 2: Polish author names
field <- "author_name"
author <- polish_author(df.orig[[field]], verbose = TRUE)

# Step 3: Create harmonized data frame
df.tmp <- data.frame(
  author_ID = df.orig$author_ID,
  author_name = author,
  stringsAsFactors = FALSE
)

# Step 4: Add to harmonized master
df.harmonized <- cbind(df.orig, author_name_harmonized = df.tmp$author_name)

# -------------------------------
# Save and summarize

output.folder <- "output.tables/"
if (!dir.exists(output.folder)) dir.create(output.folder)

# Save as RDS
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# Save as CSV
write.table(df.tmp, file = file.path(output.folder, paste0(field, "_kanto.csv")),
            quote = FALSE, row.names = FALSE)

# -------------------------------
# Summary of results
file_accepted  <- file.path(output.folder, paste0(field, "_kanto_accepted.csv"))
file_discarded <- file.path(output.folder, paste0(field, "_kanto_discarded.csv"))

message("Accepted entries in the preprocessed data")
write_xtable(df.tmp[[field]], file_accepted, count = TRUE)

message("Discarded entries in the original data")
inds <- which(is.na(df.tmp[[field]]))
original.na <- df.orig[match(df.tmp$author_ID[inds], df.orig$author_ID), field]
write_xtable(original.na, file_discarded, count = TRUE)
