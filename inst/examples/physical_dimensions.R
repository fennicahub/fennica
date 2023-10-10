field <- "physical_dimensions"

synonyms <- read.csv("../extdata/translation_fi_en_pages.csv", sep = ";")
df.orig$physical_dimensions <- map(df.orig$physical_dimensions,
          synonyms, mode = "recursive")

# Fill in missing entries where estimates can be obtained:
# area, width, height, gatherings
# (also keep pure originals before fill in)


df.tmp <- polish_dimensions(df.orig[[field]], fill = TRUE, verbose = TRUE)

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

# Generate markdown summary 
df <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
#             output = paste(field, ".md", sep = ""))

