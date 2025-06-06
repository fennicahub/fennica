
field <- "holder"
df.orig$holder <- gsub("\\|", ";", df$holder)
df.tmp <- data.frame(df.orig[[field]])
df.tmp <- data.frame(corporate = polish_corporate(df.orig[[field]]))
names(df.tmp) <- field

# Raw data
original <- df.orig[[field]]

# Harmonize the raw data
x <- fennica::polish_entry(original)

# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id,
                     holder = x)

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# Define output files
file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")

# ------------------------------------------------------------

# Generate data summaries

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df.tmp[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)

# ------------------------------------------------------------

# Generate markdown summary in note_source.md
df <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
#             output = paste(field, ".md", sep = ""))
