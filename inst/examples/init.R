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

df.orig$a.4 <- paste(df.orig$a.4, df.orig$b, sep=" ")
df.orig <- subset(df.orig, select = -b )

#rename column names
df.orig <- df.orig %>% 
  dplyr::rename("melinda_id" = 1, #("035","a")
         "author_name" = 2, # ("100","a")
         "author_date" = 3, # ("100","d")
         "language" = 4, # ("041","a")
         "title_uniform" = 5, # ("240","a")
         "title" = 6, #("245","a")
         "publication_place" = 7, #("260","a")
         "publisher" = 8, #("260","b")
         "publication_time" = 9, #("260","c")
         "physical_dimensions"= 10, # ("300","c")
         "publication_frequency" = 11, # ("310","a")
         "publication_interval" = 12) # ("362","a")
         


# TO be added later as we progress with preprosessing the fields below
          # "physical_extent" = 10, # ("300","a")
          #"subject_geography" = 14) #("651","a")
         #"callnumbers" = 18) # ("callnumbers","a")]




ntop <- 20
book_author <- "Turku Data Science Group"

knit_bookdown <- TRUE

# Visualization options
theme_set(theme_bw(20))

