# Download the csv file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/priority_fields.csv"

# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df.orig <- read.csv(url, skip = 1, header = TRUE, sep = "\t", colClasses = col_classes)

df.orig <- df.orig %>%
  dplyr::rename(
    melinda_id = 1,  # ("001", "-")
    leader = 2,  # ("leader", "-")
    `008` = 3,  # ("008", "-")
    author_name = 4,  # ("100", "a")
    author_date = 5,  # ("100", "d")
    author_id = 6,  # ("100", "0")
    language = 7,  # ("041", "a")
    language_original = 8,  # ("041", "h")
    title_uniform = 9,  # ("240", "a")
    title = 10,  # ("245", "a")
    title_remainder = 11,  # ("245", "b")
    publication_place = 12,  # ("260", "a")
    publisher = 13,  # ("260", "b")
    physical_dimensions = 14,  # ("300", "c")
    physical_extent = 15,  # ("300", "a")
    publication_frequency = 16,  # ("310", "a")
    publication_interval = 17,  # ("362", "a")
    signum = 18,  # ("callnumbers", "a")
    location_852 = 19,  # ("852", "a")
    UDK = 20,  # ("080", "a")
    UDK_aux = 21,  # ("080", "x")
    `245n` = 22,  # ("245", "n")
    genre_655 = 23,  # ("655", "a")
    `650a` = 24,  # ("650", "a")
    general_note = 25,  # ("500", "a")
    `700a` = 26,  # ("700", "a")
    `700_0` = 27,  # ("700", "0")
    `264a` = 28  # ("264", "a")
  )

# Remove duplicate rows
df.orig <- df.orig %>% distinct()

