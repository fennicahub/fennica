df <- df.processed
df$language_original <- df.orig$language_original

df$title_2 <- ifelse(is.na(df$title), df$title_remainder, 
                     ifelse(is.na(df$title_remainder), df$title, 
                            paste(df$title, df$title_remainder, sep = " ")))

df$title_2 <- ifelse(is.na(df.orig$`245n`), df$title_2, 
                     paste(df$title_2, df.orig$`245n`, sep = " "))
df$language_original <- df.orig$language_original
# Print number of columns
cat("Number of columns in df:", ncol(df), "\n")

# Print column index and name
col_info <- data.frame(
  Index = seq_along(colnames(df)),
  Name = colnames(df)
)

print(col_info)

df <- df %>%
  select(-(c(
    "author_birth",
    "author_death",
    "author_age",
    "title_length",
    "title_word",
    "title_remainder_length",
    "title_remainder_word",
    "language_primary",
    "language_multi",
    "udk_primary",
    "udk_multi"
  )))


print(col_info)

write.table(df, file = "harmonized_fennica_subsets.csv", 
            sep = "\t",
            row.names = FALSE, 
            quote = FALSE, 
            fileEncoding = "UTF-8")


