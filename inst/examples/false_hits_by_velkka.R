
# Step 1: Read the file, skipping the first 2 rows
df_v <- read.csv("julia_not_velkka_2.csv", header = FALSE, skip = 3, sep = ";")

# Step 2: Set the first row as column names
colnames(df_v) <- as.character(df_v[1, ])

# Step 3: Remove the first row now that it's used as column names
df_v <- df_v[-1, ]

# Step 4 (optional): Reset row names
rownames(df_v) <- NULL
# Rename selected columns
df_v <- df_v %>%
  rename(
    Listalla = `Listalla K/E`,
    Keltaiset = `Keltaiset K/E`,
    Punaiset = `Punaiset K/E`,
    uusi_ensipainos = `Onko uusi ensipainos? K/E`
  )

num_unique_combinations <- nrow(unique(df_v[, c("Listalla", "Keltaiset", "Punaiset")]))
cat("Number of unique combinations:", num_unique_combinations, "\n")


df_v %>%
  mutate(across(c(Listalla, Keltaiset, Punaiset), ~ {
    cleaned <- str_trim(.)              # Remove leading/trailing whitespace
    cleaned[cleaned == ""] <- NA        # Convert "" to NA
    cleaned
  })) %>%
  mutate(across(everything(), ~ifelse(is.na(.), "missing", as.character(.)))) %>%
  group_by(Listalla, Keltaiset, Punaiset) %>%
  summarise(count = n(), .groups = "drop") %>%
  arrange(desc(count)) %>%
  print()


table(df_v$uusi_ensipainos)


# Clean values and apply the condition
count_missing_uusi_with_K <- df_v %>%
  mutate(
    uusi_ensipainos = str_trim(uusi_ensipainos),
    Punaiset = str_trim(Punaiset)
  ) %>%
  filter(
    uusi_ensipainos == "" | is.na(uusi_ensipainos),
    Punaiset == "K"
  ) %>%
  nrow()

cat("Number of rows with missing 'uusi_ensipainos' and 'K' in 'Punaiset':", count_missing_uusi_with_K, "\n")

# Clean values and apply the condition
count_missing_uusi_with_E <- df_v %>%
  mutate(
    uusi_ensipainos = str_trim(uusi_ensipainos),
    Punaiset = str_trim(Punaiset)
  ) %>%
  filter(
    uusi_ensipainos == "" | is.na(uusi_ensipainos),
    Punaiset == "E"
  ) %>%
  nrow()

cat("Number of rows with missing 'uusi_ensipainos' and 'E' in 'Punaiset':", count_missing_uusi_with_E, "\n")
df_v <- df_v %>%
  mutate(
    uusi_ensipainos = str_trim(uusi_ensipainos),
    Punaiset = str_trim(Punaiset),
    uusi_ensipainos = ifelse(
      (uusi_ensipainos == "" | is.na(uusi_ensipainos)) & Punaiset == "E",
      "E",
      uusi_ensipainos
    )
  )

# Clean whitespace in Punaiset column
df_v <- df_v %>%
  mutate(uusi_ensipainos = str_trim(uusi_ensipainos))

# Total number of rows
total_rows <- nrow(df_v)

# Count values in 'Punaiset'
uusi_ensipainos_counts <- df_v %>%
  mutate(uusi_ensipainos_clean = case_when(
    uusi_ensipainos == "K" ~ "K",
    uusi_ensipainos == "E" ~ "E",
    uusi_ensipainos == "" | is.na(uusi_ensipainos) ~ "empty",
    TRUE ~ "other"
  )) %>%
  count(uusi_ensipainos_clean)

# Print results
cat("Total rows in df_v:", total_rows, "\n")
print(uusi_ensipainos_counts)

