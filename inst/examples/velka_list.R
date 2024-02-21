
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

melindas_filtered <- list

melindas_filtered$melinda_id <- gsub(".*\\(FI-MELINDA\\)", "\\(FI-MELINDA\\)", melindas_filtered$melinda_id)
melindas_filtered$melinda_id <- gsub("\\(FI-MELINDA\\)", "", melindas_filtered$melinda_id)
melindas_filtered$melinda_id <- sub("FCC", "", melindas_filtered$melinda_id)
melindas_filtered$melinda_id <- sub(" ", "", melindas_filtered$melinda_id)

all_melindas <- df.orig
all_melindas$melinda_id <- gsub(".*\\(FI-MELINDA\\)", "\\(FI-MELINDA\\)", all_melindas$melinda_id)
all_melindas$melinda_id <- gsub("\\(FI-MELINDA\\)", "", all_melindas$melinda_id)
all_melindas$melinda_id <- sub("FCC", "", all_melindas$melinda_id)
all_melindas$melinda_id <- sub(" ", "", all_melindas$melinda_id)




# Get the unique values from both columns
VL <- velka_list$melinda_id
L <- melindas_filtered$melinda_id

# Find the values that are present in VL but not in L
non_matching_values_VL <- setdiff(VL, L)
non_matching_values_L <- setdiff(L, VL)


# Print the non-matching values
print(non_matching_values_VL)
print(non_matching_values_L)


# Identify the values in VL that have a match in L
matching_values <- VL[!is.na(matches)]

# Print the matching values
print(matching_values)

library(dplyr)

non_fennica <- setdiff(non_matching_values_VL, all_melindas$melinda_id)

not_on_julia_list <- setdiff(non_matching_values_VL, non_fennica)
print(not_on_julia_list)


# Assuming all_melindas is your data frame and not_on_julia_list is your list of values

# Filter the data frame to include only rows where melinda_id is in the not_on_julia_list
not_on_julia_list <- all_melindas[all_melindas$melinda_id %in% not_on_julia_list, ]

# Print the chunk
print(matching_chunk) # the whole thing is rejected by polish_years 
                      # it is probably in the discraded publication time file


# Count the number of matching melinda_id values
count_matching <- sum(matching_chunk$melinda_id %in% df.orig$melinda_id)

# Print the count
print(count_matching)

