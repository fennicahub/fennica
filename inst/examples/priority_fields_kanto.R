
# Load parquet file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/fennica_kanto_enriched.parquet"
df.kanto <- read_parquet(url)

# Prepare df.kanto
df.kanto <- df.kanto %>%
  mutate(
    author_profession_kanto_fi = profession_metadata_profession_prefLabel_fi,
    author_date_kanto = case_when(
      !is.na(birthDate) & !is.na(deathDate) ~ paste0(birthDate, "-", deathDate),
      !is.na(birthDate) ~ as.character(birthDate),
      !is.na(deathDate) ~ as.character(deathDate),
      TRUE ~ NA_character_
    ),
    author_name_kanto = case_when(
      !is.na(prefLabel) & !is.na(altLabel) ~ paste(prefLabel, altLabel, sep = "|"),
      !is.na(prefLabel) ~ prefLabel,
      !is.na(altLabel) ~ altLabel,
      TRUE ~ NA_character_
    )
  )

# Columns to keep
columns_to_keep <- c("melinda_id", "prefLabel", "altLabel", "variantName", "hiddenLabel", "authorizedAccessPoint", "note","author_date_kanto", "author_profession_kanto_fi")

# Filter to required columns
df.kanto <- df.kanto %>% select(all_of(columns_to_keep)) #%>% distinct()



