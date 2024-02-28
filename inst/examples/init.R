library(devtools)
library(dplyr)
library(tm)
library(stringr)
library(knitr)
library(R.utils)
library(ggplot2)
library(Cairo)

# Install latest version from Github
# install_github("fennicahub/fennica") # or
# devtools::load_all() # if you are working from the clone and modifying it
library(fennica) 

# Load misc functions needed for harmonization
source("funcs.R")


# Define create the output folder
output.folder <- "output.tables/"
if (!file.exists(output.folder)) {
  dir.create(output.folder)
}

#the file need to be zipped, otherwise it's too big to be put on github
unzip("priority_fields.zip",exdir=".")
# List the pre-processed data file and read the data
df.orig <- read.csv(file = "priority_fields.csv", skip = 1, head = TRUE, sep="\t")

#rename column names
df.orig <- df.orig %>% 
  dplyr::rename("melinda_id" = 1, #("035","a")
                "leader" = 2, # ("leader", "-")
                "008" = 3, #("008", "-")
                "author_name" = 4, # ("100","a")
                "author_date" = 5, # ("100","d")
                "language" = 6, # ("041","a")
                "title_uniform" = 7, # ("240","a")
                "title" = 8, #("245","a")
                "title_remainder" = 9, #(245 b)
                "publication_place" = 10,#("260","a")
                "publisher" = 11, #("260","b")
                "physical_dimensions"= 12, #300c"),
                "physical_extent" = 13, # ("300","a")
                "publication_frequency" = 14, # ("310","a")
                "publication_interval" = 15, # ("362","a")
                "signum" = 16,  # ("callnumbers","a")
                "UDK" = 17, #(080a)
                "250a" = 18, 
                "250b" = 19, 
                "language_original" = 20,  # ("041","h"))
                "080x" = 21)

#unpack leader 

# 06 - Type of record
df.orig$type_of_record <- substr(df.orig$leader, start =  7, stop =  7)

df.orig <- df.orig %>%
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
df.orig$bibliographic_level <- substr(df.orig$leader, start =  8, stop =  8)

df.orig <- df.orig %>%
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

#  008 into columns of interest
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
  df.orig$publication_status == c("Publication date and copyright date", "Single known date/probable date"),
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




ntop <- 20
book_author <- "Turku Data Science Group"

knit_bookdown <- TRUE

# Visualization options
theme_set(theme_bw(20))