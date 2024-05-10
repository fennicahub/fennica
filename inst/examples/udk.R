#080 - Universal Decimal Classification Number (R)
#UDK suomeksi
#https://www.kiwi.fi/display/Kansallisbibliografiapalvelut/Monografia-aineiston+UDK-luokituskaavio
library(dplyr)
library(tidyr)

field <- "UDK"

# #for monographic items only 
df_udk_full <- df.orig %>% mutate(UDK = ifelse(bibliographic_level == "Monograph/Item", UDK, ""))
# #monographic for 19 
df_udk_19 <- df_udk_full %>% filter(melinda_id %in% melindas_19)


# Harmonize the raw data
out <- polish_udk(df_udk_19[[field]])
df.tmp <- out$harmonized
# Reset the index to convert it into a single-index DataFrame
row.names(df.tmp) <- NULL

# Define output files
file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_accepted <- paste0(output.folder, field, "_accepted.csv")
file_discarded_id <- paste0(output.folder, field, "_discarded_id.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set 

message("Accepted udks")
for (myfield in c("udks", "udk_first")) {
  tmp <- write_xtable(df.tmp[[myfield]], paste(output.folder, myfield, "_accepted.csv", sep = ""), 
                      count = TRUE, 
                      add.percentages = TRUE)
}

message("UDK conversions")
tab <- cbind(original = df_udk_19[[field]], df.tmp[, 1:4])
tmp <- write_xtable(tab, paste(output.folder, field, "_conversions.csv", sep = ""), 
                    count = TRUE,
                    add.percentages = TRUE)

message("Language discarded")
# Original entries that were converted into NA
s <- unlist(strsplit(df_udk_19$UDK, ";"))
original.na <- s[s %in% out$unrecognized]
# .. ie. those are "discarded" cases; list them in a table
tmp2 <- write_xtable(original.na, file_discarded, 
                     count = TRUE, 
                     add.percentages = TRUE)

# message("Language discarded id")
# 
# lo <- as.list(original.na)
# filtered_df <- df.orig[df.orig$language %in% lo, ]
# new_df <- filtered_df[, c("melinda_id", "language")]
# write.csv(new_df, "language_discarded_id.csv", row.names=FALSE)


# ------------------------------------------------------------
# Function to match and concatenate names, including undetermined and handling NA
match_and_concatenate <- function(value) {
  if (is.na(value)) {
    return(NA)
  }
  
  split_value <- strsplit(value, ";")[[1]]
  converted_values <- c()
  
  for (val in split_value) {
    match_index <- match(val, udk$synonyme)
    if (!is.na(match_index)) {
      converted_values <- c(converted_values, udk$name[match_index])
    } else {
      converted_values <- c(converted_values, "Undetermined")
    }
  }
  
  return(paste(converted_values, collapse = ";"))
}

# Apply the function to each element of x to get df$converted
df <- data.frame(original = x0, cleaned = x)
df$converted <- sapply(x, match_and_concatenate)

# Split values for further processing
split_values <- strsplit(df$cleaned, ";")

# Create a data frame for further analysis
xu <- data.frame(unlist(split_values))
xu2 <- data.frame(unlist(strsplit(df$converted, ";")))

f <- data.frame(c = xu, h = xu2)
colnames(f) <- c("udk", "explanation")
f$explanation <- as.character(f$explanation)

# Filter for undetermined and accepted values
undetermined <- filter(f, f$explanation == "Undetermined")
accepted <- filter(f,f$explanation!= "Undetermined")
# Store the language field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")))

# ------------------------------------------------------------

# Define output files for 19th century
file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")
file_accepted_19 <- paste0(output.folder, field, "_accepted_19.csv")

#Run melindas_19.R to get melindas for 1809-1917
source("melindas_19.R")

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "language"

# Generate data summaries for the subset data set 

message("Accepted languages 19th century")
for (myfield in c("languages", "language_primary")) {
  tmp <- write_xtable(df_19[[myfield]], paste(output.folder, myfield, "_accepted_19.csv", sep = ""), 
                      count = TRUE, 
                      add.percentages = TRUE)
}

message("Language conversions for the 19th century")
tab <- cbind(original = df_19$languages, df_19[, 1:4])
tmp <- write_xtable(tab, paste(output.folder, field, "_conversions_19.csv", sep = ""), 
                    count = TRUE, 
                    add.percentages = TRUE)

# Discarded
# Original entries that were converted into NA
s <- unlist(strsplit(df.orig$language, ";"))
original.na <- s[s %in% out$unrecognized]
tmp2 <- write_xtable(original.na, file_discarded_19, 
                     count = TRUE, 
                     add.percentages = TRUE)


# ---------------------------------------------------

# Store the field data for a subset 1809-1917
data.file.19 <- paste0(field,"_19", ".Rds")
saveRDS(df_19, file = data.file.19)

# Load the RDS file
df_19 <- readRDS(data.file.19) 

# Convert to CSV and store in the output.tables folder
write.table(df_19, file = paste0(output.folder, paste0(field, "_19", ".csv")))


#load to allas 
#source("allas.R")


