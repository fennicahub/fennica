henko_names <- read.csv("henko_unique_name_gender.csv")
gender_fi <- read.csv("../extdata/gender_FI.csv")
gender_fi$gender <- tolower(gender_fi$gender)
henko_names$gender <- tolower(henko_names$gender)

# Combine and keep only needed columns
all_gender <- rbind(
  henko_names[, c("name", "gender")],
  gender_fi[, c("name", "gender")]
)

# Remove duplicates, keeping the first occurrence
all_gender <- all_gender %>%
  group_by(name) %>%
  summarise(gender = paste(unique(gender), collapse = ";"), .groups = "drop")
all_gender$name <- gsub(" ", "", all_gender$name)
all_gender <- subset(all_gender, nchar(name) >= 2)

###########################
source("author_name_for_gender.R")
df_all_names <- df.tmp
# Define columns containing first names
first_name_cols <- c("first_name", "first_kanto1", "first_kanto2", "first_acess", "first_700a", "first_var")

# Row-wise merge and clean
df_all_names$first_name_merged <- apply(df_all_names[, first_name_cols], 1, function(row) {
  all_names <- unlist(strsplit(row, ";"))
  all_names <- trimws(tolower(all_names))
  all_names <- all_names[all_names != "" & !is.na(all_names)]
  paste(unique(all_names), collapse = "; ")
})

df_all_names$first_name_merged <- gsub(" ", ";", df_all_names$first_name_merged)
df_all_names$first_name_merged <- gsub(";;", ";", df_all_names$first_name_merged)

########################

# Split all rows into individual names
split_names <- strsplit(df_all_names$first_name_merged, ";")
# Flatten into a single vector
all_names <- unlist(split_names)
# Remove tags quickly
all_names <- stringi::stri_replace_all_regex(all_names, "<[^>]*>", "")
# Then remove any &entity; sequences
all_names <- gsub("&[^;]+;", "", all_names, perl = TRUE)
all_names <- trimws(all_names)
all_names <- gsub("[[:cntrl:]\u200E\uFEFF]", "", all_names)
all_names <- trimws(all_names)


all_names <- gsub("kääntäjä", "", all_names)
all_names <- gsub("yrittäjä", "", all_names)
all_names <- gsub("esittelyt", "", all_names)
all_names <- gsub("kirjailija", "", all_names)
all_names <- gsub("luku", "", all_names) 
all_names <- gsub("noin", "", all_names) 
all_names <- gsub("luvulla", "", all_names)
all_names <- trimws(all_names)

# Remove only the parentheses characters, keep the content
all_names <-gsub("A ", "",all_names)
all_names <-gsub("Â ", "",all_names)
all_names <- gsub("\\(|\\)", "", all_names)
all_names <- gsub("\\[|\\]", "", all_names)
all_names <- gsub(":", "", all_names)
all_names <-gsub('^"|"$', '',all_names)
all_names <-gsub("^'|'$", "",all_names)
all_names <-gsub("^=|=$", "",all_names)
all_names <-gsub("^`|`$", "",all_names)
all_names <-gsub("^*|*$", "",all_names)

all_names <- trimws(all_names)
all_names <-gsub("^”|”$", "",all_names)
all_names <-gsub("//", "",all_names)
all_names <-gsub("¨", "",all_names)
all_names <-gsub(",", "",all_names)
all_names <-gsub("^-|-$", "",all_names)
all_names <- trimws(tolower(all_names))
all_names <- all_names[!grepl("^(?:[A-Z]\\s)+[A-Z]$", all_names, ignore.case = TRUE)]


# View result
unique_names_fennica <- subset(all_names, nchar(all_names) >= 4)
unique_names_fennica <- unique(trimws(unique_names_fennica))
unique_names_fennica

fennica_genders <- data.frame(names = unique_names_fennica)


get_gender_from_names <- function(x, lookup = gender_lookup) {
  if (length(x) == 0 || all(is.na(x))) return(NA_character_)
  x <- tolower(as.character(x))
  m <- match(x, names(lookup))    # first position of each x in lookup names (or NA)
  i <- m[!is.na(m)][1]            # first hit
  if (is.na(i)) NA_character_ else unname(lookup[[i]])
}
# Case-insensitive lookup table
gender_lookup <- setNames(all_gender$gender, tolower(all_gender$name))
# Clean name column (just in case) and look up
name_vec <- tolower(trimws(as.character(fennica_genders$names)))
fennica_genders$gender <- unname(gender_lookup[name_vec])

missing_gen <- fennica_genders[is.na(fennica_genders$gender),]


genderize <- read.csv("genderize.csv")

genderize <- genderize %>% filter(Gender != "unknown")
genderize <- genderize %>% filter(Gender.Probability >= 0.8)
genderize <- genderize %>% rename(gender = Gender, probability = Gender.Probability)

############################
all_gender1 <- rbind(
  henko_names[, c("name", "gender")],
  gender_fi[, c("name", "gender")], 
  genderize[, c("name", "gender")]
)

all_gender1 <- all_gender1 %>%
  group_by(name) %>%
  summarise(gender = paste(unique(gender), collapse = ";"), .groups = "drop")
all_gender1$name <- gsub(" ", "", all_gender1$name)
all_gender1 <- subset(all_gender1, nchar(name) >= 2)

write.csv(
  all_gender1,
  file = "fennica_name_genders.csv",
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
