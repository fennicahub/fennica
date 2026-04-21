# # Download the csv file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/harmonized_fennica.csv"
# 
# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df  <- read.csv(url, header = TRUE, sep = "\t", quote = "", stringsAsFactors = FALSE, colClasses = col_classes)

df2 <- df

df1 <- df %>% filter(publication_year >= 1809 & publication_year <= 1917)

library(dplyr)
library(forcats)

df1 <- df1 %>%
  mutate(
    gender_primary = fct_na_value_to_level(gender_primary, "Unknown"),
    language = fct_na_value_to_level(language_primary, "Unknown"),
    publication_decade = as.factor(publication_decade),
    publication_year = as.factor(publication_year),
    genre_008 = as.factor(genre_008)
  )

tab_gender <- df1 %>%
  count(gender_primary, genre_008) %>%
  group_by(gender_primary) %>%
  mutate(prop = n / sum(n))

tab_lang <- df1 %>%
  count(language_primary, genre_008) %>%
  group_by(language_primary) %>%
  mutate(prop = n / sum(n))

tab_dec <- df1 %>%
  count(publication_decade, genre_008) %>%
  group_by(publication_decade) %>%
  mutate(prop = n / sum(n))

tab_year <- df1 %>%
  count(publication_year, genre_008) %>%
  group_by(publication_year) %>%
  mutate(prop = n / sum(n))


## Step 2

tab_gender_dec <- df1 %>%
  count(publication_decade, gender_primary, genre_008) %>%
  group_by(publication_decade, gender_primary) %>%
  mutate(prop = n / sum(n))

tab_lang_dec <- df1 %>%
  count(publication_decade, language_primary, genre_008) %>%
  group_by(publication_decade, language_primary) %>%
  mutate(prop = n / sum(n))

tab_gender_lang <- df1 %>%
  count(language_primary, gender_primary, genre_008) %>%
  group_by(language_primary, gender_primary) %>%
  mutate(prop = n / sum(n))

tab_full <- df1 %>%
  count(publication_decade, language_primary, gender_primary, genre_008) %>%
  group_by(publication_decade, language_primary, gender_primary) %>%
  mutate(prop = n / sum(n))

genre_target <- "Romaanit"
overall_gender <- df1 %>%
  mutate(is_target = genre_008 == genre_target) %>%
  group_by(gender_primary) %>%
  summarise(prop = mean(is_target, na.rm = TRUE))

within_dec <- df1 %>%
  mutate(is_target = genre_008 == genre_target) %>%
  group_by(publication_decade, gender_primary) %>%
  summarise(prop = mean(is_target, na.rm = TRUE))

within_lang <- df1 %>%
  mutate(is_target = genre_008 == genre_target) %>%
  group_by(language_primary, gender_primary) %>%
  summarise(prop = mean(is_target, na.rm = TRUE))


library(tidyr)

check_simpson <- within_dec %>%
  pivot_wider(names_from = gender_primary, values_from = prop) %>%
  mutate(direction = sign(female - male))

overall_dir <- overall_gender %>%
  pivot_wider(names_from = gender_primary, values_from = prop) %>%
  mutate(direction = sign(female - male)) %>%
  pull(direction)

check_simpson %>%
  ungroup() %>%
  summarise(prop_opposite = mean(direction != overall_dir, na.rm = TRUE))
