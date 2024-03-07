field <- "publication_time"

#polish full data
tmp  <- polish_years(df.orig[[field]], check = TRUE)

# Make data.frame
# Make sure if it called df.harmonized for publication_time, other fields have df.tmp 
# because publication_time field is sourced in other field processing files 
df.harmonized <- data.frame(melinda_id = df.orig$melinda_id,
                            publication_year_from = tmp$from,
                            publication_year_till = tmp$till)

# Add publication_year as a separate column (same as "publication_year_from")
df.harmonized$publication_year <- df.harmonized$publication_year_from

# Add publication_decade
df.harmonized$publication_decade <- decade(df.harmonized$publication_year) 


# ---------------------------------------------------------------------
#1M data conversions
message("Write conversions: publication year")
df.harmonized$original <- df.orig[[field]]


xx <- as.data.frame(df.harmonized) %>% filter(!is.na(publication_year)) %>%
  group_by(original, publication_year) %>%
  tally() %>%
  arrange(desc(n))

conversion.file <- paste0(output.folder, field, "_conversion.csv")
tmp <- write.table(xx,
                   file = conversion.file,
                   quote = FALSE,
                   row.names = FALSE)

message("Discarded publication year")
o <- as.character(df.orig[[field]])
x <- as.character(df.harmonized[["publication_year"]])
inds <- which(is.na(x))
discard.file <- paste0(output.folder, field, "_discarded.csv")
tmp <- write_xtable(o[inds],
                    file = discard.file,
                    count = TRUE)

#create a file for discarded with melindas
filtered_df <- df.harmonized %>% filter(is.na(publication_year))%>% filter(!is.na(original))
discarded_id <- filtered_df %>% select(-2, -3, -5)
discard.file.id <- paste0(output.folder, field, "_discarded_id.csv")
tmp <- write_xtable(discarded_id,
                    file = discard.file.id,
                    count = TRUE)


# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df.harmonized, file = data.file)

# Generate markdown summary for the whole data
df_pub_time <- readRDS(data.file)

# ------------------------------------------------------------

#Create subsection for the 19th century only and 
df_pubtime19 <- df.harmonized %>% filter(publication_year > 1808 & publication_year < 1918)
melindas_19 <- df_pubtime19$melinda_id

message("Write conversions: publication year for 1809-1917")
df_pubtime19$original <- df.harmonized[[field]]

xx <- as.data.frame(df_pubtime19) %>% filter(!is.na(publication_year)) %>%
  group_by(original, publication_year, melinda_id) %>%
  tally() %>%
  arrange(desc(n))

conversion.file <- paste0(output.folder, field, "_conversion_19.csv")
tmp <- write.table(xx,
                   file = conversion.file,
                   quote = FALSE,
                   row.names = FALSE)

message("Discarded publication year for 1809-1917")
o <- as.character(df.harmonized[[field]])
x <- as.character(df_pubtime19[["publication_year"]])
inds <- which(is.na(x))
discard.file <- paste0(output.folder, field, "_discarded_19.csv")
tmp <- write_xtable(o[inds],
                    file = discard.file,
                    count = TRUE)

# ---------------------------------------------------

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_pubtime19, file = data.file)

# Generate markdown summary for a subset 1809-1917
df_pubtime19 <- readRDS(data.file)

# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
#             output = paste(field, ".md", sep = ""))

