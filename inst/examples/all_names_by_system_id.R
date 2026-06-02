library(dplyr)
library(stringr)

# ------------------------------------------------------------
# Build names_database from MARC 100 and enriched MARC 700 data
#
# Purpose:
# - create one record-level database of authors
# - use MARC 100 as the main author field
# - fill missing 100 Asteri IDs when the same author_name + birth year
#   has exactly one known Asteri ID elsewhere in the data
# - add already processed MARC 700 author names and Asteri IDs

# NOTE:
# The MARC 700 data used here (df_700_by_record) is created separately.
# To inspect or reproduce it, refer to the script: 700_authors.R
# This script contains the full workflow for extracting, cleaning,
# and aggregating MARC 700 author names and Asteri IDs.
#
# Commenting and explanatory notes were generated with the assistance
# of AI and further refined and validated by Julia Matveeva.
# ------------------------------------------------------------

# source("priority_fields.R") to get df.orig

# Start from the original Fennica data
df <- df.orig

df$asteri_id <- clean_id(df$asteri_id)

# Keep only the columns needed for the MARC 100 author database
df_100_raw <- data.frame(
  id1         = df$melinda_id,
  author_name = df$author_name,
  asteri_id   = df$asteri_id,
  date        = df$author_date,
  stringsAsFactors = FALSE
)


# Harmonise author dates and author names
date_clean <- polish_author_years(df_100_raw$date)
name_clean <- polish_author(df_100_raw$author_name)
rownames(name_clean) <- NULL


# Create cleaned MARC 100 table
df_100 <- data.frame(
  id1         = df_100_raw$id1,
  author_name = name_clean$full_name,
  asteri_id   = df_100_raw$asteri_id,
  date        = date_clean$from,
  stringsAsFactors = FALSE
)


# Standardise empty strings as NA
df_100 <- df_100 %>%
  mutate(
    author_name = na_if(trimws(as.character(author_name)), ""),
    asteri_id   = na_if(trimws(as.character(asteri_id)), ""),
    date        = na_if(trimws(as.character(date)), "")
  )


# Find cases where the same author_name + birth year has:
# - at least one row with an Asteri ID
# - at least one row without an Asteri ID
#
# These are candidates for filling missing IDs.
df_100_name_date_candidates <- df_100 %>%
  filter(!is.na(author_name), !is.na(date)) %>%
  group_by(author_name, date) %>%
  summarise(
    n_with_id     = sum(!is.na(asteri_id)),
    n_without_id  = sum(is.na(asteri_id)),
    n_unique_ids  = n_distinct(asteri_id, na.rm = TRUE),
    ids           = paste(sort(unique(na.omit(asteri_id))), collapse = "; "),
    .groups = "drop"
  ) %>%
  filter(n_with_id > 0, n_without_id > 0)


# Keep only safe cases:
# same author_name + birth year maps to exactly one Asteri ID.
df_100_name_date_lookup <- df_100_name_date_candidates %>%
  filter(n_unique_ids == 1) %>%
  select(author_name, date, inferred_asteri_id = ids)


# Fill missing MARC 100 Asteri IDs using the safe lookup
df_100_filled <- df_100 %>%
  left_join(df_100_name_date_lookup, by = c("author_name", "date")) %>%
  mutate(
    asteri_id = if_else(
      is.na(asteri_id) & !is.na(inferred_asteri_id),
      inferred_asteri_id,
      asteri_id
    )
  ) %>%
  select(-inferred_asteri_id)


# Build the final names database from MARC 100
# Build the final names database from cleaned MARC 100 data
names_database <- data.frame(
  id1         = as.character(df_100_filled$id1),
  author_name = df_100_filled$author_name,
  asteri_id   = df_100_filled$asteri_id,
  date        = df_100_filled$date,
  stringsAsFactors = FALSE
)

# Add aggregated MARC 700 author information
# by matching records using field 001 / Melinda ID
names_database <- merge(
  names_database,
  
  df_700_by_record %>%
    transmute(
      id1 = as.character(field_001),
      author_name_700,
      asteri_id_700
    ),
  
  by = "id1",
  all.x = TRUE,
  sort = FALSE
)

