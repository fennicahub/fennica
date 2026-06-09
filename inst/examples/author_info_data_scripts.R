source("init.R")

# create df.orig
source("priority_fields.R")

# get_kanto() and create "fennica_enriched.parquet"
# it takes a long time to run this code, do it when you need to update only
#source("kanto_enrichment.R")

#create df.kanto 
source("priority_fields_kanto.R")

#harmonize authors from 700a
source("700_authors.R")

# create authors_df with all asteri id found in fennica
source("author_by_id.R")

#harmonized all kanto fields and create names_df
source("kanto_harmonized.R")

#create dataframe with all names for each record 
source("all_names_by_system_id.R")

#create database of all unique auhtors and info
source("author_database.R")


