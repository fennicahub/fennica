###########################################################################
#source("harmonized_fennica.R")
df.harmonized <- df.processed

df.harmonized$title_2 <- ifelse(is.na(df.harmonized$title), df.harmonized$title_remainder, 
                                ifelse(is.na(df.harmonized$title_remainder), df.harmonized$title, 
                                       paste(df.harmonized$title, df.harmonized$title_remainder, sep = " ")))

df.harmonized$title_2 <- ifelse(is.na(df.orig$`245n`), df.harmonized$title_2, 
                                paste(df.harmonized$title_2, df.orig$`245n`, sep = " "))
df.harmonized$language_original <- df.orig$language_original


# Clean the corresponding columns in the other dataframe (df.harmonized)
df.harmonized$signum <- gsub("\\s+", "", df.harmonized$signum)  # Remove all spaces
df.harmonized$melinda_id <- as.character(df.harmonized$melinda_id)  # Convert to character
df.harmonized$signum <- gsub("1972", "", df.harmonized$signum)
df.harmonized$signum <- gsub("[[:space:];-]", "",df.harmonized$signum)
df.harmonized$signum <- tolower(df.harmonized$signum)
df.harmonized$signum <- gsub(" ", "", df.harmonized$signum) 
df.harmonized$udk <- trimws(as.character(df.harmonized$udk)) 
df.harmonized$title <- gsub("/", "",df.harmonized$title)
df.harmonized$title <- trimws(as.character(df.harmonized$title))
df.harmonized <- df.harmonized %>%
  mutate(
    title_3 = case_when(
      !is.na(title) & !is.na(title_remainder) ~ str_trim(paste(title, title_remainder)),
      !is.na(title) ~ str_trim(title),
      !is.na(title_remainder) ~ str_trim(title_remainder),
      TRUE ~ NA_character_
    )
  )
df.harmonized$title_3 <- gsub("/", "",df.harmonized$title_3)
df.harmonized$title_3 <- trimws(as.character(df.harmonized$title_3))

df.harmonized19 <- df.harmonized[df.harmonized$melinda_id %in% melindas_19,]

df.harmonized <- unique(df.harmonized)
# Store the data
data.file <- paste0(field, ".Rds")
saveRDS(df.harmonized, file = data.file)
#Load the RDS file
df.harmonized <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.csv(df.harmonized,
           file = "for_automated_subset_selection.csv",
           row.names=FALSE,
           quote = FALSE,
       fileEncoding = "UTF-8")
##########################
#Apply criteria 
#1. 1809-1917
list <- df.harmonized %>% filter(publication_year >= 1809 & publication_year <= 1917)
#2. Books
# Start with filtering for "Language material"
list <- list %>%
  filter(record_type == "Language material")

list <- list %>%
  filter(biblio_level == "Monograph/Item")

#3. Finnish/Swedish
# Keep only rows where `language` contains "fin" or "swe", or is NA
list <- list[grepl("Finnish|Swedish", list$language) | is.na(list$language), ]

list <- list %>%
  filter(language_original == "")

#4. Genre

# Convert the signum column to lowercase for case-insensitive matching
kauno_rows <- grepl(
  "suom\\.\\s*kaunokirj\\.\\s*1|suom\\.\\s*kaunokirj\\.\\s*3|suom\\.\\s*kaunokirj\\.\\s*4|k\\.\\s*suom\\.\\s*kaunokirj\\.|k\\.\\s*suom\\.\\s*kaunokirj\\.\\s*1|k\\.\\s*suomal\\.\\s*kaunokirj\\.|\
k\\.\\s*suom\\.\\s*kaunok\\.|k\\.\\s*ruots\\.\\s*kaunok\\.|k\\.\\s*ruots\\.\\s*kaunokirj\\.|ruots\\.\\s*kaunokirj\\.\\s*1|\
ruots\\.\\s*kaunokirj\\.\\s*3|ruots\\.\\s*kaunokirj\\.\\s*4",
  tolower(list$signum)
)
# 
 # list <- list %>%
 #     filter(kauno_rows)

# Identify rows where `udk` matches specific classification codes
udk_rows <- grepl("839\\.79|894\\.541", list$udk_orig)

# Identify rows where `udk` matches the values "Suomenkielinen kirjallisuus" or "Suomenruotsalainen kirjallisuus"
udk_value_rows <- grepl("Suomenkielinen kirjallisuus|Suomenruotsalainen kirjallisuus", list$udk)

