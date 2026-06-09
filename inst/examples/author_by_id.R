
authors_100 <- df.orig %>%
  transmute(
    source = "100",
    id = clean_id(asteri_id)
  ) %>%
  filter(!is.na(id), id != "")

authors_700 <- df_700 %>%
  transmute(
    source = "700",
    id = as.character(clean_id(asteri_id))
  ) %>%
  filter(!is.na(id), id != "")

authors_df <- bind_rows(authors_100, authors_700) %>%
  distinct(source, id) %>%
  group_by(id) %>%
  summarise(
    sources = paste(sort(unique(source)), collapse = "; "),
    .groups = "drop"
  ) %>%
  arrange(id)

message("author_by_id: DONE")