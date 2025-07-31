#source("008_field.R")

field <- "genre_008"

df.orig$publication_decade <- df_pubtime$publication_decade
# Filter rows where data_element_008 == "Kirjat" and converted_00_33 is NA
df_genre_008 <- df.orig %>% filter(data_element_008 == "Kirjat")

file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_accepted <- paste0(output.folder, field, "_accepted.csv")

# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df_genre_008, file = data.file)
# Generate markdown summary
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE)


# ------------------------------------------------------------

# Generate data summaries for the whole data set

message("Accepted entries in the preprocessed data")
s <- write_xtable(df_genre_008$converted_008_33, file_accepted, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df_genre_008$converted_008_33))

# Original entries that were converted into NA
original.na <- df.orig[match(df_genre_008$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)


# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df_genre_008[df_genre_008$melinda_id %in% melindas_19,]
field <- "genre_008"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Generate markdown summary 
df_19 <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df_19, file = paste0(output.folder, paste0(field, "_19.csv")), quote = FALSE)


# Define output files for the 1807-1917 subset
file_accepted_19  <- paste0(output.folder, field, "_accepted_19.csv")
file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")

# ------------------------------------------------------------

# Generate data summaries for 1809-1917
message("Accepted entries in the preprocessed data for 1809-1917")
s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)

message("Discarded entries for 1809-1917")

# NA values in the final harmonized data
inds <- which(is.na(df_19[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp19 <- write_xtable(original.na, file_discarded_19, count = TRUE)


library(dplyr)
library(ggplot2)
library(scales)

# Filter and categorize
df_selected <- df_genre_008 %>%
  filter(converted_008_33 %in% c(fiction_genres, "Tietokirjallisuus")) %>%
  mutate(
    genre_group = ifelse(converted_008_33 == "Tietokirjallisuus", 
                         "Non-Fiction", 
                         "Fiction")
  )

# Count by decade and genre
genre_by_decade <- df_selected %>%
  count(publication_decade, genre_group) %>%
  filter(!is.na(publication_decade))

genre_by_decade <- genre_by_decade %>%
  filter(publication_decade >= 1500)

# Plot with stacked bars
ggplot(genre_by_decade, aes(x = publication_decade, y = n, fill = genre_group)) +
  geom_col() +  # default is position = "stack"
  scale_y_log10(
    breaks = 10^(0:5),
    labels = label_math(10^.x)
  ) +
  scale_fill_manual(
    values = c("Fiction" = "lightblue", "Non-Fiction" = "#FDBF6F")
  ) +
  scale_x_continuous(
    breaks = seq(1500, max(genre_by_decade$publication_decade, na.rm = TRUE), by = 50)
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom"
  ) +
  guides(fill = guide_legend(title.position = "top", direction = "horizontal")) +
  labs(
    title = "Fiction vs Non-Fiction Publications by Decade",
    x = "",
    y = expression("Number of Publications (log"[10]*")"),
    fill = "Genre Group"
  )
library(dplyr)
library(ggplot2)
library(scales)

# Filter to start from 1500
genre_by_decade <- genre_by_decade %>%
  filter(publication_decade >= 1500)

# Plot
ggplot(genre_by_decade, aes(x = publication_decade, y = n, fill = genre_group)) +
  geom_col(position = "dodge", width = 6) +
  scale_y_log10(
    breaks = 10^(0:5),
    labels = label_math(10^.x)
  ) +
  scale_fill_manual(
    values = c("Fiction" = "purple", "Non-Fiction" = "orange")
  ) +
  scale_x_continuous(
    breaks = seq(1500, max(genre_by_decade$publication_decade, na.rm = TRUE), by = 50)
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom"
  ) +
  guides(fill = guide_legend(title.position = "top", direction = "horizontal")) +
  labs(
    title = "Fiction vs Non-Fiction for Books by Decade",
    x = "",
    y = expression("Number of Publications (log"[10]*")"),
    fill = "Genre Group"
  )
