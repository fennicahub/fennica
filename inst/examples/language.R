# Define the field to harmonize
field <- "language"

# Harmonize the raw data
out <- polish_languages(df.orig[[field]])
df.tmp <- out$harmonized_full
# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL



# Collect the results into a data.frame
df.tmp$melinda_id <- df.orig$melinda_id


# Define output files
file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_accepted <- paste0(output.folder, field, "_accepted.csv")
file_discarded_id <- paste0(output.folder, field, "_discarded_id.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set 

message("Accepted languages")
for (myfield in c("languages", "language_primary")) {
  tmp <- write_xtable(df.tmp[[myfield]], paste(output.folder, myfield, "_accepted.csv", sep = ""), 
                      count = TRUE, 
                      add.percentages = TRUE)
}

message("Language conversions")
tab <- cbind(original = df.orig[[field]], df.tmp[, 1:4])
tmp1 <- write_xtable(tab, paste(output.folder, field, "_conversions.csv", sep = ""), 
                    count = TRUE,
                    add.percentages = TRUE)

message("Language discarded")
# Original entries that were converted into NA
s <- unlist(strsplit(df.orig$language, ";"))
original.na <- s[s %in% out$unrecognized]
# .. ie. those are "discarded" cases; list them in a table
tmp2 <- write_xtable(original.na, file_discarded, 
                     count = TRUE, 
                     add.percentages = TRUE)

message("Language discraded ID")
language_checks <- sapply(strsplit(df.orig$language, ";"), function(lang) 
  any(original.na %in% lang))
# Find rows where any language matches a discarded variable
matching_rows <- which(language_checks)

# Get the corresponding melinda_ids
result_melinda_ids <- df.orig$melinda_id[matching_rows]
id <- data.frame(
  Melinda_ID = result_melinda_ids,
  Language = df.orig$language[matching_rows]
)

# Add a new column to `id` for discarded languages
id$Discarded <- sapply(strsplit(id$Language, ";"), function(lang) {
  # Find intersection between languages and discarded values
  discarded_langs <- intersect(lang, original.na)
  # Combine discarded languages as a semicolon-separated string
  paste(discarded_langs, collapse = ";")
})

# Write the result to a CSV file without row numbers
#write.csv(id, file = file_discarded_id, row.names = FALSE, quote = FALSE)

tmp3 <- write_xtable(id, file_discarded_id, 
                     count = TRUE, 
                     add.percentages = FALSE)


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
source("melindas_19.R")

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "language"

# Generate data summaries for the subset data set 

message("Accepted languages 19th century")
for (myfield in c("languages", "language_primary")) {
  tmp <- write_xtable(df_19[[myfield]], paste(output.folder, myfield, "_accepted_19.csv", sep = ""), 
                      count = TRUE, 
                      add.percentages = TRUE)
}

message("Language conversions for the 19th century")
tab <- cbind(original = df_19$languages, df_19[, 1:4])
tmp <- write_xtable(tab, paste(output.folder, field, "_conversions_19.csv", sep = ""), 
                    count = TRUE, 
                    add.percentages = TRUE)

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


