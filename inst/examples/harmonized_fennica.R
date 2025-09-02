# #all polished fields in one df 
source("init.R")


# #initialize df.harmonized
df.harmonized <- data.frame(melinda_id = df.orig$melinda_id,
                            data_element = df.orig$data_element_008,
                            genre_008 = df.orig$converted_008_33,
                            record_type = df.orig$type_of_record,
                            biblio_level = df.orig$bibliographic_level,
                            publication_status = df.orig$publication_status)

source("author_name.R")

source("gender.R")
source("author_date.R")
#source("author_date_kanto.R")
df.harmonized <- cbind(df.harmonized, author_profession = df.orig$author_profession)

source("title.R")
source("title_remainder.R")
source("language.R")
source("publication_time.R")
source("publication_place.R")
source("publisher.R")
source("signum.R")
source("udk.R")
source("genre_655.R")

df.processed <- df.harmonized

# Store the data
data.file <- paste0(field, ".Rds")
saveRDS(df.processed, file = data.file)
#Load the RDS file
df.processed <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df.processed, 
            file = paste0(output.folder, "harmonized_fennica.csv"),
            sep = "\t",
            row.names=FALSE, 
            quote = FALSE,
            fileEncoding = "UTF-8")    


###############################################################################


df.processed19 <- df.processed[df.processed$melinda_id %in% melindas_19,] 

# Store the data
data.file <- paste0(field, ".Rds")
saveRDS(df.processed19, file = data.file)
#Load the RDS file
df.processed19 <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df.processed19, 
            file = paste0(output.folder, "harmonized_fennica19.csv"),
            row.names=FALSE, 
            quote = FALSE,
            sep = "\t",
            fileEncoding = "UTF-8")


###############################################################################



