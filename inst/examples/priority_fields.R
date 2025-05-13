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
    language = 7,              # ("041", "a")
    language_original = 8,     # ("041", "h")
    title_uniform = 9,         # ("240", "a")
    title = 10,                # ("245", "a")
    title_remainder = 11,      # ("245", "b")
    `245n` = 12,               # ("245", "n")
    publication_place = 13,    # ("260", "a")
    publisher = 14,            # ("260", "b")
    `264a` = 15,               # ("264", "a")
    physical_dimensions = 16, # ("300", "c")
    physical_extent = 17,      # ("300", "a")
    publication_frequency = 18,# ("310", "a")
    publication_interval = 19, # ("362", "a")
    signum = 20,               # ("callnumbers", "a")
    location_852 = 21,         # ("852", "a")
    UDK = 22,                  # ("080", "a")
    UDK_aux = 23,              # ("080", "x")
    genre_655 = 24,            # ("655", "a")
    `650a` = 25,               # ("650", "a")
    general_note = 26,         # ("500", "a")
    `700a` = 27,               # ("700", "a")
    `700_0` = 28               # ("700", "0")
  )



# Remove duplicate rows
df.orig <- df.orig %>% distinct()

source("priority_fields_kanto.R")
df.orig$author_name_kanto <- df.kanto$author_name_kanto
df.orig$author_date_kanto <- df.kanto$author_date_kanto
df.orig$author_profession <- df.kanto$author_profession_kanto_fi
