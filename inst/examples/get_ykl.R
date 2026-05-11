library(stringr)
library(dplyr)
library(tidyr)
library(finto)
#https://finto.fi/ykl/fi/
#YKL - Yleisten kirjastojen luokitusjärjestelmä

turtle_data <- get_vocabulary_data(
  vocid = "ykl",
  format = "text/turtle"
)
cat(turtle_data) 


# turtle_data can be one long string OR vector of lines
txt <- paste(turtle_data, collapse = "\n")

# Split into YKL concept blocks
blocks <- str_split(
  txt,
  "\n(?=ykl:[^\\s]+ a skos:Concept)"
)[[1]]

get_fi_labels <- function(block, field) {
  pattern <- paste0("skos:", field, "\\s+([^;]+);")
  m <- str_match(block, pattern)
  
  if (is.na(m[1, 2])) return(character(0))
  
  str_extract_all(m[1, 2], '"[^"]+"@fi')[[1]] |>
    str_remove_all('^"|\"@fi$')
}

get_notation <- function(block) {
  m <- str_match(block, 'skos:notation\\s+"([^"]+)"')
  ifelse(is.na(m[1, 2]), NA_character_, m[1, 2])
}

extract_ykl <- function(block) {
  concept <- str_extract(block, "^ykl:[^\\s]+")
  
  tibble(
    concept = concept,
    notation = get_notation(block),
    prefLabel_fi = list(get_fi_labels(block, "prefLabel")),
    altLabel_fi  = list(get_fi_labels(block, "altLabel"))
  )
}

df_ykl_labels <- bind_rows(lapply(blocks, extract_ykl)) %>%
  filter(!is.na(concept)) %>%
  unnest_longer(prefLabel_fi, keep_empty = TRUE) %>%
  unnest_longer(altLabel_fi, keep_empty = TRUE)

head(df_ykl_labels, n = 25)

# Save
write.csv(df_ykl_labels, "ykl_labels_fi.csv", row.names = FALSE)
