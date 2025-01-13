# unpack 008 into columns of interest


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

df.orig$`008` <- ifelse(trimws(df.orig$`008`) == "", NA, df.orig$`008`)


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




#33 - literary_genre for the BOOKs only 

# Create the new column 'literary_genre_book' based on the conditions
df.orig <- df.orig %>%
  mutate(literary_genre_book = ifelse(
    type_of_record %in% c("Language material") & #leader/06 = a
      bibliographic_level %in% c("Monograph/Item"),
    substr(`008`, start =  34, stop =  34),# Extract the  34th character from the '008' column
    "NA"
  ))


df.orig <- df.orig %>%
  mutate(literary_genre_book = case_when(
    literary_genre_book == "0" ~ "Tietokirjallisuus",
    literary_genre_book == "1" ~ "Kaunokirjallisuus",
    literary_genre_book == "d" ~ "Draama",
    literary_genre_book == "e" ~ "Esseet",
    literary_genre_book == "f" ~ "Romaanit",
    literary_genre_book == "h" ~ "Huumori, satiiri jne.",
    literary_genre_book == "i" ~ "Kirjeet", 
    literary_genre_book == "j" ~ "Novellit, kertomukset tai niiden kokoelmat", 
    literary_genre_book == "m" ~ "Yhdistelmä",
    literary_genre_book == "p" ~ "Runot", 
    literary_genre_book == "s" ~ "Puheet, esitelmät", 
    literary_genre_book == "u" ~ "Tuntematon", 
    literary_genre_book == "|" ~ "Ei koodattu", 
  ))