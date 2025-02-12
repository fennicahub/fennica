# Define the field to harmonize
field <- "language"

# Harmonize the raw data
out <- polish_languages(df.orig[[field]])
df.tmp <- out
# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL

# Collect the results into a data.frame
df.tmp$melinda_id <- df.orig$melinda_id

#add harmonized fields to df
df.harmonized <- cbind(df.harmonized,
                       language = df.tmp$full_language_name, 
                       language_primary = df.tmp$language_primary,
                       language_multi = df.tmp$multiple)

# Define output files
file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_discarded_id <- paste0(output.folder, field, "_discarded_id.csv")
file_accepted <- paste0(output.folder, field, "_accepted.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set 

message("Accepted languages")
for (myfield in c("full_language_name", "language_primary")) {
  tmp <- write_xtable(df.tmp[[myfield]], paste(output.folder, myfield, "_accepted.csv", sep = ""), 
                      count = TRUE, 
                      add.percentages = TRUE)
}

message("Language discarded")
# Original entries that were converted into NA

tmp_unrecognized <- df.tmp %>%
  filter(grepl("Unrecognized", full_language_name))

tmp_unrecognized <- tmp_unrecognized %>% select(-c(language_count, multiple, language_primary))

orig_split <- strsplit(as.character(tmp_unrecognized$language_original), ";")
full_split <- strsplit(as.character(tmp_unrecognized$full_language_name), ";")

# Extract the unrecognized abbreviation for each row
tmp_unrecognized$unrecognized_language <- sapply(1:length(orig_split), function(i) {
  # Find the index of "Unrecognized" in the full_language_name
  unrecognized_index <- which(full_split[[i]] == "Unrecognized")
  
  # Use that index to extract the corresponding abbreviation from language_original
  orig_split[[i]][unrecognized_index]
})

select(tmp_unrecognized, melinda_id, language_original, unrecognized_language, full_language_name)

tmp1 <- write_xtable(tmp_unrecognized$unrecognized_language, file_discarded, 
                     count = TRUE,
                     add.percentages = FALSE)

# .. ie. those are "discarded" cases; list them in a table
write.table(tmp_unrecognized,
            file = file_discarded_id,
            sep = "\t",
            row.names = FALSE, 
            quote = FALSE)


# ------------------------------------------------------------

# Store the language field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE)

# ------------------------------------------------------------

# Define output files for 19th century
file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")
file_accepted_19 <- paste0(output.folder, field, "_accepted_19.csv")

#Run melindas_19.R to get melindas for 1809-1917
#source("melindas_19.R")

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "language"

# Generate data summaries for the subset data set 

message("Accepted languages 19th century")
for (myfield in c("full_language_name", "language_primary")) {
  tmp <- write_xtable(df_19[[myfield]], paste(output.folder, myfield, "_accepted_19.csv", sep = ""), 
                      count = TRUE, 
                      add.percentages = TRUE)
}

# ---------------------------------------------------

# Store the field data for a subset 1809-1917
data.file.19 <- paste0(field,"_19", ".Rds")
saveRDS(df_19, file = data.file.19)

# Load the RDS file
df_19 <- readRDS(data.file.19) 

# Convert to CSV and store in the output.tables folder
write.table(df_19, file = paste0(output.folder, paste0(field, "_19", ".csv")))


#load to allas 
#source("allas.R")


