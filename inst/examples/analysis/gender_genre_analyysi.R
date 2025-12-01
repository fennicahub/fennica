library(dplyr)
library(stringr)

# start clean
lin_df <- df.harmonized19
lin_df <- lin_df[, !duplicated(names(lin_df))]
table(df.harmonized$genre_008)


# collapse to binary: non-fiction vs fiction; unknowns -> NA
lin_df <- lin_df %>%
  mutate(
    genre_label = tolower(str_trim(genre_008)),
    genre = case_when(
      genre_label == "tietokirjallisuus" ~ "non-fiction",
      # --- unknown / uncoded / non-genre categories → NA
      genre_label %in% c(
        "tuntematon", "ei koodattu", "aakkostoa tai kirjaimistoa ei ole",
        "arabialainen", "laajennettu latinalainen", "kalvo",
        "latinalainen", "videotallenne", "dia", "kyrillinen",
        "ei transponointia", "moniviestin", "sana- tai kuvakortti",
        "muu", "peli", "ilmiasun erityispiirteitä ei ole määritelty",
        "taidejäljennös", "soveltumaton", "kuva", "sekalaiset aineistot",
        "kreikkalainen", "kiinalainen", "dioraama", "raina",
        "japanilainen", "korealainen", "mikroskoopin preparaatti",
        "sovitus", "thaimaalainen", "transponointi", NA_character_
      ) ~ NA_character_,
      TRUE ~ "fiction"
    )
  )

# sanity check
table(lin_df$genre, useNA = "ifany")

#GROUP PUBLISHER
# big_pub (> 100)
# medium_pub (99-5)
# small_pub (4 - 1)

# --- 3) construct modeling dataset
df <- lin_df %>%
  mutate(
    decade    = factor(publication_decade),
    genre     = factor(genre),
    gender    = factor(gender),
    language  = factor(language),
  ) %>%
  tidyr::drop_na(genre, gender, language, decade)

# --- 4) drop unused levels + lump long tails
vars <- c("genre","gender","language","decade")
df2 <- df %>%
  mutate(
    across(all_of(vars), ~ droplevels(factor(.x))),
    across(all_of(setdiff(vars, "genre")), ~ {
      k <- 10L
      if (nlevels(.x) > k) fct_lump_n(.x, n = k, other_level = "OTHER") else .x
    })
  )

# --- 5) safe Cramér’s V using df2 (not df!)
safe_cramers_v <- function(x, y) {
  tb <- table(x, y)                 # includes only present levels after droplevels()
  if (sum(tb) == 0 || nrow(tb) < 2 || ncol(tb) < 2) return(NA_real_)
  tryCatch(CramerV(tb, bias.correct = TRUE), error = function(e) NA_real_)
}

cat_vars <- vars
cramers_v_mat <- matrix(NA_real_, length(cat_vars), length(cat_vars),
                        dimnames = list(cat_vars, cat_vars))

for (i in seq_along(cat_vars)) {
  for (j in seq_along(cat_vars)) {
    if (i == j) {
      cramers_v_mat[i, j] <- 1
    } else if (i < j) {
      v <- safe_cramers_v(df2[[cat_vars[i]]], df2[[cat_vars[j]]])
      cramers_v_mat[i, j] <- v
      cramers_v_mat[j, i] <- v
    }
  }
}

cramers_v_mat


cramers_v_long <- as.data.frame(cramers_v_mat) |>
  tibble::rownames_to_column("var1") |>
  pivot_longer(-var1, names_to = "var2", values_to = "V")

ggplot(cramers_v_long, aes(var1, var2, fill = V)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%.2f", V))) +
  scale_fill_gradient(low = "white", high = "blue") +
  coord_equal() +
  labs(title = "Cramér's V between categorical variables", x = NULL, y = NULL) +
  theme_minimal(base_size = 12)


fit <- glm(
  genre ~ gender + publisher + language + decade + place,
  data   = df,
  family = binomial()
)

summary(fit)         # coefficients on log-odds scale
glance(fit)          # model fit stats

coef_tab <- tidy(fit, conf.int = TRUE, conf.level = 0.95, exponentiate = TRUE) %>%
  mutate(across(estimate:conf.high, ~ round(.x, 3)))

coef_tab


############ VISUALS #####################
# gender per decade
# Filter your data to only include those genres
df.processed19$author_name <- NULL
df_selected <- df.processed19 %>%
  filter(
    !is.na(publication_decade),
    !is.na(gender_primary),
    publication_decade >= 1800 & publication_decade <= 1920
  )

# Summarize counts by decade and genre
df_summary <- df_selected %>%
  group_by(publication_decade, gender_primary) %>%
  summarise(n = n(), .groups = "drop")


ggplot(df_summary, aes(x = publication_decade, y = n, fill = gender_primary)) +
  geom_col(position = "stack", width = 8, color = "black") +
  scale_fill_grey(start = 0.1, end = 0.8) +
  labs(x = "Publication Decade", y = "Gender Count", fill = "Gender") +
  coord_flip() +
  theme_minimal()


table_summary <- df_summary %>%
  group_by(publication_decade) %>%
  mutate(
    decade_total = sum(n),
    pct = n / decade_total * 100
  ) %>%
  ungroup() %>%
  arrange(publication_decade, gender_primary)


library(dplyr)

genre_summary <- lin_df %>%
  mutate(
    genre_group = case_when(
      genre %in% c("fiction") ~ "fiction",
      TRUE ~ "non-fiction"
    )
  ) %>%
  group_by(publication_decade, gender, genre_group) %>%
  summarise(n = n(), .groups = "drop")
