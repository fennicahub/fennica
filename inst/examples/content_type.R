library(dplyr)

#the file need to be zipped, otherwise it's too big to be put on github
unzip("aineistotyypit.zip",exdir=".")
# List the preprocessed data file and read the data
df_content <- read.csv(file = "aineistotyypit.csv", skip = 1, head = TRUE, sep="\t")
#rename column names
df_content <- df_content %>% 
  dplyr::rename("melinda_id" = 1, #("035","a")
                "leader" = 2, # ("leader","-")
                "008" = 3, # ("008","-")
                "336" = 4, #("336","a")
                "337" = 5, # ("337","a")
                "338" = 6, # ("338","a")
                "publication_time" = 7, #("260","c")
                "signum" = 8) #("callnumbers","a")


