library(devtools)
library(dplyr)
library(tidyr)
library(tm)
library(stringr)
library(knitr)
library(R.utils)
library(ggplot2)
library(Cairo)
library(purrr)
library(stringi)
library(parallel)
library(qdapRegex)
library(readxl)
library(arrow)

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

#load the data
#source("priority_fields.R")

#load the enriched data
source("priority_fields_kanto.R")
#extract from leader-> type_of_record and bibliographic_level and add to data
source("leader.R")

#extract from 008 -> date_entered, publication_status, publication_time,
#genre_book and add to data
source("008_field.R")

#for subset analysis
source("melindas_19.R")

# #initialize df.harmonized
df.harmonized <- data.frame(melinda_id = df.orig$melinda_id,
                            data_element = df.orig$data_element_008,
                            genre_008 = df.orig$converted_008_33,
                            record_type = df.orig$type_of_record,
                            biblio_level = df.orig$bibliographic_level,
                            publication_status = df.orig$publication_status,
                            author_2 = df.orig$`700a`)

#add harmonized data from each field R file

##create csv and save to output_tables
#source("harmonized_fennica.R")
#load all cavs to allas
#source("allas.R")
ntop <- 20
book_author <- "Turku Data Science Group"

knit_bookdown <- TRUE

# Visualization options
theme_set(theme_bw(20))
