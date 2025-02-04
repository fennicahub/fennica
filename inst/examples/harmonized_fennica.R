#all polished fields in one df 

#add publicatiom time fields
df.harmonized <- data.frame(melinda_id = df.orig$melinda_id,
                            author_name = df.author$author_name,
                            author_birth = df.author_date$author_birth, 
                            author_death = df.author_date$author_death,
                            author_age = df.author_date$author_age,
                            title = df.title$title, 
                            title_length = df.title$title_length,
                            title_word = df.title$title_word_count,
                            title_remainder = df.title_remainder$title_remainder, 
                            title_remainder_length = df.title_remainder$title_remainder_length,
                            title_remainder_word = df.title_remainder$title_remainder_word_count,
                            language = df.language$full_language_name, 
                            language_primary = df.language$language_primary,
                            language_multi = df.language$multiple, 
                            publication_year_from = df_pubtime$publication_year_from, 
                            publication_year_till = df_pubtime$publication_year_till, 
                            publication_year = df_pubtime$publication_year, 
                            publication_decade = df_pubtime$publication_decade,
                            publication_place = df.publication_place$publication_place, 
                            publication_country = df.publication_place$publication_country, 
                            publucation_longitude = df.publication_place$longitude, 
                            publication_latitude = df.publication_place$latitude,
                            signum = df.signum$signum_harmonized, 
                            udk = df.udk$converted, 
                            udk_primary = df.udk$primary, 
                            udk_multi = df.udk$multi_udk,
                            data_element = df.orig$data_element_008,
                            genre = df.orig$converted_008_33, 
                            record_type = df.orig$type_of_record, 
                            biblio_level = df.orig$bibliographic_level, 
                            publication_status = df.orig$publication_status) 
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
