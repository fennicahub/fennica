field <- "publication_place"
field_2 <- "melinda_id"

#enrich 260a with 264a 
df.orig_p <- df.orig %>%
  mutate(publication_place = ifelse(
    (is.na(publication_place) | publication_place == "") & 
      !(is.na(df.orig$publication_place_264) | df.orig$publication_place_264 == ""),
    df.orig$publication_place_264,
    publication_place
  ))

df.orig$publication_place[df.orig$publication_place == ""] <-NA

# Harmonize the raw data
tab <- polish_place(df.orig_p[[field]], remove.unknown = FALSE)

# Attach country
tab_country <- get_country(tab)

# Read geo data table in
f <- system.file("extdata/all_mapped_places_2020-06-15.csv", package = "fennica")
geo_data <-  read.csv(f,fileEncoding = "UTF-8")

# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id=df.orig[field_2], publication_place = tab,country=tab_country) %>% left_join(.,geo_data)
colnames(df.tmp) <- c("melinda_id","publication_place","publication_country","longitude","latitude","chosen_id")
df.tmp$id2 <- df.orig$other_system_id
df.tmp$publication_place[df.tmp$publication_place == ""] <-NA
df.tmp$publication_country[df.tmp$publication_country == ""] <-NA
####################################################################################

# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
# Generate markdown summary
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), 
            quote = FALSE, sep = ";", row.names = FALSE)

# Generate data summaries
message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], paste(output.folder, field, "_accepted.csv", sep = ""), count = TRUE)

message("Discarded entries in the original data")

# Final NA values after harmonization
inds <- which(is.na(df.tmp[[field]]))

# Get corresponding original values
original_vals <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

# Keep only truly discarded: originally NOT NA and NOT empty
original.discarded <- original_vals[!(is.na(original_vals) | original_vals == "")]

# Write table
tmp <- write_xtable(original.discarded,
                    paste(output.folder, field, "_discarded.csv", sep = ""),
                    count = TRUE)
#----------------------------------------------------------
message("Discarded entries in the original data")

# Final NA values after harmonization
inds <- which(is.na(df.tmp[[field]]))

# Match original values + IDs
orig_idx <- match(df.tmp$melinda_id[inds], df.orig$melinda_id)

error_df <- data.frame(
  id1 = df.tmp$melinda_id[inds],
  id2 = df.tmp$id2[inds],
  original_value = df.orig[[field]][orig_idx],
  stringsAsFactors = FALSE
)

# Keep only truly discarded (exclude NA / empty / whitespace)
error_df <- error_df %>%
  dplyr::filter(!(is.na(original_value) | trimws(original_value) == ""))

# Save full error list (with IDs)
write.csv(
  error_df,
  paste0(output.folder, field, "_discarded_with_ids.csv"),
  row.names = FALSE
)

# ------------------------------------------------------------

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "publication_place"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Define output files
file_accepted_19  <- paste0(output.folder, field, "_accepted_19.csv")

# ------------------------------------------------------------

# Generate data summaries for 1809-1917

message("Accepted entries in the preprocessed data")
s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)

# Generate markdown summary in note_source.md
df_19 <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
# 

