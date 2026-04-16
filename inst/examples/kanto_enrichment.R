library(dplyr)
library(readr)
library(stringr)
library(finto)
library(arrow)

# priority_fields.R is used to create df.orig 
# Step 1. load author_id from df.orig 
# # Download the csv file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/priority_fields.csv"
# 
# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df.orig <- read.csv(url, skip = 2, header = TRUE, sep = "\t", colClasses = col_classes)

df.orig <- df.orig %>%
  dplyr::rename(
    melinda_id = 1,            # ("001", "-")
    leader = 2,                # ("leader", "-")
    `008` = 3,                 # ("008", "-")
    author_name = 4,           # ("100", "a")
    author_date = 5,           # ("100", "d")
    author_id = 6,             # ("100", "0")
    # author_110 = 7,          # ("110", "a")
    # author_111 = 8,          # ("111", "a")
    language = 7,            # ("041", "a")
    language_original = 8,   # ("041", "h")
    title_uniform = 9,       # ("240", "a")
    title = 10,               # ("245", "a")
    title_remainder = 11,     # ("245", "b")
    `245n` = 12,              # ("245", "n")
    publication_place = 13,   # ("260", "a")
    publisher = 14,           # ("260", "b")
    physical_dimensions = 15,# ("300", "c")
    physical_extent = 16,     # ("300", "a")
    publication_frequency = 17,# ("310", "a")
    publication_interval = 18,# ("362", "a")
    UDK = 19,                 # ("080", "a")
    UDK_aux = 20,             # ("080", "x")
    genre_655 = 21,           # ("655", "a")
    un650 = 22,
    un500 = 22,
    author_700a = 23,                # ("700", "a")
    author_id_700 = 24,              # ("700", "0")
    unknowm1 = 25, 
    un264 = 26
  )


# Step 3: Extract 9-digit author ID
fennica_subset <- df.orig %>%
  mutate(author_ID = str_extract(author_id, "\\d{9}"))


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





