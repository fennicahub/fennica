field_birthDate <- "birthDate"
field_deathDate <- "deathDate"

df.tmp_b <- polish_years(df.orig[[field_birthDate]], check = TRUE, verbose = TRUE)
df.tmp_d <- polish_years(df.orig[[field_deathDate]], check = TRUE, verbose = TRUE)

df.tmp <- bind_cols(
  df.tmp_b %>% rename(birth_from = from, birth_till = till),
  df.tmp_d %>% rename(death_from = from, death_till = till)
)

df.tmp <- df.tmp %>%
  mutate(
    birthDate = birth_from,
    deathDate = death_from,
    author_age = deathDate - birthDate,
    author_age = na_if(author_age, 0)
  )

# Add melinda id info as first column
df.tmp <- bind_cols(melinda_id = df.orig$melinda_id,
                    author_date = df.orig$author_date, # add field column
                    birthDate_kanto = df.orig$birthDate,
                    deathDate_kanto = df.orig$deathDate,
                    df.tmp)
rownames(df.tmp) <- NULL

#add harmonized fields to df
df.harmonized <- cbind(df.harmonized,
                       author_birth = df.tmp$birthDate,
                       author_death = df.tmp$deathDate,
                       author_age = df.tmp$author_age)

# -------------------------------
# Step 2: Save to RDS + CSV
field_birthDate <- "birthDate"
field_deathDate <- "deathDate"
field <- paste(field_birthDate, field_deathDate, sep = "_")
output.folder <- "output.tables/"
if (!dir.exists(output.folder)) dir.create(output.folder)

data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

write.table(df.tmp, file = file.path(output.folder, paste0(field, "_kanto.csv")),
            quote = FALSE, row.names = FALSE, sep = "\t")

# -------------------------------
# Step 3: Summarize accepted/discarded entries
o <- paste(df.orig[["birthDate"]], df.orig[["deathDate"]], sep = "-")
x <- as.character(df.tmp[["birthDate_kanto"]])
y <- as.character(df.tmp[["deathDate_kanto"]])

message("Accepted entries in the preprocessed data")
inds <- !is.na(x) & !is.na(y)
accept.file <- paste0(output.folder, field, "_kanto_accepted.csv")
tmp <- write_xtable(o[inds],file = accept.file,count = TRUE)


n <- rev(sort(table(o[inds])))
tab <- as.data.frame(n);
tab$Frequency <- round(100 * tab$Freq/sum(tab$Freq), 1)
colnames(tab) <- c("Term", "Count", "Frequency")
write.table(tab, file = accept.file, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")


message("Discarded entries in the original data")
inds1 <- is.na(x) & is.na(y)
discard.file <- paste0(output.folder, field, "_kanto_discarded.csv")
tmp <- write_xtable(o[inds1],file = discard.file,count = TRUE)

n <- rev(sort(table(o[inds1])))
tab <- as.data.frame(tmp);
tab$Frequency <- round(100 * tab$Count/sum(tab$Count), 1)
colnames(tab) <- c("Term", "Count", "Frequency")
write.table(tab, file = discard.file, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")
