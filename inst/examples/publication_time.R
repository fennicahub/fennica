field <- "publication_time"

#polish full data
tmp  <- polish_years(df.orig[[field]], check = TRUE)
      
# Make data.frame
# Make sure if it called df.harmonized for publication_time, other fields have df.tmp 
# because publication_time field is sourced in other field procesing files 
df.harmonized <- data.frame(melinda_id = df.orig$melinda_id,
                     publication_year_from = tmp$from,
                     publication_year_till = tmp$till)

# Add publication_year as a separate column (same as "publication_year_from")
df.harmonized$publication_year <- df.harmonized$publication_year_from

# Add publication_decade
df.harmonized$publication_decade <- decade(df.harmonized$publication_year) 


# ---------------------------------------------------------------------
#1M data conversions
message("Write conversions: publication year")
df.harmonized$original <- df.orig[[field]]

xx <- as.data.frame(df.harmonized) %>% filter(!is.na(publication_year)) %>%
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
x <- as.character(df.harmonized[["publication_year"]])
inds <- which(is.na(x))
discard.file <- paste0(output.folder, field, "_discarded.csv")
tmp <- write_xtable(o[inds],
         file = discard.file,
      count = TRUE)

# ------------------------------------------------------------

#Create subsection for the 19th century only and 
df_19 <- df.harmonized %>% filter(publication_year > 1808 & publication_year < 1917)
melindas_19 <- df_19$melinda_id

# ---------------------------------------------------

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df.harmonized, file = data.file)

# Generate markdown summary 
df <- readRDS(data.file)

# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
#             output = paste(field, ".md", sep = ""))

