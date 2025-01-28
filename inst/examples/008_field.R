# unpack `008` into columns of interest

df.orig$`008` <- ifelse(trimws(df.orig$`008`) == "", NA, df.orig$`008`)



#00-05 (Luontipäivä)
df.orig$Date_entered <- substr(df.orig$`008`, start =  1, stop =  6)

#06 06 - Julkaisuajan tyyppi/Julkaisun tila
df.orig$publication_status <- substr(df.orig$`008`, start = 7 , stop =  7)

df.orig <- df.orig %>%
  mutate(publication_status = case_when(
    publication_status == 'b' ~ 'No dates given; B.C. date involved',
    publication_status == 'c' ~ 'Continuing resource currently published',
    publication_status == 'd' ~ 'Continuing resource ceased publication',
    publication_status == 'e' ~ 'Detailed date', # DATE1 
    publication_status == 'i' ~ 'Inclusive dates of collection', #  
    publication_status == 'k' ~ 'Range of years of bulk of collection', #virhelista
    publication_status == 'm' ~ 'Multiple dates', # DATE1 
    publication_status == 'n' ~ 'Dates unknown', # virhelista
    publication_status == 'p' ~ 'Date of distribution etc', # date1 
    publication_status == 'q' ~ 'Questionable date', # date1
    publication_status == 'r' ~ 'Reprint/reissue date and original date', # DATE2
    publication_status == 's' ~ 'Single known date/probable date', # DATE1
    publication_status == 't' ~ 'Publication date and copyright date', #DATE1
    publication_status == 'u' ~ 'Continuing resource status unknown',#DATE1 date 1 ja tehdään virhelista 
    publication_status == '|' ~ 'No attempt to code' 
  ))



#07-14. merge start and end years into one column 

df.orig$publication_time <- ifelse(
  is.na(df.orig$`008`),  # Check if the value in df.orig$`008` is NA
  NA,  # Assign NA if the value is NA
  paste(
    substr(df.orig$`008`, start = 8, stop = 11),  # Extract the first part
    substr(df.orig$`008`, start = 12, stop = 15),  # Extract the second part
    sep = " "  # Combine the two parts with a " "
  )
)


#ignore b and | publication status types of publication time
df.orig$publication_time <- ifelse(df.orig$publication_status %in% c("'No dates given; B.C. date involved'", "'No attempt to code'", "Dates unknown"), "", df.orig$publication_time)

#DATE1 
df.orig$publication_time <- ifelse(
  df.orig$publication_status %in% c("Publication date and copyright date",
                                    "Single known date/probable date",
                                    "Detailed date", 
                                    "Multiple dates", 
                                    'Date of distribution etc', 
                                    'Questionable date', 
                                    'Continuing resource status unknown'),
  substr(df.orig$publication_time, start =  1, stop = 4),
  df.orig$publication_time
)


# for Reprint/reissue date and original date only DATE2 is kept
df.orig$publication_time <- ifelse(
  df.orig$publication_status %in% c("Reprint/reissue date and original date"),
  substr(df.orig$publication_time, start = 6, stop = nchar(df.orig$publication_time)),
  df.orig$publication_time
)

# Step 5: Mark publication_time as NA if the 18th character of leader is "8"
df.orig$publication_time <- ifelse(
  substr(df.orig$leader, start = 18, stop = 18) == "8",
  NA,
  df.orig$publication_time
)
#33 paikka `008` kenttä

df.orig <- df.orig %>%
  mutate(
    "008_33" = substr(`008`, 34, 34)
  )


df.orig <- df.orig %>%
  mutate(
    data_element_008 = case_when(
      is.na(`008`) ~ NA_character_,
      # 1) KIRJAT
      # nimiö/06 = 'a' or 't' AND nimiö/07 NOT in ('b', 'i', 's')
      type_of_record %in% c('Language material', 'Manuscript language material') &
        !bibliographic_level %in% c('Serial component part', 'Integrating resource', 'Serial') ~ 
        "Kirjat",
      
      # 2) ELEKTRONISET AINEISTOT
      # nimiö/06 = 'm' AND nimiö/07 in ('b', 'i', 's')
      type_of_record == 'Electronic resource' ~ 
        "Elektroniset aineistot",
      
      # 3) JATKUVAT JULKAISUT
      # nimiö/06 = 'a' or 't' AND nimiö/07 in ('b', 'i', 's')
      type_of_record %in% c('Language material', 'Manuscript language material') &
        bibliographic_level %in% c('Serial component part', 'Integrating resource', 'Serial') ~
        "Jatkuvat julkaisut",
      
      # 4) KARTAT
      # nimiö/06 = 'e' or 'f' AND nimiö/07 in ('b', 'i', 's')
      type_of_record %in% c('Cartographic material', 'Manuscript cartographic material') ~ 
        "Kartat",
      
      # 5) MUSIIKKI
      # nimiö/06 = 'c', 'd', 'i', or 'j' AND nimiö/07 in ('b', 'i', 's') AND 006/00 = 's'
      type_of_record %in% c('Notated music', 'Manuscript notated music', 
                            'Nonmusical sound recording', 'Musical sound recording') ~ 
        "Musiikki",
      
      # 6) SEKALAISET AINEISTOT
      # nimiö/06 = 'p' AND nimiö/07 in ('b', 'i', 's') AND 006/00 = 's'
      type_of_record == 'Mixed materials' ~ 
        "Sekalaiset aineistot",
      
      # 7) VISUAALISET AINEISTOT
      # nimiö/06 = 'g', 'k', 'o', or 'r' AND nimiö/07 in ('b', 'i', 's') AND 006/00 = 's'
      type_of_record %in% c('Projected medium', 'Two-dimensional nonprojectable graphic', 
                            'Kit', 'Three-dimensional artifact or naturally occurring object') ~ 
        "Visuaaliset aineistot",
      
      # Default genre if none of the above conditions are met
      TRUE ~ NA_character_
    )
  )


# Create a conversion function for KIRJAT
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

# Create a conversion function for JATKUVAT JULKAISUT
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

# Create a conversion function for KARTAT
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

# Create a conversion function for MUSIIKKI
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

# Create a conversion function for VISUAALISET AINEISTOT
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


 
# Add the new column with conversion logic
df.orig <- df.orig %>%
  mutate(
    converted_008_33 = case_when(
      is.na(`008`) ~ NA_character_,
      data_element_008 == "Kirjat" ~ convert_kirjat(`008_33`),
      data_element_008 == "Elektroniset aineistot" ~ "e-aineisto",
      data_element_008 == "Jatkuvat julkaisut" ~ convert_julkaisut(`008_33`),
      data_element_008 == "Kartat" ~ convert_kartat(`008_33`),
      data_element_008 == "Musiikki" ~ convert_musiikki(`008_33`),
      data_element_008 == "Sekalaiset aineistot" ~ "Sekalaiset aineistot",
      data_element_008 == "Visuaaliset aineistot" ~ convert_visuaaliset(`008_33`),
      TRUE ~ NA_character_

    )
  )

 