# 1. Load necessary libraries
library(readxl)
library(dplyr)

# 2. Read the Excel file into the dataframe
velka_list <- read_excel("Kirjallisuuden ensipainokset2.xlsx")

# 3. Rename columns for consistency
colnames(velka_list)[colnames(velka_list) == "MelindaID"] <- "melinda_id"
colnames(velka_list)[colnames(velka_list) == "...5"] <- "title_remainder"
colnames(velka_list)[colnames(velka_list) == "Title"] <- "title"
colnames(velka_list)[colnames(velka_list) == "Publication year"] <- "publication_time"

# 4. Function to split titles into 'title' and 'title_remainder' based on ":"
velka_list$title <- gsub(";", ":", velka_list$title)
split_title <- function(title) {
  if (grepl(":", title)) {  # If ":" exists, split into two parts
    parts <- strsplit(title, " : ")[[1]]  # Split on " : "
    title_part <- parts[1]  # Everything before ":"
    remainder_part <- parts[2]  # Everything after ":"
  } else {
    title_part <- title  # No ":" means entire title stays in 'title'
    remainder_part <- NA  # Set 'title_remainder' to NA
  }
  return(c(title_part, remainder_part))  # Return both parts
}

# 5. Apply the split_title function to the 'title' column
velka_list[c("title", "title_remainder")] <- t(sapply(velka_list$title, split_title))

# 6. Clean the 'melinda_id' and 'signum' columns to remove unnecessary spaces and characters
velka_list$melinda_id <- gsub(" ", "", velka_list$melinda_id)  # Remove spaces
velka_list$melinda_id <- gsub("FCC", "", velka_list$melinda_id)  # Remove "FCC"
velka_list$melinda_id <- as.character(velka_list$melinda_id)  # Convert to character
velka_list$signum <- gsub("\\s+", "", as.character(velka_list$Signum))  # Remove all spaces from 'Signum'

# Clean the corresponding columns in the other dataframe (df.harmonized)
df.harmonized$signum <- gsub("\\s+", "", df.harmonized$signum)  # Remove all spaces
df.harmonized$melinda_id <- as.character(df.harmonized$melinda_id)  # Convert to character
list$melinda_id <- as.character(list$melinda_id)  # Convert to character

# 7. Polish titles by applying custom function (if applicable)
velka_list$title_pol <- polish_title(velka_list$title)

# 8. Prepare dataframes for further operations (copying for testing purposes)
list_test <- list
full_fennica <- df.harmonized
nineteen <- df_pubtime19

# 9. Find melinda_id matches between different datasets
VL <- velka_list$melinda_id  # Unique melinda_ids from velka_list
JL <- list_test$melinda_id  # Unique melinda_ids from list_test

# Identify matching melinda_ids
velka_and_julia <- intersect(VL, JL)
print(velka_and_julia)

# Filter records from the list where melinda_id matches the intersection
velka_and_julia_df <- list %>%
  filter(melinda_id %in% velka_and_julia)

# 11. Identify melinda_ids that are in velka_list but not in list (dirty data)
velka_not_julia_d <- setdiff(VL, JL)  # 2298 values in velka_list but not in list
print(velka_not_julia_d)

# 12. Find melinda_ids that are in both velka_list and full_fennica
velka_and_full_fennica <- intersect(VL, full_fennica$melinda_id)
velka_not_full_fennica <- setdiff(VL, full_fennica$melinda_id)
print(velka_not_full_fennica)

# 13. Filter records from velka_list where melinda_id is not found in full_fennica
velka_not_full_fennica_df <- velka_list %>%
  filter(melinda_id %in% velka_not_full_fennica)

# 14. Clean data by excluding entries that are in both velka_not_julia_d and velka_not_full_fennica
velka_not_julia_c <- setdiff(velka_not_julia_d, velka_not_full_fennica)
print(velka_not_julia_c)

velka_not_julia_df <- df.harmonized %>%
  filter(melinda_id %in% velka_not_julia_c)

# 15. Identify records that are in 'list' but not in 'velka_list'
julia_not_velka <- setdiff(JL, VL)  # 1101 records in list but not in velka_list
print(julia_not_velka)

# 16. Filter records from full_fennica where melinda_id matches those in julia_not_velka
julia_not_velka_df <- full_fennica %>%
  filter(melinda_id %in% julia_not_velka)

# 17. Find matching melinda_ids between velka_list and df_pubtime19
velka_and_19 <- intersect(VL, nineteen$melinda_id)
print(velka_and_19)

# 18. Find melinda_ids in velka_list but not in df_pubtime19
velka_not_19 <- setdiff(VL, nineteen$melinda_id)
print(velka_not_19)

# 19. Further clean data by identifying velka_list entries that are not present in df_pubtime19
velka_not_julia_19 <- setdiff(velka_not_julia_df$melinda_id, nineteen$melinda_id)
print(velka_and_19)

# 20. Export results to CSV
write.table(velka_not_full_fennica_df, file = paste0(output.folder, "velka_not_full_fennica.csv"), quote = FALSE, sep = ";", row.names = FALSE, fileEncoding = "UTF-8")
write.table(velka_list, file = paste0(output.folder, "velka_list.csv"), quote = FALSE, sep = ";", row.names = FALSE, fileEncoding = "UTF-8")


#################################################
#Find titles in velka_list that are not present in list$title
velka_not_julia_titles <- setdiff(velka_list$title_pol$title_harmonized, list$title)
velka_and_julia_titles <- intersect(velka_list$title_pol$title_harmonized, list$title)

# 22. Function to clean titles (remove punctuation and convert to lowercase)
clean_text <- function(text) {
  text <- tolower(text)  # Convert to lowercase
  text <- gsub("[^a-z0-9 ]", "", text)  # Remove punctuation and symbols
  return(text)
}

# 23. Clean titles in velka_list and list
velka_titles_cleaned <- sapply(velka_list$title_pol$title_harmonized, clean_text)
list_titles_cleaned <- sapply(list$title, clean_text)
full_titles_cleaned <- sapply(df.harmonized$title, clean_text)

# 24. Compare cleaned titles and find exact matches (considering word order)
is_match_with_list <- sapply(velka_titles_cleaned, function(velka_title) {
  any(velka_title == list_titles_cleaned)  # Exact match considering order
})

is_match_with_full <- sapply(velka_titles_cleaned, function(velka_title) {
  any(velka_title == full_titles_cleaned)  # Exact match considering order
})

# 25. Get titles from velka_list that don't match any title in list
velka_not_julia_titles <- velka_list$title_pol$title_harmonized[!is_match]
velka_and_julia_titles <- velka_list$title_pol$title_harmonized[is_match]

# 25. Get titles from velka_list that match or not with full harmonized
velka_not_full_titles <- velka_list$title_pol$title_harmonized[!is_match_with_full]
velka_and_full_titles <- velka_list$title_pol$title_harmonized[is_match_with_full]

# 26. Print unmatched titles
print(velka_and_julia_titles)
print(velka_not_julia_titles)
print(velka_not_full_titles)
