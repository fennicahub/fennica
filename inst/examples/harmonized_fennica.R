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
df.harmonized$author_name <- df$author_name

source("author_date.R")
#add harmonized fields to df
df.harmonized$author_birth <- df.tmp$author_birth
df.harmonized$author_birth <- df.tmp$author_death
df.harmonized$author_birth <- df.tmp$author_age

# source("author_profession.R")
# df.harmonized$author_profession <- df$author_profession

source("title.R")

df.harmonized$title <- df.tmp$title
df.harmonized$title_length <- df.tmp$title_length
df.harmonized$title_word <- df.tmp$title_word_count

source("title_remainder.R")

df.harmonized$title_remainder <- df.tmp$title_remainder
df.harmonized$title_remainder_length <- df.tmp$title_remainder_length
df.harmonized$title_remainder_word <- df.tmp$title_remainder_word_count

source("title2.R")

df.harmonized$title2 <- df.tmp$title2
df.harmonized$title2_length <- df.tmp$title2_length
df.harmonized$title2_word <- df.tmp$title2_word_count

source("language.R")
#add harmonized fields to df

df.harmonized$language <- df.tmp$full_language_name
df.harmonized$language_primary <- df.tmp$language_primary
df.harmonized$language_multi <- df.tmp$multiple
df.harmonized$lang_orig <- df.orig$language_original

source("publication_time.R")

df.harmonized$publication_year_from <- df_pubtime$publication_year_from 
df.harmonized$publication_year_till <- df_pubtime$publication_year_till
df.harmonized$publication_year <- df_pubtime$publication_year
df.harmonized$publication_decade <- df_pubtime$publication_decade

source("publication_place.R")

df.harmonized$publication_place <- df.tmp$publication_place
df.harmonized$publication_country <- df.tmp$publication_country

source("publisher.R")

df.harmonized$publisher <- df.tmp$publisher

# source("signum.R")
# 
df.harmonized$signum <- df.orig$call_number

source("physical_dimensions.R")

df.harmonized$signum <- df.orig$call_number

source("physical_extent.R")
df.harmonized$signum <- df.orig$call_number

source("udk.R")

df.harmonized$udk_orig <- df.orig$UDC 
df.harmonized$udk_harm <- df.tmp$cleaned
df.harmonized$udk_aux <- df.tmp$udk_aux
df.harmonized$udk <- df.tmp$converted
df.harmonized$udk_primary <- df.tmp$primary 
df.harmonized$udk_multi <- df.tmp$multi_udk

source("genre_655.R")

df.harmonized$genre_655 <- df.tmp$harmonized


df.harmonized$id2 <- df.orig$other_system_id
df.harmonized <- unique(df.harmonized)

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

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/harmonized_fennica.csv"
# 
# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

df.processed <- read.csv(url, skip = 0, header = TRUE, sep = "\t", colClasses = col_classes)

df.processed19 <- df.processed[df.processed$melinda_id %in% melindas_19,] 

