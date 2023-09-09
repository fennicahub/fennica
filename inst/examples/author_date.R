# 
# field <- "author_date"
# 
# # TODO make a tidy cleanup function to shorten the code here
# df.tmp <- polish_years(df.orig[[field]], check = TRUE, verbose = TRUE)
# 
# df.tmp <- df.tmp %>%
#             dplyr::rename(author_birth = from) %>%
#   	    dplyr::rename(author_death = till) %>%
# 	    mutate(author_age = author_death-author_birth) %>% # Add author age
# 	    mutate(author_age = na_if(author_age, 0))          # Replace 0 age with NA
# 
# # Add original row info as first column
# df.tmp <- bind_cols(melinda_id = df.orig$melinda_id,
#                     author_date = df.orig$author_date, # add field column 
#                     df.tmp)
# rownames(df.tmp) <- NULL
# 
# # Store the title field data
# # FIXME: convert to feather or plain CSV
# data.file <- paste0(field, ".Rds")
# saveRDS(df.tmp, file = data.file)
# 
# # ------------------------------------------------------------
# 
# # Generate data summaries
# 
# o <- as.character(df.orig[[field]])
# x <- as.character(df.tmp[["author_birth"]])
# y <- as.character(df.tmp[["author_death"]])
# 
# 
# # -------------------
# 
# message("Accepted entries in the preprocessed data")
# inds <- !is.na(x) & !is.na(y)
# accept.file <- paste0(output.folder, field, "_accepted.csv")
# tmp <- write_xtable(o[inds],file = accept.file,count = TRUE)
# 
# 
# n <- rev(sort(table(o[inds])))
# tab <- as.data.frame(n);
# tab$Frequency <- round(100 * tab$Freq/sum(tab$Freq), 1)
# colnames(tab) <- c("Term", "Count", "Frequency")
# write.table(tab, file = accept.file, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")
# 
# 
# # -------------------
# 
# message("Discarded entries in the original data")
# inds1 <- is.na(x) & is.na(y)
# discard.file <- paste0(output.folder, field, "_discarded.csv")
# n <- rev(sort(table(o[inds1])))
# tab <- as.data.frame(n);
# tab$Frequency <- round(100 * tab$Freq/sum(tab$Freq), 1)
# colnames(tab) <- c("Term", "Count", "Frequency")
# write.table(tab, file = discard.file, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")
# 
# # ------------------------------------------------------------
# 
# # Generate markdown summary 
# df <- readRDS(data.file)
# # tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
# #             output = paste(field, ".md", sep = ""))
# 
# Set the field variable
field <- "author_date"

# Data Cleaning
df.tmp <- polish_years(df.orig[[field]], check = TRUE, verbose = TRUE)

# Rename columns
df.tmp <- df.tmp %>%
  rename(author_birth = from,
         author_death = till)

# Calculate author age and replace 0 age with NA
df.tmp <- df.tmp %>%
  mutate(author_age = author_death - author_birth,
         author_age = na_if(author_age, 0))

# Add original row info as first columns
df.tmp <- df.tmp %>%
  bind_cols(melinda_id = df.orig$melinda_id,
            author_date = df.orig$author_date)

# Reset row names
rownames(df.tmp) <- NULL

# Store the processed data in an RDS file
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# Generate data summaries
o <- as.character(df.orig[[field]])
x <- as.character(df.tmp[["author_birth"]])
y <- as.character(df.tmp[["author_death"]])

# Generate summaries for accepted entries
inds <- !is.na(x) & !is.na(y)
accept.file <- paste0(output.folder, field, "_accepted.csv")
n <- table(o[inds])
tab <- data.frame(Term = names(n),
                  Count = n,
                  Frequency = round(100 * n / sum(n), 1))
write.table(tab, file = accept.file, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")

# Generate summaries for discarded entries
inds1 <- is.na(x) | is.na(y)
discard.file <- paste0(output.folder, field, "_discarded.csv")
n <- table(o[inds1])
tab <- data.frame(Term = names(n),
                  Count = n,
                  Frequency = round(100 * n / sum(n), 1))
write.table(tab, file = discard.file, quote = FALSE, row.names = FALSE, col.names = TRUE, sep = "\t")

# Generate markdown summary
df <- readRDS(data.file)
