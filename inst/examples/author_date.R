field <- "author_date"

# Empty strings to NA
df.orig[[field]][df.orig[[field]] == ""] <- NA

# TODO make a tidy cleanup function to shorten the code here
df.tmp <- polish_author_years(df.orig[[field]], check = TRUE)

df.tmp <- df.tmp %>%
  dplyr::rename(
    author_birth = from,
    author_death = till
  ) %>%
  mutate(
    author_age = author_death - author_birth,
    
    # fix BCE→CE crossing (no year 0)
    author_age = ifelse(
      !is.na(author_birth) & !is.na(author_death) &
        author_birth < 0 & author_death > 0,
      author_age - 1,
      author_age
    ),
    
    # remove impossible / implausible ages
    author_age = ifelse(
      author_age < 10 | author_age > 110,
      NA,
      author_age
    ),
    
    # remove zero just in case
    author_age = na_if(author_age, 0)
  )         # Replace 0 age with NA

harm <- paste0(
  ifelse(is.na(df.tmp$author_birth), "", df.tmp$author_birth),
  "-",
  ifelse(is.na(df.tmp$author_death), "", df.tmp$author_death)
)
harm <- dplyr::na_if(trimws(harm), "")
harm <- dplyr::na_if(harm, "-")

# Add melinda id info as first column
df.tmp <- bind_cols(melinda_id = df.orig$melinda_id,
                    author_date = harm,
                    df.tmp)
rownames(df.tmp) <- NULL

df_date <- df.tmp

# ------------------------------------------------------------
# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
# Generate markdown summary
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), 
            quote = FALSE, sep = ";", row.names = FALSE)
# Generate data summaries for the whole data set


file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discard <- paste0(output.folder, field, "_discarded.csv")

# -------------------
# Accepted entries
# -------------------

message("Accepted entries in the preprocessed data")

s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE)

# -------------------
# Discarded entries
# -------------------

message("Discarded entries in the original data")

o <- as.character(df.orig[[field]])
x <- as.character(df.tmp[["author_birth"]])
y <- as.character(df.tmp[["author_death"]])

inds.discard <- !is.na(o) & is.na(x) & is.na(y)

tab.discard <- as.data.frame(rev(sort(table(o[inds.discard]))))
tab.discard$Frequency <- round(100 * tab.discard$Freq / sum(tab.discard$Freq), 1)

colnames(tab.discard) <- c("Term", "Count", "Frequency")

write.table(
  tab.discard,
  file = file_discard,
  quote = FALSE,
  row.names = FALSE,
  col.names = TRUE,
  sep = "\t"
)

message("Discarded entries with Melinda IDs")

discard_rows <- data.frame(
  id1 = df.orig$melinda_id[inds.discard],
  id2 = df.orig$other_system_id[inds.discard],
  orig_100d = df.orig$author_date[inds.discard],
  original_value_kanto = o[inds.discard],
  parsed_birth = x[inds.discard],
  parsed_death = y[inds.discard],
  stringsAsFactors = FALSE
)

write.table(
  discard_rows,
  file = paste0(output.folder, field, "_virhelista.csv"),
  quote = FALSE,
  row.names = FALSE,
  col.names = TRUE,
  sep = "\t"
)

# -------------------
# Differences between kanto and fennica
# -------------------

# # Clean original author_date
# orig_clean <- polish_years(df.orig[[field]], check = TRUE) %>%
#   dplyr::rename(
#     birth_100d_clean = from,
#     death_100d_clean = till
#   )
# 
# # Clean Kanto date
# kanto_clean <- polish_years(df.orig$author_date_kanto, check = TRUE) %>%
#   dplyr::rename(
#     birth_kanto_clean = from,
#     death_kanto_clean = till
#   )
# 
# # Compare cleaned values
# date_conflicts_clean <- bind_cols(
#   id1 = df.orig$melinda_id,
#   id2 = df.orig$other_system_id,
#   date_100d_orig = df.orig[[field]],
#   birth_kanto_orig = df.orig$author_birth_date_kanto,
#   death_kanto_orig = df.orig$author_death_date_kanto, 
#   orig_clean, 
#   kanto_clean
#   ) %>%
#   mutate(
#     conflict_clean = (
#       !is.na(birth_100d_clean) &
#         !is.na(birth_kanto_clean) &
#         birth_100d_clean != birth_kanto_clean
#     ) |
#       (
#         !is.na(death_100d_clean) &
#           !is.na(death_kanto_clean) &
#           death_100d_clean != death_kanto_clean
#       )
#   ) %>%
#   filter(conflict_clean)
# 
# date_conflict <- date_conflicts_clean %>%
#   dplyr::select(
#     id1 = id1,
#     id2 = id2,
#     date_100d_orig = date_100d_orig,
#     birth_kanto_orig = birth_kanto_orig,
#     death_kanto_orig = death_kanto_orig
#   )
# 
# tmp <- write.csv(date_conflict,
#                  file = "author_date_discrepancies",
#                  row.names=FALSE, 
#                  quote = FALSE,
#                  fileEncoding = "UTF-8")


#Suset analysis 1809-1917
file_accepted  <- paste0(output.folder, field, "_accepted_19.csv")
df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "author_date"


message("Accepted entries in the preprocessed data")

s <- write_xtable(df_19[[field]], file_accepted, count = TRUE)

# ------------------------------------------------------------
# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)
# Generate markdown summary
df_19 <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df_19, file = paste0(output.folder, paste0(field, "_19.csv")), 
            quote = FALSE, sep = ";", row.names = FALSE)



#source("allas.R")
