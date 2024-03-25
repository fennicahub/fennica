
#install.packages("qdapRegex")
library(qdapRegex)

#install.packages("readxl")
library(readxl)

# Read Excel file
velka_list <- read_excel("Kirjallisuus.xlsx")
# Change the column name using colnames
colnames(velka_list)[colnames(velka_list) == "MelindaID"] <- "melinda_id"



# change FCC to FI-MELINDA to match df.orig melindas 
velka_list$melinda_id <- gsub(".*FCC", "FCC", velka_list$melinda_id)
velka_list$melinda_id <- sub("FCC", "", velka_list$melinda_id)
velka_list$melinda_id <- sub(" ", "", velka_list$melinda_id)
velka_list$melinda_id <- sub("(FI-MELINDA)", "", velka_list$melinda_id)

velka_list$melinda_id <- substr(velka_list$melinda_id, start =  1, stop =  9)



#copy list df to this file for testing stuff

list_test <- list

list_test$melinda_id <- gsub(".*\\(FI-MELINDA\\)", "\\(FI-MELINDA\\)", list_test$melinda_id)
list_test$melinda_id <- gsub("\\(FI-MELINDA\\)", "", list_test$melinda_id)
list_test$melinda_id <- sub("FCC", "", list_test$melinda_id)
list_test$melinda_id <- sub(" ", "", list_test$melinda_id)

full_fennica <- df.orig
full_fennica$melinda_id <- gsub(".*\\(FI-MELINDA\\)", "\\(FI-MELINDA\\)", full_fennica$melinda_id)
full_fennica$melinda_id <- gsub("\\(FI-MELINDA\\)", "", full_fennica$melinda_id)
full_fennica$melinda_id <- sub("FCC", "", full_fennica$melinda_id)
full_fennica$melinda_id <- sub(" ", "", full_fennica$melinda_id)

nineteen <- df_pubtime19
nineteen$melinda_id <- gsub(".*\\(FI-MELINDA\\)", "\\(FI-MELINDA\\)", nineteen$melinda_id)
nineteen$melinda_id <- gsub("\\(FI-MELINDA\\)", "", nineteen$melinda_id)
nineteen$melinda_id <- sub("FCC", "", nineteen$melinda_id)
nineteen$melinda_id <- sub(" ", "", nineteen$melinda_id)


# Get the melinda unique values from both columns
VL <- velka_list$melinda_id
JL <- list_test$melinda_id

# Identify the values in VL that have a match in JL
velka_and_julia <- intersect(VL, JL) #2271 MATCHING
print(velka_and_julia)

velka_and_julia_df <- full_fennica %>%    #SAME VALUES 
  filter(melinda_id %in% velka_and_julia)


# DIRTY Find the values that are present in VL but not in JL
velka_not_julia_d <- setdiff(VL, JL) #513 
print(velka_not_julia_d)

# CLEAN delete 212 which are not in our dataset 301
velka_not_julia_c <- setdiff(velka_not_julia_d, velka_not_full_fennica) 
print(velka_not_julia_c)

velka_not_julia_df <- full_fennica %>%       #these are not on my list but in fennica
  filter(melinda_id %in% velka_not_julia_c)


#in julia not in velka
julia_not_velka <- setdiff(JL, VL) ##2737
print(julia_not_velka) 

julia_not_velka_df <- full_fennica %>%    #these are not in your list 
  filter(melinda_id %in% julia_not_velka)

#velka_and_full_fennica 
velka_and_full_fennica <- intersect(VL, full_fennica$melinda_id) #2572

# melindas which are in  VL but non in full fennica 
velka_not_full_fennica <- setdiff(VL, full_fennica$melinda_id) #212
print(velka_not_full_fennica)

# matches VL and 19
velka_and_19 <- intersect(VL, nineteen$melinda_id) #2572 
print(velka_and_19)

# in VL but not in harmonized list 1809-1917
velka_not_19 <- setdiff(VL, nineteen$melinda_id) #212
print(velka_not_19) 








