field <- "publication_time"

#polish full data
tmp  <- polish_years_008(df.orig[[field]])

# Make data.frame
# Make sure if it called df_pubtime for publication_time, other fields have df.tmp 
# because publication_time field is sourced in other field processing files 
df_pubtime <- data.frame(melinda_id = df.orig$melinda_id,
                            original = tmp$original,
                            publication_year_from = tmp$from,
                            publication_year_till = tmp$till, 
                            publication_year = tmp$publication_year, 
                            publication_decade = tmp$decade)



# ---------------------------------------------------------------------
#1M data conversions
message("Write conversions: publication year")

xx <- data.frame(original = df_pubtime$original,
                 start_year = df_pubtime$publication_year_from,
                 end_year = df_pubtime$publication_year_till)
xx <- xx %>% filter(!is.na(start_year)) %>% filter(!is.na(end_year)) %>% filter(!is.na(original))
conversion.file <- paste0(output.folder, field, "_conversion.csv")
tmp <- write_xtable(xx,
                    file = conversion.file,
                    count = TRUE, 
                    add.percentages = TRUE)


message("Discarded publication year")
o <- as.character(df.orig[[field]])
x <- as.character(df_pubtime[["publication_year"]])
inds <- which(is.na(x))
discard.file <- paste0(output.folder, field, "_discarded.csv")
tmp <- write_xtable(o[inds],
                    file = discard.file,
                    count = TRUE,
                    add.percentages = TRUE)


#create a file for discarded with melindas
message("Discarded publication year with melinda ids")
discard.file.id <- paste0(output.folder, field, "_discarded_id.csv")
xx1 <- data.frame(melinda_id = df_pubtime$melinda_id, original = df_pubtime$original,publication_year = df_pubtime$publication_year)
xx1 <- xx1 %>% filter(is.na(publication_year))%>% filter(!is.na(original))
write.table(xx1,file = discard.file.id,
            sep = "\t",
            row.names = FALSE, 
            quote = FALSE)

# ------------------------------------------------------------

# Store the publication time field data
data.file <- paste0(field, ".Rds")
saveRDS(df_pubtime, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, 
            file = paste0(output.folder, paste0(field, ".csv")),
            sep = "\t",
            row.names=FALSE, 
            quote = FALSE)

# ------------------------------------------------------------

#Create subsection for the 19th century only and 
df_pubtime$original <- df.orig[[field]]
df_pubtime19 <- df_pubtime %>% filter(publication_year > 1808 & publication_year < 1918)
melindas_19 <- df_pubtime19$melinda_id


message("Write conversions: publication year for 1809-1917")


xx <- data.frame(original = df_pubtime19$original,
                 start_year = df_pubtime19$publication_year,
                 end_year = df_pubtime19$publication_year_till)

xx <- xx %>% filter(!is.na(start_year)) %>% filter(!is.na(end_year)) %>% filter(!is.na(original))

conversion.file <- paste0(output.folder, field, "_conversion_19.csv")
tmp <- write_xtable(xx,
                    file = conversion.file, 
                    count = TRUE, 
                    add.percentages = TRUE)


message("Discarded publication year for 1809-1917")
o <- as.character(df_pubtime[[field]])
x <- as.character(df_pubtime19[["publication_year"]])
inds <- which(is.na(x))
discard.file <- paste0(output.folder, field, "_discarded_19.csv")
tmp <- write_xtable(o[inds],
                    file = discard.file,
                    count = TRUE, 
                    add.percentages = TRUE)

# ---------------------------------------------------
# Store the field data for a subset 1809-1917
data.file.19 <- paste0(field,"_19", ".Rds")
saveRDS(df_pubtime19, file = data.file.19)

# Load the RDS file
df_sub <- readRDS(data.file.19)

# Convert to CSV and store in the output.tables folder
write.table(df_sub, file = paste0(output.folder, paste0(field, "_19", ".csv")))


##load to allas 
#source("allas.R")


 