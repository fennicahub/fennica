library(dplyr)

source("funcs.R")


# =============================================================================
# Harmonize Kanto authority data
#
# Required objects:
#   df.kanto   = Kanto authority data
#   df.orig    = original bibliographic data
#   authors_df = one row per Asteri ID, identifier stored in `id`
#
# Required functions from funcs.R:
#   polish_author()
#   polish_author_years()
#   polish_profession()
# =============================================================================


# -----------------------------------------------------------------------------
# 1. Helper function
#
# Combine unique, non-missing values into one semicolon-separated string.
# -----------------------------------------------------------------------------

collapse_unique <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  
  x <- x[
    !is.na(x) &
      x != "" &
      !x %in% c("NA", "NULL")
  ]
  
  x <- unique(x)
  
  if (length(x) == 0) {
    return(NA_character_)
  }
  
  paste(x, collapse = "; ")
}


# -----------------------------------------------------------------------------
# 2. Standardize Asteri identifier types
#
# Asteri IDs must remain character values because leading zeros are meaningful.
# -----------------------------------------------------------------------------

authors_df$id <- as.character(authors_df$id)
df.kanto$asteri_id <- as.character(df.kanto$asteri_id)
df.orig$asteri_id <- as.character(df.orig$asteri_id)


# -----------------------------------------------------------------------------
# 3. Add all original Kanto fields to authors_df
#
# Multiple unique values belonging to the same Asteri ID are combined with
# semicolons.
# -----------------------------------------------------------------------------

kanto_fields <- setdiff(
  names(df.kanto),
  "asteri_id"
)

for (field in kanto_fields) {
  
  field_lookup <- tapply(
    df.kanto[[field]],
    df.kanto$asteri_id,
    collapse_unique
  )
  
  authors_df[[field]] <- unname(
    field_lookup[authors_df$id]
  )
}


# -----------------------------------------------------------------------------
# 4. Harmonize the main Kanto name fields
#
# Keep the original working logic:
#   1. Polish each field separately.
#   2. Store the results in polished_list.
#   3. Rename the output columns according to their source field.
#   4. Bind the results to authors_df.
# -----------------------------------------------------------------------------

f_preflabel <- polish_author(
  authors_df$prefLabel
)

f_altLabel <- polish_author(
  authors_df$altLabel
)

f_variantName <- polish_author(
  authors_df$variantName
)

f_fullerFormOfName <- polish_author(
  authors_df$fullerFormOfName
)

f_hiddenLabel <- polish_author(
  authors_df$hiddenLabel
)

f_authorizedAccessPoint <- polish_author(
  authors_df$authorizedAccessPoint
)


polished_list <- list(
  prefLabel = f_preflabel,
  altLabel = f_altLabel,
  variantName = f_variantName,
  fullerName = f_fullerFormOfName,
  hidden_label = f_hiddenLabel,
  authorized = f_authorizedAccessPoint
)


for (field in names(polished_list)) {
  
  tmp <- polished_list[[field]]
  
  # Preserve the source of each harmonized name variable
  names(tmp) <- paste0(
    field,
    "_",
    names(tmp)
  )
  
  # Add harmonized name columns to authors_df
  authors_df <- cbind(
    authors_df,
    tmp
  )
}


# -----------------------------------------------------------------------------
# 5. Identify harmonized name columns
# -----------------------------------------------------------------------------

full_name_columns <- grep(
  "_full_name$",
  names(authors_df),
  value = TRUE
)

first_name_columns <- grep(
  "_first$",
  names(authors_df),
  value = TRUE
)

last_name_columns <- grep(
  "_last$",
  names(authors_df),
  value = TRUE
)


# Check that the expected columns were created

if (length(full_name_columns) == 0) {
  stop("No harmonized full-name columns were created.")
}

if (length(first_name_columns) == 0) {
  stop("No harmonized first-name columns were created.")
}

if (length(last_name_columns) == 0) {
  stop("No harmonized last-name columns were created.")
}


# -----------------------------------------------------------------------------
# 6. Combine all harmonized name forms
#
# Create one row per Asteri ID containing all unique full names, first names,
# and last names found in the selected Kanto name fields.
# -----------------------------------------------------------------------------

