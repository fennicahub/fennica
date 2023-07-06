field <- "publication_place"
field_2 <- "melinda_id"

# Harmonize the raw data
tab <- polish_place(df.orig[[field]], remove.unknown = FALSE)

# Attach country
tab_country <- get_country(tab)

# Read geo data table in
f <- system.file("extdata/all_mapped_places_2020-06-15.csv", package = "fennica")
geo_data <-  read.csv(f,fileEncoding = "UTF-8")

# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id=df.orig[field_2],publication_place = tab,country=tab_country) %>% left_join(.,geo_data)
colnames(df.tmp) <- c("melinda_id","publication_place","publication_country","longitude","latitude","chosen_id")

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

