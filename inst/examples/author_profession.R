field <- "author_profession"
df.orig$author_700e[df.orig$author_700e == ""] <- NA

df.prep <- data.frame(melinda_id = df.orig$melinda_id, prof_700e = df.orig$author_700e, prof_kanto = df.orig$author_profession,
                         prof_merge = paste(df.orig$author_700e, 
                                            df.orig$author_profession, sep = ","))

df.prep$prof_harm <- polish_profession(df.prep$prof_merge)

# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id, orig_700e = df.orig$author_700e, orig_kanto = df.orig$author_profession, author_profession = df.prep$prof_harm)

################################################################

# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
# Generate markdown summary
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE)

###########################################################

# Define output files for the whole dataset
file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")

##########################

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE)

#-----------
message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df.tmp[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), "author_700e"]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)


# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "author_profession"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Generate markdown summary
df_19 <- readRDS(data.file)

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
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), "author_700e"]

# .. ie. those are "discarded" cases; list them in a table
tmp19 <- write_xtable(original.na, file_discarded_19, count = TRUE)


