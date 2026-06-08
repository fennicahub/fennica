library(dplyr)
library(tidyr)
library(stringr)

# ------------------------------------------------------------
# Create author_db from names_database
#
# Purpose:
# - collect all unique authors from MARC 100 and MARC 700
# - keep authors with Asteri IDs and authors without Asteri IDs
# - create a stable internal index for the author database
#
# Starting fields:
# - author_index``
# - asteri_id
# - author_name
# - author_birth
# - author_death
# ------------------------------------------------------------

author_database <- bind_rows(
  names_database %>%
    transmute(
      source = "100",
      asteri_id = str_squish(as.character(asteri_id)),
      author_name = str_squish(as.character(author_name))
    ),
  
  df_700 %>%
    transmute(
      source = "700",
      asteri_id = str_squish(as.character(asteri_id)),
      author_name = str_squish(as.character(author_name))
    )
) %>%
  mutate(
    asteri_id = na_if(asteri_id, ""),
    asteri_id = na_if(asteri_id, "NA"),
    asteri_id = na_if(asteri_id, "NaN"),
    author_name = na_if(author_name, ""),
    author_name = na_if(author_name, "NA"),
    author_name = na_if(author_name, "NaN")
  ) %>%
  filter(!is.na(asteri_id) | !is.na(author_name)) %>%
  mutate(
    author_key = if_else(
      !is.na(asteri_id),
      paste0("id:", asteri_id),
      paste0("name_only:", author_name)
    )
  ) %>%
  group_by(author_key, asteri_id, author_name) %>%
  summarise(
    source = paste(sort(unique(source)), collapse = "; "),
    .groups = "drop"
  ) %>%
  arrange(author_name, asteri_id)

records_100 <- names_database %>%
  transmute(
    id1 = as.character(id1),
    asteri_id = str_squish(as.character(asteri_id)),
    author_name = str_squish(as.character(author_name))
  )

records_700 <- df_700 %>%
  transmute(
    id1 = as.character(field_001),
    asteri_id = str_squish(as.character(asteri_id)),
    author_name = str_squish(as.character(author_name))
  )

record_authors <- bind_rows(records_100, records_700) %>%
  mutate(
    asteri_id = na_if(asteri_id, ""),
    asteri_id = na_if(asteri_id, "NA"),
    asteri_id = na_if(asteri_id, "NaN"),
    author_name = na_if(author_name, ""),
    author_name = na_if(author_name, "NA"),
    author_name = na_if(author_name, "NaN")
  ) %>%
  filter(!is.na(asteri_id) | !is.na(author_name)) %>%
  mutate(
    author_key = if_else(
      !is.na(asteri_id),
      paste0("id:", asteri_id),
      paste0("name_only:", author_name)
    )
  ) %>%
  distinct(id1, author_key)

author_counts <- record_authors %>%
  count(author_key, name = "n_records")

author_database <- author_database %>%
  left_join(author_counts, by = "author_key") %>%
  mutate(
    n_records = replace_na(n_records, 0L)
  )


#polish name
tmp <- polish_author(author_database$author_name)
tmp$first <- gsub("NA", "", tmp$first)
tmp$last <- gsub("NA", "", tmp$last)
author_database$first_fen <- tmp$first
author_database$last_fen <- tmp$last

#source("kanto_harmonized.R") to get refined kanto fields in names_df 
author_database <- author_database %>%
  rename(author_name_fen = author_name)

kanto_harmonized <- kanto_harmonized %>%
  rename(author_name_kan = author_name)

# merge names_df into author_database
author_database <- left_join(
  author_database,
  kanto_harmonized,
  by = "asteri_id"
)

author_database$first <- mapply(
  function(x, y) {
    vals <- c(
      unlist(strsplit(as.character(x), ";", fixed = TRUE)),
      unlist(strsplit(as.character(y), ";", fixed = TRUE))
    )
    
    vals <- trimws(vals)
    vals <- vals[vals != "" & !is.na(vals)]
    vals <- unique(vals)
    
    if (length(vals) == 0) NA_character_
    else paste(vals, collapse = "; ")
  },
  author_database$first,
  author_database$first_fen,
  USE.NAMES = FALSE
)

