# #all polished fields in one df 
# source("init.R")
# source("author_name.R")
# source("author_date.R")
# source("title.R")
# source("title_remainder.R")
# source("language.R")
# source("publication_time.R")
# source("publication_place.R")
# source("signum.R")
# source("udk.R")
# source("genre_655.R")


# Store the data
data.file <- paste0(field, ".Rds")
saveRDS(df.harmonized, file = data.file)
#Load the RDS file
df.harmonized <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df.harmonized, 
            file = paste0(output.folder, "harmonized_fennica.csv"),
            sep = "\t",
            row.names=FALSE, 
            quote = FALSE)

###############################################################################


df.harmonized19 <- df.harmonized[df.harmonized$melinda_id %in% melindas_19,] 

# Store the data
data.file <- paste0(field, ".Rds")
saveRDS(df.harmonized19, file = data.file)
#Load the RDS file
df.harmonized19 <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df.harmonized19, 
            file = paste0(output.folder, "harmonized_fennica19.csv"),
            sep = "\t",
            row.names=FALSE, 
            quote = FALSE)
