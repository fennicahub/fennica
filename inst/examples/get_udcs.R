
##################### UDCS ##############################################
# Monikielinen UDC Summary (udcS), suomeksi Supistettu UDK, on noin 2600 luokan valikoima joka on poimittu vuonna 2011 UDC Master Reference File (UDC MRF) tietokannasta, jossa on yli 70,000 luokkaa. Valikoima sisältää luokituksen pääluvut ja yleiset lisäluvut sekä erikoislisäluvut ja se kattaa tasaisesti kaikki tiedon alueet, jotka sisältyvät luokitukseen. UDC Summary päivitetään vuosittain UDC:n viimeisimmästä versiosta.
# https://finto.fi/udcs/fi/
# MARC21 080a

turtle_data <- get_vocabulary_data(
  vocid = "udcs",
  format = "text/turtle"
)
cat(turtle_data) 



# turtle_data can be one long string OR vector of lines
txt <- paste(turtle_data, collapse = "\n")

# Split into UDC concept blocks
blocks <- str_split(
  txt,
  "\n(?=<http://udcdata\\.info/[0-9]+> a skos:Concept)"
)[[1]]

get_fi_labels <- function(block, field) {
  pattern <- paste0("skos:", field, "\\s+([^;]+);")
  m <- str_match(block, pattern)
  
  if (is.na(m[1, 2])) return(character(0))
  
  str_extract_all(m[1, 2], '"[^"]+"@fi')[[1]] |>
    str_remove_all('^"|\"@fi$')
}

get_notation <- function(block) {
  m <- str_match(
    block,
    'skos:notation\\s+"([^"]+)"\\^\\^<http://udcdata\\.info/UDCnotation>'
  )
  
  ifelse(is.na(m[1, 2]), NA_character_, m[1, 2])
}

extract_udc <- function(block) {
  concept <- str_extract(block, "^<http://udcdata\\.info/[0-9]+>")
  concept <- str_remove_all(concept, "^<|>$")
  
  tibble(
    concept = concept,
    notation = get_notation(block),
    prefLabel_fi = list(get_fi_labels(block, "prefLabel")),
    altLabel_fi = list(get_fi_labels(block, "altLabel")),
    hiddenLabel_fi = list(get_fi_labels(block, "hiddenLabel"))
  )
}

df_udc_labels <- bind_rows(lapply(blocks, extract_udc)) %>%
  filter(!is.na(concept)) %>%
  unnest_longer(prefLabel_fi, keep_empty = TRUE) %>%
  unnest_longer(altLabel_fi, keep_empty = TRUE) %>%
  unnest_longer(hiddenLabel_fi, keep_empty = TRUE)



df_udc_labels <- df_udc_labels %>%
  mutate(
    altLabel_fi = as.character(altLabel_fi),
    notation = as.character(notation),

    has_bar = coalesce(str_detect(altLabel_fi, fixed("|")), FALSE),

    notation = case_when(
      has_bar ~ str_trim(str_extract(altLabel_fi, "(?<=\\|).*")),
      TRUE ~ notation
    ),

    altLabel_fi = case_when(
      has_bar ~ str_trim(str_remove(altLabel_fi, "\\|.*$")),
      TRUE ~ altLabel_fi
    )
  ) %>%
  select(-has_bar)

head(df_udc_labels, n = 20)

# Save
#write.csv(df_udc_labels, "udcs_labels_fi.csv", row.names = FALSE)

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/udk.csv"
udk <- read.csv(
  url,
  sep = ";",
  header = FALSE,
  encoding = "UTF-8",
  stringsAsFactors = FALSE
)
colnames(udk) <- c("synonyme", "name")