author_database$last <- mapply(
  function(x, y) {
    vals <- c(
      unlist(strsplit(as.character(x), ";", fixed = TRUE)),
      unlist(strsplit(as.character(y), ";", fixed = TRUE))
    )
    
    vals <- trimws(vals)
    vals <- vals[vals != "" & !is.na(vals)]
    vals <- unique(vals)
    
    if (length(vals) == 0) NA_character_
    else paste(vals, collapse = "; ")
  },
  author_database$last,
  author_database$last_fen,
  USE.NAMES = FALSE
)

author_database$first_fen <- NULL
author_database$last_fen <- NULL
author_database$kanto_all <- NULL

# now assign gender based on first name 
# Only replace gender if it's currently NA
author_database$gender <- assign_gender(as.character(author_database$first))
author_database$gender <- sapply(strsplit(author_database$gender, "\\|"), `[`, 1)
# obvious non-persons -> keep NA
author_database$gender[
  grepl(
    "ab$|oy$|ry$|liitto|kirjat|kääntöpiiri|seura|yhdistys|tuote",
    tolower(author_database$author_name_fen)
  )
] <- NA



#activity years for each author in fennica 
source("publication_time.R")
df_time <- df_pubtime

df_time <- df_pubtime %>%
  rename(id1 = melinda_id) %>%
  distinct(id1, publication_year)

df_time <- df_time %>%
  mutate(id1 = as.character(id1))

record_authors_years <- record_authors %>%
  left_join(
    df_time %>%
      select(id1, publication_year),
    by = "id1"
  ) %>%
  mutate(
    publication_year = suppressWarnings(as.numeric(publication_year)),
    publication_year = ifelse(publication_year < 1200, NA_real_, publication_year)
  )

author_activity <- record_authors_years %>%
  filter(!is.na(publication_year)) %>%
  group_by(author_key) %>%
  summarise(
    first_publication_year = min(publication_year),
    last_publication_year  = max(publication_year),
    activity_span = last_publication_year - first_publication_year + 1,
    .groups = "drop"
  )

author_database <- author_database %>%
  select(-any_of(c(
    "first_publication_year",
    "last_publication_year",
    "activity_span"
  ))) %>%
  left_join(author_activity, by = "author_key")

author_database_na_gender <- author_database_1809_1917 %>%
  filter(is.na(gender))

write.table(
  author_database_na_gender,
  file = "author_database_gender_na.csv",
  quote = FALSE,
  row.names = FALSE,
  col.names = TRUE,
  sep = "\t"
)

###########
idx <- match(author_database$asteri_id,
             df.kanto$asteri_id)

author_database$profession <- df.kanto$profession_metadata_profession_prefLabel_fi[idx]
author_database$title <- df.kanto$title[idx]
author_database$language <- df.kanto$language[idx]
author_database$language <- gsub("http://lexvo.org/id/iso639-3/", "", author_database$language)
author_database$country <- df.kanto$country[idx]
author_database$field_activity <- df.kanto$fieldOfActivityOfPerson[idx]
author_database$place <- df.kanto$placeAssociatedWithPerson[idx]
author_database$related_person <- df.kanto$relatedPerson[idx]
author_database$related_person2 <- df.kanto$relatedPersonOfPerson[idx]

author_database_1809_1917 <- author_database %>%
  filter(
    !is.na(first_publication_year),
    !is.na(last_publication_year),
    last_publication_year >= 1809,
    first_publication_year <= 1917
  )
### for rahti reports ###

write.table(
  author_database,
  file = paste0(output.folder, "author_database.csv"),
  quote = FALSE,
  row.names = FALSE,
  col.names = TRUE,
  sep = "\t"
)

write.table(
  author_database_1809_1917,
  file = paste0(output.folder, "author_database_19.csv"),
  quote = FALSE,
  row.names = FALSE,
  col.names = TRUE,
  sep = "\t"
)

