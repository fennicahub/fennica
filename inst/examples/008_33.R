#source("008_field.R")

field <- "genre_008"

# Filter rows where data_element_008 == "Kirjat" and converted_00_33 is NA
df_genre_008 <- df.orig %>% filter(data_element_008 == "Kirjat")

file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_accepted <- paste0(output.folder, field, "_accepted.csv")

# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df_genre_008, file = data.file)
# Generate markdown summary
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE)


# ------------------------------------------------------------

# Generate data summaries for the whole data set

message("Accepted entries in the preprocessed data")
s <- write_xtable(df_genre_008$converted_008_33, file_accepted, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df_genre_008$converted_008_33))

# Original entries that were converted into NA
original.na <- df.orig[match(df_genre_008$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)


# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df_genre_008[df_genre_008$melinda_id %in% melindas_19,]
field <- "genre_008"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Generate markdown summary 
df_19 <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df_19, file = paste0(output.folder, paste0(field, "_19.csv")), quote = FALSE)


# Define output files for the 1807-1917 subset
file_accepted_19  <- paste0(output.folder, field, "_accepted_19.csv")
file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")

# ------------------------------------------------------------

# Generate data summaries for 1809-1917
message("Accepted entries in the preprocessed data for 1809-1917")
s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)

message("Discarded entries for 1809-1917")

# NA values in the final harmonized data
inds <- which(is.na(df_19[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp19 <- write_xtable(original.na, file_discarded_19, count = TRUE)

