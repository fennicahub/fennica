library(arrow)
library(dplyr)

# NOTE:
# The parquet file used here (fennica_enriched.parquet) is created in the script:
# kanto_enrichment.R. That script is responsible for extracting, enriching,
# and exporting Kanto authority data into parquet format.
#
# This script only reads the prepared parquet file and selects relevant fields
# for further processing.
#
# Commenting and explanatory notes were generated with the assistance
# of AI and further refined and validated by Julia Matveeva.

# source("kanto_enrichment.R")

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/fennica_enriched.parquet"

df.kanto <- read_parquet(url)

df.kanto <- df.kanto %>%
  mutate(author_profession_kanto_fi = profession_metadata_profession_prefLabel_fi)

columns_to_keep <- c(
  "asteri_id",
  "prefLabel",
  "altLabel",
  "variantName",
  "fullerFormOfName",
  "hiddenLabel",
  "authorizedAccessPoint",
  "note",                                          
  "birthDate",                                    
  "deathDate", 
  "birthPlace",                                  
  "deathPlace", 
  "title", 
  "language",
  "relatedPersonOfPerson",
  "country",
  "relatedPerson",
  "placeAssociatedWithPerson",
  "fieldOfActivityOfPerson",
  "profession_metadata_profession_prefLabel_fi"
)

df.kanto <- df.kanto %>%
  dplyr::select(dplyr::all_of(columns_to_keep))