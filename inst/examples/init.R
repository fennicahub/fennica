library(devtools)
library(dplyr)
library(tm)
library(stringr)
library(knitr)
library(R.utils)
library(ggplot2)
library(Cairo)

# Install latest version from Github
# install_github("fennicahub/fennica") # or
# devtools::load_all() # if you are working from the clone and modifying it
library(fennica) 

# Load misc functions needed for harmonization
source("funcs.R")


# Define create the output folder
output.folder <- "output.tables/"
if (!file.exists(output.folder)) {
  dir.create(output.folder)
}

#the file need to be zipped, otherwise it's too big to be put on github
unzip("priority_fields.zip",exdir=".")
# List the preprocessed data file and read the data
df.orig <- read.csv(file = "priority_fields.csv", skip = 1, head = TRUE, sep="\t")

#Merge title and title_remainder

#df.orig$a.4 <- paste(df.orig$a.4, df.orig$b, sep=" ")
#df.orig <- subset(df.orig, select = -b )

#rename column names
df.orig <- df.orig %>% 
  dplyr::rename("melinda_id" = 1, #("035","a")
                "author_name" = 2, # ("100","a")
                "author_date" = 3, # ("100","d")
                "publication_time" = 4, #("260","c")
                "language" = 5, # ("041","a")
                "title_uniform" = 6, # ("240","a")
                "title" = 7, #("245","a")
                "publication_place" = 8, #("260","a")
                "publisher" = 9, #("260","b")
                "physical_dimensions"= 10, # ("300","c"),
                "physical extent" = 11, # ("300","a")
                "publication_frequency" = 12, # ("310","a")
                "publication_interval" = 13, # ("362","a")
                "signum" = 14) # ("callnumbers","a")


# TO be added later as we progress with preprosessing the fields below

#"subject_geography" = 14) #("651","a")





ntop <- 20
book_author <- "Turku Data Science Group"

knit_bookdown <- TRUE

# Visualization options
theme_set(theme_bw(20))
