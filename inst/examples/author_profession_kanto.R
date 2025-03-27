
# -------------------------------
# Step 0: Get author metadata, including profession fields
authors_df <- finto::get_kanto(df.orig) %>%
  distinct(author_ID, .keep_all = TRUE) %>%
  rename(
    author_name = prefLabel,
    author_birth = birthDate,
    author_death = deathDate,
    author_profession_en = profession_metadata_profession_prefLabel_en,
    author_profession_fi = profession_metadata_profession_prefLabel_fi
  ) %>%
  mutate(
    melinda_id = author_ID,
    author_birth = as.numeric(author_birth),
    author_death = as.numeric(author_death),
    author_age = author_death - author_birth,
    author_age = na_if(author_age, 0)
  ) %>%
  select(melinda_id, author_name, author_birth, author_death, author_age, author_profession_en, author_profession_fi)

# -------------------------------
# Step 1: Store harmonized author info (birth, death, profession)
df.tmp <- authors_df
df.harmonized <- df.tmp

# -------------------------------
# Step 2: Save to RDS + CSV
field <- "author_data"
output.folder <- "output.tables/"
if (!dir.exists(output.folder)) dir.create(output.folder)

saveRDS(df.tmp, file = paste0(field, ".Rds"))
write.table(df.tmp, file = file.path(output.folder, paste0(field, ".csv")),
            quote = FALSE, row.names = FALSE, sep = "\t")

# -------------------------------
# Step 3: Summarize accepted/discarded entries for profession
o <- df.tmp$author_name
x <- df.tmp$author_profession_en
y <- df.tmp$author_profession_fi

# Accepted professions (English)
message("Accepted professions in English")
write_summary(x, file = file.path(output.folder, paste0("profession_en_summary.csv")))

# Accepted professions (Finnish)
message("Accepted professions in Finnish")
write_summary(y, file = file.path(output.folder, paste0("profession_fi_summary.csv")))

# -------------------------------
# Helper function to write profession summary
write_summary <- function(x, file) {
  n <- rev(sort(table(x)))
  tab <- as.data.frame(n)
  tab$Frequency <- round(100 * tab$Freq / sum(tab$Freq), 1)
  colnames(tab) <- c("Term", "Count", "Frequency")
  write.table(tab, file = file, quote = FALSE, row.names = FALSE, sep = "\t")
}
