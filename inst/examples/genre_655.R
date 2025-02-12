#Genre/form data or focus term (NR)

field <- "genre_655"

df.tmp <- polish_genre_655(df.orig[[field]], chunk_size = 1000)
df.tmp$melinda_id <- df.orig$melinda_id
df.tmp <- select(df.tmp, melinda_id, everything())
df.tmp <- df.tmp %>%
  mutate(
    genre_655 = ifelse(!is.na(finnish), finnish,
                       ifelse(!is.na(swedish), swedish,
                              english)))

# Ensure the column is character
df.tmp$harmonized <- as.character(df.tmp$harmonized)

# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL

#add harmonized fields to df
df.harmonized <- cbind(df.harmonized,
                       genre_655 = df.tmp$harmonized)


###############################################################
# Define output files

file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_accepted <- paste0(output.folder, field, "_accepted.csv")

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
s <- write_xtable(df.tmp$harmonized, file_accepted, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df.tmp$genre_655))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

unique_655 <- unique(trimws(unlist(strsplit(df.tmp$harmonized, ";"))))
genre_lang_df <- read.csv("genre_655.csv", sep = ";", stringsAsFactors = FALSE)
difference_unique <- na.omit(setdiff(unique_655, genre_lang_df$genre))

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(difference_unique, file_discarded, count = TRUE)


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
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp19 <- write_xtable(original.na, file_discarded_19, count = TRUE)




