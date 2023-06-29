field <- "publication_date"
source("../../R/polish_years.R")
tmp  <- polish_years(df.orig.full[[field]], check = TRUE)
      
# Make data.frame
df.harmonized <- data.frame(melinda_id = df.orig.full$melinda_id,
                     publication_year_from = tmp$from,
                     publication_year_till = tmp$till)

# Add publication_year as a separate column (same as "publication_year_from")
df.harmonized$publication_year <- df.harmonized$publication_year_from

# Add publication_decade
df.harmonized$publication_decade <- decade(df.harmonized$publication_year) 

# ---------------------------------------------------

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df.harmonized, file = data.file)

# ---------------------------------------------------------------------

message("Write conversions: publication year")
df.harmonized$original <- df.orig.full[[field]]

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
o <- as.character(df.orig.full[[field]])
x <- as.character(df.harmonized[["publication_year"]])
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