# Apply fiction filtering, include rows that match kauno_rows, udk_rows, or the specific udk values
list <- list %>% 
  filter(
    (kauno_rows | udk_rows | udk_value_rows)  # Include kauno_rows, udk_rows, or udk_value_rows match
  )

genres_to_keep <- c("Kaunokirjallisuus", "Draama", "Esseet", "Romaanit", "Huumori, satiiri", 
                    "Novellit, kertomukset", "Runot", "Yhdistelmä", "Tuntematon", "Ei koodattu")

list <- list %>%
  filter(genre_008 %in% genres_to_keep | is.na(genre_008))

#5. Exclude children's literature and translations

list <- list %>%
  filter(
    !grepl("lasten|barn", signum, ignore.case = TRUE) &  
      !grepl("lasten|barn", udk, ignore.case = TRUE) &    
      !grepl("\\(024\\.7\\)", udk, ignore.case = TRUE) &  
      !grepl("\\(024\\.7\\)", udk_aux, ignore.case = TRUE) &  
      (!grepl("käännö", genre_655, ignore.case = TRUE) | is.na(genre_655)) &  # Keep NA values
      (!grepl("lasten|barn|child", genre_655, ignore.case = TRUE) | is.na(genre_655)) # Keep NA values
  )


list[list == ""] <- NA


# 6. Keep unique titles with the earliest publication_time


list <- list %>%
  group_by(title, author_name) %>%
  filter(publication_year == min(publication_year)) %>%
  distinct(title, author_name, .keep_all = TRUE) %>%
  arrange(publication_year)

# Count how many signums are empty
empty_signums <- is.na(list$signum) | list$signum == ""

# Count how many signums are empty
empty_count <- sum(empty_signums)

# Output the counts
empty_count

kauno_rows1 <- grepl(
  "suom\\.\\s*kaunokirj\\.\\s*1|suom\\.\\s*kaunokirj\\.\\s*3|suom\\.\\s*kaunokirj\\.\\s*4|k\\.\\s*suom\\.\\s*kaunokirj\\.|k\\.\\s*suom\\.\\s*kaunokirj\\.\\s*1|k\\.\\s*suomal\\.\\s*kaunokirj\\.|\
k\\.\\s*suom\\.\\s*kaunok\\.|k\\.\\s*ruots\\.\\s*kaunok\\.|k\\.\\s*ruots\\.\\s*kaunokirj\\.|ruots\\.\\s*kaunokirj\\.\\s*1|\
ruots\\.\\s*kaunokirj\\.\\s*3|ruots\\.\\s*kaunokirj\\.\\s*4",
  list$signum)

num_non_matching_kauno_rows <- sum(!kauno_rows1)



##################################################################################################

library(ggplot2)

# Create the data frame with ordered factors
data <- data.frame(
  Category = factor(c("Primary", "Primary", "Exclusion", "Exclusion", "Enrichment", "Enrichment"),
                    levels = c("Primary", "Exclusion", "Enrichment")),
  ListType = factor(c("Manual", "Automated", "Manual", "Automated", "Manual", "Automated"), 
                    levels = c("Manual", "Automated")),
  Count = c(9211, 5278, 4468, 3652, 2788, 4868)
)

# Create the horizontal grouped bar chart
pl <- ggplot(data, aes(x = Category, y = Count, fill = ListType)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.6), color = "black", width = 0.5) +
  geom_text(aes(label = Count), 
            position = position_dodge(width = 0.6), 
            hjust = 1.1, 
            size = 5.5) +
  scale_fill_manual(values = c("darkgray", "lightgray"), name = "") +
  labs(title = "",
       x = "Type of Criteria",
       y = "Number of Entries") +
  coord_flip() +  # Flips to horizontal bars
  theme_minimal(base_size = 15) +
  theme(legend.position = "right",
        axis.text = element_text(size = 14),
        axis.title = element_text(size = 16)) +
  expand_limits(y = max(data$Count) * 1.1)  # Room for text outside bars

pl

write.csv(list,
          file = "automated_first_edition_gender.csv",
          row.names=FALSE,
          quote = FALSE,
          fileEncoding = "UTF-8")

tbl <- table(list$gender, useNA = "ifany")

# Add total
tbl_with_total <- addmargins(tbl)

tbl_with_total

