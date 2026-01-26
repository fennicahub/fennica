field <- "author_profession"
df.orig$author_700e[df.orig$author_700e == ""] <- NA
df.orig$author_profession[df.orig$author_profession == ""] <- NA

df.prep <- data.frame(
  melinda_id = df.orig$melinda_id,
  prof_700e  = df.orig$author_700e,
  prof_kanto = df.orig$author_profession,
  prof_merge = {
    a <- df.orig$author_700e
    b <- df.orig$author_profession
    
    a[is.na(a)] <- ""
    b[is.na(b)] <- ""
    
    m <- paste(a, b, sep = ",")
    m <- gsub("^,+|,+$", "", m)   # drop leading/trailing comma if one side empty
    m[m == ""] <- NA              # if both were missing -> NA
    m
  },
  stringsAsFactors = FALSE
)

tmp <- polish_profession(df.prep$prof_merge)

# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id, 
                     orig_700e = df.orig$author_700e, 
                     orig_kanto = df.orig$author_profession, 
                     author_profession = tmp$profession_clean, 
                     profession_primary = tmp$prof_primary)

unique_prof <- df.tmp %>%
  filter(!is.na(author_profession)) %>%
  separate_rows(author_profession, sep = ",") %>%
  mutate(author_profession = trimws(author_profession)) %>%
  distinct(author_profession) %>%
  pull(author_profession)


file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_unique <- paste0(output.folder, field, "_unique.csv")
################################################################

message("Accepted languages")
tmp <- write_xtable(df.tmp$author_profession, file_accepted, 
                      count = TRUE, 
                      add.percentages = TRUE)

tmp1 <- write_xtable(unique_prof, file_unique, 
                    count = TRUE, 
                    add.percentages = TRUE)

message("Discarded entries in the original data")

# Define non-missing input rows (had something in prof_merge)
input_nonmissing <- !is.na(df.prep$prof_merge) & df.prep$prof_merge != ""

# Rows that were converted to NA by polishing: input existed, output is NA
inds_converted <- which(input_nonmissing & is.na(df.tmp$author_profession))

n_input_nonmissing <- sum(input_nonmissing)
n_converted <- length(inds_converted)
p_converted <- if (n_input_nonmissing > 0) n_converted / n_input_nonmissing else NA_real_

message("Input non-missing prof_merge rows: ", n_input_nonmissing)
message("Converted to NA in df.tmp$author_profession: ", n_converted)
message("Proportion converted: ", round(p_converted, 4))

# Original entries that were converted into NA (from df.prep, not df.orig)
original_converted <- df.prep$prof_merge[inds_converted]

# Write discarded table
tmp2 <- write_xtable(original_converted, file_discarded, count = TRUE)


# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# Generate markdown summary
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE)

###########################################################

# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "author_profession"

# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Generate markdown summary
df_19 <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df_19, file = paste0(output.folder, paste0(field, "_19.csv")), quote = FALSE)


