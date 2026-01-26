############ genre / gender analysis for the 1809-1917############

library(dplyr)
library(stringr)
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/harmonized/harmonized_fennica.csv"

df <- read.table(
  url,
  sep = "\t",
  header = TRUE,
  colClasses = "character",
  quote = "", 
  comment.char = "",
  fileEncoding = "UTF-8",
  stringsAsFactors = FALSE
)

df.processed19 <- df[df$melinda_id %in% melindas_19,] 
# start clean
lin_df <- df.processed19
lin_df <- lin_df[, !duplicated(names(lin_df))]


values_to_na <- c(
  "tuntematon", "ei koodattu", "aakkostoa tai kirjaimistoa ei ole",
  "arabialainen", "laajennettu latinalainen", "kalvo",
  "latinalainen", "videotallenne", "dia", "kyrillinen",
  "ei transponointia", "moniviestin", "sana- tai kuvakortti",
  "muu", "peli", "ilmiasun erityispiirteitä ei ole määritelty",
  "taidejäljennös", "soveltumaton", "kuva", "sekalaiset aineistot",
  "kreikkalainen", "kiinalainen", "dioraama", "raina",
  "japanilainen", "korealainen", "mikroskoopin preparaatti",
  "sovitus", "thaimaalainen", "transponointi"
)

lin_df <- lin_df %>%
  mutate(
    genre = ifelse(tolower(genre_008) %in% values_to_na, NA, genre_008)
  )

# sanity check
table(lin_df$genre, useNA = "ifany")
table(lin_df$biblio_level, useNA = "ifany")
table(lin_df$data_element, useNA = "ifany")
table(lin_df$record_type, useNA = "ifany")


lin_df <- lin_df %>%
  filter(
    biblio_level == "Monigraph/Item" |
    publication_status == "Kirjat" |
    record_type == "Language material"
  )

table(lin_df$publication_place, useNA = "ifany")
table(lin_df$publication_country, useNA = "ifany")

# lin_df <- lin_df %>%
#   filter(publication_country %in% c("Finland", "Sweden", "Russia"))



# 1  - big, 2 - medium, 3 - small publisher
library(dplyr)

lin_df <- lin_df %>%
  add_count(publisher, name = "publisher_n") %>% 
  mutate(
    publisher_size = case_when(
      publisher_n > 2000 ~ "group_1",
      publisher_n >= 50 & publisher_n <= 1999 ~ "group_2",
      publisher_n >= 1   & publisher_n <= 49  ~ "group_3",
      TRUE ~ NA_character_
    )
  ) %>%
  dplyr::select(-publisher_n)   # optional: remove the count column
table(lin_df$publisher_size, useNA = "ifany")

lin_df <- filter(lin_df, !is.na(genre))

kauno <- c("Draama", "Esseet", "Huumori, satiiri", 
           "Kaunokirjallisuus", "Kirjeet", "Novellit, kertomukset", 
           "Puheet, esitelmät", "Romaanit", "Runot", "Yhdistelmä")

lin_df <- lin_df %>% mutate(code_genre = ifelse(genre %in% kauno, "fiction", "non-fiction"))
lin_df$code_genre <- lin_df$code_genre

write.table(
  lin_df,
  file = paste0(output.folder, "books_19th.tsv"),
  sep = "\t",
  row.names = FALSE,
  quote = TRUE,          # important
  qmethod = "double",    # escape quotes inside fields
  fileEncoding = "UTF-8"
)
