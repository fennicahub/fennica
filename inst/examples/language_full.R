df.orig <- df.orig |>
  mutate(
    language_full = coalesce(na_if(language_041, ""), language_008)
  )


# Define the field to harmonize
field <- "language_full"

# Harmonize the raw data
out <- polish_languages(df.orig[[field]])
df.tmp <- out
# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL

# Collect the results into a data.frame
df.tmp$id <- df.orig$id

df.tmp <- df.tmp %>%
  dplyr::rename(language = full_language_name)


# Define output files
file_accepted <- paste0(output.folder, field, "_accepted.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set 

message("Accepted languages")
for (myfield in c("language", "language_primary")) {
  tmp <- write_xtable(
    df.tmp[[myfield]],
    paste(output.folder, myfield, "_full_accepted.csv", sep = ""),
    count = TRUE,
    add.percentages = TRUE
  )
}

message("Language conversions")
tab <- cbind(original = df.orig[[field]], df.tmp[, 1:4])
tmp1 <- write_xtable(
  tab,
  paste(output.folder, field, "_conversions.csv", sep = ""),
  count = TRUE,
  add.percentages = TRUE
)

# ------------------------------------------------------------

# Store the language field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.csv(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE)

# ------------------------------------------------------------

# Define output files for 19th century
file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")
file_accepted_19 <- paste0(output.folder, field, "_accepted_19.csv")

#Run ids_19.R to get ids for 1809-1917
#source("ids_19.R")

df_19 <- df.tmp[df.tmp$id %in% ids_19,]
field <- "language"

# Generate data summaries for the subset data set 

message("Accepted languages 19th century")
for (myfield in c("language", "language_primary")) {
  tmp <- write_xtable(df_19[[myfield]], paste(output.folder, myfield, "_full_accepted_19.csv", sep = ""), 
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



