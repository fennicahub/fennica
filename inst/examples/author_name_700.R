# in terminal nohup Rscript init.R > render.log 2>&1 &


library(devtools)
library(dplyr)
library(tidyr)
library(tm)
library(stringr)
library(knitr)
library(R.utils)
library(ggplot2)
library(Cairo)
library(purrr)
library(stringi)
library(parallel)
library(qdapRegex)
library(readxl)
library(arrow)
library(textutils)
library(data.table)
library(brms)
library(rnaturalearth)

# Install latest version from Github
# install_github("fennicahub/fennica") # or
# devtools::load_all() # if you are working from the clone and modifying it
library(fennica)

# Load misc functions needed for harmonization
source("funcs.R")

# Define create the output folder
output.folder <- "output.tables/"
if (!file.exists(output.folder)) {
  dir.create(output.folder)
}

url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/authors_700_long.csv"


df700 <- read.csv(url,stringsAsFactors = FALSE)


author_700e_unique <- df700$author_700e %>%
  as.character() %>%
  strsplit("\\|") %>%
  unlist(use.names = FALSE) %>%
  trimws() %>%
  gsub("^[\\.\\s]+|[\\.\\s]+$", "", ., perl = TRUE) %>%
  (\(x) x[x != "" & !is.na(x)])() %>%
  unique()


# Make sure df_700 is a normal data frame.
df700 <- as.data.frame(df700)
df700$author_name_700 <- df700$author_700a

roles_keep <- c(
  "kirjoittaja",
  "kirjailija",
  "tekijä",
  "författare",
  "author",
  "runoilija",
  "käsikirjoittaja",
  "sanoittaja",
  "libretisti",
  "alkuperäisteoksen kirjoittaja",
  "alkuteoksen kirjoittaja",
  "alkuperäistarinan kirjoittaja",
  "alkuperäistekstin kirjoittaja"
)

keep <- sapply(strsplit(as.character(df700$author_700e), "\\|"), function(x) {
  if (all(is.na(x)) || all(trimws(x) == "")) return(TRUE)
  
  x <- trimws(x)
  x <- gsub("^[[:punct:] ]+|[[:punct:] ]+$", "", x)
  
  any(tolower(x) %in% roles_keep)
})

df700 <- df700[keep, ]

df700 <- df700 %>%
  distinct()

df700_authors <- df700 %>%
  select(melinda_id, author_700a) %>%
  filter(!is.na(author_700a), author_700a != "") %>%
  distinct() %>%
  group_by(melinda_id) %>%
  summarise(
    author_700a = str_c(sort(unique(author_700a)), collapse = "; "),
    .groups = "drop"
  )

field <- "author_name_700"


df700_long <- df700_authors %>%
  select(melinda_id, author_700a) %>%
  separate_longer_delim(author_700a, delim = ";") %>%
  mutate(
    author_700a = str_trim(author_700a),
    author_700a = na_if(author_700a, "")
  ) %>%
  filter(!is.na(author_700a))


  author <- polish_author(df700_long$author_700a, verbose = TRUE)


  df700_polished <- df700_long %>%
  mutate(
    author_name_700 = author$full_name,
    first_700 = author$first,
    last_700 = author$last
  )


  df700_harm <- df700_polished %>%
    group_by(melinda_id) %>%
    summarise(
      author_orig_700 = str_c(unique(na.omit(author_700a)), collapse = "; "),
      author_name_700 = str_c(unique(na.omit(author_name_700)), collapse = "; "),
      first_700       = str_c(unique(na.omit(first_700)), collapse = "; "),
      last_700        = str_c(unique(na.omit(last_700)), collapse = "; "),
      .groups = "drop"
    )


# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df700_harm, file = data.file)
# Generate markdown summary
df700_harm <- readRDS(data.file)

# Define output files for the whole dataset
file_accepted_700  <- paste0(output.folder, field, "_accepted.csv")
file_discarded_700 <- paste0(output.folder, field, "_discarded.csv")
error_700 <- paste0(output.folder, field, "_error.csv")
# ------------------------------------------------------------

# Generate data summaries for the whole data set

message("Accepted entries in the preprocessed data")
s <- write_xtable(df700_harm$author_name_700, file_accepted_700, count = TRUE)

# message("Discarded entries in the original data")
# 
# inds <- which(is.na(df700_harm[[field]]))
# 
# original.na <- df700[[field]][
#   match(df700_harm$melinda_id[inds], df700$melinda_id)
# ]
# 
# tmp <- write_xtable(original.na, file_discarded, count = TRUE)


# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df700_19 <- df700_harm[df700_harm$melinda_id %in% melindas_19,]
field <- "author_name_700"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df700_19, file = data.file)

# Generate markdown summary 
df700_19 <- readRDS(data.file)


# Define output files for the 1807-1917 subset
file_accepted_700_19  <- paste0(output.folder, field, "_accepted_19.csv")

# ------------------------------------------------------------

# Generate data summaries for 1809-1917
message("Accepted entries in the preprocessed data for 1809-1917")
s <- write_xtable(df700_19[[field]], file_accepted_700_19, count = TRUE)




