# read CSVs
author_name_fennica <- read.csv(
  "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_name_accepted.csv",
  row.names = NULL,
  check.names = TRUE
)

author_name_kanto <- read.csv(
  "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_name_kanto_accepted.csv",
  row.names = NULL,
  check.names = TRUE
)

colnames(author_name_fennica)[colnames(author_name_fennica) == "row.names"] <- "surname"
colnames(author_name_fennica)[colnames(author_name_fennica) == "Name.Count"] <- "first_and_count"

colnames(author_name_kanto)[colnames(author_name_kanto) == "row.names"] <- "surname"
colnames(author_name_kanto)[colnames(author_name_kanto) == "Name.Count"] <- "first_and_count"


clean_names <- function(df) {
  df %>%
    filter(!is.na(first_and_count) & first_and_count != "") %>%
    separate(first_and_count, into = c("first_name", "count"), sep = " (?=\\d+$)", remove = FALSE) %>%
    mutate(
      author_name = paste(surname, first_name),
      count = as.integer(count)
    ) %>%
    select(author_name, count)
}

# Now apply the function
author_name_fennica_clean <- clean_names(author_name_fennica)
author_name_kanto_clean <- clean_names(author_name_kanto)

author_name_combined <- bind_rows(author_name_fennica_clean, author_name_kanto_clean) %>%
  group_by(author_name) %>%
  summarise(count = sum(count, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(count))

# save as csv files
write.csv(author_name_combined, "output.tables/author_name_combined.csv", row.names = FALSE)
