library(devtools)
library(dplyr)
library(tm)
library(stringr)
library(knitr)
library(R.utils)
library(ggplot2)
library(Cairo)

# Install latest version from Github
#install_github("comhis/fennica") # or
# devtools::load_all() # if you are working from the clone and modifying it
library(fennica) 

# Install latest version from Github
# devtools::install_github("comhis/comhis")        
library(comhis)  

# Load misc functions needed for harmonization
source("funcs.R")

# Define create the output folder
output.folder <- "output.tables/"
if (!file.exists(output.folder)) {
  dir.create(output.folder)
}

# List the preprocessed data file and read the data
df.orig <- read_bibliographic_metadata("fennica_parsed.csv.gz", verbose = TRUE, sep = "|")
# df.orig <- sample_n(df.orig, 1000) # Try with a smaller subset first!

# ------------------------------------------------------------

ntop <- 20
book_author <- "Turku Data Science Group"

knit_bookdown <- TRUE

# Visualization options
theme_set(theme_bw(20))