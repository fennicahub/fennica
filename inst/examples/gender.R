#add more columns from df.orig
df.processed$author_kanto <- df.orig$author_name_kanto
df.processed$author_700 <- df.orig$author_700a
author_name$full_name[trimws(author_name$author_700) == ""] <- NA
author_name$full_name[trimws(author_name$kanto) == ""] <- NA

# only 1809-1917
df <- df.processed[df.processed$melinda_id %in% melindas_19,] 

author_name <- data.frame(
  melinda_id = df$melinda_id,
  full_name = df$author_name,
  gender = df$gender,
  author_700 = df$author_700,
  kanto = df$author_kanto,
  stringsAsFactors = FALSE
)

author_name <- author_name %>%
  mutate(full_name = case_when(
    is.na(full_name) & !is.na(kanto) & str_trim(kanto) != "" ~ kanto,
    is.na(full_name) & !is.na(author_700) & str_trim(author_700) != "" ~ author_700,
    TRUE ~ full_name
  ))
author_name$full_name <- str_to_title(author_name$full_name)
author_name$kanto   <- str_to_title(author_name$kanto)
author_name$author_700   <- str_to_title(author_name$author_700)
# Step 1: Clean empty cells
author_name$full_name[trimws(author_name$full_name) == ""] <- NA

# Step 2: Define the splitting function
split_name <- function(name) {
  if (is.na(name)) {
    return(c(NA, NA))
  }
  parts <- unlist(strsplit(name, ",\\s*"))
  if (length(parts) == 2) {
    return(parts)
  } else if (length(parts) == 1) {
    return(c(NA, parts[1]))  # Only firstname
  } else {
    return(c(NA, NA))
  }
}

# Step 3: Apply and bind
name_parts <- t(sapply(author_name$full_name, split_name))
colnames(name_parts) <- c("surname", "firstname")

author_name$surname <- name_parts[, "surname"]
author_name$firstname <- name_parts[, "firstname"]

#clean kanto names
author_name$kanto_h <- author_name$kanto

author_name$kanto_h <- gsub("[0-9.\\-]", "", author_name$kanto_h)
author_name$kanto_h <- gsub(", ,", ",", author_name$kanto_h)

# Step 1: Remove all dots
author_name$kanto_h <- gsub("\\.", "", author_name$kanto_h)

# Step 2: Collapse multiple spaces into a single space
author_name$kanto_h <- gsub("\\s+", " ", author_name$kanto_h)

author_name$kanto_h <- gsub("^[,\\s]+|[,\\s]+$", "", author_name$kanto_h)
author_name$kanto_h <- gsub(",\\s*$", "", author_name$kanto_h)

author_name$kanto_h <- sapply(author_name$kanto_h, function(x) {
  if (is.na(x)) return(NA)
  
  parts <- unlist(strsplit(x, ","))
  parts <- trimws(parts)
  
  if (length(parts) > 2) {
    # Keep parts with more than 3 characters
    parts <- parts[nchar(parts) > 3]
  }
  
  # Recombine
  paste(parts, collapse = ", ")
})

author_name$kanto_h <- sapply(author_name$kanto_h, function(x) {
  if (is.na(x)) return(NA)  # Preserve NA values
  parts <- unlist(strsplit(x, ","))
  parts <- trimws(parts)
  parts <- unique(parts[parts != ""])  # Remove empty strings
  paste(parts, collapse = ", ")
})


# Ensure the new columns exist and are initialized
author_name$sur_w_k <- NA
author_name$first_w_k <- NA

# Apply row-wise logic
for (i in seq_along(author_name$kanto_h)) {
  entry <- author_name$kanto_h[i]
  
  if (!is.na(entry)) {
    parts <- strsplit(entry, ",")[[1]]
    parts <- trimws(parts)
    
    if (length(parts) == 2) {
      author_name$sur_w_k[i] <- parts[1]
      author_name$first_w_k[i] <- parts[2]
    }
  }
}

author_name <- author_name %>%
  rowwise() %>%
  mutate(
    # Clean both surname values
    surname_clean = str_trim(surname),
    sur_w_k_clean = str_trim(sur_w_k),
    
    firstname_clean = str_trim(firstname),
    first_w_k_clean = str_trim(first_w_k),
    
    final_surname = case_when(
      is.na(surname_clean) ~ sur_w_k_clean,
      is.na(sur_w_k_clean) ~ surname_clean,
      surname_clean == sur_w_k_clean ~ surname_clean,
      TRUE ~ surname_clean
    ),
    
    final_firstname = case_when(
      is.na(surname_clean) ~ first_w_k_clean,
      is.na(sur_w_k_clean) ~ firstname_clean,
      surname_clean == sur_w_k_clean ~ paste(
        unique(na.omit(c(firstname_clean, first_w_k_clean))), collapse = ", "
      ),
      TRUE ~ firstname_clean
    )
  ) %>%
  ungroup() %>%
  select(-surname_clean, -sur_w_k_clean, -firstname_clean, -first_w_k_clean)  # drop temp columns


author_name$final_firstname <- sapply(author_name$final_firstname, function(x) {
  if (is.na(x)) return(NA)
  
  parts <- unlist(strsplit(x, ","))
  parts <- trimws(parts)
  
  if (length(parts) > 1) {
    # Keep parts with more than 3 characters
    parts <- parts[nchar(parts) > 3]
  }
  
  # Recombine
  paste(parts, collapse = ", ")
})
