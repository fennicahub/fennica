df_long <- names_database %>%
  select(-death_700)

df_long <- df_long %>%
  rename(
    name_100 = author_name,
    asteri_100 = asteri_id,
    author_date_100 = date,
    name_700 = author_name_700,
    asteri_700 = asteri_id_700,
    author_date_700 = birth_700
  )

df_long <- df_long %>%
  mutate(
    asteri_100 = gsub(" ", "", asteri_100),
    asteri_700 = gsub(" ", "", asteri_700),
    author_date_100 = gsub(" ", "", author_date_100), 
    author_date_700 = gsub(" ", "", author_date_700), 
    author_date_100 = gsub("~", "", author_date_100),
    author_date_700 = gsub("~", "", author_date_700),
  )




df_long <- df_long %>%
  pivot_longer(
    cols = c(
      name_100,
      asteri_100,
      author_date_100,
      name_700,
      asteri_700,
      author_date_700
    ),
    names_to = c(".value", "author_source"),
    names_pattern = "(name|asteri|author_date)_(100|700)"
  )


df_long <- df_long %>%
  arrange(
    id,
    factor(author_source, levels = c("100", "700"))
  )


df_merged <- df_long %>%
  group_by(id) %>%
  summarise(
    all_names = paste(name, collapse = ";"),
    all_asteri = paste(asteri, collapse = ";"),
    all_dates = paste(author_date, collapse = ";"),
    .groups = "drop"
  )


df_long$asteri <- gsub(" ", "", as.character(df_long$asteri))
df_long$asteri[df_long$asteri %in% c("", "NA")] <- NA

df.kanto$asteri_id <- gsub(" ", "", as.character(df.kanto$asteri_id))
df.kanto$asteri_id[df.kanto$asteri_id %in% c("", "NA")] <- NA

df_long1 <- df_long %>%
  mutate(row_order = row_number())

df_long1 <- df_long1 %>%
  group_by(row_order) %>%
  mutate(author_position = row_number()) %>%
  ungroup()

df_long1 <- df_long1 %>%
  mutate(
    n_authors = if_else(
      is.na(name) | trimws(name) %in% c("", "NA"),
      0L,
      stringr::str_count(name, ";") + 1L
    )
  )
df_long1 <- df_long1 %>%
  mutate(
    n_asteri = if_else(
      is.na(asteri) | trimws(asteri) %in% c("", "NA"),
      0L,
      stringr::str_count(asteri, ";") + 1L
    )
  )

df_long1 <- df_long1 %>%
  mutate(
    n_date = if_else(
      is.na(author_date) | trimws(author_date) %in% c("", "NA"),
      0L,
      stringr::str_count(author_date, ";") + 1L
    )
  )

df_long1 <- df_long1 %>%
  mutate(
    asteri = if_else(
      stringr::str_detect(
        asteri,
        "^NA(;NA)*$"
      ),
      NA_character_,
      asteri
    ),
    author_date = if_else(
      stringr::str_detect(
        author_date,
        "^NA(;NA)*$"
      ),
      NA_character_,
      author_date
    )
  )

df_long1 <- df_long1 %>%
  separate_rows(
    name,
    asteri,
    author_date,
    sep = ";"
  )


df_long1 <- df_long1 %>%
  mutate(
    name = na_if(trimws(name), "NA"),
    asteri = na_if(gsub(" ", "", asteri), "NA"),
    author_date = na_if(gsub(" ", "", author_date), "NA")
  )

df_long1 <- df_long1 %>%
  left_join(
    kantofull,
    by = c("asteri" = "asteri_id")
  )


library(data.table)
library(tibble)

collapse_fast <- function(x, sep) {
  x <- as.character(x)
  x <- unique(x[!is.na(x) & trimws(x) != ""])
  
  if (length(x) == 0) {
    return(NA_character_)
  }
  
  paste(x, collapse = sep)
}

dt_long1 <- as.data.table(df_long1)

kanto_cols <- intersect(
  setdiff(names(kantofull), "asteri_id"),
  names(dt_long1)
)

df_merged1 <- dt_long1[
  ,
  c(
    list(
      all_names  = collapse_fast(name, ";"),
      all_asteri = collapse_fast(asteri, ";"),
      all_dates  = collapse_fast(author_date, ";")
    ),
    setNames(
      lapply(.SD, collapse_fast, sep = "/"),
      kanto_cols
    )
  ),
  by = id,
  .SDcols = kanto_cols
]

df_merged1 <- as_tibble(df_merged1)

