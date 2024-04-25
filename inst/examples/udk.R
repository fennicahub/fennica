#080 - Universal Decimal Classification Number (R)
#UDK suomeksi
#https://www.kiwi.fi/display/Kansallisbibliografiapalvelut/Monografia-aineiston+UDK-luokituskaavio
library(dplyr)
library(tidyr)

field <- "UDK"

# #for monographic items only 
df_udk_full <- df.orig %>% mutate(UDK = ifelse(bibliographic_level == "Monograph/Item", UDK, ""))
# 
# #monographic for 19 
df_udk_19 <- df_udk_full %>% filter(melinda_id %in% melindas_19)
# 
x <- df_udk_19$UDK
x <- df.orig$UDK
  
# Harmonize the raw data
tmp <- polish_udk(df.orig[[field]])
tmp


#df for original, cleaned and harmonized incl undetermined 
df.tmp <- data.frame(melinda_id = df.orig$melinda_id, 
                     original = tmp$full$original, 
                     cleaned = tmp$full$cleaned, 
                     harmonized = tmp$full$converted)

df.tmp1 <- data.frame(udk = tmp$accepted$udk, 
                      explanation = tmp$accepted$explanation)

df.tmp2 <- data.frame(udk = tmp$undetermined$udk, 
                      explanation = tmp$undetermined$explanation)

acc <- unique(df.tmp2$udk)
und <- unique(df.tmp2$udk)
x <- df.tmp$harmonized
# Check for rows where all values are "Undetermined"
rows_with_only_undetermined <- apply(df.tmp, 1, function(x) all(grepl("^Undetermined$", x)))

rows_with_undetermined <- grepl("^Undetermined(\\sUndetermined)*$", df.tmp$harmonized)
df_with_undetermined <- df.tmp[rows_with_undetermined, ]

# Print the result
print(rows_with_only_undetermined)

# Assuming df is your original dataframe

# Split df$cleaned and df$harmonized by semicolon


# Vectorized check for "Undetermined" in harmonized values
contains_undetermined <- sapply(harmonized_split, function(x) "Undetermined" %in% x)

# Split df into two based on the vectorized check
df_undetermined <- df.tmp[contains_undetermined, ]
df_other <- df.tmp[!contains_undetermined & !is.na(df.tmp$harmonized), ]

# View the resulting dataframes
df_undetermined
df_other



file_accepted <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_discarded_id <- paste0(output.folder, field, "_discarded_id.csv")

#______________________________________________________________

tmp <- write_xtable(df,
                    file = conversion.file, 
                    count = TRUE, 
                    add.percentages = TRUE)

# Accepted udks without undetermined COUNT table

# Undetermined COUNT table

# Undetermined with melindas 


# ------------------------------------------------------------

# Store the  data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")))
