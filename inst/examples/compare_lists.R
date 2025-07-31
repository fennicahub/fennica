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

# 1. Extract just melinda_id columns (if needed)
melinda_ids_velkka <- velkka_list$melinda_id
melinda_ids_list <- list$melinda_id

# 2. Find matched melinda_ids
matched_ids <- intersect(melinda_ids_velkka, melinda_ids_list) #2493
print(length(unique(matched_ids)))

# 3. Filter actual data rows based on match

# Matched records from velkka_list
matched_records_melinda <- velkka_list %>%
  filter(melinda_id %in% matched_ids) #2498
print(length(unique(matched_records_melinda$melinda_id)))
matched_records_melinda <- list %>% 
  filter(melinda_id %in% matched_ids) #2493
print(length(unique(matched_records_melinda$melinda_id)))

# Unmatched from velkka_list
unmatched_records_melinda_ve <- velkka_list %>%
  filter(!melinda_id %in% matched_ids) #295
print(length(unique(unmatched_records_melinda_ve$melinda_id)))

# Unmatched from list
unmatched_records_melinda_list <- list %>%
  filter(!melinda_id %in% matched_ids) #2375
print(length(unique(unmatched_records_melinda_list$melinda_id)))


# 2. Match by author + year + title_2

# From velkka_list unmatched
unmatched_records_melinda_ve <- unmatched_records_melinda_ve %>%
  filter(!is.na(author_harmonized), 
         !is.na(publication_time), 
         !is.na(title_harmonized)) %>%
  mutate(match_key = paste(author_harmonized, publication_time, title_harmonized, sep = "_"))

# From list
list_1 <- list %>%
  filter(!is.na(author_name), 
         !is.na(publication_year), 
         !is.na(title_2)) %>%
  mutate(match_key = paste(author_name, publication_year, title_2, sep = "_"))

# Vector of keys
keys_ve <- unmatched_records_melinda_ve$match_key
keys_list <- list_1$match_key

# Intersecting keys (matches)
matched_keys <- intersect(keys_ve, keys_list)


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

length(unique(matched_records$melinda_id))
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
  Type = rep(c("Melinda ID", "Melinda ID + metadata"), each = 5),
  Count = c(2493, 295, 119, 176, 2375, 2663, 145, 88, 57, 2375)
)

# Set custom category order
data_detailed$Category <- factor(
  data_detailed$Category,
  levels = c("Matched", "Only in automated", "Only in manual", "In data dump", "Not in data dump")
)

# Set custom black-and-white colors
colors <- c("Melinda ID" = "darkgrey",       # Light grey
            "Melinda ID + metadata" = "darkgrey")    # Black


# Conditional label positioning (inside vs outside the bars)
o <- ggplot(data_detailed, aes(x = Count, y = Category, fill = Type)) +
  geom_col(width = 0.6, color = "black") +
  geom_text(aes(label = Count,
                hjust = ifelse(Count > 500, 1.2, -0.2)),  # Inside for >500, outside for <=500
            size = 3.5, color = "black") +
  scale_fill_manual(values = colors) +
  facet_wrap(~ Type, ncol = 1) +
  scale_x_continuous(
    limits = c(0, max(data_detailed$Count) + 500),  # Set the limits manually, no negative values
    breaks = c(0, 500, 1000, 1500, 2000, 2500)  # Explicit breaks for clarity
  ) +
  theme_minimal(base_size = 13) +
  labs(x = "Count", y = NULL) +
  theme(
    panel.grid.major.y = element_blank(),
    legend.position = "none"
  ) +
  expand_limits(x = max(data_detailed$Count) + 200)

y
o

# library(biblioverlap) #loading package
# 
# #Input 1: Named list of bibliographic dataframes
# sapply(list, velkka_list, class) #ufrj_bio_0122 is an example dataset provided by the package
# #> Biochemistry     Genetics Microbiology      Zoology 
# #> "data.frame" "data.frame" "data.frame" "data.frame"
# 
# #Input 2: Namded list of columns for document matching 
# matching_cols <- list(DI = 'melinda_id',
#                       TI = 'title',
#                       PY = 'publication_year',
#                       AU = 'author_name')
# 
# #Running document-level matching procedure
# biblioverlap_results <- biblioverlap(ufrj_bio_0122, matching_fields = matching_cols)
# #> Matching by DOI for pair Biochemistry_Genetics
# #> Matching by SCORE for pair Biochemistry_Genetics
# #> Updating matched documents in db2
# #> Matching by DOI for pair Biochemistry_Microbiology
# #> Matching by SCORE for pair Biochemistry_Microbiology
# #> Updating matched documents in db2
# #> Matching by DOI for pair Biochemistry_Zoology
# #> Matching by SCORE for pair Biochemistry_Zoology
# #> Updating matched documents in db2
# #> Matching by DOI for pair Genetics_Microbiology
# #> Matching by SCORE for pair Genetics_Microbiology
# #> Updating matched documents in db2
# #> Matching by DOI for pair Genetics_Zoology
# #> Matching by SCORE for pair Genetics_Zoology
# #> Updating matched documents in db2
# #> Matching by DOI for pair Microbiology_Zoology
# #> Matching by SCORE for pair Microbiology_Zoology
# #> Updating matched documents in db2
# 
# #The results of the matching returns a list containing:
# #(i) a copy of the original data + UUID column (db_list)
# #(ii) a summary of the matching results (summary)
# sapply(biblioverlap_results, class)
# #> $db_list
# #> [1] "list"
# #> 
# #> $summary
# #> [1] "grouped_df" "tbl_df"     "tbl"        "data.frame"














empty_signums <- unmatched_julia %>%
  filter(is.na(signum) | signum == "")

cat("Empty signums:", nrow(empty_signums), "\n")

kauno_rows1 <- grepl(
  "suom\\.\\s*kaunokirj\\.\\s*1|suom\\.\\s*kaunokirj\\.\\s*3|suom\\.\\s*kaunokirj\\.\\s*4|k\\.\\s*suom\\.\\s*kaunokirj\\.|k\\.\\s*suom\\.\\s*kaunokirj\\.\\s*1|k\\.\\s*suomal\\.\\s*kaunokirj\\.|k\\.\\s*suom\\.\\s*kaunok\\.|k\\.\\s*ruots\\.\\s*kaunok\\.|k\\.\\s*ruots\\.\\s*kaunokirj\\.|ruots\\.\\s*kaunokirj\\.\\s*1|ruots\\.\\s*kaunokirj\\.\\s*3|ruots\\.\\s*kaunokirj\\.\\s*4",
  unmatched_julia$signum
)

sapply(unmatched_julia[, c("melinda_id", "title", "author_name", "publication_year", "language", "signum")], function(x) sum(is.na(x)))


cat("Signums matching kaunokirj pattern:", sum(kauno_rows1, na.rm = TRUE), "\n")

table(list$genre_008, useNA = "always")
