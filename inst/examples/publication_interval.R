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



## COMBINE PUBLICATION-YEAR AND PUBLICATION-INTERVAL FIELDS
# Recognize issues: those that have publication interval or frequency defined

message("Compare with publication year field.")
inds <- which(is.na(df.harmonized$publication_year))  
# When the non-NA entries are unique, use the same year for all
tmp <- cbind(from0 = df.harmonized$publication_year_from[inds],
             till0 = df.harmonized$publication_year_till[inds],
             from = df.harmonized$publication_interval_from[inds],
             till = df.harmonized$publication_interval_till[inds]
)
inds2 <- unname(which(apply(tmp, 1, function (x) {length(unique(na.omit(x)))}) == 1))

y <- unname(apply(matrix(tmp[inds2,], ncol = ncol(tmp)), 1, function (x) {unique(na.omit(x))}))

df.harmonized$publication_year_from[inds[inds2]] <- y
df.harmonized$publication_year_till[inds[inds2]] <- y

message("For conflicting years, select he largest combined span")
tmp <- cbind(from0 = df.harmonized$publication_year_from[inds],
             till0 = df.harmonized$publication_year_till[inds],
             from = df.harmonized$publication_interval_from[inds],
             till = df.harmonized$publication_interval_till[inds]
)

tmp <- matrix(tmp, ncol = ncol(tmp))
mins <- unname(apply(tmp, 1, function (x) {min(x, na.rm = TRUE)}))
maxs <- unname(apply(tmp, 1, function (x) {max(x, na.rm = TRUE)}))

df.harmonized$publication_year_from[inds] <- mins
df.harmonized$publication_year_till[inds] <- maxs

# LL: this uses publication_interval field from df.orig; if that is
# processed separately and stored in its own field in
# df.preprocessed then this can be trivially handled. Note that
# publication_interval is confusingly mixing (at least) to different
# types of information: (1) actual years of the publication
# interval, and (2) the number of publications during the years
# given in the publication_time (df.orig). These should be
# identified and separated.

message("Mark potential first editions")
df.tmp$first_edition <- is_first_edition(df.orig)


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