write.table(df_merged1, 
            file = paste0(output.folder, "all_author_info.csv"),
            sep = "\t",
            row.names=FALSE, 
            quote = FALSE,
            fileEncoding = "UTF-8")    

message("all_author_info.csv: DONE")


df_name_check <- df_merged1 %>%
  mutate(
    missing_all_names = is.na(all_names),
    
    available_from_prefLabel =
      missing_all_names & !is.na(prefLabel),
    
    available_from_altLabel =
      missing_all_names & is.na(prefLabel) & !is.na(altLabel)
  )


# collapse_values <- function(x, separator = "/") {
#   x <- as.character(x)
#   x <- x[!is.na(x) & trimws(x) != ""]
#   x <- unique(x)
#   
#   if (length(x) == 0) {
#     return(NA_character_)
#   }
#   
#   paste(x, collapse = separator)
# }
# 
# kanto_cols <- setdiff(
#   names(kantofull),
#   "asteri_id"
# )
# 
# kanto_cols <- intersect(
#   kanto_cols,
#   names(df_long1)
# )
# 
# df_merged1 <- df_long1 %>%
#   group_by(id) %>%
#   summarise(
#     all_names = collapse_values(name, ";"),
#     all_asteri = collapse_values(asteri, ";"),
#     all_dates = collapse_values(author_date, ";"),
#     
#     across(
#       all_of(kanto_cols),
#       ~ collapse_values(.x, "/")
#     ),
#     
#     .groups = "drop"
#   )
# 
# 
#  df_name_check <- df_merged1 %>%
#   mutate(
#     missing_all_names = is.na(all_names),
#     
#     available_from_prefLabel =
#       missing_all_names & !is.na(prefLabel),
#     
#     available_from_altLabel =
#       missing_all_names & is.na(prefLabel) & !is.na(altLabel)
#   )


df_name_check %>%
  summarise(
    missing_all_names = sum(missing_all_names),
    
    can_add_from_prefLabel =
      sum(available_from_prefLabel),
    
    can_add_from_altLabel =
      sum(available_from_altLabel),
    
    can_add_total =
      sum(
        missing_all_names &
          (!is.na(prefLabel) | !is.na(altLabel))
      ),
    
    still_missing =
      sum(
        missing_all_names &
          is.na(prefLabel) &
          is.na(altLabel)
      )
  )


df_name_check %>%
  summarise(
    missing_all_names = sum(missing_all_names),
    
    can_add_from_prefLabel =
      sum(available_from_prefLabel),
    
    can_add_from_altLabel =
      sum(available_from_altLabel),
    
    can_add_total =
      sum(
        missing_all_names &
          (!is.na(prefLabel) | !is.na(altLabel))
      ),
    
    still_missing =
      sum(
        missing_all_names &
          is.na(prefLabel) &
          is.na(altLabel)
      )
  )


library(dplyr)
library(tidyr)

# A cell is missing when it contains no usable value
is_missing_value <- function(x) {
  
  if (!is.character(x)) {
    return(is.na(x))
  }
  
  x <- trimws(x)
  
  is.na(x) |
    x == "" |
    grepl(
      "^NA(?:\\s*[;/]\\s*NA)*$",
      x,
      ignore.case = TRUE
    )
}


missing_summary_merged1 <- df_merged1 %>%
  summarise(
    across(
      everything(),
      ~ sum(is_missing_value(.x))
    )
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "field",
    values_to = "n_missing"
  ) %>%
  mutate(
    n_total = nrow(df_merged1),
    n_available = n_total - n_missing,
    percent_missing = round(
      100 * n_missing / n_total,
      2
    ),
    percent_available = round(
      100 * n_available / n_total,
      2
    )
  )
missing_summary_merged1 %>%
  arrange(desc(percent_missing))

library(dplyr)
library(tidyr)
library(stringr)

library(dplyr)
library(tidyr)
library(stringr)

top_5_author_names <- df_merged1 %>%
  select(all_names) %>%
  separate_rows(all_names, sep = ";") %>%
  mutate(all_names = str_squish(all_names)) %>%
  filter(
    !is.na(all_names),
    all_names != "",
    all_names != "NA"
  ) %>%
  count(all_names, name = "n") %>%
  mutate(
    percentage = round(100 * n / sum(n), 2)
  ) %>%
  arrange(desc(n)) %>%
  slice_head(n = 5) %>%
  select(all_names, percentage)

top_5_author_names

length(unique(df_merged1$all_names))
length(unique(df_merged1$all_asteri))
