#080 - Universal Decimal Classification Number (R)

field <- "UDK"

# Harmonize the raw data
out <- polish_udk(df.orig[[field]])
df.tmp <- out$df
df.tmp$melinda_id <- df.orig$melinda_id
df.tmp <- select(df.tmp, melinda_id, everything())

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
tab <- cbind(original = df.tmp$original, converted = df.tmp$converted)
tmp <- write_xtable(tab, paste(output.folder, field, "_accepted.csv", sep = ""), 
                    count = TRUE,
                    add.percentages = TRUE)


message("UDK discarded")
# .. ie. those are "discarded" cases; list them in a table
tmp2 <- write_xtable(df.tmp1, file_discarded, 
                     count = TRUE, 
                     add.percentages = TRUE)



message("UDK discarded id")
lo <- as.list(original.na)
filtered_df <- df.orig[df.origl$UDK %in% lo, ]
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
# #monographic for 19 
#Run melindas_19.R to get melindas for 1809-1917
source("melindas_19.R")
df.tmp_19 <- df.tmp %>% filter(melinda_id %in% melindas_19)
#df.tmp1_19 <- df.tmp1 %>% filter(melinda_id %in% melindas_19)

# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL



# Define output files

file_discarded <- paste0(output.folder, field, "_discarded_19.csv")
file_accepted <- paste0(output.folder, field, "_accepted_19.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set 

message("UDK accepted")
tab_19 <- cbind(original = df.tmp_19$original, converted = df.tmp_19$converted)
tmp_19 <- write_xtable(tab_19, paste(output.folder, field, "_accepted_19.csv", sep = ""), 
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

