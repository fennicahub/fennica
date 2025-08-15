
get_gender_from_names <- function(x, lookup = gender_lookup) {
  if (length(x) == 0 || all(is.na(x))) return(NA_character_)
  x <- tolower(as.character(x))
  m <- match(x, names(lookup))    # first position of each x in lookup names (or NA)
  i <- m[!is.na(m)][1]            # first hit
  if (is.na(i)) NA_character_ else unname(lookup[[i]])
}
# Case-insensitive lookup table
gender_lookup <- setNames(all_gender1$gender, tolower(all_gender1$name))
# Clean name column (just in case) and look up
name_vec <- tolower(trimws(as.character(fennica_genders$names)))

sum(is.na(fennica_genders))
fennica_genders$gender <- unname(gender_lookup[name_vec])
sum(is.na(fennica_genders))

mis_gen <- fennica_genders[is.na(fennica_genders$gender), ]

#############read.csv()#######################################################
# Function to extract gender from first matched sub-name
gender_lookup <- setNames(all_gender1$gender, tolower(all_gender1$name))
get_gender_from_names <- function(name_str) {
  if (is.na(name_str) || name_str == "") return(NA)
  
  # Step 1: split on ';' to separate multiple names
  name_parts <- unlist(strsplit(name_str, ";"))
  name_parts <- trimws(name_parts)
  
  # Step 2: for each name part, split on space to get individual given names
  subnames <- unlist(strsplit(name_parts, " "))
  subnames <- trimws(subnames)
  
  # Step 3: search for first match
  for (n in subnames) {
    if (n %in% names(gender_lookup)) {
      return(gender_lookup[n])
    }
  }
  return(NA)
}
df.harmonized$first_name_merged <- df_all_names$first_name_merged
df <- df.harmonized[df.harmonized$melinda_id %in% melindas_19,]
df$first_name_merged[df$first_name_merged == ""] <- NA

# Only replace gender if it's currently NA
df$gender <- ifelse(
  is.na(df$gender),
  sapply(df$first_name_merged, get_gender_from_names),
  df$gender
)

df$gender <- gsub("mies", "Male", df$gender)
df$gender <- gsub("pappi", "Male", df$gender)
df$gender <- gsub("nainen", "Female", df$gender)

mis_name <- sum(is.na(df$first_name_merged))
mis_gen <- sum(is.na(df$gender))
message("Missing author name: ", sum(is.na(df$first_name_merged)))
message("Missing gender: ", mis_gen - mis_name)


