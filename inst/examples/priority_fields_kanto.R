
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/fennica_kanto_enriched.parquet"

df.orig <- read_parquet(url)

# Step 2: Rename & reformat
df.orig <- df.orig %>%
  mutate(author_name_kanto = case_when(
    !is.na(prefLabel) & !is.na(altLabel) ~ paste(prefLabel, altLabel, sep = ", "),
    !is.na(prefLabel) ~ prefLabel,
    !is.na(altLabel) ~ altLabel,
    TRUE ~ NA_character_
  ))
df.orig <- df.orig %>% distinct()



