
#install.packages("qdapRegex")
library(qdapRegex)

#install.packages("readxl")
library(readxl)

list$signum <- gsub(" ", "", list$signum)

# Read Excel file
velka_big <- read_excel("Kauno 1809-1917.xlsx")
velka_big <- velka_big %>% slice(1:9232)

# Change the column name using colnames
colnames(velka_big)[colnames(velka_big) == "MelindaID"] <- "melinda_id"
colnames(velka_big)[colnames(velka_big) == "...5"] <- "title_remainder"
colnames(velka_big)[colnames(velka_big) == "Title"] <- "title"
colnames(velka_big)[colnames(velka_big) == "Signum"] <- "signum"
colnames(velka_big)[colnames(velka_big) == "Source language"] <- "language_original"
colnames(velka_big)[colnames(velka_big) == "Publication year"] <- "publication_time"


# change FCC to FI-MELINDA to match df.orig melindas 
velka_big$melinda_id <- sub("\\(FI-MELINDA\\)", "", velka_big$melinda_id)
velka_big$melinda_id <- sub("FCC", "", velka_big$melinda_id)
velka_big$melinda_id <- sub(" ", "", velka_big$melinda_id)
velka_big[velka_big == ''] <- NA

velka_big$melinda_id <- substr(velka_big$melinda_id, start =  1, stop =  9)
velka_big$signum <- gsub(" ", "", velka_big$signum)
df.orig$signum <- gsub(" ", "", df.orig$signum)

df.orig$melinda_id <- trimws(df.orig$melinda_id) # Trim whitespace
velka_big$melinda_id <- trimws(velka_big$melinda_id) # Trim whitespace

x <- velka_big$melinda_id[is.na(velka_big$melinda_id)]


# Step 2: Count matching melinda_id values

velka_big_unique <- velka_big[!duplicated(velka_big$melinda_id), ]

orig_and_big <- intersect(df.orig$melinda_id, velka_big_unique$melinda_id)

big_not_orig <- setdiff(velka_big_unique$melinda_id, df.orig$melinda_id)
print(big_not_orig)

big_not_orig_df <- velka_big_unique %>%     
  filter(melinda_id %in% big_not_orig)

install.packages("openxlsx")
library(openxlsx)
write.xlsx(big_not_orig_df, "only_in_Satu_list.xlsx")


write.table(big_not_orig_df, file = "only_in_Satu_list.csv", sep = ",", row.names = FALSE)


# Assuming df.orig and velka_big are your data frames

# Select rows from df.orig where melinda_id is found in velka_big$melinda_id
big_df <- df.orig[df.orig$melinda_id %in% velka_big$melinda_id, ]
big_df[big_df == ''] <- NA

#filterout lasten kirjallisuus
big_df <- big_df %>%
  filter(!grepl("Ruots\\.lastenkirj\\.|Suom\\.lastenkirj|last", signum))
big_df <- big_df[is.na(big_df$language_original), ]

big_and_orig_same <- intersect(velka_big$MelindaID, df.orig$melinda_id)#8457
big_and_orig_diff <- setdiff(velka_big$MelindaID, df.orig$melinda_id) #650 are not in our dataset


big_and_julia_same <- intersect(velka_big$MelindaID, list$melinda_id)
big_and_julia_diff <- setdiff(velka_big$MelindaID, list$melinda_id)

big_and_velka_same <- intersect(velka_big$MelindaID, velka_big$melinda_id)
big_and_velka_diff <- setdiff(velka_big$MelindaID, velka_big$melinda_id)

#__________________________________________________________________________________#
