#the idea is to create a df with only authors and author info
# dates, names, place of residence, gender
#it might be usefull 
# maybe KK has a ready made list from KANTO
#field 700id is very messy 

# Combine and deduplicate

all_unique_authors <- unique(na.omit(df.orig$author_id))
all_unique_authors <- gsub("https?://isni\\.org/isni/", "(ISNI)",all_unique_authors, ignore.case = TRUE)
all_unique_authors <- gsub("http?://id\\.loc\\.gov/authorities/names/no,", "(LOC.GOV)", all_unique_authors, ignore.case = TRUE)
all_unique_authors <- gsub("HTTPS?://LIBRIS\\.KB\\.SE/", "(LIBRIS)", all_unique_authors, ignore.case = TRUE)
all_unique_authors <- gsub("HTTPS?://ORCID\\.ORG/", "(ORCID)", all_unique_authors, ignore.case = TRUE)

author_by_id <- data.frame(id = all_unique_authors)



# mapping from the simple pair
map_main <- df.orig %>%
  select(id = author_id, author_name) %>%
  filter(!is.na(id), id != "") %>%
  mutate(
    id = str_trim(id),
    author_name = str_trim(author_name)
  ) %>%
  distinct(id, author_name)

# join onto your existing auhtor_by_id
author_by_id <- author_by_id %>%
  left_join(map_main, by = "id")



#########################################
# 2. Split multiple IDs in author_id_700
auhtor_id_700 <- df.orig %>%
  pull(author_id_700) %>%
  str_split("\\|") %>%
  unlist()


#####################################################
#########################################

# Combine and deduplicate
all_unique_authors <- unique(na.omit(asteri_id))
all_unique_authors <- gsub("https?://isni\\.org/isni/", "(ISNI)",all_unique_authors, ignore.case = TRUE)
all_unique_authors <- gsub("http?://id\\.loc\\.gov/authorities/names/no,", "(LOC.GOV)", all_unique_authors, ignore.case = TRUE)
all_unique_authors <- gsub("HTTPS?://LIBRIS\\.KB\\.SE/", "(LIBRIS)", all_unique_authors, ignore.case = TRUE)
all_unique_authors <- gsub("HTTPS?://ORCID\\.ORG/", "(ORCID)", all_unique_authors, ignore.case = TRUE)

author_by_asteri_id <- data.frame(id = all_unique_authors)

# mapping from the simple pair
map_main <- df.orig %>%
  select(id = asteri, author_name_kanto1) %>%
  filter(!is.na(id), id != "") %>%
  mutate(
    id = str_trim(id),
    author_name = str_trim(author_name_kanto1)
  ) %>%
  distinct(id, author_name)

# join onto your existing auhtor_by_id
author_by_asteri_id <- author_by_asteri_id %>%
  left_join(map_main, by = "id")


# 3) Make author_by_asteri have unique id
a3 <- author_by_asteri_id %>%
  group_by(id) %>%
  summarise(
    author_name_3 = paste(sort(unique(author_name)), collapse = "|"),
    .groups = "drop"
  )
# all unique ids from the three sources
all_ids <- sort(unique(c(a1$id, a3$id)))

result <- data.frame(
  id = all_ids,
  author_name_1 = a1$author_name_1[match(all_ids, a1$id)],
  author_name_2 = a3$author_name_3[match(all_ids, a3$id)]
)
 
#handle empty cells
result$author_name_2[result$author_name_2 == ""] <- NA



