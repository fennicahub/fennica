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


################################
library(dplyr)
library(tidyr)
library(forcats)
library(ggplot2)
library(readr)
library(broom)

# ------------------------------------------------------------
# 1. Read data
# ------------------------------------------------------------

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/harmonized_fennica.csv"

column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))

col_classes <- c("character", rep(NA, column_count - 1))

df <- read.csv(
  url,
  header = TRUE,
  sep = "\t",
  quote = "",
  stringsAsFactors = FALSE,
  colClasses = col_classes
)

# ------------------------------------------------------------
# 2. Prepare 1809-1917 data
# ------------------------------------------------------------

df1 <- df %>%
  mutate(
    publication_year = suppressWarnings(as.numeric(publication_year)),
    publication_decade = suppressWarnings(as.numeric(publication_decade))
  ) %>%
  filter(
    publication_year >= 1809,
    publication_year <= 1917
  ) %>%
  mutate(
    gender_primary = as.character(gender_primary),
    language_primary = as.character(language_primary),
    genre_008 = as.character(genre_008)
  )

# For Simpson analysis: remove missing/unknown gender and missing genre
df_simpson <- df1 %>%
  filter(
    gender_primary %in% c("female", "male"),
    !is.na(genre_008),
    !is.na(publication_decade)
  )

# ------------------------------------------------------------
# 3. Choose target genre
# ------------------------------------------------------------

genre_target <- "Romaanit"

df_simpson <- df_simpson %>%
  mutate(
    is_target = genre_008 == genre_target,
    gender_primary = factor(gender_primary, levels = c("male", "female")),
    publication_decade = factor(publication_decade),
    language_primary = fct_na_value_to_level(
      factor(language_primary),
      "Unknown"
    )
  )

# ------------------------------------------------------------
# 4. Overall gender difference
# ------------------------------------------------------------

overall_gender <- df_simpson %>%
  group_by(gender_primary) %>%
  summarise(
    n = n(),
    prop = mean(is_target),
    .groups = "drop"
  )

overall_diff <- overall_gender %>%
  select(gender_primary, prop) %>%
  pivot_wider(
    names_from = gender_primary,
    values_from = prop
  ) %>%
  mutate(diff_female_minus_male = female - male)

overall_diff
#Within-decade Simpson check
within_dec <- df_simpson %>%
  group_by(publication_decade, gender_primary) %>%
  summarise(
    n = n(),
    prop = mean(is_target),
    .groups = "drop"
  )

within_dec_diff <- within_dec %>%
  select(publication_decade, gender_primary, prop, n) %>%
  pivot_wider(
    names_from = gender_primary,
    values_from = c(prop, n)
  ) %>%
  mutate(
    diff_female_minus_male = prop_female - prop_male,
    overall_diff = overall_diff$diff_female_minus_male,
    opposite_direction = sign(diff_female_minus_male) != sign(overall_diff),
    small_group = n_female < 10 | n_male < 10
  )

within_dec_diff
#Summary table
simpson_summary_decade <- within_dec_diff %>%
  summarise(
    genre = genre_target,
    overall_diff = first(overall_diff),
    n_decades = n(),
    n_opposite = sum(opposite_direction, na.rm = TRUE),
    prop_opposite = mean(opposite_direction, na.rm = TRUE),
    mean_within_decade_diff = mean(diff_female_minus_male, na.rm = TRUE)
  )

simpson_summary_decade
#Plot 1: overall difference vs within-decade differences
ggplot(
  within_dec_diff,
  aes(
    x = publication_decade,
    y = diff_female_minus_male,
    group = 1
  )
) +
  geom_hline(yintercept = 0, linetype = 2) +
  geom_hline(
    yintercept = overall_diff$diff_female_minus_male,
    linetype = 1
  ) +
  geom_line() +
  geom_point(aes(shape = small_group), size = 2.5) +
  labs(
    title = paste("Possible Simpson effect for", genre_target),
    subtitle = "Points show within-decade female minus male difference; horizontal line shows overall difference",
    x = "Publication decade",
    y = "Female - male probability",
    shape = "Small group size"
  ) +
  theme_bw()
#Plot 2: proportions by gender and decade
ggplot(
  within_dec,
  aes(
    x = publication_decade,
    y = prop,
    group = gender_primary,
    linetype = gender_primary
  )
) +
  geom_line() +
  geom_point() +
  labs(
    title = paste("Share of", genre_target, "by gender and decade"),
    x = "Publication decade",
    y = paste("Probability of", genre_target),
    linetype = "Gender"
  ) +
  theme_bw()
#Plot 3: composition plot

#This helps explain why Simpson’s paradox may happen.

gender_decade_composition <- df_simpson %>%
  count(publication_decade, gender_primary) %>%
  group_by(publication_decade) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()

ggplot(
  gender_decade_composition,
  aes(
    x = publication_decade,
    y = prop,
    fill = gender_primary
  )
) +
  geom_col(position = "fill") +
  labs(
    title = "Gender composition by decade",
    x = "Publication decade",
    y = "Share of records",
    fill = "Gender"
  ) +
  theme_bw()

#Model-based check
model_unadjusted <- glm(
  is_target ~ gender_primary,
  data = df_simpson,
  family = binomial
)

model_decade <- glm(
  is_target ~ gender_primary + publication_decade,
  data = df_simpson,
  family = binomial
)

model_decade_language <- glm(
  is_target ~ gender_primary + publication_decade + language_primary,
  data = df_simpson,
  family = binomial
)

model_results <- bind_rows(
  tidy(model_unadjusted, exponentiate = TRUE, conf.int = TRUE) %>%
    mutate(model = "Unadjusted"),
  tidy(model_decade, exponentiate = TRUE, conf.int = TRUE) %>%
    mutate(model = "Adjusted for decade"),
  tidy(model_decade_language, exponentiate = TRUE, conf.int = TRUE) %>%
    mutate(model = "Adjusted for decade + language")
) %>%
  filter(term == "gender_primaryfemale") %>%
  select(model, term, estimate, conf.low, conf.high, p.value)

model_results

decade_novels <- df_simpson %>%
  group_by(publication_decade) %>%
  summarise(
    novel_share = mean(is_target)
  )

ggplot(decade_novels,
       aes(publication_decade,
           novel_share,
           group = 1)) +
  geom_line() +
  geom_point() +
  theme_bw() +
  labs(
    x = "Decade",
    y = "Share of novels"
  )
