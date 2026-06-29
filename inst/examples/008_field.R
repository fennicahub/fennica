library(dplyr)

# --------------------------------------------------
# Clean 008 field
# --------------------------------------------------
df.orig$field_008 <- ifelse(trimws(df.orig$field_008) == "", NA, df.orig$field_008)

# --------------------------------------------------
# 00-05 Date entered on file
# --------------------------------------------------
df.orig$Date_entered <- substr(df.orig$field_008, 1, 6)

# --------------------------------------------------
# 06 Type of date / publication status
# --------------------------------------------------
df.orig$publication_status <- substr(df.orig$field_008, 7, 7)

df.orig <- df.orig %>%
  mutate(
    publication_status = case_when(
      publication_status == "b" ~ "No dates given; B.C. date involved",
      publication_status == "c" ~ "Continuing resource currently published",
      publication_status == "d" ~ "Continuing resource ceased publication",
      publication_status == "e" ~ "Detailed date",
      publication_status == "i" ~ "Inclusive dates of collection",
      publication_status == "k" ~ "Range of years of bulk of collection",
      publication_status == "m" ~ "Multiple dates",
      publication_status == "n" ~ "Dates unknown",
      publication_status == "p" ~ "Date of distribution etc",
      publication_status == "q" ~ "Questionable date",
      publication_status == "r" ~ "Reprint/reissue date and original date",
      publication_status == "s" ~ "Single known date/probable date",
      publication_status == "t" ~ "Publication date and copyright date",
      publication_status == "u" ~ "Continuing resource status unknown",
      publication_status == "|" ~ "No attempt to code",
      TRUE ~ NA_character_
    )
  )

# --------------------------------------------------
# 07-14 Publication time (DATE1 DATE2)
# --------------------------------------------------
df.orig$publication_time <- ifelse(
  is.na(df.orig$field_008),
  NA,
  paste(
    substr(df.orig$field_008, 8, 11),
    substr(df.orig$field_008, 12, 15),
    sep = " "
  )
)

# Ignore some publication status types
df.orig$publication_time <- ifelse(
  df.orig$publication_status %in% c(
    "No dates given; B.C. date involved",
    "No attempt to code",
    "Dates unknown"
  ),
  NA,
  df.orig$publication_time
)

# Keep DATE1 only
df.orig$publication_time <- ifelse(
  df.orig$publication_status %in% c(
    "Publication date and copyright date",
    "Single known date/probable date",
    "Detailed date",
    "Multiple dates",
    "Date of distribution etc",
    "Questionable date",
    "Continuing resource status unknown"
  ),
  substr(df.orig$publication_time, 1, 4),
  df.orig$publication_time
)

# For reprint/reissue keep DATE2 only
df.orig$publication_time <- ifelse(
  df.orig$publication_status == "Reprint/reissue date and original date",
  substr(df.orig$publication_time, 6, nchar(df.orig$publication_time)),
  df.orig$publication_time
)

# If leader position 18 is "8", set publication_time to NA
df.orig$publication_time <- ifelse(
  substr(df.orig$leader, 18, 18) == "8",
  NA,
  df.orig$publication_time
)

# --------------------------------------------------
# 008/33
# --------------------------------------------------
df.orig$field_008_33 <- substr(df.orig$field_008, 34, 34)

# --------------------------------------------------
# Data element category based on type_of_record and bibliographic_level
# --------------------------------------------------
df.orig <- df.orig %>%
  mutate(
    data_element_008 = case_when(
      is.na(field_008) ~ NA_character_,
      
      type_of_record %in% c("Language material", "Manuscript language material") &
        !bibliographic_level %in% c("Serial component part", "Integrating resource", "Serial") ~
        "Kirjat",
      
      type_of_record == "Electronic resource" ~
        "Elektroniset aineistot",
      
      type_of_record %in% c("Language material", "Manuscript language material") &
        bibliographic_level %in% c("Serial component part", "Integrating resource", "Serial") ~
        "Jatkuvat julkaisut",
      
      type_of_record %in% c("Cartographic material", "Manuscript cartographic material") ~
        "Kartat",
      
      type_of_record %in% c(
        "Notated music",
        "Manuscript notated music",
        "Nonmusical sound recording",
        "Musical sound recording"
      ) ~
        "Musiikki",
      
      type_of_record == "Mixed materials" ~
        "Sekalaiset aineistot",
      
      type_of_record %in% c(
        "Projected medium",
        "Two-dimensional nonprojectable graphic",
        "Kit",
        "Three-dimensional artifact or naturally occurring object"
      ) ~
        "Visuaaliset aineistot",
      
      TRUE ~ NA_character_
    )
  )

