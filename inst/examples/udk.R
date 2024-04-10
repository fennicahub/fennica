#080 - Universal Decimal Classification Number (R)
#UDK suomeksi
#https://www.kiwi.fi/display/Kansallisbibliografiapalvelut/Monografia-aineiston+UDK-luokituskaavio
library(dplyr)
library(tidyr)
field <- "UDK"

df.tmp <- data.frame(melinda_id = df.orig$melinda_id,
                     udk = df.orig$UDK)

df.tmp$udk <- gsub(":", "|", df.tmp$udk)
df.tmp$udk <- gsub("\\+", "|", df.tmp$udk)
df.tmp$udk <- gsub("\\s+$", "", df.tmp$udk)
df.tmp$udk <- gsub("^\\s+", "", df.tmp$udk)


df_split <- df.tmp %>%
  separate_rows(udk, sep = "\\|")

tmp <- write_xtable(df_split,
                    file = conversion.file, 
                    count = TRUE, 
                    add.percentages = TRUE)


unique_values <- df_split %>%
  distinct(udk)

# Convert the result to a list
unique_values_list <- unique_values$udk

