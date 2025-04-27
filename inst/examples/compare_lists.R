library(tidyverse)
library(stringi)

# Replace NA values with empty strings
library(dplyr)
# Clean column names by removing leading/trailing whitespaces
colnames(list) <- trimws(colnames(list))

# Alternatively, you can use make.names() to ensure valid column names
colnames(list) <- make.names(colnames(list), unique = TRUE)


list <- list %>%
  mutate(
    title_remainder = replace_na(title_remainder, ""),
    title_2 = replace_na(title_2, ""),
    title = replace_na(title, ""),
    title_3 = replace_na(title_3, "")
  )



# Normalize text columns
normalize_text <- function(x) str_to_lower(stri_trans_general(x, "Latin-ASCII"))

velkka_list <- velkka_list %>%
  mutate(
    author_harmonized = normalize_text(author_harmonized),
    title_harmonized = normalize_text(title_harmonized)
  )

list <- list %>%
  mutate(
    title = normalize_text(title),
    title_2 = normalize_text(title_2),
    title_3 = normalize_text(title_3),
    author_name = normalize_text(author_name),
    title_remainder = normalize_text(title_remainder)
  )

# 1. Match by melinda_id
matched_records_melinda <- velkka_list %>%
  inner_join(list, by = "melinda_id")

unmatched_records_melinda <- velkka_list %>%
  anti_join(matched_records_melinda, by = "melinda_id")

# 2. Match by author + year + title_2
matched_records_title_2 <- unmatched_records_melinda %>%
  inner_join(list, by = c("author_harmonized" = "author_name",
                          "publication_time" = "publication_year",
                          "title_harmonized" = "title_2"))

unmatched_records_title_2 <- unmatched_records_melinda %>%
  anti_join(matched_records_title_2, by = c("author_harmonized", "publication_time", "title_harmonized"))

# 3. Match by title
matched_records_title <- unmatched_records_title_2 %>%
  inner_join(list, by = c("author_harmonized" = "author_name",
                          "publication_time" = "publication_year",
                          "title_harmonized" = "title"))

unmatched_records1 <- unmatched_records_title_2 %>%
  anti_join(matched_records_title, by = c("author_harmonized", "publication_time", "title_harmonized"))

# 4. Match by title_3
matched_records_title_3 <- unmatched_records1 %>%
  inner_join(list, by = c("author_harmonized" = "author_name",
                          "publication_time" = "publication_year",
                          "title_harmonized" = "title_3"))

unmatched_final <- unmatched_records1 %>%
  anti_join(matched_records_title_3, by = c("author_harmonized", "publication_time", "title_harmonized"))

# 5. Match by title_remainder
matched_records_title_rem <- unmatched_final %>%
  inner_join(list, by = c("publication_time" = "publication_year",
                          "title_harmonized" = "title_remainder"))

unmatched_still <- unmatched_final %>%
  anti_join(matched_records_title_rem, by = c("publication_time", "title_harmonized"))

# 6. Match by title + year again (as fallback)
matched_year_title <- unmatched_still %>%
  inner_join(list, by = c("publication_time" = "publication_year",
                          "title_harmonized" = "title"))

unmatched_final1 <- unmatched_still %>%
  anti_join(matched_year_title, by = c("publication_time", "title_harmonized"))

# Combine all matched records
matched_records <- bind_rows(
  matched_records_melinda,
  matched_records_title_2,
  matched_records_title,
  matched_records_title_3,
  matched_records_title_rem,
  matched_year_title
)

# Find unmatched rows from `list` (Julia’s list not matched by Melinda IDs)
unmatched_julia <- anti_join(list, matched_records, by = "melinda_id")

# Extra matching using df.harmonized19
df.harmonized19 <- df.harmonized19 %>%
  mutate(
    across(c(title, title_2, title_3, author_name), normalize_text),
    title_3 = gsub(" na", "", title_3)
  )

# Match by publication_year + title hierarchy
final_match_index <- match(
  paste(unmatched_final1$publication_time, unmatched_final1$title_harmonized),
  paste(df.harmonized19$publication_year, df.harmonized19$title)
)

match_index_year_title2 <- match(
  paste(unmatched_final1$publication_time[is.na(final_match_index)],
        unmatched_final1$title_harmonized[is.na(final_match_index)]),
  paste(df.harmonized19$publication_year, df.harmonized19$title_2)
)

final_match_index[is.na(final_match_index)] <- match_index_year_title2

match_index_year_title3 <- match(
  paste(unmatched_final1$publication_time[is.na(final_match_index)],
        unmatched_final1$title_harmonized[is.na(final_match_index)]),
  paste(df.harmonized19$publication_year, df.harmonized19$title_3)
)

final_match_index[is.na(final_match_index)] <- match_index_year_title3

# Final combined matches
final_matched_velkka <- unmatched_final1[!is.na(final_match_index), ]
final_matched_harmonized <- df.harmonized19[final_match_index[!is.na(final_match_index)], ]