# --------------------------------------------------
# Conversion functions for 008/33
# --------------------------------------------------
convert_kirjat <- function(symbol) {
  case_when(
    symbol == "0" ~ "Tietokirjallisuus",
    symbol == "1" ~ "Kaunokirjallisuus",
    symbol == "d" ~ "Draama",
    symbol == "e" ~ "Esseet",
    symbol == "f" ~ "Romaanit",
    symbol == "h" ~ "Huumori, satiiri",
    symbol == "i" ~ "Kirjeet",
    symbol == "j" ~ "Novellit, kertomukset",
    symbol == "m" ~ "Yhdistelmä",
    symbol == "p" ~ "Runot",
    symbol == "s" ~ "Puheet, esitelmät",
    symbol == "u" ~ "Tuntematon",
    symbol == "|" ~ "Ei koodattu",
    TRUE ~ NA_character_
  )
}

convert_julkaisut <- function(symbol) {
  case_when(
    symbol == "#" ~ "Aakkostoa tai kirjaimistoa ei ole",
    symbol == " " ~ "Aakkostoa tai kirjaimistoa ei ole",
    symbol == "a" ~ "Latinalainen",
    symbol == "b" ~ "Laajennettu latinalainen",
    symbol == "c" ~ "Kyrillinen",
    symbol == "d" ~ "Japanilainen",
    symbol == "e" ~ "Kiinalainen",
    symbol == "f" ~ "Arabialainen",
    symbol == "g" ~ "Kreikkalainen",
    symbol == "h" ~ "Heprealainen",
    symbol == "i" ~ "Thaimaalainen",
    symbol == "j" ~ "Devanagari",
    symbol == "k" ~ "Korealainen",
    symbol == "l" ~ "Tamili",
    symbol == "u" ~ "Tuntematon",
    symbol == "z" ~ "Muu",
    symbol == "|" ~ "Ei koodattu",
    TRUE ~ NA_character_
  )
}

convert_kartat <- function(symbol) {
  case_when(
    symbol == "#" ~ "Ilmiasun erityispiirteitä ei ole määritelty",
    symbol == " " ~ "Ilmiasun erityispiirteitä ei ole määritelty",
    symbol == "e" ~ "Käsin piirretty",
    symbol == "j" ~ "Kuvakortti, postikortti",
    symbol == "k" ~ "Kalenteri",
    symbol == "l" ~ "Palapeli",
    symbol == "n" ~ "Peli",
    symbol == "o" ~ "Seinäkartta",
    symbol == "p" ~ "Pelikortit",
    symbol == "r" ~ "Irtolehtikartta",
    symbol == "z" ~ "Muu",
    symbol == "|" ~ "Ei koodattu",
    TRUE ~ NA_character_
  )
}

convert_musiikki <- function(symbol) {
  case_when(
    symbol == "#" ~ "Ei transponointia",
    symbol == " " ~ "Ei transponointia",
    symbol == "a" ~ "Transponointi",
    symbol == "b" ~ "Sovitus",
    symbol == "c" ~ "Sekä transponoitu että sovitettu",
    symbol == "n" ~ "Soveltumaton",
    symbol == "u" ~ "Tuntematon",
    symbol == "|" ~ "Ei koodattu",
    TRUE ~ NA_character_
  )
}

convert_visuaaliset <- function(symbol) {
  case_when(
    symbol == "a" ~ "Taideteos, alkuperäinen",
    symbol == "b" ~ "Moniviestin",
    symbol == "c" ~ "Taidejäljennös",
    symbol == "d" ~ "Dioraama",
    symbol == "f" ~ "Raina",
    symbol == "g" ~ "Peli",
    symbol == "i" ~ "Kuva",
    symbol == "k" ~ "Grafiikka",
    symbol == "l" ~ "Tekninen piirustus",
    symbol == "m" ~ "Elokuva",
    symbol == "n" ~ "Kaavio",
    symbol == "o" ~ "Sana- tai kuvakortti",
    symbol == "p" ~ "Mikroskoopin preparaatti",
    symbol == "q" ~ "Malli",
    symbol == "r" ~ "Esine",
    symbol == "s" ~ "Dia",
    symbol == "t" ~ "Kalvo",
    symbol == "v" ~ "Videotallenne",
    symbol == "w" ~ "Lelu",
    symbol == "z" ~ "Muu",
    symbol == "|" ~ "Ei koodattu",
    TRUE ~ NA_character_
  )
}

# --------------------------------------------------
# Final decoded 008/33
# --------------------------------------------------
df.orig <- df.orig %>%
  mutate(
    converted_008_33 = case_when(
      is.na(field_008) ~ NA_character_,
      data_element_008 == "Kirjat" ~ convert_kirjat(field_008_33),
      data_element_008 == "Elektroniset aineistot" ~ "e-aineisto",
      data_element_008 == "Jatkuvat julkaisut" ~ convert_julkaisut(field_008_33),
      data_element_008 == "Kartat" ~ convert_kartat(field_008_33),
      data_element_008 == "Musiikki" ~ convert_musiikki(field_008_33),
      data_element_008 == "Sekalaiset aineistot" ~ "Sekalaiset aineistot",
      data_element_008 == "Visuaaliset aineistot" ~ convert_visuaaliset(field_008_33),
      TRUE ~ NA_character_
    )
  )

# --------------------------------------------------
# Final decoded kieli 35-37
# --------------------------------------------------

df.orig$language_008 <- substr(df.orig$field_008, 36, 38)
