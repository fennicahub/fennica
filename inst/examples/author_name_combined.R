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
