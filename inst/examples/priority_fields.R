#the file need to be zipped, otherwise it's too big to be put on github
# Download the zip file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/priority_fields.csv"
#download.file(url, destfile = "priority_fields.csv")
#unzip("priority_fields.zip",exdir=".")

# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df.orig <- read.csv(url, skip = 1, header = TRUE, sep = "\t", colClasses = col_classes)

df.orig <- df.orig %>% 
  dplyr::rename(
    "melinda_id" = 1,  # ("001","a")
    "leader" = 2,  # ("leader", "-")
    "006" = 3,  # ("006", -)
    "008" = 4,  # ("008", "-") - Fix to index 4 for uniqueness
    "author_name" = 5,  # ("100","a")
    "author_date" = 6,  # ("100","d")
    "language" = 7,  # ("041","a")
    "language_original" = 8,  # ("041","h")
    "042a" = 9, 
    "title_uniform" = 10,  # ("240","a")
    "title" = 11,  # ("245","a")
    "title_remainder" = 12,  # ("245 b")
    "250a" = 13,  # Painosmerkintö (ET)
    "250b" = 14,  # Muut painoskohtaiset tiedot (ET)
    "publication_place" = 15,  # ("260","a")
    "publisher" = 16,  # ("260","b")
    "physical_dimensions" = 17,  # ("300c")
    "physical_extent" = 18,  # ("300","a")
    "publication_frequency" = 19,  # ("310","a")
    "publication_interval" = 20,  # ("362","a")
    "signum" = 21,  # ("callnumbers","a")
    "UDK" = 22,  # (080a)
    "080-8" = 23, 
    "080x" = 24, 
    "245n" = 25,  # Numerointitieto (T)
    "655a" = 26,  # Lajityyppiä/muotoa kuvaava termi tai fokustermi (ET)
    "650a" = 27,  # Aihetta ilmaiseva termi tai maantieteellinen nimi (ET)
    "700a" = 28, 
    "264a" = 29  # Correct final index
  )




