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
unzip("priority_fields_full_fennica.zip",exdir=".")
# List the preprocessed data file and read the data
df.orig <- read.csv(file = "priority_fields_full_fennica.csv", skip = 1, head = TRUE, sep="\t")

# Column name has to be chabged if column is deleted or a new one added. 
# These are also the same columns/fields that we have in rahti qmd book. 
#It is important not to change the names 

df.orig <- df.orig %>% 
  rename("melinda_id" = 1, 
         "language" = 2, 
         "language_original" = 3,
         "author_name" = 4,
         "author_date" = 5,
         "title_uniform" = 6, 
         "title" = 7,
         "title_remainder" = 8, 
         "publication_place" = 9,
         "publication_name" = 10, 
         "publication_date" = 11,
         "physical_extent" = 12, 
         "other_physical_details" = 13, 
         "physical_dimensions"= 14, 
         "accompanying_material" = 15, 
         "publication_frequency" = 16, 
         "publication_interval" = 17, 
         "subject_geography" = 18, 
         "callnumbers" = 19)



# ------------------------------------------------------------

ntop <- 20
book_author <- "Turku Data Science Group"

knit_bookdown <- TRUE

# Visualization options
theme_set(theme_bw(20))
