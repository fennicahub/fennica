# sources: genderize.io (https://genderize.io/) and henko dataset (https://www.ldf.fi/dataset/henko)
# see genderize.csv and henko_unique_name_gender.csv which were merged into fennica_name_genders.csv see get_names_for_gender.R
#source("author_name_for_gender.R"): get all names that exist in fennica and create fennica_all_names.csv
field <- "gender"


# Only replace gender if it's currently NA
df.tmp$gender <- assign_gender(as.character(author$first))

gender_fix <- c(
  "000082550" = "female",  # Tekla Renfors
  "000113874" = "male",    # Johan Fredrik Galetski
  "000100931" = "male",    # Ferdinand Augustinus Sainio
  "000113858" = "female",  # Anna Edelheim
  "000117480" = "female",  # Fredrika Runeberg
  "000091150" = "male",    # Georg Fraser
  "000101671" = "male",    # Martti Bergh-Wuori
  "000131538" = "male",    # Kaarle Jaakko Gummerus
  "000096230" = "male",    # Antti Mäkinen
  "000100856" = "male",    # Into Konrad Inha
  "000096233" = "male",    # Volmar Lindman
  "000096461" = "female",  # Anna Lilius
  "000100855" = "male",    # Johan Gustaf Nordlund
  "000091857" = "male",    # Jebets Jesiel Judi Säilä
  "000094323" = "male",    # Arvi Aleksanteri Karisto
  "000091050" = "female",  # Alma Hongell
  "000084618" = "female",  # Alma Suppanen
  "000091184" = "male",    # Axel Alfthan
  "000097594" = "female",  # Aleksandra Gripenberg
  "000077619" = "male",    # Einar Reuter
  "000091987" = "female",  # Edith Theodora Forssman
  "000089826" = "female",  # Lilli Lilius
  "000091891" = "female",  # Nanny Cedercreutz
  "000091259" = "male",    # Nino Runeberg
  "000085988" = "male",    # Antti Mäkinen
  "000091315" = "female",  # Hedvig Gebhard
  "000113243" = "male",    # Karl August Andelin
  "000091262" = "male",    # Hjalmar Neiglick
  "000132972" = "male",    # Hugo Alfred Josef Grönstrand
  "000073637" = "male",    # Otto Arvid Lydecken
  "000091115" = "female",  # Adéle Weman
  "000091619" = "female",  # Aura Jurva
  "000132837" = "male",    # Oiva Johannes Tuulio/Tallgren
  "000091726" = "male",    # Johan Albert Bergman
  "000096569" = "male"     # Mathias Bergman
)

df.tmp$gender <- dplyr::coalesce(
  df.tmp$gender,
  unname(gender_fix[df.tmp$asteri_id])
)

###########

df.tmp$gender <- trimws(df.tmp$gender)
df.tmp$gender <- tolower(df.tmp$gender)
df.tmp$gender <- gsub("fmale", "female", df.tmp$gender)
df.tmp$gender <- gsub("fmale", "female", df.tmp$gender)
df.tmp$gender <- gsub("male ", "male", df.tmp$gender)
df.tmp$gender <- gsub("female ", "female", df.tmp$gender)
df.tmp$gender <- gsub("nainen", "female", df.tmp$gender)
df.tmp$gender <- gsub("mies", "male", df.tmp$gender)

df.tmp$gender_primary <- sapply(strsplit(df.tmp$gender, "\\|"), `[`, 1)

df <- df.tmp

################################################################

# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE, sep = ";", row.names = FALSE)

##################################################################

# Define output files for the whole dataset
file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
#add other fields as well
inds <- which(is.na(df.tmp[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)


# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "gender"

write.table(df_19, file = paste0(output.folder, paste0(field, "_19.csv")), quote = FALSE, sep = ";", row.names = FALSE)

# # Define output files for the 1807-1917 subset
# file_accepted_19  <- paste0(output.folder, field, "_accepted_19.csv")
# file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")

# ------------------------------------------------------------

# # Generate data summaries for 1809-1917
#message("Accepted entries in the preprocessed data for 1809-1917")
#s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)
# 
# message("Discarded entries for 1809-1917")
# 
# # NA values in the final harmonized data
# inds <- which(is.na(df_19[[field]]))
# 
# # Original entries that were converted into NA
# original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]
# 
# # .. ie. those are "discarded" cases; list them in a table
#tmp19 <- write_xtable(original.na, file_discarded_19, count = TRUE)
# 

