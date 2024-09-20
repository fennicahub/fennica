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

df.orig$publication_time <- paste(substr(df.orig$`008`, start =  8, stop =  11),  
                                  substr(df.orig$`008`, start =  12, stop =  15),  
                                  sep = "-")
#ignore b and | publication status types of publication time
df.orig$publication_time <- ifelse(df.orig$publication_status %in% c("'No dates given; B.C. date involved'", "'No attempt to code'", "Dates unknown"), NA, df.orig$publication_time)

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


#preferably had to be transfered to polish_years.R 

# df.orig$publication_time <- ifelse(df.orig$publication_time == "    -", NA, df.orig$publication_time)
# df.orig$publication_time <- ifelse(df.orig$publication_time == "    -    ", NA, df.orig$publication_time)
# df.orig$publication_time <- ifelse(df.orig$publication_time == "-    ", NA, df.orig$publication_time)
# df.orig$publication_time <- ifelse(df.orig$publication_time == "-", NA, df.orig$publication_time)
# 
# df.orig <- df.orig %>%
#   mutate(publication_time = ifelse(grepl("^\\s+$", publication_time), NA, publication_time))
# 
# df.orig <- df.orig %>%
#   mutate(publication_time = ifelse(grepl("0000", publication_time), NA, publication_time))
# 
# 
# 
# # Replace cells containing "    -" with NA
# df.orig$publication_time <- ifelse(df.orig$publication_time == "    -", NA, df.orig$publication_time)


#33 - genre for the BOOKs only 

# Create the new column 'genre_book' based on the conditions
df.orig <- df.orig %>%
  mutate(genre_book = ifelse(
    type_of_record %in% c("Language material", "Manuscript language material") &
      bibliographic_level %in% c("Monographic component part", "Collection", "Subunit", "Monograph/Item"),
    substr(`008`, start =  34, stop =  34),# Extract the  34th character from the '008' column
    "NA"
  ))


df.orig <- df.orig %>%
  mutate(genre_book = case_when(
    genre_book == "0" ~ "Tietokirjallisuus (ei tarkkaa määritelmää)",
    genre_book == "1" ~ "Kaunokirjallisuus (ei tarkkaa määritelmää)",
    genre_book == "d" ~ "Draama",
    genre_book == "e" ~ "Esseet",
    genre_book == "f" ~ "Romaanit",
    genre_book == "h" ~ "Huumori, satiiri jne.",
    genre_book == "i" ~ "Kirjeet", 
    genre_book == "j" ~ "Novellit, kertomukset tai niiden kokoelmat", 
    genre_book == "m" ~ "Yhdistelmä",
    genre_book == "p" ~ "Runot", 
    genre_book == "s" ~ "Puheet, esitelmät", 
    genre_book == "u" ~ "Tuntematon", 
    genre_book == "|" ~ "Ei koodattu", 
  ))