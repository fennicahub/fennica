# 2. Read the Excel file into the dataframe
velka_list_m <- read_excel("Kirjallisuuden ensipainokset2.xlsx")

# 3. Rename columns for consistency
colnames(velka_list_m)[colnames(velka_list_m) == "MelindaID"] <- "melinda_id"
colnames(velka_list_m)[colnames(velka_list_m) == "...5"] <- "title_remainder"
colnames(velka_list_m)[colnames(velka_list_m) == "Title"] <- "title"
colnames(velka_list_m)[colnames(velka_list_m) == "Publication year"] <- "publication_time"



# 6. Clean the 'melinda_id' and 'signum' columns to remove unnecessary spaces and characters
velka_list_m$melinda_id <- gsub(" ", "", velka_list_m$melinda_id)  # Remove spaces
velka_list_m$melinda_id <- gsub("FCC", "", velka_list_m$melinda_id)  # Remove "FCC"
velka_list_m$melinda_id <- as.character(velka_list_m$melinda_id)  # Convert to character
velka_list_m$signum <- gsub("\\s+", "", as.character(velka_list_m$Signum))  # Remove all spaces from 'Signum'

# Clean the corresponding columns in the other dataframe (df.harmonized)
df.harmonized$signum <- gsub("\\s+", "", df.harmonized$signum)  # Remove all spaces
df.harmonized$melinda_id <- as.character(df.harmonized$melinda_id)  # Convert to character
list$melinda_id <- as.character(list$melinda_id)  # Convert to character

# 7. Polish titles by applying custom function (if applicable)
velka_list_m$title_pol <- polish_title(velka_list_m$title)

# 8. Prepare dataframes for further operations (copying for testing purposes)
list_test <- list
full_fennica <- df.harmonized[df.harmonized$melinda_id %in% melindas_19,]


# 9. Find melinda_id matches between different datasets
VL <- velka_list_m$melinda_id  # Unique melinda_ids from velka_list_m
JL <- list_test$melinda_id  # Unique melinda_ids from list_test

# Identify matching melinda_ids
velka_and_julia <- intersect(VL, JL)


# Filter records from the list where melinda_id matches the intersection
velka_and_julia_df <- list %>%
  filter(melinda_id %in% velka_and_julia)

# 11. Identify melinda_ids that are in velka_list_m but not in list (dirty data)
velka_not_julia_d <- setdiff(VL, JL)  # 2298 values in velka_list_m but not in list


# 12. Find melinda_ids that are in both velka_list_m and full_fennica
velka_and_full_fennica <- intersect(VL, full_fennica$melinda_id)
velka_not_full_fennica <- setdiff(VL, full_fennica$melinda_id)


# 13. Filter records from velka_list_m where melinda_id is not found in full_fennica
velka_not_full_fennica_df <- velka_list_m %>%
  filter(melinda_id %in% velka_not_full_fennica)

# 14. Clean data by excluding entries that are in both velka_not_julia_d and velka_not_full_fennica
velka_not_julia_c <- setdiff(velka_not_julia_d, velka_not_full_fennica)


velka_not_julia_df <- full_fennica %>%
  filter(melinda_id %in% velka_not_julia_c)

# 15. Identify records that are in 'list' but not in 'velka_list_m'
julia_not_velka <- setdiff(JL, VL)  # 1101 records in list but not in velka_list_m


# 16. Filter records from full_fennica where melinda_id matches those in julia_not_velka
julia_not_velka_df <- full_fennica %>%
  filter(melinda_id %in% julia_not_velka)

########################

cat("velkka_list:", nrow(velkka_list), "\n")
cat("list:", nrow(list), "\n")
cat("matched_records:", nrow(velka_and_julia_df), "\n")
cat("unmatched_velkka:", length(velka_not_julia_d), "\n")
cat("unmatched_julia:", nrow(julia_not_velka_df), "\n")
cat("not_in_harm19:", length(velka_not_julia_c), "\n")
cat("final_matched_harmonized:", nrow(velka_not_full_fennica_df), "\n")



