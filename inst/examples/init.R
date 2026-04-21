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
library(textutils)
library(data.table)
library(brms)
library(rnaturalearth)

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

#read csv to get all authors' names in fennica
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/fennica_all_names.csv"
fennica_all_names <- read.delim(url, 
                                header = TRUE, 
                                sep = "\t", 
                                quote = "", 
                                fileEncoding = "UTF-8", 
                                colClasses = "character",  # all columns as character
                                check.names = FALSE)

#enrich with kanto when priority_fields.R changes
#source("kanto_enrichment.R")
#load the data
source("priority_fields.R") 

#enrich with Kanto, see (kanto_enrichment.R) for more information on how to ger df.kanto
source("priority_fields_kanto.R") 

#extract from leader-> type_of_record and bibliographic_level and add to data
source("leader.R")

#extract from 008 -> date_entered, publication_status, publication_time,
#genre_book and add to data
source("008_field.R")

# enrich with signum information
source("holdings_add.R")

#add gender column
source("asteri_gender.R")
df.orig$gender <- as.character(df.orig$gender)

#for subset analysis
source("melindas_19.R")


##create csv and save to output_tables
#source("harmonized_fennica.R")
#load all csvs to allas
#source("allas.R")
ntop <- 20
book_author <- "Turku Data Science Group"

knit_bookdown <- TRUE

# Visualization options
theme_set(theme_bw(20))

