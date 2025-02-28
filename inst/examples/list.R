



############################################################################

list <- df.harmonized19 
# Start with filtering for "Language material"
list <- list %>%
  filter(record_type == "Language material")

# Clean up columns
list$signum <- gsub(" ", "", as.character(list$signum)) 
list$udk <- trimws(as.character(list$udk)) 


# Keep only rows where `language` contains "fin" or "swe", or is NA
list <- list[grepl("Finnish|Swedish", list$language) | is.na(list$language), ]


# # Identify rows where `signum` contains Finnish or Swedish fiction classification
# kauno_rows <- grepl("Suom\\.kaunokirj.1|Suom\\.kaunokirj.3|Suom\\.kaunokirj.4|Suom\\.kaunokirj.5|
# Suom\\.kaunokirj.6|K\\.Suom.kaunokirj.|K\\.Suom.kaunokirj.1|K\\.Suomal.kaunokirj.|K\\.Suom.kaunok.|K\\.Ruots.kaunok.|K\\.Ruots.kaunokirj.|Ruots\\.kaunokirj.1|Ruots\\.kaunokirj.3|Ruots\\.kaunokirj.4|Ruots\\.kaunokirj.5|
# Ruots\\.kaunokirj.6", list$signum)

# Define rows based on signum matching "Suom.kaunok" or "Ruots.kaunok" patterns
kauno_rows <- grepl("Suom\\.kaunok\\d*|Ruots\\.kaunok\\d*|Suom\\.kaunokirj\\.(1|3|4|5|6)|Ruots\\.kaunokirj\\.(1|3|4|5|6)|K\\.Suom\\.kaunokirj\\.(1|3|4|5|6)|K\\.Ruots\\.kaunokirj\\.(1|3|4|5|6)", list$signum)

# Identify rows where `udk` matches specific classification codes
udk_rows <- grepl("839\\.79|894\\.541", list$udk_orig)

# Identify rows where `udk` matches the values "Suomenkielinen kirjallisuus" or "Suomenruotsalainen kirjallisuus"
udk_value_rows <- grepl("Suomenkielinen kirjallisuus|Suomenruotsalainen kirjallisuus", list$udk)

# Apply fiction filtering, include rows that match kauno_rows, udk_rows, or the specific udk values
list <- list %>% 
  filter(
    (kauno_rows | udk_rows | udk_value_rows)  # Include if kauno_rows, udk_rows, or udk_value_rows match
  )


list <- list %>%
  filter(
    !grepl("lasten|barn", signum, ignore.case = TRUE) &  # Exclude children's books based on signum
      !grepl("lasten|barn", udk, ignore.case = TRUE) &    # Exclude children's books based on udk
      !grepl("\\(024\\.7\\)", udk, ignore.case = TRUE) &  # Exclude children's books based on udk (024.7)
      !grepl("\\(024\\.7\\)", udk_aux, ignore.case = TRUE) &  # Exclude children's books based on udk_aux (024.7)
      !grepl("käännö", genre_655, ignore.case = TRUE) &  # Exclude translations based on genre_655
      !grepl("lasten|barn|child", genre_655, ignore.case = TRUE) # Exclude children's literature based on genre_655
      )


genres_to_keep <- c("Kaunokirjallisuus", "Draama", "Esseet", "Romaanit", "Huumori, satiiri", 
                    "Novellit, kertomukset", "Runot", "Yhdistelmä", "Tuntematon", "Ei koodattu")

list <- list %>%
  filter(genre_008 %in% genres_to_keep | is.na(genre_008))


list[list == ""] <- NA

# Keep unique titles with the earliest publication_time
list <- list %>%
  group_by(title) %>%
  filter(publication_year == min(publication_year)) %>%
  distinct(title, .keep_all = TRUE) %>%
  arrange(publication_year)

list$signum <- gsub("\\s+", "", list$signum)
list$signum <- gsub("[[:space:]]+", "", list$signum)

# Output the final result
print(list)


