library(arrow)
library(dplyr)
library(stringr)

# NOTE:
# The priority fields dataset (priority_fields_062026.parquet) is generated
# through preprocessing scripts in the "field_picking" folder. The main script,
# pick_fields.py, extracts and structures MARC fields for downstream analysis.
# This script reads the prepared Parquet file and performs further cleaning
# and harmonisation. Comments were generated with AI assistance and validated
# by Julia Matveeva.

library(arrow)
library(dplyr)

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/priority_fields_062026.parquet"

df.orig <- arrow::read_parquet(url)

names(df.orig) <- c(
  "fikka_id", "id", "leader", "field_008", "other_system_id",
  "author_name", "author_date", "language_work", "asteri_id",
  "language_041", "language_original",
  "title_uniform", "title", "title_remainder", "title_part_number",
  "publication_place", "publisher", "publication_place_264",
  "physical_dimensions", "physical_extent",
  "publication_frequency", "publication_dates",
  "UDC", "UDC_aux", "genre_655", "subject_650", "note_500",
  "content_type_336", "contents_505", "summary_520",
  "variant_title_246", "series_490", "dissertation_note_502",
  "title_uniform_130", "corporate_author_110", "event_author_111"
)
df.orig <- df.orig[, !is.na(names(df.orig)), drop = FALSE]
df.orig <- slice(df.orig, -(1:2))

df.orig <- df.orig %>%
  filter(!if_all(everything(), ~ is.na(.) | trimws(as.character(.)) == "")) %>%
  distinct() %>%
  mutate(
    fikka_id = as.character(fikka_id),
    id = as.character(id),
    title2 = paste(title, "|", title_remainder),
    physical_dimensions = na_if(trimws(physical_dimensions), ""),
    asteri_id = clean_id(asteri_id),
    asteri_id = str_trim(asteri_id),
    asteri_id = na_if(asteri_id, ""),
    asteri_id = str_remove(asteri_id, "^\\(FI-ASTERI-N\\)\\s*"),
    asteri_id = str_extract(asteri_id, "\\d{9}")
  )