names_df <- data.frame(
  asteri_id = authors_df$id,
  
  author_name = apply(
    authors_df[full_name_columns],
    1,
    collapse_unique
  ),
  
  first = apply(
    authors_df[first_name_columns],
    1,
    collapse_unique
  ),
  
  last = apply(
    authors_df[last_name_columns],
    1,
    collapse_unique
  ),
  
  stringsAsFactors = FALSE
)


# Remove punctuation artefacts introduced when several names are combined

names_df$author_name <- names_df$author_name %>%
  gsub(",\\s*;+", ";", .) %>%
  gsub(";\\s*,", ";", .) %>%
  gsub(";+", ";", .) %>%
  gsub("^\\s*;|;\\s*$", "", .) %>%
  trimws()

names_df$author_name <- na_if(
  names_df$author_name,
  ""
)


# -----------------------------------------------------------------------------
# 7. Clean and add profession
#
# The profession field has already been aggregated by Asteri ID in authors_df.
# polish_profession() cleans and combines its semicolon-separated values.
# -----------------------------------------------------------------------------

profession_field <-
  "profession_metadata_profession_prefLabel_fi"

names_df$profession <- vapply(
  authors_df[[profession_field]],
  polish_profession,
  FUN.VALUE = character(1)
)


# -----------------------------------------------------------------------------
# 8. Harmonize MARC 100$d author dates
# -----------------------------------------------------------------------------

author_date_field <- "author_date"

df.orig[[author_date_field]] <- as.character(
  df.orig[[author_date_field]]
)

df.orig[[author_date_field]][
  trimws(df.orig[[author_date_field]]) == ""
] <- NA_character_


df_date <- polish_author_years(
  df.orig[[author_date_field]],
  check = TRUE
) %>%
  rename(
    author_birth = from,
    author_death = till
  ) %>%
  mutate(
    author_age = author_death - author_birth,
    
    # Correct BCE-to-CE lifespans because there is no year zero
    author_age = ifelse(
      !is.na(author_birth) &
        !is.na(author_death) &
        author_birth < 0 &
        author_death > 0,
      author_age - 1,
      author_age
    ),
    
    # Remove implausible ages
    author_age = ifelse(
      author_age < 10 | author_age > 110,
      NA_real_,
      author_age
    ),
    
    author_age = na_if(
      author_age,
      0
    )
  )


# Create a harmonized date string

df_date$author_date <- paste0(
  ifelse(
    is.na(df_date$author_birth),
    "",
    df_date$author_birth
  ),
  "-",
  ifelse(
    is.na(df_date$author_death),
    "",
    df_date$author_death
  )
)

df_date$author_date <- trimws(
  df_date$author_date
)

df_date$author_date <- na_if(
  df_date$author_date,
  "-"
)


# Add bibliographic record and Asteri identifiers

df_date <- bind_cols(
  id = df.orig$id,
  asteri_id = df.orig$asteri_id,
  df_date
)

rownames(df_date) <- NULL


# -----------------------------------------------------------------------------
# 9. Match Kanto and MARC date information
#
# Kanto dates are preferred. MARC 100$d dates are used only when the relevant
# Kanto value is missing.
# -----------------------------------------------------------------------------

kanto_index <- match(
  names_df$asteri_id,
  df.kanto$asteri_id
)

marc_index <- match(
  names_df$asteri_id,
  df_date$asteri_id
)


names_df$author_birth_kanto <-
  df.kanto$birthDate[kanto_index]

names_df$author_death_kanto <-
  df.kanto$deathDate[kanto_index]

names_df$author_birth_100 <-
  df_date$author_birth[marc_index]

names_df$author_death_100 <-
  df_date$author_death[marc_index]


names_df <- names_df %>%
  mutate(
    from = coalesce(
      as.character(author_birth_kanto),
      as.character(author_birth_100)
    ),
    
    till = coalesce(
      as.character(author_death_kanto),
      as.character(author_death_100)
    )
  )


# -----------------------------------------------------------------------------
# 10. Add notes and combined Kanto names
# -----------------------------------------------------------------------------

names_df$note <- authors_df$note

names_df$kanto_all <- names_df$author_name


# -----------------------------------------------------------------------------
# 11. Calculate author age
# -----------------------------------------------------------------------------

