library(dplyr)
library(readr)
library(stringr)
library(finto)
library(arrow)

# priority_fields.R is used to create df.orig 
# Step 1. load author_id from df.orig 
#df.orig can be loaded from source("priority_fields.R")
id <- data.frame(author_id = df.orig$author_id)

# Step 3: Extract 9-digit author ID
fennica_subset <- id %>%
  mutate(author_ID = str_extract(author_id, "\\d{9}"))


# Step 4:Drop NA before calling get_kanto
author_ids_clean <- fennica_subset %>%
  filter(!is.na(author_ID) & author_ID != "") %>%
  distinct(author_ID)

# Step 5:Use get_kanto() on just the IDs
authors_df <- finto::get_kanto(author_ids_clean)
authors_df

# # Step 6: Merge enriched authors_df back to the fennica_subset
authors_df_clean <- authors_df %>%
   distinct(author_ID, .keep_all = TRUE)
# 
# 
# # Final join
merged_data <- dplyr::left_join(fennica_subset, authors_df_clean, by = "author_ID")
# 
# # choose the file type as the following both files formats compress the files as the enriched data is big
arrow::write_parquet(merged_data, "fennica_enriched.parquet", compression = "zstd")






