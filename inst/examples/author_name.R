field <- "author_name"

# Full author name (Last, First, Full)
author <- polish_author(df.orig[[field]], verbose = TRUE)

# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id, 
                     orig = df.orig$author_name,
                     author_name = author$full_name, 
                     first = author$first, 
                     last= author$last)

df.tmp$first[df.tmp$first == ""] <- NA
df.tmp$first[df.tmp$first == "NA"] <- NA

df.tmp$last[df.tmp$last == ""] <- NA
df.tmp$last[df.tmp$last == "NA"] <- NA
################################################################

# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
# Generate markdown summary
df <- readRDS(data.file)
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

# NA values in the final harmonized data #add other fields as well 
inds <- which(is.na(df.tmp[[field]])) 
# Original entries that were converted into NA 
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field] 
# .. ie. those are "discarded" cases; list them in a table 
tmp <- write_xtable(original.na, file_discarded, count = TRUE)

# Match those rows to original data
matched_inds <- match(df.tmp$melinda_id[inds], df.orig$melinda_id)
# Keep only cases that were NOT NA originally (i.e., became NA)
became_na <- !is.na(df.orig[[field]][matched_inds])
# Select rows that became NA
discarded_rows <- df.orig[matched_inds[became_na], c("melinda_id", "author_name")]
# Write the table with count
tmp <- write.table(discarded_rows, 
                   file = paste0(output.folder, "author_name_100a_discraded.csv"),
                   sep = "\t",
                   row.names=FALSE, 
                   quote = FALSE,
                   fileEncoding = "UTF-8")  

# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "author_name"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Generate markdown summary
df_19 <- readRDS(data.file)


# Define output files for the 1807-1917 subset
field <- "author_name"
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

