field <- "publication_interval"

tmp <- polish_years(df.orig[[field]], check = TRUE)
      
# Add to data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id,
                     publication_interval_from = tmp$from,
              	     publication_interval_till = tmp$till)

message("Enrich publication interval")
# Based on analysis of a random sample of entries in Fennica,
# it seems that when interval is of the form "1908" ie a single year
# the publication interval is in all cases 1908-1908 ie a single year.
# Hence let us augment the interval based on this if till year is missing.
# Assume that all cases with denoted interval have start and end year
# If one is missing, then it means that start and end are the same year
# therefore we fill those missing entries here

df.tmp$publication_interval_from[is.na(df.tmp$publication_interval_from)] <- df.tmp$publication_interval_till[is.na(df.tmp$publication_interval_from)]
df.tmp$publication_interval_till[is.na(df.tmp$publication_interval_till)] <- df.tmp$publication_interval_from[is.na(df.tmp$publication_interval_till)]

message("Discard erroneous entires in publication interval")
# Require that publication interval is within 1400-2000 (indicates error otherwise)
df.tmp$publication_interval_from[df.tmp$publication_interval_from < 1400] <- NA
df.tmp$publication_interval_from[df.tmp$publication_interval_from > 2000] <- NA
df.tmp$publication_interval_till[df.tmp$publication_interval_till < 1400] <- NA
df.tmp$publication_interval_till[df.tmp$publication_interval_till > 2000] <- NA


# ---------------------------------------------------------------------
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
original.na <- df.orig[match(df.tmp$melinda_fi[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)

# ------------------------------------------------------------

# Generate markdown summary in note_source.md
df <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
#             output = paste(field, ".md", sep = ""))


