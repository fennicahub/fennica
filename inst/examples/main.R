
# ----------------------------------------------------
#            INITIALIZE AND LOAD DATA
# ----------------------------------------------------

source("init.R")

# ----------------------------------------------------
#           PREPROCESS DATA'
# ----------------------------------------------------

# author_date field
source("author_date.R")

# author_name field
source("author_name.R")

# corporate field
#source("corporate.R")

# Language
source("language.R")

#Physiacl dimension
source("physical_dimensions.R")

# holder field
#source("holder.R")

# note_510c field
#source("note_510c.R")

# note_dissertation field
#source("note_dissertation.R")

# note_granter field
#source("note_granter.R")

# note_source field
#source("note_source.R")

# publisher field
source("publisher.R")

#publication_interval field
#source("publication_interval.R")

# Publication place field and derived country- and geoinformation
source("publication_place.R")

# Publication place field and derived country- and geoinformation
source("publication_time.R")

# note_subject_topic field
#source("subject_topic.R")
#source("subject_geography.R")

# successor field
#source("successor.R")

# Title fields
source("title.R")
source("title_uniform.R")

# uncontrolled field
#source("uncontrolled.R")

# Generate an overview with links to the summary files:
knit("overview.Rmd")
# TODO: has to be done after harmonizations are complete, and an aggregated data set can be created
# knit("details.Rmd")
