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
                "language_original" = 7,  # ("041","h"))
                "042a" = 8, 
                "title_uniform" = 9, # ("240","a")
                "title" = 10, #("245","a")
                "title_remainder" = 11, #(245 b)
                "250a" = 12, 
                "250b" = 13, 
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
                "245n" = 24)

df.orig$melinda_id <- gsub(" ", "", df.orig$melinda_id)
df.orig$melinda_id <- gsub("\\(FI-MELINDA\\)", "", df.orig$melinda_id)
