field <- "publisher"

# Generic cleanup for the publisher field
x <- polish_publisher(df.orig[[field]])


# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id,
                     id2 = df.orig$other_system_id,
                     original = df.orig$publisher,
                     publisher = x)

# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
# Generate markdown summary
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.csv(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE, row.names = FALSE)


# Define output files
file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole dataset

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE)


message("Discarded entries in the original data")

discarded <- df.tmp[is.na(df.tmp$publisher) &
                      !is.na(df.tmp$original) &
                      nzchar(trimws(df.tmp$original)), ]

write.csv(
  discarded,
  file = file_discarded,
  quote = FALSE,
  row.names = FALSE
)

# ------------------------------------------------------------

#the 19th century slicing

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "publisher"


# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Define output files
file_accepted_19  <- paste0(output.folder, field, "_accepted_19.csv")
file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")

# ------------------------------------------------------------
# 
# # Generate data summaries for 1809-1917
# 
# message("Accepted entries in the preprocessed data")
s19 <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)


# Convert to CSV and store in the output.tables folder
write.csv(df_19, file = paste0(output.folder, paste0(field, "_19", ".csv")),, quote = FALSE, row.names = FALSE)

