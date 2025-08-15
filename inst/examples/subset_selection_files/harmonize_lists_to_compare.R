###########################################################################
# # Download the csv file

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/harmonized_fennica_subsets.csv"

df <- read_delim(url, delim = "\t", quote = "", show_col_types = FALSE)

df$title_2 <- ifelse(is.na(df$title), df$title_remainder, 
                                ifelse(is.na(df$title_remainder), df$title, 
                                       paste(df$title, df$title_remainder, sep = " ")))

df$title_2 <- ifelse(is.na(df.orig$`245n`), df$title_2, 
                                paste(df$title_2, df.orig$`245n`, sep = " "))
df$language_original <- df.orig$language_original


# Clean the corresponding columns in the other dataframe (df)
df$signum <- gsub("\\s+", "", df$signum)  # Remove all spaces
df$melinda_id <- as.character(df$melinda_id)  # Convert to character
df$signum <- gsub("1972", "", df$signum)
df$signum <- gsub("[[:space:];-]", "",df$signum)
df$signum <- tolower(df$signum)
df$signum <- gsub(" ", "", df$signum) 
df$udk <- trimws(as.character(df$udk)) 
df$title_2 <- gsub("/", "",df$title_2)
df$title_2 <- trimws(as.character(df$title_2))
df <- df %>%
  mutate(
    title_3 = case_when(
      !is.na(title) & !is.na(title_remainder) ~ str_trim(paste(title, title_remainder)),
      !is.na(title) ~ str_trim(title),
      !is.na(title_remainder) ~ str_trim(title_remainder),
      TRUE ~ NA_character_
    )
  )
df$title_3 <- gsub("/", "",df$title_3)
df$title_3 <- trimws(as.character(df$title_3))

# Clean column names by removing leading/trailing whitespaces
colnames(df) <- trimws(colnames(df))

df <- df %>%
  mutate(
    title_remainder = replace_na(title_remainder, ""),
    title_2 = replace_na(title_2, ""),
    title = replace_na(title, ""),
    title_3 = replace_na(title_3, "")
  )


################################################################################
# 2. Read the Excel file into the dataframe

library(readxl)

# URL of the Excel file
url2 <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/manual_list_orig.xlsx"

# Temporary file to download to
temp_file <- tempfile(fileext = ".xlsx")

# Download the file
download.file(url2, destfile = temp_file, mode = "wb")

# Read it using read_excel
colnames_preview <- names(read_excel(temp_file, n_max = 0))
# Create col_types: text for all, numeric for "publication_time"
col_types_vec <- ifelse(colnames_preview == "publication_year", "numeric", "text")
manual_list <- read_excel(temp_file, col_types = col_types_vec)

colnames(manual_list) <- gsub("^\\s+|\\s+$", "", colnames(manual_list))  # Remove leading/trailing spaces


# 4. Function to split titles into 'title' and 'title_remainder' based on ":"
manual_list$title <- gsub(";", "", manual_list$title)
manual_list$title <- gsub("\\s+:", "", manual_list$title)
manual_list$title <- gsub('"', '', manual_list$title)
manual_list$title <- gsub("'", "", manual_list$title)
manual_list$title <- gsub("/", "", manual_list$title)



# 6. Clean the 'melinda_id' and 'signum' columns to remove unnecessary spaces and characters
manual_list$melinda_id <- gsub(" ", "", manual_list$melinda_id)  # Remove spaces
manual_list$melinda_id <- gsub("FCC", "", manual_list$melinda_id)  # Remove "FCC"
manual_list$melinda_id <- as.character(manual_list$melinda_id)  # Convert to character
# Remove the exact pattern "1972" from manual_list$signum
manual_list$signum <- gsub("1972", "", manual_list$signum)
# Remove extra spaces, semicolons, hyphens, and other unwanted characters from manual_list$signum
manual_list$signum <- gsub("[[:space:];-]", "", manual_list$signum)
# Convert to lowercase to make the matching case-insensitive (optional)
manual_list$signum <- tolower(manual_list$signum)
manual_list$signum <- gsub("\\s+", "", as.character(manual_list$signum))  # Remove all spaces from 'Signum'


# 7. Polish titles by applying custom function (if applicable)
title_pol <- polish_title(manual_list$title)
manual_list$title_harmonized <- title_pol$title_harmonized
manual_list$author_harmonized <- polish_author(manual_list$author)
manual_list$title_harmonized <- gsub("\\.{2,}", "", manual_list$title_harmonized)
manual_list$title_harmonized <- gsub("\\.{1,}", "", manual_list$title_harmonized)
manual_list$title_harmonized <- gsub("-","", manual_list$title_harmonized)
manual_list$title_harmonized <- gsub("å","a", manual_list$title_harmonized)
manual_list$title_harmonized <- gsub("ä","a", manual_list$title_harmonized)
manual_list$title_harmonized <- gsub("ö","o", manual_list$title_harmonized)
manual_list$title_harmonized <- gsub("Å","A", manual_list$title_harmonized)
manual_list$title_harmonized <- gsub("Ä","A", manual_list$title_harmonized)
manual_list$title_harmonized <- gsub("Ö","O", manual_list$title_harmonized)
manual_list$title_harmonized <- gsub("\\s+", " ", manual_list$title_harmonized)
manual_list$title_harmonized <- gsub("=","", manual_list$title_harmonized)
manual_list$title_harmonized <- trimws(manual_list$title_harmonized)
# Filter manual_list to keep only unique title_harmonized values
manual_list <- manual_list %>%
  distinct(melinda_id, .keep_all = TRUE)

# --- Utility Functions ---

clean_text <- function(text) {
  text <- as.character(text)
  text <- trimws(text)
  text <- gsub("\\.{2,}", " ", text)
  text <- gsub("[^a-zA-ZäöåÄÖÅ0-9 ]", "", text)
  text <- tolower(text)
  text <- gsub('["]', '', text)
  text <- gsub("\\s+", " ", text)
  text <- gsub("-", "", text)
  return(text)
}


# 1. Clean both title and title_remainder columns in manual_list and list
df$title <- sapply(df$title, clean_text)
df$title_2 <- sapply(df$title_2, clean_text)
df$title_3 <- sapply(df$title_3, clean_text)
df$title_remainder <- sapply(df$title_3, clean_text)
manual_list$title_harmonized <- sapply(manual_list$title_harmonized, clean_text)

# Normalize text columns
normalize_text <- function(x) str_to_lower(stri_trans_general(x, "Latin-ASCII"))

manual_list <- manual_list %>%
  mutate(
    author_harmonized = normalize_text(author_harmonized),
    title_harmonized = normalize_text(title_harmonized)
  )

df <- df %>%
  mutate(
    title = normalize_text(title),
    title_2 = normalize_text(title_2),
    title_3 = normalize_text(title_3),
    author_name = normalize_text(author_name),
    title_remainder = normalize_text(title_remainder)
  )

