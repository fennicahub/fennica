
# Load parquet file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/fennica_kanto_enriched.parquet"
df.kanto <- read_parquet(url)

df.kanto <- df.kanto %>%
  mutate(author_profession_kanto_fi = profession_metadata_profession_prefLabel_fi)

# Columns to keep
columns_to_keep <- c("melinda_id", "prefLabel", "altLabel", "variantName", "hiddenLabel", "authorizedAccessPoint", "note","birthDate", "deathDate", "author_profession_kanto_fi")

# Filter to required columns
df.kanto <- df.kanto %>% select(all_of(columns_to_keep)) #%>% distinct()



