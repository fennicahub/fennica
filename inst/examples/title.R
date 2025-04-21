# ------------------------------------------------------------
# Title harmonization pipeline
# ------------------------------------------------------------

field <- "title"

# ---------------------------
# 1. Harmonize titles
# ---------------------------
x <- polish_title(df.orig[[field]])

# Collapse multi-component titles into single strings
x$title_original <- sapply(x$title_original, paste, collapse = " ")
x$title_harmonized <- sapply(x$title_harmonized, paste, collapse = " ")

# ---------------------------
# 2. Create processed dataframe
# ---------------------------
df.tmp <- data.frame(
  melinda_id = df.orig$melinda_id,
  original = x$title_original,
  title = x$title_harmonized,
  title_length = x$title_length,
  title_word_count = x$title_word_count,
  stringsAsFactors = FALSE
)

# ---------------------------
# 3. Add to harmonized dataset
# ---------------------------
df.harmonized <- cbind(
  df.harmonized,
  title = df.tmp$title,
  title_length = df.tmp$title_length,
  title_word = df.tmp$title_word_count
)

# ---------------------------
# 4. Output configuration
# ---------------------------
output_files <- list(
  accepted = paste0(output.folder, field, "_accepted.csv"),
  discarded = paste0(output.folder, field, "_discarded.csv"),
  discarded_id = paste0(output.folder, field, "_discarded_id.csv")
)

# ---------------------------
# 5. Generate summaries
# ---------------------------
# Full dataset reports
write_xtable(df.tmp$title, output_files$accepted,
             count = TRUE, add.percentages = TRUE)

# Discarded items processing
discarded_titles <- df.orig[[field]][!df.orig$melinda_id %in% df.tmp$melinda_id[complete.cases(df.tmp)]]
write_xtable(data.frame(original = as.character(discarded_titles)),
             output_files$discarded,
             count = TRUE)

# ---------------------------
# 6. Data storage
# ---------------------------
# Save full dataset
saveRDS(df.tmp, paste0(output.folder, field, ".Rds"))
write.csv(df.tmp, paste0(output.folder, field, ".csv"),
          row.names = FALSE, quote = TRUE)

# ---------------------------
# 7. 19th century subset
# ---------------------------
df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19, ]

# Subset outputs
output_files_19 <- list(
  accepted = paste0(output.folder, field, "_accepted_19.csv"),
  discarded = paste0(output.folder, field, "_discarded_19.csv")
)

# Subset reporting
write_xtable(df_19$title, output_files_19$accepted,
             count = TRUE, add.percentages = TRUE)

discarded_19 <- df.orig[[field]][df.orig$melinda_id %in%
                                   df_19$melinda_id[is.na(df_19$title)]]
write_xtable(data.frame(original = as.character(discarded_19)),
             output_files_19$discarded,
             count = TRUE)

# Save subset
saveRDS(df_19, paste0(output.folder, field, "_19.Rds"))
write.csv(df_19, paste0(output.folder, field, "_19.csv"),
          row.names = FALSE, quote = TRUE)
