
kanto_fields <- setdiff(colnames(df.kanto), "asteri_id")

for (field in kanto_fields) {
  # create named vector: asteri_id -> aggregated values
  map_vec <- tapply(
    df.kanto[[field]],
    df.kanto$asteri_id,
    function(x) paste(unique(na.omit(x)), collapse = "; ")
  )
  # assign to author_df using match-like indexing
  author_database[[field]] <- map_vec[author_df$asteri_id]
}

f_preflabel <- polish_author(author_df$prefLabel)
f_altLabel <- polish_author(author_df$altLabel)
f_variantName <- polish_author(author_df$variantName)
f_fullerFormOfName <- polish_author(author_df$fullerFormOfName)
f_hiddenLabel <- polish_author(author_df$hiddenLabel)
f_authorizedAccessPoint <- polish_author(author_df$authorizedAccessPoint)

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
  # rename columns to keep origin
  names(tmp) <- paste0(field, "_", names(tmp))
  # bind column-wise (same row order assumed)
  author_database <- cbind(author_database, tmp)
}


# collect all *_author_name, *_first, *_last columns
name_cols  <- grep("_full_name$", names(author_database), value = TRUE)
first_cols <- grep("_first$", names(author_database), value = TRUE)
last_cols  <- grep("_last$", names(author_database), value = TRUE)

# helper to collapse unique values per row
collapse_unique <- function(x) {
  x <- unique(na.omit(x))
  if (length(x) == 0) return(NA_character_)
  paste(x, collapse = "; ")
}

# build final names df
names_df <- data.frame(
  asteri_id = author_database$asteri_id,
  author_name = apply(author_database[name_cols], 1, collapse_unique),
  first       = apply(author_database[first_cols], 1, collapse_unique),
  last        = apply(author_database[last_cols], 1, collapse_unique),
  stringsAsFactors = FALSE
)

names_df$author_name <- gsub(",\\s*;+", ";", names_df$author_name)  # ,;;  -> ;
names_df$author_name <- gsub(";\\s*,", ";", names_df$author_name)   # ;,   -> ;
names_df$author_name <- gsub(";+", ";", names_df$author_name) 
names_df$author_name <- gsub(",\\s*;+", ";", names_df$author_name)

# ensure same type
names_df$asteri_id <- as.character(names_df$asteri_id)
df.kanto$asteri_id <- as.character(df.kanto$asteri_id)
df.orig$asteri_id <- as.character(df.orig$asteri_id)

# match index
idx <- match(names_df$asteri_id, df.kanto$asteri_id)
idx1 <- match(names_df$asteri_id, df.orig$asteri_id)

# assign columns
names_df$author_birth <- df.kanto$birthDate[idx]
names_df$author_death <- df.kanto$deathDate[idx]
names_df$author_date <- df.orig$author_date[idx1]
names_df$note <- df.kanto$note[idx]


df.tmp <- polish_author_years(names_df$author_date, check = TRUE)
names_df$author_from1 <- df.tmp$from
names_df$author_till1 <- df.tmp$till

names_df <- names_df %>%
  mutate(
    from = if_else(!is.na(author_from1),
                   as.character(author_from1),
                   as.character(author_birth)),
    till = if_else(!is.na(author_till1),
                   as.character(author_till1),
                   as.character(author_death))
  )

names_df$kanto_all <- names_df$author_name
names_df <- names_df %>%
  select(-author_birth,
         -author_death,
         -author_date,
         -author_from1,
         -author_till1, 
         -author_name)

