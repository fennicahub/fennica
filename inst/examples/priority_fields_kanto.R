library(arrow)
library(dplyr)

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/fennica_enriched.parquet"
url <- "fennica_enriched.parquet"

df.kanto <- read_parquet(url)

df.kanto <- df.kanto %>%
  mutate(author_profession_kanto_fi = profession_metadata_profession_prefLabel_fi)
colnames(df.kanto)

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
  "profession",                                   
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


