###############################################################
# Count occurrences of these excluded genres
excluded_genres <- unique(final_matched_harmonized$genre_008[!final_matched_harmonized$genre_008 %in% genres_to_keep])

# Find unique languages that are NOT Finnish or Swedish
excluded_languages <- unique(final_matched_harmonized$language[!grepl("Finnish|Swedish", final_matched_harmonized$language, ignore.case = TRUE)])

# Identify rows where `signum` matches Finnish or Swedish fiction classification
kauno_rows <- grepl("Suom\\.kaunokirj\\.1|Suom\\.kaunokirj\\.3|Suom\\.kaunokirj\\.4|Suom\\.kaunokirj\\.5|
Suom\\.kaunokirj\\.6|K\\.Suom\\.kaunokirj\\.|K\\.Suom\\.kaunokirj\\.1|K\\.Suomal\\.kaunokirj\\.|K\\.Suom\\.kaunok\\.|K\\.Ruots\\.kaunok\\.|K\\.Ruots\\.kaunokirj\\.|Ruots\\.kaunokirj\\.1|Ruots\\.kaunokirj\\.3|Ruots\\.kaunokirj\\.4|Ruots\\.kaunokirj\\.5|
Ruots\\.kaunokirj\\.6", final_matched_harmonized$signum)


###########################

# Count rows where genre_008 is in excluded genres
excluded_genre_008_rows <- final_matched_harmonized[final_matched_harmonized$genre_008 %in% excluded_genres, ]
excluded_genre_008_count <- nrow(excluded_genre_008_rows)

# Find rows with excluded languages (not Finnish or Swedish)
excluded_language_rows <- final_matched_harmonized[final_matched_harmonized$language %in% excluded_languages, ]
excluded_language_count <- nrow(excluded_language_rows)

# Count rows where 'udk' contains "(024.7)"
udk_0247_rows <- final_matched_harmonized[grepl("\\(024\\.7\\)", final_matched_harmonized$udk, ignore.case = TRUE), ]
udk_0247_count <- nrow(udk_0247_rows)

# Count rows where 'udk_aux' contains "(024.7)"
udk_aux_0247_rows <- final_matched_harmonized[grepl("\\(024\\.7\\)", final_matched_harmonized$udk_aux, ignore.case = TRUE), ]
udk_aux_0247_count <- nrow(udk_aux_0247_rows)

# Count rows where 'genre_655' contains "lasten", "barn", or "child"
genre_655_lasten_barn_child_rows <- final_matched_harmonized[grepl("lasten|barn|child", final_matched_harmonized$genre_655, ignore.case = TRUE), ]
genre_655_lasten_barn_child_count <- nrow(genre_655_lasten_barn_child_rows)

# Count rows where 'genre_655' contains "lasten", "barn", or "child"
signum_lasten_rows <- final_matched_harmonized[grepl("lasten", final_matched_harmonized$signum, ignore.case = TRUE), ]
signum_lasten_count <- nrow(signum_lasten_rows)

genre_655_kaanno_rows <- final_matched_harmonized[grepl("käännö", final_matched_harmonized$genre_655, ignore.case = TRUE), ]
genre_655_kaanno_count <- nrow(genre_655_kaanno_rows)
# Print the results
cat("Rows with genre_008 in excluded genres:", excluded_genre_008_count, "\n")
cat("Rows with excluded languages (not Finnish or Swedish):", excluded_language_count, "\n")
cat("Rows with '(024.7)' in udk:", udk_0247_count, "\n")
cat("Rows with '(024.7)' in udk_aux:", udk_aux_0247_count, "\n")
cat("Rows with 'lasten', 'barn', or 'child' in genre_655:", genre_655_lasten_barn_child_count, "\n")
cat("Rows with 'lasten' in sugnum :", signum_lasten_count, "\n")
cat("Rows with 'käännö' in 655 :", genre_655_kaanno_count, "\n")

# Create a logical vector for rows that fall into any exclusion criteria
exclude_rows <- final_matched_harmonized$melinda_id[final_matched_harmonized$genre_008 %in% excluded_genres |
                                                      final_matched_harmonized$language %in% excluded_languages |
                                                      grepl("\\(024\\.7\\)", final_matched_harmonized$udk, ignore.case = TRUE) |
                                                      grepl("\\(024\\.7\\)", final_matched_harmonized$udk_aux, ignore.case = TRUE) |
                                                      grepl("lasten|barn|child", final_matched_harmonized$genre_655, ignore.case = TRUE) |
                                                      grepl("lasten", final_matched_harmonized$signum, ignore.case = TRUE) |
                                                      grepl("käännö", final_matched_harmonized$genre_655, ignore.case = TRUE)]

# Get the count of unique `melinda_id` values that fall into exclusions
excluded_melinda_ids <- unique(exclude_rows)
excluded_melinda_count <- length(excluded_melinda_ids)

# Get the count of unique `melinda_id` values that do not fall into exclusions
non_excluded_melinda_ids <- setdiff(unique(final_matched_harmonized$melinda_id), excluded_melinda_ids)
non_excluded_melinda_count <- length(non_excluded_melinda_ids)

# Print the results
cat("Rows with melinda_id that fall into exclusion criteria:", excluded_melinda_count, "\n")
cat("Rows with melinda_id that do not fall into any exclusion criteria:", non_excluded_melinda_count, "\n")




# Create exclusion condition
exclude_condition <- final_matched_harmonized$genre_008 %in% excluded_genres | 
  final_matched_harmonized$language %in% excluded_languages |
  grepl("\\(024\\.7\\)", final_matched_harmonized$udk, ignore.case = TRUE) |
  grepl("\\(024\\.7\\)", final_matched_harmonized$udk_aux, ignore.case = TRUE) |
  grepl("lasten|barn|child", final_matched_harmonized$genre_655, ignore.case = TRUE) |
  grepl("lasten", final_matched_harmonized$signum, ignore.case = TRUE) |
  grepl("käännö", final_matched_harmonized$genre_655, ignore.case = TRUE) |
  kauno_rows  # Explicitly exclude rows where `kauno_rows` condition is met

# Subset rows where exclusion condition is not met (i.e., rows that are not excluded)
subset_non_excluded <- final_matched_harmonized[!exclude_condition, ]
subset_excluded <- final_matched_harmonized[exclude_condition, ]
# Print the number of rows that do not meet any exclusion criteria
cat("Rows that do not fall into any exclusion criteria:", nrow(subset_non_excluded), "\n")

# Optionally, preview the rows that do not fall into any exclusion criteria
head(subset_non_excluded)

# Create a new column for each exclusion criterion
final_matched_harmonized$excluded_genre_008 <- final_matched_harmonized$genre_008 %in% excluded_genres
final_matched_harmonized$excluded_language <- final_matched_harmonized$language %in% excluded_languages
final_matched_harmonized$udk_0247 <- grepl("\\(024\\.7\\)", final_matched_harmonized$udk, ignore.case = TRUE)
final_matched_harmonized$udk_aux_0247 <- grepl("\\(024\\.7\\)", final_matched_harmonized$udk_aux, ignore.case = TRUE)
final_matched_harmonized$genre_655_lasten_barn_child <- grepl("lasten|barn|child", final_matched_harmonized$genre_655, ignore.case = TRUE)
final_matched_harmonized$signum_lasten <- grepl("lasten", final_matched_harmonized$signum, ignore.case = TRUE)
final_matched_harmonized$genre_655_kaanno <- grepl("käännö", final_matched_harmonized$genre_655, ignore.case = TRUE)
final_matched_harmonized$kauno_rows <- kauno_rows

# Create a combined exclusion group
final_matched_harmonized$exclusion_group <- apply(final_matched_harmonized[, c("excluded_genre_008", "excluded_language", "udk_0247", 
                                                                               "udk_aux_0247", "genre_655_lasten_barn_child", 
                                                                               "signum_lasten", "genre_655_kaanno", "kauno_rows")], 
                                                  1, function(x) paste(names(x)[x], collapse = ", "))

# Count the number of rows in each exclusion group
group_counts <- table(final_matched_harmonized$exclusion_group)

# Print the counts of rows by exclusion group
print(group_counts)

# Optionally, you can also view the rows in each group
# For example, to view rows that fall into the 'genre_008' and 'genre_655_lasten_barn_child' group:
subset_group <- final_matched_harmonized[final_matched_harmonized$exclusion_group == "excluded_genre_008, genre_655_lasten_barn_child", ]
head(subset_group)

library(ggplot2)
library(svglite)

# Data
data <- data.frame(
  Category = c("genre_008", "language", "genre_655_translations", 
               "genre_655_child", "UDC_child", 
               "UDC_child, genre_655_child", 
               "UDC_child, callnumber_child"),
  Count = c(30, 1, 13, 1, 16, 3, 5)
)
# Set a cutoff for placing labels inside vs outside
label_cutoff <- 2
p <- ggplot(data, aes(x = reorder(Category, Count), y = Count)) +
  geom_col(width = 0.8, fill = "gray", color = "black") +  # cleaner bars
  geom_text(aes(label = Count,
                vjust = ifelse(Count > label_cutoff, 1.5, -0.5)),  # inside for tall bars
            color = "black", size = 3.5) +
  labs(x = "Category (MARC21 fields)", y = "Count of Excluded Records") +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(size = 10, angle = 30, hjust = 1),
    axis.text.y = element_text(size = 10),
    axis.title = element_text(size = 12, face = "bold"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.margin = margin(10, 10, 10, 10)
  ) +
  scale_y_continuous(
    limits = c(0, max(data$Count) + 5),
    breaks = c(0, 5, 10, 15, 20, 25, 30)
  )


p
ggsave("figure3_vertailu.svg", p, width = 7, height = 4, dpi = 600)
browseURL("figure3_vertailu.svg")


