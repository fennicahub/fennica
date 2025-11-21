# sources: genderize.io (https://genderize.io/) and henko dataset (https://www.ldf.fi/dataset/henko)
# see genderize.csv and henko_unique_name_gender.csv which were merged into fennica_name_genders.csv see get_names_for_gender.R
#source("author_name_for_gender.R"): get all names that exist in fennica and create fennica_all_names.csv
field <- "gender"

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/fennica_all_names.csv"
df.tmp <- read.delim(
  url,
  header = TRUE,
  sep = "\t",
  quote = "",
  fileEncoding = "UTF-8",
  colClasses = "character",  # all columns as character
  check.names = FALSE
)

# Only replace gender if it's currently NA
df.tmp$gender <- assign_gender(as.character(df.tmp$first))

##add to author_name_for_gender.R
df.tmp$note <- gsub(
  "Koko nimi|Syntymänimi|Aiempi nimi|Tunnetaan myös nimellä|entinen nimi|Kirjoitti myös nimimerkillä|maallikkonimi|Maanmittari|nimi vuoteen|vuodesta|nimi vuodesta|professori|senaattori|valtioneuvos|Ruotsin tiedeakatemian jäsen|Aateloitu 1809|maantieteilijä",
  "",
  df.tmp$note,
  ignore.case = TRUE
)

df.tmp$note <- trimws(df.tmp$note) 
###########

missing_idx <- is.na(df.tmp$gender)
df.tmp$gender[missing_idx] <- assign_gender(df.tmp$note[missing_idx])

df.tmp$gender <- trimws(df.tmp$gender)
df.tmp$gender <- tolower(df.tmp$gender)
df.tmp$gender <- gsub("fmale", "female", df.tmp$gender)
df.tmp$gender <- gsub("fmale", "female", df.tmp$gender)
df.tmp$gender <- gsub("male ", "male", df.tmp$gender)
df.tmp$gender <- gsub("female ", "female", df.tmp$gender)
df.tmp$gender <- gsub("nainen", "female", df.tmp$gender)
df.tmp$gender <- gsub("mies", "male", df.tmp$gender)

df.tmp$gender_primary <- sapply(strsplit(df.tmp$gender, "\\|"), `[`, 1)

df <- df.tmp

################################################################

# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE, sep = ";", row.names = FALSE)

##################################################################

# Define output files for the whole dataset
file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
#add other fields as well
inds <- which(is.na(df.tmp[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)


# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "gender"

write.table(df_19, file = paste0(output.folder, paste0(field, "_19.csv")), quote = FALSE, sep = ";", row.names = FALSE)

# # Define output files for the 1807-1917 subset
# file_accepted_19  <- paste0(output.folder, field, "_accepted_19.csv")
# file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")

# ------------------------------------------------------------

# # Generate data summaries for 1809-1917
#message("Accepted entries in the preprocessed data for 1809-1917")
#s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)
# 
# message("Discarded entries for 1809-1917")
# 
# # NA values in the final harmonized data
# inds <- which(is.na(df_19[[field]]))
# 
# # Original entries that were converted into NA
# original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]
# 
# # .. ie. those are "discarded" cases; list them in a table
#tmp19 <- write_xtable(original.na, file_discarded_19, count = TRUE)
# 

