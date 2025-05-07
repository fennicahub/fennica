
field <- "author_date_kanto"
# TODO make a tidy cleanup function to shorten the code here
df.tmp <- polish_years(df.orig[[field]], check = TRUE, verbose = TRUE)

df.tmp <- df.tmp %>%
  dplyr::rename(author_birth = from) %>%
  dplyr::rename(author_death = till) %>%
  mutate(author_age = author_death-author_birth) %>% # Add author age
  mutate(author_age = na_if(author_age, 0))          # Replace 0 age with NA

# Add melinda id info as first column
df.tmp <- bind_cols(melinda_id = df.orig$melinda_id,
                    author_date = df.orig$author_date, # add field column
                    df.tmp)
rownames(df.tmp) <- NULL

#add harmonized fields to df
df.harmonized <- cbind(df.harmonized,
                       author_birth = df.tmp$author_birth,
                       author_death = df.tmp$author_death,
                       author_age = df.tmp$author_age)


# ------------------------------------------------------------
# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# Generate data summaries for the whole data set
o <- as.character(df.orig[[field]])
x <- as.character(df.tmp[["author_birth"]])
y <- as.character(df.tmp[["author_death"]])

# -------------------

message("Accepted entries in the preprocessed data")
inds <- !is.na(x) & !is.na(y)
accept.file <- paste0(output.folder, field, "_accepted.csv")
tmp <- write_xtable(o[inds],file = accept.file,count = TRUE)


n <- rev(sort(table(o[inds])))
tab <- as.data.frame(n);
tab$Frequency <- round(100 * tab$Freq/sum(tab$Freq), 1)
colnames(tab) <- c("Term", "Count", "Frequency")
write.table(tab, file = accept.file, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")


# -------------------

message("Discarded entries in the original data")
inds1 <- is.na(x) & is.na(y)
discard.file <- paste0(output.folder, field, "_discarded.csv")
n <- rev(sort(table(o[inds1])))
tab <- as.data.frame(n);
tab$Frequency <- round(100 * tab$Freq/sum(tab$Freq), 1)
colnames(tab) <- c("Term", "Count", "Frequency")
write.table(tab, file = discard.file, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")


# Generate markdown summary
df <- readRDS(data.file)
# ------------------------------------------------------------
# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,] # publication time has df.harmonized instead of df.tmp
field <- "author_date"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Generate accepted and discarded files for the 19 century subset


o <- as.character(df.orig[[field]])
x <- as.character(df_19[["author_birth"]])
y <- as.character(df_19[["author_death"]])

# -------------------

message("Accepted entries in the 19th data")
inds <- !is.na(x) & !is.na(y)
accept.file19 <- paste0(output.folder, field, "_accepted_19.csv")
tmp <- write_xtable(o[inds],file = accept.file,count = TRUE)


n <- rev(sort(table(o[inds])))
tab <- as.data.frame(n);
tab$Frequency <- round(100 * tab$Freq/sum(tab$Freq), 1)
colnames(tab) <- c("Term", "Count", "Frequency")
write.table(tab, file = accept.file19, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")


# -------------------

message("Discarded entries in the 19th cebtury data")
inds1 <- is.na(x) & is.na(y)
discard.file19 <- paste0(output.folder, field, "_discarded_19.csv")
n <- rev(sort(table(o[inds1])))
tab <- as.data.frame(n);
tab$Frequency <- round(100 * tab$Freq/sum(tab$Freq), 1)
colnames(tab) <- c("Term", "Count", "Frequency")
write.table(tab, file = discard.file19, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")

# Generate markdown summary
df_19 <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""),
#             output = paste(field, ".md", sep = ""))
