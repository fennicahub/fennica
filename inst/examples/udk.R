#080 - Universal Decimal Classification Number (R)

field <- "UDC"

# Harmonize the raw data
out <- polish_udk(df.orig[[field]], chunk_size = 1000)

                   
df.tmp <- out$full
df.tmp$melinda_id <- df.orig$melinda_id
df.tmp$udk_aux <- polish_udk1(df.orig$UDC_aux, chunk_size = 1000)
df.tmp <- dplyr::select(df.tmp, melinda_id, everything())
df.tmp$id2 <- df.orig$other_system_id


df.tmp1 <- out$undetermined

# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL
row.names(df.tmp1) <- NULL


# Define output files

file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_accepted <- paste0(output.folder, field, "_accepted.csv")


# ------------------------------------------------------------

# Generate data summaries for the whole data set 

message("UDK accepted")
tmp <- write_xtable(as.character(df.tmp$converted), file_accepted, 
                    count = TRUE,
                    add.percentages = TRUE)


message("UDK discarded")
tmp2 <- write_xtable(df.tmp1, file_discarded, 
                     count = TRUE, 
                     add.percentages = TRUE)

message("Error list")

errors <- df.tmp %>%
  # remove rows with missing data
  filter(!is.na(cleaned), !is.na(converted)) %>%
  # split both columns on ";"
  mutate(
    unknown = str_split(cleaned, ";"),
    converted = str_split(converted, ";")
  ) %>%
  # unnest so each pair (code, label) gets its own row
  unnest(c(unknown, converted)) %>%
  # trim whitespace
  mutate(across(c(unknown, converted), str_trim)) %>%
  # keep only the rows where converted == "Undetermined"
  filter(str_detect(converted, regex("^Undetermined\\.?$", ignore_case = TRUE)))

errors <- data.frame(id1 = errors$melinda_id, id2 = errors$id2, original = errors$original, 
                     harmonized = errors$cleaned, unknown_udk = errors$unknown)

tmp1 <- write.csv(errors, 
                   file = paste0(output.folder, "udk_errors_list.csv"),
                   row.names=FALSE, 
                   quote = FALSE,
                   fileEncoding = "UTF-8")  


# Store the UDK field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, field, ".csv"), quote = FALSE, sep = "", row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------

#Run melindas_19.R to get melindas for 1809-1917
#source("melindas_19.R")
df.tmp_19 <- df.tmp %>% filter(melinda_id %in% melindas_19)


# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL

# Define output files

file_discarded <- paste0(output.folder, field, "_discarded_19.csv")
file_accepted <- paste0(output.folder, field, "_accepted_19.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set 

message("UDK accepted")
tmp_19 <- write_xtable(as.character(df.tmp_19$converted), paste(output.folder, field, "_accepted_19.csv", sep = ""), 
                    count = TRUE,
                    add.percentages = TRUE, 
                    na.rm = TRUE)

# ------------------------------------------------------------

# Store the UDK field data
data.file.19 <- paste0(field, ".Rds")
saveRDS(df.tmp_19, file = data.file.19)
#Load the RDS file
df_19 <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df_19, file = paste0(output.folder, paste0(field, "_19.csv")), quote = FALSE, sep = "", row.names = FALSE, fileEncoding = "UTF-8")

