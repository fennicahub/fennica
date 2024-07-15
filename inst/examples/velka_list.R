
#install.packages("qdapRegex")
library(qdapRegex)

#install.packages("readxl")
library(readxl)

list$signum <- gsub(" ", "", list$signum)


# Read Excel file
velka_list <- read_excel("Kirjallisuuden ensipainokset.xlsx")
# Change the column name using colnames
colnames(velka_list)[colnames(velka_list) == "MelindaID"] <- "melinda_id"
colnames(velka_list)[colnames(velka_list) == "...5"] <- "title_remainder"
colnames(velka_list)[colnames(velka_list) == "Title"] <- "title"
colnames(velka_list)[colnames(velka_list) == "Publication year"] <- "publication_time"


# change FCC to FI-MELINDA to match df.orig melindas 
velka_list$melinda_id <- gsub(".*FCC", "FCC", velka_list$melinda_id)
velka_list$melinda_id <- sub("FCC", "", velka_list$melinda_id)
velka_list$melinda_id <- sub(" ", "", velka_list$melinda_id)
velka_list$melinda_id <- sub("(FI-MELINDA)", "", velka_list$melinda_id)

velka_list$melinda_id <- substr(velka_list$melinda_id, start =  1, stop =  9)
velka_list$signum <- gsub(" ", "", velka_list$Signum)
df.orig$signum <- gsub(" ", "", df.orig$signum)

# result1 <- velka_list %>%
#   group_by(title) %>%
#   filter(publication_time == min(publication_time)) %>%
#   distinct(title,.keep_all = TRUE)
# 
# velka_list <- result1 %>% arrange(publication_time)


#copy list df to this file for testing stuff

list_test <- list
full_fennica <- df.orig
nineteen <- df_pubtime19


# Get the melinda unique values from both columns
VL <- velka_list$melinda_id #2791
JL <- list_test$melinda_id #3398

# Identify the values in VL that have a match in JL
velka_and_julia <- intersect(VL, JL) #2298 MATCHING
print(velka_and_julia)

velka_and_julia_df <- full_fennica %>%     
  filter(melinda_id %in% velka_and_julia)

velka_and_julia_titles <- setdiff(velka_list$title, list$title)

# DIRTY Find the values that are present in VL but not in JL 
velka_not_julia_d <- setdiff(VL, JL) #487
print(velka_not_julia_d)

#velka_and_full_fennica 
velka_and_full_fennica <- intersect(VL, full_fennica$melinda_id) #2574

# melindas which are in  VL but non in full fennica 
velka_not_full_fennica <- setdiff(VL, full_fennica$melinda_id) #210
print(velka_not_full_fennica)

velka_not_full_fennica_df <- velka_list %>%       #these are not on my list but in fennica
  filter(melinda_id %in% velka_not_full_fennica)

# CLEAN delete which are not in our dataset 
velka_not_julia_c <- setdiff(velka_not_julia_d, velka_not_full_fennica) #277
print(velka_not_julia_c)

velka_not_julia_df <- full_fennica %>%       #these are not on my list but in fennica
  filter(melinda_id %in% velka_not_julia_c)


#in julia not in velka
julia_not_velka <- setdiff(JL, VL) ##1101
print(julia_not_velka) 

julia_not_velka_df <- full_fennica %>%    #these are not in your list 
  filter(melinda_id %in% julia_not_velka)


# matches VL and 19
velka_and_19 <- intersect(VL, nineteen$melinda_id) #2574
print(velka_and_19)

# in VL but not in harmonized list 1809-1917
velka_not_19 <- setdiff(VL, nineteen$melinda_id) #210 also not in fennica
print(velka_not_19) 

velka_not_julia_19<- setdiff(velka_not_julia_df$melinda_id, nineteen$melinda_id) #2574
print(velka_and_19)



write.table(velka_not_full_fennica_df, file = paste0(output.folder, "velka_not_full_fennica.csv"), quote = FALSE, sep = ";", row.names = FALSE, fileEncoding = "UTF-8")


################################################################################


