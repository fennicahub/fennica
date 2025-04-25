# Step 1: Read CSVs
author_date_fennica <- read.csv(
  "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_date_accepted.csv",
  row.names = NULL,
  check.names = TRUE
)

author_date_kanto <- read.csv(
  "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/birthDate_deathDate_kanto_accepted.csv",
  row.names = NULL,
  check.names = TRUE
)

# Step 2: Rename columns
colnames(author_date_fennica)[1] <- "name_count"
colnames(author_date_kanto)[1] <- "term_count_freq"

# Step 3: Clean Fennica — extract fields but keep all rows
author_date_fennica_clean <- author_date_fennica %>%
  mutate(
    birth_death = str_extract(name_count, "\\d{4}[-–]\\d{4}"),
    doc_count = str_extract(name_count, "\\d+$"),
    birth_year = as.integer(str_extract(birth_death, "^\\d{4}")),
    death_year = as.integer(str_extract(birth_death, "\\d{4}$")),
    freq = NA,
    source = "Fennica"
  )

# Step 4: Clean Kanto — split 3-part string and extract years
author_date_kanto_clean <- author_date_kanto %>%
  separate(term_count_freq, into = c("birth_death", "doc_count", "freq"), sep = "\t", fill = "right", extra = "merge") %>%
  mutate(
    birth_year = as.integer(str_extract(birth_death, "^\\d{4}")),
    death_year = as.integer(str_extract(birth_death, "\\d{4}$")),
    source = "Kanto"
  )

# Step 5: Combine both datasets
author_date_combined <- bind_rows(author_date_fennica_clean, author_date_kanto_clean)

# Step 6: Harmonize `birth_death` and drop `name_count`
author_date_combined <- author_date_combined %>%
  mutate(
    birth_death = ifelse(is.na(birth_death), name_count, birth_death)
  ) %>%
  select(-name_count)

# Step 7: Save or inspect
write.csv(author_date_combined, "output.tables/author_date_combined.csv", row.names = FALSE)

# Filter to subset of interest
df_combined <- author_name_combined[author_name_combined$melinda_id %in% melindas_id, ]

# Set field name
field <- "author_name"

# Save as .Rds with the field name
data.file <- paste0(field, ".Rds")
saveRDS(df_combined, file = data.file)


