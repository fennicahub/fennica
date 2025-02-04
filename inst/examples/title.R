
field <- "title"

# Harmonize the raw data
x <- polish_title(df.orig[[field]])


# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id,
                     original = x$title_original,
                     title = x$title_harmonized,
                     title_length = x$title_length,
                     title_word_count = x$title_word_count)
df.title <- df.tmp


# Define output files
file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_discarded_id <- paste0(output.folder, field, "_discarded_id.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole dataset

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE, add.percentages = TRUE)

message("Discarded entries in the original data")

message("Discarded title")
o <- as.character(df.orig[[field]])
x <- as.character(df.tmp[["title"]])
inds <- which(is.na(x))
discard.file <- paste0(output.folder, field, "_discarded.csv")
tmp <- write_xtable(o[inds],
                    file = discard.file,
                    count = TRUE,
                    add.percentages = TRUE)

# ------------------------------------------------------------

# Store the title field data

data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the data.files folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")))

# Subset 1809-1917 
# ------------------------------------------------------------


#Run melindas_19.R to get melindas for 1809-1917
source("melindas_19.R")

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,] # publication time has df.harmonized instead of df.tmp 
field <- "title"

# Define output files
file_accepted_19  <- paste0(output.folder, field, "_accepted_19.csv")
file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")

# ------------------------------------------------------------

# Generate data summaries for the 19th century

message("Accepted entries in the preprocessed data")
s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE, add.percentages = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df_19[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded_19, count = TRUE, add.percentages = TRUE)

# ------------------------------------------------------------
# Store the title field data

data.file.19 <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file.19)
# Load the RDS file
df_19 <- readRDS(data.file.19) 

# Convert to CSV and store in the output.tables folder
write.table(df_19, file = paste0(output.folder, paste0(field, "_19", ".csv")))

#load to allas 
#source("allas.R")

