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

# Column name (MARC code) has to be changed if column is deleted or a new one added. 
# These are also the same columns/fields that we have in rahti qmd book. 
#It is important not to change the names 

#columns_to_pick = [("035","a"),("100","a"),("100","d"),("041","a"),
#("041","h"),("240","a"),("245","a"),("245","b"),("260","a"),
#("260","b"),("260","c"),("300","a"),("300","b"),("300","c"),("310","a"),
#("362","a"),()"651","a",("callnumbers","a")]

df.orig <- df.orig %>% 
  rename("melinda_id" = 1, #("035","a")
         "author_name" = 2, # ("100","a")
         "author_date" = 3, # ("100","d")
         "language" = 4, # ("041","a")
         "title_uniform" = 5, # ("240","a")
         "title" = 6, #("245","a")
         "title_remainder" = 7, #("245","b")
         "publication_place" = 8, #("260","a")
         "publisher" = 9, #("260","b")
         "publication_time" = 10, #("260","c")
         "physical_extent" = 11, # ("300","a")
         "physical_dimensions"= 12) # ("300","c")

# TO be added later as we progress with preprosessing the fields below
         #"publication_frequency" = 15, # ("310","a")
         #"publication_interval" = 16, # ("362","a")
         #"subject_geography" = 17, #()"651","a"
         #"callnumbers" = 18) # ("callnumbers","a")]



# ------------------------------------------------------------

ntop <- 20
book_author <- "Turku Data Science Group"

knit_bookdown <- TRUE

# Visualization options
theme_set(theme_bw(20))

