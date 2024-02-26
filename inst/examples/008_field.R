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
    publication_status == 'e' ~ 'Detailed date',
    publication_status == 'i' ~ 'Inclusive dates of collection',
    publication_status == 'k' ~ 'Range of years of bulk of collection',
    publication_status == 'm' ~ 'Multiple dates',
    publication_status == 'n' ~ 'Dates unknown',
    publication_status == 'p' ~ 'Date of distribution etc', 
    publication_status == 'q' ~ 'Questionable date',
    publication_status == 'r' ~ 'Reprint/reissue date and original date',
    publication_status == 's' ~ 'Single known date/probable date', # the meaning has to be discussed with the library
    publication_status == 't' ~ 'Publication date and copyright date',
    publication_status == 'u' ~ 'Continuing resource status unknown',
    publication_status == '|' ~ 'No attempt to code'
  ))



#07-14. merge start and end years into one column 

df.orig$publication_time <- paste(substr(df.orig$`008`, start =  8, stop =  11),  
                                  substr(df.orig$`008`, start =  12, stop =  15),  
                                  sep = "-")

#only the start date is kept
df.orig$publication_time <- ifelse(
  df.orig$publication_status == c("Publication date and copyright date"),
  substr(df.orig$publication_time, start =  1, stop = nchar(df.orig$publication_time) -  4),
  df.orig$publication_time
)


#original date is kept
df.orig$publication_time <- ifelse(
  df.orig$publication_status == "Reprint/reissue date and original date",
  substr(df.orig$publication_time, start = nchar(df.orig$publication_time) -  3, stop = nchar(df.orig$publication_time)),
  df.orig$publication_time
)

#did not work on all dates, see in the discarded
df.orig$publication_time <- ifelse(
  df.orig$publication_status == c("Date of distribution etc", "Continuing resource ceased publication","Continuing resource status unknown"),
  "",
  df.orig$publication_time
)


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
    genre_book == "0" ~ "Not fiction (not further specified)",
    genre_book == "1" ~ "Fiction (not further specified)",
    genre_book == "d" ~ "Dramas",
    genre_book == "e" ~ "Essays",
    genre_book == "f" ~ "Novels",
    genre_book == "h" ~ "Humor, satires, etc.",
    genre_book == "i" ~ "Letters", 
    genre_book == "j" ~ "Short stories, stories or their collections", 
    genre_book == "m" ~ "Combination of genres",
    genre_book == "p" ~ "Poems", 
    genre_book == "s" ~ "Speeches, presentations", 
    genre_book == "u" ~ "Unknown", 
    genre_book == "|" ~ "No attempt to code", 
  ))