library(arrow)
library(dplyr)

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/fennica_enriched.parquet"

df.kanto <- read_parquet(url)

df.kanto <- df.kanto %>%
  mutate(author_profession_kanto_fi = profession_metadata_profession_prefLabel_fi)

columns_to_keep <- c(
  "melinda_id", "prefLabel", "altLabel",
  "variantName", "fullerFormOfName",
  "authorizedAccessPoint", 
  "note", "birthDate", "deathDate", "hiddenLabel",
  "author_profession_kanto_fi"
)

df.kanto <- df.kanto %>%
  dplyr::select(dplyr::all_of(columns_to_keep))

df.orig$author_name_kanto1 <- df.kanto$prefLabel
df.orig$author_name_kanto2 <- df.kanto$altLabel
df.orig$author_name_kantoVAR <- df.kanto$variantName
df.orig$hidden_kanto <- df.kanto$hiddenLabel
df.orig$access_kanto <- df.kanto$authorizedAccessPoint
df.orig$note_kanto <- df.kanto$note
df.orig$fuller_first <- df.kanto$fullerFormOfName


df.orig$author_birth_date_kanto <- df.kanto$birthDate
df.orig$author_death_date_kanto <- df.kanto$deathDate
df.orig$author_profession <- df.kanto$author_profession_kanto_fi
df.orig <- df.orig %>%
  mutate(
    author_id = na_if(added_author_id, ""),           # Convert "" to NA
    author_id_700 = na_if(added_author_id, ""),   # Convert "" to NA
    asteri = coalesce(author_id, author_id) # Use author_id, fallback to author_id_700
  )
