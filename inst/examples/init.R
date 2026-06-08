# in terminal nohup Rscript init.R > render.log 2>&1 &


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

#load the data
source("priority_fields.R") 

#extract from leader-> type_of_record and bibliographic_level and add to data
source("leader.R")

#extract from 008 -> date_entered, publication_status, publication_time,
source("008_field.R")

# enrich with signum information
source("holdings_add.R")

#for subset analysis
source("melindas_19.R")

# uncomment when you need to update 
#source("author_info_data_scripts.R")
#create csv and save to output_tables
#source("harmonized_fennica.R")
#load all csvs to allas
#source("allas.R")
#source("render_quarto.R")
ntop <- 20
book_author <- "Turku Data Science Group"

knit_bookdown <- TRUE

# Visualization options
theme_set(theme_bw(20))