# ## 1. Coverage summary
# 
# summary_table <- tibble(
#   metric = c(
#     "Unique authors",
#     "Authors with Asteri ID",
#     "Authors without Asteri ID",
#     "Authors with birth year",
#     "Authors with death year",
#     "Authors with age",
#     "Authors with gender",
#     "Authors with profession",
#     "Authors with field of activity",
#     "Authors with place",
#     "Authors with language"
#   ),
#   n = c(
#     nrow(author_database),
#     sum(!is.na(author_database$asteri_id)),
#     sum(is.na(author_database$asteri_id)),
#     sum(!is.na(author_database$from)),
#     sum(!is.na(author_database$till)),
#     sum(!is.na(author_database$author_age)),
#     sum(!is.na(author_database$gender)),
#     sum(!is.na(author_database$profession)),
#     sum(!is.na(author_database$field_activity)),
#     sum(!is.na(author_database$place)),
#     sum(!is.na(author_database$language))
#   )
# )
# 
# summary_table
# 
# 
# 
#   
#   ## 2. Top authors by number of records
#   
#   top_authors <- author_database %>%
#   arrange(desc(n_records)) %>%
#   select(author_name, n_records) %>%
#   slice_head(n = 20)
# 
# top_authors
# 
#   
#   ## 3. Authors with and without authority control
#   
# 
# author_database %>%
#   summarise(
#     with_asteri = sum(!is.na(asteri_id)),
#     without_asteri = sum(is.na(asteri_id))
#   )
# 
# 
# #Percentages:
# 
# author_database %>%
#   summarise(
#     pct_with_asteri =
#       round(mean(!is.na(asteri_id))*100,1)
#   )
# 
#   ## 4. Gender distribution
#   
# 
# gender_table <- author_database %>%
#   count(gender, sort = TRUE) %>%
#   mutate(
#     pct = round(100*n/sum(n),1)
#   )
# 
# gender_table
# 
#   
#   ## 5. Age statistics
#   
# 
# author_database %>%
#   summarise(
#     n = sum(!is.na(author_age)),
#     mean = mean(author_age, na.rm=TRUE),
#     median = median(author_age, na.rm=TRUE),
#     min = min(author_age, na.rm=TRUE),
#     max = max(author_age, na.rm=TRUE)
#   )
# 
#   
#   ## 6. Birth year coverage
#   
# 
# author_database %>%
#   mutate(
#     birth_decade = floor(as.numeric(from)/10)*10
#   ) %>%
#   count(birth_decade, sort=TRUE)
# 
#   
#   ## 7. Most common professions
# 
# professions <- author_database %>%
#   separate_rows(profession, sep=",\\s*") %>%
#   filter(!is.na(profession)) %>%
#   count(profession, sort=TRUE)
# 
# head(professions,20)
# 
#   
#   ## 8. Most common fields of activity
# 
# activities <- author_database %>%
#   separate_rows(field_activity, sep=";\\s*") %>%
#   filter(!is.na(field_activity)) %>%
#   count(field_activity, sort=TRUE)
# 
# head(activities,20)
# 
#   
#   ## 9. Languages
# 
# languages <- author_database %>%
#   separate_rows(language, sep=";\\s*") %>%
#   filter(!is.na(language)) %>%
#   count(language, sort=TRUE)
# 
# head(languages,20)
# 
#   
#   ## 10. Countries
#   
# 
# countries <- author_database %>%
#   separate_rows(country, sep=";\\s*") %>%
#   filter(!is.na(country)) %>%
#   count(country, sort=TRUE)
# 
# head(countries,20)
# 
#   
#   ## 11. Places associated with authors
#   
# 
# places <- author_database %>%
#   separate_rows(place, sep=";\\s*") %>%
#   filter(!is.na(place)) %>%
#   count(place, sort=TRUE)
# 
# head(places,20)
# 
#   
#   ## 12. Metadata completeness by authority status
#   
# 
# author_database %>%
#   mutate(
#     authority =
#       ifelse(is.na(asteri_id),
#              "No Asteri",
#              "Asteri")
#   ) %>%
#   group_by(authority) %>%
#   summarise(
#     birth = mean(!is.na(from))*100,
#     age = mean(!is.na(author_age))*100,
#     gender = mean(!is.na(gender))*100,
#     profession = mean(!is.na(profession))*100,
#     language = mean(!is.na(language))*100,
#     activity = mean(!is.na(field_activity))*100
#   )
# 
#   
#   ## 13. Record count distribution
#   
# author_database %>%
#   mutate(
#     records_group = case_when(
#       n_records == 1 ~ "1",
#       n_records <= 5 ~ "2-5",
#       n_records <= 10 ~ "6-10",
#       n_records <= 20 ~ "11-20",
#       TRUE ~ "20+"
#     )
#   ) %>%
#   count(records_group)
# 
# ## 14. Authors with richest metadata
#   
# 
# author_database %>%
#   mutate(
#     metadata_score =
#       rowSums(!is.na(across(
#         c(
#           gender,
#           profession,
#           language,
#           country,
#           field_activity,
#           place,
#           from,
#           till
#         )
#       )))
#   ) %>%
#   arrange(desc(metadata_score))
# 
