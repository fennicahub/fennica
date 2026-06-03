#Genre/form data or focus term (NR)

field <- "genre_655"
df.orig[[field]][df.orig[[field]] == ""] <- NA

df.tmp <- polish_genre_655(df.orig[[field]])
df.tmp$melinda_id <- df.orig$melinda_id
df.tmp <- select(df.tmp, melinda_id, everything())


# Ensure the column is character
df.tmp$harmonized <- as.character(trimws(df.tmp$harmonized))
df.tmp$harmonized[df.tmp$harmonized == ""] <- NA

# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL


###############################################################
# Define output files

file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_accepted <- paste0(output.folder, field, "_accepted.csv")
error_list <- paste0(output.folder, field, "_error_list.csv")

# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
# Generate markdown summary
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE)


# ------------------------------------------------------------

# Generate data summaries for the whole data set

message("Accepted entries in the preprocessed data")
s <- write_xtable(as.character(df.tmp$harmonized), file_accepted, count = TRUE)

###############
message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df.tmp$harmonized))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)


message("Error list")

errors <-  tibble(
  melinda_id = df.tmp$melinda_id[inds],
  original_value = df.orig[[field]][
    match(df.tmp$melinda_id[inds], df.orig$melinda_id)
  ]
) %>%
  filter(!is.na(original_value))

tmp1 <- write.csv(errors, 
          file = error_list,
          row.names=FALSE, 
          quote = FALSE,
          fileEncoding = "UTF-8")
# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing
#source("melindas_19.R")

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "genre_655"

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
s <- write_xtable(as.character(df_19[[field]]), file_accepted_19, count = TRUE)

message("Discarded entries for 1809-1917")

# NA values in the final harmonized data
inds <- which(is.na(df_19[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp19 <- write_xtable(as.character(original.na), file_discarded_19, count = TRUE)




