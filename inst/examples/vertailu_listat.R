library(tidyverse) 
# Replace NA values with empty strings in specific columns
list <- list %>%
  mutate(
    title_remainder = replace_na(title_remainder, ""),
    title_2 = replace_na(title_2, ""),
    title = replace_na(title, ""),
    title_3 = replace_na(title_3, "")
  )

# Normalize text columns
velkka_list$author_harmonized <- str_to_lower(stri_trans_general(velkka_list$author_harmonized, "Latin-ASCII"))
velkka_list$title_harmonized <- str_to_lower(stri_trans_general(velkka_list$title_harmonized, "Latin-ASCII"))
list$title <- str_to_lower(stri_trans_general(list$title, "Latin-ASCII"))
list$title_2 <- str_to_lower(stri_trans_general(list$title_2, "Latin-ASCII"))
list$title_3 <- str_to_lower(stri_trans_general(list$title_3, "Latin-ASCII"))
list$author_name <- str_to_lower(stri_trans_general(list$author_name, "Latin-ASCII"))
list$title_remainder <- str_to_lower(stri_trans_general(list$title_remainder, "Latin-ASCII"))

# **Match by title_2**
match_index_2 <- match(
  paste(velkka_list$author_harmonized, velkka_list$publication_time, velkka_list$title_harmonized),
  paste(list$author_name, list$publication_year, list$title_2)
)

matched_records_title_2 <- velkka_list[!is.na(match_index_2), ]
matched_records_title_2 <- cbind(matched_records_title_2, list[match_index_2[!is.na(match_index_2)], ])

# Find unmatched records
unmatched_records_title_2 <- velkka_list[is.na(match_index_2), ]

# **Match by title**
match_index_title <- match(
  paste(unmatched_records_title_2$author_harmonized, unmatched_records_title_2$publication_time, unmatched_records_title_2$title_harmonized),
  paste(list$author_name, list$publication_year, list$title)
)

matched_records_title <- unmatched_records_title_2[!is.na(match_index_title), ]
matched_records_title <- cbind(matched_records_title, list[match_index_title[!is.na(match_index_title)], ])

# Find remaining unmatched records
unmatched_records1 <- unmatched_records_title_2[is.na(match_index_title), ]

# title_3 and match
match_index_title_3 <- match(
  paste(unmatched_records1$author_harmonized, unmatched_records1$publication_time, unmatched_records1$title_harmonized),
  paste(list$author_name, list$publication_year, list$title_3)
)

matched_records_title_3 <- unmatched_records1[!is.na(match_index_title_3), ]
matched_records_title_3 <- cbind(matched_records_title_3, list[match_index_title_3[!is.na(match_index_title_3)], ])

# Find final unmatched records
unmatched_final <- unmatched_records1[is.na(match_index_title_3), ]

###Title_remainder search
match_index_title_rem <- match(
  paste(unmatched_final$publication_time, unmatched_final$title_harmonized),
  paste(list$publication_year, list$title_remainder)
)


matched_records_title_rem <- unmatched_final[!is.na(match_index_title_rem), ]
matched_records_title_rem <- cbind(matched_records_title_rem, list[match_index_title_rem[!is.na(match_index_title_rem)], ])


# **Match by year + title**
match_index_year_title <- match(
  paste(unmatched_final$publication_time, unmatched_final$title_harmonized),
  paste(list$publication_year, list$title)
)

matched_year_title <- unmatched_final[!is.na(match_index_year_title), ]
matched_year_title <- cbind(matched_year_title, list[match_index_year_title[!is.na(match_index_year_title)], ])

# **Final matched records**
matched_records <- bind_rows(matched_records_title_2, matched_records_title, matched_records_title_3, matched_year_title,matched_records_title_rem)

# Find remaining unmatched records
unmatched_final1 <- unmatched_final[is.na(match_index_year_title), ]
unmatched_julia <- setdiff(list$melinda_id, matched_records$melinda_id...14)


unmatched_julia <- anti_join(list, matched_records, by = c("melinda_id" = "melinda_id...14"))


nrow(unique(unmatched_julia$melinda_id))

melinda_match <- intersect(unmatched_final1$melinda_id, list$melinda_id)
#ADD THOSE TO MATCHED
#melinda_match add those rows from here that match velkka_list to matched 
matched_records1 <- bind_rows(matched_records, filter(list, melinda_id %in% melinda_match))

#############################################################################################################################

# **Extra Matching: Using df.harmonized19**


df.harmonized19$title <- str_to_lower(stri_trans_general(df.harmonized19$title, "Latin-ASCII"))
df.harmonized19$title_2 <- str_to_lower(stri_trans_general(df.harmonized19$title_2, "Latin-ASCII"))
df.harmonized19$author_name <- str_to_lower(stri_trans_general(df.harmonized19$author_name, "Latin-ASCII"))
df.harmonized19$title_3 <- str_to_lower(stri_trans_general(df.harmonized19$title_3, "Latin-ASCII"))
df.harmonized19$title_3 <- gsub(" na", "",df.harmonized19$title_3)

# Match by title
match_index_year_title <- match(
  paste(unmatched_final1$publication_time, unmatched_final1$title_harmonized),
  paste(df.harmonized19$publication_year, df.harmonized19$title)
)

# Initialize final match index with the first matching condition
final_match_index <- match_index_year_title

# Match by title_2 only if no match was found before
match_index_year_title2 <- match(
  paste(unmatched_final1$publication_time[is.na(final_match_index)], unmatched_final1$title_harmonized[is.na(final_match_index)]),
  paste(df.harmonized19$publication_year, df.harmonized19$title_2)
)

# Update final match index where title_2 found a match
final_match_index[is.na(final_match_index)] <- match_index_year_title2

# Match by title_3 only if no match was found before
match_index_year_title3 <- match(
  paste(unmatched_final1$publication_time[is.na(final_match_index)], unmatched_final1$title_harmonized[is.na(final_match_index)]),
  paste(df.harmonized19$publication_year, df.harmonized19$title_3)
)

# Update final match index where title_3 found a match
final_match_index[is.na(final_match_index)] <- match_index_year_title3

# Extract final matched records
# Final matches in unmatched_final1 (velkka_list)
final_matched_velkka <- unmatched_final1[!is.na(final_match_index), ]

# Final matches in df.harmonized19 based on the same indices
final_matched_harmonized <- df.harmonized19[final_match_index[!is.na(final_match_index)], ]

# Combine both data frames side by side
final_combined <- bind_cols(final_matched_velkka, final_matched_harmonized)

# Check the final combined dataset
head(final_combined)

not_in_harm19 <- unmatched_final1[is.na(final_match_index), ]



#####################


cat("velkka_list:", nrow(velkka_list), "\n")
cat("list:", nrow(list), "\n")
cat("matched_records:", nrow(matched_records), "\n")
cat("unmatched_velkka:", nrow(unmatched_final1), "\n")
cat("unmatched_julia:", nrow(unmatched_julia), "\n")
cat("not_in_harm19:", nrow(not_in_harm19), "\n")
cat("final_matched_harmonized:", nrow(final_matched_harmonized), "\n")
