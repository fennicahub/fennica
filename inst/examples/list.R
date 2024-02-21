library(devtools)
library(dplyr)
library(tm)
library(stringr)
library(knitr)
library(R.utils)
library(ggplot2)
library(Cairo)
library(fennica) 
source("funcs.R")
#source("publication_time.R")



# Parameters: 
# 0) ("260","c") 1809-1917
#take melindas from the df_pubtime19 which were obtained after harmonizing
#publication_time field in df.orig

melindas <- df_pubtime19$melinda_id
list <-  df.orig[df.orig$melinda_id %in% melindas, ]

# 5) 250 a (tyhjä) (only this gives 47627)
list <- list[is.na(list$"250a") | list$"250a" == "", ]


# 2) 041 h (tyhjä) (43106)

list <- list[is.na(list$language_original) | list$language_original == "", ]

# 1) 041 a fin ja (tai) swe (47160)

list <- list[grepl("fin|swe", list$language) | is.na(list$language), ]


# 3) 080 a 839.79 ja (tai) 894.541 (5124)

list <- list[grepl("839.79|839.7|894.541|820/89|894.54", list$UDK)| is.na(list$UDK), ]


# 4) 080 x -1, -2, -3, -4 (only this parameter gives 4993 obs)


# Assuming list is your data frame and "080x" is the column name
# The pattern is a regular expression that matches -1, -2, -3, or -4

list <- list[grepl("-1|-2|-3|-4", list$'080x') | is.na(list$'080x'), ]

# genre based search 


 
# # Define the genres you want to keep
genres_to_keep <- c("Fiction (not further specified)", "Dramas", "Essays", "Novels",  
                     "Humor, satires, etc.", "Short stories, stories or their collections",  
                     "Combination of genres", "Poems")
 
# # Filter the list DataFrame to keep only the rows with the specified genres
list <- list %>% filter(genre_book %in% genres_to_keep)

#kaunokirj.

#list <- list[grepl("kauno", list$signum) | is.na(list$signum), ]

############################################################################

#the list has only language material type of record 
unique_counts <- table(list$type_of_record)

