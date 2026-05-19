library(dplyr)
library(tidyr)
library(stringr)

# ------------------------------------------------------------
# Create author_db from names_database
#
# Purpose:
# - collect all unique authors from MARC 100 and MARC 700
# - keep authors with Asteri IDs and authors without Asteri IDs
# - create a stable internal index for the author database
#
# Starting fields:
# - author_index
# - asteri_id
# - author_name
# - author_birth
# - author_death
# ------------------------------------------------------------

names_database <- database2

# 1. Main authors from MARC 100
authors_100 <- names_database %>%
  transmute(
    source = "100",
    asteri_id = asteri_id,
    author_name = author_name
  )


# 2. Added authors from MARC 700
# author_name_700 and asteri_id_700 are stored as "; "-separated strings,
# so they need to be separated back into long format.
authors_700 <- df_700 %>%
  transmute(
    source = "700",
    author_name = author_name,
    asteri_id = asteri_id
  ) 


# 3. Combine 100 and 700 authors
authors_all <- bind_rows(authors_100, authors_700) %>%
  mutate(
    asteri_id = na_if(str_trim(as.character(asteri_id)), ""),
    author_name = na_if(str_trim(as.character(author_name)), ""),
    author_birth = na_if(str_trim(as.character(author_birth)), ""),
    author_death = na_if(str_trim(as.character(author_death)), "")
  ) %>%
  filter(!is.na(author_name) | !is.na(asteri_id))


# 4. Keep unique authors
# If Asteri ID exists, uniqueness is based primarily on Asteri ID.
# If Asteri ID is missing, uniqueness is based on author_name + birth.
author_db <- authors_all %>%
  group_by(asteri_id, author_name, author_birth, author_death) %>%
  summarise(
    sources = paste(sort(unique(source)), collapse = "; "),
    .groups = "drop"
  ) %>%
  arrange(author_name, author_birth, asteri_id) %>%
  mutate(author_index = row_number()) %>%
  select(
    author_index,
    asteri_id,
    author_name,
    author_birth,
    author_death,
    sources
  )


# Combine 100 and 700 authors
authors_all <- bind_rows(authors_100, authors_700) %>%
  mutate(
    asteri_id = na_if(str_trim(as.character(asteri_id)), ""),
    author_name = na_if(str_trim(as.character(author_name)), "")
  ) %>%
  filter(!is.na(asteri_id) | !is.na(author_name))

# Create author database:
# one row per unique Asteri ID + author name combination
author_database <- authors_all %>%
  group_by(asteri_id, author_name) %>%
  summarise(
    source = paste(sort(unique(source)), collapse = "; "),
    .groups = "drop"
  ) %>%
  arrange(author_name, asteri_id) %>%
  select(asteri_id, author_name, source)

#source("kanto_harmonized.R") to get refined kanto fields in names_df 

# merge names_df into author_database 
