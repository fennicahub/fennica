# Define the field to harmonize
field <- "language"

df.orig$language <- gsub("\\|", ";", df.orig$language)


# Harmonize the raw data
out <- polish_languages(df.orig[[field]])
df.tmp <- out$harmonized_full

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
tmp <- write_xtable(tab, paste(output.folder, field, "_conversions.csv", sep = ""), 
                    count = TRUE,
                    add.percentages = TRUE)

message("Discarded")
# Original entries that were converted into NA
s <- unlist(strsplit(df.orig$language, ";"))
original.na <- s[s %in% out$unrecognized]
# .. ie. those are "discarded" cases; list them in a table
tmp2 <- write_xtable(original.na, file_discarded, 
                     count = TRUE, 
                     add.percentages = TRUE)

message("Discarded id")

lo <- as.list(original.na)
filtered_df <- df.orig[df.orig$language %in% lo, ]
new_df <- filtered_df[, c("melinda_id", "language")]
tmp3 <- write_xtable(new_df, file_discarded_id, 
                     count = TRUE, 
                     add.percentages = TRUE)


# ------------------------------------------------------------

# Store the language field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")))

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

# Discarded
# Original entries that were converted into NA
s <- unlist(strsplit(df.orig$language, ";"))
original.na <- s[s %in% out$unrecognized]
tmp2 <- write_xtable(original.na, file_discarded_19, 
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

source("allas.R")


