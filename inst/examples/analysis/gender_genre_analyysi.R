library(dplyr)
library(stringr)

# start clean
lin_df <- df.harmonized
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



# --- 2) filter to langs & years; top-5 publishers
df_test <- lin_df %>%
  filter(language %in% c("Finnish","Swedish", "Russian"),
         publication_year >= 1700, publication_year <= 1950)

# top 10 publishers, excluding NA
top_pubs <- df_test %>%
  filter(!is.na(publisher)) %>%
  count(publisher, sort = TRUE) %>%
  slice_head(n = 30) %>%
  pull(publisher)

# keep only rows with a non-missing publisher in that top list
df_test <- df_test %>%
  filter(!is.na(publisher), publisher %in% top_pubs)

# top 10 publishers, excluding NA
top_places <- df_test %>%
  filter(!is.na(publication_place)) %>%
  count(publication_place, sort = TRUE) %>%
  slice_head(n = 30) %>%
  pull(publication_place)

# keep only rows with a non-missing publisher in that top list
df_test <- df_test %>%
  filter(!is.na(publication_place), publication_place %in% top_places)

# --- 3) construct modeling dataset
df <- df_test %>%
  mutate(
    decade    = factor(publication_decade),
    genre     = factor(genre, levels = c("non-fiction","fiction")),
    gender    = factor(gender),
    publisher = fct_infreq(factor(publisher)) %>% fct_drop(),
    language  = factor(language, levels = c("Finnish","Swedish", "Russian")),
    place = factor(publication_place)
  ) %>%
  tidyr::drop_na(genre, gender, publisher, language, decade, place)

# --- 4) drop unused levels + lump long tails
vars <- c("genre","gender","publisher","language","decade", "place")
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
