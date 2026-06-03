url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/authors_700_long.csv"


df700 <- read.csv(url,stringsAsFactors = FALSE)

field <- "author_name"


# Full author name (Last, First) 
author <- polish_author(df700[[field]], verbose = TRUE)

# Collect the results into a data.frame
df.tmp_700 <- data.frame(id1 = df700$field_001, 
                         author_name = author$full_name, 
                         first = author$first, 
                         last = author$last)
df.tmp_700$author_name[trimws(df.tmp_700$author_name) == ""] <- NA
df.tmp_700$author_name[trimws(df.tmp_700$author_name) == "NA"] <- NA

df.tmp_700$first[trimws(df.tmp_700$first) == ""] <- NA
df.tmp_700$first[trimws(df.tmp_700$first) == "-"] <- NA
df.tmp_700$first[trimws(df.tmp_700$first) == "NA"] <- NA


df.tmp_700$last[trimws(df.tmp_700$last) == ""] <- NA
df.tmp_700$last[trimws(df.tmp_700$last) == "-"] <- NA
df.tmp_700$last[trimws(df.tmp_700$last) == "NA"] <- NA


# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp_700, file = data.file)
# Generate markdown summary
df700 <- readRDS(data.file)

# Define output files for the whole dataset
file_accepted_700  <- paste0(output.folder, field, "_accepted_700.csv")
file_discarded_700 <- paste0(output.folder, field, "_discarded_700.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp_700[[field]], file_accepted_700, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df.tmp_700[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp_700$id1[inds], df700$field_001), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded_700, count = TRUE)


# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df700_19 <- df.tmp_700[df.tmp_700$id1 %in% melindas_19,]
field <- "author_name"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df700_19, file = data.file)

# Generate markdown summary 
df700_19 <- readRDS(data.file)


# Define output files for the 1807-1917 subset
file_accepted_700_19  <- paste0(output.folder, field, "_accepted_700_19.csv")

# ------------------------------------------------------------

# Generate data summaries for 1809-1917
message("Accepted entries in the preprocessed data for 1809-1917")
s <- write_xtable(df700_19[[field]], file_accepted_700_19, count = TRUE)




