library(dplyr)
library(readr)
library(stringr)
library(finto)
library(arrow)

# choose the reading of the files  depending on the file type
#If the file is parquet file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/priority_fields.parquet"
df.orig <- read_parquet(url)

# If the file is CSV
# url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/priority_fields.csv"
# df.orig <- read_csv(url)

df.orig <- df.orig %>%
  dplyr::rename(
    melinda_id = 1, leader = 2, `008` = 3,
    author_name = 4, author_date = 5, author_id = 6,
    language = 7, language_original = 8,
    title_uniform = 9, title = 10, title_remainder = 11,
    publication_place = 12, publisher = 13,
    physical_dimensions = 14, physical_extent = 15,
    publication_frequency = 16, publication_interval = 17,
    signum = 18, location_852 = 19,
    UDK = 20, UDK_aux = 21, `245n` = 22,
    genre_655 = 23, `650a` = 24, general_note = 25,
    `700a` = 26, `700_0` = 27, `264a` = 28
  ) %>%
  mutate(
    author_ID = case_when(
      author_id != "" & `264a` != "" ~ paste(author_id, `264a`, sep = " | "),
      author_id != "" ~ author_id,
      `264a` != "" ~ `264a`,
      TRUE ~ ""
    )
  ) %>%
  relocate(author_ID, .after = author_date) %>%
  select(-author_id, -`264a`) %>%
  distinct()

# Step 3: Extract 9-digit author ID
fennica_subset <- df.orig %>%
  mutate(author_ID = str_extract(author_ID, "\\d{9}"))


# Step 4:Drop NA before calling get_kanto
author_ids_clean <- fennica_subset %>%
  filter(!is.na(author_ID) & author_ID != "") %>%
  distinct(author_ID)

#authors_df <- get_kanto(author_ids_clean)

# Step 5:Use get_kanto() on just the IDs
authors_df <- finto::get_kanto(author_ids_clean)

# Step 6: Merge enriched authors_df back to the fennica_subset
authors_df_clean <- authors_df %>%
  distinct(author_ID, .keep_all = TRUE)


# Final join
merged_data <- dplyr::left_join(fennica_subset, authors_df_clean, by = "author_ID")

# choose the file type as the following both files formats compress the files as the enriched data is big
arrow::write_parquet(merged_data, "fennica_enriched.parquet", compression = "zstd")

arrow::write_feather(df, "fennica_kanto_enriched.feather", compression = "zstd")





