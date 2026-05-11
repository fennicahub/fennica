library(finto)
library(stringr)
library(dplyr)
library(tidyr)

#https://finto.fi/slm/fi/
#SLM - Suomalainen lajityyppi- ja muotosanasto 
#MARC21 655a


turtle_data <- get_vocabulary_data(
  vocid = "slm",
  format = "text/turtle"
)
cat(turtle_data) 


# If turtle_data is already one long character string:
txt <- paste(turtle_data, collapse = "\n")

# Split into concept blocks
blocks <- str_split(txt, "\n(?=slm:s[0-9]+ a skos:Concept)")[[1]]

extract_labels <- function(block) {
  concept <- str_extract(block, "^slm:s[0-9]+")
  
  pref <- str_match(block, "skos:prefLabel\\s+([^;]+);")
  alt  <- str_match(block, "skos:altLabel\\s+([^;]+);")
  
  get_fi <- function(x) {
    if (is.na(x[2])) return(character(0))
    str_extract_all(x[2], '"[^"]+"@fi')[[1]] |>
      str_remove_all('^"|\"@fi$')
  }
  
  tibble(
    concept = concept,
    prefLabel_fi = list(get_fi(pref)),
    altLabel_fi  = list(get_fi(alt))
  )
}

df_slm_labels <- bind_rows(lapply(blocks, extract_labels)) %>%
  filter(!is.na(concept)) %>%
  unnest_longer(prefLabel_fi, keep_empty = TRUE) %>%
  unnest_longer(altLabel_fi, keep_empty = TRUE)


genre_lang_df <- read.csv("genre_655.csv", sep = ";", stringsAsFactors = FALSE)

unique_labels <- df_slm_labels %>%
  select(prefLabel_fi, altLabel_fi) %>%
  pivot_longer(everything(), values_to = "label") %>%
  filter(!is.na(label), label != "") %>%
  mutate(label = tolower(label)) %>%
  bind_rows(
    tibble(label = tolower(genre_lang_df$genre))
  ) %>%
  filter(!is.na(label), label != "") %>%
  distinct(label) %>%
  pull(label)

unique_labels <- unique(unique_labels)

head(df_slm_labels, n  = 100)

# Save
write.csv(unique_labels, "unique_slm_labels_fi.csv", row.names = FALSE)
