#080 - Universal Decimal Classification Number (R)

field <- "UDK"

# #for monographic items only 

# First, filter the rows where bibliographic_level is "Monograph/Item"
df_udk_full <- df.orig %>%
  filter(bibliographic_level == "Monograph/Item")

# #monographic for 19 
df_udk_19 <- df_udk_full %>% filter(melinda_id %in% melindas_19)


# Harmonize the raw data
out <- polish_udk(df_udk_full[[field]])
df.tmp <- out$df
df.tmp$melinda_id <- df_udk_full$melinda_id

df.tmp1 <- out$undetermined
df.tmp2 <- out$accepted

# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL
row.names(df.tmp1) <- NULL
row.names(df.tmp1) <- NULL


# Define output files

file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_accepted <- paste0(output.folder, field, "_accepted.csv")


# ------------------------------------------------------------

# Generate data summaries for the whole data set 

message("Accepted udks")
tmp <- write_xtable(df.tmp2, file_accepted, 
                      count = TRUE, 
                      add.percentages = TRUE)


message("UDK discarded")
# Original entries that were converted into NA
s <- unlist(strsplit(df_udk_full$UDK, ";"))
original.na <- s[s %in% df.tmp1$udk]
# .. ie. those are "discarded" cases; list them in a table
tmp2 <- write_xtable(original.na, file_discarded, 
                     count = TRUE, 
                     add.percentages = TRUE)


message("UDK discarded id")
lo <- as.list(original.na)
filtered_df <- df_udk_full[df_udk_full$UDK %in% lo, ]
x <- filtered_df[, c("melinda_id", "UDK")]
write.csv(x, "udk_discarded_id.csv", row.names=FALSE)

# ------------------------------------------------------------

# Store the UDK field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE, sep = ";", row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------

# Harmonize the raw data
out <- polish_udk(df_udk_19[[field]])
df.tmp_19 <- out$df
df.tmp_19$melinda_id <- df_udk_19$melinda_id

df.tmp1_19 <- out$undetermined
df.tmp2_19 <- out$accepted

# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL



# Define output files

file_discarded <- paste0(output.folder, field, "_discarded_19.csv")
file_accepted <- paste0(output.folder, field, "_accepted_19.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set 

message("Accepted udks")
tmp_19 <- write_xtable(df.tmp2_19, file_accepted, 
                    count = TRUE, 
                    add.percentages = TRUE)


message("UDK discarded")
# Original entries that were converted into NA
s <- unlist(strsplit(df_udk_19$UDK, ";"))
original.na <- s[s %in% df.tmp1_19$udk]
# .. ie. those are "discarded" cases; list them in a table
tmp2_19 <- write_xtable(original.na, file_discarded, 
                     count = TRUE, 
                     add.percentages = TRUE)

message("UDK discarded id")
lo <- as.list(original.na)
filtered_df <- df_udk_19[df_udk_19$UDK %in% lo, ]
x_19 <- filtered_df[, c("melinda_id", "UDK")]
write.csv(x_19, "udk_discarded_id_19.csv", row.names=FALSE)


# ------------------------------------------------------------

# Store the UDK field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp_19, file = data.file)
#Load the RDS file
df_19 <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df_19, file = paste0(output.folder, paste0(field, "_19.csv")), quote = FALSE, sep = ";", row.names = FALSE, fileEncoding = "UTF-8")