names_df <- names_df %>%
  mutate(
    from_numeric = suppressWarnings(
      as.numeric(from)
    ),
    
    till_numeric = suppressWarnings(
      as.numeric(till)
    ),
    
    author_age = till_numeric - from_numeric,
    
    # Correct BCE-to-CE lifespans
    author_age = ifelse(
      !is.na(from_numeric) &
        !is.na(till_numeric) &
        from_numeric < 0 &
        till_numeric > 0,
      author_age - 1,
      author_age
    ),
    
    # Remove implausible ages
    author_age = ifelse(
      author_age < 10 | author_age > 110,
      NA_real_,
      author_age
    ),
    
    author_age = na_if(
      author_age,
      0
    )
  ) %>%
  select(
    -from_numeric,
    -till_numeric,
    -author_birth_kanto,
    -author_death_kanto,
    -author_birth_100,
    -author_death_100
  )


# -----------------------------------------------------------------------------
# 12. Create the final harmonized Kanto table
# -----------------------------------------------------------------------------

kanto_harmonized <- names_df %>%
  select(
    asteri_id,
    author_name,
    first,
    last,
    profession,
    note,
    from,
    till,
    kanto_all,
    author_age
  )


# -----------------------------------------------------------------------------
# 13. Basic validation
# -----------------------------------------------------------------------------

message(
  "Non-missing harmonized author names: ",
  sum(!is.na(kanto_harmonized$author_name)),
  " / ",
  nrow(kanto_harmonized)
)

message("kanto_harmonized.R: DONE")

library(dplyr)

# -------------------------------------------------------------------------
# Create kantofull from the complete df.kanto table
#
# This ensures that every original Kanto field is retained.
# The selected name fields are additionally harmonized.
# -------------------------------------------------------------------------

name_fields <- c(
  "prefLabel",
  "altLabel",
  "variantName",
  "fullerFormOfName",
  "hiddenLabel",
  "authorizedAccessPoint",
  "relatedPersonOfPerson",
  "relatedPerson"
)

# Begin with every column from df.kanto
kantofull <- df.kanto %>%
  mutate(
    asteri_id = as.character(asteri_id)
  )


# -------------------------------------------------------------------------
# Harmonize the Kanto name fields
#
# For each field:
#   field_orig  = original Kanto value
#   field       = harmonized full name
#   field_first = harmonized first name
#   field_last  = harmonized last name
# -------------------------------------------------------------------------

for (field in name_fields) {
  
  original_value <- as.character(kantofull[[field]])
  
  original_value <- trimws(original_value)
  original_value[
    original_value %in% c("", "NA", "NULL")
  ] <- NA_character_
  
  polished_name <- polish_author(
    original_value,
    verbose = TRUE
  )
  
  # Preserve the original value
  kantofull[[paste0(field, "_orig")]] <- original_value
  
  # Replace the source field with its harmonized full name
  kantofull[[field]] <- polished_name$full_name
  
  # Add harmonized first and last names
  kantofull[[paste0(field, "_first")]] <- polished_name$first
  kantofull[[paste0(field, "_last")]] <- polished_name$last
}


# -------------------------------------------------------------------------
# Add the combined harmonized author variables
#
# `note` is not joined because the original df.kanto note column is already
# present in kantofull.
# -------------------------------------------------------------------------

kanto_author_info <- kanto_harmonized %>%
  mutate(
    asteri_id = as.character(asteri_id)
  ) %>%
  select(
    asteri_id,
    author_name,
    first,
    last,
    profession,
    from,
    till,
    kanto_all,
    author_age
  )


kantofull <- kantofull %>%
  left_join(
    kanto_author_info,
    by = "asteri_id"
  )


# -------------------------------------------------------------------------
# Assign gender from the combined harmonized first-name field
# -------------------------------------------------------------------------

kantofull$gender <- assign_gender(
  kantofull$first
)


# -------------------------------------------------------------------------
# Collapse duplicate Kanto rows to one row per Asteri ID
# -------------------------------------------------------------------------

kantofull <- kantofull %>%
  group_by(asteri_id) %>%
  summarise(
    across(
      everything(),
      collapse_unique
    ),
    .groups = "drop"
  )


# -------------------------------------------------------------------------
# Move the principal harmonized variables to the beginning
# -------------------------------------------------------------------------

kantofull <- kantofull %>%
  relocate(
    author_name,
    first,
    last,
    gender,
    profession,
    from,
    till,
    author_age,
    .after = asteri_id
  )


# Verify that every original Kanto column is present
setdiff(
  names(df.kanto),
  names(kantofull)
)

# Inspect the result

names(kantofull)
head(kantofull, 100)
