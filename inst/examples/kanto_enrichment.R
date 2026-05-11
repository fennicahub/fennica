library(dplyr)
library(readr)
library(stringr)
library(finto)
library(arrow)


# Step 1. load author_id from df.orig 
source("priority_fields.R")

library(dplyr)
library(tidyr)
library(stringr)
library(arrow)

# 1. collect all Asteri IDs from 100 and 700 fields
fennica_asteri <- df.orig %>%
  transmute(
    author_id = as.character(author_id),
    added_author_id = as.character(added_author_id)
  ) %>%
  pivot_longer(
    cols = c(author_id, added_author_id),
    names_to = "source_field",
    values_to = "asteri_raw"
  ) %>%
  filter(!is.na(asteri_raw), asteri_raw != "") %>%
  separate_rows(asteri_raw, sep = "\\|") %>%
  mutate(
    asteri_id = str_trim(asteri_raw),
    asteri_id = str_remove(asteri_id, "^\\(FI-ASTERI-N\\)\\s*"),
    author_ID = str_extract(asteri_id, "\\d{9}")
  ) %>%
  filter(!is.na(author_ID), author_ID != "") %>%
  distinct(author_ID, .keep_all = TRUE)

# 2. IDs only for Kanto
author_ids_clean <- fennica_asteri %>%
  select(author_ID) %>%
  distinct()

# 3. get Kanto metadata
authors_df <- finto::get_kanto(author_ids_clean)

# 4. remove duplicate Kanto rows if needed
authors_df_clean <- authors_df %>%
  distinct(author_ID, .keep_all = TRUE)

# 5. join Kanto metadata back to Fennica Asteri IDs
merged_data <- fennica_asteri %>%
  left_join(authors_df_clean, by = "author_ID")

# 6. save
arrow::write_parquet(
  merged_data,
  "fennica_enriched.parquet",
  compression = "zstd"
)