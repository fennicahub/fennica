
# 2. Read the Excel file into the dataframe
velkka_list <- read_excel("Kirjallisuuden ensipainokset2.xlsx")
velkka_list <- unique(velkka_list)

colnames(velkka_list) <- gsub("^\\s+|\\s+$", "", colnames(velkka_list))  # Remove leading/trailing spaces

velkka_list_orig <- read_excel("Kirjallisuuden ensipainokset2.xlsx")
# 3. Rename columns for consistency
colnames(velkka_list)[colnames(velkka_list) == "MelindaID"] <- "melinda_id"
colnames(velkka_list)[colnames(velkka_list) == "...5"] <- "title_remainder"
colnames(velkka_list)[colnames(velkka_list) == "Title"] <- "title"
colnames(velkka_list)[colnames(velkka_list) == "Publication year"] <- "publication_time"
colnames(velkka_list)[colnames(velkka_list) == "Signum"] <- "signum"


# 4. Function to split titles into 'title' and 'title_remainder' based on ":"
velkka_list$title <- gsub(";", "", velkka_list$title)
velkka_list$title <- gsub("\\s+:", "", velkka_list$title)
velkka_list$title <- gsub('"', '', velkka_list$title)
velkka_list$title <- gsub("'", "", velkka_list$title)
velkka_list$title <- gsub("/", "", velkka_list$title)



# 6. Clean the 'melinda_id' and 'signum' columns to remove unnecessary spaces and characters
velkka_list$melinda_id <- gsub(" ", "", velkka_list$melinda_id)  # Remove spaces
velkka_list$melinda_id <- gsub("FCC", "", velkka_list$melinda_id)  # Remove "FCC"
velkka_list$melinda_id <- as.character(velkka_list$melinda_id)  # Convert to character
# Remove the exact pattern "1972" from velkka_list$signum
velkka_list$signum <- gsub("1972", "", velkka_list$signum)
# Remove extra spaces, semicolons, hyphens, and other unwanted characters from velkka_list$signum
velkka_list$signum <- gsub("[[:space:];-]", "", velkka_list$signum)
# Convert to lowercase to make the matching case-insensitive (optional)
velkka_list$signum <- tolower(velkka_list$signum)
velkka_list$signum <- gsub("\\s+", "", as.character(velkka_list$signum))  # Remove all spaces from 'Signum'


# 7. Polish titles by applying custom function (if applicable)
title_pol <- polish_title(velkka_list$title)
velkka_list$title_harmonized <- title_pol$title_harmonized
velkka_list$author_harmonized <- polish_author(velkka_list$Author)
velkka_list$title_harmonized <- gsub("\\.{2,}", "", velkka_list$title_harmonized)
velkka_list$title_harmonized <- gsub("\\.{1,}", "", velkka_list$title_harmonized)
velkka_list$title_harmonized <- gsub("-","", velkka_list$title_harmonized)
velkka_list$title_harmonized <- gsub("å","a", velkka_list$title_harmonized)
velkka_list$title_harmonized <- gsub("ä","a", velkka_list$title_harmonized)
velkka_list$title_harmonized <- gsub("ö","o", velkka_list$title_harmonized)
velkka_list$title_harmonized <- gsub("Å","A", velkka_list$title_harmonized)
velkka_list$title_harmonized <- gsub("Ä","A", velkka_list$title_harmonized)
velkka_list$title_harmonized <- gsub("Ö","O", velkka_list$title_harmonized)
velkka_list$title_harmonized <- gsub("\\s+", " ", velkka_list$title_harmonized)
velkka_list$title_harmonized <- gsub("=","", velkka_list$title_harmonized)
velkka_list$title_harmonized <- trimws(velkka_list$title_harmonized)
# Filter velkka_list to keep only unique title_harmonized values
# velkka_list <- velkka_list %>%
#   distinct(title_harmonized, .keep_all = TRUE)


###################################################################

# 22. Function to clean titles (remove punctuation and convert to lowercase)
clean_text <- function(text) {
  text <- as.character(text)  # Ensure the input is treated as a character string
  text <- trimws(text)  # Remove leading/trailing spaces
  text <- gsub("\\.{2,}", " ", text)  # Replace sequences of two or more dots with a space
  text <- gsub("[^a-zA-ZäöåÄÖÅ0-9 ]", "", text)  # Remove punctuation but keep words and Finnish characters
  text <- tolower(text)  # Convert to lowercase
  text <- gsub('["]', '', text)  # Remove any double quotes
  text <- gsub('\\s+', ' ', text)# Replace multiple spaces with a single space
  text <- gsub("-","", text)
  return(text)
}


# 1. Clean both title and title_remainder columns in velkka_list and list
list$title <- sapply(list$title, clean_text)
list$title_2 <- sapply(list$title_2, clean_text)
list$title_3 <- sapply(list$title_3, clean_text)
list$title_remainder <- sapply(list$title_3, clean_text)
velkka_list$title_harmonized <- sapply(velkka_list$title_harmonized, clean_text)



df.harmonized19$title_harmonized <- sapply(df.harmonized19$title, clean_text)
df.harmonized19$title_2 <- sapply(df.harmonized19$title_2, clean_text)
df.harmonized19$title_3 <- sapply(df.harmonized19$title_3, clean_text)

# Count unique vs total
cat("Unique melinda_id:", length(unique(velkka_list$melinda_id)), "\n")
cat("Total rows:", nrow(velkka_list), "\n")

# Extract duplicated rows
dupes_melinda <- velkka_list %>%
  group_by(melinda_id) %>%
  filter(n() > 1) %>%
  arrange(melinda_id)

# Number of duplicated melinda_ids
cat("Duplicated melinda_ids:", length(unique(dupes_melinda$melinda_id)), "\n")
print(dupes_melinda)

# Count unique vs total
cat("Unique FikkaID:", length(unique(velkka_list$FikkaID)), "\n")
cat("Total rows:", nrow(velkka_list), "\n")

# Extract duplicated rows
dupes_fikka <- velkka_list %>%
  group_by(FikkaID) %>%
  filter(n() > 1) %>%
  arrange(FikkaID)

# Number of duplicated FikkaIDs
cat("Duplicated FikkaIDs:", length(unique(dupes_fikka$FikkaID)), "\n")
print(dupes_fikka)

