
# -------------------------------
# Step 0: Get author metadata with birth/death info
authors_df <- finto::get_kanto(df.orig) %>%
  distinct(author_ID, .keep_all = TRUE) %>%
  rename(
    author_name = prefLabel,
    author_birth = birthDate,
    author_death = deathDate
  ) %>%
  mutate(
    melinda_id = author_ID,
    author_birth = as.numeric(author_birth),
    author_death = as.numeric(author_death),
    author_age = author_death - author_birth,
    author_age = na_if(author_age, 0)
  ) %>%
  select(melinda_id, author_name, author_birth, author_death, author_age)

# -------------------------------
# Step 1: Store harmonized author info
df.tmp <- authors_df
df.harmonized <- df.tmp

# -------------------------------
# Step 2: Save to RDS + CSV
field <- "author_date"
output.folder <- "output.tables/"
if (!dir.exists(output.folder)) dir.create(output.folder)

data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

write.table(df.tmp, file = file.path(output.folder, paste0(field, "_kanto.csv")),
            quote = FALSE, row.names = FALSE, sep = "\t")

# -------------------------------
# Step 3: Summarize accepted/discarded entries
x <- df.tmp$author_birth
y <- df.tmp$author_death
o <- df.tmp$author_name

# Accepted entries
message("Accepted entries in the preprocessed data")
inds <- !is.na(x) & !is.na(y)
accept.file <- file.path(output.folder, paste0(field, "_kanto_accepted.csv"))
tab <- as.data.frame(rev(sort(table(o[inds]))))
tab$Frequency <- round(100 * tab$Freq / sum(tab$Freq), 1)
colnames(tab) <- c("Term", "Count", "Frequency")
write.table(tab, file = accept.file, quote = FALSE, row.names = FALSE, sep = "\t")

# Discarded entries
message("Discarded entries in the original data")
inds1 <- is.na(x) & is.na(y)
discard.file <- file.path(output.folder, paste0(field, "_kanto_discarded.csv"))
tab <- as.data.frame(rev(sort(table(o[inds1]))))
tab$Frequency <- round(100 * tab$Freq / sum(tab$Freq), 1)
colnames(tab) <- c("Term", "Count", "Frequency")
write.table(tab, file = discard.file, quote = FALSE, row.names = FALSE, sep = "\t")
