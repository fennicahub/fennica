# # Download the csv file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/priority_fields.csv"
# 
# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df.orig <- read.csv(url, skip = 2, header = TRUE, sep = "\t", colClasses = col_classes)

df.orig <- df.orig %>%
  dplyr::rename(
    melinda_id = 1,            # ("001", "-")
    leader = 2,                # ("leader", "-")
    `008` = 3,                 # ("008", "-")
    author_name = 4,           # ("100", "a")
    author_date = 5,           # ("100", "d")
    author_id = 6,             # ("100", "0")
    # author_110 = 7,          # ("110", "a")
    # author_111 = 8,          # ("111", "a")
    language = 7,            # ("041", "a")
    language_original = 8,   # ("041", "h")
    title_uniform = 9,       # ("240", "a")
    title = 10,               # ("245", "a")
    title_remainder = 11,     # ("245", "b")
    `245n` = 12,              # ("245", "n")
    publication_place = 13,   # ("260", "a")
    publisher = 14,           # ("260", "b")
    physical_dimensions = 15,# ("300", "c")
    physical_extent = 16,     # ("300", "a")
    publication_frequency = 17,# ("310", "a")
    publication_interval = 18,# ("362", "a")
    UDK = 19,                 # ("080", "a")
    UDK_aux = 20,             # ("080", "x")
    genre_655 = 21,           # ("655", "a")
    un650 = 22,
    un500 = 22,
    author_700a = 23,                # ("700", "a")
    author_id_700 = 24,              # ("700", "0")
    unknowm1 = 25, 
    un264 = 26
  )

# Remove duplicate rows
df.orig <- df.orig %>% distinct()
df.orig$title2 <- paste(df.orig$title, "|" ,df.orig$title_remainder)
# 
# source("priority_fields_kanto.R")
# df.orig$author_name_kanto1 <- df.kanto$prefLabel
# df.orig$author_name_kanto2 <- df.kanto$altLabel
# df.orig$author_name_kantoVAR <- df.kanto$variantName
# df.orig$hidden_kanto <- df.kanto$hiddenLabel
# df.orig$access_kanto <- df.kanto$authorizedAccessPoint
# df.orig$note_kanto <- df.kanto$note
# df.orig$fuller_first <- df.kanto$fullerFormOfName
# df.orig$related_person <- df.kanto$relatedPersonOfPerson_prefLabel
# 
# df.orig$author_birth_date_kanto <- df.kanto$birthDate
# df.orig$author_death_date_kanto <- df.kanto$deathDate
# df.orig$author_profession <- df.kanto$author_profession_kanto_fi
# df.orig <- df.orig %>%
#   mutate(
#     author_id = na_if(author_id, ""),           # Convert "" to NA
#     author_id_700 = na_if(author_id_700, ""),   # Convert "" to NA
#     asteri = coalesce(author_id, author_id_700) # Use author_id, fallback to author_id_700
#   )
