
install.packages("qdapRegex")
library(qdapRegex)

install.packages("readxl")
library(readxl)

# Read Excel file
velka_list <- read_excel("Kirjallisuus.xlsx")


# change FCC to FI-MELINDA to match df.orig melindas 
velka_list$MelindaID <- gsub(".*FCC", "FCC", velka_list$MelindaID)
velka_list$MelindaID <- sub("FCC", "", velka_list$MelindaID)
velka_list$MelindaID <- sub(" ", "", velka_list$MelindaID)
velka_list$MelindaID <- sub("(FI-MELINDA)", "", velka_list$MelindaID)
#velka_list$MelindaID <- rm_bracket(velka_list$MelindaID, pattern = "(", replacement = "")
#velka_list$MelindaID <- rm_bracket(velka_list$MelindaID, pattern = ")", replacement = "")


#copy list df to this file for testing stuff

melindas_filtered <- list

melindas_filtered$melinda_id <- gsub(".*\\(FI-MELINDA\\)", "\\(FI-MELINDA\\)", melindas_filtered$melinda_id)
melindas_filtered$melinda_id <- gsub("\\(FI-MELINDA\\)", "", melindas_filtered$melinda_id)
melindas_filtered$melinda_id <- sub("FCC", "", melindas_filtered$melinda_id)
melindas_filtered$melinda_id <- sub(" ", "", melindas_filtered$melinda_id)
#melidas_filtered$melinda_id <- rm_bracket(melidas_filtered$melinda_id, pattern = "(", replacement = "")
#melidas_filtered$melinda_id <- rm_bracket(melidas_filtered$melinda_id, pattern = ")", replacement = "")


# Get the unique values from both columns
unique_values_VL <- unique(velka_list$MelindaID)
unique_values_L <- unique(melindas_filtered$melinda_id)

# Find the values that are present in VL but not in L
non_matching_values_VL <- setdiff(unique_values_VL, unique_values_L)
non_matching_values_L <- setdiff(unique_values_L, unique_values_VL)


# Print the non-matching values
print(non_matching_values_VL)
print(non_matching_values_L)


matches <- match(unique_values_VL, unique_values_L)

# Identify the values in VL that have a match in L
matching_values <- unique_values_VL[!is.na(matches)]

# Print the matching values
print(matching_values)

