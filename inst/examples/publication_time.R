field <- "publication_time"
tmp  <- polish_years(df.orig[[field]], check = TRUE)
      
# Make data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id,
                     publication_year_from = tmp$from,
                     publication_year_till = tmp$till)

# Add publication_year as a separate column (same as "publication_year_from")
df.tmp$publication_year <- df.tmp$publication_year_from

# Add publication_decade
df.tmp$publication_decade <- decade(df.tmp$publication_year) 

#create df.harmonized to be used in physical_interval for comparison
df.harmonized <- df.tmp

# ---------------------------------------------------

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# ---------------------------------------------------------------------

message("Write conversions: publication year")
df.tmp$original <- df.orig[[field]]

xx <- as.data.frame(df.tmp) %>% filter(!is.na(publication_year)) %>%
                                       group_by(original, publication_year) %>%
                                       tally() %>%
				       arrange(desc(n))

conversion.file <- paste0(output.folder, field, "_conversion.csv")
tmp <- write.table(xx,
         file = conversion.file,
	 quote = FALSE,
	 row.names = FALSE)
  
message("Discarded publication year")
o <- as.character(df.orig[[field]])
x <- as.character(df.tmp[["publication_year"]])
inds <- which(is.na(x))
discard.file <- paste0(output.folder, field, "_discarded.csv")
tmp <- write_xtable(o[inds],
         file = discard.file,
      count = TRUE)

# ------------------------------------------------------------

# Generate markdown summary 
df <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
#             output = paste(field, ".md", sep = ""))

