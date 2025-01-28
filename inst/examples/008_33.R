#source("008_field.R")

field <- `008_33`

# Select only the 008 columns from df.orig
df.tmp <- df.orig %>%
  select(
    melinda_id, 
    `008`, 
    type_of_record, 
    bibliographic_level, 
    Date_entered, 
    publication_status, 
    data_element_008, 
    `008_33`, 
    converted_008_33
  )
df.tmp1 <- df.tmp %>%
  filter(is.na(converted_008_33))
df.tmp2 <- df.tmp %>%
  filter(!is.na(converted_008_33))


# Define output files
file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_discarded_id <- paste0(output.folder, field, "_discarded_id.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole dataset

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp2, file_accepted, count = TRUE, add.percentages = FALSE)


message("Discarded title")
tmp <- write_xtable(df.tmp1,
                    file = file_discarded_id,
                    count = TRUE,
                    add.percentages = FALSE)

# ------------------------------------------------------------

# Store the title field data

data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the data.files folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")))