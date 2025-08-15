# # Download the csv file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/priority_fields.csv"
# 
# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df.orig <- read.csv(url, skip = 1, header = TRUE, sep = "\t", colClasses = col_classes)

df.orig <- df.orig %>%
  dplyr::rename(
    melinda_id = 1,            # ("001", "-")
    leader = 2,                # ("leader", "-")
    `008` = 3,                 # ("008", "-")
    author_name = 4,           # ("100", "a")
    author_date = 5,           # ("100", "d")
    author_id = 6,             # ("100", "0")
    author_110 = 7,          # ("110", "a")
    author_111 = 8,          # ("111", "a")
    author_700a = 9,                # ("700", "a")
    author_700e = 10,               # ("700", "e")
    author_id_700 = 11,              # ("700", "0")
    language = 12,            # ("041", "a")
    language_original = 13,   # ("041", "h")
    title_uniform = 14,       # ("240", "a")
    title = 15,               # ("245", "a")
    title_remainder = 16,     # ("245", "b")
    `245n` = 17,              # ("245", "n")
    publication_place = 18,   # ("260", "a")
    publisher = 19,           # ("260", "b")
    physical_dimensions = 20,# ("300", "c")
    physical_extent = 21,     # ("300", "a")
    publication_frequency = 22,# ("310", "a")
    publication_interval = 23,# ("362", "a")
    signum = 24,              # ("callnumbers", "a")
    location_852 = 25,        # ("852", "a")
    UDK = 26,                 # ("080", "a")
    UDK_aux = 27,             # ("080", "x")
    genre_655 = 28,           # ("655", "a")
    `650a` = 29,              # ("650", "a")
    general_note = 30,        # ("500", "a")
    `264a` = 31               # ("264", "a")
  )

# Remove duplicate rows
df.orig <- df.orig %>% distinct()

source("priority_fields_kanto.R")
df.orig$author_name_kanto1 <- df.kanto$prefLabel
df.orig$author_name_kanto2 <- df.kanto$altLabel
df.orig$author_name_kantoVAR <- df.kanto$variantName
df.orig$hidden_kanto <- df.kanto$hiddenLabel
df.orig$access_kanto <- df.kanto$authorizedAccessPoint
df.orig$note_kanto <- df.kanto$note

df.orig$author_date_kanto <- df.kanto$author_date_kanto
df.orig$author_profession <- df.kanto$author_profession_kanto_fi
df.orig <- df.orig %>%
  mutate(
    author_id = na_if(author_id, ""),           # Convert "" to NA
    author_id_700 = na_if(author_id_700, ""),   # Convert "" to NA
    asteri = coalesce(author_id, author_id_700) # Use author_id, fallback to author_id_700
  )