final_combined <- bind_cols(final_matched_velkka, final_matched_harmonized)

not_in_harm19 <- unmatched_final1[is.na(final_match_index), ]

# Print diagnostics
cat("velkka_list:", nrow(velkka_list), "\n")
cat("list:", nrow(list), "\n")
cat("matched_records:", nrow(matched_records), "\n")
cat("unmatched_velkka:", nrow(unmatched_final1), "\n")
cat("unmatched_julia:", nrow(unmatched_julia), "\n")
cat("not_in_harm19:", nrow(not_in_harm19), "\n")
cat("final_matched_harmonized:", nrow(final_matched_harmonized), "\n")

write.csv(unmatched_julia, "unmatched_julia.csv", row.names = FALSE)

matched_from_processed <- df.processed %>%
  semi_join(unmatched_julia, by = "melinda_id")

# Write the filtered rows to a CSV file
write.csv(matched_from_processed, "julia_not_velkka.csv", row.names = FALSE)


# Extract melinda_ids
velkka_ids <- velkka_list$melinda_id
list_ids <- list$melinda_id
orig_ids <- df.orig$melinda_id

# 1. Common between velkka_list and list
common_ids <- intersect(velkka_ids, list_ids)

# 2. In velkka_list but not in list
only_in_velkka <- setdiff(velkka_ids, list_ids)

# 3. In list but not in velkka_list
only_in_list <- setdiff(list_ids, velkka_ids)

# 4. In velkka_list but not in df.orig
velkka_not_in_orig <- setdiff(velkka_ids, orig_ids)

# Print summary
cat("Common (velkka & list):", length(common_ids), "\n")
cat("Only in velkka_list:", length(only_in_velkka), "\n")
cat("Only in list:", length(only_in_list), "\n")
cat("In velkka_list but not in df.orig:", length(velkka_not_in_orig), "\n")

library(ggplot2)

# Create the dataset
data_detailed <- data.frame(
  Category = rep(c("Matched", "Only in manual", "In data dump", "Not in data dump", "Only in automated"), 2),
  Type = rep(c("Melinda ID", "With metadata"), each = 5),
  Count = c(2493, 295, 119, 176, 2375, 2663, 145, 88, 57, 2375)
)

# Set custom category order
data_detailed$Category <- factor(
  data_detailed$Category,
  levels = c("Matched", "Only in automated", "Only in manual", "In data dump", "Not in data dump")
)

# Set custom black-and-white colors
colors <- c("Melinda ID" = "darkgrey",       # Light grey
            "With metadata" = "lightgrey")    # Black

# Plot
ggplot(data_detailed, aes(x = Category, y = Count, fill = Type)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
  scale_fill_manual(values = colors) +
  geom_text(aes(label = Count), 
            position = position_dodge(width = 0.8), 
            vjust = -0.4, size = 3.5, color = "black") +
  labs(
    title = "",
    x = NULL, y = "Count", fill = "Comparison Type"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 30, hjust = 1),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank()
  )


library(biblioverlap) #loading package

#Input 1: Named list of bibliographic dataframes
sapply(ufrj_bio_0122, class) #ufrj_bio_0122 is an example dataset provided by the package
#> Biochemistry     Genetics Microbiology      Zoology 
#> "data.frame" "data.frame" "data.frame" "data.frame"

#Input 2: Namded list of columns for document matching 
matching_cols <- list(DI = 'DOI',
                      TI = 'Title',
                      PY = 'Publication Year',
                      AU = 'Author/s',
                      SO = 'Source Title')

#Running document-level matching procedure
biblioverlap_results <- biblioverlap(ufrj_bio_0122, matching_fields = matching_cols)
#> Matching by DOI for pair Biochemistry_Genetics
#> Matching by SCORE for pair Biochemistry_Genetics
#> Updating matched documents in db2
#> Matching by DOI for pair Biochemistry_Microbiology
#> Matching by SCORE for pair Biochemistry_Microbiology
#> Updating matched documents in db2
#> Matching by DOI for pair Biochemistry_Zoology
#> Matching by SCORE for pair Biochemistry_Zoology
#> Updating matched documents in db2
#> Matching by DOI for pair Genetics_Microbiology
#> Matching by SCORE for pair Genetics_Microbiology
#> Updating matched documents in db2
#> Matching by DOI for pair Genetics_Zoology
#> Matching by SCORE for pair Genetics_Zoology
#> Updating matched documents in db2
#> Matching by DOI for pair Microbiology_Zoology
#> Matching by SCORE for pair Microbiology_Zoology
#> Updating matched documents in db2

#The results of the matching returns a list containing:
#(i) a copy of the original data + UUID column (db_list)
#(ii) a summary of the matching results (summary)
sapply(biblioverlap_results, class)
#> $db_list
#> [1] "list"
#> 
#> $summary
#> [1] "grouped_df" "tbl_df"     "tbl"        "data.frame"