#the file need to be zipped, otherwise it's too big to be put on github
unzip("priority_fields.zip",exdir=".")
# List the pre-processed data file and read the data
df.orig <- read.csv(file = "priority_fields.csv", skip = 1, head = TRUE, sep="\t")

#set column names
df.orig <- df.orig %>% 
  dplyr::rename("melinda_id" = 1, #("035","a")
                "leader" = 2, # ("leader", "-")
                "008" = 3, #("008", "-")
                "author_name" = 4, # ("100","a")
                "author_date" = 5, # ("100","d")
                "language" = 6, # ("041","a")
                "title_uniform" = 7, # ("240","a")
                "title" = 8, #("245","b")
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

df.orig$melinda_id <- gsub(" ", "", df.orig$melinda_id)
df.orig$melinda_id <- gsub("\\(FI-MELINDA\\)", "", df.orig$melinda_id)
