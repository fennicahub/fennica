# Define the field to harmonize
field <- "language"

# Harmonize the raw data
out <- polish_languages(df.orig[[field]])
df.tmp <- out
# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL

# Collect the results into a data.frame
df.tmp$melinda_id <- df.orig$melinda_id



# Define output files
file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_discarded_id <- paste0(output.folder, field, "_discarded_id.csv")
file_accepted <- paste0(output.folder, field, "_accepted.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set 

message("Accepted languages")
for (myfield in c("full_language_name", "language_primary")) {
  tmp <- write_xtable(
    df.tmp[[myfield]],
    paste(output.folder, myfield, "_accepted.csv", sep = ""),
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

message("Language discarded")

orig_split <- strsplit(df.tmp$language_original, ";")
full_split <- strsplit(df.tmp$full_language_name, ";")

original.na <- unlist(
  sapply(seq_along(orig_split), function(i) {
    if (is.na(df.tmp$language_original[i]) || is.na(df.tmp$full_language_name[i])) {
      return(character(0))
    }
    bad_idx <- which(trimws(full_split[[i]]) == "Unrecognized")
    
    if (length(bad_idx) == 0) {
      return(character(0))
    }
    
    trimws(orig_split[[i]][bad_idx])
  })
)

original.na <- original.na[!is.na(original.na) & original.na != ""]

tmp_unrecognized <- write_xtable(
  original.na,
  file_discarded,
  count = TRUE,
  add.percentages = TRUE
)

message("Language discarded ID")

matching_rows <- which(
  sapply(full_split, function(x) any(trimws(x) == "Unrecognized"))
)

id <- data.frame(
  id1 = df.orig$melinda_id[matching_rows],
  id2 = df.orig$other_system_id[matching_rows],
  language = df.orig[[field]][matching_rows],
  discarded = sapply(matching_rows, function(i) {
    bad_idx <- which(trimws(full_split[[i]]) == "Unrecognized")
    paste(trimws(orig_split[[i]][bad_idx]), collapse = ";")
  }),
  stringsAsFactors = FALSE
)

write.csv(id, file = file_discarded_id, row.names = FALSE, quote = FALSE)
                    

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


