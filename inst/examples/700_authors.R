library(dplyr)
library(stringr)

# NOTE:
# This script uses authority data from the Kanto database (df.kanto).
# The object df.kanto is assumed to be pre-generated, where priority is given
# to selected authority fields (e.g. preferred name, birth/death dates).
# This means that the enrichment of MARC 700 authors relies on Kanto-derived authority data.
#
# To inspect how df.kanto is constructed and which fields are prioritised,
# refer to the Kanto processing script.

# Commenting and explanatory notes were generated with the assistance of AI 
# and further refined and validated by Julia Matveeva.

# Read the long-format table extracted from MARC 700 fields.
# Each row should represent one added/contributing author from field 700.


df_700 <- read.csv("authors_700_long.csv")

# Clean Asteri IDs from the original author_id column.
# The goal is to keep only the 9-digit numeric Asteri identifier.
df_700 <- df_700 %>%
  mutate(
    asteri_id = str_trim(author_id),                         # remove extra spaces
    asteri_id = na_if(asteri_id, ""),                        # empty strings become NA
    asteri_id = str_remove(asteri_id, "^\\(FI-ASTERI-N\\)\\s*"), # remove prefix
    asteri_id = str_extract(asteri_id, "\\d{9}")             # keep only 9-digit ID
  )

# Harmonise / clean author names using your polish_author() function.
# The function returns a structured object; here only full_name is kept.
name <- polish_author(df_700$author_name)

df_700$author_name <- name$full_name

# Make sure df_700 is a normal data frame.
df_700 <- as.data.frame(df_700)

# Match cleaned 700 Asteri IDs with df.kanto.
# df.kanto contains authority-data dates: from = birth, till = death.
idx <- match(df_700$asteri_id, df.kanto$asteri_id)

df_700[["birth"]] <- df.kanto[["from"]][idx]
df_700[["death"]] <- df.kanto[["till"]][idx]

# Check whether the same combination of author_name + birth
# maps to one or several Asteri IDs.
name_birth_ids <- df_700 %>%
  transmute(
    author_name = author_name,
    birth = birth,
    asteri_id = asteri_id
  ) %>%
  filter(!is.na(author_name), !is.na(birth)) %>%
  group_by(author_name, birth) %>%
  summarise(
    n_ids = n_distinct(asteri_id, na.rm = TRUE),
    ids = paste(sort(unique(na.omit(asteri_id))), collapse = "; "),
    .groups = "drop"
  )

# Cases where the same name + birth year maps to more than one ID.
# These are ambiguous and should not be used for automatic filling.
name_birth_ambiguous <- name_birth_ids %>%
  filter(n_ids > 1)

# Diagnostics: how many ambiguous cases exist?
nrow(name_birth_ambiguous)

# Diagnostics: distribution of number of IDs per name + birth combination.
table(name_birth_ids$n_ids)

# Safe combinations: name + birth maps to exactly one Asteri ID.
name_birth_unique <- name_birth_ids %>%
  filter(n_ids == 1)

# Build a lookup table:
# if author_name + birth has exactly one Asteri ID,
# use that ID as a safe candidate for missing IDs.
lookup_nb <- df_700 %>%
  filter(!is.na(author_name), !is.na(birth)) %>%
  group_by(author_name, birth) %>%
  summarise(
    n_ids = n_distinct(asteri_id, na.rm = TRUE),
    id_unique = ifelse(n_ids == 1, first(na.omit(asteri_id)), NA_character_),
    .groups = "drop"
  ) %>%
  filter(n_ids == 1) %>%
  select(author_name, birth, id_unique)

# Create matching keys for lookup and df_700.
key_lookup <- paste(lookup_nb$author_name, lookup_nb$birth)
key_700    <- paste(df_700$author_name, df_700$birth)

idx <- match(key_700, key_lookup)

# Fill missing Asteri IDs in df_700 only where a safe name + birth match exists.
missing_id <- is.na(df_700$asteri_id)

df_700$asteri_id[missing_id] <- lookup_nb$id_unique[idx][missing_id]

# Diagnostic: how many missing IDs were filled by name + birth.
sum(missing_id & !is.na(df_700$asteri_id))

# Second enrichment step:
# find author names that map to exactly one Asteri ID regardless of birth year.
# This is weaker than name + birth, but still safe if the name has only one ID.
name_unique_id <- df_700 %>%
  filter(!is.na(author_name)) %>%
  group_by(author_name) %>%
  summarise(
    n_ids = n_distinct(asteri_id, na.rm = TRUE),
    id_unique = ifelse(n_ids == 1, first(na.omit(asteri_id)), NA_character_),
    .groups = "drop"
  ) %>%
  filter(n_ids == 1)

# Match df_700 rows to the name-only lookup.
idx <- match(df_700$author_name, name_unique_id$author_name)

# Fill remaining missing IDs using name-only matches.
missing_id <- is.na(df_700$asteri_id)

df_700$asteri_id[missing_id] <- name_unique_id$id_unique[idx][missing_id]

# Diagnostic: how many additional missing IDs were filled by name only.
sum(missing_id & !is.na(df_700$asteri_id))

# Collapse the long 700 table back to one row per bibliographic record.
# id1 is the record identifier.
# Multiple 700 authors and IDs are pasted together with "; ".
df_700_by_record <- df_700 %>%
  group_by(id1) %>%
  summarise(
    author_name_700 = paste(author_name, collapse = "; "),
    asteri_id_700   = paste(asteri_id, collapse = "; "),
    .groups = "drop"
  )