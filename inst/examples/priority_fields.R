#the file need to be zipped, otherwise it's too big to be put on github
# Download the zip file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/priority_fields.csv"
download.file(url, destfile = "priority_fields.csv")

#unzip("priority_fields.zip",exdir=".")
# List the pre-processed data file and read the data
df.orig <- read.csv(file = "priority_fields.csv", skip = 1, head = TRUE, sep="\t")

#set column names
df.orig <- df.orig %>% 
  dplyr::rename("melinda_id_001" = 1, #("001","a")
                "melinda_id_035" = 2,
                "leader" = 3, # ("leader", "-")
                "008" = 4, #("008", "-")
                "author_name" = 5, # ("100","a")
                "author_date" = 6, # ("100","d")
                "language" = 7, # ("041","a")
                "language_original" = 8,  # ("041","h"))
                "042a" = 9, 
                "title_uniform" = 10, # ("240","a")
                "title" = 11, #("245","a")
                "title_remainder" = 12, #(245 b)
                "250a" = 13, 
                "250b" = 14, 
                "publication_place" = 15,#("260","a")
                "publisher" = 16, #("260","b")
                "physical_dimensions"= 17, #300c"),
                "physical_extent" = 18, # ("300","a")
                "publication_frequency" = 19, # ("310","a")
                "publication_interval" = 20, # ("362","a")
                "signum" = 21,  # ("callnumbers","a")
                "UDK" = 22, #(080a)
                "080-8" = 23, 
                "080x" = 24, 
                "245n" = 25, 
                "655a" = 26, 
                "650a" = 27)

#df.orig$melinda_id <- gsub(" ", "", df.orig$melinda_id)
#df.orig$melinda_id <- gsub("\\(FI-MELINDA\\)", "", df.orig$melinda_id)


# df.orig$melinda_id[df.orig$melinda_id == ""] <- NA
# sum(is.na(df.orig$melinda_id))
# 
# empty_melinda <- df.orig[is.na(df.orig$melinda_id), ]
#empty_melinda1 <- df.orig[df.orig$melinda_id == "", ]
