#the file need to be zipped, otherwise it's too big to be put on github
# Download the zip file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/priority_fields.csv"
download.file(url, destfile = "priority_fields.csv")
unzip("priority_fields.zip",exdir=".")

# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv("output.tables/priority_fields.csv", nrows = 1, sep = "\t"))

# Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df.orig <- read.csv(file = "output.tables/priority_fields.csv", skip = 1, header = TRUE, sep = "\t",
                    colClasses = col_classes)

#set column names
df.orig <- df.orig %>% 
  dplyr::rename("melinda_id" = 1, #("001","a")
                "leader" = 2, # ("leader", "-")
                "008" = 3, #("008", "-")
                "author_name" = 4, # ("100","a")
                "author_date" = 5, # ("100","d")
                "language" = 6, # ("041","a")
                "language_original" = 7,  # ("041","h"))
                "042a" = 8, 
                "title_uniform" = 9, # ("240","a")
                "title" = 10, #("245","a")
                "title_remainder" = 11, #(245 b)
                "250a" = 12, #Painosmerkintö (ET)
                "250b" = 13, #Muut painoskohtaiset tiedot (ET)
                "publication_place" = 14,#("260","a")
                "publisher" = 15, #("260","b")
                "physical_dimensions"= 16, #300c"),
                "physical_extent" = 17, # ("300","a")
                "publication_frequency" = 18, # ("310","a")
                "publication_interval" = 19, # ("362","a")
                "signum" = 20,  # ("callnumbers","a")
                "UDK" = 21, #(080a)
                "080-8" = 22, 
                "080x" = 23, 
                "245n" = 24, #Numerointitieto (T)
                "655a" = 25, #Lajityyppiä/muotoa kuvaava termi tai fokustermi (ET)
                "650a" = 26, #Aihetta ilmaiseva termi tai maantieteellinen nimi (ET)
                "700a" = 27, 
                "264a"= 28) 




