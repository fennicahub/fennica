library(arrow)
library(dplyr)

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/fennica_kanto_enriched.parquet"

df.kanto <- read_parquet(url)

df.kanto <- df.kanto %>%
  mutate(author_profession_kanto_fi = profession_metadata_profession_prefLabel_fi)

columns_to_keep <- c(
  "melinda_id", "prefLabel", "altLabel",
  "variantName", "fullerFormOfName",
  "authorizedAccessPoint", "relatedPersonOfPerson_prefLabel",
  "note", "birthDate", "deathDate",
  "author_profession_kanto_fi"
)

df.kanto <- df.kanto %>%
  dplyr::select(dplyr::all_of(columns_to_keep))
