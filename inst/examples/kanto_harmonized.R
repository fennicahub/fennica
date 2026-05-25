
kanto_fields <- setdiff(colnames(df.kanto), "asteri_id")

for (field in kanto_fields) {
  # create named vector: asteri_id -> aggregated values
  map_vec <- tapply(
    df.kanto[[field]],
    df.kanto$asteri_id,
    function(x) paste(unique(na.omit(x)), collapse = "; ")
  )
  # assign to author_df using match-like indexing
  authors_df[[field]] <- map_vec[authors_df$id]
}

f_preflabel <- polish_author(authors_df$prefLabel)
f_altLabel <- polish_author(authors_df$altLabel)
f_variantName <- polish_author(authors_df$variantName)
f_fullerFormOfName <- polish_author(authors_df$fullerFormOfName)
f_hiddenLabel <- polish_author(authors_df$hiddenLabel)
f_authorizedAccessPoint <- polish_author(authors_df$authorizedAccessPoint)

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
  authors_df <- cbind(authors_df, tmp)
}


# collect all *_author_name, *_first, *_last columns
name_cols  <- grep("_full_name$", names(authors_df), value = TRUE)
first_cols <- grep("_first$", names(authors_df), value = TRUE)
last_cols  <- grep("_last$", names(authors_df), value = TRUE)

# helper to collapse unique values per row
collapse_unique <- function(x) {
  x <- unique(na.omit(x))
  if (length(x) == 0) return(NA_character_)
  paste(x, collapse = "; ")
}

# build final names df
names_df <- data.frame(
  asteri_id = authors_df$id,
  author_name = apply(authors_df[name_cols], 1, collapse_unique),
  first       = apply(authors_df[first_cols], 1, collapse_unique),
  last        = apply(authors_df[last_cols], 1, collapse_unique),
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

source("author_date.R")
# assign columns
names_df$author_birth <- df.kanto$birthDate[idx]
names_df$author_death <- df.kanto$deathDate[idx]
names_df$author_birth_100 <- df_date$author_birth[idx1]
names_df$author_death_100 <- df_date$author_death[idx1]
names_df$note <- df.kanto$note[idx]


names_df <- names_df %>%
  mutate(
    from = coalesce(
      as.character(author_birth),
      as.character(author_birth_100)
    ),
    till = coalesce(
      as.character(author_death),
      as.character(author_death_100)
    )
  )

names_df$kanto_all <- names_df$author_name

names_df <- names_df %>%
  mutate(
    from_num = as.numeric(from),
    till_num = as.numeric(till),
    
    author_age = till_num - from_num,
    
    author_age = ifelse(
      !is.na(from_num) & !is.na(till_num) &
        from_num < 0 & till_num > 0,
      author_age - 1,
      author_age
    ),
    
    author_age = ifelse(
      author_age < 10 | author_age > 110,
      NA,
      author_age
    ),
    
    author_age = na_if(author_age, 0)
  ) %>%
  select(-from_num, -till_num)


names_df <- names_df %>%
  select(-author_birth,
         -author_death,
         -author_date,
         -author_birth_100,
         -author_death_100)

kanto_harmonized <- names_df

