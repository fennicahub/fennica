field <- "publication_place"
field_2 <- "melinda_id"

#enrich 260a with 264a 
df.orig_p <- df.orig %>%
  mutate(publication_place = ifelse(
    (is.na(publication_place) | publication_place == "") & 
      !(is.na(df.orig$`264a`) | df.orig$`264a` == ""),
    df.orig$`264a`,
    publication_place
  ))

# Harmonize the raw data
tab <- polish_place(df.orig_p[[field]], remove.unknown = FALSE)

# Attach country
tab_country <- get_country(tab)

# Read geo data table in
f <- system.file("extdata/all_mapped_places_2020-06-15.csv", package = "fennica")
geo_data <-  read.csv(f,fileEncoding = "UTF-8")

# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id=df.orig[field_2],publication_place = tab,country=tab_country) %>% left_join(.,geo_data)
colnames(df.tmp) <- c("melinda_id","publication_place","publication_country","longitude","latitude","chosen_id")

####################################################################################

# Save publication place data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# Generate data summaries
message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], paste(output.folder, field, "_accepted.csv", sep = ""), count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df.tmp[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, paste(output.folder, field, "_discarded.csv", sep = ""), count = TRUE)

# ------------------------------------------------------------

# Generate markdown summary
df <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
#             output = paste(field, ".md", sep = ""))



# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "publication_place"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Define output files
file_accepted_19  <- paste0(output.folder, field, "_accepted_19.csv")
file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")

# ------------------------------------------------------------

# Generate data summaries for 1809-1917

message("Accepted entries in the preprocessed data")
s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df_19[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded_19, count = TRUE)

# ------------------------------------------------------------

# Generate markdown summary in note_source.md
df_19 <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
# 

