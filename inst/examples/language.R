# Define the field to harmonize
field <- "language"

# Harmonize the raw data
out <- polish_languages(df.orig[[field]])
df.tmp <- out$harmonized_full

# Collect the results into a data.frame
df.tmp$melinda_id <- df.orig$melinda_id

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# Define output files
file_discarded <- paste0(output.folder, field, "_discarded.csv")

# ------------------------------------------------------------

# Generate data summaries

message("Accepted languages")
for (myfield in c("languages", "language_original")) {
  tmp <- write_xtable(df.tmp[[myfield]], paste(output.folder, myfield, "_accepted.csv", sep = ""), count = TRUE)
}

message("Language conversions")
tab <- cbind(original = df.orig[[field]], df.tmp[, 1:4])
tmp <- write_xtable(tab, paste(output.folder, field, "_conversions.csv", sep = ""), count = TRUE)

# Discarded
# Original entries that were converted into NA
s <- unlist(strsplit(df.orig$language, ";"))
original.na <- s[s %in% out$unrecognized]

# .. ie. those are "discarded" cases; list them in a table
tmp2 <- write_xtable(original.na, file_discarded, count = TRUE)

# ------------------------------------------------------------

# Generate markdown summary in title.md
 df <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
#             output = paste(field, ".md", sep = ""))


