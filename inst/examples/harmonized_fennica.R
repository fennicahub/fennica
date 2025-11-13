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
#add harmonized fields to df
df.harmonized <- cbind(df.harmonized,author_name = df.tmp$author_name)

source("gender.R")
df.harmonized <- cbind(df.harmonized, gender = df.tmp$gender)

source("author_date.R")
#add harmonized fields to df
df.harmonized <- cbind(df.harmonized, 
                       author_birth = df.tmp$author_birth,
                       author_death = df.tmp$author_death,
                       author_age = df.tmp$author_age)
#source("author_date_kanto.R")
df.harmonized <- cbind(df.harmonized, author_profession = df.orig$author_profession)

source("title2.R")

df.harmonized <- cbind(df.harmonized,
                       title = df.tmp$title2,
                       title_length = df.tmp$title2_length,
                       title_word = df.tmp$title2_word_count)

# source("title_remainder.R")
# df.harmonized <- cbind(df.harmonized,
#                        title_remainder = df.tmp$title_remainder, 
#                        title_remainder_length = df.tmp$title_remainder_length,
#                        title_remainder_word = df.tmp$title_remainder_word_count)
source("language.R")
#add harmonized fields to df
df.harmonized <- cbind(df.harmonized,
                       language = df.tmp$full_language_name, 
                       language_primary = df.tmp$language_primary,
                       language_multi = df.tmp$multiple)

source("publication_time.R")

df.harmonized <- cbind(df.harmonized, 
                       publication_year_from = df_pubtime$publication_year_from, 
                       publication_year_till = df_pubtime$publication_year_till, 
                       publication_year = df_pubtime$publication_year,
                       publication_decade = df_pubtime$publication_decade)

source("publication_place.R")

df.harmonized <- cbind(df.harmonized,
                       publication_place = df.tmp$publication_place, 
                       publication_country = df.tmp$publication_country)

source("publisher.R")

df.harmonized <- cbind(df.harmonized, publisher = df.tmp$publisher)
source("signum.R")

df.harmonized <- cbind(df.harmonized, signum = df.tmp$signum_harmonized)

source("udk.R")

df.harmonized <- cbind(df.harmonized,
                       udk_orig = df.orig$UDK, 
                       udk_aux = df.tmp$udk_aux,
                       udk = df.tmp$converted, 
                       udk_primary = df.tmp$primary, 
                       udk_multi = df.tmp$multi_udk)
source("genre_655.R")
df.harmonized <- cbind(df.harmonized, genre_655 = df.tmp$harmonized)

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



