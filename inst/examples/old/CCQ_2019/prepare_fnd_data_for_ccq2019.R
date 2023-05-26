library(ggplot2)
library(tidyr)
library(dplyr)
library(fennica)
library(magrittr)
library(reshape2)
library(gridExtra)
library(knitr)

# ---------------------------------

# Set global parameters
timespan <- c(1500, 1800)
datafile <- "data/unified/polished/df.Rds"
author <- "Lahti, Marjanen, Roivainen, Tolonen"
#fields <- c("publication_year", "publication_place", "title", "language_primary", "languages", "gatherings", "pagecount", "printarea")
fields <- c("publication_year", "publication_place", "title", "language_primary", "languages", "gatherings", "pagecount")

print("Prepare the final data set")
df0 <- readRDS(datafile)

# Year limits
df <- df0
if (exists("timespan")) {
  df <- filter(df,
          publication_year >=  min(timespan) & 
	  publication_year <= max(timespan))
} else {
  # Create timespan but do not filter if not given
  timespan <- range(df$publication_year, na.rm = TRUE)
}

# Include the selected fields
df <- df %>% select(fields) %>%
             arrange(publication_year, publication_place, title, language_primary, gatherings, pagecount)

# Store
write.table(df, file = "data/unified/polished/FNB_20180627.csv", sep = "\t", row.names = FALSE, quote = FALSE)

