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
  
# Harmonize the raw data
tmp <- polish_udk(df_udk_full[[field]])
tmp


#df for original, cleaned and harmonized incl undetermined 
df.tmp <- data.frame(melinda_id = df.orig$melinda_id, 
                     original = tmp$full$original, 
                     cleaned = tmp$full$cleaned, 
                     harmonized = tmp$full$converted)

#df for accepted
df.tmp1 <- data.frame(udk = tmp$accepted$udk, 
                      explanation = tmp$accepted$explanation)

#df for undetermiend 
df.tmp2 <- data.frame(udk = tmp$undetermined$udk, 
                      explanation = tmp$undetermined$explanation)


message("Converted entries in the preprocessed data")

xx <- xx %>% filter(!is.na(start_year)) %>% filter(!is.na(end_year)) %>% filter(!is.na(original))
conversion.file <- paste0(output.folder, field, "_conversion.csv")
tmp <- write_xtable(xx,
                    file = conversion.file, 
                    count = TRUE, 
                    add.percentages = TRUE)

message("Accepted entries in the preprocessed data")

xx <- xx %>% filter(!is.na(start_year)) %>% filter(!is.na(end_year)) %>% filter(!is.na(original))
conversion.file <- paste0(output.folder, field, "_conversion.csv")
tmp <- write_xtable(xx,
                    file = conversion.file, 
                    count = TRUE, 
                    add.percentages = TRUE)

message("UDK discarded")

original.na <- s[s %in% out$unrecognized]
# .. ie. those are "discarded" cases; list them in a table
tmp2 <- write_xtable(original.na, file_discarded, 
                     count = TRUE, 
                     add.percentages = TRUE)

