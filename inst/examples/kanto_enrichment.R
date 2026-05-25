library(devtools)
library(dplyr)
library(tidyr)
library(tm)
library(stringr)
library(knitr)
library(R.utils)
library(ggplot2)
library(Cairo)
library(purrr)
library(stringi)
library(parallel)
library(qdapRegex)
library(readxl)
library(arrow)
library(textutils)
library(data.table)
library(brms)
library(rnaturalearth)

# Install latest version from Github
# install_github("fennicahub/fennica") # or
# devtools::load_all() # if you are working from the clone and modifying it
library(fennica)

# Load misc functions needed for harmonization
source("funcs.R")
# Step 1. load author_id from df.orig 
source("priority_fields.R")

# collect all Asteri IDs from both df.orig and df_700
fennica_asteri <- bind_rows(
  df.orig %>% transmute(asteri_raw = as.character(asteri_id)),
  df.orig %>% transmute(asteri_row = as.character(added_id))
) %>%
  filter(!is.na(asteri_raw), asteri_raw != "") %>%
  separate_rows(asteri_raw, sep = "\\|") %>%
  mutate(
    asteri_id = clean_id(asteri_raw),
    author_ID = str_extract(asteri_id, "\\d+")
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