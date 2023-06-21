library(ggplot2)
library(tidyr)
library(dplyr)
library(fennica)
library(magrittr)
library(reshape2)
library(gridExtra)
library(knitr)
library(stringr)
# library(comhis)

# Set global parameters
# timespan <- c(1400, 1920)
if (!exists("timespan")) {
  timespan <- range(df$publication_year, na.rm = TRUE)
}

datafile <- "df.Rds" # Final preprocessed, enriched, validated data
datafile.orig <- "df.raw.Rds" # Original raw data entries for comparison

