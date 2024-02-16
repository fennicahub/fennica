library(dplyr)

#the file need to be zipped, otherwise it's too big to be put on github
unzip("aineistotyypit.zip",exdir=".")
# List the preprocessed data file and read the data
df_content <- read.csv(file = "aineistotyypit.csv", skip = 1, head = TRUE, sep="\t")
#rename column names
df_content <- df_content %>% 
  dplyr::rename("melinda_id" = 1, #("035","a")
                "leader" = 2, # ("leader","-")
                "008" = 3, # ("008","-")
                "336" = 4, #("336","a")
                "337" = 5, # ("337","a")
                "338" = 6, # ("338","a")
                "publication_time" = 7, #("260","c")
                "signum" = 8) #("callnumbers","a")

############## for leader #######################################################

# 06 - Type of record
df_content$type_of_record <- substr(df_content$leader, start =  7, stop =  7)

df_content <- df_content %>%
  mutate(type_of_record = case_when(
    type_of_record == 'a' ~ 'Language material',
    type_of_record == 'c' ~ 'Notated music',
    type_of_record == 'd' ~ 'Manuscript notated music',
    type_of_record == 'e' ~ 'Cartographic material',
    type_of_record == 'f' ~ 'Manuscript cartographic material',
    type_of_record == 'g' ~ 'Projected medium',
    type_of_record == 'i' ~ 'Nonmusical sound recording',
    type_of_record == 'j' ~ 'Musical sound recording',
    type_of_record == 'k' ~ 'Two-dimensional nonprojectable graphic',
    type_of_record == 'm' ~ 'Computer file',
    type_of_record == 'o' ~ 'Kit',
    type_of_record == 'p' ~ 'Mixed materials',
    type_of_record == 'r' ~ 'Three-dimensional artifact or naturally occurring object',
    type_of_record == 't' ~ 'Manuscript language material'
  ))


# 07 - Bibliographic level
df_content$bibliographic_level <- substr(df_content$leader, start =  8, stop =  8)

df_content <- df_content %>%
  mutate(bibliographic_level = case_when(
    bibliographic_level == 'a' ~ 'Monographic component part',
    bibliographic_level == 'b' ~ 'Serial component part',
    bibliographic_level == 'c' ~ 'Collection',
    bibliographic_level == 'd' ~ 'Subunit',
    bibliographic_level == 'i' ~ 'Integrating resource',
    bibliographic_level == 'm' ~ 'Monograph/Item',
    bibliographic_level == 's' ~ 'Serial'
    # Add more conditions here if needed
  ))

############## for the 008 ######################################################
#00-05 (Luontipäivä)
df_content$Date_entered <- substr(df_content$`008`, start =  1, stop =  6)

#06 06 - Julkaisuajan tyyppi/Julkaisun tila
df_content$publication_status <- substr(df_content$`008`, start = 7 , stop =  7)

df_content <- df_content %>%
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
  publication_status == 's' ~ 'Single known date/probable date',
  publication_status == 't' ~ 'Publication date and copyright date',
  publication_status == 'u' ~ 'Continuing resource status unknown',
  publication_status == '|' ~ 'No attempt to code'
))



#07-14 (Julkaisuvuosi 1nja 2)
df_content$date <- substr(df_content$`008`, start = 8 , stop =  15)



#33 - genre 

#BOOKS

df_content <- df_content %>%
  mutate(genre_book = ifelse(
    type_of_record %in% c("Language material", "Manuscript language material") &
      bibliographic_level %in% c("Monographic component part", "Collection", "Subunit", "Monograph/Item"),
    substr(`008`, start =  34, stop =  34),# Extract the  34th character from the '008' column
    " "
    ))


df_content <- df_content %>%
  mutate(genre_book = case_when(
    genre_book == "0" ~ "Not fiction (not further specified)",
    genre_book == "1" ~ "Fiction (not further specified)",
    genre_book == "d" ~ "Dramas",
    genre_book == "e" ~ "Essays",
    genre_book == "f" ~ "Novels",
    genre_book == "h" ~ "Humor, satires, etc.",
    genre_book == "i" ~ "Letters"
  ))

#MUSIC

df_content <- df_content %>%
  mutate(genre_music = ifelse(
    type_of_record %in% c("Notated music", "Manuscript notated music",
                          "Nonmusical sound recording", "Musical sound recording"),
    substr(`008`, start =  34, stop =  34),# Extract the  34th character from the '008' column
    " "
  ))


df_content <- df_content %>%
  mutate(genre_music = case_when(
    genre_music == "#" ~ "Not arrangement or transposition or not specified",
    genre_music == "a" ~ "Transposition",
    genre_music == "b" ~ "Arrangement",
    genre_music == "c" ~ "Both transposed and arranged",
    genre_music == "n" ~ " Not applicable",
    genre_music == "u" ~ "Unknown",
    genre_music == "|" ~ "No attempt to code"
  ))


##############################################################################
#some testing codes 

# Function to remove non-numeric characters
remove_non_numeric <- function(x) {
  gsub("[^0-9]", "", x)
}

# Apply the function to each element of the column
df_content$`008_07/10`<- sapply(df_content$`008_07/10`, remove_non_numeric)


# Count the number of empty cells
empty_cells <- sum(is.na(non_matching_rows2$publication_time) |
                     non_matching_rows2$publication_time == "" |
                     non_matching_rows2$publication_time == " ")







